/*
terraform init
terraform plan
terraform apply
*enter a value:* yes
*/

# load network and subnetwork data and create addresses

data "google_compute_network" "default_network" {
    name = "default"
}

data "google_compute_subnetwork" "default_subnetwork" {
    name = "default"
    region = "europe-southwest1"
}

resource "google_compute_address" "osd_1_ip" {
    name = "osd-1-ip"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "osd_2_ip" {
    name = "osd-2-ip"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "mon_1_ip" {
    name = "mon-1-ip"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "mgr_1_ip" {
    name = "mgr-1-ip"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
}

resource "google_compute_address" "client_1_ip" {
    name = "client-1-ip"
    subnetwork = data.google_compute_subnetwork.default_subnetwork.id
    region = "europe-southwest1"
    address_type  = "INTERNAL"
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

# @TODO: create disks to attach to instances

# resource "google_compute_disk" "osd_1_disk" {
#     name = "osd-1-disk"
#     type = "pd-ssd"
#     zone = "europe-southwest1-a"
#     size = 10
# }


# create compute instances

resource "google_compute_instance" "osd_node_1" {
    name         = "osd-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.osd_1_ip.address
    }
}

resource "google_compute_instance" "osd_node_2" {
    name         = "osd-instance-2"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.osd_2_ip.address
    }
}

resource "google_compute_instance" "mon_1" {
    name         = "monitor-instance-1"
    machine_type = "e2-micro"
    zone         = "europe-southwest1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.mon_1_ip.address
    }

    provisioner "file" {
        source      = "./mon_config.sh"
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
    zone         = "europe-southwest1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.mgr_1_ip.address
    }
}

resource "google_compute_instance" "client_1" {
    name         = "client-instance-1"
    machine_type = "e2-small"
    zone         = "europe-southwest1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
            type = "pd-ssd"
            size = 10
        }
    }

    network_interface {
        network = data.google_compute_network.default_network.id
        subnetwork = data.google_compute_subnetwork.default_subnetwork.id
        network_ip = google_compute_address.client_1_ip.address
    }

    metadata = {
        ssh-keys = <<EOF
            root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3MUis6A3DvI+sCMAXewZ7hECAoameXjOWcVNUjMCW/ sofia
        EOF
    }
}
