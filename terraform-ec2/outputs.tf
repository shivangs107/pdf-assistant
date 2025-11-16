# Show the EC2 instance public IP
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.streamlit_app.public_ip
}

# Show ready-to-use SSH command
output "ssh_connection_streamlit" {
  description = "SSH command to connect to your EC2 instance"
  value       = "ssh -i ${path.module}/${aws_key_pair.streamlit_keypair.key_name}.pem ubuntu@${aws_instance.streamlit_app.public_ip}"
}

# Show your Streamlit app URL
output "app_url" {
  description = "Streamlit app URL"
  value       = "http://${aws_instance.streamlit_app.public_ip}:8501"
}

#Nagios EC2 public IP
output "nagios_ip" {
  description = "Nagios EC2 Public IP"
  value       = aws_instance.nagios_server.public_ip
}

#Nagios Web Interface
output "nagios_url" {
  description = "Nagios Web Interface"
  value       = "http://${aws_instance.nagios_server.public_ip}"
}

# Show ready-to-use SSH command
output "ssh_connection_nagios" {
  description = "SSH command to connect to your EC2 instance"
  value       = "ssh -i ${path.module}/${aws_key_pair.streamlit_keypair.key_name}.pem ubuntu@${aws_instance.nagios_server.public_ip}"
}