#!/bin/bash

# mount local disk for backups
# parted --script /dev/sdb 'mklabel gpt'
# parted --script /dev/sdb "mkpart primary 0% 100%"
# mkfs.xfs /dev/sdb1
# mkdir /mnt/ceph-backup
# mount /dev/sdb1 /mnt/ceph-backup

# copy config and keyring from monitor node
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph/
chown ceph. /etc/ceph/ceph.*

# create default RBD pool [rbd]
ceph osd pool create rbd 64
# enable Placement Groups auto scale mode
ceph mgr module enable pg_autoscaler
ceph osd pool set rbd pg_autoscale_mode on

# initialize the pool
rbd pool init rbd

# create a block device with 10GB
rbd create --size 20G --pool rbd rbd01

# map block device
rbd map rbd01

# show it, /dev/rbd0 is expected
# rbd showmapped

# format with XFS
mkfs.xfs /dev/rbd0

# mount block device
mkdir /mnt/rbd
mount /dev/rbd0 /mnt/rbd

echo "Done provisioning $(hostname)"

## delete block device instructions
## unmap
# rbd unmap /dev/rbd/rbd/rbd01
## delete a block device
# rbd rm rbd01 -p rbd
## delete a pool
## ceph osd pool delete [Pool Name] [Pool Name] ***
# ceph osd pool delete rbd rbd --yes-i-really-really-mean-it
