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


resource "aws_security_group" "k8s-sg" {
  name = "k8s-sg"
  
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

resource "aws_instance" "worker-1" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t3.medium"
  key_name = local.key_name
  tags = {
    name = "k8s"
    role = "worker"
    id = "1"
  }
  security_groups =["${aws_security_group.k8s-sg.name}"]
  provisioner "remote-exec" {
    inline = [ "echo 'Wait until SSH is ready'" ]

    connection {
      type = "ssh"
      user = local.ssh_user
      private_key = file(local.private_key_path)
      host = aws_instance.worker-1.public_ip
    }
  }

  provisioner "local-exec" {
    command =  "ansible-playbook -i ${aws_instance.worker-1.public_ip}, --private-key ${local.private_key_path} nginx.yml"
    
  }
}

resource "aws_instance" "worker-2" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t3.medium"
  key_name = local.key_name
  tags = {
    name = "k8s"
    role = "worker"
    id = "2"
  }
  security_groups =["${aws_security_group.k8s-sg.name}"]
  provisioner "remote-exec" {
    inline = [ "echo 'Wait until SSH is ready'" ]

    connection {
      type = "ssh"
      user = local.ssh_user
      private_key = file(local.private_key_path)
      host = aws_instance.worker-2.public_ip
    }
  }

  provisioner "local-exec" {
    command =  "ansible-playbook -i ${aws_instance.worker-2.public_ip}, --private-key ${local.private_key_path} nginx.yml"
    
  }
}


resource "aws_instance" "master" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t3.medium"
  key_name = local.key_name
  tags = {
    name = "k8s"
    role = "master"
    id = "1"
  }
  security_groups =["${aws_security_group.k8s-sg.name}"]
  provisioner "remote-exec" {
    inline = [ "echo 'Wait until SSH is ready'" ]

    connection {
      type = "ssh"
      user = local.ssh_user
      private_key = file(local.private_key_path)
      host = aws_instance.master.public_ip
    }
    
    
  }

  provisioner "local-exec" {
    command =  "ansible-playbook -i ${aws_instance.master.public_ip}, --private-key ${local.private_key_path} nginx.yml"
    
  }
}


output "worker_1_ip" {
  value = aws_instance.worker-1.public_ip
}

output "worker_2_ip" {
  value = aws_instance.worker-2.public_ip
}

output "master_ip" {
  value = aws_instance.master.public_ip
}