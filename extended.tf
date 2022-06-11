

#                                      REMEMEBER API INFRASTRUCTURE                                 #


# Variables


variable "base_name" {
    type = string
}

variable "region" {
    type = string
}

variable "do_token" {
    type = string
}

variable "app_auth_secret" {
    type = string
    sensitive = true
}

variable "app_auth_token" {
    type = string
    sensitive = true
}

variable "app_auth_id" {
    type = string
}

variable "user_auth_secret" {
    type = string
    sensitive = true
}

variable "github_client_id" {
    type = string
}

variable "github_client_secret" {
    type = string
    sensitive = true
}

# Providers


terraform {
    required_providers {
        digitalocean = {
            source  = "digitalocean/digitalocean"
            version = "~> 2.0"
        }
    }
}

provider "digitalocean" {
    token = var.do_token
}


# Tags


resource "digitalocean_tag" "remember_tag" {
    name = "remember"
}


# Network


resource "digitalocean_vpc" "remember_vpc" {
    name        = "${var.base_name}_vpc"
    region      = var.region
    ip_range    = "10.10.10.0/24"
    description = "Main VPC for Remember Project"
    # tags        = [digitalocean_tag.remember_tag.id]
}


#Images


data "digitalocean_spaces_bucket" "remember_images" {
    name    = "${var.base_name}_images"
    region  = var.region
}

//Should be created along with a bucket
# resource "digitalocean_spaces_bucket_policy" "foobar" {
#   region = digitalocean_spaces_bucket.foobar.region
#   bucket = digitalocean_spaces_bucket.foobar.name
#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "IPAllow",
#             "Effect": "Deny",
#             "Principal": "*",
#             "Action": "s3:*",
#             "Resource": [
#                 "arn:aws:s3:::${digitalocean_spaces_bucket.foobar.name}",
#                 "arn:aws:s3:::${digitalocean_spaces_bucket.foobar.name}/*"
#             ],
#             "Condition": {
#                 "NotIpAddress": {
#                     "aws:SourceIp": "54.240.143.0/24"
#                 }
#             }
#         }
#     ]
#   })
# }

resource "digitalocean_custom_image" "app_auth_image" {
    name    = "app_auth"
    url     = "${data.digitalocean_spaces_bucket.remember_images.bucket_domain_name}/<app_auth_image_file>"
    regions = [var.region]
}

resource "digitalocean_custom_image" "user_auth_image" {
    name    = "user_auth"
    url     = "${data.digitalocean_spaces_bucket.remember_images.bucket_domain_name}/<user_auth_image_file>"
    regions = [var.region]
}

resource "digitalocean_custom_image" "remember_api_image" {
    name    = "remember_api"
    url     = "${data.digitalocean_spaces_bucket.remember_images.bucket_domain_name}/<remember_api_image_file>"
    regions = [var.region]
}


# Droplets


locals {
  db_connection     = digitalocean_database_cluster.remember_mongodb_cluster.private_uri
  api_port          = 33455
  app_auth_port     = 33456
  user_auth_port    = 33457
}

resource "digitalocean_ssh_key" "remember_droplets_key" {
  name       = "remember_droplets_key"
  public_key = file("<key file>")
}

resource "digitalocean_droplet" "remember_app_auth_1" {
    image   = digitalocean_custom_image.app_auth_image.id
    name    = "remember_app_auth_1"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_droplet" "remember_app_auth_2" {
    image   = digitalocean_custom_image.app_auth_image.id
    name    = "remember_app_auth_2"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_droplet" "remember_user_auth_1" {
    image   = digitalocean_custom_image.user_auth_image.id
    name    = "remember_user_auth_1"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_droplet" "remember_user_auth_2" {
    image   = digitalocean_custom_image.user_auth_image.id
    name    = "remember_user_auth_2"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_droplet" "remember_api_1" {
    image   = digitalocean_custom_image.remember_api_image.id
    name    = "remember_api_1"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_droplet" "remember_api_2" {
    image   = digitalocean_custom_image.remember_api_image.id
    name    = "remember_api_2"
    region  = var.region
    size    = "s-1vcpu-1gb"
    ssh_keys = [ digitalocean_ssh_key.remember_droplets_key.fingerprint ]
    monitoring = true
    vpc_uuid = digitalocean_vpc.remember_vpc.id
    tags = [digitalocean_tag.remember_tag.id]    
}

