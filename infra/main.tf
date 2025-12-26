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

  pages {
    source {
      branch = "main"
      path   = "/"
    }
  }
}

# Add CNAME for custom domain
resource "github_repository_file" "cname" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "CNAME"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Set custom domain"
  content    = each.value.subdomain
  overwrite_on_create = true
}

# Add Pages workflow that builds content
resource "github_repository_file" "workflow" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = ".github/workflows/deploy.yml"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Add GitHub Pages deploy workflow"
  overwrite_on_create = true

  depends_on = [github_repository_file.cname]

  content = <<-YAML
    name: Deploy to GitHub Pages
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
          - name: Create app directory
            run: |
              mkdir -p app
              cat > app/index.html <<'EOF'
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>${each.value.subdomain}</title>
              </head>
              <body>
                <h1>${each.value.subdomain}</h1>
                <p>Deployed via Terraform + GitHub Pages</p>
              </body>
              </html>
              EOF
          - uses: actions/upload-pages-artifact@v3
            with:
              path: './app'
          - name: Deploy to GitHub Pages
            id: deployment
            uses: actions/deploy-pages@v4
  YAML
}

