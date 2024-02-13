terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.13.0"
    }
  }
}

# Variables & Data
locals {
  app_name = "tfVpcDemo"
}
variable "LINODE_TOKEN" {}
variable "DOMAIN1" {}
variable "DOMAIN2" {}
variable "PORT" {}
variable "START_COMMAND" {}
variable "DB_NAME" {}
variable "DB_USER" {}
variable "DB_PASS" {}
variable "DB_PORT" {
  type = string
  default = 5432
}
variable "region" {
  type = string
  default = "us-sea" # see https://api.linode.com/v4/regions
}
variable "vpc_subnet_ip" {
  type = string
  default = "10.0.0.0/24"
}

# Configure the Linode Provider
provider "linode" {
  token = var.LINODE_TOKEN
}

data "linode_domain" "domain1" {
  domain = var.DOMAIN1
}
data "linode_domain" "domain2" {
  domain = var.DOMAIN2
}

resource "linode_sshkey" "ssh_key" {
  label = "my_ssh_key"
  ssh_key = chomp(file("~/.ssh/id_ed25519.pub"))
}

# VPC
resource "linode_vpc" "vpc" {
  label = "${local.app_name}-vpc"
  region = var.region
}
resource "linode_vpc_subnet" "vpc_subnet" {
  vpc_id = linode_vpc.vpc.id
  label = "${local.app_name}-vpc-subnet"
  ipv4 = "${var.vpc_subnet_ip}"
}

# VPS
resource "linode_instance" "application1" {
  depends_on = [
    linode_instance.database2
  ]
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-linode1"
  group = "${local.app_name}-group"
  region = var.region
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]
}
resource "linode_instance" "application2" {
  depends_on = [
    linode_instance.database1
  ]
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-linode2"
  group = "${local.app_name}-group"
  region = var.region
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]

  interface {
    purpose = "public"
  }
  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.vpc_subnet.id
    ipv4 {
      vpc = "10.0.0.2"
    }
  }
}

resource "null_resource" "configure_server1" {
  connection {
    type = "ssh"
    user = "root"
    agent = "true"
    host = "${linode_instance.application1.ip_address}"
  }
  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/AustinGil/linode-vpc-demo.git app && cd app",
      # Must use inline env variables
      "START_COMMAND=${var.START_COMMAND} PORT=${var.NODE_PORT} DB_USER=${var.DB_USER} DB_PASS=${var.DB_PASS} DB_HOST=${linode_instance.database1.ip_address} DB_PORT=${var.DB_PORT} DB_NAME=${var.DB_NAME} DOMAIN1=${var.DOMAIN1} bash ./terraform/server-init.sh"
    ]
  }
}
resource "null_resource" "configure_server2" {
  connection {
    type = "ssh"
    user = "root"
    agent = "true"
    host = "${linode_instance.application2.ip_address}"
  }
  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/AustinGil/linode-vpc-demo.git app && cd app",
      # Must use inline env variables
      "START_COMMAND=${var.START_COMMAND} PORT=${var.NODE_PORT} DB_USER=${var.DB_USER} DB_PASS=${var.DB_PASS} DB_HOST=${linode_instance.database2.ip_address} DB_PORT=${var.DB_PORT} DB_NAME=${var.DB_NAME} DOMAIN1=${var.DOMAIN1} bash ./terraform/server-init.sh"
    ]
  }
}

# Domain/DNS
resource "linode_domain_record" "dns_record1" {
  domain_id = "${data.linode_domain.domain1.id}"
  record_type = "A"
  target = "${linode_instance.application1.ip_address}"
}
resource "linode_domain_record" "dns_record2" {
  domain_id = "${data.linode_domain.domain2.id}"
  record_type = "A"
  target = "${linode_instance.application2.ip_address}"
}

# Database
resource "linode_stackscript" "db_setup1" {
  label = "${local.app_name}-db"
  description = "Sets up the database"
  script = <<EOF
#!/bin/bash
apt update && apt install postgresql -y && systemctl start postgresql.service;
sudo -u postgres createdb ${var.DB_NAME}
sudo -u postgres psql -c "CREATE USER ${var.DB_USER} WITH ENCRYPTED PASSWORD '${var.DB_PASS}'; GRANT ALL PRIVILEGES ON DATABASE ${var.DB_NAME} TO ${var.DB_USER};"
echo "listen_addresses = '*'" >> /etc/postgresql/12/main/postgresql.conf 
echo "host all all all md5" >> /etc/postgresql/12/main/pg_hba.conf
sudo systemctl restart postgresql
EOF
  images = ["linode/ubuntu20.04"]
}
resource "linode_stackscript" "db_setup2" {
  label = "${local.app_name}-db"
  description = "Sets up the database"
  script = <<EOF
#!/bin/bash
apt update && apt install postgresql -y && systemctl start postgresql.service;
sudo -u postgres createdb ${var.DB_NAME}
sudo -u postgres psql -c "CREATE USER ${var.DB_USER} WITH ENCRYPTED PASSWORD '${var.DB_PASS}'; GRANT ALL PRIVILEGES ON DATABASE ${var.DB_NAME} TO ${var.DB_USER};"
echo "listen_addresses = '*'" >> /etc/postgresql/12/main/postgresql.conf 
echo "host all all ${var.vpc_subnet_ip} md5" >> /etc/postgresql/12/main/pg_hba.conf
sudo systemctl restart postgresql
EOF
  images = ["linode/ubuntu20.04"]
}

resource "linode_instance" "database1" {
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-db"
  group = "${local.app_name}-group"
  region = var.region
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]
  stackscript_id = linode_stackscript.db_setup.id
}
resource "linode_instance" "database2" {
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-db"
  group = "${local.app_name}-group"
  region = var.region
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]
  stackscript_id = linode_stackscript.db_setup.id

  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.vpc_subnet.id
    ipv4 {
      vpc = "10.0.0.3"
    }
  }
}