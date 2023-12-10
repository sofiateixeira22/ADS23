#!/bin/bash

# assumes it's a bullseye/focal distro
# in our case it's a focal - ubuntu 20.04

echo "Installing Ceph on $(hostname)"

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
sudo apt-get update && \
sudo apt-get install -y \
    ntpsec \
    ceph \
    ceph-mds

echo "Finished installing Ceph on $(hostname)"

# for the client `ceph-common` should be enough (not tested in our project)
# but for the sake of simplicity we do the same installation for all the vms
# we can also take advantage that docker comes pre-installed
