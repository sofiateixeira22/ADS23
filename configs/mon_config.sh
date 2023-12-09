#!/bin/bash
sudo touch /etc/ceph/ceph.conf
sudo chmod 777 /etc/ceph
sudo chmod 777 /etc/ceph/ceph.conf

USER=$(logname)
UUID=$(uuidgen)
IP=$(hostname -I)

sudo tee -a /etc/ceph/ceph.conf << EOF
[global]
fsid = $UUID
mon_initial_members = monitor-instance-1
mon host = $IP
public network = 10.204.0.0/20
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 2
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1

[mon]
host = monitor-instance-1
mon_addr = $IP
mon_data = /var/lib/ceph/mon/ceph-monitor-instance-1

[osd.0]
host = osd-instance-1 
keyring = /etc/ceph/ceph.client.bootstrap-osd.keyring

[osd.1]
host = osd-instance-2
keyring = /etc/ceph/ceph.client.bootstrap-osd.keyring

[mgr]
host = manager-instance-1
keyring = /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
EOF

# monitor keyring directory
sudo chmod 777 /tmp
sudo touch /tmp/ceph.mon.keyring
sudo chmod 777 /tmp/ceph.mon.keyring

# client admin keyring directory
sudo touch /etc/ceph/ceph.client.admin.keyring
sudo chmod 777 /etc/ceph/ceph.client.admin.keyring

# create client admin and osd bootstrap keyrings
sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chown ceph:ceph /tmp/ceph.mon.keyring

# create monmap
monmaptool --create --add monitor-instance-1 $IP --fsid $UUID /tmp/monmap
sudo mkdir /var/lib/ceph/mon/ceph-monitor-instance-1
sudo chmod 777 /var/lib/ceph
sudo chmod 777 /var/lib/ceph/mon
sudo chmod 777 /var/lib/ceph/mon/ceph-monitor-instance-1
sudo -u ceph ceph-mon --mkfs -i monitor-instance-1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

sudo systemctl start ceph-mon@monitor-instance-1

sudo apt-get install -y firewalld
sudo firewall-cmd --zone=public --add-service=ceph-mon
sudo firewall-cmd --zone=public --add-service=ceph-mon --permanent

sudo ceph -s



# directories/files for bootstrap osd keyring
sudo chmod 777 /var/lib/ceph/bootstrap-osd
sudo chmod 777 /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo touch /etc/ceph/ceph.client.bootstrap-osd.keyring
sudo cp /var/lib/ceph/bootstrap-osd/ceph.keyring /etc/ceph/ceph.client.bootstrap-osd.keyring


# directories/files for mgr keyring
sudo chmod 777 /var/lib/ceph/mgr
sudo mkdir /var/lib/ceph/mgr/ceph-manager-instance-1
sudo chmod 777 /var/lib/ceph/mgr/ceph-manager-instance-1
sudo touch /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
sudo chmod 777 /var/lib/ceph/mgr/ceph-manager-instance-1/keyring 

# create mgr keyring
sudo ceph auth get-or-create mgr.manager-instance-1 mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /var/lib/ceph/mgr/ceph-manager-instance-1/keyring


# directories/files for client keyring
sudo touch /etc/ceph/ceph.client.client-instance-1.keyring
sudo chmod 777 /etc/ceph/ceph.client.client-instance-1.keyring

# create client keyring
sudo ceph auth get-or-create client.client-instance-1 mon 'profile rbd' osd 'profile rbd pool=pool_test_ads' mgr 'profile rbd pool=pool_test_ads' > /etc/ceph/ceph.client.client-instance-1.keyring
