#!/bin/bash
sudo touch /etc/ceph/ceph.conf
sudo chmod 755 /etc/ceph/ceph.conf

sudo touch /etc/ceph/ceph.client.client-instance-1.keyring
sudo chmod 777 /etc/ceph/ceph.client.client-instance-1.keyring

USER=$(logname)

sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring
sudo scp -o StrictHostKeyChecking=no -i /home/$USER/.ssh/id_ed25519 $USER@monitor-instance-1:/etc/ceph/ceph.client.client-instance-1.keyring /etc/ceph/ceph.client.client-instance-1.keyring

sudo chown ceph. /etc/ceph/ceph.*

sudo ceph osd pool create rbd 64
sudo ceph mgr module enable pg_autoscaler
sudo ceph osd pool set rbd pg_autoscale_mode on
sudo rbd pool init rbd
sudo ceph osd pool autoscale-status
sudo rbd create --size 10G --pool rbd postgresql-db

sudo rbd ls -l
RBD_DEV=$(sudo rbd map postgresql-db)
sudo rbd showmapped

sudo mkfs.xfs $RBD_DEV
sudo mount $RBD_DEV /mnt

sudo df -hT

# PostgreSql installation
sudo apt-get install postgresql -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
ls /etc/postgresql/13/main/postgresql.conf

sudo tee -a /etc/postgresql/13/main/postgresql.conf << EOF
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
rados_class = 'rbd'
rados_pool = 'rbd'
rados_user = $USER
rados_secret = '/etc/ceph/ceph.client.$USER.keyring'
EOF

sudo rbd ls
sudo rbd info rbd/postgresql-db


