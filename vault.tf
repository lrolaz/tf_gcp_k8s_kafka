resource "google_kms_key_ring" "vault" {
  name     = "vault"
  location = "europe-west1-b"
}

resource "google_kms_crypto_key" "vault-init" {
  name            = "vault-init"
  key_ring        = "${google_kms_key_ring.vault.self_link}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "vault-storage" {
  name     = "kube-kafka-labo-vault-storage"
  location = "europe-west1-b"
}

data "google_service_account" "vault-server" {
  account_id = "vault-server"
}

resource "google_storage_bucket_acl" "image-store-acl" {
  bucket = "${google_storage_bucket.image-store.name}"

  role_entity = [
    "OWNER:user-my.email@gmail.com",
    "READER:group-mygroup",
  ]
}