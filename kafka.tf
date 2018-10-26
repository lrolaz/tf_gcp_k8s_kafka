
resource "kubernetes_namespace" "kube-kafka" {
  metadata {
    name = "kube-kafka"
  }
}

# Write the secret
resource "kubernetes_secret" "ca" {
  metadata {
    name = "ca"
    namespace = "kube-kafka"
  }

  data {
    "tls.crt" = "${tls_self_signed_cert.vault-ca.cert_pem}"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
}

# Write the secret
resource "kubernetes_secret" "kafka-cp-kafka-keystores" {
  metadata {
    name = "kafka-cp-kafka-keystores"
    namespace = "kube-kafka"
  }

  data {
    "kafka-cp-kafka-truststore.jks" = "${data.local_file.vault-ca-truststore.content}"
    "kafka-cp-kafka-truststore.password" = "password"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
} 