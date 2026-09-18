# Execucao em linha de comando / rotina em lote
param(
    [string]$SingleId = "",
    [switch]$NoDelay
)

$ErrorActionPreference = "Continue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "config.json"

if (-not (Test-Path $configFile)) {
    $exampleFile = Join-Path $scriptDir "config.example.json"
    if (Test-Path $exampleFile) {
        Copy-Item $exampleFile $configFile
    } else {
        Write-Host "Arquivo config.json nao encontrado." -ForegroundColor Red
        exit 1
    }
}

try {
    $configContent = Get-Content -Path $configFile -Raw -Encoding UTF8
    $config = $configContent | ConvertFrom-Json
} catch {
    Write-Host "Erro ao ler config.json: $_" -ForegroundColor Red
    exit 1
}

$delay = if ($config.settings.delaySeconds) { [double]$config.settings.delaySeconds } else { 0.8 }
$preventDupes = if ($null -ne $config.settings.preventDuplicates) { [bool]$config.settings.preventDuplicates } else { $true }

$itemsToProcess = @()
if ($SingleId -ne "") {
    $itemsToProcess = $config.items | Where-Object { $_.id -eq $SingleId }
} else {
    $itemsToProcess = $config.items | Where-Object { $_.enabled -eq $true }
}

$total = $itemsToProcess.Count
$current = 0
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

foreach ($item in $itemsToProcess) {
    $current++
    $name = $item.name
    $type = $item.type
    $target = $item.target
    $processName = $item.processName
    $args = $item.args

    Write-Host "[$current/$total] Iniciando: $name" -ForegroundColor Gray

    try {
        switch ($type.ToLower()) {
            "app" {
                if ($preventDupes -and $processName) {
                    $running = Get-Process -Name $processName -ErrorAction SilentlyContinue
                    if ($running) {
                        Write-Host "  -> Ja esta em execucao. Pulando." -ForegroundColor DarkGray
                        continue
                    }
                }

                if ($target -eq "whatsapp:" -or $item.id -eq "whatsapp") {
                    $waPkg = Get-AppxPackage *WhatsApp* -ErrorAction SilentlyContinue
                    if ($waPkg) {
                        Start-Process "explorer.exe" -ArgumentList "shell:AppsFolder\$($waPkg.PackageFamilyName)!App"
                    } else {
                        Start-Process "whatsapp:"
                    }
                } elseif (Test-Path $target) {
                    if ($args) {
                        Start-Process -FilePath $target -ArgumentList $args
                    } else {
                        Start-Process -FilePath $target
                    }
                } else {
                    Start-Process -FilePath $target
                }
            }

            "url" {
                if (Test-Path $chromePath) {
                    Start-Process -FilePath $chromePath -ArgumentList "`"$target`""
                } else {
                    Start-Process $target
                }
            }

            "folder" {
                if (Test-Path $target) {
                    Start-Process "explorer.exe" -ArgumentList "`"$target`""
                }
            }
        }
    } catch {
        Write-Host "  -> Erro ao abrir $name : $_" -ForegroundColor Red
    }

    if (-not $NoDelay -and $current -lt $total -and $delay -gt 0) {
        Start-Sleep -Seconds $delay
    }
}
