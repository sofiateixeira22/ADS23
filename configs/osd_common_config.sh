#!/bin/bash

USER=$(logname)

sudo chmod 755 /var/lib/ceph
sudo chmod 755 /var/lib/ceph/bootstrap-osd
sudo touch /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chmod 755 /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo touch /etc/ceph/ceph.conf
sudo chmod 755 /etc/ceph/ceph.conf

sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/my-ssh-key $USER@monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/my-ssh-key $USER@monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf

# ssd
sudo ceph-volume lvm create --data /dev/sdb

# hdd
sudo ceph-volume lvm create --data /dev/sdc

sudo touch ceph_lvm_list.txt
sudo ceph-volume lvm list

#sudo ceph-volume lvm list >> ceph_lvm_list.txt 
#osd_fsid=$(grep "osd fsid" "ceph_lvm_list.txt" | awk '{print $14}')
#osd_id=$(grep "osd id" "ceph_lvm_list.txt" | awk '{print $15}')
#sudo ceph-volume lvm activate $osd_id $osd_fsid

sudo ceph-volume lvm activate --all
