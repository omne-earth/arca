#!/bin/bash
set -ueox pipefail
SOURCE="./source"

# pre-requisites
sudo apt update -y
sudo apt install -y ca-certificates curl git

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
