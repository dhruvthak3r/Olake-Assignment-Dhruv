provider "aws" {
  profile = "olake-assignment"
  region = "ap-south-1"
}


data "aws_vpc" "default" {
  default = true
}


resource "aws_instance" "OLake" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.olake-security-group.id]
  key_name = var.olake_ssh
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted = true
  }

  provisioner "file" {
    source = "./setup.sh"
    destination = "/home/ubuntu/setup.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("olake-ssh.pem")
      host = self.public_ip
    }

  }

  provisioner "remote-exec" {
      inline = [ 
        "chmod +x /home/ubuntu/setup.sh",
        "sudo /home/ubuntu/setup.sh"
      ]

      connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file("olake-ssh.pem")
        host        = self.public_ip
      }
    }


  tags = {
    Name = "Olake-Assignment-Dhruv"
  }

}




resource "aws_security_group" "olake-security-group" {
    name = "olake-security-group"
    description = "Security group for Olake assignment"
    vpc_id = data.aws_vpc.default.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "public_ip" {
  value = aws_instance.OLake.public_ip
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
  registries = [ {
    url = "https://datazip-inc.github.io/olake-helm"
    username = "admin"
    password = "password"
  } ]
}


resource "helm_release" "olake_release" {
  name = "olake"
  repository = "https://datazip-inc.github.io/olake-helm"
  chart = "olake/olake"
  
  values = [file("${path.module}/values.yaml")]
  
}


