# Validate-Template.ps1
# Validates and cleans a template before deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$TemplatePath,

    [switch]$Fix,
    [switch]$ShowDetails
)

$script:errors = @()
$script:warnings = @()
$script:fixes = @()

function Write-Check {
    param([string]$Message, [string]$Status)
    if ($ShowDetails) {
        $color = switch ($Status) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            "FIX" { "Cyan" }
            default { "White" }
        }
        Write-Host "  [$Status] $Message" -ForegroundColor $color
    }
}

function Test-SettingsJson {
    param([string]$Path)

    $settingsPath = Join-Path $Path "settings.json"

    if (-not (Test-Path $settingsPath)) {
        $script:errors += "Missing settings.json"
        Write-Check "settings.json missing" "ERROR"
        return
    }

    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

        # Check schema
        $correctSchema = "https://json.schemastore.org/claude-code-settings.json"
        if (-not $settings.'$schema') {
            $script:errors += "settings.json missing `$schema"
            Write-Check "settings.json missing `$schema" "ERROR"

            if ($Fix) {
                $content = Get-Content $settingsPath -Raw
                $content = $content -replace '^\{', "{`n  `"`$schema`": `"$correctSchema`","
                Set-Content $settingsPath $content
                $script:fixes += "Added `$schema to settings.json"
                Write-Check "Added `$schema" "FIX"
            }
        } elseif ($settings.'$schema' -ne $correctSchema) {
            $script:errors += "settings.json has wrong `$schema: $($settings.'$schema')"
            Write-Check "settings.json has wrong `$schema" "ERROR"

            if ($Fix) {
                $content = Get-Content $settingsPath -Raw
                $content = $content -replace '"?\$schema"?\s*:\s*"[^"]*"', "`"`$schema`": `"$correctSchema`""
                Set-Content $settingsPath $content
                $script:fixes += "Fixed `$schema in settings.json"
                Write-Check "Fixed `$schema" "FIX"
            }
        } else {
            Write-Check "settings.json `$schema correct" "OK"
        }

    } catch {
        $script:errors += "settings.json is invalid JSON: $_"
        Write-Check "settings.json invalid JSON" "ERROR"
    }
}

function Test-HardcodedPaths {
    param([string]$Path)

    # Patterns to check for - customize with your admin username
    # These detect hardcoded paths that shouldn't be in templates
    $adminUser = $env:USERNAME
    $badPatterns = @(
        "C:\\Users\\$adminUser",
        "C:/Users/$adminUser",
        "/c/Users/$adminUser",
        "/Users/$adminUser"
    )

    $filesToCheck = Get-ChildItem $Path -Recurse -Include "*.ts","*.js","*.json","*.md" -File |
        Where-Object { $_.FullName -notmatch 'node_modules' }

    foreach ($file in $filesToCheck) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            foreach ($pattern in $badPatterns) {
                if ($content -match [regex]::Escape($pattern)) {
                    $script:warnings += "Hardcoded path in $($file.Name): $pattern"
                    Write-Check "Hardcoded path in $($file.Name)" "WARN"
                }
            }
        }
    }

    if ($script:warnings.Count -eq 0) {
        Write-Check "No hardcoded paths found" "OK"
    }
}

function Remove-SessionData {
    param([string]$Path)

    # Directories to remove
    $dirsToRemove = @(
        'cache', 'debug', 'logs', 'paste-cache', 'shell-snapshots',
        'session-env', 'statsig', 'state', 'telemetry', 'temp',
        'todos', 'file-history', 'history', 'projects', 'plugins',
        'config', 'bridge/reports'
    )

    # Files to remove
    $filesToRemove = @(
        'history.jsonl', 'agent-sessions.json', 'span-sessions.json',
        'langfuse-span-cache.json', 'stats-cache.json', 'tool-timing-cache.json',
        'settings.local.json', '.claude.json', '.credentials.json'
    )

    # Patterns to remove
    $patternsToRemove = @('tmpclaude-*', '*.local.json.backup*', 'nul')

    foreach ($dir in $dirsToRemove) {
        $fullPath = Join-Path $Path $dir
        if (Test-Path $fullPath) {
            if ($Fix) {
                Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                $script:fixes += "Removed directory: $dir"
                Write-Check "Removed $dir/" "FIX"
            } else {
                $script:warnings += "Session directory exists: $dir"
                Write-Check "Session directory: $dir/" "WARN"
            }
        }
    }

    foreach ($file in $filesToRemove) {
        $fullPath = Join-Path $Path $file
        if (Test-Path $fullPath) {
            if ($Fix) {
                Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
                $script:fixes += "Removed file: $file"
                Write-Check "Removed $file" "FIX"
            } else {
                $script:warnings += "Session file exists: $file"
                Write-Check "Session file: $file" "WARN"
            }
        }
    }

    foreach ($pattern in $patternsToRemove) {
        $matches = Get-ChildItem $Path -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($match in $matches) {
            if ($Fix) {
                Remove-Item $match.FullName -Force -ErrorAction SilentlyContinue
                $script:fixes += "Removed: $($match.Name)"
                Write-Check "Removed $($match.Name)" "FIX"
            } else {
                $script:warnings += "Temp file: $($match.Name)"
                Write-Check "Temp file: $($match.Name)" "WARN"
            }
        }
    }
}

# Main validation
Write-Host "Validating template: $TemplatePath" -ForegroundColor Cyan

if (-not (Test-Path $TemplatePath)) {
    Write-Host "ERROR: Template path does not exist" -ForegroundColor Red
    exit 1
}

$claudePath = Join-Path $TemplatePath ".claude"
if (-not (Test-Path $claudePath)) {
    Write-Host "ERROR: No .claude directory in template" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Checking settings.json..." -ForegroundColor White
Test-SettingsJson -Path $claudePath

Write-Host ""
Write-Host "Checking for hardcoded paths..." -ForegroundColor White
Test-HardcodedPaths -Path $claudePath

Write-Host ""
Write-Host "Checking for session data..." -ForegroundColor White
Remove-SessionData -Path $claudePath

# Summary
Write-Host ""
Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan

if ($script:errors.Count -gt 0) {
    Write-Host "Errors: $($script:errors.Count)" -ForegroundColor Red
    foreach ($e in $script:errors) { Write-Host "  - $e" -ForegroundColor Red }
}

if ($script:warnings.Count -gt 0) {
    Write-Host "Warnings: $($script:warnings.Count)" -ForegroundColor Yellow
    foreach ($w in $script:warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
}

if ($script:fixes.Count -gt 0) {
    Write-Host "Fixes applied: $($script:fixes.Count)" -ForegroundColor Cyan
    foreach ($f in $script:fixes) { Write-Host "  - $f" -ForegroundColor Cyan }
}

if ($script:errors.Count -eq 0 -and $script:warnings.Count -eq 0) {
    Write-Host "Template is clean!" -ForegroundColor Green
}

# Exit code
if ($script:errors.Count -gt 0) {
    exit 1
} else {
    exit 0
}
