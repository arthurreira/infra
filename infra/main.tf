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
    build_type = "workflow"
  }
}

# Add CNAME for custom domain
resource "github_repository_file" "cname" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "app/CNAME"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Set custom domain"
  content    = each.value.subdomain
  overwrite_on_create = true
}

# Add starter app/index.html for each repo
resource "github_repository_file" "starter_content" {
  for_each   = local.apps_by_name
  repository = github_repository.apps[each.key].name
  file       = "app/index.html"
  branch     = github_repository.apps[each.key].default_branch
  commit_message = "Add starter content"
  overwrite_on_create = true
  
  content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${each.value.subdomain}</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
      </style>
    </head>
    <body>
      <h1>${each.value.subdomain}</h1>
      <p>This is a starter page. Edit <code>app/index.html</code> in this repository to customize your site.</p>
      <p>You can add CSS, JavaScript, images, and more to the <code>app/</code> directory.</p>
    </body>
    </html>
  HTML
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
          url: $${{ steps.deployment.outputs.page_url }}
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Remove old root CNAME if exists
            run: rm -f CNAME
          - name: Verify app directory contents
            run: ls -la app/
          - uses: actions/upload-pages-artifact@v3
            with:
              path: './app'
          - name: Deploy to GitHub Pages
            id: deployment
            uses: actions/deploy-pages@v4
  YAML
}

