data "google_container_engine_versions" "kube_version" {
  zone = "europe-west1-b"
}

resource "google_container_cluster" "gcp_kubernetes" {
  name               = "${var.cluster_name}"
  zone               = "europe-west1-b"
  initial_node_count = "${var.gcp_cluster_count}"
  node_version       = "${data.google_container_engine_versions.kube_version.latest_node_version}"
  min_master_version = "${data.google_container_engine_versions.kube_version.latest_node_version}"

  master_auth {
    username = "${var.linux_admin_username}"
    password = "${var.linux_admin_password}}"
  }

  addons_config {
  
    http_load_balancing {
      disabled = true
    }
    
    horizontal_pod_autoscaling {
      disabled = true
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb       = 10

    labels {
      this-is-for = "kafka-cluster"
    }

    tags = ["kafka", "labo"]
  }
}
