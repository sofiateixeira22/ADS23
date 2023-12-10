#!/bin/bash
# this script is ittentionally left out from running in the mtain.tf
# it's only for reference and documentation to what the machines run
# as a first provisioning step

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

# in theory ceph-mds should not be installed because we are using RBD (block storage) and not CephFS (file storage), which needs the meatadata server (MDS)
# however, not installing it does not install some tools like `ceph-volume` which is used to manage disks on OSD nodes
# ntpsec is used to sync the time between the nodes

# for the client `ceph-common` should be enough to use as RBD client (not tested in our project)
# but for the sake of simplicity we do the same installation for all the vms
# we can also take advantage that docker comes pre-installed

# --no-install-recommends is not used because it will not install the ceph-common package
# nor is able to install ceph-volume afterwards (a tool to manage disks on OSD nodes)
