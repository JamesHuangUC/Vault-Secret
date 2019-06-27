variable "dockerami" {
    type = "string"
    default = "ami-05edd4ca34b25f722"
}


provider "aws" {
  region     = "us-east-1"
}


resource "aws_instance" "consul-server-1" {
  availability_zone = "us-east-1a"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Consul Server 1"
  }
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-server-1.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "docker run --name=consulserver1 --net=host -e CONSUL_BIND_INTERFACE=eth0 -e CONSUL_CLIENT_INTERFACE=eth0 -e CONSUL_HTTP_ADDR=${aws_instance.consul-server-1.private_ip}:8500 -d consul agent -ui -server -bootstrap-expect=3"
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul server1 public ip: ${aws_instance.consul-server-1.public_ip}
      echo consul server1 private ip: ${aws_instance.consul-server-1.private_ip}
    EOT
  }
}

resource "aws_instance" "consul-server-2" {
  availability_zone = "us-east-1b"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Consul Server 2"
  }

  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-server-2.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "docker run --name=consulserver2 --net=host -e CONSUL_BIND_INTERFACE=eth0 -e CONSUL_CLIENT_INTERFACE=eth0 -e CONSUL_HTTP_ADDR=${aws_instance.consul-server-2.private_ip}:8500 -d consul agent -ui -server -join ${aws_instance.consul-server-1.public_ip} -bootstrap-expect=3"    
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul server2 public ip: ${aws_instance.consul-server-2.public_ip}
      echo consul server2 private ip: ${aws_instance.consul-server-2.private_ip}
    EOT
  }
}

resource "aws_instance" "consul-server-3" {
  availability_zone = "us-east-1c"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Consul Server 3"
  }

  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-server-3.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "docker run --name=consulserver3 --net=host -e CONSUL_BIND_INTERFACE=eth0 -e CONSUL_CLIENT_INTERFACE=eth0 -e CONSUL_HTTP_ADDR=${aws_instance.consul-server-3.private_ip}:8500 -d consul agent -ui -server -join ${aws_instance.consul-server-1.public_ip} -bootstrap-expect=3"    
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul server3 public ip: ${aws_instance.consul-server-3.public_ip}
      echo consul server3 private ip: ${aws_instance.consul-server-3.private_ip}
    EOT
  }
}

resource "aws_instance" "consul-client-1" {
  availability_zone = "us-east-1a"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Consul Client 1"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul client1 public ip: ${aws_instance.consul-client-1.public_ip}
      echo consul client1 private ip: ${aws_instance.consul-client-1.private_ip}
      echo {\"api_addr\": \"http://${aws_instance.consul-client-1.private_ip}:8200\", \"backend\": { \"consul\": { \"address\": \"127.0.0.1:8500\", \"path\": \"vault/\" }}, \"cluster_addr\": \"https://${aws_instance.consul-client-1.private_ip}:8201\", \"default_lease_ttl\": \"168h\", \"listener\": { \"tcp\": { \"address\": \"0.0.0.0:8200\", \"cluster_address\": \"${aws_instance.consul-client-1.private_ip}:8201\", \"tls_disable\": \"true\" } }, \"max_lease_ttl\": \"720h\" } > vault-conf.json
    EOT
  }
  provisioner "file" {
    connection {
      host = "${aws_instance.consul-client-1.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    source      = "vault-conf.json"
    destination = "/tmp/vault-conf.json"
  }
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-client-1.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "mkdir -p /home/ubuntu/myvault/config",
      "mv /tmp/vault-conf.json /home/ubuntu/myvault/config/",
      "docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp  -p 8500:8500 -p 53:8600/udp --name consul-agent1 consul agent -advertise ${aws_instance.consul-client-1.public_ip} -join ${aws_instance.consul-server-1.public_ip} -client 0.0.0.0",
      "docker run -d --net=host --cap-add=IPC_LOCK -e VAULT_ADDR='http://127.0.0.1:8200' -v /home/ubuntu/myvault/config:/vault/config vault server"
    ]
  }
}

resource "aws_instance" "consul-client-2" {
  availability_zone = "us-east-1b"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Consul Client 2"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul client2 public ip: ${aws_instance.consul-client-2.public_ip}
      echo consul client2 private ip: ${aws_instance.consul-client-2.private_ip}
      echo {\"api_addr\": \"http://${aws_instance.consul-client-2.private_ip}:8200\", \"backend\": { \"consul\": { \"address\": \"127.0.0.1:8500\", \"path\": \"vault/\" }}, \"cluster_addr\": \"https://${aws_instance.consul-client-2.private_ip}:8201\", \"default_lease_ttl\": \"168h\", \"listener\": { \"tcp\": { \"address\": \"0.0.0.0:8200\", \"cluster_address\": \"${aws_instance.consul-client-2.private_ip}:8201\", \"tls_disable\": \"true\" } }, \"max_lease_ttl\": \"720h\" } > vault-conf.json
    EOT
  }
  provisioner "file" {
    connection {
      host = "${aws_instance.consul-client-2.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    source      = "vault-conf.json"
    destination = "/tmp/vault-conf.json"
  }
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-client-2.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "mkdir -p /home/ubuntu/myvault/config",
      "mv /tmp/vault-conf.json /home/ubuntu/myvault/config/",
      "docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp  -p 8500:8500 -p 53:8600/udp --name consul-agent2 consul agent -advertise ${aws_instance.consul-client-2.public_ip} -join ${aws_instance.consul-server-1.public_ip} -client 0.0.0.0",
      "docker run -d --net=host --cap-add=IPC_LOCK -e VAULT_ADDR='http://127.0.0.1:8200' -v /home/ubuntu/myvault/config:/vault/config vault server"
    ]
  }
}

resource "aws_instance" "consul-client-3" {
  availability_zone = "us-east-1c"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Jenkins"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul client3 public ip: ${aws_instance.consul-client-3.public_ip}
      echo consul client3 private ip: ${aws_instance.consul-client-3.private_ip}
    EOT
  }
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-client-3.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp  -p 8500:8500 -p 53:8600/udp --name consul-agent3 consul agent -advertise ${aws_instance.consul-client-3.public_ip} -join ${aws_instance.consul-server-1.public_ip} -client 0.0.0.0",
      "docker run -d -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts"
    ]
  }
}

resource "aws_instance" "consul-client-4" {
  availability_zone = "us-east-1c"
  ami           = "${var.dockerami}"
  instance_type = "t2.micro"
  key_name = "james-IAM-keypair"
  security_groups = ["Consul Security Group"]
  tags = {
    Name = "Packer Nodejs"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo consul client4 public ip: ${aws_instance.consul-client-4.public_ip}
      echo consul client4 private ip: ${aws_instance.consul-client-4.private_ip}
    EOT
  }
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.consul-client-4.public_ip}"
      type     = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/james-IAM-keypair.pem")}"
      timeout = "1m"
    }
    inline = [
      "docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp  -p 8500:8500 -p 53:8600/udp --name consul-agent3 consul agent -advertise ${aws_instance.consul-client-4.public_ip} -join ${aws_instance.consul-server-1.public_ip} -client 0.0.0.0",
      "docker pull node:10"
    ]
  }
}
