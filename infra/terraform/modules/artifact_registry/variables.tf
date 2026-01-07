variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "location" {
  description = "The location of the repository"
  type        = string
}

variable "repository_id" {
  description = "The repository ID"
  type        = string
}

variable "description" {
  description = "The description of the repository"
  type        = string
  default     = ""
}

variable "format" {
  description = "The format of the repository"
  type        = string
  default     = "DOCKER"
}
