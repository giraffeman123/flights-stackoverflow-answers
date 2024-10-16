#!/bin/bash

#Instalacion paquetes necesarios
sudo apt-get update

#nodejs & npm installation
sudo apt-get -y install nodejs
node -v
sudo apt-get -y install npm
npm -v

#we clone api repository and install project dependencies 
cd /home/ubuntu/
git clone https://github.com/giraffeman123/merge-sort-api.git
cd merge-sort-api/
sudo npm install --production

#create directory for app logs
sudo mkdir /var/log/merge-sort-app

#we add the api as a service unit in systemd service manager 
cat > /home/ubuntu/merge-sort-app.service <<EOF
[Unit]
Description=Simple NodeJs App with merge-sort algorithm and other endpoints for testing
After=network.target
[Service]
ExecStart=/usr/bin/node /home/ubuntu/merge-sort-api/index.js
WorkingDirectory=/home/ubuntu/merge-sort-api
Restart=always
User=ubuntu
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Environment=PORT=${app_port}
StandardOutput=file:/var/log/merge-sort-app/logs.log
StandardError=file:/var/log/merge-sort-app/logs.log
[Install]
WantedBy=multi-user.target
EOF

sudo mv /home/ubuntu/merge-sort-app.service /etc/systemd/system/

#create link to nodejs executable
sudo ln -s "$(which node)" /usr/bin/node

#we enable the service, start it and check status
sudo systemctl enable merge-sort-app
sudo systemctl start merge-sort-app
sudo systemctl status merge-sort-app

#install, configure and start cloudwatch agent
mkdir /tmp/cloudwatch-logs && cd /tmp/cloudwatch-logs
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${ssm_cloudwatch_config} -s

#install, configure and start ssm-agent
sudo mkdir /tmp/ssm && cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent
rm amazon-ssm-agent.deb