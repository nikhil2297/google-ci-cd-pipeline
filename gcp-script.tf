# provider.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "assignment-2-project-442810"
  region  = "northamerica-northeast2"
  zone    = "northamerica-northeast2-a"
}

# variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "assignment-2-project-442810"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "northamerica-northeast2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "northamerica-northeast2-a"
}

variable "container_image" {
  description = "Container image path in GCR"
  type        = string
  default     = "gcr.io/assignment-2-project-442810/assignment2-flask-image:latest"
}

# network.tf
resource "google_compute_network" "vpc" {
  name                    = "flask-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
}

# firewall.tf
resource "google_compute_firewall" "flask" {
  name    = "flask-app-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]  # Updated to match Flask app port
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["flask-app"]
}

# SSH firewall rule
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["flask-app"]
}

# compute.tf
resource "google_compute_instance" "flask_instance" {
  name         = "flask-app-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["flask-app"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"  # Changed to Ubuntu for better container support
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      // Assigns a public IP
    }
  }

  # Metadata for container deployment
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      sudo apt-get update
      
      sudo apt-get install -y docker.io
      
      sudo gcloud auth configure-docker
      
      sudo docker pull gcr.io/northamerica-northeast2-docker.pkg.dev/assignment-2-project-442810/assignment2-flask/assignment2-flask-image:latest
      
      sudo docker run -d --name flask-app -p 8080:8080 gcr.io/northamerica-northeast2-docker.pkg.dev/assignment-2-project-442810/assignment2-flask/assignment2-flask-image:latest
    EOF
  }

  # Service account with necessary permissions
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# outputs.tf
output "public_ip" {
  value = google_compute_instance.flask_instance.network_interface[0].access_config[0].nat_ip
}