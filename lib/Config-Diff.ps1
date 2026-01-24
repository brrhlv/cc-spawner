# Config-Diff.ps1 - Compare two configs (user vs user, user vs template, template vs template)
# Called by: spawner diff <source> <target> [--detailed]

param(
    [Parameter(Mandatory=$true)]
    $Config,
    [Parameter(Mandatory=$true)]
    [string]$SpawnerRoot,
    [Parameter(Mandatory=$true)]
    [string]$Source,
    [Parameter(Mandatory=$true)]
    [string]$Target,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "OK"    { "Green" }
        "STEP"  { "Cyan" }
        "ADD"   { "Green" }
        "DEL"   { "Red" }
        "MOD"   { "Yellow" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Resolve-ConfigPath {
    param([string]$Name)

    # Check if it's a template
    if ($Config.templates.$Name) {
        return Join-Path $SpawnerRoot $Config.templates.$Name.path
    }

    # Check if it's a user
    $userPath = "C:\Users\$Name\.claude"
    if (Test-Path $userPath) {
        return $userPath
    }

    # Check if it's a direct path
    if (Test-Path $Name) {
        return $Name
    }

    return $null
}

# Resolve paths
$sourcePath = Resolve-ConfigPath $Source
$targetPath = Resolve-ConfigPath $Target

if (-not $sourcePath) {
    Write-Log "Source not found: $Source" "ERROR"
    exit 1
}

if (-not $targetPath) {
    Write-Log "Target not found: $Target" "ERROR"
    exit 1
}

Write-Log "========================================" "STEP"
Write-Log "  CONFIG DIFF" "STEP"
Write-Log "========================================" "STEP"
Write-Log "Source: $Source ($sourcePath)" "INFO"
Write-Log "Target: $Target ($targetPath)" "INFO"
Write-Log "" "INFO"

# Get file lists
$sourceFiles = @{}
$targetFiles = @{}

Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $relativePath = $_.FullName.Replace("$sourcePath\", "")
    $sourceFiles[$relativePath] = @{
        Path = $_.FullName
        Size = $_.Length
        Hash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
        Modified = $_.LastWriteTime
    }
}

Get-ChildItem $targetPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $relativePath = $_.FullName.Replace("$targetPath\", "")
    $targetFiles[$relativePath] = @{
        Path = $_.FullName
        Size = $_.Length
        Hash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
        Modified = $_.LastWriteTime
    }
}

# Compare
$onlyInSource = @()
$onlyInTarget = @()
$modified = @()
$identical = @()

foreach ($file in $sourceFiles.Keys) {
    if ($targetFiles.ContainsKey($file)) {
        if ($sourceFiles[$file].Hash -eq $targetFiles[$file].Hash) {
            $identical += $file
        } else {
            $modified += $file
        }
    } else {
        $onlyInSource += $file
    }
}

foreach ($file in $targetFiles.Keys) {
    if (-not $sourceFiles.ContainsKey($file)) {
        $onlyInTarget += $file
    }
}

# Summary
Write-Log "SUMMARY:" "STEP"
Write-Log "  Identical: $($identical.Count) files" "OK"
Write-Log "  Modified:  $($modified.Count) files" "MOD"
Write-Log "  Only in $Source$([char]58) $($onlyInSource.Count) files" "ADD"
Write-Log "  Only in $Target$([char]58) $($onlyInTarget.Count) files" "DEL"
Write-Log "" "INFO"

# Details
if ($onlyInSource.Count -gt 0) {
    Write-Log "FILES ONLY IN $Source$([char]58)" "ADD"
    foreach ($file in $onlyInSource | Sort-Object) {
        Write-Log "  + $file" "ADD"
    }
    Write-Log "" "INFO"
}

if ($onlyInTarget.Count -gt 0) {
    Write-Log "FILES ONLY IN $Target$([char]58)" "DEL"
    foreach ($file in $onlyInTarget | Sort-Object) {
        Write-Log "  - $file" "DEL"
    }
    Write-Log "" "INFO"
}

if ($modified.Count -gt 0) {
    Write-Log "MODIFIED FILES:" "MOD"
    foreach ($file in $modified | Sort-Object) {
        $srcInfo = $sourceFiles[$file]
        $tgtInfo = $targetFiles[$file]
        Write-Log "  ~ $file" "MOD"

        if ($Detailed) {
            Write-Log "      Source: $($srcInfo.Size) bytes, $($srcInfo.Modified)" "INFO"
            Write-Log "      Target: $($tgtInfo.Size) bytes, $($tgtInfo.Modified)" "INFO"

            # Show first few lines of diff for text files
            $textExtensions = @(".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".js", ".ts", ".ps1", ".sh")
            $ext = [System.IO.Path]::GetExtension($file).ToLower()

            if ($textExtensions -contains $ext) {
                try {
                    $srcContent = Get-Content $srcInfo.Path -TotalCount 50
                    $tgtContent = Get-Content $tgtInfo.Path -TotalCount 50

                    $diff = Compare-Object $srcContent $tgtContent -PassThru | Select-Object -First 5
                    if ($diff) {
                        Write-Log "      Sample diff:" "INFO"
                        foreach ($line in $diff) {
                            $prefix = if ($line.SideIndicator -eq "<=") { "<" } else { ">" }
                            $truncated = if ($line.Length -gt 60) { $line.Substring(0, 57) + "..." } else { $line }
                            Write-Log "        $prefix $truncated" "INFO"
                        }
                    }
                } catch {
                    # Skip if can't read
                }
            }
        }
    }
    Write-Log "" "INFO"
}

if ($Detailed -and $identical.Count -gt 0) {
    Write-Log "IDENTICAL FILES ($($identical.Count)):" "OK"
    foreach ($file in $identical | Sort-Object | Select-Object -First 20) {
        Write-Log "  = $file" "OK"
    }
    if ($identical.Count -gt 20) {
        Write-Log "  ... and $($identical.Count - 20) more" "INFO"
    }
}

# Return summary object
return @{
    Source = $Source
    Target = $Target
    Identical = $identical.Count
    Modified = $modified.Count
    OnlyInSource = $onlyInSource.Count
    OnlyInTarget = $onlyInTarget.Count
    ModifiedFiles = $modified
    SourceOnlyFiles = $onlyInSource
    TargetOnlyFiles = $onlyInTarget
}
