# User-Import.ps1 - Import snapshot/export to user
# Called by: spawner import <path> <username> [--merge]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$ImportPath,
    [Parameter(Mandatory=$true)]
    [string]$TargetUser,
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

# Validate target user exists
$targetHome = "C:\Users\$TargetUser"
$targetConfigDir = "$targetHome\.claude"

if (-not (Test-Path $targetHome)) {
    Write-Log "Target user home not found: $targetHome" "ERROR"
    Write-Log "Create the user first with: spawner spawn $TargetUser" "INFO"
    exit 1
}

# Resolve import path
if (-not [System.IO.Path]::IsPathRooted($ImportPath)) {
    $testPath = Join-Path (Get-Location) $ImportPath
    if (Test-Path $testPath) {
        $ImportPath = $testPath
    }
}

if (-not (Test-Path $ImportPath)) {
    Write-Log "Import path not found: $ImportPath" "ERROR"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  IMPORT TO: $TargetUser" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $ImportPath" "INFO"
Write-Log "Target: $targetConfigDir" "INFO"
Write-Log "Mode: $(if ($Merge) { 'MERGE' } else { 'REPLACE' })" "INFO"

# Determine if it's a zip or directory
$isZip = $ImportPath -match "\.zip$"
$sourceDir = $ImportPath

if ($isZip) {
    Write-Log "Extracting zip archive..." "STEP"
    $tempDir = Join-Path $env:TEMP "spawner-import-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Expand-Archive -Path $ImportPath -DestinationPath $tempDir -Force
    $sourceDir = $tempDir
}

# Check for manifest
$manifestPath = Get-ChildItem $sourceDir -Filter "*-manifest.json" -Recurse | Select-Object -First 1
if ($manifestPath) {
    $manifest = Get-Content $manifestPath.FullName -Raw | ConvertFrom-Json
    Write-Log "Found manifest: $($manifest.type) from $($manifest.username)" "INFO"
}

# Backup current config if it exists
if (Test-Path $targetConfigDir) {
    Write-Log "Backing up current config..." "STEP"
    $snapshotScript = Join-Path $SpawnerRoot "lib\User-Snapshot.ps1"
    if (Test-Path $snapshotScript) {
        & $snapshotScript -Config $Config -SpawnerRoot $SpawnerRoot -Username $TargetUser | Out-Null
        Write-Log "  Backup created" "OK"
    }
}

# Create target directory if needed
if (-not (Test-Path $targetConfigDir)) {
    New-Item -ItemType Directory -Path $targetConfigDir -Force | Out-Null
}

# Preserve .env (API key) from target
$envBackup = $null
$targetEnvPath = Join-Path $targetConfigDir ".env"
if (Test-Path $targetEnvPath) {
    $envBackup = Get-Content $targetEnvPath -Raw
    Write-Log "Preserving target .env (API key)" "INFO"
}

try {
    if ($Merge) {
        Write-Log "Merging files (preserving existing)..." "STEP"
        $robocopyArgs = @($sourceDir, $targetConfigDir, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
        # Exclude manifest files
        $robocopyArgs += "/XF"
        $robocopyArgs += "*-manifest.json"
        $robocopyArgs += "README.md"
    } else {
        Write-Log "Replacing config..." "STEP"
        $robocopyArgs = @($sourceDir, $targetConfigDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
        $robocopyArgs += "/XF"
        $robocopyArgs += "*-manifest.json"
        $robocopyArgs += "README.md"
    }

    $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
    if ($result.ExitCode -gt 7) {
        throw "robocopy failed with exit code $($result.ExitCode)"
    }

    # Replace {USER_HOME} placeholders
    Write-Log "Replacing path placeholders..." "STEP"
    $textExtensions = @(".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".js", ".ts", ".ps1", ".sh")
    $textFiles = Get-ChildItem $targetConfigDir -Recurse -File | Where-Object {
        $ext = $_.Extension.ToLower()
        $textExtensions -contains $ext
    }

    $replacementCount = 0
    foreach ($file in $textFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match "\{USER_HOME\}") {
                $content = $content -replace "\{USER_HOME\}", $targetHome
                $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
                $replacementCount++
            }
        } catch {
            # Skip files we can't process
        }
    }
    if ($replacementCount -gt 0) {
        Write-Log "  Replaced placeholders in $replacementCount files" "INFO"
    }

    # Restore .env if we had one and import didn't include one
    if ($envBackup) {
        if (-not (Test-Path $targetEnvPath) -or (Get-Content $targetEnvPath -Raw) -match "\[REDACTED\]") {
            $envBackup | Out-File $targetEnvPath -Encoding UTF8 -NoNewline
            Write-Log "Restored .env (API key)" "OK"
        }
    } else {
        # Check if .env exists, if not warn
        if (-not (Test-Path $targetEnvPath)) {
            Write-Log "No .env file - user will need to add API key" "WARN"
            Write-Log "  Create: $targetEnvPath" "WARN"
            Write-Log "  Content: ANTHROPIC_API_KEY=sk-ant-api..." "WARN"
        }
    }

    # Set ownership if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Log "Setting file ownership..." "STEP"
        icacls $targetConfigDir /setowner $TargetUser /T /C 2>&1 | Out-Null
        icacls $targetConfigDir /grant "${TargetUser}:(OI)(CI)F" /T /C 2>&1 | Out-Null
        Write-Log "  Ownership set" "OK"
    }

    Write-Log "========================================" "OK"
    Write-Log "  IMPORT COMPLETE" "OK"
    Write-Log "========================================" "OK"

} catch {
    Write-Log "Import failed: $($_.Exception.Message)" "ERROR"
    exit 1

} finally {
    # Cleanup temp dir if we extracted a zip
    if ($isZip -and (Test-Path $tempDir)) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
