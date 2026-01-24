# Config-Compose.ps1 - Recompose decomposed layers into a user config
# Called internally or via: spawner compose <decomposed-path> <username>
#
# Takes base/, identity/, project/ layers and merges into target user

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    [Parameter(Mandatory=$true)]
    [string]$TargetUser,
    [string[]]$Layers = @("base", "identity", "project"),
    [switch]$Merge
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

# Validate source path
if (-not (Test-Path $SourcePath)) {
    Write-Log "Source path not found: $SourcePath" "ERROR"
    exit 1
}

# Check for manifest
$manifestPath = Join-Path $SourcePath "decompose-manifest.json"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    Write-Log "Found manifest from: $($manifest.username)" "INFO"
}

# Validate target user
$targetHome = "C:\Users\$TargetUser"
$targetConfigDir = "$targetHome\.claude"

if (-not (Test-Path $targetHome)) {
    Write-Log "Target user home not found: $targetHome" "ERROR"
    Write-Log "Create user first with: spawner spawn $TargetUser" "INFO"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  COMPOSE LAYERS -> $TargetUser" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $SourcePath" "INFO"
Write-Log "Target: $targetConfigDir" "INFO"
Write-Log "Layers: $($Layers -join ', ')" "INFO"
Write-Log "Mode: $(if ($Merge) { 'MERGE' } else { 'REPLACE' })" "INFO"

# Backup current config
if (Test-Path $targetConfigDir) {
    Write-Log "Backing up current config..." "STEP"
    $snapshotScript = Join-Path $SpawnerRoot "lib\User-Snapshot.ps1"
    if (Test-Path $snapshotScript) {
        & $snapshotScript -Config $Config -SpawnerRoot $SpawnerRoot -Username $TargetUser | Out-Null
        Write-Log "  Backup created" "OK"
    }
}

# Preserve .env
$envBackup = $null
$envPath = Join-Path $targetConfigDir ".env"
if (Test-Path $envPath) {
    $envBackup = Get-Content $envPath -Raw
    Write-Log "Preserving .env" "INFO"
}

# Create target if needed
if (-not (Test-Path $targetConfigDir)) {
    New-Item -ItemType Directory -Path $targetConfigDir -Force | Out-Null
}

# If not merging, clear target first
if (-not $Merge) {
    Write-Log "Clearing target directory..." "STEP"
    Get-ChildItem $targetConfigDir -Force | Where-Object { $_.Name -ne ".env" } | Remove-Item -Recurse -Force
}

# Apply layers in order
foreach ($layer in $Layers) {
    $layerPath = Join-Path $SourcePath $layer

    if (-not (Test-Path $layerPath)) {
        Write-Log "Layer not found: $layer (skipping)" "WARN"
        continue
    }

    $itemCount = (Get-ChildItem $layerPath -Recurse -File -ErrorAction SilentlyContinue).Count
    if ($itemCount -eq 0) {
        Write-Log "Layer empty: $layer (skipping)" "INFO"
        continue
    }

    Write-Log "Applying layer: $layer ($itemCount files)..." "STEP"

    # Copy layer contents to target
    Get-ChildItem $layerPath -Force | ForEach-Object {
        $destPath = Join-Path $targetConfigDir $_.Name

        if ($_.PSIsContainer) {
            # Directory - merge or replace
            if ($Merge -and (Test-Path $destPath)) {
                # Merge: copy files without deleting existing
                $robocopyArgs = @($_.FullName, $destPath, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            } else {
                # Replace
                if (Test-Path $destPath) { Remove-Item $destPath -Recurse -Force }
                $robocopyArgs = @($_.FullName, $destPath, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            }
            Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow | Out-Null
        } else {
            # File - always overwrite
            Copy-Item $_.FullName -Destination $destPath -Force
        }
    }

    Write-Log "  Applied: $layer" "OK"
}

# Restore .env
if ($envBackup) {
    $envBackup | Out-File $envPath -Encoding UTF8 -NoNewline
    Write-Log "Restored .env" "OK"
}

# Replace path placeholders
Write-Log "Replacing path placeholders..." "STEP"
$textFiles = Get-ChildItem $targetConfigDir -Recurse -File -Include "*.md","*.json","*.yaml","*.yml","*.txt","*.js","*.ts","*.ps1" -ErrorAction SilentlyContinue

$replacementCount = 0
foreach ($file in $textFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "\{USER_HOME\}") {
            $content = $content -replace "\{USER_HOME\}", $targetHome
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
            $replacementCount++
        }
    } catch {}
}

if ($replacementCount -gt 0) {
    Write-Log "  Replaced placeholders in $replacementCount files" "OK"
}

# Set ownership
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Log "Setting file ownership..." "STEP"
    icacls $targetConfigDir /setowner $TargetUser /T /C 2>&1 | Out-Null
    icacls $targetConfigDir /grant "${TargetUser}:(OI)(CI)F" /T /C 2>&1 | Out-Null
    Write-Log "  Ownership set" "OK"
}

Write-Log "========================================" "OK"
Write-Log "  COMPOSE COMPLETE" "OK"
Write-Log "========================================" "OK"
Write-Log "" "INFO"
Write-Log "User $TargetUser now has:" "INFO"
foreach ($layer in $Layers) {
    $layerPath = Join-Path $SourcePath $layer
    if (Test-Path $layerPath) {
        Write-Log "  - $layer layer applied" "INFO"
    }
}
