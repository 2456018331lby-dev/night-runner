<#
.SYNOPSIS
    Run all Night Runner verification scenes and generate a summary report.

.DESCRIPTION
    Discovers all verify_*.tscn scenes relative to this script, bootstraps Godot's
    import/class cache, runs each scene headlessly with a timeout, and fails on
    either a non-zero exit code or Godot diagnostics.

.PARAMETER GodotExe
    Optional path or command name for the Godot console executable.

.PARAMETER SceneTimeoutSeconds
    Maximum runtime for one verification scene.

.PARAMETER Quiet
    Suppress the per-scene report while preserving the exit code.

.NOTES
    Exit codes: 0 = all passed, 1 = one or more failed
#>

param(
    [string]$GodotExe = "",
    [int]$SceneTimeoutSeconds = 60,
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$ProjectPath = [System.IO.Path]::GetFullPath($PSScriptRoot)

function Get-LogText {
    param([string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return ""
    }

    try {
        return [System.IO.File]::ReadAllText($Path)
    } catch {
        return "Unable to read log '$Path': $($_.Exception.Message)"
    }
}

function ConvertTo-StartProcessArgument {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value -or $Value.Length -eq 0) {
        return '""'
    }

    # Start-Process joins ArgumentList entries into one command line. Quote only
    # values that need it so project paths containing spaces remain one argument.
    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    # The arguments passed here are paths without embedded quotes or trailing
    # separators, so a normal Windows command-line quote is sufficient.
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Stop-ProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return $true
    }

    $processId = $Process.Id
    try {
        if (-not $Process.HasExited) {
            # .NET 5+ supports killing the complete descendant tree.
            $Process.Kill($true)
        }
    } catch {
        # Fall through to taskkill, which is available on supported Windows hosts.
    }

    try {
        if ($Process.WaitForExit(5000)) {
            return $true
        }
    } catch {
    }

    $taskkill = Join-Path $env:SystemRoot "System32\taskkill.exe"
    if (Test-Path $taskkill -PathType Leaf) {
        try {
            & $taskkill /PID $processId /T /F *> $null
        } catch {
        }
    }

    try {
        [void]$Process.WaitForExit(5000)
    } catch {
    }

    try {
        return [bool]$Process.HasExited
    } catch {
        return $false
    }
}

function New-CommandResult {
    param(
        [int]$ExitCode,
        [bool]$TimedOut,
        [bool]$Started,
        [bool]$ProcessTreeCleaned,
        [string]$Stdout,
        [string]$Stderr,
        [string]$StdoutPath,
        [string]$StderrPath
    )

    return [PSCustomObject]@{
        ExitCode = $ExitCode
        TimedOut = $TimedOut
        Started = $Started
        ProcessTreeCleaned = $ProcessTreeCleaned
        Stdout = $Stdout
        Stderr = $Stderr
        StdoutPath = $StdoutPath
        StderrPath = $StderrPath
    }
}

# Resolve Godot from an explicit argument, PATH, or the developer's local install.
if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    $godotCommand = Get-Command godot, godot4, Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $godotCommand) {
        $GodotExe = if ($godotCommand.Source) { $godotCommand.Source } else { $godotCommand.Path }
    }
}
if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    $localGodot = "C:\Users\24560\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
    if (Test-Path $localGodot) {
        $GodotExe = $localGodot
    }
}
if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path $GodotExe -PathType Leaf)) {
    Write-Host "ERROR: Godot executable not found. Pass -GodotExe or add godot to PATH." -ForegroundColor Red
    exit 1
}
$GodotExe = (Resolve-Path $GodotExe).Path

if (-not (Test-Path (Join-Path $ProjectPath "project.godot") -PathType Leaf)) {
    Write-Host "ERROR: project.godot not found under $ProjectPath." -ForegroundColor Red
    exit 1
}

if ($SceneTimeoutSeconds -lt 5) {
    Write-Host "ERROR: SceneTimeoutSeconds must be at least 5 seconds." -ForegroundColor Red
    exit 1
}

$VerifyScenes = @(Get-ChildItem -Path (Join-Path $ProjectPath "scenes\tools\verify_*.tscn") -File | Sort-Object Name)
if ($VerifyScenes.Count -eq 0) {
    Write-Host "ERROR: No verification scenes found under $ProjectPath\scenes\tools." -ForegroundColor Red
    exit 1
}

$LogRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("night-runner-verifications-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

function Invoke-GodotCommand {
    param(
        [string[]]$Arguments,
        [string]$LogName,
        [int]$TimeoutSeconds
    )

    $stdoutPath = Join-Path $LogRoot ($LogName + ".stdout.log")
    $stderrPath = Join-Path $LogRoot ($LogName + ".stderr.log")
    $startArguments = @($Arguments | ForEach-Object { ConvertTo-StartProcessArgument $_ })
    $childProcess = $null

    try {
        $childProcess = Start-Process -FilePath $GodotExe `
                                 -ArgumentList $startArguments `
                                 -WorkingDirectory $ProjectPath `
                                 -RedirectStandardOutput $stdoutPath `
                                 -RedirectStandardError $stderrPath `
                                 -WindowStyle Hidden `
                                 -PassThru -ErrorAction Stop
    } catch {
        $message = "Failed to start Godot: $($_.Exception.Message)"
        [System.IO.File]::WriteAllText($stderrPath, $message)
        return New-CommandResult -ExitCode 1 -TimedOut $false -Started $false -ProcessTreeCleaned $true `
            -Stdout "" -Stderr $message -StdoutPath $stdoutPath -StderrPath $stderrPath
    }

    try {
        $finished = $childProcess.WaitForExit($TimeoutSeconds * 1000)
    } catch {
        $finished = $false
    }

    if (-not $finished) {
        $cleaned = Stop-ProcessTree $childProcess
        return New-CommandResult -ExitCode 124 -TimedOut $true -Started $true -ProcessTreeCleaned $cleaned `
            -Stdout (Get-LogText $stdoutPath) -Stderr (Get-LogText $stderrPath) `
            -StdoutPath $stdoutPath -StderrPath $stderrPath
    }

    try {
        [void]$childProcess.WaitForExit()
        $childProcess.Refresh()
        $exitCode = [int]$childProcess.ExitCode
    } catch {
        $exitCode = 1
    }

    return New-CommandResult -ExitCode $exitCode -TimedOut $false -Started $true -ProcessTreeCleaned $true `
        -Stdout (Get-LogText $stdoutPath) -Stderr (Get-LogText $stderrPath) `
        -StdoutPath $stdoutPath -StderrPath $stderrPath
}

function Test-GodotDiagnostics {
    param([string]$Stdout, [string]$Stderr)

    $diagnosticText = "$Stdout`n$Stderr"
    return $diagnosticText -match "(?m)(ERROR:|SCRIPT ERROR:|Parse Error:)"
}

if (-not $Quiet) {
    Write-Host "=== Night Runner Verification Suite ===" -ForegroundColor Cyan
    Write-Host "Project: $ProjectPath" -ForegroundColor Gray
    Write-Host "Found $($VerifyScenes.Count) verification scene(s)`n" -ForegroundColor Gray
}

# Generate imported resources and the global script class cache before running
# scenes. A clean checkout otherwise reports false failures for imported assets.
$bootstrap = Invoke-GodotCommand -Arguments @("--headless", "--editor", "--path", $ProjectPath, "--quit") -LogName "bootstrap" -TimeoutSeconds $SceneTimeoutSeconds
if ($bootstrap.TimedOut -or $bootstrap.ExitCode -ne 0 -or -not $bootstrap.ProcessTreeCleaned -or (Test-GodotDiagnostics $bootstrap.Stdout $bootstrap.Stderr)) {
    Write-Host "ERROR: Godot import/class-cache bootstrap failed (exit=$($bootstrap.ExitCode), timeout=$($bootstrap.TimedOut), tree-clean=$($bootstrap.ProcessTreeCleaned))." -ForegroundColor Red
    Write-Host "Logs: $($bootstrap.StdoutPath), $($bootstrap.StderrPath)" -ForegroundColor Red
    exit 1
}

# The scene suite can pass while the actual application entry point is broken;
# probe the shipping main scene before running the narrower regression scenes.
$mainProbe = Invoke-GodotCommand -Arguments @("--headless", "--path", $ProjectPath, "--scene", "res://scenes/app/main.tscn", "--quit-after", "2") -LogName "main-scene" -TimeoutSeconds $SceneTimeoutSeconds
$mainDiagnostics = Test-GodotDiagnostics $mainProbe.Stdout $mainProbe.Stderr
if ($mainProbe.TimedOut -or $mainProbe.ExitCode -ne 0 -or -not $mainProbe.ProcessTreeCleaned -or $mainDiagnostics) {
    Write-Host "ERROR: Main scene startup probe failed (exit=$($mainProbe.ExitCode), timeout=$($mainProbe.TimedOut), tree-clean=$($mainProbe.ProcessTreeCleaned))." -ForegroundColor Red
    Write-Host "Logs: $($mainProbe.StdoutPath), $($mainProbe.StderrPath)" -ForegroundColor Red
    exit 1
}

$Results = @()
$TotalStartTime = Get-Date
foreach ($Scene in $VerifyScenes) {
    $SceneName = $Scene.Name
    $logName = [System.IO.Path]::GetFileNameWithoutExtension($SceneName)
    $sceneArgument = "res://scenes/tools/$SceneName"
    if (-not $Quiet) { Write-Host "Running $SceneName... " -NoNewline }

    $StartTime = Get-Date
    $run = Invoke-GodotCommand -Arguments @("--headless", "--path", $ProjectPath, $sceneArgument) -LogName $logName -TimeoutSeconds $SceneTimeoutSeconds
    $Duration = ((Get-Date) - $StartTime).TotalSeconds
    $hasDiagnostics = Test-GodotDiagnostics $run.Stdout $run.Stderr
    $passed = (-not $run.TimedOut) -and $run.ExitCode -eq 0 -and $run.Started -and $run.ProcessTreeCleaned -and (-not $hasDiagnostics)

    $Results += [PSCustomObject]@{
        Scene = $SceneName
        Passed = $passed
        ExitCode = $run.ExitCode
        TimedOut = $run.TimedOut
        Diagnostics = $hasDiagnostics
        ProcessTreeCleaned = $run.ProcessTreeCleaned
        Duration = $Duration
        StdoutPath = $run.StdoutPath
        StderrPath = $run.StderrPath
    }

    if (-not $Quiet) {
        if ($passed) {
            Write-Host "PASS" -ForegroundColor Green -NoNewline
            Write-Host " ($([math]::Round($Duration, 2))s)"
        } elseif ($run.TimedOut) {
            Write-Host "TIMEOUT" -ForegroundColor Red -NoNewline
            Write-Host " (>${SceneTimeoutSeconds}s, tree-clean=$($run.ProcessTreeCleaned))"
        } else {
            $reason = if ($hasDiagnostics) { "diagnostics" } elseif (-not $run.ProcessTreeCleaned) { "process tree cleanup" } else { "exit $($run.ExitCode)" }
            Write-Host "FAIL" -ForegroundColor Red -NoNewline
            Write-Host " ($reason, $([math]::Round($Duration, 2))s)"
        }
    }
}

$TotalDuration = ((Get-Date) - $TotalStartTime).TotalSeconds
$PassedCount = @($Results | Where-Object { $_.Passed }).Count
$FailedResults = @($Results | Where-Object { -not $_.Passed })
$FailedCount = $FailedResults.Count

if (-not $Quiet) {
    Write-Host "`n=== Verification Report ===" -ForegroundColor Cyan
    Write-Host "Total:       $($Results.Count)"
    Write-Host "Passed:      $PassedCount" -ForegroundColor Green
    Write-Host "Failed:      $FailedCount" -ForegroundColor $(if ($FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Total time:  $([math]::Round($TotalDuration, 1))s"
    if ($FailedCount -gt 0) {
        Write-Host "`nFAILED:" -ForegroundColor Red
        foreach ($Result in $FailedResults) {
            $reason = if ($Result.TimedOut) { "timeout" } elseif ($Result.Diagnostics) { "diagnostics" } elseif (-not $Result.ProcessTreeCleaned) { "process tree cleanup" } else { "exit $($Result.ExitCode)" }
            Write-Host "  - $($Result.Scene) ($reason, exit $($Result.ExitCode))" -ForegroundColor Red
            Write-Host "    logs: $($Result.StdoutPath) / $($Result.StderrPath)" -ForegroundColor DarkGray
        }
    }
}

if ($FailedCount -gt 0) {
    if (-not $Quiet) { Write-Host "`nVerification suite FAILED" -ForegroundColor Red }
    exit 1
}
if (-not $Quiet) { Write-Host "`nAll verifications PASSED" -ForegroundColor Green }
exit 0
