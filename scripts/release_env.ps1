#Requires -Version 7
# Shared by release.ps1 and patch.ps1: checks the env file a release build is
# compiled with and returns its full path. Never prints a value from it.

function Resolve-ReleaseEnvFile {
    param(
        [Parameter(Mandatory)][string]$App,
        [Parameter(Mandatory)][string]$EnvFile
    )

    $path = if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $App $EnvFile }
    if (-not (Test-Path $path)) {
        throw "No env file at $path. Copy .env.example to it and fill in the release values."
    }

    $values = @{}
    foreach ($line in Get-Content $path) {
        if ($line -match '^\s*(?<Key>[A-Z0-9_]+)\s*=\s*(?<Value>.*)$') {
            $values[$Matches.Key] = $Matches.Value.Trim().Trim('"').Trim("'")
        }
    }

    foreach ($key in 'DATING_APP_API_BASE_URL', 'DATING_APP_SHARED_SECRET', 'CLERK_PUBLISHABLE_KEY') {
        if (-not $values[$key]) { throw "$EnvFile has no $key." }
    }
    # Release builds refuse cleartext HTTP, so anything else cannot reach the
    # backend from an installed app.
    if ($values['DATING_APP_API_BASE_URL'] -notmatch '^https://') {
        throw "$EnvFile needs an https DATING_APP_API_BASE_URL; release builds cannot use http."
    }
    if ($values['CLERK_PUBLISHABLE_KEY'] -notmatch '^pk_') {
        throw "$EnvFile needs a Clerk publishable key (pk_...). Never a secret key."
    }
    # These are test logins; a define is readable inside a distributed APK.
    if ($values['CLERK_TEST_ACCOUNTS']) {
        throw "$EnvFile sets CLERK_TEST_ACCOUNTS. Remove it: test passwords must not ship in a release."
    }

    return (Resolve-Path $path).Path
}
