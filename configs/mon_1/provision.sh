#!/bin/bash

# set envs
CLUSTER_UUID=$(uuidgen)
IP=$(hostname -i)
SUBNET='10.204.0.0/20'

# Create the ceph.conf file
sudo tee -a /etc/ceph/ceph.conf << EOF
[global]
fsid = $CLUSTER_UUID
mon_initial_members = monitor-instance-1
mon host = $IP
cluster network = $SUBNET
public network = $SUBNET
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 2
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1

[mon.monitor-instance-1]
host = monitor-instance-1
mon addr = $IP
mon allow pool delete = true
EOF


# create keyrings
# monitor secret key
ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
# client.admin
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
# client.bootstrap-osd
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
# add generated keys to the monitor keyring
sudo ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

# generate a monitor map
sudo monmaptool --create --add monitor-instance-1 $IP --fsid $CLUSTER_UUID /etc/ceph/monmap

# Create a default data directory for the monitor
sudo -u ceph mkdir /var/lib/ceph/mon/ceph-monitor-instance-1

# give ceph user perms
chown ceph. /etc/ceph/ceph.*
chown -R ceph. /var/lib/ceph/mon/ceph-monitor-instance-1 /var/lib/ceph/bootstrap-osd

# Populate the monitor daemon(s) with the monitor map and keyring
sudo -u ceph ceph-mon --cluster ceph --mkfs -i monitor-instance-1 --monmap /etc/ceph/monmap --keyring /etc/ceph/ceph.mon.keyring

# start service
sudo systemctl enable --now ceph-mon@monitor-instance-1

echo "Done provisioning $(hostname)"
