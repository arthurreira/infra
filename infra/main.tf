# Create repos
locals {
  apps_by_name = { for a in var.apps : a.name => a }
}

resource "github_repository" "apps" {
  for_each   = local.apps_by_name
  name       = each.value.name
  visibility = each.value.visibility
  auto_init  = true
  has_issues = true
  delete_branch_on_merge = true
  # Description helps identify the app
  description = "Pages app for ${each.value.subdomain}"
}

# Add Pages workflow (depends on content being created first)
resource "github_repository_file" "workflow" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = ".github/workflows/deploy.yml"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Add GitHub Pages deploy workflow"
  
  # Ensure content files exist before workflow triggers
  depends_on = [
    github_repository_file.index,
    github_repository_file.cname
  ]
  
  content = <<-YAML
    name: Deploy static content to Pages
    on:
      push:
        branches: ["main"]
      workflow_dispatch:
    permissions:
      contents: read
      pages: write
      id-token: write
    concurrency:
      group: "pages"
      cancel-in-progress: false
    jobs:
      deploy:
        environment:
          name: github-pages
          url: ${{ steps.deployment.outputs.page_url }}
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - uses: actions/configure-pages@v5
            with:
              enablement: true
          - uses: actions/upload-pages-artifact@v3
            with:
              path: "./app"
          - id: deployment
            uses: actions/deploy-pages@v4
  YAML
}

# Minimal site content
resource "github_repository_file" "index" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "app/index.html"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Add index.html"
  content = <<-HTML
    <!doctype html>
    <meta charset="utf-8">
    <title>${each.value.subdomain}</title>
    <h1>${each.value.subdomain}</h1>
    <p>Deployed via GitHub Actions + Terraform.</p>
  HTML
}

# CNAME to set the custom subdomain for this repo's Pages site
resource "github_repository_file" "cname" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "app/CNAME"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Set Pages custom domain"
  content    = each.value.subdomain
}