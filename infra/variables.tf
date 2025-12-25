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
    name      = string       # repo name
    subdomain = string       # e.g., app1.arthurreira.dev
    visibility = string      # "public" or "private"
  }))
  default = [
    { name = "app1", subdomain = "app1.arthurreira.dev", visibility = "public" },
    { name = "app2", subdomain = "app2.arthurreira.dev", visibility = "public" },
    { name = "app3", subdomain = "app3.arthurreira.dev", visibility = "public" },
  ]
}