# Registry module — provisions a local Docker registry.
#
# Used for local pipeline testing. Push images here instead of
# ghcr.io to avoid needing cloud credentials for demos.
#
# In production on AWS, you'd use ECR:
# resource "aws_ecr_repository" "app" {
#   name                 = "devsecops-demo"
#   image_tag_mutability = "IMMUTABLE"  # Prevent tag overwriting
#   image_scanning_configuration {
#     scan_on_push = true  # Automatic Trivy-like scanning
#   }
# }

variable "registry_version" {
  type    = string
  default = "2"
}

variable "registry_port" {
  type    = number
  default = 5000
}

resource "docker_image" "registry" {
  name = "registry:${var.registry_version}"
}

resource "docker_container" "registry" {
  name  = "devsecops-registry"
  image = docker_image.registry.image_id

  ports {
    internal = 5000
    external = var.registry_port
  }

  volumes {
    host_path      = "/tmp/devsecops-registry"
    container_path = "/var/lib/registry"
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD", "wget", "--spider", "-q", "http://localhost:5000/v2/"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "5s"
  }
}

output "registry_address" {
  value = "localhost:${var.registry_port}"
}

output "container_id" {
  value = docker_container.registry.id
}
