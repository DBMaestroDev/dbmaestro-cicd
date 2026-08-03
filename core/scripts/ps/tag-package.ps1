# tag-package.ps1 — Add a tag to a DBmaestro package
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Package name to tag (required)
#   DBMAESTRO_TAG_TYPE_NAME   Tag type name (required, e.g. "Task")
#   DBMAESTRO_TAG_NAME        Tag name/value to apply (required)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
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
$tagTypeName = $env:DBMAESTRO_TAG_TYPE_NAME
$tagName     = $env:DBMAESTRO_TAG_NAME
$projectName = $env:DBMAESTRO_PROJECT_NAME
$agentJar    = $env:DBMAESTRO_AGENT_JAR
$server      = $env:DBMAESTRO_SERVER
$user        = $env:DBMAESTRO_USER
$password    = $env:DBMAESTRO_PASSWORD
$useSsl      = if ($env:DBMAESTRO_USE_SSL)   { $env:DBMAESTRO_USE_SSL }   else { "True" }
$authType    = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }
$accessTokenFilePath = $env:DBMAESTRO_ACCESS_TOKEN_FILE_PATH
if ($accessTokenFilePath -eq "none") { $accessTokenFilePath = "" }

foreach ($v in @($packageName, $tagTypeName, $tagName, $projectName, $agentJar, $server)) {
    if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
}
if (-not $accessTokenFilePath) {
    foreach ($v in @($user, $password)) {
        if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
    }
}

$authArgs = if ($accessTokenFilePath) {
    @("-AccessTokenFilePath", $accessTokenFilePath)
} else {
    @("-AuthType", $authType, "-UserName", $user, "-Password", $password)
}
$sslArgs = if ($accessTokenFilePath) { @() } else { @("-UseSSL", $useSsl) }

Write-Host "==== Tagging package: $packageName ===="
Write-Host "==== Project name: $projectName ===="
Write-Host "==== Tag type: $tagTypeName ===="
Write-Host "==== Tag name: $tagName ===="

& java -jar "$agentJar" -AddTag `
    -ProjectName "$projectName" `
    -PackageName "$packageName" `
    -TagTypeName "$tagTypeName" `
    -TagName "$tagName" `
    -Server "$server" `
    @sslArgs `
    @authArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "==== Tagging failed for package: $packageName ===="
    exit 1
}
Write-Host "==== Package $packageName tagged successfully ===="
