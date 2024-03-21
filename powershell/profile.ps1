# Set readline options
if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineOption -PredictionSource History
    # Set-PSReadLineOption -PredictionViewStyle ListView
}

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

# Unix aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# macOS aliases
Set-Alias -Name pbcopy -Value Set-Clipboard
Set-Alias -Name pbpaste -Value Get-Clipboard

#endregion
