#!/usr/bin/env bash
#MISE description="Configure Git LFS"
#MISE depends=["bootstrap:git"]
#MISE quiet=true

git lfs install --skip-repo
