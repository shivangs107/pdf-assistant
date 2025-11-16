/*
variables.tf is a separate Terraform file used to declare input variables — values that you can change without editing the 
main Terraform code (main.tf).

Using variables.tf allows you to:
    Reuse the same Terraform configuration for multiple environments (dev, test, prod).
    Keep your code clean (no hardcoded values).
    Pass values dynamically via CLI or .tfvars files.
    Store secrets or paths separately.
*/

variable "aws_region" {
  default = "ap-south-1"
}

variable "docker_image" {
  description = "Docker image to run"
  default     = "shivangs107/pdf-assistant:latest"
}

variable "key_name" {
  description = "Key pair name to create and use"
  default     = "pdfkey"
}