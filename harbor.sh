#!/bin/bash

#Pre req for Harbor on Ubuntu 18.04

# Housekeeping
apt update -y
swapoff --all
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
ufw disable #do not do this in production
echo "Housekeeping done"

#Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce=5:18.09.9~3-0~ubuntu-bionic
tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
groupadd docker
MAINUSER=$(logname)
usermod -aG docker $MAINUSER
systemctl daemon-reload
systemctl restart docker
echo "Docker Installation done"

#Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "Docker Compose Installation done"

#Install Latest Harbor Release
HARBORVERSION=$(curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar xvf harbor-online-installer-$HARBORVERSION.tgz
ETHIP=$(hostname -I|cut -d" " -f 1)
cd harbor
sed -i "s/reg.mydomain.com/$ETHIP/g" harbor.yml
./install.sh --with-clair --with-chartmuseum
echo "Harbor Installation Complete"
