# Template-Sync.ps1 - Sync template to/from users
# Called by: spawner sync <template> --to <user1,user2> OR --from <user>

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    [string[]]$ToUsers,
    [string]$FromUser
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

$templatePath = Join-Path $SpawnerRoot $Config.templates.$TemplateName.path

if (-not (Test-Path $templatePath)) {
    Write-Log "Template path not found: $templatePath" "ERROR"
    exit 1
}

# Determine direction
if ($FromUser) {
    # Pull from user to template
    Write-Log "========================================" "STEP"
    Write-Log "  SYNC: $FromUser -> $TemplateName (PULL)" "STEP"
    Write-Log "========================================" "STEP"

    $userHome = "C:\Users\$FromUser"
    $userConfigDir = "$userHome\.claude"

    if (-not (Test-Path $userConfigDir)) {
        Write-Log "User .claude not found: $userConfigDir" "ERROR"
        exit 1
    }

    # Backup current template
    Write-Log "Backing up current template..." "STEP"
    $backupDir = Join-Path $SpawnerRoot "backups\templates\$TemplateName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path (Split-Path $backupDir -Parent) -Force | Out-Null
    Copy-Item $templatePath -Destination $backupDir -Recurse -Force
    Write-Log "  Backup: $backupDir" "OK"

    # Sanitize and sync
    Write-Log "Syncing from $FromUser..." "STEP"
    $sanitizeScript = Join-Path $SpawnerRoot "lib\Sanitize-Config.ps1"
    $result = & $sanitizeScript -SourcePath $userConfigDir -DestPath $templatePath -Config $Config -Validate

    if ($result.Success) {
        Write-Log "  Sync complete" "OK"
    } else {
        Write-Log "  Sync failed - restoring backup" "ERROR"
        Remove-Item $templatePath -Recurse -Force
        Copy-Item $backupDir -Destination $templatePath -Recurse -Force
        exit 1
    }

} elseif ($ToUsers -and $ToUsers.Count -gt 0) {
    # Push template to users
    Write-Log "========================================" "STEP"
    Write-Log "  SYNC: $TemplateName -> Users (PUSH)" "STEP"
    Write-Log "========================================" "STEP"
    Write-Log "Template: $templatePath" "INFO"
    Write-Log "Targets: $($ToUsers -join ', ')" "INFO"

    $excludePaths = $Config.sync.excludePaths
    $preservePaths = $Config.sync.preservePaths

    foreach ($user in $ToUsers) {
        $user = $user.Trim()
        $userHome = "C:\Users\$user"
        $userConfigDir = "$userHome\.claude"

        Write-Log "" "INFO"
        Write-Log "Syncing to $user..." "STEP"

        if (-not (Test-Path $userHome)) {
            Write-Log "  User home not found: $userHome" "WARN"
            continue
        }

        # Create snapshot before sync
        Write-Log "  Creating snapshot..." "INFO"
        $snapshotScript = Join-Path $SpawnerRoot "lib\User-Snapshot.ps1"
        if (Test-Path $snapshotScript) {
            & $snapshotScript -Config $Config -SpawnerRoot $SpawnerRoot -Username $user | Out-Null
        }

        # Preserve .env
        $envBackup = $null
        $envPath = Join-Path $userConfigDir ".env"
        if (Test-Path $envPath) {
            $envBackup = Get-Content $envPath -Raw
        }

        # Preserve specified paths
        $preservedData = @{}
        foreach ($path in $preservePaths) {
            $fullPath = Join-Path $userConfigDir $path
            if (Test-Path $fullPath) {
                $tempPreserve = Join-Path $env:TEMP "spawner-preserve-$user-$(Get-Random)"
                New-Item -ItemType Directory -Path $tempPreserve -Force | Out-Null
                if (Test-Path $fullPath -PathType Container) {
                    Copy-Item $fullPath -Destination (Join-Path $tempPreserve $path) -Recurse -Force
                } else {
                    $parentDir = Split-Path $path -Parent
                    if ($parentDir) {
                        New-Item -ItemType Directory -Path (Join-Path $tempPreserve $parentDir) -Force | Out-Null
                    }
                    Copy-Item $fullPath -Destination (Join-Path $tempPreserve $path) -Force
                }
                $preservedData[$path] = $tempPreserve
            }
        }

        # Sync template to user
        if (-not (Test-Path $userConfigDir)) {
            New-Item -ItemType Directory -Path $userConfigDir -Force | Out-Null
        }

        $robocopyArgs = @($templatePath, $userConfigDir, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
        $robocopyArgs += "/XD"
        $robocopyArgs += $excludePaths

        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
        if ($result.ExitCode -gt 7) {
            Write-Log "  Sync failed for $user" "ERROR"
            continue
        }

        # Restore preserved paths
        foreach ($path in $preservedData.Keys) {
            $tempPreserve = $preservedData[$path]
            $srcPath = Join-Path $tempPreserve $path
            $dstPath = Join-Path $userConfigDir $path

            if (Test-Path $srcPath -PathType Container) {
                if (Test-Path $dstPath) { Remove-Item $dstPath -Recurse -Force }
                Copy-Item $srcPath -Destination $dstPath -Recurse -Force
            } else {
                Copy-Item $srcPath -Destination $dstPath -Force
            }
            Remove-Item (Split-Path $tempPreserve -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Restore .env
        if ($envBackup) {
            $envBackup | Out-File $envPath -Encoding UTF8 -NoNewline
        }

        # Set ownership
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) {
            icacls $userConfigDir /setowner $user /T /C 2>&1 | Out-Null
            icacls $userConfigDir /grant "${user}:(OI)(CI)F" /T /C 2>&1 | Out-Null
        }

        Write-Log "  Done" "OK"
    }

} else {
    Write-Log "Specify --to <users> or --from <user>" "ERROR"
    Write-Log "  Push: spawner sync $TemplateName --to Lab1,Lab2" "INFO"
    Write-Log "  Pull: spawner sync $TemplateName --from Lab1" "INFO"
    exit 1
}

Write-Log "========================================" "OK"
Write-Log "  SYNC COMPLETE" "OK"
Write-Log "========================================" "OK"
