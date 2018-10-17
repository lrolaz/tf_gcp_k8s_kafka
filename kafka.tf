
resource "kubernetes_namespace" "kube-kafka" {
  metadata {
    name = "kube-kafka"
  }
}

# Write the secret
resource "kubernetes_secret" "kafka-ca" {
  metadata {
    name = "kafka-ca"
    namespace = "kube-kafka"
  }

  data {
    "ca.pem" = "${tls_self_signed_cert.vault-ca.cert_pem}"
    "truststore.jks" = "${data.local_file.vault-ca-truststore.content}"
    "truststore.password" = "password"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
} 