# build-from-source.ps1 — Build a DBmaestro package from source control
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME            Name of the package to build (required)
#   DBMAESTRO_PROJECT_NAME            DBmaestro project name (required)
#   DBMAESTRO_ENV_NAME                Development environment name (required)
#   DBMAESTRO_AGENT_JAR               Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER                  DBmaestro server URL (required)
#   DBMAESTRO_USER                    DBmaestro username (required)
#   DBMAESTRO_PASSWORD                DBmaestro password (required)
#   DBMAESTRO_VERSION_TYPE            Tasks or Specific Commit (default: "")
#   DBMAESTRO_ADDITIONAL_INFORMATION  Task list or commit hash (default: "")
#   DBMAESTRO_USE_SSL                 Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE               Auth type (default: DBmaestroAccount)

$ErrorActionPreference = 'Stop'

$packageName = $env:DBMAESTRO_PACKAGE_NAME
$projectName = $env:DBMAESTRO_PROJECT_NAME
$envName = $env:DBMAESTRO_ENV_NAME
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$versionType = if ($env:DBMAESTRO_VERSION_TYPE) { $env:DBMAESTRO_VERSION_TYPE } else { "" }
$additionalInfo = if ($env:DBMAESTRO_ADDITIONAL_INFORMATION) { $env:DBMAESTRO_ADDITIONAL_INFORMATION } else { "" }
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }

foreach ($v in @($packageName, $projectName, $envName, $agentJar, $server, $user, $password)) {
    if (-not $v) { Write-Host "ERROR: Required environment variable is missing"; exit 1 }
}

Write-Host "==== Building package: $packageName ===="
Write-Host "Project: $projectName"
Write-Host "Environment: $envName"
Write-Host "Version Type: $versionType"
Write-Host "Additional Information: $additionalInfo"

& java -jar "$agentJar" -Build `
    -ProjectName "$projectName" `
    -EnvName "$envName" `
    -VersionType "$versionType" `
    -AdditionalInformation "$additionalInfo" `
    -CreatePackage True `
    -PackageName "$packageName" `
    -Server "$server" `
    -UseSSL "$useSsl" `
    -AuthType "$authType" `
    -UserName "$user" `
    -Password "$password"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build package $packageName"
    exit 1
}
Write-Host "Package $packageName built successfully"
