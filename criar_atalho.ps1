# ==============================================================================
# Cria o atalho na Area de Trabalho do usuario
# ==============================================================================
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath = Join-Path $scriptDir "iniciar_tudo.vbs"
$shortcutPath = Join-Path $desktopPath "iniciartudo.lnk"

$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $scriptDir
$shortcut.Description = "Abrir todos os programas e sites diarios de trabalho (1 Clique)"

# Icone verde de inicio/execucao da shell32.dll
$iconPath = "$env:SystemRoot\System32\shell32.dll"
$shortcut.IconLocation = "$iconPath, 24"

$shortcut.Save()

Write-Host "Atalho criado em: $shortcutPath" -ForegroundColor Green
