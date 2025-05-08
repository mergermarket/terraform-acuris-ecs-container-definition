locals {
  team      = lookup(var.labels, "team", "")
  env       = lookup(var.labels, "env", "")
  component = lookup(var.labels, "component", "")
  extra_hosts = var.extra_hosts
  container_depends_on  = jsonencode(var.container_depends_on)
  container_links  = jsonencode(var.container_links)
}

data "external" "encode_env" {
  program = ["python", "${path.module}/encode_env.py"]

  query = {
    env      = jsonencode(var.container_env)
    metadata = jsonencode(var.metadata)
  }
}

data "external" "encode_secrets" {
  program = ["python", "${path.module}/encode_secrets.py"]

  query = {
    secrets = jsonencode(
      zipmap(
        var.application_secrets,
        data.aws_secretsmanager_secret.secret.*.arn,
      ),
    )
    common_secrets = jsonencode(
      zipmap(
        var.platform_secrets,
        data.aws_secretsmanager_secret.platform_secrets.*.arn,
      ),
    )
  }
}

data "aws_secretsmanager_secret" "secret" {
  count = length(var.application_secrets)
  name  = "${local.team}/${local.env}/${local.component}/${element(var.application_secrets, count.index)}"
}

data "aws_secretsmanager_secret" "platform_secrets" {
  count = length(var.platform_secrets)
  name  = "platform_secrets/${element(var.platform_secrets, count.index)}"
}

