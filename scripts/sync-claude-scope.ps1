[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('User', 'Project')]
    [string] $Scope,

    [switch] $WhatIf,
    [switch] $Force,
    [switch] $Diff,
    [switch] $Uninstall,

    # -Scope User: override the target %USERPROFILE%\.claude
    [string] $UserScopePath,

    # -Scope Project: the repo whose .claude/ should receive the project-scope template
    [string] $TargetRepo
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent -Path $scriptRoot

$manifestFileName = '.claude-scope-sync.json'
$backupDirName = '.claude-scope-backups'
$hookPlaceholder = 'C:\\Users\\{User}\\.claude\\hooks\\block-dangerous.js'

$selectedModes = @(@($WhatIf.IsPresent, $Diff.IsPresent, $Uninstall.IsPresent) | Where-Object { $_ })
if ($selectedModes.Count -gt 1) {
    throw 'WhatIf, Diff, and Uninstall are mutually exclusive.'
}

if ($Scope -eq 'User') {
    $sourceClaudePath = Join-Path -Path $repoRoot -ChildPath 'user\.claude'
    $managedFiles = @(
        'CLAUDE.md',
        'settings.json',
        'hooks\block-dangerous.js',
        'agents\generic-test-quality-reviewer.md'
    )

    if ([string]::IsNullOrWhiteSpace($UserScopePath)) {
        if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
            throw 'USERPROFILE is not set; cannot resolve the Claude Code User Scope path.'
        }
        $UserScopePath = Join-Path -Path $env:USERPROFILE -ChildPath '.claude'
    }
    $targetClaudePath = [System.IO.Path]::GetFullPath($UserScopePath)
}
else {
    $sourceClaudePath = Join-Path -Path $repoRoot -ChildPath 'project\.claude'
    $managedFiles = @(
        'settings.json',
        'hooks\format-lint.js'
    )

    if ([string]::IsNullOrWhiteSpace($TargetRepo)) {
        throw '-Scope Project requires -TargetRepo <path to the repo whose .claude/ should be updated>.'
    }
    $resolvedRepo = [System.IO.Path]::GetFullPath($TargetRepo)
    if (-not (Test-Path -LiteralPath $resolvedRepo -PathType Container)) {
        throw "TargetRepo does not exist: $resolvedRepo"
    }
    $targetClaudePath = Join-Path -Path $resolvedRepo -ChildPath '.claude'
}

if (-not (Test-Path -LiteralPath $sourceClaudePath -PathType Container)) {
    throw "Source directory was not found: $sourceClaudePath"
}

function Test-BytesEqual {
    param([byte[]] $FirstBytes, [byte[]] $SecondBytes)
    if ($FirstBytes.Length -ne $SecondBytes.Length) { return $false }
    for ($index = 0; $index -lt $FirstBytes.Length; $index++) {
        if ($FirstBytes[$index] -ne $SecondBytes[$index]) { return $false }
    }
    return $true
}

