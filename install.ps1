<#
.SYNOPSIS
    dotfiles install script for PowerShell (Windows 11)
.DESCRIPTION
	Install user profile and configuration
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = (Join-Path -Path $env:USERPROFILE -ChildPath '.config\dotfiles'),
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function InstallPrerequisites() {
    if (-not (Get-AppPackage -Name 'Microsoft.DesktopAppInstaller')) {
        throw "winget is not installed. Please install it from https://github.com/microsoft/winget-cli/"
    }

    winget install @('Git.Git', 'Microsoft.PowerShell') --interactive

    $Env:Path = @(
        [System.Environment]::GetEnvironmentVariable("Path","Machine"),
        [System.Environment]::GetEnvironmentVariable("Path","User")
    ) -Join ";"
}

function CloneDotfiles($path) {
    if (-not (Test-Path -Path $Path)) {
        $dotfileParent = Split-Path -Path $Path
        if (-not (Test-Path -Path $dotfileParent)) {
            New-Item -Path $dotfileParent -ItemType Directory -Force
        }
        Start-Process -FilePath (Get-Command git.exe) -ArgumentList "clone https://github.com/ascarter/dotfiles.git $Path" -Wait -NoNewWindow
    }

    if ($null -eq [System.Environment]::GetEnvironmentVariable('DOTFILES', [System.EnvironmentVariableTarget]::User)) {
        [System.Environment]::SetEnvironmentVariable('DOTFILES', $Path, [System.EnvironmentVariableTarget]::User)
    }
}

function InstallProfile($path) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path -Path $profilePath)) {
        Write-Output "Install PowerShell profile"
        New-Item -Path $profilePath -ItemType File -Force
        $dotfilesProfile = (Join-Path $Path -ChildPath powershell\profile.ps1)
        Set-Content -Path $profilePath -Value ". $dotfilesProfile"
    } else {
        Write-Warning "The profile already exists at $profilePath"
    }
}

function InitDotfiles() {
    InstallProfile $Path
}

try {
    InstallPrerequisites
    CloneDotfiles -Path $Path
    InitDotfiles
}
catch {
    Write-Error "An error occurred: $_"
}
