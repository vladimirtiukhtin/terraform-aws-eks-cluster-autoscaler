resource "kubernetes_deployment_v1" "cluster_autoscaler" {
  metadata {
    name        = local.name
    namespace   = var.namespace
    labels      = local.labels
  }

  spec {

    replicas = var.replicas

    selector {
      match_labels = local.selector_labels
    }

    template {

      metadata {
        annotations = var.pod_annotations
        labels      = local.labels
      }

      spec {

        service_account_name            = kubernetes_service_account_v1.cluster_autoscaler.metadata.0.name
        automount_service_account_token = true

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                dynamic "match_expressions" {
                  for_each = local.selector_labels
                  content {
                    key      = match_expressions.key
                    operator = "In"
                    values   = [match_expressions.value]
                  }
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = var.user_id
          run_as_group    = var.group_id
        }

        container {
          name               = var.name
          image              = "${var.image_name}:v${var.image_tag}"
          image_pull_policy = var.image_pull_policy
          command = ["/cluster-autoscaler"]
          args = [
            "--cloud-provider=aws",
            "--stderrthreshold=info",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled"
          ]

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }

        }

        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.key
            operator = toleration.value["operator"]
            value    = toleration.value["value"]
            effect   = toleration.value["effect"]
          }
        }

      }

    }

  }
  wait_for_rollout = var.wait_for_rollout
  depends_on = [
    kubernetes_cluster_role_binding
  ]
}
