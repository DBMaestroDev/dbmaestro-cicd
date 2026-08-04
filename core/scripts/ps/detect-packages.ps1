# detect-packages.ps1 — Detect changed DBmaestro packages from git diff or manual input
#
# Environment variables (inputs):
#   DETECT_IS_PULL_REQUEST   true|false   Detect changed files between base and HEAD (PR mode)
#   DETECT_BASE_REF          string       Base branch for PR diff (optional)
#   DETECT_FROM_PUSH         true|false   Detect changed files from last push commit
#   DETECT_PACKAGE_NAME      string       Comma-separated package names (manual input)
#   DETECT_TAG_NAME          string       Tag name for tag-based upgrade (bypasses git diff detection)
#   DETECT_PACKAGES_FOLDER   string       Root folder packages live under (default: "packages")
#
# Outputs written to DBM_OUTPUT_FILE (key=value pairs):
#   has_packages             true|false
#   packages_list            comma-separated list (or "None")
#   packages                 JSON array
#   matrix                   JSON array of {"package":"<name>"} objects

$ErrorActionPreference = 'Stop'

$packages = @()
$isPullRequest = $env:DETECT_IS_PULL_REQUEST -eq "true"
$detectFromPush = $env:DETECT_FROM_PUSH -eq "true"
$baseRef = $env:DETECT_BASE_REF
$packageName = $env:DETECT_PACKAGE_NAME
$tagName = $env:DETECT_TAG_NAME
$outputFile = $env:DBM_OUTPUT_FILE
$packagesFolder = if ($env:DETECT_PACKAGES_FOLDER) { $env:DETECT_PACKAGES_FOLDER } else { "packages" }
$packagePattern = '^' + [regex]::Escape($packagesFolder) + '/([^/]+)'

if ($tagName) {
    Write-Host "Tag input: $tagName"
    # Tag-based upgrade: no package detection needed; the upgrade script uses the tag directly.
    $hasPackages = "true"
    $packagesList = $tagName
    $matrixJson = '[{"package":""}]'
    $packagesJson = "[]"
    Write-Host "has_packages=$hasPackages"
    Write-Host "packages_list=$packagesList"
    Write-Host "matrix=$matrixJson"
    Write-Host "packages=$packagesJson"
    if ($outputFile) {
        Add-Content -Path $outputFile -Value "has_packages=$hasPackages"
        Add-Content -Path $outputFile -Value "packages_list=$packagesList"
        Add-Content -Path $outputFile -Value "matrix=$matrixJson"
        Add-Content -Path $outputFile -Value "packages=$packagesJson"
    }
    exit 0
}

if ($isPullRequest) {
    Write-Host "Detecting packages for Pull Request"
    if ($baseRef) {
        $changedFiles = git diff --name-only "origin/$baseRef" HEAD
    } else {
        $changedFiles = git diff --name-only HEAD~1 HEAD
    }
    $LASTEXITCODE = 0   # a failed/empty diff means "no packages", not a script failure - see detectFromPush below
    Write-Host "Changed files: $($changedFiles -join ', ')"

    foreach ($file in $changedFiles) {
        if ($file -match $packagePattern) {
            $pkg = $matches[1]
            if ($pkg -notin $packages) {
                $packages += $pkg
            }
        }
    }
} elseif ($packageName) {
    Write-Host "Package input: $packageName"
    $packages = $packageName -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
} elseif ($detectFromPush) {
    $changedFiles = git diff --name-only HEAD~1 HEAD
    $LASTEXITCODE = 0   # a failed/empty diff (e.g. single-commit history) means "no packages", not a script failure
    Write-Host "Changed files: $($changedFiles -join ', ')"

    foreach ($file in $changedFiles) {
        if ($file -match $packagePattern) {
            $pkg = $matches[1]
            if ($pkg -notin $packages) {
                $packages += $pkg
            }
        }
    }
} elseif ($baseRef) {
    Write-Host "Detecting packages by comparing to base ref: $baseRef"
    $changedFiles = git diff --name-only "origin/$baseRef" HEAD
    $LASTEXITCODE = 0   # a failed/empty diff (e.g. origin/$baseRef not resolvable in this checkout) means "no packages", not a script failure
    Write-Host "Changed files: $($changedFiles -join ', ')"

    foreach ($file in $changedFiles) {
        if ($file -match $packagePattern) {
            $pkg = $matches[1]
            if ($pkg -notin $packages) {
                $packages += $pkg
            }
        }
    }
}

$packages = $packages | Sort-Object

if ($packages.Count -eq 0) {
    Write-Host "No packages detected"
    $hasPackages = "false"
    $packagesList = "None"
    $matrixJson = '[{"package":""}]'
    $packagesJson = "[]"
} else {
    Write-Host "Detected packages: $($packages -join ', ')"
    $hasPackages = "true"
    $packagesList = $packages -join ", "

    $matrixObjects = $packages | ForEach-Object { [PSCustomObject]@{package = $_} }
    if (@($matrixObjects).Count -eq 1) {
        $matrixJson = "[$((@($matrixObjects) | ConvertTo-Json -Compress))]"
    } else {
        $matrixJson = @($matrixObjects) | ConvertTo-Json -Compress
    }

    if ($packages.Count -eq 1) {
        $packagesJson = "[$($packages[0] | ConvertTo-Json -Compress)]"
    } else {
        $packagesJson = $packages | ConvertTo-Json -Compress
    }
}

Write-Host "has_packages=$hasPackages"
Write-Host "packages_list=$packagesList"
Write-Host "matrix=$matrixJson"
Write-Host "packages=$packagesJson"

if ($outputFile) {
    Add-Content -Path $outputFile -Value "has_packages=$hasPackages"
    Add-Content -Path $outputFile -Value "packages_list=$packagesList"
    Add-Content -Path $outputFile -Value "matrix=$matrixJson"
    Add-Content -Path $outputFile -Value "packages=$packagesJson"
}
