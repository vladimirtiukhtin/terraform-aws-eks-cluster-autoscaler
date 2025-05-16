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
