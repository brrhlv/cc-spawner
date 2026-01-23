# Merge-Identity.ps1
# Merges an identity's contents into a user's .claude directory

param(
    [Parameter(Mandatory=$true)]
    [string]$UserPath,           # e.g., C:\Users\Lab1\.claude

    [Parameter(Mandatory=$true)]
    [string]$IdentityPath,       # e.g., C:\Spawner\identities\developer

    [switch]$ShowDetails
)

$script:merged = @()
$script:warnings = @()

function Write-MergeLog {
    param([string]$Message, [string]$Level = "INFO")
    if ($ShowDetails) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "  $Message" -ForegroundColor $color
    }
}

# 1. Append IDENTITY.md to CLAUDE.md
$identityMd = Join-Path $IdentityPath "IDENTITY.md"
if (Test-Path $identityMd) {
    $claudeMd = Join-Path $UserPath "CLAUDE.md"

    # If CLAUDE.md exists, append; otherwise create
    if (Test-Path $claudeMd) {
        $separator = "`n`n---`n`n# Applied Identity`n`n"
        $identityContent = Get-Content $identityMd -Raw
        Add-Content -Path $claudeMd -Value "$separator$identityContent"
    } else {
        Copy-Item $identityMd -Destination $claudeMd
    }

    $script:merged += "IDENTITY.md -> CLAUDE.md"
    Write-MergeLog "Appended IDENTITY.md to CLAUDE.md" "OK"
}

# 2. Copy skills (merge folders)
$skillsPath = Join-Path $IdentityPath "skills"
if (Test-Path $skillsPath) {
    $destSkills = Join-Path $UserPath "skills"
    if (-not (Test-Path $destSkills)) {
        New-Item -ItemType Directory -Path $destSkills -Force | Out-Null
    }

    $skills = Get-ChildItem $skillsPath -Directory
    foreach ($skill in $skills) {
        $destSkill = Join-Path $destSkills $skill.Name

        # Use robocopy for reliable merging
        $robocopyArgs = @($skill.FullName, $destSkill, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")
        $result = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

        $script:merged += "skills/$($skill.Name)"
        Write-MergeLog "Copied skill: $($skill.Name)" "OK"
    }
}

# 3. Copy agents (merge folders)
$agentsPath = Join-Path $IdentityPath "agents"
if (Test-Path $agentsPath) {
    $destAgents = Join-Path $UserPath "agents"
    if (-not (Test-Path $destAgents)) {
        New-Item -ItemType Directory -Path $destAgents -Force | Out-Null
    }

    $agents = Get-ChildItem $agentsPath -File -Filter "*.md"
    foreach ($agent in $agents) {
        $destAgent = Join-Path $destAgents $agent.Name
        Copy-Item $agent.FullName -Destination $destAgent -Force

        $script:merged += "agents/$($agent.Name)"
        Write-MergeLog "Copied agent: $($agent.Name)" "OK"
    }
}

# 4. Copy hooks (merge folders)
$hooksPath = Join-Path $IdentityPath "hooks"
if (Test-Path $hooksPath) {
    $destHooks = Join-Path $UserPath "hooks"
    if (-not (Test-Path $destHooks)) {
        New-Item -ItemType Directory -Path $destHooks -Force | Out-Null
    }

    $hooks = Get-ChildItem $hooksPath -File
    foreach ($hook in $hooks) {
        $destHook = Join-Path $destHooks $hook.Name
        Copy-Item $hook.FullName -Destination $destHook -Force

        $script:merged += "hooks/$($hook.Name)"
        Write-MergeLog "Copied hook: $($hook.Name)" "OK"
    }
}

# 5. Merge settings.patch.json into settings.json
$patchFile = Join-Path $IdentityPath "settings.patch.json"
if (Test-Path $patchFile) {
    $settingsFile = Join-Path $UserPath "settings.json"

    if (Test-Path $settingsFile) {
        try {
            $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
            $patch = Get-Content $patchFile -Raw | ConvertFrom-Json

            # Simple merge: copy top-level properties from patch
            foreach ($prop in $patch.PSObject.Properties) {
                if ($prop.Name -ne "_comment") {
                    # If property exists, merge arrays; otherwise add
                    if ($settings.PSObject.Properties[$prop.Name]) {
                        # For permissions.allow/deny, merge arrays
                        if ($prop.Name -eq "permissions") {
                            if (-not $settings.permissions) {
                                $settings | Add-Member -NotePropertyName "permissions" -NotePropertyValue @{} -Force
                            }

                            if ($patch.permissions.allow) {
                                $existingAllow = @($settings.permissions.allow)
                                $settings.permissions.allow = $existingAllow + @($patch.permissions.allow) | Select-Object -Unique
                            }

                            if ($patch.permissions.deny) {
                                $existingDeny = @($settings.permissions.deny)
                                $settings.permissions.deny = $existingDeny + @($patch.permissions.deny) | Select-Object -Unique
                            }
                        } else {
                            $settings.$($prop.Name) = $prop.Value
                        }
                    } else {
                        $settings | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
                    }
                }
            }

            $settings | ConvertTo-Json -Depth 10 | Out-File $settingsFile -Encoding UTF8 -Force
            $script:merged += "settings.patch.json -> settings.json"
            Write-MergeLog "Merged settings.patch.json" "OK"

        } catch {
            $script:warnings += "Failed to merge settings.patch.json: $_"
            Write-MergeLog "Failed to merge settings: $_" "WARN"
        }
    } else {
        $script:warnings += "No settings.json to merge into"
        Write-MergeLog "No settings.json found to merge into" "WARN"
    }
}

# Return summary
return @{
    Merged = $script:merged
    Warnings = $script:warnings
}
