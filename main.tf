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


resource "aws_security_group" "sg" {
  name = "sg"
  
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

resource "aws_instance" "worker" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name = local.key_name

  security_groups =["${aws_security_group.sg.name}"]
  provisioner "remote-exec" {
    inline = [ "echo 'Wait until SSH is ready'" ]

    connection {
      type = "ssh"
      user = local.ssh_user
      private_key = file(local.private_key_path)
      host = aws_instance.worker.public_ip
    }
  }

  provisioner "local-exec" {
    command =  "ansible-playbook -i ${aws_instance.worker.public_ip}, --private-key ${local.private_key_path} nginx.yml"
    
  }
}


output "worker_ip" {
  value = aws_instance.worker.public_ip
}
