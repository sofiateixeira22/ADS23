# Systems Administration - Ceph Cluster

## Introduction
This project was developed within the scope of the Systems Administration course in the Master's in Network Engineering and Computer Systems. The project aimed at building a Ceph cluster using tools such as the Google Cloud Platform and Terraform. The Ceph cluster consists of 4 virtual machines: 1 monitor (to monitor the cluster's status), 1 manager (to manage the cluster), and 2 OSDs (to store the cluster's data). An additional virtual machine was also used to act as a client (to interact with the cluster) and simultaneously serve as a backup solution.

## Infrastructure Creation  
To create the infrastructure, we used Terraform. Terraform is a tool that simplifies infrastructure management by enabling the creation, modification, and removal of resources such as VMs, networks, and attached disks. This way, we can build the entire infrastructure by simply running the command `terraform apply`, and remove it using `terraform destroy`. This allows an easy way to create and destroy the entire infrastructure, instead of having to create and destroy each resource individually using a console or the web interface.

### Terraform Configuration
To configure Terraform, we had to create a service account on Google Cloud Platformn and download the credentials file. This file contains the credentials that Terraform uses to authenticate with Google Cloud Platform.

After installing Terraform and creating the service account, we created the `provider.tf` file which contains the configuration for Terraform to use the credentials file and the project ID.

Then we created the `main.tf` file which is the base file of our project. This file contains the configuration for the VMs, networks, and attached disks. It also contains the configuration for the SSH key and the provisioners.

To run our project, we need to run the following commands:
```bash
terraform init
terraform apply
```
The `terraform init` command initializes a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration. The `terraform apply` command creates or updates the infrastructure according to the Terraform configuration files.

### VMs Creation
To create the VMs, we had to consider the zone and region, the machine type and it's operating system. This configuration is the same for all the VMs used for this project. We also added private network so that the VMs could communicate with each other internally, and public IP addresses for them to have access to the Internet. For some of them (OSDs and client), we also added attached disks.

We used the following code to create the monitor VM, which is the same for all the VMs except for the name, machine type, and attached disks:
```terraform
resource "google_compute_instance" "mon_1" {
    name         = "monitor-instance-1"
    machine_type = "e2-medium"
    zone         = "europe-southwest1-c"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2004-lts"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.mon_1_ip_internal.address
        access_config {
            nat_ip = google_compute_address.mon_1_ip_external.address
        }
    }
}
```

As we also need to create private and public IP resources:
```terraform
data "google_compute_network" "default_network" {
    name = "default"
}

data "google_compute_subnetwork" "default_subnetwork" {
    name = "default"
    region = "europe-southwest1"
}
resource "google_compute_address" "mon_1_ip_internal" {
    name = "mon-1-ip-internal"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "mon_1_ip_external" {
    name = "mon-1-ip-external"
    region = "europe-southwest1"
    address_type  = "EXTERNAL"
}
```

#### Zone and Region
The `europe-southwest1` region it's the closest to us, so we chose it. We are using the same zone and region for all resources because instances within the same region or zone communicate with lower latency and higher network throughput. This minimizes delays in data transmission.

#### Machine Type
We initially used the `e2-micro` type to understand how to get the project done due to its low cost. After implementing almost all of the project, we decided to switch to `e2-medium` because, even though the cost is higher, the performance is better for the final phase of the project.

#### Operating System
For the operating system, we chose based on the recommendations from the official [Ceph website](https://docs.ceph.com/en/quincy/start/os-recommendations/). In our case, we selected Ubuntu because it's one of the operating systems with extensive software testing and because we are familiar with it in our day-to-day basis.
![](/doc_imgs/os_recomendation.png)

### Attached Disks
To create an attached disk and attach it to the respective VM using Terraform, you just need to add two resources, one to specify the attached disk name, type, zone and size, and another to attach it to the VM.
For the first OSD node, we used the following code:
```terraform
resource "google_compute_disk" "osd_1_disk_ssd" {
    name = "osd-1-disk-ssd"
    type = "pd-ssd"
    zone = "europe-southwest1-c"
    size = 15
}

resource "google_compute_disk" "osd_1_disk_standard" {
    name = "osd-1-disk-standard"
    type = "pd-standard"
    zone = "europe-southwest1-c"
    size = 20
}
resource "google_compute_attached_disk" "osd_1_disk_ssd_attach" {
    disk = google_compute_disk.osd_1_disk_ssd.id
    instance = google_compute_instance.osd_node_1.id
    zone = "europe-southwest1-c"
}

resource "google_compute_attached_disk" "osd_1_disk_standard_attach" {
    disk = google_compute_disk.osd_1_disk_standard.id
    instance = google_compute_instance.osd_node_1.id
    zone = "europe-southwest1-c"
}
```

#### Disks for OSDs
Since OSDs are Object Storage Devices, they need disks to store the cluster data. To do this we needed to create the disks and attach them to the respective VMs. Since we have 2 OSD nodes and to show how a Ceph cluster balances the data distribution, we chose to have disks with different sizes and different types within each node. For the first OSD node we chose to have a 15GB SSD disk and a 20GB HDD disk. For the second OSD node we chose to have a 10GB SSD disk and a 25GB HDD disk.

#### Disk for client
Since the client and the backup solution share the same VM, we've decided to add a disk to this VM to store the backup files.

### SSH Key
To be able to execute commands on the VMs using Terraform, we needed to setup an SSH key. The following code generates the key pair which are later used on every provisioning code block. This key is generated using the ED25519 algorithm which is more secure than the RSA algorithm and the new default for OpenSSH.
```terraform
resource "tls_private_key" "ssh_key" {
    algorithm = "ED25519"
}
```

This key is used for the authentication between the local machine and the VMs.
We used the user `root` and used the following code to allow us to use this SSH key for the whole project:
```terraform
resource "google_compute_project_metadata" "ssh_keys" {
    metadata = {
        ssh-keys = "${var.ssh_username}:${tls_private_key.ssh_key.public_key_openssh}"
    }
}
```

This key is then copied to the VMs using the Terraform resource `null-resource.ssh_key_copy` which executes the following commands:
```bash
echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519,
chmod 600 /root/.ssh/id_ed25519
```
Where `${tls_private_key.ssh_key.private_key_openssh}` is the private key generated by Terraform.

After this, we created a `ssh_config` file that has the translation between the VMs name and their IP addresses. This file is then copied to the VMs using the Terraform resource `null-resource.setup_hosts_file` and the provisioner `file` where `<terraform-vm-name>` is the name of the VM used in Terraform:
```terraform
provisioner "file" {
    source      = "./configs/.tmp/ssh_config"
    destination = "/root/.ssh/config"
    connection {
        type        = "ssh"
        user        = var.ssh_username
        private_key = tls_private_key.ssh_key.private_key_pem
        host        = google_compute_instance.<terraform-vm-name>.network_interface[0].access_config[0].nat_ip
    }
}
```
This allows us to use the VMs name instead of their IP addresses when executing commands like `ssh` on the VMs.

### Provisioning
When we create the VMs using the resource `google_compute_instance`, we can run a provisioner `remote-exec` which executes commands on the VMs. We used this provisioner to install the necessary packages and dependencies for the Ceph cluster to work.

To install the Ceph packages we are using the following code:
```bash
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt update
apt install -y \
    ntpsec \
    ceph \
    ceph-mds
```

The `wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -` command downloads the Ceph repository key and adds it to the system. The `echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list` command adds the Ceph repository to the system. The `apt update` command updates the package list. The `apt install -y ntpsec ceph ceph-mds` command installs the packages `ntpsec` (used to sync the time between the nodes), `ceph` and `ceph-mds` which are necessary for the Ceph cluster to work.

In theory `ceph-mds` should not be installed because we are using RBD (block storage) and not CephFS (file storage), which needs the meatadata server (MDS).
However, not installing it does not install some tools like `ceph-volume` which is used to manage disks on OSD nodes

For the client, `ceph-common` should be enough to use as RBD client (not tested in our project) but for the sake of simplicity we do the same installation for all the VMs. We can also take advantage that docker comes pre-installed.

The `--no-install-recommends` option is not used because it will not install the `ceph-common` package, nor is able to install `ceph-volume` afterwards (a tool to manage disks on OSD nodes).

Since each node has a different configuration, their configurations are in `.sh` files in the `configs` folder. These files are executed in the respective VMs provisioner `remote-exec` where `<terraform-vm-name>` is the name of the VM used in Terraform and `<folder-name>` is the name of the folder where the `.sh` file is located:
```terraform
provisioner "remote-exec" {
    script = "./configs/<folder-name>/provision.sh"
    connection {
        type        = "ssh"
        user        = var.ssh_username
        private_key = tls_private_key.ssh_key.private_key_pem
        host        = google_compute_instance.<terraform-vm-name>.network_interface[0].access_config[0].nat_ip
    }
}
```

Each configuration is executed by the resource `null_resource.provision_<vm-name>` which is executed after the VM is created and after the SSH key is copied to the VM. This resource is also executed after the disks are attached to the VMs.

## Ceph Cluster Configuration
After creating the infrastructure, we needed to configure the Ceph cluster by executing the configuration files mentioned in the previous section.

To do this, we used the `remote-exec` provisioner to execute the `.sh` files on the VMs. We also needed to execute the commands in the correct order, so we used the `depends_on` argument to specify the order of execution.

### Monitor
The monitor node is the first one to be configured. This node is essencial for maintaining the health, consistency, and proper functioning of a Ceph cluster.

To execute the configuration file copied to the VM, we used the following code:
```terraform
resource "null_resource" "provision_monitor" {
    # make sure to run the first provisioning only after all files are copied and disks are attached
    depends_on = [
        null_resource.setup_hosts_file,
        google_compute_instance.client_1,
        google_compute_instance.mon_1,
        google_compute_instance.mgr_1,
        google_compute_instance.osd_node_1,
        google_compute_instance.osd_node_2,
        google_compute_attached_disk.osd_1_disk_ssd_attach,
        google_compute_attached_disk.osd_1_disk_standard_attach,
        google_compute_attached_disk.osd_2_disk_1_attach,
        google_compute_attached_disk.osd_2_disk_2_attach,
        google_compute_attached_disk.client_1_disk_1_attach
    ]
    provisioner "remote-exec" {
        script = "./configs/mon_1/provision.sh"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mon_1.network_interface[0].access_config[0].nat_ip
        }
    }
}
```
To configure the monitor node, we followed the official [Ceph documentation](https://docs.ceph.com/en/quincy/install/manual-deployment/#monitor-bootstrapping). This resulted in the following list of commands:
```bash
CLUSTER_UUID=$(uuidgen)
IP=$(hostname -i)
SUBNET='10.204.0.0/20'

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

ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'

sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'

sudo ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo monmaptool --create --add monitor-instance-1 $IP --fsid $CLUSTER_UUID /etc/ceph/monmap

sudo -u ceph mkdir /var/lib/ceph/mon/ceph-monitor-instance-1

chown ceph. /etc/ceph/ceph.*
chown -R ceph. /var/lib/ceph/mon/ceph-monitor-instance-1 /var/lib/ceph/bootstrap-osd

sudo -u ceph ceph-mon --cluster ceph --mkfs -i monitor-instance-1 --monmap /etc/ceph/monmap --keyring /etc/ceph/ceph.mon.keyring

sudo systemctl enable --now ceph-mon@monitor-instance-1
```
After executing these commands, the monitor node is configured and ready to be used. When executing the command `sudo ceph -s` on the monitor node we get the status of the cluster.

### OSDs
OSD nodes are fundamental in a Ceph cluster, serving as the backbone for data storage, replication, fault tolerance, and ensuring efficient performance and reliability of the entire storage infrastructure.

To configure the OSDs, we used a similar approach to the one used for the monitor node. The following code shows the resource used to configure the first OSD node:
```terraform
resource "null_resource" "provision_osd_1" {
    depends_on = [null_resource.provision_manager]
    provisioner "remote-exec" {
        script = "./configs/osd/provision.sh"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_1.network_interface[0].access_config[0].nat_ip
        }
    }
}
```
For the OSDs, we followed [this](https://www.server-world.info/en/note?os=Debian_11&p=ceph14&f=2) documentation provided by the professor. This resulted in the following list of commands:
```bash
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph
scp monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd

chown ceph. /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
parted --script /dev/sdb 'mklabel gpt'
parted --script /dev/sdb "mkpart primary 0% 100%"
ceph-volume lvm create --data /dev/sdb1

chown ceph. /etc/ceph/ceph.* /var/lib/ceph/bootstrap-osd/*
parted --script /dev/sdc 'mklabel gpt'
parted --script /dev/sdc "mkpart primary 0% 100%"
ceph-volume lvm create --data /dev/sdc1
```
After executing these commands, the OSDs are configured and ready to be used. When executing the command `sudo ceph -s`, we get the status of the cluster and we can now see that the OSDs are up and running.

### Manager
To configure the manager, we used a similar approach to the one used for the monitor node.
```terraform
resource "null_resource" "provision_manager" {
    depends_on = [null_resource.provision_monitor]
    provisioner "remote-exec" {
        script = "./configs/mgr_1/provision.sh"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mgr_1.network_interface[0].access_config[0].nat_ip
        }
    }
}
```

For the manager node, we followed [this](https://www.server-world.info/en/note?os=Debian_11&p=ceph14&f=1) documentation provided by the professor. This resulted in the following list of commands:
```bash
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph
scp monitor-instance-1:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd

ceph mon enable-msgr2
ceph config set mon auth_allow_insecure_global_id_reclaim false

mkdir /var/lib/ceph/mgr/ceph-manager-instance-1

ceph auth get-or-create mgr.manager-instance-1 mon 'allow profile mgr' osd 'allow *' mds 'allow *'

ceph auth get-or-create mgr.manager-instance-1 | tee /etc/ceph/ceph.mgr.admin.keyring
cp /etc/ceph/ceph.mgr.admin.keyring /var/lib/ceph/mgr/ceph-manager-instance-1/keyring
chown ceph. /etc/ceph/ceph.mgr.admin.keyring
chown -R ceph. /var/lib/ceph/mgr/ceph-manager-instance-1
systemctl enable --now ceph-mgr@manager-instance-1
```

### Client and Backup Solution
The client node is used to interact with the cluster. It is used to create pools, create and delete objects, and to mount the RBDs. 

To configure the manager, we used a similar approach to the one used for the other nodes.
```terraform
resource "null_resource" "provision_client" {
    depends_on = [null_resource.provision_osd_2]
    provisioner "remote-exec" {
        script = "./configs/client/provision.sh"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.client_1.network_interface[0].access_config[0].nat_ip
        }
    }
}
```

For the client node, we followed [this](https://www.server-world.info/en/note?os=Debian_11&p=ceph14&f=3) documentation provided by the professor. This resulted in the following list of commands:
```bash
scp monitor-instance-1:/etc/ceph/ceph.conf /etc/ceph/
scp monitor-instance-1:/etc/ceph/ceph.client.admin.keyring /etc/ceph/
chown ceph. /etc/ceph/ceph.*

ceph osd pool create rbd 64
ceph mgr module enable pg_autoscaler
ceph osd pool set rbd pg_autoscale_mode on

rbd pool init rbd

rbd create --size 20G --pool rbd rbd01

rbd map rbd01

mkfs.xfs /dev/rbd0

mkdir /mnt/rbd
mount /dev/rbd0 /mnt/rbd

parted --script /dev/sdb 'mklabel gpt'
parted --script /dev/sdb "mkpart primary 0% 100%"
mkfs.xfs /dev/sdb1
mkdir /mnt/ceph-backup-disk
mount /dev/sdb1 /mnt/ceph-backup-disk

echo "*/5 * * * * rsync -a /mnt/rbd/ /mnt/ceph-backup-disk/" | crontab -
```

The backup solution is used to backup the data stored in the cluster. It is used to backup the data stored in the RBDs. We chose for it to copy the data from the RBDs to the attached disk every 5 minutes.
This solution is represented by this line of code:
```bash
echo "*/5 * * * * rsync -a /mnt/rbd/ /mnt/ceph-backup-disk/" | crontab -
```

## Authors
- Ana Sofia Teixeira - up201906031
- Cristina Pêra - up201907321
- Henrique Vicente - up202005321

### Contributions
- Ana Sofia Teixeira - 50%
- Cristina Pêra - 50%
- Henrique Vicente - 0%
