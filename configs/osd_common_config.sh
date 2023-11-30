#!/bin/bash
#sudo apt-get update -y
#sudo apt-get install -y ceph ceph-mds 

USER=$(logname)

sudo chmod +x /home/$USER/.ssh

sudo touch /home/$USER/.ssh/my-ssh-key
sudo touch /home/$USER/.ssh/my-ssh-key.pub

sudo tee -a /home/$USER/.ssh/my-ssh-key << EOF
myprivkey
EOF

sudo tee -a /home/$USER/.ssh/my-ssh-key.pub << EOF
ssh-rsa mypubkey
EOF

# sudo ssh-keygen -t rsa -f /home/$USER/.ssh/my-ssh-key -C $USER -b 2048 -q -N ""

sudo chmod 600 /home/$USER/.ssh/my-ssh-key
sudo chmod 644 /home/$USER/.ssh/my-ssh-key.pub

sudo ssh-keygen -p -P pass -N '' -f /home/$USER/.ssh/my-ssh-key

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
