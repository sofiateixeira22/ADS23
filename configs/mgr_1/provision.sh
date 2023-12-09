#!/bin/bash

# copy config and keyring from monitor node
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph
scp monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd

# enable Messenger v2 Protocol
ceph mon enable-msgr2
ceph config set mon auth_allow_insecure_global_id_reclaim false

# create a directory for Manager Daemon
mkdir /var/lib/ceph/mgr/ceph-manager-instance-1
# create auth key
ceph auth get-or-create mgr.manager-instance-1 mon 'allow profile mgr' osd 'allow *' mds 'allow *'

# [mgr.node01]
#         key = AQD/ASZh9RQCKBAAmM8soMAgMHBJRRXr7hSSKQ==

ceph auth get-or-create mgr.manager-instance-1 | tee /etc/ceph/ceph.mgr.admin.keyring
cp /etc/ceph/ceph.mgr.admin.keyring /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
chown ceph. /etc/ceph/ceph.mgr.admin.keyring
chown -R ceph. /var/lib/ceph/mgr/ceph-manager-instance-1
systemctl enable --now ceph-mgr@manager-instance-1

echo "Done provisioning $(hostname)"
