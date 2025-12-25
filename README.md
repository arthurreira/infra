# Terraform GitHub Pages Infra

One Terraform project to create and configure multiple GitHub repositories, each with a GitHub Pages workflow and a custom subdomain (via your wildcard DNS like `*.arthurreira.dev`).

Configs live in `infra/`.

## What it creates

- 3 repos by default: `app1`, `app2`, `app3` (public)
- In each repo:
	- `app/index.html` and `app/CNAME` (your subdomain)
	- A Pages deploy workflow that enables Pages and publishes `app/`
- With wildcard DNS in place, you’ll get:
	- https://app1.arthurreira.dev
	- https://app2.arthurreira.dev
	- https://app3.arthurreira.dev

## Requirements

- Classic GitHub Personal Access Token (PAT) with `repo` + `delete_repo` scopes.
- Terraform >= 1.5, provider `integrations/github` ~> 6.0.

Notes:
- The built-in GitHub Actions `GITHUB_TOKEN` cannot create repos; use a classic PAT.
- Some org policies block automatic Pages enablement. If the first deploy fails, open Settings → Pages in each new repo, set Source = GitHub Actions once. Subsequent deploys work.

## Configure apps

Edit `infra/variables.tf` `var.apps`, or create your own `infra/terraform.tfvars` using `infra/terraform.tfvars.example`.

## How to run (macOS)

Quick minimal (env vars)

```bash
export TF_VAR_github_owner="arthurreira"
export TF_VAR_github_token="ghp_yourClassicPAT"
# Optional: define apps inline via env var (JSON/HCL works)
export TF_VAR_apps='[
	{"name":"app1","subdomain":"app1.arthurreira.dev","visibility":"public"},
	{"name":"app2","subdomain":"app2.arthurreira.dev","visibility":"public"},
	{"name":"app3","subdomain":"app3.arthurreira.dev","visibility":"public"}
]'
terraform -chdir=infra init
terraform -chdir=infra apply
```

Option A — environment variable

```bash
export TF_VAR_github_token="ghp_yourClassicPAT"
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply
```

Option B — tfvars file

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
# edit infra/terraform.tfvars to set github_owner, github_token, and apps
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply
```

## Outputs

After apply, Terraform prints:

- `repositories`: the list of repo names created
- `app_urls`: a map of repo → expected custom domain URL

## Customize further

- Change repo names or add/remove apps in `var.apps`.
- Want real app scaffolds (React/Vite) per repo? We can add those to each repo via `github_repository_file` or a post-create workflow.

## Run in GitHub Actions

You can keep variables in this repo’s Actions settings and run Terraform from CI.

- Add repository secret:
	- `GH_PAT`: classic PAT with `repo` + `delete_repo`
- Optional repository variables:
	- `APPS_JSON`: JSON string for `var.apps` (e.g. `[{"name":"app1","subdomain":"app1.arthurreira.dev","visibility":"public"},...]`)
	- `GITHUB_OWNER`: override owner (defaults to `arthurreira` in variables)

Workflow: [/.github/workflows/terraform.yml](.github/workflows/terraform.yml)

Trigger manually with "Run workflow"; toggle the `apply` input to perform an apply.

