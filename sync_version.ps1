# Keeps the "1.0.N" version number consistent across the repo, where N is
# the itch.io build number (the same number shown on the public itch.io
# page and returned by `butler status`). This is the single source of
# truth for what "the version" means for this project -- there's no
# separately-maintained VERSION file to fall out of sync with itch.
#
# Called automatically by deploy_to_itch.ps1 after a successful push, with
# the build number butler just reported. Can also be run by hand:
#   powershell -File sync_version.ps1 -BuildNumber 12
#
# Deliberately narrow regexes (anchored to the surrounding text specific to
# each file) rather than a blind "replace 1.0.1 with 1.0.12" -- a lock file
# in particular can easily contain an unrelated third-party package that
# happens to also be at version 1.0.1, and a careless global replace would
# silently corrupt that dependency's pinned version.
#
# Also refreshes web/lib/version.ts's CUR_VERSION from cur/VERSION.md's
# "Current corpus version" line -- that submodule is maintained by a
# separate team/repo and moves on its own schedule, unrelated to itch
# build numbers, so this half runs every time regardless of -BuildNumber
# (run `powershell -File sync_version.ps1` with no args any time the cur/
# submodule is updated, to pick up a new corpus version on its own).

param(
    [int]$BuildNumber = 0
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$Version = "1.0.$BuildNumber"

function Update-InFile {
    param([string]$Path, [string]$Pattern, [string]$Replacement, [string]$Label)
    $full = Join-Path $RepoRoot $Path
    $content = Get-Content -Raw -Path $full
    $updated = $content -replace $Pattern, $Replacement
    if ($updated -eq $content) {
        Write-Host "  (no change) $Label"
        return
    }
    Set-Content -Path $full -Value $updated -NoNewline
    Write-Host "  updated: $Label"
}

if ($BuildNumber -gt 0) {
    Write-Host "Syncing repo version to $Version (itch build #$BuildNumber)..."

    # README.md badge: Version-1.0.1--Alpha-blue (shields.io escapes a literal
    # "-" as "--", so the suffix after the version number reads "--Alpha").
    Update-InFile "README.md" `
        'Version-1\.0\.\d+--Alpha' `
        "Version-$Version--Alpha" `
        "README.md badge"

    # CONTRIBUTORS.md: **Version** 1.0.1-Official-Evergreen
    Update-InFile "CONTRIBUTORS.md" `
        '(\*\*Version\*\*\s+)1\.0\.\d+(-Official-Evergreen)' `
        "`${1}$Version`$2" `
        "CONTRIBUTORS.md"

    # web/package.json: top-level "version" field.
    Update-InFile "web/package.json" `
        '("version":\s*")1\.0\.\d+(")' `
        "`${1}$Version`$2" `
        "web/package.json"

    # web/package-lock.json: both the top-level and packages[""] entries are
    # anchored right after the "name": "aevoria-simulator" line, which is what
    # keeps this from touching an unrelated dependency's version.
    Update-InFile "web/package-lock.json" `
        '("name":\s*"aevoria-simulator",\s*\n\s*"version":\s*")1\.0\.\d+(")' `
        "`${1}$Version`$2" `
        "web/package-lock.json"

    # godot/export_presets.cfg: Windows exe file/product version
    # metadata (shows up in the .exe's Properties > Details tab in Explorer).
    # file_version wants the traditional 4-part Windows form.
    Update-InFile "godot/export_presets.cfg" `
        'application/file_version="[^"]*"' `
        "application/file_version=`"$Version.0`"" `
        "export_presets.cfg (file_version)"
    Update-InFile "godot/export_presets.cfg" `
        'application/product_version="[^"]*"' `
        "application/product_version=`"$Version`"" `
        "export_presets.cfg (product_version)"

    # web/lib/version.ts: APP_VERSION, shown in the front-door status bar
    # alongside the CUR corpus version, with a "Beta" label next to it.
    Update-InFile "web/lib/version.ts" `
        '(export const APP_VERSION = ")[^"]*(")' `
        "`${1}$Version`$2" `
        "web/lib/version.ts (APP_VERSION)"
} else {
    Write-Host "No -BuildNumber given: skipping the itch-build-number version bump."
}

# CUR corpus version: pulled from the cur/ submodule's own VERSION.md,
# independent of everything above. "Current corpus version: 1.2.0-Official-Evergreen"
$curVersionFile = Join-Path $RepoRoot "cur\VERSION.md"
if (Test-Path $curVersionFile) {
    $curContent = Get-Content -Raw -Path $curVersionFile
    $match = [regex]::Match($curContent, 'Current corpus version:\s*(\d+\.\d+\.\d+)')
    if ($match.Success) {
        $curVersion = $match.Groups[1].Value
        Write-Host "Syncing CUR version to $curVersion (from cur/VERSION.md)..."
        Update-InFile "web/lib/version.ts" `
            '(export const CUR_VERSION = ")[^"]*(")' `
            "`${1}$curVersion`$2" `
            "web/lib/version.ts (CUR_VERSION)"
    } else {
        Write-Host "  (skipped) could not find a corpus version line in cur/VERSION.md"
    }
} else {
    Write-Host "  (skipped) cur/VERSION.md not found -- is the cur submodule checked out?"
}

Write-Host "Version sync done."
