# In PowerShell issue this command to allow running this script: 
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
<#
.SYNOPSIS
    Verify file integrity using an MD5 checklist.

.DESCRIPTION
    This script reads a checklist.md5sum file and compares hashes to current files.
    Useful for checking data integrity after long-term storage.
#>

param (
    [string]$ChecklistFile = "checklist.md5sum",
    [string]$RootFolder = "."
)

# Validate inputs
if (-Not (Test-Path -LiteralPath $ChecklistFile -PathType Leaf)) {
    Write-Error "Checklist file not found: $ChecklistFile"
    exit 1
}

if (-Not (Test-Path -LiteralPath $RootFolder -PathType Container)) {
    Write-Error "Root folder not found: $RootFolder"
    exit 1
}

# Normalize RootFolder with long path prefix
$ResolvedRoot = (Resolve-Path -LiteralPath $RootFolder).Path
$LongRoot = if ($ResolvedRoot -notlike '\\?\*') { "\\?\$ResolvedRoot" } else { $ResolvedRoot }

Write-Host "Verifying files using MD5..."
Write-Host "Checklist file : $ChecklistFile"
Write-Host "Root folder    : $LongRoot"
Write-Host ""

# Read checklist
$Lines = Get-Content -Path $ChecklistFile -Encoding UTF8
$Total = $Lines.Count
$i = 0
$Failures = 0
$Missing = 0
$BadHash = 0
$MissingFiles = @()
$BadHashFiles = @()

foreach ($line in $Lines) {
    $i++
    if ($line.Length -lt 35) {
        continue
    }

    $expectedHash = $line.Substring(0, 32)
    $relPath = $line.Substring(34).Trim()

    # Convert forward slashes (used in checklist) to backslashes for Windows
    $relPathWin = $relPath -replace '/', '\'

    # Manually construct full path for long path compatibility
    $fullPath = "$LongRoot\$relPathWin"

    Write-Host ("[{0:D4}/{1:D4}] {2}" -f $i, $Total, $relPath) -NoNewline

    if (-Not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Write-Host "  --> MISSING"
        $MissingFiles += $relPath
        $Failures++
        $Missing++
        continue
    }

    try {
        $actualHash = (Get-FileHash -LiteralPath $fullPath -Algorithm MD5).Hash.ToLower()
        if ($actualHash -ne $expectedHash) {
            Write-Host "  --> HASH MISMATCH"
            $BadHashFiles += $relPath
            $Failures++
            $BadHash++
        } else {
            Write-Host "  OK"
        }
    } catch {
        Write-Host "  --> ERROR: $($_.Exception.Message)"
        $Failures++
        $BadHash++
        $BadHashFiles += $relPath
    }
}

# Summary
Write-Host "`nSUMMARY:"
Write-Host "Total files listed : $Total"
Write-Host "Passed             : $($Total - $Failures)"
Write-Host "Missing files      : $Missing"
Write-Host "Hash mismatches    : $BadHash"
Write-Host ""

# Report failures
if ($MissingFiles.Count -gt 0) {
    Write-Host "Missing files:"
    $MissingFiles | ForEach-Object { Write-Host " - $_" }
    Write-Host ""
}

if ($BadHashFiles.Count -gt 0) {
    Write-Host "Hash mismatched files:"
    $BadHashFiles | ForEach-Object { Write-Host " - $_" }
    Write-Host ""
}

