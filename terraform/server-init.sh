#! /bin/bash

sudo apt update

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
source ~/.bashrc

# Install Node
nvm install 20

# cd app
npm install
npm run build

# Install PM2
npm install -g pm2
pm2 startup

# Run Node app
PORT=$PORT DB_USER=$DB_USER DB_PASS=$DB_PASS DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_NAME=$DB_NAME pm2 start "$START_COMMAND"
# TODO: Look into https://pm2.io/docs/runtime/best-practices/environment-variables/

# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Configure Caddy
echo "$DOMAIN {
  auto_https off
  file_server
  reverse_proxy localhost:$PORT
}" > /etc/caddy/Caddyfile

# Reload Caddy
systemctl reload caddy

echo "$DOMAIN" >> temp.txt
echo "$PORT" >> temp.txt
echo "$START_COMMAND" >> temp.txt
echo "$DB_HOST" >> temp.txt