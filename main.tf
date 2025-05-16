terraform {
  required_version = ">=1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0"
    }
  }

}

locals {
  name = var.instance != null ? "${var.name}-${var.instance}" : var.name
  selector_labels = merge({
    "app.kubernetes.io/name" = var.name
    }, var.instance != null ? {
    "app.kubernetes.io/instance" = var.instance
  } : {})
  common_labels = {
    "app.kubernetes.io/version"    = var.image_tag
    "app.kubernetes.io/managed-by" = "terraform"
  }
  labels = merge(var.extra_labels, local.common_labels, local.selector_labels)
}