resource "digitalocean_volume" "api_volume" {
  region                  = var.region
  name                    = "api_volume"
  size                    = 1024
  initial_filesystem_type = "ext4"
  description             = "Volume for API file storage"
}

# Volumes

resource "digitalocean_volume_attachment" "api_1_volume_attachement" {
  droplet_id = digitalocean_droplet.remember_api_1.id
  volume_id  = digitalocean_volume.api_volume.id
}

resource "digitalocean_volume_attachment" "api_2_volume_attachement" {
  droplet_id = digitalocean_droplet.remember_api_2.id
  volume_id  = digitalocean_volume.api_volume.id
}

resource "digitalocean_volume_snapshot" "api_volume_snapshot" {
  name      = "api_volume_snapshot"
  volume_id = digitalocean_volume.api_volume.id
}

# Droplet Snapshots

resource "digitalocean_droplet_snapshot" "remember_app_auth_1_snapshot" {  
  droplet_id = digitalocean_droplet.remember_app_auth_1.id
  name       = "remember_app_auth_1_snapshot"
}

resource "digitalocean_droplet_snapshot" "remember_app_auth_2_snapshot" {
  droplet_id = digitalocean_droplet.remember_app_auth_2.id
  name       = "remember_app_auth_2_snapshot"
}

resource "digitalocean_droplet_snapshot" "remember_user_auth_1_snapshot" {
  droplet_id = digitalocean_droplet.remember_user_auth_1.id
  name       = "remember_user_auth_1_snapshot"
}

resource "digitalocean_droplet_snapshot" "remember_user_auth_2_snapshot" {
  droplet_id = digitalocean_droplet.remember_user_auth_2.id
  name       = "remember_user_auth_2_snapshot"
}

resource "digitalocean_droplet_snapshot" "remember_api_1_snapshot" {
  droplet_id = digitalocean_droplet.remember_api_1.id
  name       = "remember_api_1_snapshot"
}

resource "digitalocean_droplet_snapshot" "remember_api_2_snapshot" {
  droplet_id = digitalocean_droplet.remember_api_2.id
  name       = "remember_api_2_snapshot"
}

resource "digitalocean_monitor_alert" "droplet_cpu_alerts" {
  window      = "10m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 90
  enabled     = true
  entities    = [
      digitalocean_droplet.remember_app_auth_1.id,
      digitalocean_droplet.remember_app_auth_2.id,
      digitalocean_droplet.remember_user_auth_1.id,
      digitalocean_droplet.remember_user_auth_2.id,
      digitalocean_droplet.remember_api_1.id,
      digitalocean_droplet.remember_api_2.id
    ]
  description = "CPU usage alert"
}

resource "digitalocean_monitor_alert" "droplet_memory_alerts" {
  window      = "10m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 90
  enabled     = true
  entities    = [
      digitalocean_droplet.remember_app_auth_1.id,
      digitalocean_droplet.remember_app_auth_2.id,
      digitalocean_droplet.remember_user_auth_1.id,
      digitalocean_droplet.remember_user_auth_2.id,
      digitalocean_droplet.remember_api_1.id,
      digitalocean_droplet.remember_api_2.id
    ]
  description = "Memory usage alert"
}

# Loadbalancers

resource "digitalocean_loadbalancer" "app_auth_loadbalancer" {
    name    = "app_auth_loadbalancer"
    region  = var.region

    forwarding_rule {
      entry_port            = locals.app_auth_port
      entry_protocol        = "https"

      target_port           = locals.app_auth_port
      target_protocol       = "https"
    }

    redirect_http_to_https = true

    droplet_ids = [
        digitalocean_droplet.remember_app_auth_1.id,
        digitalocean_droplet.remember_app_auth_2.id
    ]

    vpc_uuid = digitalocean_vpc.remember_vpc.id
}

