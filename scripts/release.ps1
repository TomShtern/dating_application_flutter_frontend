#Requires -Version 7
<#
.SYNOPSIS
Builds a signed release APK through Shorebird and publishes it for the in-app
"Update available" banner. A full release is only needed for native changes;
Dart fixes go out with .\scripts\patch.ps1.
.DESCRIPTION
Bumps the version (patch and build number), runs shorebird release (which
builds an APK signed with the release key and registers it as the base for
later patches), uploads the APK to a GitHub release, and only then publishes
latest.json and marks the release as the latest one, so phones never see a link
to a half-uploaded file. The new version is written back to pubspec.yaml after
the publish succeeds.

Needs, once: android\key.properties (the release signing key), a Shorebird
login (shorebird login), a GitHub login (gh auth login), and an env file with
the release build's Dart defines.

From the repository root: .\scripts\release.ps1 -Notes 'What changed'
.PARAMETER Notes
Short changelog stored in latest.json and shown in the banner.
.PARAMETER VersionName
Overrides the automatic patch bump, e.g. 1.1.0.
.PARAMETER EnvFile
The Dart defines for the release build, in .env format. Defaults to
.env.release (gitignored). Its DATING_APP_API_BASE_URL must be https: release
builds refuse cleartext HTTP.
.PARAMETER DryRun
Builds the APK (shorebird release --dry-run) and writes latest.json next to
it, then stops: no Shorebird release is registered, nothing is uploaded and
pubspec.yaml is left alone.
#>
[CmdletBinding()]
param(
    [string]$Notes = '',
    [ValidatePattern('^\d+\.\d+\.\d+$')][string]$VersionName,
    [string]$EnvFile = '.env.release',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

# Keep equal to latestReleaseManifestUrl in
# lib/features/updates/app_release_provider.dart.
$releaseRepo = 'TomShtern/dating_application_flutter_frontend'
# The Flutter version Shorebird builds with. Patches reuse their release's
# version, so this only changes when a new release is cut.
$shorebirdFlutter = '3.47.2'

$app = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pubspec = Join-Path $app 'pubspec.yaml'

if (-not (Test-Path (Join-Path $app 'android\key.properties'))) {
    throw 'No release key (android\key.properties). A debug-signed APK cannot update a release install.'
}
if (-not (Test-Path (Join-Path $app 'shorebird.yaml'))) {
    throw 'No shorebird.yaml. Run shorebird init in this folder first.'
}
. (Join-Path $PSScriptRoot 'release_env.ps1')
$defines = Resolve-ReleaseEnvFile -App $app -EnvFile $EnvFile

$pubspecText = Get-Content $pubspec -Raw
if ($pubspecText -notmatch '(?m)^version:[ \t]*(?<Major>\d+)\.(?<Minor>\d+)\.(?<Patch>\d+)\+(?<Build>\d+)(?=\s|$)') {
    throw 'pubspec.yaml needs a version like 1.0.0+1.'
}
$build = [int]$Matches.Build + 1
if (-not $VersionName) { $VersionName = "$($Matches.Major).$($Matches.Minor).$([int]$Matches.Patch + 1)" }
$oldVersionLine = $Matches[0]
$tag = "v$build"
Write-Host "Releasing $VersionName (build $build) to github.com/$releaseRepo"

# shorebird.bat forwards only nine arguments and re-splits "--define=a=b", so
# the script behind it is called directly, in this session: through
# pwsh -File its exit code is lost.
$shorebird = Join-Path $HOME '.shorebird\bin\shorebird.ps1'
if (-not (Test-Path $shorebird)) { throw "Shorebird CLI not found at $shorebird." }
$apk = Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk'
# Also checked below, so a leftover APK from an earlier build cannot pass for
# a new one.
Remove-Item $apk -ErrorAction SilentlyContinue

# Built with Shorebird's Flutter, so the app can receive Dart patches. This
# also registers the build as a Shorebird release (the base that patch.ps1
# patches); with -DryRun it builds and validates but registers nothing. If a
# later step fails after the registration, this version exists on Shorebird
# and a rerun needs -VersionName with a higher version.
$shorebirdArgs = @(
    'release', 'android', '--artifact', 'apk', '--target-platform', 'android-arm64',
    '--flutter-version', $shorebirdFlutter,
    '--build-name', $VersionName, '--build-number', $build,
    '--dart-define-from-file', $defines
)
if ($DryRun) { $shorebirdArgs += '--dry-run' }
Push-Location $app
try {
    & $shorebird @shorebirdArgs
    $shorebirdExit = $LASTEXITCODE
} finally {
    Pop-Location
}
# Nothing may be uploaded unless Shorebird registered the release too: a build
# with no Shorebird release behind it can never be patched.
if ($shorebirdExit -ne 0) { throw "shorebird release failed (exit $shorebirdExit); see its output above. Nothing was uploaded." }
if (-not (Test-Path $apk)) { throw 'shorebird release did not produce an APK; see its output above.' }

$apkName = "dating-app-$build.apk"
$apkUrl = "https://github.com/$releaseRepo/releases/download/$tag/$apkName"
$outDir = Split-Path $apk
$namedApk = Join-Path $outDir $apkName
$manifest = Join-Path $outDir 'latest.json'
Copy-Item $apk $namedApk -Force
[System.IO.File]::WriteAllText($manifest, (
    [ordered]@{
        versionCode = $build
        versionName = $VersionName
        apkUrl = $apkUrl
        # The app checks the download against this before opening the installer.
        sha256 = (Get-FileHash $apk -Algorithm SHA256).Hash.ToLowerInvariant()
        notes = $Notes
    } | ConvertTo-Json
), [System.Text.UTF8Encoding]::new($false))

if ($DryRun) {
    Remove-Item $namedApk -ErrorAction SilentlyContinue
    Write-Host "Dry run: built $apk"
    Write-Host "Would publish $manifest as:"
    Get-Content $manifest
    Write-Host 'Nothing was uploaded and pubspec.yaml is unchanged.'
    return
}

try {
    # A prerelease is never "latest", so phones cannot see the release until
    # both files are up.
    $releaseNotes = if ($Notes) { $Notes } else { "Build $build" }
    & gh release create $tag --repo $releaseRepo --prerelease --title "$VersionName (build $build)" --notes $releaseNotes
    if ($LASTEXITCODE -ne 0) { throw "Could not create GitHub release $tag." }
    # APK first, manifest last.
    & gh release upload $tag $namedApk --repo $releaseRepo
    if ($LASTEXITCODE -ne 0) { throw 'APK upload failed.' }
    $head = Invoke-WebRequest -Uri $apkUrl -Method Head
    if ($head.StatusCode -ne 200) { throw "Uploaded APK is not reachable at $apkUrl." }
    & gh release upload $tag $manifest --repo $releaseRepo
    if ($LASTEXITCODE -ne 0) { throw 'latest.json upload failed.' }
    & gh release edit $tag --repo $releaseRepo --prerelease=false --latest
    if ($LASTEXITCODE -ne 0) { throw "Could not mark $tag as the latest release." }
} finally {
    Remove-Item $namedApk, $manifest -ErrorAction SilentlyContinue
}

# Read it back the way the app does, past any cached copy.
$verificationTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$published = Invoke-RestMethod -Uri "https://github.com/$releaseRepo/releases/latest/download/latest.json?t=$verificationTime"
if ($published.versionCode -ne $build) {
    throw "latest.json says build $($published.versionCode), expected $build. Check the releases page."
}

$newVersionLine = "version: $VersionName+$build"
Set-Content -Path $pubspec -Value $pubspecText.Replace($oldVersionLine, $newVersionLine) -NoNewline
Write-Host "Published $VersionName (build $build): $apkUrl"
Write-Host "pubspec.yaml now says $newVersionLine. Phones on an older build will offer the update on next launch."
