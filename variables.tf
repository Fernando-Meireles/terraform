# Define region
variable "region" {
  default = "eu-west-1"
}

# Define VPC network
variable "vpc_name" {
  description = "Name of the site VPC"
  type        = string
  default     = "my-vpc"
}

variable "vpc_cidr" {
  description = "cidr block for the VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "vpc_azs" {
  description = "Availability zones for the VPC"
  type        = list
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "vpc_public_subnets" {
  description = "DMZ subnet"
  type        = list(string)
  default     = ["10.100.101.0/24"]
}

variable "vpc_private_subnets" {
  description = "private subnet"
  type        = list(string)
  default     = ["10.100.1.0/24"]
}

# Define key
variable "key_name" {
  default = "server_key"
}

variable "key_path" {
  default = "~/.ssh/id_rsa.pub"
}


# Define the path for the cloud-config file
variable "cloud_init_path" {
  default = "./content/cloud-init.yaml"
}

# Define instance type
variable "instance_type" {
  default = "t2.micro"
}

# Define data content to send to the server
variable "html_source" {
  default = "./content/index.html"
}

variable "html_destination" {
  description = "Define where do you want to put the html file considering the user. Since I plan on using the ubuntu user, I will chose the ubunto home dir"
  default     = "/home/ubuntu/index.html"
}

variable "server_dir" {
  default = "myserver"
}
