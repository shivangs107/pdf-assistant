# Generate an RSA private key
/*
Uses Terraform’s tls provider to generate a new RSA key pair — entirely locally, 
not in AWS.
This means Terraform will create both:
    a private key (kept locally), and
    a public key (which will later be uploaded to AWS).
*/
resource "tls_private_key" "streamlit_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the public key
/*
Creates a new key pair in AWS EC2, but only uploads the public key.
AWS stores this public key, and any EC2 instance launched with this key name will accept 
SSH access from your corresponding private key.
*/
resource "aws_key_pair" "streamlit_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.streamlit_key.public_key_openssh
}

# Save the private key locally
/*
This block saves the private key locally on your computer as a .pem file — so you can use it 
later to SSH into your EC2 instance.
*/
resource "local_file" "private_key_pem" {
  content  = tls_private_key.streamlit_key.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}
