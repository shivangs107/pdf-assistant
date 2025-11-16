# Fetch the first available VPC (so Terraform knows where to create resources)
data "aws_vpc" "default" {
  default = true
}

#EC2 SSM Access
resource "aws_iam_instance_profile" "streamlit_profile" {
  name = "streamlit-profile"
  role = "EC2_SSM_Access"
}

#Main Resources
resource "aws_instance" "streamlit_app" {
  ami           = "ami-02b8269d5e85954ef"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.streamlit_keypair.key_name

  # Allow HTTP (8501 for Streamlit) and SSH
  vpc_security_group_ids = [aws_security_group.streamlit_sg.id]
  iam_instance_profile = aws_iam_instance_profile.streamlit_profile.name #Apply IAM roles

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -eux
    
    sudo apt update -y
    sudo apt install -y ca-certificates curl unzip
    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker

    api_key=$(aws ssm get-parameter --name "OPENAI_API_KEY" --with-decryption --query Parameter.Value --output text --region ap-south-1)
    sudo docker run -d -p 8501:8501 -e OPENAI_API_KEY=$api_key ${var.docker_image}
  EOF
  root_block_device {
    volume_size           = 20        # Increase to 20 GB (adjust as needed)
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "streamlit-app-instance"
  }
}
#ca-certificates curl unzip -> Prepares environment for HTTPS downloads
#curl https://awscli.amazonaws.com/... -> Installs AWS CLI v2 correctly (works in all Ubuntu versions)
#curl -fsSL https://get.docker.com -> Official Docker install method (maintained by Docker)
#systemctl enable/start docker -> Starts Docker properly after setup
#docker run ... -> Runs your container as intended

#Important flags
# -e: Exit immediately if any command fails (stops early instead of silently failing)
# -u: Treat unset variables as an error (Catches typos or missing environment variables (e.g., $api_key not defined))
# -x: Print commands before execution

resource "aws_security_group" "streamlit_sg" {
  name_prefix = "streamlit-sg-"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
