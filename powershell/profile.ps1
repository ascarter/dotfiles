#region dotfiles setup

# Set DOTFILES environment varible if not already set
if ($null -eq [System.Environment]::GetEnvironmentVariable('DOTFILES', 'User')) {
    $dotfilesPath = Join-Path $Env:USERPROFILE -ChildPath .config\dotfiles
    if (Test-Path -Path $dotfilesPath) {
        Set-Item -Path Env:DOTFILES -Value $dotfilesPath
    } else {
        Write-Warning "The path '$dotfilesPath' does not exist."
    }
}

# Add dotfiles module to path
$Env:PSModulePath += [System.IO.Path]::PathSeparator + (Join-Path -Path $Env:DOTFILES -ChildPath powershell\Modules)

#endregion

# Add tools to path
# Update-Path @(
#     (Join-Path -Path ${env:SystemDrive} -ChildPath bin),
#     (Join-Path -Path ${env:LOCALAPPDATA} -ChildPath Fork),
#     (Join-Path -Path ${env:ProgramFiles} -ChildPath '7-Zip'),
#     (Join-Path -Path ${env:ProgramFiles} -ChildPath 'Sublime Text'),
#     (Join-Path -Path ${env:ProgramFiles} -ChildPath 'Yubico\YubiKey Manager'),
#     (Join-Path -Path ${env:ProgramFiles} -ChildPath qemu),
#     (Join-Path -Path ${env:ProgramFiles} -ChildPath vim\vim82),
#     (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath GnuPG\bin),
#     (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Gpg4Win\bin'),
#     (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Gpg4Win\bin_64')
# )

#region Aliases


#endregion
