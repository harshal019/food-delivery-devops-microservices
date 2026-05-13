# Get latest Amazon Linux 2 AMI (NO HARDCODE – use data source)
# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# Key Pair
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file(var.ssh_public_key_path)
  tags       = { env = var.env, Project = var.project_name }
}

# EC2 Instance
resource "aws_instance" "jenkins" {
  ami           = var.ami_id # dynamic, no hardcode
  instance_type = var.instance_type

  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.jenkins_security_group_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins_key.key_name
  iam_instance_profile        = var.jenkins_instance_profile

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name      = "${var.project_name}-jenkins-${var.env}"
    env       = var.env
    Role      = "jenkins"
    ManagedBy = "Terraform"
  }
}

# Elastic IP
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-jenkins-eip-${var.env}"
    env  = var.env
  }
}

