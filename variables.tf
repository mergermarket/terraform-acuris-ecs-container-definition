variable "name" {
  description = "Name/name prefix to apply to the resources in the module"
}

variable "image" {
  description = "The docker image to use"
}

variable "cpu" {
  description = "The CPU limit for this container definition"
  default     = "64"
}

variable "privileged" {
  description = "Gives the container privileged access to the host"
  type = bool
  default = false
}

variable "memory" {
  description = "The memory limit for this container definition"
  default     = "256"
}

variable "command" {
  description = "The command that is passed to the container"
  type        = list(string)
  default     = []
}

variable "nofile_soft_ulimit" {
  description = "The soft ulimit for the number of files in container"
  default     = "4096"
}

variable "container_port" {
  description = "App port to expose in the container"
  default     = "8080"
}

variable "container_env" {
  description = "Environment variables for this container"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to be applied to the docker container"
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "DEPRECATED - values passed to this variable will be ignored"
  type        = map(string)
  default     = {}
}

variable "mountpoint" {
  description = "Mountpoint map with 'sourceVolume' and 'containerPath' and 'readOnly' (optional)."
  type        = map(string)
  default     = {}
}

variable "port_mappings" {
  description = "JSON document containing an array of port mappings for the container defintion - if set container_port is ignored (optional)."
  default     = ""
  type        = string
}

variable "application_secrets" {
  type    = list(string)
  default = []
}

variable "platform_secrets" {
  type    = list(string)
  default = []
}

variable "stop_timeout" {
  description = "The duration is seconds to wait before the container is forcefully killed. Default 30s, max 120s."
  default     = "none"
}
variable "extra_hosts" {
  description = "values to add to /etc/hosts in the container"
  type = list(any)
  default = []
}

variable "container_depends_on" {
  description = "..."
  type = list(object({
    condition      = string
    containerName  = string
  }))
  default = []
}

variable "container_links" {
  description = "..."
  type = list(string)
  default = []
}

variable "enable_cafagent_sidecar" {
  description = "Include a FireLens CAF agent sidecar and route application stdout and stderr through it."
  type        = bool
  default     = false
}

variable "cafagent_image" {
  description = "CAF agent Fluent Bit image. Required when enable_cafagent_sidecar is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_cafagent_sidecar || try(trimspace(var.cafagent_image) != "", false)
    error_message = "cafagent_image must be set when enable_cafagent_sidecar is true."
  }
}

variable "cafagent_cpu" {
  description = "CPU units reserved for the CAF agent sidecar."
  type        = number
  default     = 128
}

variable "cafagent_memory" {
  description = "Memory in MiB reserved for the CAF agent sidecar."
  type        = number
  default     = 128
}

variable "cafagent_environment" {
  description = "Environment variables for the CAF agent sidecar."
  type        = map(string)
  default     = {}
}

variable "cafagent_secrets" {
  description = "ECS Secrets Manager secret definitions for the CAF agent sidecar."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "cafagent_mount_points" {
  description = "Mount points for the CAF agent sidecar."
  type        = list(any)
  default     = []
}

variable "app_firelens_log_options" {
  description = "FireLens output options used by the application container when the sidecar is enabled."
  type        = map(string)
  default     = {}
}

variable "cafagent_log_configuration" {
  description = "ECS log configuration for the CAF agent sidecar. Required when the sidecar is enabled."
  type = object({
    logDriver = string
    options   = map(string)
  })
  default = null

  validation {
    condition     = !var.enable_cafagent_sidecar || var.cafagent_log_configuration != null
    error_message = "cafagent_log_configuration must be set when enable_cafagent_sidecar is true."
  }
}

variable "firelens_configuration_options" {
  description = "FireLens Fluent Bit configuration options for the CAF agent sidecar."
  type        = map(string)
  default = {
    "config-file-type"        = "file"
    "config-file-value"       = "/fluent-bit/etc/custom-caf-agent.conf"
    "enable-ecs-log-metadata" = "true"
  }
}