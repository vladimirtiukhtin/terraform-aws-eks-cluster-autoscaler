data "aws_iam_openid_connect_provider" "eks_cluster" {
  arn = var.openid_connect_provider_arn
}

resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  metadata {
    name      = local.name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.cluster_autoscaler.arn
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = join("", [for word in regexall("[[:word:]]", local.name) : title(word)])
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = data.aws_iam_openid_connect_provider.eks_cluster.arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${data.aws_iam_openid_connect_provider.eks_cluster.url}:aud" = "sts.amazonaws.com"
              "${data.aws_iam_openid_connect_provider.eks_cluster.url}:sub" = "system:serviceaccount:${var.namespace}:${local.name}"
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "ClusterAutoscaler"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup",
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "kubernetes_cluster_role_binding_v1" "cluster_autoscaler" {
  metadata {
    name = local.name
    labels = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.cluster_autoscaler.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler.metadata.0.name
    namespace = var.namespace
  }
}


resource "kubernetes_cluster_role_v1" "cluster_autoscaler" {
  metadata {
    name   = local.name
    labels = local.labels
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }

  rule {
    api_groups = [""]
    resources = [
      "namespaces",
      "pods",
      "services",
      "replicationcontrollers",
      "persistentvolumeclaims",
      "persistentvolumes"
    ]
    verbs = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }
}

resource "kubernetes_role_binding_v1" "cluster_autoscaler" {
  metadata {
    name      = local.name
    namespace = var.namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.cluster_autoscaler.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler.metadata.0.name
    namespace = var.namespace
  }
}


resource "kubernetes_role_v1" "cluster_autoscaler" {
  metadata {
    name      = local.name
    namespace = var.namespace
    labels    = local.labels
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs          = ["delete", "get", "update", "watch"]
  }
}
