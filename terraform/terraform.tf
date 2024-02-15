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
variable "GIT_REPO" {}
variable "NODE_PORT" {}
variable "START_COMMAND" {}
variable "DB_NAME" {}
variable "DB_USER" {}
variable "DB_PASS" {}
variable "DB_PORT" {
  type = string
  default = 5432
}
variable "REGION" {
  type = string
  default = "us-sea" # see https://api.linode.com/v4/regions
}
variable "VPC_SUBNET_IP" {
  type = string
  default = "10.0.0.0/24"
}
variable "DB_PRIVATE_IP" {
  type = string
  default = "10.0.0.3"
}

# Configure the Linode Provider
provider "linode" {
  token = var.LINODE_TOKEN
}

resource "linode_sshkey" "ssh_key" {
  label = "my_ssh_key"
  ssh_key = chomp(file("~/.ssh/id_ed25519.pub"))
}

# Private network (VPC)
resource "linode_vpc" "vpc" {
  label = "${local.app_name}-vpc"
  region = var.REGION
}
resource "linode_vpc_subnet" "vpc_subnet" {
  vpc_id = linode_vpc.vpc.id
  label = "${local.app_name}-vpc-subnet"
  ipv4 = "${var.VPC_SUBNET_IP}"
}

# Application servers
resource "linode_stackscript" "configure_app_server" {
  label = "setup-${local.app_name}-server"
  description = "Sets up the application server"
  script = <<EOF
#! /bin/bash
# <UDF name="GIT_REPO" label="Repo to clone" default="">
# <UDF name="START_COMMAND" label="Command to run to start app" default="">
# <UDF name="NODE_PORT" label="Port where node app is running" default="">
# <UDF name="DB_HOST" label="Database host" default="">
# <UDF name="DB_PORT" label="Database port" default="">
# <UDF name="DB_NAME" label="Database name" default="">
# <UDF name="DB_USER" label="Database username" default="">
# <UDF name="DB_PASS" label="Database password" default="">
# <UDF name="DOMAIN" label="Domain for the application" default="">
echo "$DOMAIN
$GIT_REPO
$START_COMMAND
$NODE_PORT
$DB_HOST
$DB_PORT
$DB_NAME
$DB_USER
$DB_PASS
" > temp.txt
sudo apt update
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$([ -z "$${XDG_CONFIG_HOME-}" ] && printf %s "$${HOME}/.nvm" || printf %s "$${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
source ~/.bashrc
# Install Node
nvm install 20
# Install PM2
npm install -g pm2
pm2 startup
# Build App
git clone "$GIT_REPO" app
cd app
npm install
npm run build
# Run app with env variables
pm2 start "$START_COMMAND"
# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
# Configure Caddy
echo "$DOMAIN {
  file_server
  reverse_proxy localhost:$NODE_PORT
}" > /etc/caddy/Caddyfile
# Reload Caddy
systemctl reload caddy
EOF
  images = ["linode/ubuntu20.04"]
}
resource "linode_instance" "application1" {
  depends_on = [
    linode_instance.database1
  ]
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-application1"
  group = "${local.app_name}-group"
  region = var.REGION
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]

  stackscript_id = linode_stackscript.configure_app_server.id
  stackscript_data = {
    "GIT_REPO" = var.GIT_REPO,
    "START_COMMAND" = var.START_COMMAND,
    "DOMAIN" = var.DOMAIN1,
    "NODE_PORT" = var.NODE_PORT,
    "DB_HOST" = linode_instance.database1.ip_address,
    "DB_PORT" = var.DB_PORT,
    "DB_NAME" = var.DB_NAME,
    "DB_USER" = var.DB_USER,
    "DB_PASS" = var.DB_PASS,
  }
}
resource "linode_instance" "application2" {
  depends_on = [
    linode_instance.database2
  ]
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-application2"
  group = "${local.app_name}-group"
  region = var.REGION
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]

  stackscript_id = linode_stackscript.configure_app_server.id
  stackscript_data = {
    "GIT_REPO" = var.GIT_REPO,
    "START_COMMAND" = var.START_COMMAND,
    "DOMAIN" = var.DOMAIN2,
    "NODE_PORT" = var.NODE_PORT,
    "DB_HOST" = var.DB_PRIVATE_IP,
    "DB_PORT" = var.DB_PORT,
    "DB_NAME" = var.DB_NAME,
    "DB_USER" = var.DB_USER,
    "DB_PASS" = var.DB_PASS,
  }

  interface {
    purpose = "public"
  }
  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.vpc_subnet.id
  }
}

# Database servers
resource "linode_stackscript" "configure_db_server" {
  label = "setup-${local.app_name}-db"
  description = "Sets up the database"
  script = <<EOF
#!/bin/bash
# <UDF name="DB_NAME" label="Database name" default="">
# <UDF name="DB_USER" label="Database user" default="">
# <UDF name="DB_PASS" label="Database password" default="">
# <UDF name="PG_HBA_ENTRY" label="Line to add to pg_hba.conf" example="host all all all md5" default="">
apt update && apt install postgresql -y && systemctl start postgresql.service;
sudo -u postgres createdb $DB_NAME
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS'; GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo "# listen on all interfaces" >> /etc/postgresql/12/main/postgresql.conf
echo "listen_addresses = '*'" >> /etc/postgresql/12/main/postgresql.conf
echo "# allow connections from all hosts" >> /etc/postgresql/12/main/pg_hba.conf
echo "$PG_HBA_ENTRY" >> /etc/postgresql/12/main/pg_hba.conf
sudo systemctl restart postgresql
EOF
  images = ["linode/ubuntu20.04"]
}
resource "linode_instance" "database1" {
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-db1"
  group = "${local.app_name}-group"
  region = var.REGION

  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]
  stackscript_id = linode_stackscript.configure_db_server.id
  stackscript_data = {
    "DB_NAME" = var.DB_NAME,
    "DB_USER" = var.DB_USER,
    "DB_PASS" = var.DB_PASS,
    "PG_HBA_ENTRY" = "host all all all md5"
  }
}
resource "linode_instance" "database2" {
  image = "linode/ubuntu20.04"
  type = "g6-nanode-1"
  label = "${local.app_name}-db2"
  group = "${local.app_name}-group"
  region = var.REGION
  authorized_keys = [ linode_sshkey.ssh_key.ssh_key ]

  stackscript_id = linode_stackscript.configure_db_server.id
  stackscript_data = {
    "DB_NAME" = var.DB_NAME,
    "DB_USER" = var.DB_USER,
    "DB_PASS" = var.DB_PASS,
    "PG_HBA_ENTRY" = "host all all samenet md5"
  }

  interface {
    purpose = "public"
  }
  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.vpc_subnet.id
    ipv4 {
      vpc = var.DB_PRIVATE_IP
    }
  }
}

# Domain/DNS
data "linode_domain" "domain1" {
  domain = var.DOMAIN1
}
data "linode_domain" "domain2" {
  domain = var.DOMAIN2
}
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