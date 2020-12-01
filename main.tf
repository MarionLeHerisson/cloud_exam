provider "aws" {
    profile                 = "default"       # nom du profil dans $HOME/.aws/credentials
    region                  = "eu-west-3"
    shared_credentials_file = "$HOME/.aws/credentials"
}

resource "aws_instance" "ubuntu_instance" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    user_data     = file("myUserData.sh")
  
    subnet_id = aws_subnet.ubuntu_subnet_public.id    # Security Group
    vpc_security_group_ids = [aws_security_group.ssh-allowed.id]    # the Public SSH key
    key_name = aws_key_pair.my-awesome-key-pair.id
    
    connection {
        user = "ubuntu"
        private_key = file("my-awesome-key-pair")
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_vpc" "prod-vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = "true"
    enable_dns_hostnames = "true"
    enable_classiclink   = "false"
    instance_tenancy     = "default"
}

resource "aws_subnet" "ubuntu_subnet_public" {
    vpc_id                  = aws_vpc.prod-vpc.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "eu-west-3b"
}

resource "aws_lb" "test_lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.ubuntu_subnet_public.*.id
  
  enable_deletion_protection = false
}

// Sends your public key to the instance
resource "aws_key_pair" "my-awesome-key-pair" {
    key_name   = "my-awesome-key-pair"
    public_key = file("my-awesome-key-pair.pub")
}

output "image_id" {
    value = data.aws_ami.ubuntu.id
}

