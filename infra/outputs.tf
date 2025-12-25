output "repositories" {
	description = "Created repositories by name"
	value       = [for r in github_repository.apps : r.name]
}

output "app_urls" {
	description = "Custom domain URLs per app"
	value       = { for a in var.apps : a.name => "https://${a.subdomain}" }
}
