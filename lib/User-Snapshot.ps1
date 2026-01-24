# User-Snapshot.ps1 - Create full snapshot of user's .claude directory
# Called by: spawner snapshot <username> [--output <path>] [--full]
# This is an internal backup, NOT sanitized for sharing (use export for that)

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Output,
    [switch]$Full
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

# Validate user exists
$userHome = "C:\Users\$Username"
$userConfigDir = "$userHome\.claude"

if (-not (Test-Path $userConfigDir)) {
    Write-Log "User .claude directory not found: $userConfigDir" "ERROR"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  USER SNAPSHOT: $Username" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $userConfigDir" "INFO"

# Determine snapshot path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ($Output) {
    $snapshotDir = $Output
} else {
    $usersBackupPath = Join-Path $SpawnerRoot $Config.backups.usersPath
    $snapshotDir = Join-Path $usersBackupPath "$Username-$timestamp"
}

# Create snapshot directory
$parentDir = Split-Path $snapshotDir -Parent
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

Write-Log "Destination: $snapshotDir" "INFO"

# Determine what to exclude
$excludeDirs = @()
$excludeFiles = @()

if (-not $Full) {
    # Exclude session data for normal snapshot
    $excludeDirs = $Config.security.sanitize.removeDirs
    Write-Log "Mode: Standard (excluding session data)" "INFO"
} else {
    Write-Log "Mode: Full (including all files)" "INFO"
}

# Copy using robocopy
Write-Log "Creating snapshot..." "STEP"

$robocopyArgs = @($userConfigDir, $snapshotDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")

if ($excludeDirs.Count -gt 0) {
    $robocopyArgs += "/XD"
    $robocopyArgs += $excludeDirs
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
    type = "user-snapshot"
    username = $Username
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    source = $userConfigDir
    full = $Full.IsPresent
    files = @()
    directories = @()
}

# Count files and dirs
Get-ChildItem $snapshotDir -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $relativePath = $_.FullName.Replace("$snapshotDir\", "")
    $manifest.files += @{
        path = $relativePath
        size = $_.Length
        modified = $_.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

Get-ChildItem $snapshotDir -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $relativePath = $_.FullName.Replace("$snapshotDir\", "")
    $manifest.directories += $relativePath
}

$manifest | ConvertTo-Json -Depth 10 | Out-File (Join-Path $snapshotDir "snapshot-manifest.json") -Encoding UTF8

# Cleanup old snapshots if retention is set
$retentionDays = $Config.backups.retentionDays
if ($retentionDays -and -not $Output) {
    Write-Log "Checking snapshot retention ($retentionDays days)..." "INFO"
    $usersBackupPath = Join-Path $SpawnerRoot $Config.backups.usersPath
    $cutoffDate = (Get-Date).AddDays(-$retentionDays)

    Get-ChildItem $usersBackupPath -Directory | Where-Object {
        $_.Name -match "^$Username-" -and $_.CreationTime -lt $cutoffDate
    } | ForEach-Object {
        Write-Log "  Removing old snapshot: $($_.Name)" "INFO"
        Remove-Item $_.FullName -Recurse -Force
    }
}

Write-Log "========================================" "OK"
Write-Log "  SNAPSHOT COMPLETE" "OK"
Write-Log "  Location: $snapshotDir" "OK"
Write-Log "  Files: $($manifest.files.Count)" "OK"
Write-Log "========================================" "OK"

return $snapshotDir
