#!/bin/bash

# install nodejs
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install -y nodejs

# install yarn
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
sudo rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
sudo yum -y install yarn

# theia dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git libX11-devel libxkbfile-devel

git clone https://github.com/eclipse-theia/theia
sudo mv theia /opt
cd /opt/theia
yarn

cat <<EOF >launch_example.sh
#!/bin/bash

cd /opt/theia/examples/browser
yarn run start
EOF
chmod +x launch_example.sh

#create theia service
myuser=$(whoami)
mygroup=$(groups | tr ' ' '\n' | head -n1)

cat <<EOF | sudo tee /etc/systemd/system/theia.service
[Unit]
Description=The theia IDE example
After=network.target
[Service]
Type=simple
User=$myuser
Group=$mygroup
ExecStart=/opt/theia/launch_example.sh
Restart=always
[Install]
WantedBy=multi-user.target
EOF
sudo chmod 600 /etc/systemd/system/theia.service

sudo systemctl daemon-reload
sudo systemctl enable theia
sudo systemctl start theia
