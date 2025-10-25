#!/bin/bash
set -ueox pipefail
SOURCE="./source"
RELEASE="sysbox-ce_0.6.7.linux_amd64.deb"

# pre-requisites
sudo apt update -y
sudo apt install -y ca-certificates curl git

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
curl -Lo "${SOURCE}/sysbox/pkg/${RELEASE}" "https://github.com/nestybox/sysbox/releases/download/v0.6.7/${RELEASE}"
ls "${SOURCE}/sysbox/pkg/${RELEASE}" | xargs -I {} sudo apt install -y "${SOURCE}/sysbox/pkg/${RELEASE}"

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

# clean
rm -rf "${SOURCE}/sysbox/"

# setup system
sudo systemctl enable --now sysbox-fs.service sysbox-mgr.service sysbox.service
sudo systemctl daemon-reload
sudo systemctl restart docker

