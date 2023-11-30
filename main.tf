/*
terraform init
terraform plan
terraform apply
*enter a value:* yes
*/

# TODO: fix external ip address
# TODO: run commands to install ceph on each node

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

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "debian:${tls_private_key.ssh_key.public_key_openssh}"
  }
}

# create disks to attach to osd instances

resource "google_compute_disk" "osd_1_disk_ssd" {
    name = "osd-1-disk-ssd"
    type = "pd-ssd"
    zone = "europe-southwest1-b"
    size = 15
}

resource "google_compute_disk" "osd_1_disk_standard" {
    name = "osd-1-disk-standard"
    type = "pd-standard"
    zone = "europe-southwest1-b"
    size = 10
}

resource "google_compute_disk" "osd_2_disk_1" {
    name = "osd-2-disk-1"
    type = "pd-ssd"
    zone = "europe-southwest1-b"
    size = 10
}

resource "google_compute_disk" "osd_2_disk_2" {
    name = "osd-2-disk-2"
    type = "pd-ssd"
    zone = "europe-southwest1-b"
    size = 10
}

# attaching the disks to the osd instances

resource "google_compute_attached_disk" "osd_1_disk_ssd_attach" {
    disk = google_compute_disk.osd_1_disk_ssd.id
    instance = google_compute_instance.osd_node_1.id
    zone = "europe-southwest1-b"
}

resource "google_compute_attached_disk" "osd_1_disk_standard_attach" {
    disk = google_compute_disk.osd_1_disk_standard.id
    instance = google_compute_instance.osd_node_1.id
    zone = "europe-southwest1-b"
}

resource "google_compute_attached_disk" "osd_2_disk_1_attach" {
    disk = google_compute_disk.osd_2_disk_1.id
    instance = google_compute_instance.osd_node_2.id
    zone = "europe-southwest1-b"
}

resource "google_compute_attached_disk" "osd_2_disk_2_attach" {
    disk = google_compute_disk.osd_2_disk_2.id
    instance = google_compute_instance.osd_node_2.id
    zone = "europe-southwest1-b"
}

# create compute instances

resource "google_compute_instance" "osd_node_1" {
    name         = "osd-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-standard"
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

    tags = [ "http-server", "https-server" ]
    # su root | apt-get update | apt-get install ceph -y

    provisioner "file" {
        source      = "./configs/osd1_config.sh"
        destination = "./osd1_config.sh"
        connection {
            type        = "ssh"
            user        = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "remote-exec" {
        inline = [
          "sudo chmod +x ./osd1_config.sh",
          "sudo ./osd1_config.sh"
        ]
        connection {
            type = "ssh"
            user = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

}

resource "google_compute_instance" "osd_node_2" {
    name         = "osd-instance-2"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-standard"
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

    tags = [ "http-server", "https-server" ]

    provisioner "file" {
        source      = "./configs/osd2_config.sh"
        destination = "./osd2_config.sh"
        connection {
            type        = "ssh"
            user        = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "remote-exec" {
        inline = [
          "sudo chmod +x ./osd2_config.sh",
          "sudo ./osd2_config.sh"
        ]
        connection {
            type = "ssh"
            user = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }
    
}

resource "google_compute_instance" "mon_1" {
    name         = "monitor-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-standard"
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

    tags = [ "http-server", "https-server" ]

    provisioner "file" {
        source      = "./configs/mon_config.sh"
        destination = "./mon_config.sh"
        connection {
            type        = "ssh"
            user        = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "remote-exec" {
        inline = [
          "sudo chmod +x ./mon_config.sh",
          "sudo ./mon_config.sh"
        ]
        connection {
            type = "ssh"
            user = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }
}

resource "google_compute_instance" "mgr_1" {
    name         = "manager-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-standard"
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

    tags = [ "http-server", "https-server" ]

    provisioner "file" {
        source      = "./configs/mgr_config.sh"
        destination = "./mgr_config.sh"
        connection {
            type        = "ssh"
            user        = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "remote-exec" {
        inline = [
          "sudo chmod +x ./mgr_config.sh",
          "sudo ./mgr_config.sh"
        ]
        connection {
            type = "ssh"
            user = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }
}

resource "google_compute_instance" "client_1" {
    name         = "client-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-standard"
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

    tags = [ "http-server", "https-server" ]

    metadata = {
        ssh-keys = <<EOF
            root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3MUis6A3DvI+sCMAXewZ7hECAoameXjOWcVNUjMCW/ sofia
        EOF
    }

    provisioner "file" {
        source      = "./configs/client_config.sh"
        destination = "./client_config.sh"
        connection {
            type        = "ssh"
            user        = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }

    provisioner "remote-exec" {
        inline = [
          "sudo chmod +x ./client_config.sh",
          "sudo ./client_config.sh"
        ]
        connection {
            type = "ssh"
            user = "debian"
            private_key = tls_private_key.ssh_key.private_key_pem
            host        = self.network_interface[0].access_config[0].nat_ip
        }
    }
}
