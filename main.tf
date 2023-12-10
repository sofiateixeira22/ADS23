/*
terraform init
terraform plan
terraform apply
*enter a value:* yes
*/

variable "ssh_username" {
    default = "root"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "${var.ssh_username}:${tls_private_key.ssh_key.public_key_openssh}"
  }
}

# load network and subnetwork data and create addresses

data "google_compute_network" "default_network" {
    name = "default"
}

data "google_compute_subnetwork" "default_subnetwork" {
    name = "default"
    region = "europe-southwest1"
}

resource "google_compute_address" "osd_1_ip_internal" {
    name = "osd-1-ip-internal"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "osd_1_ip_external" {
    name = "osd-1-ip-external"
    region = "europe-southwest1"
    address_type  = "EXTERNAL"
}

resource "google_compute_address" "osd_2_ip_internal" {
    name = "osd-2-ip-internal"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "osd_2_ip_external" {
    name = "osd-2-ip-external"
    region = "europe-southwest1"
    address_type  = "EXTERNAL"
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

resource "google_compute_address" "mgr_1_ip_internal" {
    name = "mgr-1-ip-internal"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "mgr_1_ip_external" {
    name = "mgr-1-ip-external"
    region = "europe-southwest1"
    address_type  = "EXTERNAL"
}

resource "google_compute_address" "client_1_ip_internal" {
    name = "client-1-ip-internal"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "client_1_ip_external" {
    name = "client-1-ip-external"
    region = "europe-southwest1"
    address_type  = "EXTERNAL"
}

# create disks to attach to instances

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

resource "google_compute_disk" "osd_2_disk_1" {
    name = "osd-2-disk-1"
    type = "pd-ssd"
    zone = "europe-southwest1-c"
    size = 10
}

resource "google_compute_disk" "osd_2_disk_2" {
    name = "osd-2-disk-2"
    type = "pd-standard"
    zone = "europe-southwest1-c"
    size = 25
}

resource "google_compute_disk" "client_1_disk_1" {
    name = "client-1-disk-1"
    type = "pd-standard"
    zone = "europe-southwest1-c"
    size = 30
}

# attaching the disks to the osd instances

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

resource "google_compute_attached_disk" "osd_2_disk_1_attach" {
    disk = google_compute_disk.osd_2_disk_1.id
    instance = google_compute_instance.osd_node_2.id
    zone = "europe-southwest1-c"
}

resource "google_compute_attached_disk" "osd_2_disk_2_attach" {
    disk = google_compute_disk.osd_2_disk_2.id
    instance = google_compute_instance.osd_node_2.id
    zone = "europe-southwest1-c"
}

resource "google_compute_attached_disk" "client_1_disk_1_attach" {
    disk = google_compute_disk.client_1_disk_1.id
    instance = google_compute_instance.client_1.id
    zone = "europe-southwest1-c"
}

# create compute instances
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

    provisioner "remote-exec" {
        inline = [
            "wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -",
            "echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list",
            "apt update",
            "apt install -y ntpsec ceph ceph-mds",
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mon_1.network_interface[0].access_config[0].nat_ip
        }
    }

    tags = []
}

resource "google_compute_instance" "osd_node_1" {
    name         = "osd-instance-1"
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
        network_ip = google_compute_address.osd_1_ip_internal.address
        access_config {
            nat_ip = google_compute_address.osd_1_ip_external.address
        }
    }

    provisioner "remote-exec" {
        inline = [
            "wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -",
            "echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list",
            "apt update",
            "apt install -y ntpsec ceph ceph-mds",
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_1.network_interface[0].access_config[0].nat_ip
        }
    }

    tags = []
}

resource "google_compute_instance" "osd_node_2" {
    name         = "osd-instance-2"
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
        network_ip = google_compute_address.osd_2_ip_internal.address
        access_config {
            nat_ip = google_compute_address.osd_2_ip_external.address
        }
    }

    provisioner "remote-exec" {
        inline = [
            "wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -",
            "echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list",
            "apt update",
            "apt install -y ntpsec ceph ceph-mds",
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_2.network_interface[0].access_config[0].nat_ip
        }
    }

    tags = []
}

resource "google_compute_instance" "mgr_1" {
    name         = "manager-instance-1"
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
        network_ip = google_compute_address.mgr_1_ip_internal.address
        access_config {
            nat_ip = google_compute_address.mgr_1_ip_external.address
        }
    }

    provisioner "remote-exec" {
        inline = [
            "wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -",
            "echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list",
            "apt update",
            "apt install -y ntpsec ceph ceph-mds",
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mgr_1.network_interface[0].access_config[0].nat_ip
        }
    }

    tags = []
}

resource "google_compute_instance" "client_1" {
    name         = "client-instance-1"
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
        network_ip = google_compute_address.client_1_ip_internal.address
        access_config {
            nat_ip = google_compute_address.client_1_ip_external.address
        }
    }

    provisioner "remote-exec" {
        inline = [
            "wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -",
            "echo deb https://download.ceph.com/debian-quincy/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list",
            "apt update",
            "apt install -y ntpsec ceph ceph-mds",
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.client_1.network_interface[0].access_config[0].nat_ip
        }
    }

    tags = [ "http-server", "https-server" ]
}

