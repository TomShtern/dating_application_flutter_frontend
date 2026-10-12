#Requires -Version 7
<#
.SYNOPSIS
Ships a Dart-only fix to phones already running the current release, with no
installer: shorebird patch.
.DESCRIPTION
Builds the app the same way release.ps1 did (same version, same defines) and
sends only the changed Dart code to Shorebird. Phones download it in the
background (lib/features/updates/app_update_provider.dart), show "Update
ready", and run it after the Restart button or the next full start. Nothing
goes to GitHub, and pubspec.yaml is not touched: a patch belongs to the release
named in pubspec.yaml, which release.ps1 writes last.

A patch cannot carry native code, plugins, the manifest, or assets. Shorebird
refuses those changes and so does this script (no --allow-native-diffs, no
--allow-asset-diffs); cut a full release with .\scripts\release.ps1 instead.

From the repository root: .\scripts\patch.ps1
.PARAMETER EnvFile
The same Dart defines the release was built with. Defaults to .env.release.
.PARAMETER DryRun
Builds and validates the patch (shorebird patch --dry-run) without uploading it.
#>
[CmdletBinding()]
param(
    [string]$EnvFile = '.env.release',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$app = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pubspec = Join-Path $app 'pubspec.yaml'

. (Join-Path $PSScriptRoot 'release_env.ps1')
$defines = Resolve-ReleaseEnvFile -App $app -EnvFile $EnvFile

# release.ps1 writes the new version last, so pubspec.yaml names the release
# that is out on phones.
if ((Get-Content $pubspec -Raw) -notmatch '(?m)^version:[ \t]*(?<Name>\d+\.\d+\.\d+)\+(?<Build>\d+)(?=\s|$)') {
    throw 'pubspec.yaml needs a version like 1.0.0+1.'
}
$versionName = $Matches.Name
$build = $Matches.Build
Write-Host "Patching release $versionName (build $build)"

# shorebird.bat forwards only nine arguments and re-splits "--define=a=b", so
# the script behind it is called directly, in this session so its exit code
# survives (see release.ps1).
$shorebird = Join-Path $HOME '.shorebird\bin\shorebird.ps1'
if (-not (Test-Path $shorebird)) { throw "Shorebird CLI not found at $shorebird." }

# The release is arm64 only; a patch built for every CPU type is refused as an
# asset difference once a plugin ships a native library per CPU type.
$shorebirdArgs = @(
    'patch', '--platforms', 'android',
    '--release-version', "$versionName+$build",
    '--build-name', $versionName, '--build-number', $build,
    '--dart-define-from-file', $defines
)
if ($DryRun) { $shorebirdArgs += '--dry-run' }
$shorebirdArgs += @('--', '--target-platform', 'android-arm64')
Push-Location $app
try {
    & $shorebird @shorebirdArgs
    $shorebirdExit = $LASTEXITCODE
} finally {
    Pop-Location
}
if ($shorebirdExit -ne 0) { throw "shorebird patch failed (exit $shorebirdExit); see its output above." }
if ($DryRun) { Write-Host 'Dry run: the patch built and validated; nothing was published.' }
else { Write-Host "Patch published for $versionName+$build. Phones download it on next launch and offer a Restart." }
