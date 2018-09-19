provider "google" {
  credentials = "${file("./secrets/kube-kafka-labo-78bbc185654d.json")}"
  project     = "kube-kafka-labo"
  region      = "europe-west1-b"
}
