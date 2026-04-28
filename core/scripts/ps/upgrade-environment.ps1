# upgrade-environment.ps1 — Upgrade a DBmaestro target environment with a package
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Package name to upgrade (required)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_TARGET_ENV      Target environment name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server URL (required)
#   DBMAESTRO_USER            DBmaestro username (required)
#   DBMAESTRO_PASSWORD        DBmaestro password (required)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)

$ErrorActionPreference = 'Stop'

$packageName = $env:DBMAESTRO_PACKAGE_NAME
$projectName = $env:DBMAESTRO_PROJECT_NAME
$targetEnv = $env:DBMAESTRO_TARGET_ENV
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }

foreach ($v in @($packageName, $projectName, $targetEnv, $agentJar, $server, $user, $password)) {
    if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
}

if (-not $packageName) {
    Write-Host "No package to process"
    exit 1
}

Write-Host "==== Upgrade package on $targetEnv environment... ===="
Write-Host "==== Package name: $packageName ===="
Write-Host "==== Project name: $projectName ===="
Write-Host "==== Agent JAR: $agentJar ===="

& java -jar "$agentJar" -Upgrade `
    -ProjectName "$projectName" `
    -EnvName "$targetEnv" `
    -PackageName "$packageName" `
    -Server "$server" `
    -UseSSL "$useSsl" `
    -AuthType "$authType" `
    -UserName "$user" `
    -Password "$password"

if ($LASTEXITCODE -ne 0) {
    Write-Host "==== Upgrade failed for package: $packageName ===="
    exit 1
}
Write-Host "==== Upgrade package on $targetEnv environment completed successfully ===="
