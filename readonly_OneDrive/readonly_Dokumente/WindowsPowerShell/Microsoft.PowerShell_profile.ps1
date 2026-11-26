Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Windows

Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory

Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward()
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward()
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PSReadLineOption -Colors @{
    InlinePrediction = '#6c6c6c'
    Command          = '#87d787'
    Parameter        = '#d7af87'
    String           = '#d78787'
    Comment          = '#5f5f5f'
    Keyword          = '#d787d7'
    Variable         = '#87d7d7'
    Operator         = '#d7d787'
    Type             = '#87afd7'
    Number           = '#af87d7'
    Member           = '#d7af87'
    Error            = 'Red'
}



Import-Module Terminal-Icons

Set-Alias ll Get-ChildItem
function ll { Get-ChildItem -Force }
Set-Alias la Get-ChildItem
function la { Get-ChildItem -Force -Recurse }
Set-Alias l Get-ChildItem
function l { Get-ChildItem -Force }


# Go up one level
function .. { Set-Location .. }
# Go up two levels
function ... { Set-Location ..\.. }
# Go up three levels
function .... { Set-Location ..\..\.. }
# Go up four levels
function ..... { Set-Location ..\..\..\.. }

# Override the built-in cd alias
Remove-Item Alias:cd -ErrorAction SilentlyContinue

function cd {
    if ($args.Count -eq 0) {
        Set-Location $HOME
    } else {
        Set-Location @args
    }
}

$zdir = "$HOME\.config\zellij"
if ([Environment]::GetEnvironmentVariable('ZELLIJ_CONFIG_DIR', 'User') -ne $zdir) {
    [Environment]::SetEnvironmentVariable('ZELLIJ_CONFIG_DIR', $zdir, 'User')
}
$env:ZELLIJ_CONFIG_DIR = $zdir

Invoke-Expression (&starship init powershell)
