# variables.tf

variable "project_name" {
  description = "Project identifier (used in resource names)"
  default     = "qrcode"
}

variable "environment" {
  description = "Environment name (e.g. prod)"
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  default     = "Central India"
}

variable "github_owner" {
  description = "GitHub organization or user name"
}

variable "github_repo" {
  description = "GitHub repository name"
}

variable "github_token" {
  description = "Personal Access Token for GitHub (to set secrets)"
  sensitive   = true
}
