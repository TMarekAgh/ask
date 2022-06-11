

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
        type    = "app"
        value   = digitalocean_app.remember_app.id
    }
}


# Applications


locals {
  db_connection     = digitalocean_database_cluster.remember_mongodb_cluster.private_uri
  api_port          = 33455
  app_auth_port     = 33456
  user_auth_port    = 33457
}

resource "digitalocean_app" "remember_app" {
    spec {
        name    = "${var.base_name}_app"
        region  = var.region

        alert {
            rule = "DEPLOYMENT_FAILED"
        }

        alert {
            rule = "DOMAIN_FAILED"
        }

        domain {
            name = "rmbr.com" 
        }

        service {
            name                = "${var.base_name}_app_auth_ms"
            dockerfile_path     = "./app-auth-ms/Dockerfile"
            environment_slug    = "node" # only for icon
            instance_count      = 1 

            internal_ports = [ locals.api_port, locals.user_auth_port ]

            routes {
                path = "/api"
            }     

            github {
               repo     = "<app-auth-repo-link>"
               branch   = "master"
            }

            alert {
                rule        = "CPU_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            alert {
                rule        = "MEM_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            env {
                key     = "DB_USER"
                value   = digitalocean_database_user.remember_app_auth_access.name
            }

            env {
                key     = "DB_PASS"
                value   = digitalocean_database_user.remember_app_auth_access.password
            }

            env {
                key     = "PORT"
                value   = tostring(locals.app_auth_port)
            }

            env {
                key     = "HOST"
                value   = "localhost"
            }

            env {
                key     = "SECRET"
                value   = var.app_auth_secret
                type    = "SECRET"
            }            

            env {
                key     = "DB_CONN"
                value   = "${locals.db_connection}/${digitalocean_database_db.remember_app_auth_db.name}"
            }
        }    

        service {
            name                = "${var.base_name}_user_auth_ms"
            dockerfile_path     = "./user-auth-ms/Dockerfile"
            environment_slug    = "node" # only for icon
            instance_count      = 1

            github {
               repo     = "<user-auth-repo-link>"
               branch   = "master"
            }

            internal_ports = [ locals.api_port, locals.app_auth_port ]

            alert {
                rule        = "CPU_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            alert {
                rule        = "MEM_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            env {
                key     = "DB_CONN"
                value   = "${locals.db_connection}/${digitalocean_database_db.remember_user_auth_db.name}"
            }

            env {
                key     = "PORT"                
                value   = tostring(locals.user_auth_port)
            }

            env {
                key     = "HOST"
                value   = "localhost"
            }

            env {
                key     = "APP_AUTH_PORT"
                value   = tostring(locals.app_auth_port)
            }

            env {
                key     = "APP_AUTH_HOST"
                value   = "localhost"
            }

            env {
                key     = "DB_USER"
                value   = digitalocean_database_user.remember_user_auth_access.name
            }

            env {
                key     = "DB_PASS"
                value   = digitalocean_database_user.remember_user_auth_access.password
                type    = "SECRET"
            }

            env {
                key     = "GITHUB_LOGIN_URL"
                value   = "https://github.com/login/oauth/authorize"
            }

            env {
                key     = "GITHUB_TOKEN_URL"
                value   = "https://github.com/login/oauth/access_token"
            }

            env {
                key     = "GITHUB_API_URL"
                value   = "https://api.github.com"
            }

            env {
                key     = "GITHUB_CLIENT_ID"
                value   = var.github_client_id
                type    = "SECRET"
            }

            env {
                key     = "GITHUB_CLIENT_SECRET"
                value   = var.github_client_secret
                type    = "SECRET"
            }

            env {
                key     = "JWT_SECRET"
                value   = var.user_auth_secret
                type    = "SECRET"
            }

            env {
                key     = "JWT_EXPIRATION"
                value   = "6000s"
            }
        }

        service {
            name                = "${var.base_name}_api"
            dockerfile_path     = "./Dockerfile"
            environment_slug    = "node" # only for icon
            instance_count      = 1

            http_port = locals.api_port

            internal_ports = [ locals.app_auth_port, locals.user_auth_port ]

            github {
               repo     = "<api-repo-link>"
               branch   = "master"
            }

            alert {
                rule        = "CPU_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            alert {
                rule        = "MEM_UTILIZATION"
                value       = 80
                operator    = "GREATER_THAN"
                window      = "TEN_MINUTES"
            }

            env {
                key     = "PORT"                
                value   = tostring(locals.api_port)
            }

            env {
                key     = "DB_CONN"
                value   = "${locals.db_connection}/${digitalocean_database_db.remember_api_db.name}"
            }

            env {
                key     = "APP_AUTH_SERVICE_HOST"
                value   = "localhost"
            }

            env {
                key     = "APP_AUTH_SERVICE_PORT"
                value   = tostring(locals.app_auth_port)
            }

            env {
                key     = "USER_AUTH_SERVICE_HOST"
                value   = "localhost" 
            }

            env {
                key     = "USER_AUTH_SERVICE_PORT"
                value   = tostring(locals.user_auth_port)
            }

            env {
                key     = "APP_AUTH_ID"
                value   = var.app_auth_id
                type    = "SECRET"
            }

            env {
                key     = "APP_AUTH_TOKEN"
                value   = var.app_auth_token
                type    = "SECRET"
            }
        }

        service {
            name                = "${var.base_name}_app"
            dockerfile_path     = "./Dockerfile"
            environment_slug    = "node" # only for icon
            instance_count      = 1

            github {
                repo     = "<app-repo-link>"
                branch   = "master"
            }

            routes {
                path = "/"
            }

            http_port = 443

        }

        database {
          cluster_name = digitalocean_database_cluster.remember_mongodb_cluster.name
          production = false
        }
    }
}


# Projects


resource "digitalocean_project" "remember" {
    name        = "${var.base_name}"
    description = "Remember project infrastructure"
    environment = "Development"
    resources   = [
        digitalocean_database_cluster.remember_mongodb_cluster.urn
    ]
}