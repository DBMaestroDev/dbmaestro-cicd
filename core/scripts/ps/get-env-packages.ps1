# get-env-packages.ps1 — Retrieve the package list for a DBmaestro environment
#
# Environment variables (inputs):
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_ENV_NAME        DBmaestro environment name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server hostname (required)
#   DBMAESTRO_USER            DBmaestro username (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_PASSWORD        DBmaestro password (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_ACCESS_TOKEN_FILE_PATH  Path to an access-token file (optional; "none"/empty = disabled).
#                                     When set, used INSTEAD of DBMAESTRO_AUTH_TYPE/USER/PASSWORD.
#   DBMAESTRO_FILE_PATH       Output file for the retrieved package list (default: packages.json)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)
#
# Outputs written to DBM_OUTPUT_FILE:
#   packages_file             path to the retrieved package list file

$ErrorActionPreference = 'Stop'

$projectName = $env:DBMAESTRO_PROJECT_NAME
$envName = $env:DBMAESTRO_ENV_NAME
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$filePath = if ($env:DBMAESTRO_FILE_PATH) { $env:DBMAESTRO_FILE_PATH } else { "packages.json" }
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }
$accessTokenFilePath = $env:DBMAESTRO_ACCESS_TOKEN_FILE_PATH
if ($accessTokenFilePath -eq "none") { $accessTokenFilePath = "" }

foreach ($v in @($projectName, $envName, $agentJar, $server)) {
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

Write-Host "Retrieving packages for environment $envName"
& java -jar "$agentJar" -GetEnvPackages `
    -ProjectName "$projectName" `
    -EnvName "$envName" `
    -FilePath "$filePath" `
    -Server "$server" `
    -UseSSL "$useSsl" `
    @authArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Retrieved packages successfully"
    Write-Host "packages_file=$filePath"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "packages_file=$filePath" }
} else {
    Write-Host "Failed to retrieve environment packages"
    exit 1
}
