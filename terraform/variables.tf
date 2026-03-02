# =============================================================================
# Variables — Bourbaki Engine GCP Infrastructure
# Todas las credenciales se inyectan vía TF_VAR_* o terraform.tfvars
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "maverick-data-482905"
}

variable "region" {
  description = "GCP region para todos los recursos"
  type        = string
  default     = "us-central1"
}

# --- Cloud SQL ---

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  type        = string
  default     = "bourbaki_db"
}

variable "db_user" {
  description = "Usuario administrador de Cloud SQL (inyectar via TF_VAR_db_user)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de Cloud SQL (inyectar vía TF_VAR_db_password)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "La contraseña de la base de datos debe tener al menos 16 caracteres."
  }
}

variable "db_tier" {
  description = "Machine tier para Cloud SQL (db-f1-micro para dev, db-custom-2-7680 para prod)"
  type        = string
  default     = "db-f1-micro"
}
