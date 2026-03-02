# =============================================================================
# Bourbaki Engine — GCP Infrastructure
# Provider: Google Cloud Platform
# Resources: Cloud SQL (PostgreSQL 14), Artifact Registry, Cloud Run v2
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# 1. Cloud SQL — PostgreSQL 14 (bourbaki-db-master)
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "bourbaki_db_master" {
  name             = "bourbaki-db-master"
  database_version = "POSTGRES_14"
  region           = var.region

  # Previene destrucción accidental en producción
  deletion_protection = true

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL" # Upgradar a REGIONAL para HA en producción
    disk_size         = 20      # GB, auto-crecimiento habilitado
    disk_autoresize   = true
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00" # UTC — ventana de backup
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled = true # IP pública — para Cloud Run serverless connector

      authorized_networks {
        name  = "allow-cloud-run"
        value = "0.0.0.0/0" # En producción: restringir a VPC connector
      }
    }

    maintenance_window {
      day          = 7 # Domingo
      hour         = 4 # 4 AM UTC
      update_track = "stable"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }
  }
}

resource "google_sql_database" "bourbaki_db" {
  name     = var.db_name
  instance = google_sql_database_instance.bourbaki_db_master.name
}

resource "google_sql_user" "bourbaki_user" {
  name     = var.db_user
  instance = google_sql_database_instance.bourbaki_db_master.name
  password = var.db_password
}

# -----------------------------------------------------------------------------
# 2. Artifact Registry — Repositorio Docker
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "bourbaki_docker" {
  location      = var.region
  repository_id = "bourbaki-docker"
  description   = "Docker images para Bourbaki Engine microservicios"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-latest-10"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }
}

# -----------------------------------------------------------------------------
# 3. Cloud Run v2 — Causal Engine Service
# -----------------------------------------------------------------------------

locals {
  image_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.bourbaki_docker.repository_id}/causal-engine:latest"

  database_url = "postgresql://${var.db_user}:${var.db_password}@${google_sql_database_instance.bourbaki_db_master.public_ip_address}:5432/${var.db_name}"
}

resource "google_cloud_run_v2_service" "causal_engine" {
  name     = "bourbaki-causal-engine"
  location = var.region

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = local.image_uri

      ports {
        container_port = 8000
      }

      # --- Variables de entorno inyectadas ---
      env {
        name  = "DATABASE_URL"
        value = local.database_url
      }

      env {
        name  = "CLOUD_SQL_CONNECTION_NAME"
        value = google_sql_database_instance.bourbaki_db_master.connection_name
      }

      env {
        name  = "ENVIRONMENT"
        value = "production"
      }

      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }

        cpu_idle          = true  # Scale-to-zero
        startup_cpu_boost = true  # Mejora cold start
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }

    # Timeout para operaciones de inferencia causal pesadas
    timeout = "300s"
  }
}

# --- Acceso público (invocación sin autenticación) ---
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.causal_engine.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
