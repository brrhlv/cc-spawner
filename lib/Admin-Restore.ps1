# Admin-Restore.ps1 - Restore admin's .claude from backup
# Called by: spawner restore <backup-path> [--merge] [--force]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$BackupPath,
    [switch]$Merge,
    [switch]$Force
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

# Resolve backup path (could be relative or absolute)
if (-not [System.IO.Path]::IsPathRooted($BackupPath)) {
    # Try relative to spawner root
    $testPath = Join-Path $SpawnerRoot $BackupPath
    if (Test-Path $testPath) {
        $BackupPath = $testPath
    } else {
        # Try relative to admin backups
        $testPath = Join-Path $SpawnerRoot (Join-Path $Config.backups.adminPath $BackupPath)
        if (Test-Path $testPath) {
            $BackupPath = $testPath
        }
    }
}

if (-not (Test-Path $BackupPath)) {
    Write-Log "Backup not found: $BackupPath" "ERROR"
    exit 1
}

# Check for manifest
$manifestPath = Join-Path $BackupPath "backup-manifest.json"
if (Test-Path $manifestPath) {
    $backupManifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    Write-Log "Found backup manifest (created: $($backupManifest.created))" "INFO"
} else {
    Write-Log "No manifest found - proceeding with unverified backup" "WARN"
    $backupManifest = $null
}

# Get admin config directory
$adminConfigDir = $Config.admin.configDir
if (-not $adminConfigDir) {
    $adminConfigDir = "$env:USERPROFILE\.claude"
}

Write-Log "========================================" "STEP"
Write-Log "  ADMIN RESTORE" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $BackupPath" "INFO"
Write-Log "Target: $adminConfigDir" "INFO"
Write-Log "Mode: $(if ($Merge) { 'MERGE' } else { 'REPLACE' })" "INFO"

# Confirm unless forced
if (-not $Force) {
    $response = Read-Host "Restore admin config from backup? (yes/no)"
    if ($response -ne "yes") {
        Write-Log "Aborted" "WARN"
        exit 0
    }
}

# Auto-backup current config if configured
if ($Config.admin.autoBackupOnUpgrade) {
    Write-Log "Creating automatic backup of current config..." "STEP"
    $autoBackupScript = Join-Path $SpawnerRoot "lib\Admin-Backup.ps1"
    if (Test-Path $autoBackupScript) {
        $autoBackupPath = & $autoBackupScript -Config $Config -SpawnerRoot $SpawnerRoot
        Write-Log "  Auto-backup: $autoBackupPath" "OK"
    }
}

try {
    if ($Merge) {
        # Merge mode: copy files but don't delete existing
        Write-Log "Merging files (preserving existing)..." "STEP"

        $robocopyArgs = @($BackupPath, $adminConfigDir, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/XF", "backup-manifest.json")
        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

        if ($result.ExitCode -gt 7) {
            throw "robocopy failed with exit code $($result.ExitCode)"
        }
    } else {
        # Replace mode: mirror the backup (except manifest)
        Write-Log "Replacing config (mirror mode)..." "STEP"

        # First, backup .env if it exists (we never want to lose API key)
        $envBackup = $null
        $envPath = Join-Path $adminConfigDir ".env"
        if (Test-Path $envPath) {
            $envBackup = Get-Content $envPath -Raw
        }

        $robocopyArgs = @($BackupPath, $adminConfigDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/XF", "backup-manifest.json")
        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

        if ($result.ExitCode -gt 7) {
            throw "robocopy failed with exit code $($result.ExitCode)"
        }

        # Restore .env if it was there and backup didn't have it
        if ($envBackup -and -not (Test-Path $envPath)) {
            $envBackup | Out-File $envPath -Encoding UTF8 -NoNewline
            Write-Log "  Preserved existing .env (API key)" "INFO"
        }
    }

    Write-Log "========================================" "OK"
    Write-Log "  RESTORE COMPLETE" "OK"
    Write-Log "========================================" "OK"

} catch {
    Write-Log "Restore failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Your previous config may have been modified. Check auto-backup if available." "WARN"
    exit 1
}
