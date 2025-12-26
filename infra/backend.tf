terraform {
  cloud {
    organization = "YOUR_TC_ORG"

    workspaces {
      name = "github-repos"
    }
  }
}
