output "rendered" {
  value = templatefile(
    "${path.module}/container_definition.json.tmpl",
    {
      image                    = var.image
      container_name           = var.name
      port_mappings            = var.port_mappings == "" ? format("[ { \"containerPort\": %s } ]", var.container_port) : var.port_mappings
      cpu                      = var.cpu
      privileged               = var.privileged
      mem                      = var.memory    
      stop_timeout             = var.stop_timeout
      command                  = length(var.command) > 0 ? jsonencode(var.command) : "null"
      container_env            = data.external.encode_env.result["env"]
      secrets                  = data.external.encode_secrets.result["secrets"]
      labels                   = jsonencode(var.labels)
      nofile_soft_ulimit       = var.nofile_soft_ulimit
      mountpoint_sourceVolume  = lookup(var.mountpoint, "sourceVolume", "none")
      mountpoint_containerPath = lookup(var.mountpoint, "containerPath", "none")
      mountpoint_readOnly      = lookup(var.mountpoint, "readOnly", false)
      extra_hosts              = local.extra_hosts == [] ? "null" : jsonencode(local.extra_hosts)
      depends_on               = local.container_depends_on == "[]" ? "null" : local.container_depends_on
      links                    = local.container_links == "[]" ? "null" : local.container_links      
  })
}

output "rendered_definitions" {
  description = "Rendered JSON array containing the application container and, when enabled, the CAF agent sidecar."

  value = templatefile(
    "${path.module}/container_definitions.json.tmpl",
    {
      image                          = var.image
      container_name                 = var.name
      port_mappings                  = var.port_mappings == "" ? format("[ { \"containerPort\": %s } ]", var.container_port) : var.port_mappings
      cpu                            = var.cpu
      privileged                     = var.privileged
      mem                            = var.memory
      stop_timeout                   = var.stop_timeout
      command                        = length(var.command) > 0 ? jsonencode(var.command) : "null"
      container_env                  = data.external.encode_env.result["env"]
      secrets                        = data.external.encode_secrets.result["secrets"]
      labels                         = jsonencode(var.labels)
      nofile_soft_ulimit             = var.nofile_soft_ulimit
      mountpoint_sourceVolume        = lookup(var.mountpoint, "sourceVolume", "none")
      mountpoint_containerPath       = lookup(var.mountpoint, "containerPath", "none")
      mountpoint_readOnly            = lookup(var.mountpoint, "readOnly", false)
      extra_hosts                    = local.extra_hosts == [] ? "null" : jsonencode(local.extra_hosts)
      depends_on                     = local.container_depends_on == "[]" ? "null" : local.container_depends_on
      links                          = local.container_links == "[]" ? "null" : local.container_links
      enable_cafagent_sidecar        = var.enable_cafagent_sidecar
      cafagent_image                 = var.cafagent_image
      cafagent_cpu                   = var.cafagent_cpu
      cafagent_memory                = var.cafagent_memory
      cafagent_environment           = data.external.encode_cafagent_env.result["env"]
      cafagent_secrets               = jsonencode(var.cafagent_secrets)
      cafagent_mount_points          = jsonencode(var.cafagent_mount_points)
      app_firelens_log_options       = jsonencode(var.app_firelens_log_options)
      cafagent_log_configuration     = jsonencode(var.cafagent_log_configuration)
      firelens_configuration_options = jsonencode(var.firelens_configuration_options)
    }
  )
}