resource "digitalocean_loadbalancer" "user_auth_loadbalancer" {
    name    = "user_auth_loadbalancer"
    region  = var.region

    forwarding_rule {
      entry_port            = locals.user_auth_port
      entry_protocol        = "https"

      target_port           = locals.user_auth_port
      target_protocol       = "https"
    }

    redirect_http_to_https = true

    droplet_ids = [
        digitalocean_droplet.remember_user_auth_1.id,
        digitalocean_droplet.remember_user_auth_2.id
    ]

    vpc_uuid = digitalocean_vpc.remember_vpc.id
}

resource "digitalocean_loadbalancer" "remember_api_loadbalancer" {
    name    = "remember_api_loadbalancer"
    region  = var.region

    forwarding_rule {
      entry_port            = locals.api_port
      entry_protocol        = "https"

      target_port           = locals.api_port
      target_protocol       = "https"
    }

    redirect_http_to_https = true

    droplet_ids = [
        digitalocean_droplet.remember_api_1.id,
        digitalocean_droplet.remember_api_2.id
    ]

    vpc_uuid = digitalocean_vpc.remember_vpc.id
}


# Storage


resource "digitalocean_database_cluster" "remember_mongodb_cluster" {
    name                    = "${var.base_name}_mongodb_cluster"
    engine                  = "mongodb"
    version                 = "5"
    size                    = "db-s-1vcpu-1gb"
    region                  = var.region
    node_count              = 3
    private_network_uuid    = digitalocean_vpc.remember_vpc.id
    tags                    = [digitalocean_tag.remember_tag.id]
}

resource "digitalocean_database_user" "remember_app_auth_access" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "${var.base_name}_app_auth_access"
}

resource "digitalocean_database_user" "remember_user_auth_access" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "${var.base_name}_user_auth_access"
}

resource "digitalocean_database_user" "remember_api_access" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "${var.base_name}_api_access"
}

resource "digitalocean_database_db" "remember_app_auth_db" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "app_auth" 
}

resource "digitalocean_database_db" "remember_user_auth_db" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "user_auth" 
}

resource "digitalocean_database_db" "remember_api_db" {
    cluster_id  = digitalocean_database_cluster.remember_mongodb_cluster.id
    name        = "remember" 
}

resource "digitalocean_database_firewall" "remember_mongodb_cluster_firewall" {
    cluster_id = digitalocean_database_cluster.remember_mongodb_cluster.id

    rule {
        type    = "tag"
        value   = digitalocean_tag.remember_tag.name
    }
}


# Domain

resource "digitalocean_domain" "remember_domain" {
  name       = "remember_domain"
}

resource "digitalocean_record" "www_app" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "www"
  value  = digitalocean_loadbalancer.remember_api_loadbalancer.ip
}

# resource "digitalocean_record" "www_api" {
#   domain = digitalocean_domain.default.id
#   type   = "A"
#   name   = "www.api"
#   value  = fqdn.
# }


# Website


data "digitalocean_spaces_bucket" "remember_app" {
    name    = "${var.base_name}_app_files"
    region  = var.region
}

resource "digitalocean_cdn" "app_cdn" {
    origin = data.digitalocean_spaces_bucket.remember_app.bucket_domain_name
}

output "fqdn" {
    value = digitalocean_cdn.app_cdn.endpoint
}

# Projects


resource "digitalocean_project" "remember" {
    name        = "${var.base_name}"
    description = "Remember project infrastructure"
    environment = "Development"
    resources   = [
        digitalocean_database_cluster.remember_mongodb_cluster.urn,
        digitalocean_droplet.remember_app_auth_1.urn,
        digitalocean_droplet.remember_app_auth_2.urn,
        digitalocean_droplet.remember_user_auth_1.urn,
        digitalocean_droplet.remember_user_auth_2.urn,
        digitalocean_droplet.remember_api_1.urn,
        digitalocean_droplet.remember_api_2.urn,
        digitalocean_domain.remember_domain.urn,
        digitalocean_loadbalancer.app_auth_loadbalancer.urn,
        digitalocean_loadbalancer.user_auth_loadbalancer.urn,
        digitalocean_loadbalancer.remember_api_loadbalancer.urn,
        digitalocean_volume.api_volume.urn,
        digitalocean_spaces_bucket.remember_images.urn,
        digitalocean_spaces_bucket.remember_app.urn
    ]
}