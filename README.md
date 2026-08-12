`container_definitions` module
-----------------------------

[![Build Status](https://travis-ci.org/mergermarket/tf_ecs_container_definition.svg?branch=master)](https://travis-ci.org/mergermarket/tf_ecs_container_definition)

This module should contain the logic that generates our default set of container definitions,
providing the rendered definitions as an output.

Input variables
---------------

 * `container_name` - (string) **REQUIRED** - Name/name prefix to apply to the resources in the module.
 * `image` - (string) **REQUIRED** - The docker image in use
 * `container_port` - (string) OPTIONAL -App port to expose in the container. Default 8080.
 * `cpu`- (string) OPTIONAL -The CPU limit for this container definition
 * `privileged`- (boolean) OPTIONAL - The container has privileged access to the hosts, default is false.
 * `memory`- (string) OPTIONAL - The memory limit for this container definition
 * `stop_timeout`- (number) OPTIONAL - Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own.
 * `env`: (map) OPTIONAL - map with environment variables
 * `metadata`: (map) OPTIONAL - Set of metadata for this container. It will be passed as environment variables (key uppercased) and labels.
 * `mountpoint`: (map) OPTIONAL - Configuration of one mountpoint for this volume. Map with the values `sourceVolume`, `containerPath` and (optional) `readOnly` .
 * `extra_hosts`: list(object({name=string, ipAdress=string})) OPTIONAL - List of extra hosts to add to the container's /etc/hosts file.

### Optional CAF agent FireLens sidecar

The module continues to produce the existing single application definition through `rendered`.
Set `enable_cafagent_sidecar` to `true` and consume `rendered_definitions` to receive a JSON array
containing the application container plus a CAF agent Fluent Bit FireLens sidecar. When enabled, the
application container uses the `awsfirelens` log driver and its stdout/stderr are routed to the sidecar.

 * `enable_cafagent_sidecar`: (bool) OPTIONAL - Include the CAF agent FireLens sidecar. Default `false`.
 * `cafagent_image`: (string) REQUIRED when enabled - Image containing the CAF agent Fluent Bit configuration.
 * `cafagent_cpu`: (number) OPTIONAL - CPU units reserved for the sidecar. Default `128`.
 * `cafagent_memory`: (number) OPTIONAL - Memory in MiB reserved for the sidecar. Default `128`.
 * `cafagent_environment`: (map(string)) OPTIONAL - Environment variables passed to the sidecar.
 * `cafagent_secrets`: (list(object({name=string, valueFrom=string}))) OPTIONAL - ECS secret definitions passed to the sidecar.
 * `cafagent_mount_points`: (list(any)) OPTIONAL - ECS mount points passed to the sidecar.
 * `app_firelens_log_options`: (map(string)) OPTIONAL - FireLens output options for the application container.
 * `cafagent_log_configuration`: (object({logDriver=string, options=map(string)})) REQUIRED when enabled - Log configuration for the sidecar itself, normally an `awslogs` configuration.
 * `firelens_configuration_options`: (map(string)) OPTIONAL - Fluent Bit FireLens configuration. By default it reads `/fluent-bit/etc/custom-caf-agent.conf` from the sidecar image and enables ECS log metadata.

Usage
-----

```hcl
module "container_defintions" {
  source = "mergermarket/ecs-container-definition/acuris"

  name           = "some-app"
  image          = "repo/image"
  container_port = "8080"
  cpu            = 1024
  memory         = 256

  container_env = {
    VAR1 = "value1"
    VAR2 = "value2"
  }

  metadata = {
    "label1" = "label.one"
    "label2" = "label.two"
  }

  mountpoint = {
    sourceVolume  = 'data_volume',
    containerPath = '/mnt/data',
    readOnly      = true
  }
  extraHosts = [{"hostname": "host1", "ipAddress": "10.0.0.1"}]
}
```

### CAF agent FireLens sidecar example

```hcl
module "container_definitions" {
  source = "mergermarket/ecs-container-definition/acuris"

  name   = "news-api"
  image  = "example/news-api:sha"
  cpu    = 128
  memory = 1028

  enable_cafagent_sidecar = true
  cafagent_image          = "example/caf-agent:sha"

  app_firelens_log_options = {
    Name = "opensearch"
    Host = "logs.example.internal"
    Port = "443"
    TLS  = "On"
  }

  cafagent_log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/news-api"
      awslogs-region        = "eu-west-1"
      awslogs-stream-prefix = "caf-agent-ecs"
    }
  }
}
```

Outputs
-------

 * `rendered`: rendered container definition
 * `rendered_definitions`: rendered JSON array containing the application container and, when enabled, the CAF agent sidecar
