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

# install guacamole
git clone "https://github.com/boschkundendienst/guacamole-docker-compose.git"
cd guacamole-docker-compose
sudo ./prepare.sh

# set http basic auth stuff
printf 'bt:$2y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu' > nginx/htpasswd
sed -i '/location \//a\    auth_basic "Restricted Area";\n    auth_basic_user_file /etc/nginx/.htpasswd;' nginx/templates/guacamole.conf.template
sed -i '/nginx:/,/volumes:/ {
  /volumes:/a\   - ./nginx/htpasswd:/etc/nginx/.htpasswd:ro
}' docker-compose.yml

sudo docker-compose up -d

# add mitre caldera
git clone https://github.com/mitre/caldera.git --recursive --branch 5.3.0
cd caldera
sudo docker build --build-arg WIN_BUILD=true . -t caldera:server
docker run -d -p 7010:7010 -p 7011:7011/udp -p 7012:7012 -p 8888:8888 caldera:server
