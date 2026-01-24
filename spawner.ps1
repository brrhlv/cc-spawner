# spawner.ps1 - Spawner v3: Configuration Management and Sharing Platform
# Usage: .\spawner.ps1 <command> [target] [options]
#
# User Management Commands:
#   spawn <username>              Create ready-to-use user
#   respawn <username>            Recreate user fresh (or --cli for config only)
#   despawn <username>            Delete user
#   cospawn <username> --from <source>  Copy from another user
#   validate [template]           Validate templates (all or specific)
#
# Admin Management (v3):
#   backup                        Backup admin's .claude directory
#   restore <backup-path>         Restore admin from backup
#   upgrade [--from template|url] Upgrade admin config from template/git
#
# User Snapshots (v3):
#   snapshot <username>           Save user's complete state
#   export <username>             Export sanitized config for sharing
#   import <path> <username>      Import snapshot/export to user
#
# Template Syncing (v3):
#   promote <username> --as <name>  Save user's .claude as new template
#   sync <template> --to <users>    Push template to users
#   diff <source> <target>          Compare two configs
#
# Git Integration (v3):
#   repo init|status|commit <template>  Manage git for templates
#
# GitHub Sharing (v3):
#   publish <template> --repo <owner/repo>  Push template to GitHub
#   clone <github-url> <username>           Spawn from GitHub URL
#
# Decomposition (v3):
#   decompose <username>          Extract base/identity/project layers
#
# Examples:
#   .\spawner.ps1 spawn Lab4
#   .\spawner.ps1 spawn Lab4 --template pai-mod --identity developer
#   .\spawner.ps1 backup --output backups/admin
#   .\spawner.ps1 export Lab1 --output Lab1-share.zip
#   .\spawner.ps1 promote Lab1 --as my-template
#   .\spawner.ps1 publish my-template --repo brrhlv/my-template
#   .\spawner.ps1 clone https://github.com/user/template Lab5

param(
    [Parameter(Position=0)]
    [ValidateSet(
        # Existing commands
        "spawn", "respawn", "despawn", "cospawn", "validate", "help",
        # v3: Admin Management
        "backup", "restore", "upgrade",
        # v3: User Snapshots
        "snapshot", "export", "import",
        # v3: Template Syncing
        "promote", "sync", "diff",
        # v3: Git Integration
        "repo",
        # v3: GitHub Sharing
        "publish", "clone",
        # v3: Decomposition
        "decompose"
    )]
    [string]$Command = "help",

    [Parameter(Position=1)]
    [string]$Username,

    # Existing params
    [Alias("Base")]
    [string]$Template,
    [string]$Identity,
    [string]$Projects,
    [string]$Password,
    [string]$From,
    [switch]$Cli,
    [switch]$Full,
    [switch]$Force,
    [switch]$NoBackup,
    [switch]$Quiet,
    [switch]$Help,

    # v3 params
    [string]$Output,              # Output path for backup/snapshot/export
    [switch]$IncludeSecrets,      # Include secrets (dangerous, admin backup only)
    [switch]$Merge,               # Merge instead of replace on restore/import
    [string]$Preserve,            # Paths to preserve (comma-separated)
    [string]$As,                  # Template name for promote
    [string]$To,                  # Target users for sync (comma-separated)
    [switch]$Detailed,            # Detailed output for diff
    [string]$Repo,                # GitHub repo (owner/name)
    [switch]$Private,             # Private GitHub repo
    [string]$Message              # Commit message for repo command
)

$ErrorActionPreference = "Stop"
$SpawnerRoot = $PSScriptRoot
$ConfigPath = Join-Path $SpawnerRoot "config.json"
$PasswordsPath = Join-Path $SpawnerRoot ".passwords.json"
$ManifestPath = Join-Path $SpawnerRoot "manifest.json"
$DepsPath = Join-Path $SpawnerRoot "dependencies"
$LogsPath = Join-Path $SpawnerRoot "logs"
$BackupsPath = Join-Path $SpawnerRoot "backups"
$IdentitiesPath = Join-Path $SpawnerRoot "identities"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    if (-not $Quiet) {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN"  { "Yellow" }
            "OK"    { "Green" }
            "STEP"  { "Cyan" }
            default { "White" }
        }
        Write-Host $logLine -ForegroundColor $color
    }

    # Append to log file
    $logFile = Join-Path $LogsPath "spawner-$(Get-Date -Format 'yyyy-MM-dd').log"
    if (-not (Test-Path $LogsPath)) { New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null }
    Add-Content -Path $logFile -Value $logLine
}

function ConvertTo-SecureStringDirect {
    param([string]$PlainText)
    $secure = New-Object System.Security.SecureString
    foreach ($char in $PlainText.ToCharArray()) {
        $secure.AppendChar($char)
    }
    $secure.MakeReadOnly()
    return $secure
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "This command must be run as Administrator" "ERROR"
        exit 1
    }
}

function Get-Config {
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath -Raw | ConvertFrom-Json
    }
    Write-Log "Config file not found: $ConfigPath" "ERROR"
    exit 1
}

function Get-Passwords {
    if (Test-Path $PasswordsPath) {
        return Get-Content $PasswordsPath -Raw | ConvertFrom-Json
    }
    Write-Log "Passwords file not found: $PasswordsPath" "WARN"
    Write-Log "Create .passwords.json with category passwords" "WARN"
    # Return default structure
    return @{
        defaults = @{ password = "Spawn12345" }
        categories = @{}
    } | ConvertTo-Json | ConvertFrom-Json
}

function Test-UsernameValid {
    param([string]$Username)
    # Username must start with letter, contain only alphanumeric, underscore, hyphen
    # Max 20 characters
    if ($Username -match "^[a-zA-Z][a-zA-Z0-9_-]{0,19}$") {
        return $true
    }
    return $false
}

function Test-ApiKeyValid {
    param([string]$ApiKey)
    # Anthropic API keys start with sk-ant-api0X-
    if ($ApiKey -match "^sk-ant-api0[0-9]-[A-Za-z0-9_-]+$") {
        return $true
    }
    return $false
}

function Get-Manifest {
    if (Test-Path $ManifestPath) {
        return Get-Content $ManifestPath -Raw | ConvertFrom-Json
    }
    # Return empty manifest structure
    return @{
        version = "2.0"
        created = (Get-Date -Format "yyyy-MM-dd")
        updated = (Get-Date -Format "yyyy-MM-dd")
        users = @{}
    } | ConvertTo-Json | ConvertFrom-Json
}

