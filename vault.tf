
resource "kubernetes_namespace" "kube-security" {
  metadata {
    name = "kube-security"
  }
}

# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server"
  display_name = "Vault Server"
}

# Create a service account key
resource "google_service_account_key" "vault" {
  service_account_id = "${google_service_account.vault-server.name}"
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = "${length(var.service_account_iam_roles)}"
  role    = "${element(var.service_account_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = "${length(var.project_services)}"
  service = "${element(var.project_services, count.index)}"

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

# Create the storage bucket
resource "google_storage_bucket" "vault-server" {
  name          = "kube-kafka-labo-vault"
  force_destroy = true
  storage_class = "MULTI_REGIONAL"
  location = "EU"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 3
    }
  }

  depends_on = ["google_project_service.service"]
}

# Grant service account access to the storage bucket
resource "google_storage_bucket_iam_member" "vault-server" {
  count  = "${length(var.storage_bucket_roles)}"
  bucket = "${google_storage_bucket.vault-server.name}"
  role   = "${element(var.storage_bucket_roles, count.index)}"
  member = "serviceAccount:${google_service_account.vault-server.email}"
}

# Create the KMS key ring
resource "google_kms_key_ring" "vault-server" {
  name     = "vault-server"
  location = "${var.region}"

  depends_on = ["google_project_service.service"]
}

# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-server-init" {
  name            = "vault-init"
  key_ring        = "${google_kms_key_ring.vault-server.id}"
  rotation_period = "604800s"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-server-init" {
  count         = "${length(var.kms_crypto_key_roles)}"
  crypto_key_id = "${google_kms_crypto_key.vault-server-init.id}"
  role          = "${element(var.kms_crypto_key_roles, count.index)}"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}

# Write the secret
resource "kubernetes_secret" "vault-tls" {
  metadata {
    name = "vault-tls"
    namespace = "kube-security"
  }

  data {
    "vault.crt" = "${tls_locally_signed_cert.vault.cert_pem}\n${tls_self_signed_cert.vault-ca.cert_pem}"
    "vault.key" = "${tls_private_key.vault.private_key_pem}"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]  
}

# Write the secret
resource "kubernetes_secret" "vault-ca" {
  metadata {
    name = "vault-ca"
    namespace = "kube-security"
  }

  data {
    "vault-ca.pem" = "${tls_self_signed_cert.vault-ca.cert_pem}"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
}

# Write the configmap
resource "kubernetes_config_map" "vault" {
  metadata {
    name = "vault"
    namespace = "kube-security"
  }

  data {
    load_balancer_address = "${google_compute_address.vault.address}"
    gcs_bucket_name       = "${google_storage_bucket.vault-server.name}"
    kms_key_id            = "${google_kms_crypto_key.vault-server-init.id}"
    project_id            = "kube-kafka-labo"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
}

# Provision IP
resource "google_compute_address" "vault" {
  name    = "vault-lb"
  region  = "${var.region}"

  depends_on = ["google_project_service.service"]
}

# Download the encrypted root token to disk
data "google_storage_object_signed_url" "root-token" {
  bucket = "${google_storage_bucket.vault-server.name}"
  path   = "root-token.enc"

  credentials = "${base64decode(google_service_account_key.vault.private_key)}"
}

# Download the encrypted file
data "http" "root-token" {
  url = "${data.google_storage_object_signed_url.root-token.signed_url}"
}

# Decrypt the secret
data "google_kms_secret" "root-token" {
  crypto_key = "${google_kms_crypto_key.vault-server-init.id}"
  ciphertext = "${data.http.root-token.body}"
}

output "vault_token" {
  value = "${data.google_kms_secret.root-token.plaintext}"
}

output "vault_address" {
  value = "${google_compute_address.vault.address}"
}

output "region" {
  value = "${var.region}"
}

output "zone" {
  value = "${var.zone}"
}