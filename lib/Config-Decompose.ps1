# Config-Decompose.ps1 - Extract base/identity/project layers from user config
# Called by: spawner decompose <username> [--output <path>]
#
# Separates a user's .claude into reusable layers:
#   base/     - Core settings, permissions (settings.json)
#   identity/ - Skills, agents, hooks, CLAUDE.md
#   project/  - Project-specific configs

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Output
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
Write-Log "  DECOMPOSE: $Username" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $userConfigDir" "INFO"

# Determine output path
if ($Output) {
    $outputDir = $Output
} else {
    $outputDir = Join-Path $SpawnerRoot "decomposed\$Username-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

# Create layer directories
$baseDir = Join-Path $outputDir "base"
$identityDir = Join-Path $outputDir "identity"
$projectDir = Join-Path $outputDir "project"

New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
New-Item -ItemType Directory -Path $identityDir -Force | Out-Null
New-Item -ItemType Directory -Path $projectDir -Force | Out-Null

Write-Log "Output: $outputDir" "INFO"

# Define what goes where
$baseFiles = @(
    "settings.json",
    "settings.local.json"
)

$baseDirs = @(
    # Core settings only
)

$identityFiles = @(
    "CLAUDE.md",
    "IDENTITY.md",
    "CONSTITUTION.md",
    "PREFERENCES.md"
)

$identityDirs = @(
    "skills",
    "agents",
    "hooks",
    "commands",
    "bundles",
    "library"
)

$projectFiles = @(
    "PROJECTS.md"
)

$projectDirs = @(
    "projects",
    "TELOS",
    "memory"
)

# Files/dirs to exclude entirely (session data, secrets)
$excludeFiles = $Config.security.sanitize.removeFiles
$excludeDirs = $Config.security.sanitize.removeDirs

# Track what we find
$results = @{
    base = @()
    identity = @()
    project = @()
    skipped = @()
    unknown = @()
}

Write-Log "" "INFO"
Write-Log "Analyzing structure..." "STEP"

# Process base layer
Write-Log "  BASE layer (core settings):" "INFO"
foreach ($file in $baseFiles) {
    $src = Join-Path $userConfigDir $file
    if (Test-Path $src) {
        Copy-Item $src -Destination $baseDir -Force
        $results.base += $file
        Write-Log "    + $file" "OK"
    }
}

# Process identity layer
Write-Log "  IDENTITY layer (skills, agents, hooks):" "INFO"
foreach ($file in $identityFiles) {
    $src = Join-Path $userConfigDir $file
    if (Test-Path $src) {
        Copy-Item $src -Destination $identityDir -Force
        $results.identity += $file
        Write-Log "    + $file" "OK"
    }
}

foreach ($dir in $identityDirs) {
    $src = Join-Path $userConfigDir $dir
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $identityDir $dir) -Recurse -Force
        $results.identity += "$dir/"
        Write-Log "    + $dir/" "OK"
    }
}

# Process project layer
Write-Log "  PROJECT layer (project-specific):" "INFO"
foreach ($file in $projectFiles) {
    $src = Join-Path $userConfigDir $file
    if (Test-Path $src) {
        Copy-Item $src -Destination $projectDir -Force
        $results.project += $file
        Write-Log "    + $file" "OK"
    }
}

foreach ($dir in $projectDirs) {
    $src = Join-Path $userConfigDir $dir
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $projectDir $dir) -Recurse -Force
        $results.project += "$dir/"
        Write-Log "    + $dir/" "OK"
    }
}

# Check for unknown items
$allItems = Get-ChildItem $userConfigDir -Force
$knownItems = $baseFiles + $baseDirs + $identityFiles + $identityDirs + $projectFiles + $projectDirs + $excludeFiles + $excludeDirs

foreach ($item in $allItems) {
    $name = $item.Name
    if ($knownItems -notcontains $name -and $excludeFiles -notcontains $name -and $excludeDirs -notcontains $name) {
        $results.unknown += $name
        Write-Log "  UNKNOWN: $name (not categorized)" "WARN"
    }
    if ($excludeFiles -contains $name -or $excludeDirs -contains $name) {
        $results.skipped += $name
    }
}

# Run sanitization on each layer
Write-Log "" "INFO"
Write-Log "Sanitizing layers..." "STEP"

$sanitizeScript = Join-Path $SpawnerRoot "lib\Sanitize-Config.ps1"
if (Test-Path $sanitizeScript) {
    foreach ($layer in @("base", "identity", "project")) {
        $layerPath = Join-Path $outputDir $layer
        if ((Get-ChildItem $layerPath -Recurse -File).Count -gt 0) {
            $tempSanitize = Join-Path $env:TEMP "spawner-sanitize-$(Get-Random)"
            New-Item -ItemType Directory -Path $tempSanitize -Force | Out-Null

            # Copy to temp, sanitize, copy back
            Copy-Item "$layerPath\*" -Destination $tempSanitize -Recurse -Force -ErrorAction SilentlyContinue
            $result = & $sanitizeScript -SourcePath $tempSanitize -DestPath $layerPath -Config $Config
            Remove-Item $tempSanitize -Recurse -Force -ErrorAction SilentlyContinue

            Write-Log "  $layer layer sanitized" "OK"
        }
    }
}

# Generate manifest
Write-Log "Generating manifest..." "STEP"

$manifest = @{
    version = "3.0"
    type = "decomposed"
    username = $Username
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    source = $userConfigDir
    layers = @{
        base = $results.base
        identity = $results.identity
        project = $results.project
    }
    skipped = $results.skipped
    unknown = $results.unknown
    instructions = @"
DECOMPOSED CONFIG LAYERS

base/     - Core settings (settings.json)
            Use as foundation for any template.

identity/ - Skills, agents, hooks, CLAUDE.md
            Defines AI personality and capabilities.
            Can be mixed with different bases.

project/  - Project-specific configs (TELOS, memory)
            User's personal context.
            Usually not shared.

TO RECOMPOSE:
  spawner compose <decomposed-path> <username>

TO USE LAYERS:
  1. Start with a base template
  2. Merge identity as overlay
  3. Optionally add project layer
"@
}

$manifest | ConvertTo-Json -Depth 10 | Out-File (Join-Path $outputDir "decompose-manifest.json") -Encoding UTF8

# Summary
Write-Log "" "INFO"
Write-Log "========================================" "OK"
Write-Log "  DECOMPOSITION COMPLETE" "OK"
Write-Log "========================================" "OK"
Write-Log "" "INFO"
Write-Log "Output: $outputDir" "INFO"
Write-Log "" "INFO"
Write-Log "Layers:" "INFO"
Write-Log "  base/     $($results.base.Count) items" "INFO"
Write-Log "  identity/ $($results.identity.Count) items" "INFO"
Write-Log "  project/  $($results.project.Count) items" "INFO"

if ($results.unknown.Count -gt 0) {
    Write-Log "" "INFO"
    Write-Log "Unknown items (review manually):" "WARN"
    foreach ($item in $results.unknown) {
        Write-Log "  ? $item" "WARN"
    }
}

Write-Log "" "INFO"
Write-Log "Each layer can be used independently:" "INFO"
Write-Log "  - base/ as a template foundation" "INFO"
Write-Log "  - identity/ as a spawner identity overlay" "INFO"
Write-Log "  - project/ for personal context" "INFO"

return $outputDir