function Save-Manifest {
    param($Manifest)
    $Manifest.updated = (Get-Date -Format "yyyy-MM-dd")
    $Manifest | ConvertTo-Json -Depth 10 | Out-File $ManifestPath -Encoding UTF8 -Force
}

function Get-CategoryFromUsername {
    param([string]$Username)
    switch -Regex ($Username) {
        "^Lab" { return "lab" }
        "^Dev" { return "dev" }
        default { return "lab" }
    }
}

function Get-PasswordForUser {
    param([string]$Username)
    $passwords = Get-Passwords
    $category = Get-CategoryFromUsername $Username
    if ($passwords.categories.$category) {
        return $passwords.categories.$category
    }
    return $passwords.defaults.password
}

# ============================================================================
# DEPENDENCIES MANAGEMENT (v4 - Native Claude Code + Python)
# ============================================================================

function Ensure-Dependencies {
    param($Config)

    $downloadedMarker = Join-Path $DepsPath ".downloaded-v4"

    if (Test-Path $downloadedMarker) {
        Write-Log "Dependencies already cached (v4)" "INFO"
        return $true
    }

    Write-Log "Downloading dependencies (first-time setup)..." "STEP"

    if (-not (Test-Path $DepsPath)) {
        New-Item -ItemType Directory -Path $DepsPath -Force | Out-Null
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Disable progress bar for faster downloads
    $ProgressPreference = 'SilentlyContinue'

    # === Download Claude Code Native Binary ===
    $claudeConfig = $Config.dependencies.claudeCode
    $claudeBaseUrl = $claudeConfig.baseUrl
    $claudePlatform = $claudeConfig.platform
    $claudeDepPath = Join-Path $DepsPath "claude-code"

    if (-not (Test-Path $claudeDepPath)) {
        New-Item -ItemType Directory -Path $claudeDepPath -Force | Out-Null
    }

    try {
        # Get latest version
        Write-Log "  Fetching Claude Code version..." "INFO"
        $versionUrl = "$claudeBaseUrl/latest"
        $claudeVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()
        Write-Log "  Latest version: $claudeVersion" "INFO"

        # Download binary
        $binaryUrl = "$claudeBaseUrl/$claudeVersion/$claudePlatform/claude.exe"
        $binaryPath = Join-Path $claudeDepPath "claude.exe"
        Write-Log "  Downloading Claude Code $claudeVersion..." "INFO"
        Invoke-WebRequest -Uri $binaryUrl -OutFile $binaryPath -UseBasicParsing

        # Download manifest for verification
        $manifestUrl = "$claudeBaseUrl/$claudeVersion/manifest.json"
        $manifestPath = Join-Path $claudeDepPath "manifest.json"
        Invoke-WebRequest -Uri $manifestUrl -OutFile $manifestPath -UseBasicParsing

        # Save version
        $claudeVersion | Out-File (Join-Path $claudeDepPath ".version") -Encoding UTF8

        Write-Log "  Claude Code cached successfully" "OK"
    } catch {
        Write-Log "Failed to download Claude Code: $($_.Exception.Message)" "ERROR"
        return $false
    }

    # === Download Python Embeddable ===
    $pythonConfig = $Config.dependencies.python
    $pythonVersion = $pythonConfig.version
    $pythonBaseUrl = $pythonConfig.baseUrl
    $pythonDepPath = Join-Path $DepsPath "python"

    if (-not (Test-Path $pythonDepPath)) {
        New-Item -ItemType Directory -Path $pythonDepPath -Force | Out-Null
    }

    try {
        # Download Python embeddable zip
        $pythonZipUrl = "$pythonBaseUrl/$pythonVersion/python-$pythonVersion-embed-amd64.zip"
        $pythonZipPath = Join-Path $pythonDepPath "python-embed.zip"
        Write-Log "  Downloading Python $pythonVersion embeddable..." "INFO"
        Invoke-WebRequest -Uri $pythonZipUrl -OutFile $pythonZipPath -UseBasicParsing

        # Download get-pip.py for pip installation
        $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
        $getPipPath = Join-Path $pythonDepPath "get-pip.py"
        Write-Log "  Downloading get-pip.py..." "INFO"
        Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing

        # Save version
        $pythonVersion | Out-File (Join-Path $pythonDepPath ".version") -Encoding UTF8

        Write-Log "  Python cached successfully" "OK"
    } catch {
        Write-Log "Failed to download Python: $($_.Exception.Message)" "ERROR"
        return $false
    }

    # Create marker file
    @"
downloaded=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
claude_version=$claudeVersion
python_version=$pythonVersion
"@ | Out-File $downloadedMarker -Encoding UTF8
    Write-Log "Dependencies cached successfully" "OK"
    return $true
}

function Install-PythonForUser {
    param(
        [string]$Username,
        [string]$UserHome,
        $Config
    )

    $pythonRoot = "$UserHome\.python"
    $pythonVersion = $Config.dependencies.python.version

    Write-Log "Installing portable Python for $Username..." "STEP"

    try {
        # Remove existing and recreate clean
        if (Test-Path $pythonRoot) { Remove-Item $pythonRoot -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $pythonRoot -Force | Out-Null

        # Extract Python embeddable
        $pythonZipPath = Join-Path $DepsPath "python\python-embed.zip"
        Write-Log "  Extracting Python $pythonVersion..." "INFO"
        Expand-Archive -Path $pythonZipPath -DestinationPath $pythonRoot -Force

        # Enable site-packages by modifying python*._pth file
        $pthFile = Get-ChildItem $pythonRoot -Filter "python*._pth" | Select-Object -First 1
        if ($pthFile) {
            $pthContent = Get-Content $pthFile.FullName
            # Uncomment 'import site' line to enable pip
            $pthContent = $pthContent -replace '^#import site', 'import site'
            # Add Lib\site-packages
            $pthContent += "`nLib\site-packages"
            $pthContent | Out-File $pthFile.FullName -Encoding ASCII -Force
        }

        # Create Lib\site-packages directory
        $sitePackages = Join-Path $pythonRoot "Lib\site-packages"
        New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null

        # Install pip
        $getPipPath = Join-Path $DepsPath "python\get-pip.py"
        $pythonExe = Join-Path $pythonRoot "python.exe"
        Write-Log "  Installing pip..." "INFO"
        $result = Start-Process -FilePath $pythonExe -ArgumentList "`"$getPipPath`" --no-warn-script-location" -Wait -PassThru -NoNewWindow
        if ($result.ExitCode -ne 0) {
            Write-Log "  pip installation returned code $($result.ExitCode)" "WARN"
        }

        # Create Scripts directory if it doesn't exist (pip should create it)
        $scriptsPath = Join-Path $pythonRoot "Scripts"
        if (-not (Test-Path $scriptsPath)) {
            New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
        }

        Write-Log "  Python installed at $pythonRoot" "OK"
        return $true
    } catch {
        Write-Log "  Failed to install Python: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Legacy function for templates that still need Node.js (e.g., pai-vanilla)
function Install-NodeForUser {
    param(
        [string]$Username,
        [string]$UserHome,
        $Config
    )

    Write-Log "Node.js installation skipped (legacy templates only)" "WARN"
    Write-Log "  Use --template pai-vanilla for TypeScript hooks" "INFO"
    return $false
}

function Install-ClaudeNativeForUser {
    param(
        [string]$Username,
        [string]$UserHome,
        $Config
    )

    # Native Claude Code installation paths
    $localBinPath = "$UserHome\.local\bin"
    $localSharePath = "$UserHome\.local\share\claude"

    Write-Log "Installing Claude Code (native)..." "STEP"

    try {
        # Create .local directories
        New-Item -ItemType Directory -Path $localBinPath -Force | Out-Null
        New-Item -ItemType Directory -Path $localSharePath -Force | Out-Null

        # Copy cached binary
        $cachedBinary = Join-Path $DepsPath "claude-code\claude.exe"
        $targetBinary = Join-Path $localBinPath "claude.exe"

        if (-not (Test-Path $cachedBinary)) {
            throw "Cached Claude binary not found at $cachedBinary"
        }

        Write-Log "  Copying Claude Code binary..." "INFO"
        Copy-Item $cachedBinary -Destination $targetBinary -Force

        # Copy version info
        $cachedVersion = Join-Path $DepsPath "claude-code\.version"
        if (Test-Path $cachedVersion) {
            $version = Get-Content $cachedVersion
            $version | Out-File (Join-Path $localSharePath "version") -Encoding UTF8 -Force
        }

        # Verify installation
        if (Test-Path $targetBinary) {
            Write-Log "  Claude Code installed at $localBinPath" "OK"
            return $true
        } else {
            Write-Log "  Claude Code binary not found after copy" "WARN"
            return $false
        }
    } catch {
        Write-Log "Failed to install Claude Code: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Legacy function for npm-based installation (deprecated)
function Install-ClaudeCliForUser {
    param(
        [string]$Username,
        [string]$UserHome,
        $Config
    )

    Write-Log "npm-based installation deprecated - use Install-ClaudeNativeForUser" "WARN"
    return $false
}

function Set-UserOwnership {
    param(
        [string]$Username,
        [string]$UserHome
    )

    # Set ownership on specific directories only (avoid recursive symlink loops)
    $dirsToOwn = @(
        "$UserHome\.claude",
        "$UserHome\.local",
        "$UserHome\.python",
        "$UserHome\projects",
        "$UserHome\.gitconfig"
    )

    foreach ($path in $dirsToOwn) {
        if (Test-Path $path) {
            # Use /T for directories, skip for files
            if (Test-Path $path -PathType Container) {
                icacls $path /setowner $Username /T /C 2>&1 | Out-Null
                icacls $path /grant "${Username}:(OI)(CI)F" /T /C 2>&1 | Out-Null
            } else {
                icacls $path /setowner $Username /C 2>&1 | Out-Null
                icacls $path /grant "${Username}:F" /C 2>&1 | Out-Null
            }
        }
    }
}

# ============================================================================
# SPAWN COMMAND
# ============================================================================

function Invoke-Spawn {
    param(
        [string]$Username,
        [string]$Template,
        [string]$Identity,
        [string]$Projects,
        [string]$Password
    )

    Test-AdminPrivileges

    if (-not $Username) {
        Write-Log "Username required. Usage: spawner spawn <username>" "ERROR"
        exit 1
    }

    # Validate username format
    if (-not (Test-UsernameValid $Username)) {
        Write-Log "Invalid username format. Must start with letter, alphanumeric/underscore/hyphen only, max 20 chars." "ERROR"
        exit 1
    }

    $config = Get-Config
    $manifest = Get-Manifest

    # Check if user already exists
    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Log "User '$Username' already exists. Use 'respawn' to recreate." "ERROR"
        exit 1
    }

    # Set defaults
    if (-not $Template) { $Template = $config.defaults.template }
    if (-not $Password) { $Password = Get-PasswordForUser $Username }
    $category = Get-CategoryFromUsername $Username

    Write-Log "========================================" "STEP"
    Write-Log "  SPAWN: $Username" "STEP"
    Write-Log "  Base: $Template" "STEP"
    if ($Identity) { Write-Log "  Identity: $Identity" "STEP" }
    if ($Projects) { Write-Log "  Projects: $Projects" "STEP" }
    Write-Log "  Category: $category" "STEP"
    Write-Log "========================================" "STEP"

    # Ensure dependencies are cached
    if (-not (Ensure-Dependencies $config)) {
        Write-Log "Failed to ensure dependencies" "ERROR"
        exit 1
    }

    $UserHome = "C:\Users\$Username"
    $rollbackNeeded = $false

    try {
        # 1. Create Windows user
        Write-Log "Creating Windows user account..." "STEP"
        $SecurePassword = ConvertTo-SecureStringDirect $Password
        New-LocalUser -Name $Username -Password $SecurePassword -Description "Spawner: $category/$Template" -PasswordNeverExpires | Out-Null
        Add-LocalGroupMember -Group "Users" -Member $Username -ErrorAction SilentlyContinue
        $rollbackNeeded = $true
        Write-Log "  User account created" "OK"

        # 2. Create user profile
        Write-Log "Creating user profile..." "STEP"
        $Credential = New-Object PSCredential($Username, $SecurePassword)

        # Trigger profile creation by running a process as the user
        $profileCreated = $false
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo init" `
                    -Credential $Credential -PassThru -WindowStyle Hidden -Wait -ErrorAction Stop
                Start-Sleep -Seconds 2
                if (Test-Path $UserHome) {
                    $profileCreated = $true
                    break
                }
            } catch {
                Start-Sleep -Seconds 1
            }
        }

        if (-not $profileCreated) {
            # Manual profile creation fallback
            New-Item -ItemType Directory -Path $UserHome -Force | Out-Null
            $defaultDirs = @("AppData", "AppData\Local", "AppData\Roaming", "Desktop", "Documents", "Downloads")
            foreach ($dir in $defaultDirs) {
                New-Item -ItemType Directory -Path "$UserHome\$dir" -Force | Out-Null
            }
        }
        Write-Log "  Profile created: $UserHome" "OK"

        # 3. Create directory structure
        Write-Log "Creating directory structure..." "STEP"
        $dirs = @("$UserHome\.claude", "$UserHome\projects", "$UserHome\.local\bin", "$UserHome\.local\share")
        foreach ($dir in $dirs) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Write-Log "  Directories created" "OK"

        # 4. Install Claude Code (native binary)
        $claudeInstalled = Install-ClaudeNativeForUser $Username $UserHome $config
        if (-not $claudeInstalled) {
            Write-Log "Claude Code installation failed - continuing anyway" "WARN"
        }

        # 5. Install Python (if template requires it)
        $pythonInstalled = $false
        $templateConfig = $config.templates.$Template
        if ($templateConfig.requiresPython -eq $true) {
            $pythonInstalled = Install-PythonForUser $Username $UserHome $config
            if (-not $pythonInstalled) {
                Write-Log "Python installation failed - hooks may not work" "WARN"
            }
        } else {
            Write-Log "Skipping Python (template doesn't require it)" "INFO"
        }

        # 6. Validate and copy template
        Write-Log "Validating template: $Template..." "STEP"
        $templatePath = Join-Path $SpawnerRoot $config.templates.$Template.path
        $templateRoot = Split-Path $templatePath -Parent

        # Run template validation (auto-fix issues)
        $validateScript = Join-Path $SpawnerRoot "lib\Validate-Template.ps1"
        if (Test-Path $validateScript) {
            & $validateScript -TemplatePath $templateRoot -Fix -ShowDetails:$false
            Write-Log "  Template validated" "OK"
        }

        Write-Log "Copying template: $Template..." "STEP"
        if (Test-Path $templatePath) {
            $robocopyArgs = @($templatePath, "$UserHome\.claude", "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
            if ($result.ExitCode -le 7) {
                Write-Log "  Template copied" "OK"
            }
        } else {
            Write-Log "  Template not found: $templatePath" "WARN"
        }

        # 6.25. Copy projects scaffold from template (if exists)
        $projectsScaffold = Join-Path $templateRoot "projects"
        if (Test-Path $projectsScaffold) {
            Write-Log "Copying projects scaffold..." "STEP"
            $robocopyArgs = @($projectsScaffold, "$UserHome\projects", "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
            if ($result.ExitCode -le 7) {
                Write-Log "  Projects scaffold created" "OK"
            }
        }

        # 6.5. Merge identity (if specified)
        if ($Identity) {
            Write-Log "Merging identity: $Identity..." "STEP"
            $identityPath = Join-Path $IdentitiesPath $Identity

            if (Test-Path $identityPath) {
                $mergeScript = Join-Path $SpawnerRoot "lib\Merge-Identity.ps1"
                if (Test-Path $mergeScript) {
                    $result = & $mergeScript -UserPath "$UserHome\.claude" -IdentityPath $identityPath -ShowDetails
                    if ($result.Merged.Count -gt 0) {
                        Write-Log "  Merged: $($result.Merged -join ', ')" "OK"
                    }
                    if ($result.Warnings.Count -gt 0) {
                        foreach ($warn in $result.Warnings) {
                            Write-Log "  $warn" "WARN"
                        }
                    }
                } else {
                    Write-Log "  Merge script not found" "WARN"
                }
            } else {
                Write-Log "  Identity not found: $identityPath" "WARN"
                Write-Log "  Available: $((Get-ChildItem $IdentitiesPath -Directory).Name -join ', ')" "INFO"
            }
        }

        # 6.6. Copy projects (if specified)
        if ($Projects) {
            Write-Log "Copying projects: $Projects..." "STEP"
            $projectsList = $Projects -split ","

            foreach ($projName in $projectsList) {
                $projName = $projName.Trim()
                $projSource = $config.projects.$projName

                if ($projSource) {
                    if (Test-Path $projSource) {
                        $projDest = Join-Path "$UserHome\projects" $projName

                        Write-Log "  Copying $projName..." "INFO"
                        $robocopyArgs = @($projSource, $projDest, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/XD", ".git", "node_modules", ".next", "dist", "build")
                        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

                        if ($result.ExitCode -le 7) {
                            # Initialize fresh git repo
                            Push-Location $projDest
                            git init -q 2>&1 | Out-Null
                            Pop-Location
                            Write-Log "  Copied: $projName (git initialized)" "OK"
                        } else {
                            Write-Log "  Failed to copy: $projName" "WARN"
                        }
                    } else {
                        Write-Log "  Project source not found: $projSource" "WARN"
                    }
                } else {
                    Write-Log "  Project not in registry: $projName" "WARN"
                    Write-Log "  Available: $($config.projects.PSObject.Properties.Name -join ', ')" "INFO"
                }
            }
        }

        # 7. Configure git
        Write-Log "Configuring Git..." "STEP"
        $gitConfig = @"
[user]
    name = $Username
    email = $Username@local.spawner
[init]
    defaultBranch = main
"@
        $gitConfig | Out-File "$UserHome\.gitconfig" -Encoding UTF8 -Force
        Write-Log "  Git configured" "OK"

        # 8. Copy API key
        Write-Log "Setting up API key..." "STEP"
        $apiKeyFile = Join-Path $SpawnerRoot "_config\api-keys.env"
        if (Test-Path $apiKeyFile) {
            $keyLine = Get-Content $apiKeyFile | Where-Object { $_ -match "^ANTHROPIC_API_KEY=" }
            if ($keyLine) {
                # Validate API key format
                $apiKey = ($keyLine -split "=", 2)[1].Trim()
                if (Test-ApiKeyValid $apiKey) {
                    $keyLine | Out-File "$UserHome\.claude\.env" -Encoding UTF8 -Force
                    Write-Log "  API key configured (validated)" "OK"
                } else {
                    Write-Log "  API key format invalid (expected sk-ant-api0X-...)" "WARN"
                    $keyLine | Out-File "$UserHome\.claude\.env" -Encoding UTF8 -Force
                    Write-Log "  API key copied anyway (may not work)" "WARN"
                }
            }
        } else {
            Write-Log "  No API key file found (create _config/api-keys.env)" "WARN"
        }

        # 9. Set ownership
        Write-Log "Setting file ownership..." "STEP"
        Set-UserOwnership $Username $UserHome
        Write-Log "  Ownership set" "OK"

        # 9.5. Set user environment variables (isolate from global config)
        Write-Log "Setting environment variables..." "STEP"
        try {
            # Get user SID
            $userSid = (Get-LocalUser -Name $Username | Select-Object -ExpandProperty SID).Value

            # Load user registry hive if not loaded
            $hivePath = "$UserHome\NTUSER.DAT"
            $hiveLoaded = $false
            if (Test-Path $hivePath) {
                reg load "HKU\$userSid" $hivePath 2>&1 | Out-Null
                $hiveLoaded = $true
            }

            # Set environment variables
            $envPath = "Registry::HKEY_USERS\$userSid\Environment"
            if (-not (Test-Path $envPath)) {
                New-Item -Path $envPath -Force | Out-Null
            }

            # CLAUDE_CONFIG_DIR - user's .claude directory
            Set-ItemProperty -Path $envPath -Name "CLAUDE_CONFIG_DIR" -Value "$UserHome\.claude" -Type String

            # PATH - add .local\bin for Claude Code and .python for Python
            $currentPath = ""
            try {
                $currentPath = (Get-ItemProperty -Path $envPath -Name "Path" -ErrorAction SilentlyContinue).Path
            } catch { }

            $pathsToAdd = @("$UserHome\.local\bin")
            if ($pythonInstalled) {
                $pathsToAdd += "$UserHome\.python"
                $pathsToAdd += "$UserHome\.python\Scripts"
            }

            foreach ($addPath in $pathsToAdd) {
                if ($currentPath -notlike "*$addPath*") {
                    if ($currentPath) {
                        $currentPath = "$addPath;$currentPath"
                    } else {
                        $currentPath = $addPath
                    }
                }
            }
            Set-ItemProperty -Path $envPath -Name "Path" -Value $currentPath -Type ExpandString

            # Unload hive if we loaded it
            if ($hiveLoaded) {
                [gc]::Collect()
                Start-Sleep -Milliseconds 500
                reg unload "HKU\$userSid" 2>&1 | Out-Null
            }

            Write-Log "  CLAUDE_CONFIG_DIR set to $UserHome\.claude" "OK"
            Write-Log "  PATH updated with .local\bin" "OK"
        } catch {
            Write-Log "  Failed to set env vars: $($_.Exception.Message)" "WARN"
        }

        # 10. Save credentials for runas
        Write-Log "Saving credentials..." "STEP"
        cmdkey /add:$Username /user:$Username /pass:$Password 2>&1 | Out-Null
        Write-Log "  Credentials saved" "OK"

        # 11. Update manifest
        Write-Log "Updating manifest..." "STEP"
        $userEntry = @{
            category = $category
            template = $Template
            identity = if ($Identity) { $Identity } else { $null }
            projects = if ($Projects) { $Projects } else { $null }
            created = (Get-Date -Format "yyyy-MM-dd")
            home = $UserHome
            status = "active"
            installMethod = "native"  # v4: native installer
            claudeInstalled = $claudeInstalled
            pythonInstalled = $pythonInstalled
        }

        if ($manifest.users -is [PSCustomObject]) {
            $manifest.users | Add-Member -NotePropertyName $Username -NotePropertyValue $userEntry -Force
        } else {
            $manifest.users = @{ $Username = $userEntry }
        }
        Save-Manifest $manifest
        Write-Log "  Manifest updated" "OK"

        # 12. Generate spawn README
        Write-Log "Generating spawn README..." "STEP"
        $readmeScript = Join-Path $SpawnerRoot "lib\Generate-SpawnReadme.ps1"
        if (Test-Path $readmeScript) {
            $readmePath = & $readmeScript -UserPath "$UserHome\.claude" -Username $Username -Template $Template -Identity $Identity -Projects $Projects -SpawnerRoot $SpawnerRoot
            Write-Log "  Created: SPAWN-README.md" "OK"
        }

        # Success
        Write-Log "========================================" "OK"
        Write-Log "  SUCCESS: $Username is ready!" "OK"
        Write-Log "========================================" "OK"
        Write-Log "" "INFO"
        Write-Log "Switch to user:" "INFO"
        Write-Log "  runas /user:$Username cmd" "INFO"
        Write-Log "  Then run: claude" "INFO"

    } catch {
        Write-Log "SPAWN FAILED: $($_.Exception.Message)" "ERROR"

        if ($rollbackNeeded) {
            Write-Log "Rolling back..." "WARN"
            Remove-LocalUser -Name $Username -ErrorAction SilentlyContinue
        }
        exit 1
    }
}

# ============================================================================
# RESPAWN COMMAND
# ============================================================================

function Invoke-Respawn {
    param(
        [string]$Username,
        [switch]$CliOnly,
        [string]$Template
    )

    Test-AdminPrivileges

    if (-not $Username) {
        Write-Log "Username required. Usage: spawner respawn <username>" "ERROR"
        exit 1
    }

    $config = Get-Config
    $manifest = Get-Manifest
    $UserHome = "C:\Users\$Username"

    # Check if user exists
    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        Write-Log "User '$Username' does not exist" "ERROR"
        exit 1
    }

    if ($CliOnly) {
        # Just reset .claude directory
        Write-Log "========================================" "STEP"
        Write-Log "  RESPAWN (CLI only): $Username" "STEP"
        Write-Log "========================================" "STEP"

        # Backup existing .claude if configured
        if ($config.despawn.backup -and -not $NoBackup) {
            $backupDir = Join-Path $BackupsPath "$Username-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            if (Test-Path "$UserHome\.claude") {
                Write-Log "Backing up .claude..." "STEP"
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                Copy-Item "$UserHome\.claude" -Destination "$backupDir\.claude" -Recurse -Force
                Write-Log "  Backed up to $backupDir" "OK"
            }
        }

        # Delete .claude
        Write-Log "Removing .claude directory..." "STEP"
        if (Test-Path "$UserHome\.claude") {
            Remove-Item "$UserHome\.claude" -Recurse -Force
        }

        # Copy fresh template
        if (-not $Template) {
            # Get from manifest or default
            if ($manifest.users.$Username -and $manifest.users.$Username.template) {
                $Template = $manifest.users.$Username.template
            } else {
                $Template = $config.defaults.template
            }
        }

        # Validate template before copying
        Write-Log "Validating template: $Template..." "STEP"
        $templatePath = Join-Path $SpawnerRoot $config.templates.$Template.path
        $templateRoot = Split-Path $templatePath -Parent
        $validateScript = Join-Path $SpawnerRoot "lib\Validate-Template.ps1"
        if (Test-Path $validateScript) {
            & $validateScript -TemplatePath $templateRoot -Fix -ShowDetails:$false
        }

        Write-Log "Copying template: $Template..." "STEP"
        New-Item -ItemType Directory -Path "$UserHome\.claude" -Force | Out-Null
        if (Test-Path $templatePath) {
            $robocopyArgs = @($templatePath, "$UserHome\.claude", "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
            Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow | Out-Null
        }

        # Restore API key
        $apiKeyFile = Join-Path $SpawnerRoot "_config\api-keys.env"
        if (Test-Path $apiKeyFile) {
            $keyLine = Get-Content $apiKeyFile | Where-Object { $_ -match "^ANTHROPIC_API_KEY=" }
            if ($keyLine) {
                $keyLine | Out-File "$UserHome\.claude\.env" -Encoding UTF8 -Force
            }
        }

        # Set ownership
        Set-UserOwnership $Username "$UserHome\.claude"

        Write-Log "  .claude reset complete" "OK"

    } else {
        # Full respawn - delete and recreate
        Write-Log "========================================" "STEP"
        Write-Log "  RESPAWN (full): $Username" "STEP"
        Write-Log "========================================" "STEP"

        # Get current settings before despawn
        $currentTemplate = $Template
        if (-not $currentTemplate -and $manifest.users.$Username) {
            $currentTemplate = $manifest.users.$Username.template
        }
        if (-not $currentTemplate) { $currentTemplate = $config.defaults.template }

        $currentPassword = Get-PasswordForUser $Username

        # Despawn
        Invoke-Despawn -Username $Username -SkipConfirm

        # Spawn fresh
        Invoke-Spawn -Username $Username -Template $currentTemplate -Password $currentPassword
    }
}

# ============================================================================
# DESPAWN COMMAND
# ============================================================================

function Invoke-Despawn {
    param(
        [string]$Username,
        [switch]$SkipConfirm
    )

    Test-AdminPrivileges

    if (-not $Username) {
        Write-Log "Username required. Usage: spawner despawn <username>" "ERROR"
        exit 1
    }

    $config = Get-Config
    $manifest = Get-Manifest
    $UserHome = "C:\Users\$Username"

    # Check if user exists
    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if (-not $existingUser) {
        Write-Log "User '$Username' does not exist" "ERROR"
        exit 1
    }

    Write-Log "========================================" "STEP"
    Write-Log "  DESPAWN: $Username" "STEP"
    Write-Log "========================================" "STEP"

    # Confirm unless forced or called internally
    if ($config.despawn.confirm -and -not $Force -and -not $SkipConfirm) {
        $response = Read-Host "Delete user '$Username' and all data? (yes/no)"
        if ($response -ne "yes") {
            Write-Log "Aborted" "WARN"
            exit 0
        }
    }

    # Backup if configured
    if ($config.despawn.backup -and -not $NoBackup) {
        $backupDir = Join-Path $BackupsPath "$Username-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if (Test-Path $UserHome) {
            Write-Log "Backing up user data..." "STEP"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

            # Copy important directories
            $dirsToBackup = @(".claude", "projects", ".gitconfig")
            foreach ($dir in $dirsToBackup) {
                $src = Join-Path $UserHome $dir
                if (Test-Path $src) {
                    Copy-Item $src -Destination $backupDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            Write-Log "  Backed up to $backupDir" "OK"
        }
    }

    # Kill any processes running as this user (use taskkill for speed)
    Write-Log "Terminating user processes..." "STEP"
    try {
        # Fast approach: use taskkill with /FI filter
        $result = & taskkill /F /FI "USERNAME eq $Username" 2>&1
        # taskkill returns error if no processes found, which is fine
    } catch {}
    Start-Sleep -Seconds 1
    Write-Log "  Processes terminated" "OK"

    # Remove saved credentials
    Write-Log "Removing saved credentials..." "STEP"
    cmdkey /delete:$Username 2>&1 | Out-Null
    Write-Log "  Credentials removed" "OK"

    # Delete Windows user
    Write-Log "Deleting Windows user..." "STEP"
    Remove-LocalUser -Name $Username -ErrorAction SilentlyContinue
    Write-Log "  User deleted" "OK"

    # Delete home directory
    Write-Log "Deleting home directory..." "STEP"
    if (Test-Path $UserHome) {
        # Use cmd /c rd for reliable deletion (handles junctions/symlinks properly)
        $result = & cmd /c "rd /s /q `"$UserHome`"" 2>&1
        # If rd fails, try takeown without /R (skip recursive to avoid symlink loops)
        if (Test-Path $UserHome) {
            takeown /F $UserHome /D Y 2>&1 | Out-Null
            # Grant permissions on top-level only, then delete
            icacls $UserHome /grant Administrators:F /C 2>&1 | Out-Null
            Remove-Item $UserHome -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "  Home directory deleted" "OK"

    # Remove from manifest
    Write-Log "Updating manifest..." "STEP"
    if ($manifest.users.$Username) {
        $manifest.users.PSObject.Properties.Remove($Username)
        Save-Manifest $manifest
    }
    Write-Log "  Manifest updated" "OK"

    Write-Log "========================================" "OK"
    Write-Log "  DESPAWN complete: $Username" "OK"
    Write-Log "========================================" "OK"
}

# ============================================================================
# COSPAWN COMMAND
# ============================================================================

function Invoke-Cospawn {
    param(
        [string]$Username,
        [string]$SourceUser,
        [switch]$FullProfile
    )

    Test-AdminPrivileges

    if (-not $Username) {
        Write-Log "Username required. Usage: spawner cospawn <username> --from <source>" "ERROR"
        exit 1
    }

    if (-not $SourceUser) {
        Write-Log "Source user required. Usage: spawner cospawn <username> --from <source>" "ERROR"
        exit 1
    }

    $config = Get-Config
    $SourceHome = "C:\Users\$SourceUser"
    $UserHome = "C:\Users\$Username"

    # Check source exists
    if (-not (Test-Path $SourceHome)) {
        Write-Log "Source user home not found: $SourceHome" "ERROR"
        exit 1
    }

    Write-Log "========================================" "STEP"
    Write-Log "  COSPAWN: $Username from $SourceUser" "STEP"
    Write-Log "========================================" "STEP"

    # Spawn the new user with vanilla template
    Invoke-Spawn -Username $Username -Template "vanilla"

    # Now copy from source
    if ($FullProfile) {
        Write-Log "Copying full profile from $SourceUser..." "STEP"
        $dirsToSync = @(".claude", "projects", ".gitconfig", ".npmrc")
    } else {
        Write-Log "Copying .claude from $SourceUser..." "STEP"
        $dirsToSync = @(".claude")
    }

    foreach ($item in $dirsToSync) {
        $src = Join-Path $SourceHome $item
        $dst = Join-Path $UserHome $item

        if (Test-Path $src) {
            # Remove existing
            if (Test-Path $dst) {
                Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Copy
            if (Test-Path $src -PathType Container) {
                $robocopyArgs = @($src, $dst, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
                Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow | Out-Null
            } else {
                Copy-Item $src -Destination $dst -Force
            }
            Write-Log "  Copied: $item" "OK"
        }
    }

    # Set ownership
    Set-UserOwnership $Username $UserHome

    # Update manifest with source info
    $manifest = Get-Manifest
    if ($manifest.users.$Username) {
        $manifest.users.$Username | Add-Member -NotePropertyName "copiedFrom" -NotePropertyValue $SourceUser -Force
        Save-Manifest $manifest
    }

    Write-Log "========================================" "OK"
    Write-Log "  COSPAWN complete: $Username" "OK"
    Write-Log "========================================" "OK"
}

# ============================================================================
# HELP
# ============================================================================

function Show-Help {
    Write-Host @"

Spawner v3 - Configuration Management and Sharing Platform

USAGE:
    spawner <command> [target] [options]

USER MANAGEMENT:
    spawn <username>     Create ready-to-use user environment
    respawn <username>   Recreate user (full) or reset config (--cli)
    despawn <username>   Delete user and all data
    cospawn <username>   Copy environment from another user
    validate [template]  Validate templates

ADMIN MANAGEMENT (v3):
    backup               Backup admin's .claude directory
    restore <path>       Restore admin from backup
    upgrade              Upgrade admin from template or git URL

USER SNAPSHOTS (v3):
    snapshot <username>  Save user's complete state
    export <username>    Export sanitized config for sharing
    import <path> <user> Import snapshot/export to user

TEMPLATE SYNCING (v3):
    promote <user>       Save user's .claude as new template (--as <name>)
    sync <template>      Push/pull between template and users
    diff <source> <tgt>  Compare two configs

GIT INTEGRATION (v3):
    repo <action> <tpl>  init|status|commit for templates

GITHUB SHARING (v3):
    publish <template>   Push template to GitHub (--repo <owner/name>)
    clone <url> <user>   Spawn from GitHub URL

DECOMPOSITION (v3):
    decompose <username> Extract base/identity/project layers

BASE TEMPLATES:
    cc-vanilla           Stock Claude Code (no PAI)
    pai-vanilla          Minimal PAI skeleton
    pai-mod              PAI with hooks framework

IDENTITIES:
    developer            Code quality, TDD, API design
    researcher           Search and summarize
    learner              Education and tutoring
    auditor              Security review (read-only)

OPTIONS:
    --base <name>        Base template (alias: --template)
    --identity <name>    Apply identity overlay
    --projects <list>    Copy projects (comma-separated)
    --password <pass>    Override default password
    --from <user>        Source user for cospawn/sync
    --cli                Respawn: only reset .claude directory
    --full               Cospawn: copy full profile
    --force              Skip confirmation prompts
    --no-backup          Skip automatic backups
    --quiet              Suppress output (logs only)

    # v3 options
    --output <path>      Output path for backup/snapshot/export
    --include-secrets    Include secrets in backup (admin only, dangerous)
    --merge              Merge instead of replace on restore/import
    --preserve <paths>   Paths to preserve (comma-separated)
    --as <name>          Template name for promote
    --to <users>         Target users for sync (comma-separated)
    --detailed           Detailed output for diff
    --repo <owner/name>  GitHub repo for publish
    --private            Make GitHub repo private
    --message <msg>      Commit message for repo command

EXAMPLES:
    spawner spawn Lab1 --base cc-vanilla
    spawner spawn Lab2 --base pai-mod --identity developer
    spawner backup --output backups/admin/my-backup
    spawner restore backups/admin/2026-01-23 --merge
    spawner snapshot Lab1
    spawner export Lab1 --output Lab1-share.zip
    spawner import Lab1-share.zip Lab2
    spawner promote Lab1 --as my-template
    spawner sync pai-mod --to Lab1,Lab2
    spawner diff Lab1 pai-mod --detailed
    spawner repo init my-template
    spawner publish my-template --repo brrhlv/my-template --private
    spawner clone https://github.com/user/template Lab5
    spawner decompose Lab1

"@ -ForegroundColor Cyan
}

# ============================================================================
# VALIDATE TEMPLATES
# ============================================================================

function Invoke-ValidateTemplates {
    param(
        [string]$TemplateName,
        [switch]$AutoFix
    )

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $validateScript = Join-Path $SpawnerRoot "lib\Validate-Template.ps1"

    if (-not (Test-Path $validateScript)) {
        Write-Log "Validation script not found: $validateScript" "ERROR"
        return
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  TEMPLATE VALIDATION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $templates = @()
    if ($TemplateName) {
        if ($config.templates.$TemplateName) {
            $templates += @{ Name = $TemplateName; Config = $config.templates.$TemplateName }
        } else {
            Write-Host "Template not found: $TemplateName" -ForegroundColor Red
            Write-Host "Available templates: $($config.templates.PSObject.Properties.Name -join ', ')" -ForegroundColor Yellow
            return
        }
    } else {
        foreach ($t in $config.templates.PSObject.Properties) {
            $templates += @{ Name = $t.Name; Config = $t.Value }
        }
    }

    $results = @()
    foreach ($t in $templates) {
        $templatePath = Join-Path $SpawnerRoot $t.Config.path
        $templateRoot = Split-Path $templatePath -Parent

        Write-Host "Validating: $($t.Name)" -ForegroundColor White
        Write-Host "  Path: $templateRoot" -ForegroundColor Gray

        if ($AutoFix) {
            & $validateScript -TemplatePath $templateRoot -Fix -ShowDetails
        } else {
            & $validateScript -TemplatePath $templateRoot -ShowDetails
        }

        $results += @{
            Name = $t.Name
            ExitCode = $LASTEXITCODE
        }
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $passed = ($results | Where-Object { $_.ExitCode -eq 0 }).Count
    $failed = ($results | Where-Object { $_.ExitCode -ne 0 }).Count

    foreach ($r in $results) {
        $status = if ($r.ExitCode -eq 0) { "[OK]" } else { "[FAIL]" }
        $color = if ($r.ExitCode -eq 0) { "Green" } else { "Red" }
        Write-Host "  $status $($r.Name)" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Passed: $passed / $($results.Count)" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })

    if ($failed -gt 0 -and -not $AutoFix) {
        Write-Host ""
        Write-Host "Run with --force to auto-fix issues" -ForegroundColor Yellow
    }
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Command) {
    # ===== Existing Commands =====
    "spawn" {
        Invoke-Spawn -Username $Username -Template $Template -Identity $Identity -Projects $Projects -Password $Password
    }
    "respawn" {
        Invoke-Respawn -Username $Username -CliOnly:$Cli -Template $Template
    }
    "despawn" {
        Invoke-Despawn -Username $Username
    }
    "cospawn" {
        Invoke-Cospawn -Username $Username -SourceUser $From -FullProfile:$Full
    }
    "validate" {
        Invoke-ValidateTemplates -TemplateName $Username -AutoFix:$Force
    }

    # ===== v3: Admin Management =====
    "backup" {
        $script = Join-Path $SpawnerRoot "lib\Admin-Backup.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Output $Output -IncludeSecrets:$IncludeSecrets
        } else {
            Write-Log "Admin-Backup.ps1 not found" "ERROR"
        }
    }
    "restore" {
        $script = Join-Path $SpawnerRoot "lib\Admin-Restore.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -BackupPath $Username -Merge:$Merge -Force:$Force
        } else {
            Write-Log "Admin-Restore.ps1 not found" "ERROR"
        }
    }
    "upgrade" {
        $script = Join-Path $SpawnerRoot "lib\Admin-Upgrade.ps1"
        if (Test-Path $script) {
            $preserveList = if ($Preserve) { $Preserve -split "," } else { @() }
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -From $From -Preserve $preserveList
        } else {
            Write-Log "Admin-Upgrade.ps1 not found" "ERROR"
        }
    }

    # ===== v3: User Snapshots =====
    "snapshot" {
        $script = Join-Path $SpawnerRoot "lib\User-Snapshot.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Username $Username -Output $Output -Full:$Full
        } else {
            Write-Log "User-Snapshot.ps1 not found" "ERROR"
        }
    }
    "export" {
        $script = Join-Path $SpawnerRoot "lib\User-Export.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Username $Username -Output $Output
        } else {
            Write-Log "User-Export.ps1 not found" "ERROR"
        }
    }
    "import" {
        $script = Join-Path $SpawnerRoot "lib\User-Import.ps1"
        if (Test-Path $script) {
            # Username is the path, Template is the target user
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -ImportPath $Username -TargetUser $Template -Merge:$Merge
        } else {
            Write-Log "User-Import.ps1 not found" "ERROR"
        }
    }

    # ===== v3: Template Syncing =====
    "promote" {
        $script = Join-Path $SpawnerRoot "lib\Template-Promote.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Username $Username -TemplateName $As
        } else {
            Write-Log "Template-Promote.ps1 not found" "ERROR"
        }
    }
    "sync" {
        $script = Join-Path $SpawnerRoot "lib\Template-Sync.ps1"
        if (Test-Path $script) {
            $targetUsers = if ($To) { $To -split "," } else { @() }
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -TemplateName $Username -ToUsers $targetUsers -FromUser $From
        } else {
            Write-Log "Template-Sync.ps1 not found" "ERROR"
        }
    }
    "diff" {
        $script = Join-Path $SpawnerRoot "lib\Config-Diff.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Source $Username -Target $Template -Detailed:$Detailed
        } else {
            Write-Log "Config-Diff.ps1 not found" "ERROR"
        }
    }

    # ===== v3: Git Integration =====
    "repo" {
        $script = Join-Path $SpawnerRoot "lib\Git-Repo.ps1"
        if (Test-Path $script) {
            # Username is the action (init/status/commit), Template is the template name
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Action $Username -TemplateName $Template -Message $Message
        } else {
            Write-Log "Git-Repo.ps1 not found" "ERROR"
        }
    }

    # ===== v3: GitHub Sharing =====
    "publish" {
        $script = Join-Path $SpawnerRoot "lib\GitHub-Publish.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -TemplateName $Username -Repo $Repo -Private:$Private
        } else {
            Write-Log "GitHub-Publish.ps1 not found" "ERROR"
        }
    }
    "clone" {
        $script = Join-Path $SpawnerRoot "lib\GitHub-Clone.ps1"
        if (Test-Path $script) {
            # Username is the GitHub URL, Template is the target username
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -GitHubUrl $Username -TargetUser $Template -Identity $Identity
        } else {
            Write-Log "GitHub-Clone.ps1 not found" "ERROR"
        }
    }

    # ===== v3: Decomposition =====
    "decompose" {
        $script = Join-Path $SpawnerRoot "lib\Config-Decompose.ps1"
        if (Test-Path $script) {
            & $script -Config (Get-Config) -SpawnerRoot $SpawnerRoot -Username $Username -Output $Output
        } else {
            Write-Log "Config-Decompose.ps1 not found" "ERROR"
        }
    }

    # ===== Help =====
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
