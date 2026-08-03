# upgrade-environment.ps1 — Upgrade a DBmaestro target environment with a package
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Package name to upgrade (required unless DBMAESTRO_TAG_NAME is set)
#   DBMAESTRO_TAG_NAME        Tag name to upgrade (use instead of DBMAESTRO_PACKAGE_NAME)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_TARGET_ENV      Target environment name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server URL (required)
#   DBMAESTRO_USER            DBmaestro username (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_PASSWORD        DBmaestro password (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_ACCESS_TOKEN_FILE_PATH  Path to an access-token file (optional; "none"/empty = disabled).
#                                     When set, used INSTEAD of DBMAESTRO_AUTH_TYPE/USER/PASSWORD.
#   DBMAESTRO_USE_SSL         Use SSL (default: True; ignored when DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)

$ErrorActionPreference = 'Stop'

$packageName = $env:DBMAESTRO_PACKAGE_NAME
$tagName = $env:DBMAESTRO_TAG_NAME
if ($packageName -eq "none") { $packageName = "" }
if ($tagName -eq "none") { $tagName = "" }
$projectName = $env:DBMAESTRO_PROJECT_NAME
$targetEnv = $env:DBMAESTRO_TARGET_ENV
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }
$accessTokenFilePath = $env:DBMAESTRO_ACCESS_TOKEN_FILE_PATH
if ($accessTokenFilePath -eq "none") { $accessTokenFilePath = "" }

foreach ($v in @($projectName, $targetEnv, $agentJar, $server)) {
    if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
}
if (-not $accessTokenFilePath) {
    foreach ($v in @($user, $password)) {
        if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
    }
}

if (-not $packageName -and -not $tagName) {
    Write-Host "ERROR: Either DBMAESTRO_PACKAGE_NAME or DBMAESTRO_TAG_NAME is required"
    exit 1
}
if ($packageName -and $tagName) {
    Write-Host "ERROR: DBMAESTRO_PACKAGE_NAME and DBMAESTRO_TAG_NAME cannot both be set"
    exit 1
}

$authArgs = if ($accessTokenFilePath) {
    @("-AccessTokenFilePath", $accessTokenFilePath)
} else {
    @("-AuthType", $authType, "-UserName", $user, "-Password", $password)
}
$sslArgs = if ($accessTokenFilePath) { @() } else { @("-UseSSL", $useSsl) }

Write-Host "==== Upgrade on $targetEnv environment... ===="
Write-Host "==== Project name: $projectName ===="
Write-Host "==== Agent JAR: $agentJar ===="

if ($tagName) {
    Write-Host "==== Tag name: $tagName ===="
    & java -jar "$agentJar" -Upgrade `
        -ProjectName "$projectName" `
        -EnvName "$targetEnv" `
        -TagName "$tagName" `
        -Server "$server" `
        @sslArgs `
        @authArgs
} else {
    Write-Host "==== Package name: $packageName ===="
    & java -jar "$agentJar" -Upgrade `
        -ProjectName "$projectName" `
        -EnvName "$targetEnv" `
        -PackageName "$packageName" `
        -Server "$server" `
        @sslArgs `
        @authArgs
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "==== Upgrade failed ===="
    exit 1
}
Write-Host "==== Upgrade on $targetEnv environment completed successfully ===="
