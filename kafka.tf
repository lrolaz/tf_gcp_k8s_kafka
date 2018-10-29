
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
resource "kubernetes_secret" "ca-public" {
  metadata {
    name = "ca"
    namespace = "kube-public"
  }

  data {
    "tls.crt" = "${tls_self_signed_cert.vault-ca.cert_pem}"
  }
  
  depends_on = ["google_container_cluster.gcp_kubernetes"]
}
