#!/bin/bash

# copy config and keyring from monitor node
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph
scp monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd

# set up osd disks
# /dev/sdb disk
chown ceph. /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
parted --script /dev/sdb 'mklabel gpt'
parted --script /dev/sdb "mkpart primary 0% 100%"
ceph-volume lvm create --data /dev/sdb1

# /dev/sdb disk
chown ceph. /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
parted --script /dev/sdc 'mklabel gpt'
parted --script /dev/sdc "mkpart primary 0% 100%"
ceph-volume lvm create --data /dev/sdc1

echo "Done provisioning $(hostname)"
