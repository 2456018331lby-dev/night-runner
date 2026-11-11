<#
.SYNOPSIS
    Keep the declared Web bundle sizes in docs/index.html in sync with the real files.

.DESCRIPTION
    Godot's Web loader accumulates the download total from the "fileSizes" entry in the
    page configuration, while the reported byte count comes from the real download stream.
    A drift between the two breaks the loading bar:
      * declared size too small -> the bar races to 100% and then appears frozen
      * declared size too large -> the bar never reaches 100%
    docs/index.html is a hand-maintained landing page (the export script only refreshes
    index.js / index.pck / index.wasm), so the numbers have to be re-synced after every
    export. export_web_to_docs.bat calls this script automatically.

.PARAMETER OutputDir
    Directory holding index.html, index.pck and index.wasm. Defaults to .\docs next to
    this script.

.EXAMPLE
    .\sync_web_bundle_sizes.ps1

.NOTES
    Exit codes: 0 = synced, 1 = missing input or invalid fileSizes contract.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$OutputDir = (Join-Path $PSScriptRoot "docs")
)

$ErrorActionPreference = "Stop"
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$HtmlPath = Join-Path $OutputDir "index.html"

if (-not (Test-Path $OutputDir -PathType Container)) {
    Write-Error "Output directory not found: $OutputDir"
    exit 1
}
if (-not (Test-Path $HtmlPath -PathType Leaf)) {
    Write-Error "index.html not found at: $HtmlPath"
    exit 1
}

$html = [System.IO.File]::ReadAllText($HtmlPath)
$changed = $false

foreach ($name in @("pck", "wasm")) {
    $filePath = Join-Path $OutputDir ("index." + $name)
    if (-not (Test-Path $filePath -PathType Leaf)) {
        Write-Error "Required bundle file missing: $filePath"
        exit 1
    }

    $realSize = (Get-Item $filePath).Length
    if ($realSize -le 0) {
        Write-Error "Required bundle file is empty: $filePath"
        exit 1
    }

    $pattern = '"index\.' + $name + '"\s*:\s*(\d+)'
    $matches = [regex]::Matches($html, $pattern)
    if ($matches.Count -ne 1) {
        Write-Error "Expected exactly one fileSizes entry for index.$name in $HtmlPath; found $($matches.Count)."
        exit 1
    }

    $replacement = '"index.' + $name + '": ' + $realSize
    $updated = [regex]::Replace($html, $pattern, $replacement, 1)
    if ($updated -ne $html) {
        $html = $updated
        $changed = $true
        Write-Host ("UPDATED index.$name -> {0} bytes" -f $realSize) -ForegroundColor Green
    } else {
        Write-Host ("OK      index.$name already {0} bytes" -f $realSize) -ForegroundColor Gray
    }
}

if ($changed) {
    # UTF-8 without BOM: the page declares <meta charset="utf-8"> and contains Chinese copy.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($HtmlPath, $html, $utf8NoBom)
    Write-Host "index.html updated." -ForegroundColor Green
} else {
    Write-Host "index.html already in sync." -ForegroundColor Gray
}

exit 0
