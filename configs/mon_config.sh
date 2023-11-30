#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y ceph ceph-mds
sudo touch /etc/ceph/ceph.conf

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

#sudo ssh-keygen -t rsa -f /home/$USER/.ssh/my-ssh-key -C $USER -b 2048 -q -N ""

sudo chmod 600 /home/$USER/.ssh/my-ssh-key
sudo chmod 644 /home/$USER/.ssh/my-ssh-key.pub

sudo ssh-keygen -p -P pass -N '' -f /home/$USER/.ssh/my-ssh-key

UUID=$(uuidgen)
echo -e "[global]\nfsid = $UUID" | sudo tee /etc/ceph/ceph.conf

echo "mon_initial_members = monitor-instance-1" | sudo tee -a /etc/ceph/ceph.conf

IP=$(hostname -I)
echo "mon host = $IP" | sudo tee -a /etc/ceph/ceph.conf

sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chown ceph:ceph /tmp/ceph.mon.keyring

monmaptool --create --add monitor-instance-1 $IP --fsid $UUID /tmp/monmap
sudo mkdir /var/lib/ceph/mon/adm-ceph-monitor-instance-1
sudo -u ceph ceph-mon --mkfs -i monitor-instance-1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

sudo tee -a /etc/ceph/ceph.conf << EOF
public network = 10.204.0.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 2
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1
EOF

sudo chmod 755 /var/lib/ceph
sudo chmod 755 /var/lib/ceph/bootstrap-osd
sudo chmod 755 /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo systemctl start ceph-mon@monitor-instance-1

sudo apt-get install -y firewalld
sudo firewall-cmd --zone=public --add-service=ceph-mon
sudo firewall-cmd --zone=public --add-service=ceph-mon --permanent

sudo ceph -s

