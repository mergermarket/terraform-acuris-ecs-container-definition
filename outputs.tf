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

