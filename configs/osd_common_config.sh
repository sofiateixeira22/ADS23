#!/bin/bash

USER=$(logname)

sudo chmod 755 /var/lib/ceph
sudo chmod 755 /var/lib/ceph/bootstrap-osd
sudo touch /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chmod 755 /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo touch /etc/ceph/ceph.conf
sudo chmod 755 /etc/ceph/ceph.conf

sudo touch /etc/ceph/ceph.client.bootstrap-osd.keyring
sudo chmod 777 /etc/ceph/ceph.client.bootstrap-osd.keyring

sudo touch /etc/ceph/ceph.client.admin.keyring
sudo chmod 777 /etc/ceph/ceph.client.admin.keyring

sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring

sudo cp /var/lib/ceph/bootstrap-osd/ceph.keyring /etc/ceph/ceph.client.bootstrap-osd.keyring 

# ssd
sudo ceph-volume lvm create --data /dev/sdb

# hdd
sudo ceph-volume lvm create --data /dev/sdc

sudo ceph-volume lvm list

sudo ceph-volume lvm activate --all
