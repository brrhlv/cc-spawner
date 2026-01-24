# GitHub-Clone.ps1 - Spawn user from GitHub template URL
# Called by: spawner clone <github-url> <username> [--identity <name>]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$GitHubUrl,
    [Parameter(Mandatory=$true)]
    [string]$TargetUser,
    [string]$Identity
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

# Validate GitHub URL
if ($GitHubUrl -notmatch "github\.com") {
    Write-Log "Invalid GitHub URL: $GitHubUrl" "ERROR"
    exit 1
}

# Convert to clone URL if needed
$cloneUrl = $GitHubUrl
if ($cloneUrl -notmatch "\.git$") {
    $cloneUrl = "$cloneUrl.git"
}
if ($cloneUrl -match "^https://github\.com/") {
    # Already HTTPS, good
} elseif ($cloneUrl -match "^github\.com/") {
    $cloneUrl = "https://$cloneUrl"
}

Write-Log "========================================" "STEP"
Write-Log "  CLONE FROM GITHUB" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $GitHubUrl" "INFO"
Write-Log "Target user: $TargetUser" "INFO"

# Clone to temp directory
$tempDir = Join-Path $env:TEMP "spawner-clone-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Log "Cloning repository..." "STEP"
$gitResult = git clone --depth 1 $cloneUrl $tempDir 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log "Git clone failed: $gitResult" "ERROR"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Log "  Clone complete" "OK"

# Find .claude directory in cloned repo
$claudeDir = $null
if (Test-Path (Join-Path $tempDir ".claude")) {
    $claudeDir = Join-Path $tempDir ".claude"
} else {
    # Search for .claude in subdirectories
    $found = Get-ChildItem $tempDir -Directory -Recurse -Filter ".claude" | Select-Object -First 1
    if ($found) {
        $claudeDir = $found.FullName
    }
}

if (-not $claudeDir) {
    Write-Log "No .claude directory found in repository" "ERROR"
    Write-Log "Expected structure: repo/.claude/ or repo/template-name/.claude/" "INFO"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Log "Found .claude at: $claudeDir" "INFO"

# Check if target user exists
$targetHome = "C:\Users\$TargetUser"
$targetConfigDir = "$targetHome\.claude"

$userExists = Get-LocalUser -Name $TargetUser -ErrorAction SilentlyContinue

if (-not $userExists) {
    # Spawn the user first with vanilla template
    Write-Log "Creating user $TargetUser..." "STEP"

    # Check if we're admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "Must run as Administrator to create users" "ERROR"
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # Call spawn with vanilla template (we'll replace .claude after)
    $spawnerScript = Join-Path $SpawnerRoot "spawner.ps1"
    & $spawnerScript spawn $TargetUser --template cc-vanilla
}

# Now import the cloned config
Write-Log "Importing configuration..." "STEP"

# Use the import script
$importScript = Join-Path $SpawnerRoot "lib\User-Import.ps1"
if (Test-Path $importScript) {
    & $importScript -Config $Config -SpawnerRoot $SpawnerRoot -ImportPath $claudeDir -TargetUser $TargetUser
} else {
    # Manual import
    if (Test-Path $targetConfigDir) {
        # Backup existing
        $backupDir = Join-Path $SpawnerRoot "backups\users\$TargetUser-preclone-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path (Split-Path $backupDir -Parent) -Force | Out-Null
        Copy-Item $targetConfigDir -Destination $backupDir -Recurse -Force
    }

    # Copy cloned config
    if (-not (Test-Path $targetConfigDir)) {
        New-Item -ItemType Directory -Path $targetConfigDir -Force | Out-Null
    }

    $robocopyArgs = @($claudeDir, $targetConfigDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
    Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow | Out-Null

    # Replace path placeholders
    $textFiles = Get-ChildItem $targetConfigDir -Recurse -File -Include "*.md","*.json","*.yaml","*.yml","*.txt","*.js","*.ts","*.ps1"
    foreach ($file in $textFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match "\{USER_HOME\}") {
                $content = $content -replace "\{USER_HOME\}", $targetHome
                $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
            }
        } catch {}
    }
}

# Apply identity if specified
if ($Identity) {
    Write-Log "Applying identity: $Identity..." "STEP"
    $mergeScript = Join-Path $SpawnerRoot "lib\Merge-Identity.ps1"
    $identityPath = Join-Path $SpawnerRoot "identities\$Identity"

    if ((Test-Path $mergeScript) -and (Test-Path $identityPath)) {
        & $mergeScript -UserPath $targetConfigDir -IdentityPath $identityPath -ShowDetails
    } else {
        Write-Log "  Identity not found or merge script missing" "WARN"
    }
}

# Set ownership
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Log "Setting file ownership..." "STEP"
    icacls $targetConfigDir /setowner $TargetUser /T /C 2>&1 | Out-Null
    icacls $targetConfigDir /grant "${TargetUser}:(OI)(CI)F" /T /C 2>&1 | Out-Null
}

# Cleanup
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Check for .env
$envPath = Join-Path $targetConfigDir ".env"
if (-not (Test-Path $envPath)) {
    Write-Log "" "INFO"
    Write-Log "NOTE: No API key configured!" "WARN"
    Write-Log "Create $envPath with:" "WARN"
    Write-Log "  ANTHROPIC_API_KEY=sk-ant-api..." "WARN"
}

Write-Log "========================================" "OK"
Write-Log "  CLONE COMPLETE: $TargetUser" "OK"
Write-Log "========================================" "OK"
Write-Log "" "INFO"
Write-Log "Switch to user:" "INFO"
Write-Log "  runas /user:$TargetUser cmd" "INFO"
Write-Log "  Then run: claude" "INFO"
