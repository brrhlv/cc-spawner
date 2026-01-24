# Git-Repo.ps1 - Manage git repository for templates
# Called by: spawner repo <action> <template> [-m <message>]
# Actions: init, status, commit

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "status", "commit")]
    [string]$Action,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    [string]$Message
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

Write-Log "========================================" "STEP"
Write-Log "  GIT REPO: $TemplateName" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Path: $templateRoot" "INFO"

switch ($Action) {
    "init" {
        $gitDir = Join-Path $templateRoot ".git"

        if (Test-Path $gitDir) {
            Write-Log "Git repository already exists" "WARN"
            exit 0
        }

        Write-Log "Initializing git repository..." "STEP"

        # Create .gitignore from template
        $gitignoreTemplate = Join-Path $SpawnerRoot "lib\templates\TEMPLATE-GITIGNORE"
        $gitignoreDest = Join-Path $templateRoot ".gitignore"

        if (Test-Path $gitignoreTemplate) {
            Copy-Item $gitignoreTemplate -Destination $gitignoreDest -Force
            Write-Log "  Created .gitignore" "OK"
        } else {
            # Create default .gitignore
            $defaultGitignore = @"
# Session data - never commit
history.jsonl
cache/
logs/
state/
telemetry/
session-env/
debug/
temp/
shell-snapshots/
paste-cache/
statsig/

# CRITICAL: Secrets - NEVER commit
.env
.credentials.json
api-keys.env
.passwords.json
settings.local.json

# Editor/OS
.DS_Store
Thumbs.db
*.swp
*~
"@
            $defaultGitignore | Out-File $gitignoreDest -Encoding UTF8
            Write-Log "  Created default .gitignore" "OK"
        }

        # Initialize git
        Push-Location $templateRoot
        try {
            $branch = $Config.git.defaultBranch
            if (-not $branch) { $branch = "main" }

            git init -b $branch 2>&1 | Out-Null
            git add -A 2>&1 | Out-Null
            git commit -m "Initial commit: $TemplateName template" 2>&1 | Out-Null

            Write-Log "  Repository initialized" "OK"
            Write-Log "  Branch: $branch" "INFO"
        } finally {
            Pop-Location
        }
    }

    "status" {
        $gitDir = Join-Path $templateRoot ".git"

        if (-not (Test-Path $gitDir)) {
            Write-Log "Not a git repository. Run: spawner repo init $TemplateName" "ERROR"
            exit 1
        }

        Push-Location $templateRoot
        try {
            Write-Log "" "INFO"

            # Branch info
            $branch = git branch --show-current 2>&1
            Write-Log "Branch: $branch" "INFO"

            # Last commit
            $lastCommit = git log -1 --format="%h %s (%ar)" 2>&1
            Write-Log "Last commit: $lastCommit" "INFO"

            # Status
            Write-Log "" "INFO"
            Write-Log "Status:" "STEP"
            $status = git status --short 2>&1
            if ($status) {
                $status | ForEach-Object { Write-Log "  $_" "INFO" }
            } else {
                Write-Log "  Working tree clean" "OK"
            }

            # Remote
            $remote = git remote -v 2>&1 | Select-Object -First 1
            if ($remote) {
                Write-Log "" "INFO"
                Write-Log "Remote: $remote" "INFO"
            }

        } finally {
            Pop-Location
        }
    }

    "commit" {
        $gitDir = Join-Path $templateRoot ".git"

        if (-not (Test-Path $gitDir)) {
            Write-Log "Not a git repository. Run: spawner repo init $TemplateName" "ERROR"
            exit 1
        }

        if (-not $Message) {
            $Message = "Update $TemplateName template - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }

        Push-Location $templateRoot
        try {
            # Check for changes
            $status = git status --porcelain 2>&1
            if (-not $status) {
                Write-Log "No changes to commit" "WARN"
                exit 0
            }

            Write-Log "Committing changes..." "STEP"

            # Stage all changes
            git add -A 2>&1 | Out-Null

            # Commit
            $commitResult = git commit -m $Message 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "  Committed: $Message" "OK"

                # Show commit hash
                $hash = git rev-parse --short HEAD 2>&1
                Write-Log "  Hash: $hash" "INFO"
            } else {
                Write-Log "  Commit failed: $commitResult" "ERROR"
                exit 1
            }

        } finally {
            Pop-Location
        }
    }
}

Write-Log "========================================" "OK"
Write-Log "  DONE" "OK"
Write-Log "========================================" "OK"
