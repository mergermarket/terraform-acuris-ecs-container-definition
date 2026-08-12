# configure provider to not try too hard talking to AWS API
provider "aws" {
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  max_retries                 = 1
  access_key                  = "a"
  secret_key                  = "a"
  region                      = "eu-west-1"
}


# fixture
module "tf_ecs_container_definition_test" {
  source              = "../.."
  cpu                 = var.cpu
  memory              = var.memory
  command             = var.command
  name                = var.name
  image               = var.image
  nofile_soft_ulimit  = var.nofile_soft_ulimit
  container_port      = var.container_port
  labels              = var.labels
  port_mappings       = var.port_mappings
  mountpoint          = var.mountpoint
  container_env       = var.container_env
  metadata            = var.metadata
  application_secrets = var.application_secrets
  platform_secrets    = var.platform_secrets
  extra_hosts         = var.extra_hosts
  enable_cafagent_sidecar        = var.enable_cafagent_sidecar
  cafagent_image                 = var.cafagent_image
  cafagent_cpu                   = var.cafagent_cpu
  cafagent_memory                = var.cafagent_memory
  cafagent_environment           = var.cafagent_environment
  cafagent_secrets               = var.cafagent_secrets
  cafagent_mount_points          = var.cafagent_mount_points
  app_firelens_log_options       = var.app_firelens_log_options
  cafagent_log_configuration     = var.cafagent_log_configuration
  firelens_configuration_options = var.firelens_configuration_options
}

variable "name" {}

variable "image" {}

variable "nofile_soft_ulimit" {
  default     = "4096"
}

variable "container_port" { default = "8080" }
 
variable "labels" { default = {} }
 
variable "port_mappings" { default = "" }
 
variable "mountpoint" { default = {} }
 
variable "container_env" { default = {} }
 
variable "metadata" { default = {} }
 
variable "application_secrets" { default = [] }

variable "platform_secrets" { default = [] }

variable "memory" { default = "256" }

variable "cpu" { default = "64" }

variable "command" { default = [] }

variable "extra_hosts" { default = []}

variable "enable_cafagent_sidecar" {
  type    = bool
  default = false
}

variable "cafagent_image" {
  type    = string
  default = null
}

variable "cafagent_cpu" {
  type    = number
  default = 128
}

variable "cafagent_memory" {
  type    = number
  default = 128
}

variable "cafagent_environment" {
  type    = map(string)
  default = {}
}

variable "cafagent_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "cafagent_mount_points" {
  type    = list(any)
  default = []
}

variable "app_firelens_log_options" {
  type    = map(string)
  default = {}
}

variable "cafagent_log_configuration" {
  type = object({
    logDriver = string
    options   = map(string)
  })
  default = null
}

variable "firelens_configuration_options" {
  type = map(string)
  default = {
    "config-file-type"        = "file"
    "config-file-value"       = "/fluent-bit/etc/custom-caf-agent.conf"
    "enable-ecs-log-metadata" = "true"
  }
}
  
output "rendered" {
  value = module.tf_ecs_container_definition_test.rendered
}

output "rendered_definitions" {
  value = module.tf_ecs_container_definition_test.rendered_definitions
}
