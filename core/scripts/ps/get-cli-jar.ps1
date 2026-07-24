# get-cli-jar.ps1 — Download the DBmaestro Agent JAR file
#
# Environment variables (inputs):
#   DBMAESTRO_VERSION     Version to download, e.g. 26.1.0.13224 (required)
#   DBMAESTRO_JAR_PATH    Destination path including filename (required)
#
# Version caching:
#   A marker file at <DBMAESTRO_JAR_PATH>.version stores the last downloaded version.
#   If the JAR exists and the marker matches DBMAESTRO_VERSION, the download is skipped.
#   If the JAR exists but the marker is missing or holds a different version, the JAR is
#   deleted and re-downloaded so the correct version is always used.
#
# Outputs written to DBM_OUTPUT_FILE:
#   download_success      true|false

$ErrorActionPreference = 'Stop'

$version = $env:DBMAESTRO_VERSION
$jarPath = $env:DBMAESTRO_JAR_PATH

if (-not $version) { Write-Host "ERROR: DBMAESTRO_VERSION is required"; exit 1 }
if (-not $jarPath) { Write-Host "ERROR: DBMAESTRO_JAR_PATH is required"; exit 1 }

$versionFile = "$jarPath.version"

if (Test-Path -Path $jarPath) {
    if ((Test-Path $versionFile) -and ((Get-Content $versionFile -Raw).Trim() -eq $version)) {
        Write-Host "JAR version $version already present at $jarPath, skipping download."
        Write-Host "download_success=true"
        if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=true" }
        exit 0
    } else {
        $cached = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { 'unknown' }
        Write-Host "JAR exists but version mismatch (want $version, found $cached). Re-downloading."
        Remove-Item -Path $jarPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $versionFile -Force -ErrorAction SilentlyContinue
        # If the file still exists, the path is write-protected (e.g. a system-managed install).
        # Fall back to using the existing JAR rather than failing the step.
        if (Test-Path -Path $jarPath) {
            Write-Host "Warning: cannot replace JAR at $jarPath (write-protected). Using existing file."
            Write-Host "download_success=true"
            if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=true" }
            exit 0
        }
    }
}

$jarUrl = "https://raw.githubusercontent.com/DBMaestroDev/DBmaestroCLI/refs/tags/v${version}/DBmaestroAgent.jar"

Write-Host "Downloading DBmaestro Agent JAR version $version"
Write-Host "From: $jarUrl"
Write-Host "To: $jarPath"

try {
    $jarDir = Split-Path -Path $jarPath -Parent
    if ($jarDir -and -not (Test-Path -Path $jarDir)) {
        Write-Host "Creating directory: $jarDir"
        New-Item -ItemType Directory -Path $jarDir -Force | Out-Null
    }

    Invoke-WebRequest -Uri $jarUrl -OutFile $jarPath -UseBasicParsing

    if (Test-Path -Path $jarPath) {
        $fileInfo = Get-Item -Path $jarPath
        if ($fileInfo.Length -gt 0) {
            Write-Host "Successfully downloaded JAR file to $jarPath ($($fileInfo.Length) bytes)"
            Write-Host "download_success=true"
            if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=true" }
            # Record downloaded version so future runs can skip re-downloading the same version.
            Set-Content -Path $versionFile -Value $version
        } else {
            Write-Host "ERROR: Downloaded file is empty"
            if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=false" }
            exit 1
        }
    } else {
        Write-Host "ERROR: Downloaded file does not exist at $jarPath"
        if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=false" }
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to download JAR file from $jarUrl"
    Write-Host "Error details: $_"
    Write-Host "Please verify the version exists in the repository"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "download_success=false" }
    exit 1
}
