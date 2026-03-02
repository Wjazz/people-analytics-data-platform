# =============================================================================
# Outputs — Bourbaki Engine GCP Infrastructure
# =============================================================================

output "cloud_run_url" {
  description = "URL pública del servicio Causal Engine en Cloud Run"
  value       = google_cloud_run_v2_service.causal_engine.uri
}

output "cloud_sql_connection_name" {
  description = "Connection name para Cloud SQL Proxy (project:region:instance)"
  value       = google_sql_database_instance.bourbaki_db_master.connection_name
}

output "cloud_sql_public_ip" {
  description = "IP pública de la instancia Cloud SQL"
  value       = google_sql_database_instance.bourbaki_db_master.public_ip_address
}

output "database_url" {
  description = "Connection string completa para PostgreSQL (SENSIBLE)"
  value       = local.database_url
  sensitive   = true
}

output "artifact_registry_repo" {
  description = "URI del repositorio Docker en Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.bourbaki_docker.repository_id}"
}
