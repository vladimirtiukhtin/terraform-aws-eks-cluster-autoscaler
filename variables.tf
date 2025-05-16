variable "name" {
  description = "Basename for all kubernetes resources"
  type        = string
  default     = "cluster-autoscaler"
}

variable "instance" {
  description = "If defined adds suffix to all kubernetes resources allowing multiple deployments of the module"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "kube-system"
}

variable "replicas" {
  description = "Number of pods"
  type        = number
  default     = 1
}

variable "user_id" {
  description = "Unix UID"
  type        = number
  default     = 65534
}

variable "group_id" {
  description = "Unix GID"
  type        = number
  default     = 65534
}

variable "image_name" {
  description = "Container image name including registry address"
  type        = string
  default     = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "image_tag" {
  description = "Container image tag (version)"
  type        = string
  default     = "1.26.2"
}

variable "image_pull_policy" {
  description = "Always, IfNotPresent or Never"
  type        = string
  default     = "IfNotPresent"
}

variable "pod_annotations" {
  description = ""
  type        = map(any)
  default     = {}
}

variable "openid_connect_provider_arn" {
  description = "AWS IAM OpenID provider ARN associated with the EKS cluster"
  type        = string
}

variable "tolerations" {
  description = "List of node taints a pod tolerates"
  type = map(object({
    operator = optional(string, null)
    value    = optional(string, null)
    effect   = optional(string, null)
  }))
  default = {
    "node-role.kubernetes.io/master" = {
      effect = "NoSchedule"
    }
  }
}

variable "extra_labels" {
  description = "Any extra labels to apply to all kubernetes resources"
  type        = map(string)
  default     = {}
}

variable "wait_for_rollout" {
  description = "Whether to wait for kubernetes readiness probe to succeed"
  type        = bool
  default     = true
}
