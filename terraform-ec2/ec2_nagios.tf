# Nagios Monitoring Server (Dockerized + Auto Monitoring)
resource "aws_security_group" "nagios_sg" {
  name_prefix = "nagios-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress {#SSH Traffic
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Allow connection from anywhere on the internet to SSH into its EC2
  }

  ingress {#HTTP Traffic for accessing Nagios Web UI
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /* ICMP for check_ping!100.0,20%!500.0,60%
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP Ping from Nagios"
  }
  */

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #All protocol
    cidr_blocks = ["0.0.0.0/0"] #To any destination
  }

  tags = {
    Name = "nagios-security-group"
  }
}

# Wait until Streamlit app becomes active (check from inside EC2)
resource "null_resource" "wait_for_streamlit" {
  depends_on = [aws_instance.streamlit_app]

  # Connect inside the Streamlit EC2 instance
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.streamlit_key.private_key_pem
    host        = aws_instance.streamlit_app.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo '⏳ Waiting for Streamlit app to start...'",
      "for i in $(seq 1 10); do",
      "  STATUS=$(curl -s -o /dev/null -w '%%{http_code}' http://localhost:8501 || true)",
      "  echo \"Attempt $i: Received HTTP status $STATUS from Streamlit.\"",
      "  if [ \"$STATUS\" = \"200\" ]; then",
      "    echo '✅ Streamlit app is running at http://${aws_instance.streamlit_app.public_ip}:8501';",
      "    exit 0;",
      "  else",
      "    echo \"Streamlit not ready yet (HTTP $STATUS), retrying in 30s...\";",
      "    sleep 30;",
      "  fi;",
      "done",
      "echo '❌ Streamlit app did not start in time.' && exit 1"
    ]
  }
}

# Nagios EC2 Instance
resource "aws_instance" "nagios_server" {
  ami                    = "ami-02b8269d5e85954ef"  # Ubuntu 22.04
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.streamlit_keypair.key_name
  vpc_security_group_ids = [aws_security_group.nagios_sg.id]
  iam_instance_profile = aws_iam_instance_profile.streamlit_profile.name
  depends_on             = [null_resource.wait_for_streamlit]

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -eux

    sudo apt update -y
    sudo apt install -y ca-certificates curl unzip

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker

    # Fetch credentials securely from AWS SSM
    NAGIOS_USER=$(aws ssm get-parameter --name "NAGIOS_USER" --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
    NAGIOS_PASS=$(aws ssm get-parameter --name "NAGIOS_PASS" --with-decryption --query Parameter.Value --output text --region ${var.aws_region})

    # Create monitoring config for Streamlit EC2
    STREAMLIT_IP="${aws_instance.streamlit_app.public_ip}"
    cat <<CONFIG > /tmp/streamlit.cfg
    define host {
        use             linux-server
        host_name       streamlit-app
        alias           Streamlit Application
        address         $STREAMLIT_IP
        check_command   check_http!-p 8501
        max_check_attempts  3
        check_period    24x7
        notification_interval 2
        notification_period   24x7
    }

    define service {
        use                     generic-service
        host_name               streamlit-app
        service_description     Streamlit HTTP Port
        check_command           check_http!-p 8501
    }
    CONFIG

    # Fix permissions so Nagios container can read it
    sudo chown 1000:1000 /tmp/streamlit.cfg
    sudo chmod 644 /tmp/streamlit.cfg

    # Run Nagios container
    sudo docker run -d \
      --name nagios \
      --restart unless-stopped \
      -p 80:80 \
      -v /tmp/streamlit.cfg:/opt/nagios/etc/servers/streamlit.cfg \
      -e NAGIOSADMIN_USER=$NAGIOS_USER \
      -e NAGIOSADMIN_PASS=$NAGIOS_PASS \
      jasonrivers/nagios:latest

    # Wait a bit for container startup and restart Nagios daemon
    sleep 10

    # Enable /opt/nagios/etc/servers directory in Nagios config
    sudo docker exec nagios sed -i 's|#cfg_dir=/opt/nagios/etc/servers|cfg_dir=/opt/nagios/etc/servers|' /opt/nagios/etc/nagios.cfg
    
    # Restart Nagios to apply config changes
    sudo docker restart nagios

    # Validate and reload Nagios
    sudo docker exec nagios /opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg || true
    sudo docker exec nagios /opt/nagios/bin/nagios -d /opt/nagios/etc/nagios.cfg || true

    echo "✅ Nagios setup complete. Monitoring Streamlit app at $STREAMLIT_IP:8501"
  EOF

  tags = {
    Name = "nagios-monitor-instance"
    Environment = "Monitoring"
    ManagedBy = "Terraform"
  }
}
