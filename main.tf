terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

# get the most recent ubuntu-18-server AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# use the module from the previous exercise
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                = var.vpc_azs
  public_subnets     = var.vpc_public_subnets
  private_subnets    = var.vpc_private_subnets
  enable_nat_gateway = true
}

# create the security group for the bastion
resource "aws_security_group" "bastion" {
  name   = "sg_22"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH access to the infra"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound for the server"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion_sg"
  }
}

# create the security group for the http_server
resource "aws_security_group" "http_server" {
  name   = "sg_80"
  vpc_id = module.vpc.vpc_id

  ingress {
    description       = "SSH access from bastion sg"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_groups   = [aws_security_group.bastion.id]
  }
  ingress {
    description = "HTTP for Webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS for Webserver"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound for the server"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webserver_sg"
  }
}

# create the security group for the backend srv
resource "aws_security_group" "backend" {
  name   = "sg_priv"
  vpc_id = module.vpc.vpc_id

  ingress {
    description       = "SSH access from bastion sg"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_groups   = [aws_security_group.bastion.id]
  }
  egress {
    description = "Outbound for the server"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block] # connect only inside the vpc
  }

  tags = {
    Name = "Backend_sg"
  }
}


# create a new key-pair for further association
resource "aws_key_pair" "server" {
  key_name   = var.key_name
  public_key = file(var.key_path)
}

# add content from the cloud-init
data "template_file" "server_init" {
  template = file(var.cloud_init_path)
}

# using file, remote execution and connection
resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  user_data                   = data.template_file.server_init.rendered
  vpc_security_group_ids      = [aws_security_group.http_server.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  connection {
    type                = "ssh"
    host                = self.private_ip #omg why am I so stupid!
    user                = "ubuntu"
    bastion_host        = aws_instance.bastion.public_ip
    bastion_host_key    = file(var.key_path)
    bastion_user        = "ubuntu"
    bastion_private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /home/ubuntu/myserver/",
      "mkdir /home/ubuntu/myCA/",
      "openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj '/C=CH/ST=Geneva/L=Geneva/O=Test WS/OU=IT/CN=example.com' ",
      "cp server.key server.key.org",
      "openssl rsa -in server.key.org -out server.key",
      "openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt",
      "cp server.key server.crt /home/ubuntu/myCA/",
    ]
  }

  provisioner "file" {
    source      = var.html_source
    destination = "/home/ubuntu/myserver/index.html"
  }

  tags = {
    Name = "WebServer"
  }
}


# create the ssh bastion
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
  }

  provisioner "file" {
    source = "~/.ssh/id_rsa"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 600 ~/.ssh/id_rsa",
    ]
  }

  tags = {
    Name = "bastion"
  }
}

# create the backend server
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.backend.id]
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false

  tags = {
    Name = "backend"
  }
}
