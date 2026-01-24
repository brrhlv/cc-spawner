# Sanitize-Config.ps1 - Core sanitization pipeline for safe sharing
# Removes secrets, redacts patterns, replaces hardcoded paths
#
# Usage:
#   $result = & .\Sanitize-Config.ps1 -SourcePath <path> -DestPath <path> -Config <config>
#
# Returns: @{ Success = $bool; Warnings = @(); RemovedFiles = @(); RedactedFiles = @() }

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    [Parameter(Mandatory=$true)]
    [string]$DestPath,
    [Parameter(Mandatory=$true)]
    $Config,
    [switch]$Validate
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

$result = @{
    Success = $true
    Warnings = @()
    RemovedFiles = @()
    RemovedDirs = @()
    RedactedFiles = @()
    PathsReplaced = @()
}

# Get sanitization config
$removeFiles = $Config.security.sanitize.removeFiles
$removeDirs = $Config.security.sanitize.removeDirs
$redactPatterns = $Config.security.sanitize.redactPatterns

Write-Log "Sanitizing config for safe sharing..." "STEP"

# Step 1: Copy source to destination (excluding secret files/dirs)
Write-Log "  Step 1: Copying files (excluding secrets)..." "INFO"

$robocopyArgs = @($SourcePath, $DestPath, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS")

if ($removeDirs.Count -gt 0) {
    $robocopyArgs += "/XD"
    $robocopyArgs += $removeDirs
}

if ($removeFiles.Count -gt 0) {
    $robocopyArgs += "/XF"
    $robocopyArgs += $removeFiles
}

$copyResult = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
if ($copyResult.ExitCode -gt 7) {
    $result.Success = $false
    $result.Warnings += "robocopy failed with exit code $($copyResult.ExitCode)"
    return $result
}

# Track removed files/dirs
foreach ($f in $removeFiles) {
    $testPath = Join-Path $SourcePath $f
    if (Test-Path $testPath) {
        $result.RemovedFiles += $f
    }
}
foreach ($d in $removeDirs) {
    $testPath = Join-Path $SourcePath $d
    if (Test-Path $testPath) {
        $result.RemovedDirs += $d
    }
}

# Step 2: Remove any secret files that might have been missed
Write-Log "  Step 2: Double-checking for secret files..." "INFO"
foreach ($file in $removeFiles) {
    Get-ChildItem $DestPath -Recurse -Filter $file -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        $result.RemovedFiles += $_.FullName.Replace("$DestPath\", "")
        Write-Log "    Removed: $($_.Name)" "WARN"
    }
}

# Step 3: Redact inline secrets in text files
Write-Log "  Step 3: Redacting inline secrets..." "INFO"

$textExtensions = @(".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".env.example", ".js", ".ts", ".ps1", ".sh")
$textFiles = Get-ChildItem $DestPath -Recurse -File | Where-Object {
    $ext = $_.Extension.ToLower()
    $textExtensions -contains $ext -or $_.Name -match "\.(md|txt|json|yaml|yml|toml|js|ts|ps1|sh)$"
}

foreach ($file in $textFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $originalContent = $content
        $redacted = $false

        foreach ($pattern in $redactPatterns) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, "[REDACTED]"
                $redacted = $true
            }
        }

        if ($redacted) {
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
            $relativePath = $file.FullName.Replace("$DestPath\", "")
            $result.RedactedFiles += $relativePath
            Write-Log "    Redacted: $relativePath" "INFO"
        }
    } catch {
        # Skip binary files or files we can't read
    }
}

# Step 4: Replace hardcoded paths
Write-Log "  Step 4: Replacing hardcoded paths..." "INFO"

$userHome = $env:USERPROFILE
$pathPatterns = @(
    @{ Pattern = [regex]::Escape($userHome); Replacement = "{USER_HOME}" },
    @{ Pattern = "C:\\Users\\[^\\]+"; Replacement = "{USER_HOME}" },
    @{ Pattern = "/c/Users/[^/]+"; Replacement = "{USER_HOME}" },
    @{ Pattern = "/home/[^/]+"; Replacement = "{USER_HOME}" }
)

foreach ($file in $textFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $originalContent = $content
        $modified = $false

        foreach ($pp in $pathPatterns) {
            if ($content -match $pp.Pattern) {
                $content = $content -replace $pp.Pattern, $pp.Replacement
                $modified = $true
            }
        }

        if ($modified) {
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
            $relativePath = $file.FullName.Replace("$DestPath\", "")
            if ($result.PathsReplaced -notcontains $relativePath) {
                $result.PathsReplaced += $relativePath
            }
        }
    } catch {
        # Skip files we can't process
    }
}

# Step 5: Validation pass - ensure no secrets remain
if ($Validate) {
    Write-Log "  Step 5: Validating no secrets remain..." "INFO"

    $allFiles = Get-ChildItem $DestPath -Recurse -File
    $secretsFound = $false

    foreach ($file in $allFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            foreach ($pattern in $redactPatterns) {
                if ($content -match $pattern) {
                    $relativePath = $file.FullName.Replace("$DestPath\", "")
                    $result.Warnings += "Secret pattern found in $relativePath after sanitization!"
                    Write-Log "    WARNING: Secret still found in $relativePath" "WARN"
                    $secretsFound = $true
                }
            }
        } catch {
            # Skip files we can't read
        }
    }

    if ($secretsFound) {
        $result.Success = $false
        Write-Log "  VALIDATION FAILED: Secrets still present!" "ERROR"
    } else {
        Write-Log "  Validation passed - no secrets detected" "OK"
    }
}

Write-Log "Sanitization complete" "OK"
Write-Log "  Removed files: $($result.RemovedFiles.Count)" "INFO"
Write-Log "  Removed dirs: $($result.RemovedDirs.Count)" "INFO"
Write-Log "  Redacted files: $($result.RedactedFiles.Count)" "INFO"
Write-Log "  Paths replaced: $($result.PathsReplaced.Count)" "INFO"

return $result
