# Admin-Backup.ps1 - Backup admin's .claude directory
# Called by: spawner backup [--output <path>] [--include-secrets]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [string]$Output,
    [switch]$IncludeSecrets
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
Write-Log "  ADMIN BACKUP" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $adminConfigDir" "INFO"

# Determine backup path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ($Output) {
    $backupDir = $Output
} else {
    $adminBackupPath = Join-Path $SpawnerRoot $Config.backups.adminPath
    $backupDir = Join-Path $adminBackupPath "admin-$timestamp"
}

# Create backup directory
if (-not (Test-Path (Split-Path $backupDir -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $backupDir -Parent) -Force | Out-Null
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Log "Destination: $backupDir" "INFO"

# Files/directories to exclude (unless --include-secrets)
$secretFiles = $Config.security.sanitize.removeFiles
$secretDirs = $Config.security.sanitize.removeDirs

# Build exclude list for robocopy
$excludeDirs = @()
$excludeFiles = @()

if (-not $IncludeSecrets) {
    $excludeDirs = $secretDirs
    $excludeFiles = $secretFiles
    Write-Log "Excluding secrets (use --include-secrets to include)" "INFO"
} else {
    Write-Log "WARNING: Including secrets in backup!" "WARN"
}

# Copy using robocopy
Write-Log "Copying files..." "STEP"

$robocopyArgs = @($adminConfigDir, $backupDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")

if ($excludeDirs.Count -gt 0) {
    $robocopyArgs += "/XD"
    $robocopyArgs += $excludeDirs
}

if ($excludeFiles.Count -gt 0) {
    $robocopyArgs += "/XF"
    $robocopyArgs += $excludeFiles
}

$result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
if ($result.ExitCode -gt 7) {
    Write-Log "robocopy failed with exit code $($result.ExitCode)" "ERROR"
    exit 1
}

# Generate manifest
Write-Log "Generating manifest..." "STEP"
$manifest = @{
    version = "3.0"
    type = "admin-backup"
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    source = $adminConfigDir
    includesSecrets = $IncludeSecrets.IsPresent
    files = @()
    directories = @()
}

# List what was backed up
Get-ChildItem $backupDir -File -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace("$backupDir\", "")
    $manifest.files += @{
        path = $relativePath
        size = $_.Length
        modified = $_.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

Get-ChildItem $backupDir -Directory -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace("$backupDir\", "")
    $manifest.directories += $relativePath
}

$manifest | ConvertTo-Json -Depth 10 | Out-File (Join-Path $backupDir "backup-manifest.json") -Encoding UTF8

# Cleanup old backups if retention is set
$retention = $Config.admin.backupRetention
if ($retention -and -not $Output) {
    Write-Log "Checking backup retention (keeping last $retention)..." "INFO"
    $adminBackupPath = Join-Path $SpawnerRoot $Config.backups.adminPath
    $allBackups = Get-ChildItem $adminBackupPath -Directory | Sort-Object CreationTime -Descending

    if ($allBackups.Count -gt $retention) {
        $toDelete = $allBackups | Select-Object -Skip $retention
        foreach ($old in $toDelete) {
            Write-Log "  Removing old backup: $($old.Name)" "INFO"
            Remove-Item $old.FullName -Recurse -Force
        }
    }
}

Write-Log "========================================" "OK"
Write-Log "  BACKUP COMPLETE" "OK"
Write-Log "  Location: $backupDir" "OK"
Write-Log "  Files: $($manifest.files.Count)" "OK"
Write-Log "========================================" "OK"

# Return the backup path
return $backupDir
