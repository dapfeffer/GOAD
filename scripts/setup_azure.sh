#!/bin/bash

# Install git and python3
sudo apt-get update
sudo apt-get install -y git python3-venv python3-pip

#python3 -m venv .venv
#source .venv/bin/activate

# Install ansible and pywinrm
python3 -m pip install --upgrade pip
python3 -m pip install ansible-core==2.12.6
python3 -m pip install pywinrm

# Install the required ansible libraries
/home/goad/.local/bin/ansible-galaxy install -r /home/goad/GOAD/ansible/requirements.yml

# set color
sudo sed -i '/force_color_prompt=yes/s/^#//g' /home/*/.bashrc
sudo sed -i '/force_color_prompt=yes/s/^#//g' /root/.bashrc

# add guacamole based on autoinstaller
# first download to bootstrap
wget https://raw.githubusercontent.com/itiligent/Guacamole-Install/main/1-setup.sh

# then change config for our environment
sed -i 's/SERVER_NAME=""/SERVER_NAME="jumpbox"/g' 1-setup.sh
sed -i 's/LOCAL_DOMAIN=""/LOCAL_DOMAIN="local"/g' 1-setup.sh
sed -i 's/INSTALL_MYSQL=""/INSTALL_MYSQL="true"/g' 1-setup.sh
sed -i 's/SECURE_MYSQL=""/SECURE_MYSQL="true"/g' 1-setup.sh
sed -i 's/MYSQL_ROOT_PWD=""/MYSQL_ROOT_PWD="supersecretpassword"/g' 1-setup.sh
sed -i 's/GUAC_PWD=""/GUAC_PWD="evenmoresecretpassword"/g' 1-setup.sh
sed -i 's/INSTALL_TOPT=""/INSTALL_TOPT="false"/g' 1-setup.sh
sed -i 's/INSTALL_DUO=""/INSTALL_DUO="false"/g' 1-setup.sh
sed -i 's/INSTALL_LDAP=""/INSTALL_LDAP="false"/g' 1-setup.sh
sed -i 's/INSTALL_QCONNECT=""/INSTALL_QCONNECT="false"/g' 1-setup.sh
sed -i 's/INSTALL_HISTREC=""/INSTALL_HISTREC="false"/g' 1-setup.sh
sed -i 's/GUAC_URL_REDIR=""/GUAC_URL_REDIR="true"/g' 1-setup.sh
sed -i 's/INSTALL_NGINX=""/INSTALL_NGINX="true"/g' 1-setup.sh
sed -i 's/SELF_SIGN=""/SELF_SIGN="true"/g' 1-setup.sh

# first we need to install nginx as the script is not able to do it
sudo apt-get install -y nginx

# then we run the script
chmod +x 1-setup.sh

./1-setup.sh


# install docker
# https://docs.docker.com/engine/install/ubuntu/
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
#
# # Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

