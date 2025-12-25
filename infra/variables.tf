variable "github_owner" {
  type    = string
  default = "arthurreira"
}

variable "github_token" {
  type      = string
  sensitive = true
  description = "Classic PAT with repo + delete_repo"
}

# Define your apps and subdomains
variable "apps" {
  type = list(object({
    name      = string       # repo name (lowercase, hyphens)
    subdomain = string       # e.g., app1.arthurreira.dev
    visibility = string      # "public" or "private"
  }))
  
  # Default: simple numbered apps
  default = [
    { name = "hackathon-registration", subdomain = "register.arthurreira.dev", visibility = "public" },
    { name = "hackathon-schedule", subdomain = "schedule.arthurreira.dev", visibility = "public" },
    { name = "hackathon-projects", subdomain = "projects.arthurreira.dev", visibility = "public" },
  ]
  
  # Example: Camping Weekend Game
  # default = [
  #   { name = "camping-game", subdomain = "play.arthurreira.dev", visibility = "public" },
  #   { name = "leaderboard", subdomain = "scores.arthurreira.dev", visibility = "public" },
  #   { name = "admin-panel", subdomain = "admin.arthurreira.dev", visibility = "private" },
  # ]
  
  # Example: Multi-tenant SaaS
  # default = [
  #   { name = "client-acme", subdomain = "acme.arthurreira.dev", visibility = "private" },
  #   { name = "client-beta", subdomain = "beta.arthurreira.dev", visibility = "private" },
  #   { name = "landing-page", subdomain = "www.arthurreira.dev", visibility = "public" },
  # ]
  
  # Example: Hackathon Projects
  # default = [
  #   { name = "team-alpha-demo", subdomain = "alpha.arthurreira.dev", visibility = "public" },
  #   { name = "team-bravo-demo", subdomain = "bravo.arthurreira.dev", visibility = "public" },
  #   { name = "judges-portal", subdomain = "judges.arthurreira.dev", visibility = "private" },
  # ]
  
  description = "List of apps to deploy. Each gets its own repo and subdomain."
}