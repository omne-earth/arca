#!/bin/bash
set -ueox pipefail
SOURCE="./source"

# pre-requisites
sudo apt update -y
sudo apt install -y ca-certificates curl git vim

# add docker to keyring
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y

# purge docker
mv -f "${HOME}/.docker/" "${HOME}/.docker.bak/" || true
sudo mv -f "/etc/docker/daemon.json" "/etc/docker/daemon.json.bak" || true
sudo systemctl stop docker docker.socket || true
sudo systemctl disable docker docker.socket || true
sudo rm -rf "/var/run/docker.sock" "${HOME}/.docker/"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc;
  do sudo apt-get remove "${pkg}";
done
sudo apt remove -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin || true
sudo apt auto-remove -y

# install docker
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin

# setup group and user
sudo groupadd docker || true
sudo usermod -aG docker "${USER}" || true
sudo systemctl enable --now docker
sleep 10
sudo chmod 666 "/var/run/docker.sock"
sudo systemctl restart docker

# remove containers, required by sysbox
docker stop $(docker ps -a -q) || true
docker rm $(docker ps -a -q) || true

# purge sysbox
sudo systemctl stop sysbox-fs.service sysbox-mgr.service sysbox.service || true
sudo systemctl disable sysbox-fs.service sysbox-mgr.service sysbox.service || true
sudo apt remove -y sysbox-ce || true
sudo apt auto-remove -y
sudo apt update -y

# install sysbox
rm -rf "${SOURCE}/sysbox/"
mkdir -p "${SOURCE}/sysbox/pkg/"
wget -P "${SOURCE}/sysbox/pkg/" "https://github.com/nestybox/sysbox/releases/download/v0.6.7/sysbox-ce_0.6.7.linux_amd64.deb"
ls "${SOURCE}/sysbox/pkg/" | xargs -I {} sudo apt install -y "${SOURCE}/sysbox/pkg/{}"

# sysbox patch for zfs
if [ $(docker info | grep "Storage Driver" | cut -d ":" -f 2 | xargs -I {} echo {}) == "zfs" ]; then
  sudo apt install -y vim make build-essential golang-go
  mkdir -p "${SOURCE}/sysbox/git/"
  git clone --recursive https://github.com/nestybox/sysbox.git "${SOURCE}/sysbox/git/"
  sed -i '/0x65735546/i\        0x2fc12fc1: "zfs",' "${SOURCE}/sysbox/git/sysbox-libs/utils/fs.go"
  cd "${SOURCE}/sysbox/git"
  make sysbox-static
  sudo make install
fi
sudo systemctl enable sysbox-fs.service sysbox-mgr.service sysbox.service
sudo systemctl start sysbox-fs.service sysbox-mgr.service sysbox.service
sudo systemctl daemon-reload
sudo systemctl restart docker
rm -rf "${SOURCE}/sysbox/"
