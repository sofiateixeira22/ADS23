#!/bin/bash
sudo chmod 422 /var/lib/ceph
sudo chmod 422 /var/lib/ceph/mgr
sudo mkdir /var/lib/ceph/mgr/ceph-manager-instance-1
sudo chmod 777 /var/lib/ceph/mgr/ceph-manager-instance-1
sudo touch /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
sudo chmod 777 /var/lib/ceph/mgr/ceph-manager-instance-1/keyring

USER=$(logname)

#sudo iptables -A INPUT -i ens4 -m multiport -p tcp -s 10.204.0.0/20 --dports 6800:7300 -j ACCEPT
sudo chmod 733 /var/lib/ceph/bootstrap-osd
sudo touch /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chmod 733 /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo chmod 777 /etc/ceph
sudo touch /etc/ceph/ceph.conf
sudo chmod 777 /etc/ceph/ceph.conf

sudo touch /etc/ceph/ceph.client.admin.keyring
sudo chmod 777 /etc/ceph/ceph.client.admin.keyring

sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/var/lib/ceph/mgr/ceph-manager-instance-1/keyring /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring

sudo ceph-mgr -i manager-instance-1
sudo ceph status