# Template-Promote.ps1 - Save user's .claude as a new template
# Called by: spawner promote <username> --as <template-name>

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName
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

# Validate template name
if ($TemplateName -notmatch "^[a-zA-Z][a-zA-Z0-9_-]{0,29}$") {
    Write-Log "Invalid template name. Use alphanumeric, underscore, hyphen. Max 30 chars." "ERROR"
    exit 1
}

# Check if template already exists
$templatesDir = Join-Path $SpawnerRoot "templates"
$newTemplatePath = Join-Path $templatesDir $TemplateName

if (Test-Path $newTemplatePath) {
    Write-Log "Template already exists: $TemplateName" "ERROR"
    Write-Log "Delete it first or choose a different name" "INFO"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  PROMOTE TO TEMPLATE" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $Username ($userConfigDir)" "INFO"
Write-Log "Template: $TemplateName" "INFO"

# Create template directory structure
Write-Log "Creating template directory..." "STEP"
New-Item -ItemType Directory -Path $newTemplatePath -Force | Out-Null
$templateClaudeDir = Join-Path $newTemplatePath ".claude"
New-Item -ItemType Directory -Path $templateClaudeDir -Force | Out-Null

# Run sanitization to create clean template
Write-Log "Sanitizing for template use..." "STEP"
$sanitizeScript = Join-Path $SpawnerRoot "lib\Sanitize-Config.ps1"
$sanitizeResult = & $sanitizeScript -SourcePath $userConfigDir -DestPath $templateClaudeDir -Config $Config -Validate

if (-not $sanitizeResult.Success) {
    Write-Log "Sanitization failed - template may contain secrets!" "ERROR"
    foreach ($warn in $sanitizeResult.Warnings) {
        Write-Log "  $warn" "WARN"
    }
    # Cleanup failed template
    Remove-Item $newTemplatePath -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Create template metadata
$templateMeta = @{
    name = $TemplateName
    description = "Promoted from user $Username"
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    source = $Username
    complexity = "custom"
    sanitized = $true
}

$templateMeta | ConvertTo-Json -Depth 5 | Out-File (Join-Path $newTemplatePath "template.json") -Encoding UTF8

# Update config.json with new template
Write-Log "Registering template in config.json..." "STEP"
$configPath = Join-Path $SpawnerRoot "config.json"
$configContent = Get-Content $configPath -Raw | ConvertFrom-Json

# Add new template entry
$newTemplateEntry = @{
    description = "Promoted from $Username - $(Get-Date -Format 'yyyy-MM-dd')"
    path = "templates/$TemplateName/.claude"
    complexity = "custom"
}

$configContent.templates | Add-Member -NotePropertyName $TemplateName -NotePropertyValue $newTemplateEntry -Force

# Save config
$configContent | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding UTF8

# Run template validation
Write-Log "Validating new template..." "STEP"
$validateScript = Join-Path $SpawnerRoot "lib\Validate-Template.ps1"
if (Test-Path $validateScript) {
    & $validateScript -TemplatePath $newTemplatePath -Fix -ShowDetails:$false
}

Write-Log "========================================" "OK"
Write-Log "  TEMPLATE CREATED: $TemplateName" "OK"
Write-Log "========================================" "OK"
Write-Log "" "INFO"
Write-Log "Use with:" "INFO"
Write-Log "  spawner spawn <username> --template $TemplateName" "INFO"
Write-Log "" "INFO"
Write-Log "To version control:" "INFO"
Write-Log "  spawner repo init $TemplateName" "INFO"

return $newTemplatePath
