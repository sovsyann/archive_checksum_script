<#
.SYNOPSIS
    Generate MD5 checksums for all files in a directory, outputting a checklist file.

.DESCRIPTION
    This script creates a checklist of MD5 hashes of files under a given directory,
    suitable for later verification on any platform (Windows, macOS, Linux).

    It can also log any skipped files due to read/access issues, optionally enabled via -LogSkipped.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [switch]$LogSkipped
)

# Output files
$OutFile = "checklist.md5sum"
$LogFile = "skipped_files.log"

# Ensure the path exists
if (-Not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Error: '$TargetDir' is not a directory."
    exit 1
}

# Normalize to full path with long path prefix
$ResolvedPath = (Resolve-Path $TargetDir).Path
$TargetDirFull = "\\?\$ResolvedPath"
$BaseFolder = Split-Path $ResolvedPath -Leaf
$OutFilePath = Join-Path (Get-Location) $OutFile
$LogFilePath = Join-Path (Get-Location) $LogFile

# Prepare the output file with UTF-8 BOM
$utf8BomEncoding = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($OutFilePath, "", $utf8BomEncoding)

# If logging enabled, initialize skipped file log
if ($LogSkipped) {
    Set-Content -Path $LogFilePath -Value "Skipped files log:`n"
}

Write-Host "Generating MD5 checklist for: $TargetDirFull"
Write-Host "Output will be: $OutFilePath"
if ($LogSkipped) {
    Write-Host "Logging skipped files to: $LogFilePath"
}
Write-Host ""

# File list to write
$lines = @()

# Enumerate files and build lines
Get-ChildItem -LiteralPath $TargetDirFull -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notmatch '^(\._|\.DS_Store|desktop.ini)$'
} | ForEach-Object {
    $FullPath = $_.FullName
    $RelativePath = $FullPath.Substring($TargetDirFull.Length).TrimStart('\', '/')
    $RelativePath = Join-Path $BaseFolder $RelativePath
    $RelativePath = $RelativePath -replace '\\', '/'

    try {
        $md5 = Get-FileHash -LiteralPath $FullPath -Algorithm MD5 -ErrorAction Stop
        if ($md5 -ne $null) {
            $hash = $md5.Hash.ToLower()
            $lines += "$hash  $RelativePath"
        } else {
            $msg = "NULL hash: $FullPath"
            Write-Warning $msg
            if ($LogSkipped) {
                Add-Content -Path $LogFilePath -Value $msg
            }
        }
    } catch {
        $msg = "ERROR [$($_.Exception.Message)]: $FullPath"
        Write-Warning $msg
        if ($LogSkipped) {
            Add-Content -Path $LogFilePath -Value $msg
        }
    }
}

# Append all at once to minimize file locking
foreach ($line in $lines) {
    [System.IO.File]::AppendAllText($OutFilePath, "$line`r`n", $utf8BomEncoding)
}

# Convert CRLF to LF (preserving BOM)
$content = Get-Content -Raw -Encoding Byte -Path $OutFilePath
$hasBOM = ($content[0] -eq 0xEF -and $content[1] -eq 0xBB -and $content[2] -eq 0xBF)
$startIndex = if ($hasBOM) { 3 } else { 0 }

$textBody = [System.Text.Encoding]::UTF8.GetString($content, $startIndex, $content.Length - $startIndex)
$textBodyLF = $textBody -replace "`r`n", "`n"

$finalBytes = [System.Text.Encoding]::UTF8.GetBytes($textBodyLF)
if ($hasBOM) {
    $bomBytes = 0xEF, 0xBB, 0xBF
    $finalBytes = $bomBytes + $finalBytes
}
[System.IO.File]::WriteAllBytes($OutFilePath, $finalBytes)

Write-Host "`nChecklist written to $OutFilePath (LF line endings, UTF-8 BOM)"
if ($LogSkipped) {
    Write-Host "Skipped file details in: $LogFilePath"
}