function Get-BytesSha256 {
    param([byte[]] $Bytes)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-DesiredFileBytes {
    param([string] $RelativePath)

    $sourceFilePath = Join-Path -Path $sourceClaudePath -ChildPath $RelativePath
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

    if ($Scope -eq 'User' -and $RelativePath -eq 'settings.json') {
        $json = Get-Content -LiteralPath $sourceFilePath -Raw
        try { $json | ConvertFrom-Json | Out-Null }
        catch { throw "Source settings.json is not valid JSON: $sourceFilePath" }

        $hookScriptPath = Join-Path -Path $targetClaudePath -ChildPath 'hooks\block-dangerous.js'
        $json = $json.Replace($hookPlaceholder, $hookScriptPath.Replace('\', '\\'))
        return $utf8WithoutBom.GetBytes($json)
    }

    return [System.IO.File]::ReadAllBytes($sourceFilePath)
}

function Read-Manifest {
    $manifestPath = Join-Path -Path $targetClaudePath -ChildPath $manifestFileName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { return $null }
    return (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)
}

function Write-Manifest {
    param([object[]] $Entries)
    $manifestPath = Join-Path -Path $targetClaudePath -ChildPath $manifestFileName
    $manifest = [ordered]@{
        version = 1
        scope = $Scope
        source = (Resolve-Path -LiteralPath $sourceClaudePath).Path
        files = $Entries
    }
    $json = $manifest | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($manifestPath, $json + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
}

function Backup-ExistingFile {
    param([string] $TargetFilePath, [string] $RelativePath)
    $backupFolder = Join-Path -Path (Join-Path -Path $targetClaudePath -ChildPath $backupDirName) -ChildPath (Get-Date -Format 'yyyyMMdd-HHmmss')
    $backupFilePath = Join-Path -Path $backupFolder -ChildPath $RelativePath
    $backupDirectory = Split-Path -Parent -Path $backupFilePath
    if (-not (Test-Path -LiteralPath $backupDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    }
    Copy-Item -LiteralPath $TargetFilePath -Destination $backupFilePath -Force
    Write-Output "Backed up: $RelativePath -> $backupFilePath"
}

if ($Diff) {
    foreach ($relativePath in $managedFiles) {
        $targetFilePath = Join-Path -Path $targetClaudePath -ChildPath $relativePath
        if (-not (Test-Path -LiteralPath $targetFilePath -PathType Leaf)) {
            Write-Output "Missing: $relativePath"
        }
        elseif (Test-BytesEqual -FirstBytes (Get-DesiredFileBytes -RelativePath $relativePath) -SecondBytes ([System.IO.File]::ReadAllBytes($targetFilePath))) {
            Write-Output "Unchanged: $relativePath"
        }
        else {
            Write-Output "Different: $relativePath"
        }
    }
    return
}

if ($Uninstall) {
    $manifest = Read-Manifest
    if ($null -eq $manifest) {
        Write-Output 'No sync manifest found; nothing was removed.'
        return
    }
    foreach ($manifestEntry in @($manifest.files)) {
        $relativePath = [string] $manifestEntry.path
        $targetFilePath = Join-Path -Path $targetClaudePath -ChildPath $relativePath
        if (-not (Test-Path -LiteralPath $targetFilePath -PathType Leaf)) {
            Write-Output "Skipped (missing): $relativePath"
            continue
        }
        $currentHash = Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($targetFilePath))
        if ($currentHash -eq [string] $manifestEntry.sha256) {
            Remove-Item -LiteralPath $targetFilePath -Force
            Write-Output "Removed: $relativePath"
        }
        else {
            Write-Warning "Kept modified file: $relativePath"
        }
    }
    Remove-Item -LiteralPath (Join-Path -Path $targetClaudePath -ChildPath $manifestFileName) -Force
    return
}

if (-not $WhatIf -and -not (Test-Path -LiteralPath $targetClaudePath -PathType Container)) {
    New-Item -ItemType Directory -Path $targetClaudePath -Force | Out-Null
}

foreach ($relativePath in $managedFiles) {
    $sourceFilePath = Join-Path -Path $sourceClaudePath -ChildPath $relativePath
    if (-not (Test-Path -LiteralPath $sourceFilePath -PathType Leaf)) {
        throw "Managed source file was not found: $sourceFilePath"
    }

    $targetFilePath = Join-Path -Path $targetClaudePath -ChildPath $relativePath
    $targetDirectory = Split-Path -Parent -Path $targetFilePath
    $desiredBytes = Get-DesiredFileBytes -RelativePath $relativePath

    $targetBytes = $null
    if (Test-Path -LiteralPath $targetFilePath -PathType Leaf) {
        $targetBytes = [System.IO.File]::ReadAllBytes($targetFilePath)
    }

    if ($null -ne $targetBytes -and (Test-BytesEqual -FirstBytes $desiredBytes -SecondBytes $targetBytes)) {
        Write-Output "Skipped (unchanged): $relativePath"
        continue
    }

    if ($WhatIf) {
        if ($null -eq $targetBytes) {
            Write-Output "Would sync: $relativePath"
        }
        elseif ($Force) {
            Write-Output "Would back up and sync: $relativePath"
        }
        else {
            Write-Output "Would skip conflict (use -Force): $relativePath"
        }
        continue
    }

    if ($null -ne $targetBytes) {
        if (-not $Force) {
            Write-Output "Skipped (different; use -Force): $relativePath"
            continue
        }
        Backup-ExistingFile -TargetFilePath $targetFilePath -RelativePath $relativePath
    }

    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }
    [System.IO.File]::WriteAllBytes($targetFilePath, $desiredBytes)
    Write-Output "Synced: $relativePath"
}

if ($WhatIf) { return }

$manifestEntries = @()
foreach ($relativePath in $managedFiles) {
    $targetFilePath = Join-Path -Path $targetClaudePath -ChildPath $relativePath
    if (-not (Test-Path -LiteralPath $targetFilePath -PathType Leaf)) {
        Write-Warning "Not synced (left out of manifest): $relativePath"
        continue
    }
    $manifestEntries += [pscustomobject]@{
        path = $relativePath
        sha256 = Get-BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($targetFilePath))
    }
}
Write-Manifest -Entries $manifestEntries

Write-Verbose "Scope:  $Scope"
Write-Verbose "Source: $sourceClaudePath"
Write-Verbose "Target: $targetClaudePath"
