#!/bin/bash
# assumes it's a bullseye/focal distro
# in our case it's a focal - ubuntu 20.04

echo "Installing Ceph on $(hostname)"
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt update
apt install -y \
    ntpsec \
    ceph \
    ceph-mds
echo "Finished installing Ceph on $(hostname)"
