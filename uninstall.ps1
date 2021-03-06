<#
.SYNOPSIS
    Uninstall script for Windows
.DESCRIPTION
    Remove dotfiles configuration for current Windows user
#>
[cmdletbinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Remove user profile
if (Test-Path -Path $PROFILE) { Remove-Item -Path $PROFILE }

# Remove vimrc
$vimrc = Join-Path -Path $env:USERPROFILE -ChildPath _vimrc
if (Test-Path -Path $vimrc) { Remove-Item -Path $vimrc }

# Remove gitconfig
$gitconfig = Join-Path -Path $env:USERPROFILE -ChildPath .gitconfig
if (Test-Path -Path $gitconfig) { Remove-Item -Path $gitconfig }

Write-Output "dotfiles uninstalled"
