<#
.SYNOPSIS
    Run all Night Runner verification scenes and generate a summary report.

.DESCRIPTION
    This script discovers all verify_*.tscn scenes in scenes/tools/,
    runs them headlessly via Godot, and reports pass/fail status with timing.

.EXAMPLE
    .\run_all_verifications.ps1

.NOTES
    Exit codes: 0 = all passed, 1 = one or more failed
#>

$ErrorActionPreference = "Continue"

# Godot executable path
$GodotExe = "C:\Users\24560\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"

# Verify Godot exists
if (-not (Test-Path $GodotExe)) {
    Write-Host "ERROR: Godot executable not found at: $GodotExe" -ForegroundColor Red
    exit 1
}

# Discover all verification scenes
$VerifyScenes = Get-ChildItem -Path "scenes\tools\verify_*.tscn" -File | Sort-Object Name

if ($VerifyScenes.Count -eq 0) {
    Write-Host "WARNING: No verification scenes found in scenes/tools/" -ForegroundColor Yellow
    exit 0
}

Write-Host "=== Night Runner Verification Suite ===" -ForegroundColor Cyan
Write-Host "Found $($VerifyScenes.Count) verification scene(s)`n" -ForegroundColor Gray

$Results = @()
$TotalStartTime = Get-Date

foreach ($Scene in $VerifyScenes) {
    $SceneName = $Scene.Name
    Write-Host "Running $SceneName... " -NoNewline

    $StartTime = Get-Date

    # Run headless verification
    $Process = Start-Process -FilePath $GodotExe `
                             -ArgumentList "--headless", "--path", ".", $Scene.FullName `
                             -NoNewWindow `
                             -Wait `
                             -PassThru

    $EndTime = Get-Date
    $Duration = ($EndTime - $StartTime).TotalSeconds
    $ExitCode = $Process.ExitCode

    $Result = [PSCustomObject]@{
        Scene    = $SceneName
        Passed   = ($ExitCode -eq 0)
        ExitCode = $ExitCode
        Duration = $Duration
    }
    $Results += $Result

    if ($ExitCode -eq 0) {
        Write-Host "PASS" -ForegroundColor Green -NoNewline
        Write-Host " ($([math]::Round($Duration, 2))s)"
    } else {
        Write-Host "FAIL" -ForegroundColor Red -NoNewline
        Write-Host " (exit $ExitCode, $([math]::Round($Duration, 2))s)"
    }
}

$TotalEndTime = Get-Date
$TotalDuration = ($TotalEndTime - $TotalStartTime).TotalSeconds

# Generate summary report
$PassedCount = ($Results | Where-Object { $_.Passed }).Count
$FailedCount = ($Results | Where-Object { -not $_.Passed }).Count

Write-Host "`n=== Verification Report ===" -ForegroundColor Cyan
Write-Host "Total:       $($Results.Count)"
Write-Host "Passed:      " -NoNewline
Write-Host $PassedCount -ForegroundColor Green
Write-Host "Failed:      " -NoNewline
if ($FailedCount -gt 0) {
    Write-Host $FailedCount -ForegroundColor Red
} else {
    Write-Host $FailedCount -ForegroundColor Green
}
Write-Host "Total time:  $([math]::Round($TotalDuration, 1))s"

if ($FailedCount -gt 0) {
    Write-Host "`nFAILED:" -ForegroundColor Red
    foreach ($Result in ($Results | Where-Object { -not $_.Passed })) {
        Write-Host "  - $($Result.Scene) (exit $($Result.ExitCode), $([math]::Round($Result.Duration, 2))s)" -ForegroundColor Red
    }
}

Write-Host "`nPASSED:" -ForegroundColor Green
foreach ($Result in ($Results | Where-Object { $_.Passed })) {
    Write-Host "  - $($Result.Scene) ($([math]::Round($Result.Duration, 2))s)"
}

# Exit with failure if any verification failed
if ($FailedCount -gt 0) {
    Write-Host "`n❌ Verification suite FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All verifications PASSED" -ForegroundColor Green
    exit 0
}
