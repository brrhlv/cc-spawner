# GitHub-Publish.ps1 - Publish template to GitHub
# Called by: spawner publish <template> --repo <owner/repo> [--private]
# Requires: gh CLI authenticated

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    [string]$Repo,
    [switch]$Private
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

# Check gh CLI is available
$ghPath = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghPath) {
    Write-Log "GitHub CLI (gh) not found. Install from: https://cli.github.com/" "ERROR"
    exit 1
}

# Check gh is authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log "GitHub CLI not authenticated. Run: gh auth login" "ERROR"
    exit 1
}

# Validate template exists
if (-not $Config.templates.$TemplateName) {
    Write-Log "Template not found: $TemplateName" "ERROR"
    Write-Log "Available: $($Config.templates.PSObject.Properties.Name -join ', ')" "INFO"
    exit 1
}

$templateClaudePath = Join-Path $SpawnerRoot $Config.templates.$TemplateName.path
$templateRoot = Split-Path $templateClaudePath -Parent

if (-not (Test-Path $templateRoot)) {
    Write-Log "Template directory not found: $templateRoot" "ERROR"
    exit 1
}

# Determine repo name
if (-not $Repo) {
    $prefix = $Config.github.templatePrefix
    if (-not $prefix) { $prefix = "cc-template-" }
    $Repo = "$prefix$TemplateName"
    Write-Log "No --repo specified, using: $Repo" "INFO"
}

# Parse owner/repo
if ($Repo -match "^([^/]+)/(.+)$") {
    $repoOwner = $Matches[1]
    $repoName = $Matches[2]
} else {
    # Get current user
    $repoOwner = (gh api user --jq '.login' 2>&1)
    $repoName = $Repo
}

$fullRepo = "$repoOwner/$repoName"

Write-Log "========================================" "STEP"
Write-Log "  PUBLISH TO GITHUB" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Template: $TemplateName" "INFO"
Write-Log "Repository: $fullRepo" "INFO"
Write-Log "Visibility: $(if ($Private) { 'private' } else { 'public' })" "INFO"

# Ensure template has git initialized
$gitDir = Join-Path $templateRoot ".git"
if (-not (Test-Path $gitDir)) {
    Write-Log "Template not version controlled. Initializing..." "STEP"
    $gitRepoScript = Join-Path $SpawnerRoot "lib\Git-Repo.ps1"
    & $gitRepoScript -Config $Config -SpawnerRoot $SpawnerRoot -Action "init" -TemplateName $TemplateName
}

# Run sanitization check before publishing
Write-Log "Verifying no secrets in template..." "STEP"
$sanitizeScript = Join-Path $SpawnerRoot "lib\Sanitize-Config.ps1"
$tempCheck = Join-Path $env:TEMP "spawner-publish-check-$(Get-Random)"
New-Item -ItemType Directory -Path $tempCheck -Force | Out-Null

$checkResult = & $sanitizeScript -SourcePath $templateClaudePath -DestPath $tempCheck -Config $Config -Validate
Remove-Item $tempCheck -Recurse -Force -ErrorAction SilentlyContinue

if (-not $checkResult.Success) {
    Write-Log "SECURITY CHECK FAILED - secrets detected!" "ERROR"
    foreach ($warn in $checkResult.Warnings) {
        Write-Log "  $warn" "WARN"
    }
    Write-Log "Run sanitization first or remove secrets manually" "ERROR"
    exit 1
}
Write-Log "  Security check passed" "OK"

# Create README if it doesn't exist
$readmePath = Join-Path $templateRoot "README.md"
if (-not (Test-Path $readmePath)) {
    Write-Log "Creating README.md..." "STEP"
    $readmeTemplate = Join-Path $SpawnerRoot "lib\templates\GITHUB-README.md"

    if (Test-Path $readmeTemplate) {
        $readme = Get-Content $readmeTemplate -Raw
        $readme = $readme -replace "\{TEMPLATE_NAME\}", $TemplateName
        $readme = $readme -replace "\{REPO\}", $fullRepo
        $readme = $readme -replace "\{DATE\}", (Get-Date -Format "yyyy-MM-dd")
        $readme | Out-File $readmePath -Encoding UTF8
    } else {
        # Default README
        $readme = @"
# $TemplateName

Claude Code configuration template.

## Installation

### Using Spawner

```powershell
spawner clone https://github.com/$fullRepo <username>
```

### Manual

1. Clone this repository
2. Copy `.claude/` to your user's `.claude` directory
3. Create `.env` with your API key

## Contents

- Claude Code settings and permissions
- Skills, agents, and hooks
- Custom commands

---

*Published with [Spawner](https://github.com/brrhlv/cc-spawner)*
"@
        $readme | Out-File $readmePath -Encoding UTF8
    }
}

Push-Location $templateRoot
try {
    # Commit any pending changes
    $status = git status --porcelain 2>&1
    if ($status) {
        Write-Log "Committing pending changes..." "STEP"
        git add -A 2>&1 | Out-Null
        git commit -m "Prepare for GitHub publish" 2>&1 | Out-Null
    }

    # Check if repo exists on GitHub
    $repoExists = gh repo view $fullRepo 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Repository exists, pushing updates..." "STEP"

        # Check if remote is set
        $remotes = git remote 2>&1
        if ($remotes -notcontains "origin") {
            git remote add origin "https://github.com/$fullRepo.git" 2>&1 | Out-Null
        }

        git push -u origin HEAD 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Push failed. Check permissions." "ERROR"
            exit 1
        }

    } else {
        Write-Log "Creating new repository..." "STEP"

        $visibility = if ($Private) { "--private" } else { "--public" }
        $description = $Config.templates.$TemplateName.description
        if (-not $description) { $description = "Claude Code template: $TemplateName" }

        gh repo create $fullRepo $visibility --description "$description" --source . --push 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create repository" "ERROR"
            exit 1
        }
    }

    Write-Log "========================================" "OK"
    Write-Log "  PUBLISHED SUCCESSFULLY" "OK"
    Write-Log "========================================" "OK"
    Write-Log "" "INFO"
    Write-Log "URL: https://github.com/$fullRepo" "INFO"
    Write-Log "" "INFO"
    Write-Log "Share with:" "INFO"
    Write-Log "  spawner clone https://github.com/$fullRepo <username>" "INFO"

} finally {
    Pop-Location
}

return "https://github.com/$fullRepo"
