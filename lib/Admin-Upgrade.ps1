# Admin-Upgrade.ps1 - Upgrade admin config from template or git URL
# Called by: spawner upgrade [--from <template|git-url>] [--preserve <paths>]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [string]$From,
    [string[]]$Preserve
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "OK"    { "Green" }
        "STEP"  { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Get admin config directory
$adminConfigDir = $Config.admin.configDir
if (-not $adminConfigDir) {
    $adminConfigDir = "$env:USERPROFILE\.claude"
}

if (-not (Test-Path $adminConfigDir)) {
    Write-Log "Admin .claude directory not found: $adminConfigDir" "ERROR"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  ADMIN UPGRADE" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Target: $adminConfigDir" "INFO"

# Determine source
$isGitUrl = $From -and ($From -match "^https?://" -or $From -match "^git@")
$sourcePath = $null
$tempDir = $null

if (-not $From) {
    # Interactive selection
    Write-Log "Available templates:" "INFO"
    $templates = $Config.templates.PSObject.Properties
    $i = 1
    foreach ($t in $templates) {
        Write-Log "  [$i] $($t.Name) - $($t.Value.description)" "INFO"
        $i++
    }
    $selection = Read-Host "Select template (1-$($templates.Count)) or enter git URL"

    if ($selection -match "^\d+$") {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $templates.Count) {
            $From = $templates[$selectedIndex].Name
        } else {
            Write-Log "Invalid selection" "ERROR"
            exit 1
        }
    } else {
        $From = $selection
        $isGitUrl = $From -match "^https?://" -or $From -match "^git@"
    }
}

if ($isGitUrl) {
    # Clone from git
    Write-Log "Source: $From (git)" "INFO"
    $tempDir = Join-Path $env:TEMP "spawner-upgrade-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    Write-Log "Cloning repository..." "STEP"
    $gitResult = & git clone --depth 1 $From $tempDir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Git clone failed: $gitResult" "ERROR"
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # Look for .claude directory in cloned repo
    if (Test-Path (Join-Path $tempDir ".claude")) {
        $sourcePath = Join-Path $tempDir ".claude"
    } else {
        # Maybe it's a bare .claude contents
        $sourcePath = $tempDir
    }
} else {
    # Use template
    Write-Log "Source: $From (template)" "INFO"

    if (-not $Config.templates.$From) {
        Write-Log "Template not found: $From" "ERROR"
        Write-Log "Available: $($Config.templates.PSObject.Properties.Name -join ', ')" "INFO"
        exit 1
    }

    $sourcePath = Join-Path $SpawnerRoot $Config.templates.$From.path
    if (-not (Test-Path $sourcePath)) {
        Write-Log "Template path not found: $sourcePath" "ERROR"
        exit 1
    }
}

# Default preserve paths from config
if (-not $Preserve -or $Preserve.Count -eq 0) {
    $Preserve = $Config.sync.preservePaths
}

Write-Log "Preserve: $($Preserve -join ', ')" "INFO"

# Auto-backup before upgrade
if ($Config.admin.autoBackupOnUpgrade) {
    Write-Log "Creating automatic backup..." "STEP"
    $backupScript = Join-Path $SpawnerRoot "lib\Admin-Backup.ps1"
    if (Test-Path $backupScript) {
        $backupPath = & $backupScript -Config $Config -SpawnerRoot $SpawnerRoot
        Write-Log "  Backup: $backupPath" "OK"
    }
}

# Save preserved directories
$preservedData = @{}
foreach ($path in $Preserve) {
    $fullPath = Join-Path $adminConfigDir $path
    if (Test-Path $fullPath) {
        $tempPreserve = Join-Path $env:TEMP "spawner-preserve-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempPreserve -Force | Out-Null

        if (Test-Path $fullPath -PathType Container) {
            Copy-Item $fullPath -Destination (Join-Path $tempPreserve $path) -Recurse -Force
        } else {
            $parentDir = Split-Path $path -Parent
            if ($parentDir) {
                New-Item -ItemType Directory -Path (Join-Path $tempPreserve $parentDir) -Force | Out-Null
            }
            Copy-Item $fullPath -Destination (Join-Path $tempPreserve $path) -Force
        }
        $preservedData[$path] = $tempPreserve
        Write-Log "  Preserved: $path" "INFO"
    }
}

# Also preserve .env (API key)
$envPath = Join-Path $adminConfigDir ".env"
$envContent = $null
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath -Raw
    Write-Log "  Preserved: .env (API key)" "INFO"
}

try {
    # Copy template to admin config
    Write-Log "Applying upgrade..." "STEP"

    $robocopyArgs = @($sourcePath, $adminConfigDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
    # Exclude session data
    $robocopyArgs += "/XD"
    $robocopyArgs += $Config.sync.excludePaths

    $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

    if ($result.ExitCode -gt 7) {
        throw "robocopy failed with exit code $($result.ExitCode)"
    }

    # Restore preserved directories
    foreach ($path in $preservedData.Keys) {
        $tempPreserve = $preservedData[$path]
        $srcPath = Join-Path $tempPreserve $path
        $dstPath = Join-Path $adminConfigDir $path

        if (Test-Path $srcPath -PathType Container) {
            if (Test-Path $dstPath) { Remove-Item $dstPath -Recurse -Force }
            Copy-Item $srcPath -Destination $dstPath -Recurse -Force
        } else {
            Copy-Item $srcPath -Destination $dstPath -Force
        }
        Write-Log "  Restored: $path" "INFO"

        # Cleanup temp
        Remove-Item (Split-Path $tempPreserve -Parent) -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Restore .env
    if ($envContent) {
        $envContent | Out-File $envPath -Encoding UTF8 -NoNewline
        Write-Log "  Restored: .env" "INFO"
    }

    Write-Log "========================================" "OK"
    Write-Log "  UPGRADE COMPLETE" "OK"
    Write-Log "========================================" "OK"

} catch {
    Write-Log "Upgrade failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Check auto-backup to restore previous config." "WARN"
    exit 1

} finally {
    # Cleanup temp git clone
    if ($tempDir -and (Test-Path $tempDir)) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
