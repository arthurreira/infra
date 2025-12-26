# Terraform GitHub Pages Infra

Create multiple GitHub repositories with GitHub Pages and custom subdomains using Terraform + GitHub Actions automation.

Configs live in `infra/`.

## What it creates

**By default:** 3 repos (hackathon-registration, hackathon-schedule, hackathon-projects)

**In each repo:**
- `CNAME` file with custom subdomain (e.g., register.arthurreira.dev)
- `.github/workflows/deploy.yml` that auto-deploys to Pages on push
- Pages enabled and configured via Terraform
- Automatic Pages deployments on every commit to main

**Result:** With wildcard DNS (`*.arthurreira.dev → GitHub Pages`), you get:
- https://register.arthurreira.dev
- https://schedule.arthurreira.dev
- https://projects.arthurreira.dev

## Architecture

**Two separate concerns:**

1. **Terraform (infra repo)**
   - Creates GitHub repositories
   - Enables GitHub Pages (via Terraform PAT permissions)
   - Sets custom domains (CNAME files)
   - Generates deploy workflows
   - Imports existing repos to avoid recreation

2. **Deploy workflows (app repos)**
   - Auto-trigger on push to main
   - Build static content (creates `./app/index.html`)
   - Upload and deploy to Pages
   - Run with default GitHub Actions permissions (no configuration needed)

## Requirements

- **Classic GitHub Personal Access Token (PAT)** with `repo` + `delete_repo` scopes
- **Terraform >= 1.5**, provider `integrations/github` ~> 6.0
- **Wildcard DNS** pointing to GitHub Pages (`.arthurreira.dev` → GitHub's IP)

## How to run

### Local (macOS/Linux)

```bash
export TF_VAR_github_owner="arthurreira"
export TF_VAR_github_token="ghp_yourClassicPAT"

terraform -chdir=infra init
terraform -chdir=infra plan
terraform -chdir=infra apply
```

**OR** use a tfvars file:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars with your values
terraform -chdir=infra init
terraform -chdir=infra apply
```

### Customize apps

Edit `infra/variables.tf` (default) or `infra/terraform.tfvars`:

```hcl
variable "apps" {
  type = list(object({
    name      = string
    subdomain = string
    visibility = string
  }))
  default = [
    {
      name       = "hackathon-registration"
      subdomain  = "register.arthurreira.dev"
      visibility = "public"
    },
    # ... more apps
  ]
}
```

## How to run in GitHub Actions

This repo includes a Terraform workflow that handles everything automatically.

**Setup:**
1. Add repository secret in https://github.com/arthurreira/infra/settings/secrets/actions:
   - `GH_PAT`: Classic PAT with `repo` + `delete_repo` scopes

**Workflow: [.github/workflows/terraform.yml](.github/workflows/terraform.yml)**

**To run:**
1. Go to Actions → Terraform
2. Click "Run workflow"
3. Toggle `apply` to `true` to execute apply (default is plan-only)
4. Workflow will:
   - Initialize Terraform
   - Validate configuration
   - Plan changes
   - Import existing repos (avoid recreation)
   - Apply changes
   - Output repository URLs

**Automation after apply:**
- New repos are created
- Pages is enabled (Terraform handles this)
- Deploy workflows are auto-generated
- Deploy workflows auto-trigger on the initial commits
- Each app repo's Pages site goes live within seconds

## Outputs

After apply, Terraform prints:

```json
{
  "repositories": ["hackathon-projects", "hackathon-registration", "hackathon-schedule"],
  "app_urls": {
    "hackathon-projects": "https://projects.arthurreira.dev",
    "hackathon-registration": "https://register.arthurreira.dev",
    "hackathon-schedule": "https://schedule.arthurreira.dev"
  }
}
```

## Important notes

### Pages is enabled via Terraform, not Actions
- Terraform uses your PAT (which has admin permissions)
- GitHub Actions workflows use limited GITHUB_TOKEN (cannot enable Pages)
- This prevents 403 "Resource not accessible by integration" errors

### Existing repos are imported
- Workflow includes `terraform import` step before apply
- Prevents "name already exists" errors on re-runs
- Allows idempotent Terraform (run apply 100x, same result)

### Deploy workflows run automatically
- Each app repo's workflow triggers on push to main
- Builds `./app/` and uploads to Pages
- No manual deployment needed

## Troubleshooting

**Terraform fails with "name already exists"**
- The import step should prevent this
- If it happens, the repos exist in GitHub but not in Terraform state
- Try deleting repos and re-running apply

**Pages site shows 404**
- Check Pages settings in repo → Pages (should show "Source: GitHub Actions")
- Deploy workflow should have completed successfully (check Actions tab)
- DNS propagation may still be in progress (wait 5-10 minutes)

**Deploy workflow fails**
- Check workflow logs in the app repo's Actions tab
- Most likely: Pages not enabled yet (Terraform apply should fix this)
- Or: CNAME file not committed (Terraform apply should fix this)
