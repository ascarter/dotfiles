#!/usr/bin/env bash
#MISE description="Configure Git Credential Manager for Azure DevOps"
#MISE depends=["bootstrap:git"]
#MISE quiet=true

git-credential-manager configure
