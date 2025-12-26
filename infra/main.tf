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
  description = "Pages app for ${each.value.subdomain}"
}

# Minimal site content - index
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

# CNAME for custom domain
resource "github_repository_file" "cname" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "app/CNAME"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Set Pages custom domain"
  content    = each.value.subdomain
}

# Add Pages workflow
resource "github_repository_file" "workflow" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = ".github/workflows/deploy.yml"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Add GitHub Pages deploy workflow"
  overwrite_on_create = true

  depends_on = [
    github_repository_file.index,
    github_repository_file.cname
  ]

  content = <<-YAML
    name: Deploy to GitHub Pages
    on:
      push:
        branches: ["main"]
        paths:
          - 'app/**'
    permissions:
      contents: read
      pages: write
      id-token: write
    concurrency:
      group: "pages"
      cancel-in-progress: true
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Verify app directory
            run: ls -la app/
          - uses: actions/configure-pages@v4
          - uses: actions/upload-pages-artifact@v3
            with:
              path: './app'
          - uses: actions/deploy-pages@v4
  YAML
}
