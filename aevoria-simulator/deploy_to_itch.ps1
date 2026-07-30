# One-command release: export the Windows release build, then push it to
# itch.io via butler (only uploads what changed, generates patches for the
# itch.io app automatically).
#
# Requires:
#   - A release GDExtension build already exists at
#     bin/libaevoria.windows.template_release.x86_64.dll (rebuild with
#     `python -m SCons platform=windows target=template_release -j4` from
#     the repo root first if the C++ side changed).
#   - butler installed and logged in (`butler login`) -- already done on
#     this machine, credentials live at ~/.config/itch/butler_creds.
#
# Usage: powershell -File deploy_to_itch.ps1

$ErrorActionPreference = "Stop"

# Adjust if Godot is installed somewhere else on this machine.
$GodotExe = "c:\Users\keefe\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe"
$ButlerExe = "c:\Users\keefe\AppData\Local\butler\butler.exe"
$ItchTarget = "aevoria-simulator/aevoria-simulator-per-avia-ad-astra:windows"
$BuildDir = Join-Path $PSScriptRoot "builds\windows-release"
$BuildExe = Join-Path $BuildDir "AevoriaSimulator.exe"

Write-Host "Exporting release build..."
& $GodotExe --headless --export-release "Windows Desktop" $BuildExe
if ($LASTEXITCODE -ne 0) { throw "Godot export failed with exit code $LASTEXITCODE" }

# Godot's export only ever writes the .exe/.dll -- copy this in every time
# rather than relying on it surviving in $BuildDir between runs, so players
# extracting the zip have a one-click way to get a desktop icon (the
# executable itself now has a real icon as of the Ascending Arc emblem
# commit, but Windows still won't put a shortcut anywhere on its own).
Copy-Item (Join-Path $PSScriptRoot "packaging\Create Desktop Shortcut.bat") $BuildDir -Force

Write-Host "Pushing to itch.io ($ItchTarget)..."
& $ButlerExe push $BuildDir $ItchTarget
if ($LASTEXITCODE -ne 0) { throw "butler push failed with exit code $LASTEXITCODE" }

# Pull the build number butler just assigned (the same number shown on the
# public itch.io page) and stamp it as "1.0.<N>" everywhere else in the repo
# that quotes a version (README badge, web/package.json, export_presets.cfg,
# etc.) -- see sync_version.ps1 at the repo root for the exact file list.
# This intentionally reads it back from `butler status` rather than trusting
# a locally-incremented counter, since butler is the actual source of truth
# for "what build is live."
Write-Host "Syncing repo version numbers to the new itch build..."
$statusJson = & $ButlerExe status $ItchTarget.Split(":")[0] --json 2>$null | Select-String '"type":"result"'
if (-not $statusJson) { throw "Could not read butler status to determine the new build number." }
$status = ($statusJson | Select-Object -Last 1).ToString() | ConvertFrom-Json
$buildNumber = ($status.value.channels | Where-Object { $_.name -eq "windows" }).head.version
powershell -File (Join-Path $PSScriptRoot "..\sync_version.ps1") -BuildNumber $buildNumber
if ($LASTEXITCODE -ne 0) { throw "sync_version.ps1 failed with exit code $LASTEXITCODE" }

Write-Host "Done. Live version: 1.0.$buildNumber -- check status with: $ButlerExe status aevoria-simulator/aevoria-simulator-per-avia-ad-astra"
