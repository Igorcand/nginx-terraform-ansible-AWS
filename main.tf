locals {
  ssh_user = "ubuntu"
  key_name = "terraform-ansible"
  private_key_path = "terraform-ansible.pem"
}


terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.34.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}


resource "aws_security_group" "nginx" {
  name = "nginx_access2"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

} 

resource "aws_instance" "nginx" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name = local.key_name
  tags = {
    name = "k8s"
    type = "worker"
  }
  security_groups =["${aws_security_group.nginx.name}"]
  provisioner "remote-exec" {
    inline = [ "echo 'Wait until SSH is ready'" ]

    connection {
      type = "ssh"
      user = local.ssh_user
      private_key = file(local.private_key_path)
      host = aws_instance.nginx.public_ip
    }
    
  }

  provisioner "local-exec" {
    command =  "ansible-playbook -i ${aws_instance.nginx.public_ip}, --private-key ${local.private_key_path} -v nginx.yml"
    
  }
}

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
  
}