############### CONFIGURATION_MANAGEMENT ###############

# generate ssh config file
resource "null_resource" "setup_hosts_file" {
    depends_on = [null_resource.ssh_key_copy]
    provisioner "local-exec" {
        command = <<EOF
            echo "Host *" > ./configs/.tmp/ssh_config
            echo "    StrictHostKeyChecking no" >> ./configs/.tmp/ssh_config
            echo "Host monitor-instance-1" >> ./configs/.tmp/ssh_config
            echo "    HostName ${google_compute_address.mon_1_ip_internal.address}" >> ./configs/.tmp/ssh_config
            echo "    User ${var.ssh_username}" >> ./configs/.tmp/ssh_config
            echo "Host manager-instance-1" >> ./configs/.tmp/ssh_config
            echo "    HostName ${google_compute_address.mgr_1_ip_internal.address}" >> ./configs/.tmp/ssh_config
            echo "    User ${var.ssh_username}" >> ./configs/.tmp/ssh_config
            echo "Host osd-instance-1" >> ./configs/.tmp/ssh_config
            echo "    HostName ${google_compute_address.osd_1_ip_internal.address}" >> ./configs/.tmp/ssh_config
            echo "    User ${var.ssh_username}" >> ./configs/.tmp/ssh_config
            echo "Host osd-instance-2" >> ./configs/.tmp/ssh_config
            echo "    HostName ${google_compute_address.osd_2_ip_internal.address}" >> ./configs/.tmp/ssh_config
            echo "    User ${var.ssh_username}" >> ./configs/.tmp/ssh_config
            echo "Host client-instance-1" >> ./configs/.tmp/ssh_config
            echo "    HostName ${google_compute_address.client_1_ip_internal.address}" >> ./configs/.tmp/ssh_config
            echo "    User ${var.ssh_username}" >> ./configs/.tmp/ssh_config
        EOF
    }
    provisioner "file" {
        source      = "./configs/.tmp/ssh_config"
        destination = "/root/.ssh/config"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mon_1.network_interface[0].access_config[0].nat_ip
        }
    }
    provisioner "file" {
        source      = "./configs/.tmp/ssh_config"
        destination = "/root/.ssh/config"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mgr_1.network_interface[0].access_config[0].nat_ip
        }
    }
    provisioner "file" {
        source      = "./configs/.tmp/ssh_config"
        destination = "/root/.ssh/config"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_1.network_interface[0].access_config[0].nat_ip
        }
    }
    provisioner "file" {
        source      = "./configs/.tmp/ssh_config"
        destination = "/root/.ssh/config"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_2.network_interface[0].access_config[0].nat_ip
        }
    }
    provisioner "file" {
        source      = "./configs/.tmp/ssh_config"
        destination = "/root/.ssh/config"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.client_1.network_interface[0].access_config[0].nat_ip
        }
    }
}

# copy private key to all instances
resource "null_resource" "ssh_key_copy" {
    depends_on = [
        google_compute_instance.mon_1,
        google_compute_instance.osd_node_1,
        google_compute_instance.osd_node_2,
        google_compute_instance.mgr_1,
        google_compute_instance.client_1
     ]
    provisioner "remote-exec" {
        inline = [
            "echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519",
            "chmod 600 /root/.ssh/id_ed25519"
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mon_1.network_interface[0].access_config[0].nat_ip
        }   
    }

    provisioner "remote-exec" {
        inline = [
            "echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519",
            "chmod 600 /root/.ssh/id_ed25519"
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_1.network_interface[0].access_config[0].nat_ip
        }   
    }

    provisioner "remote-exec" {
        inline = [
            "echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519",
            "chmod 600 /root/.ssh/id_ed25519"
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_2.network_interface[0].access_config[0].nat_ip
        }   
    }

    provisioner "remote-exec" {
        inline = [
            "echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519",
            "chmod 600 /root/.ssh/id_ed25519"
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.mgr_1.network_interface[0].access_config[0].nat_ip
        }   
    }

    provisioner "remote-exec" {
        inline = [
            "echo '${tls_private_key.ssh_key.private_key_openssh}' > /root/.ssh/id_ed25519",
            "chmod 600 /root/.ssh/id_ed25519"
        ]
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.client_1.network_interface[0].access_config[0].nat_ip
        }   
    }
}

# provisioning monitor
# since its the first node, make sure all other resources are created
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
# provision manager
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
resource "null_resource" "provision_osd_2" {
    depends_on = [null_resource.provision_osd_1]
    provisioner "remote-exec" {
        script = "./configs/osd/provision.sh"
        connection {
            type        = "ssh"
            user        = var.ssh_username
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = google_compute_instance.osd_node_2.network_interface[0].access_config[0].nat_ip
        }
    }
}
# provision client
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

# create tun shell script
resource "null_resource" "create_tun_script" {
    depends_on = [null_resource.provision_client]
    provisioner "local-exec" {
        command = "echo ssh -i configs/.tmp/id_ed25519 -o StrictHostKeyChecking=no -R 8080:localhost:80 root@${google_compute_instance.client_1.network_interface[0].access_config[0].nat_ip} > ./ssh-tun.sh"
    }
}
