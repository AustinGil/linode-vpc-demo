# Variables & Data
variable "LINODE_TOKEN" {
  sensitive = true
}
variable "REGION" {
  # see https://www.linode.com/docs/products/networking/vpc/#availability
  type = string
}
variable "VPC_SUBNET_IP_RANGE" {
  type = string
  default = "10.0.0.0/24"
}
variable "GIT_REPO" {}
variable "START_COMMAND" {}
variable "NODE_PORT" {
  type = string
  default = "3000"
}
variable "DB_NAME" {
  sensitive = true
}
variable "DB_USER" {
  sensitive = true
}
variable "DB_PASS" {
  sensitive = true
}
variable "DB_PORT" {
  type = string
  default = 5432
  sensitive = true
}
variable "DOMAIN" {}
variable "INSTANCE_TYPE" {
  # see https://api.linode.com/v4/linode/types
  type = string
  default = "g6-nanode-1"
}
variable "DB_SERVER_PRIVATE_IP" {
  type = string
  default = "10.0.0.3"
}
variable "APP_NAME" {
  type = string
  default = "tfVpcDemo"
}
variable "SSH_KEYS" {
  type = set(string)
  default = []
}

# Configure the Linode Provider
terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.13.0"
    }
  }
}
provider "linode" {
  token = var.LINODE_TOKEN
}

# Private network (VPC)
resource "linode_vpc" "vpc" {
  label = "${var.APP_NAME}-vpc"
  region = var.REGION
}
resource "linode_vpc_subnet" "vpc_subnet" {
  vpc_id = linode_vpc.vpc.id
  label = "${var.APP_NAME}-vpc-subnet"
  ipv4 = "${var.VPC_SUBNET_IP_RANGE}"
}

# Application servers
resource "linode_stackscript" "configure_app_server" {
  label = "setup-${var.APP_NAME}-server"
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
resource "linode_instance" "application" {
  depends_on = [
    linode_instance.database
  ]
  image = "linode/ubuntu20.04"
  type = var.INSTANCE_TYPE
  label = "${var.APP_NAME}-application"
  group = "${var.APP_NAME}-group"
  region = var.REGION
  authorized_keys = var.SSH_KEYS

  stackscript_id = linode_stackscript.configure_app_server.id
  stackscript_data = {
    "GIT_REPO" = var.GIT_REPO,
    "START_COMMAND" = var.START_COMMAND,
    "DOMAIN" = var.DOMAIN,
    "NODE_PORT" = var.NODE_PORT,
    "DB_HOST" = var.DB_SERVER_PRIVATE_IP,
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
  label = "setup-${var.APP_NAME}-db"
  description = "Sets up the database"
  script = <<EOF
#!/bin/bash
# <UDF name="DB_NAME" label="Database name" default="">
# <UDF name="DB_USER" label="Database user" default="">
# <UDF name="DB_PASS" label="Database password" default="">
apt update && apt install postgresql -y && systemctl start postgresql.service;
sudo -u postgres createdb $DB_NAME
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS'; GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo "# listen on all interfaces" >> /etc/postgresql/12/main/postgresql.conf
echo "listen_addresses = '*'" >> /etc/postgresql/12/main/postgresql.conf
echo "# allow connections from all hosts" >> /etc/postgresql/12/main/pg_hba.conf
echo "host all all samenet md5" >> /etc/postgresql/12/main/pg_hba.conf
sudo systemctl restart postgresql
EOF
  images = ["linode/ubuntu20.04"]
}
resource "linode_instance" "database" {
  image = "linode/ubuntu20.04"
  type = var.INSTANCE_TYPE
  label = "${var.APP_NAME}-db"
  group = "${var.APP_NAME}-group"
  region = var.REGION
  authorized_keys = var.SSH_KEYS

  stackscript_id = linode_stackscript.configure_db_server.id
  stackscript_data = {
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
    ipv4 {
      vpc = var.DB_SERVER_PRIVATE_IP
    }
  }
}

# Domain/DNS
data "linode_domain" "domain" {
  domain = var.DOMAIN
}
resource "linode_domain_record" "dns_record" {
  domain_id = "${data.linode_domain.domain.id}"
  record_type = "A"
  target = "${linode_instance.application.ip_address}"
}