provider "google" {
  credentials = "${file("./secrets/kube-kafka-labo.json")}"
  project     = "kube-kafka-labo"
  region      = "europe-west1-b"
}
