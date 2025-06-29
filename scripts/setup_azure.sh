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

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# install guacamole
git clone "https://github.com/boschkundendienst/guacamole-docker-compose.git"
cd guacamole-docker-compose
sudo ./prepare.sh

# set http basic auth stuff
printf 'bt:$2y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu\n' > nginx/htpasswd
printf 'bt1:$3y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu\n' >> nginx/htpasswd
printf 'bt2:$2y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu\n' >> nginx/htpasswd
printf 'bt3:$2y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu\n' >> nginx/htpasswd
printf 'bt4:$2y$05$GHyrkppsBzm5/wG/DSzrIOCoYeH6NnYJKtxfcif3RI/jIB4YuTRXu' >> nginx/htpasswd
sed -i '/location \//a\    auth_basic "Restricted Area";\n    auth_basic_user_file /etc/nginx/.htpasswd;' nginx/templates/guacamole.conf.template
sed -i '/nginx:/,/volumes:/ {
  /volumes:/a\   - ./nginx/htpasswd:/etc/nginx/.htpasswd:ro
}' docker-compose.yml

# change https port
sed -i 's/8443:443/443:443/g' docker-compose.yml

sudo docker compose up -d

# add mitre caldera
cd ..
git clone https://github.com/mitre/caldera.git --recursive --branch 5.3.0
cd caldera
sudo docker build --build-arg WIN_BUILD=true . -t caldera:server
sudo docker run -d -p 7010:7010 -p 7011:7011/udp -p 7012:7012 -p 8888:8888 --name caldera_server caldera:server

# to get completly hardcore, install gui and rdp to connect through guacamole
sudo DEBIAN_FRONTEND=noninteractive apt install lubuntu-desktop xrdp firefox remmina sshpass -y
echo "allowed_users=anybody" | sudo tee /etc/X11/Xwrapper.config
sudo systemctl start xrdp
sudo systemctl enable xrdp

# some stuff to repair xrdp
echo "startlxqt" | sudo tee /etc/skel/.xsession
echo "startlxqt" > ~/.xsession

sudo systemctl restart xrdp

# create user and set passw and add to sudoers
sudo adduser --disabled-password --gecos "" bt
sudo usermod --password '$6$THyM9QYqPV2VG50g$oysqHTh/Afal6EerYY807tLrhndMOPkZ3AJcuJS3nuLRuw5fr3MGDPtahfyx3F5ZIE/kdUEEkta0jtzg/2A0l0' bt
sudo usermod -aG sudo bt
# copy .ssh authorized users
sudo cp -r /home/goad/.ssh /home/bt/
sudo chown bt:bt /home/bt/.ssh

sudo adduser --disabled-password --gecos "" rt
sudo usermod --password '$6$THyM9QYqPV2VG50g$oysqHTh/Afal6EerYY807tLrhndMOPkZ3AJcuJS3nuLRuw5fr3MGDPtahfyx3F5ZIE/kdUEEkta0jtzg/2A0l0' rt
# copy .ssh authorized users
sudo cp -r /home/goad/.ssh /home/rt/
sudo chown bt:bt /home/rt/.ssh

# paste caldera output to bt-file to give him pw
sudo docker logs caldera_server | sudo tee /home/bt/caldera.txt
sudo chown bt:bt /home/bt/caldera.txt

# setup dfir-iris
git clone https://github.com/dfir-iris/iris-web.git
cd iris-web
git checkout v2.4.22
cp .env.model .env
sed -i 's/__MUST_BE_CHANGED__/__MUST_BE_CHANGED__OK_NOW_THIS_IS_CHANGED__/g' .env
sed -i 's/INTERFACE_HTTPS_PORT=443/INTERFACE_HTTPS_PORT=8443/g' .env
sudo docker compose pull
sudo docker compose up -d
sudo docker logs | sudo tee /home/bt/dfir-iris.txt
cd ..
