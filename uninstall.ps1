<#
.SYNOPSIS
    Uninstall script for Windows
.DESCRIPTION
    Remove PSDotfiles configuration for current Windows user
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = (Join-Path -Path $env:USERPROFILE -ChildPath '.config\dotfiles')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    # Remove dotfiles artifacts
    $pathsToRemove = @(
        $PROFILE.CurrentUserAllHosts,
        (Join-Path -Path $env:USERPROFILE -ChildPath .gitconfig),
        $Path
    )

    foreach ($path in $pathsToRemove) {
        if (Test-Path -Path $path) {
            Remove-Item -Path $path -Force -Recurse
        }
    }

    # Unset DOTFILES environment variable
    [System.Environment]::SetEnvironmentVariable("DOTFILES", $null, [System.EnvironmentVariableTarget]::User)

    Write-Output "dotfiles uninstalled"
}
catch {
    Write-Error "An error occurred: $_"
}
