#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y ceph ceph-mds
sudo touch /etc/ceph/ceph.conf

USER=$(logname)

sudo chmod +x /home/$USER/.ssh

sudo touch /home/$USER/.ssh/my-ssh-key
sudo touch /home/$USER/.ssh/my-ssh-key.pub

sudo tee -a /home/$USER/.ssh/my-ssh-key << EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABBv6QfSrV
xPldIGqiIPBRXrAAAAEAAAAAEAAAEXAAAAB3NzaC1yc2EAAAADAQABAAABAQCx/ypUE7Wt
mpa9hwlWuZNwY5CgTT80K0rOykNZYlubgEfpSeKj+j0VPyccXvxxs3Kta6zliT7N4fiNUp
4NxhH5MEzlV6DSUyuWCchv7y90dkyI/jqE5PmWtGQHAx7CPYe4I8o4HgQSswVLPblJV4y3
rjqcfN7nmeXxL2Vherhr2TOO/fKyIYroYhkAXFJ0nlUjGs+tZM8OugAQDTUVb8BArPsCfg
jLCM+Jz0bwADRZCQ6PxnZQS26vT6wZR+XLHAIYDNi+dX58vkywm4qgXw0YnarKS76eBo9P
CrD0jqGSGB4gOkg5q+K4c2xrWLqfWPRFPQz3JZv11Zn/ZQQ+drvTAAAD0LYeUn5v6/KKla
7kV1Ifqd/t75+Q72s6az5EF81aCg8TB1k9jznp5vYfgp3njMSMGy7TaBs+HzfMdfEYAsRP
BhVjyfr0lqASr7jU1F44AsxMt1FjRd+An/f8mpVKr6x2DDODKkgIon14anx06qJM4tXk8c
0mNNWBoa8UHB99cimWsI0fwdIggg27g4sgM8Ul5wAUT6t7BbyTU6qgDBBbOeNthK3LRdXQ
WCstU0pH6PBIfQH5u0ns0rR8wk4VF2LK0Sc5Ut0onq2Qoy15qn/5266M+nFZDqu7eMuvt/
h3/yX5XSQiXvywoLOPllY3lE5E2HQ3+/ZnLLdhAMFFZRWpVl24/wb4jilDMfU7pvvvSKyp
qlpwfJgIFrJ1CbieN24qral3Gn2bcq+hnGdN2ZiCAjB5+7rRi2pnVhgSFZRFlekQPgMaqz
9x1JYL7Og6eLf2+YfsetBB8neHdXIsLWkfTyYNZ9yP3/8DrdfZ8ns8CHAC+FnKuAzlF2JN
5C9mcCe0pV5ws7T5ztXm7bx3eOeOLxBKNifwE6t88GNijGBCMJDUVl2/wIMsqwGNHtu6Ma
ECB+HSTqVyAcZfCIXI5/AQz+wbpyv9T8FJoEZVCO9n+cbgOUQvpDehuszxpeiJSowtiq2Y
qEAJz5XDQ9tdoNS+D3cq+wg0UVTBz2Iji6Ydi6YDSNVkuHK9ICh8NZFSPgervQz2int3Pd
x+LLMZql4X5I6kpeF8avOjV9APSul6vKh+Av6+4kRN+mXhEqoUhi6TrBjtm2MWEJeadaPJ
q82CU5diNLIBAZrm9i/+8gVQyB8ks/CJQtAMbaWC6NDgvHaTmOnXwCP5FQTJMslQKj5Y5+
IdAyBi+5TSIdvRYbmUX6WTTXviySpsyKFRKFChI6pfcDFqqeN/V2gXwQ4Vm8kT/u12Cn+D
MjminMJnO+fzSuGuNrT/OntKYbVfLiL4iAFyWmgxgLTYrjFPbDYyyK8UscsDiHVH5T/NRK
MiiBnGd0fTR1ceuTU1c/BFEY83G1QuuVNNs0p9KpZS14lNL7TS/mHZU1skMmLXJ7pcQW+x
Q8ZMKf8HZRoqneMlTXpXmTNksC7jptDJhzYhTC1zQf0U3iuYT3Q3js3xVmujBzpt+MuYII
nF2Yp5YF8ZlWX/j0eG7aGWSb43R68SDQjnLyVynpOr7SETbrkF9DJaU2KMhw6GIQTojmpa
5fbPS9a8OnDkMjogUlI/U6CPrX+tzttCJOpkPPMI3/zPJtcYp27z2Q5cOFZ64K+LaFAznW
/dT6j4x/x+xecgeZnFC8rDXsPSBS4=
-----END OPENSSH PRIVATE KEY-----
EOF

sudo tee -a /home/$USER/.ssh/my-ssh-key.pub << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCx/ypUE7Wtmpa9hwlWuZNwY5CgTT80K0rOykNZYlubgEfpSeKj+j0VPyccXvxxs3Kta6zliT7N4fiNUp4NxhH5MEzlV6DSUyuWCchv7y90dkyI/jqE5PmWtGQHAx7CPYe4I8o4HgQSswVLPblJV4y3rjqcfN7nmeXxL2Vherhr2TOO/fKyIYroYhkAXFJ0nlUjGs+tZM8OugAQDTUVb8BArPsCfgjLCM+Jz0bwADRZCQ6PxnZQS26vT6wZR+XLHAIYDNi+dX58vkywm4qgXw0YnarKS76eBo9PCrD0jqGSGB4gOkg5q+K4c2xrWLqfWPRFPQz3JZv11Zn/ZQQ+drvT cristinamcp21
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

