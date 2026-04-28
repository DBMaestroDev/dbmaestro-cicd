# precheck-package.ps1 — Validate a DBmaestro package using precheck operation
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Name of the package to validate (required)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server hostname (required)
#   DBMAESTRO_USER            DBmaestro username (required)
#   DBMAESTRO_PASSWORD        DBmaestro password (required)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)
#
# Outputs written to DBM_OUTPUT_FILE:
#   validation_passed         true|false

$ErrorActionPreference = 'Stop'

$packageName = $env:DBMAESTRO_PACKAGE_NAME
$projectName = $env:DBMAESTRO_PROJECT_NAME
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }

foreach ($v in @($packageName, $projectName, $agentJar, $server, $user, $password)) {
    if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
}

Write-Host "Pre-checking package $packageName"
& java -jar "$agentJar" -PreCheck `
    -ProjectName "$projectName" `
    -PackageName "$packageName" `
    -Server "$server" `
    -UseSSL "$useSsl" `
    -AuthType "$authType" `
    -UserName "$user" `
    -Password "$password"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Precheck validation passed"
    Write-Host "validation_passed=true"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "validation_passed=true" }
} else {
    Write-Host "Precheck validation failed"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "validation_passed=false" }
    exit 1
}
