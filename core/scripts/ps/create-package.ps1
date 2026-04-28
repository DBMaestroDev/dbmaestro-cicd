# create-package.ps1 — Create a DBmaestro package (manifest + zip + upload)
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME        Name of the package to create (required)
#   DBMAESTRO_PROJECT_NAME        DBmaestro project name (required)
#   DBMAESTRO_AGENT_JAR           Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER              DBmaestro server hostname (required)
#   DBMAESTRO_USER                DBmaestro username (required)
#   DBMAESTRO_PASSWORD            DBmaestro password (required)
#   DBMAESTRO_PACKAGES_FOLDER     Root folder containing packages (default: packages)
#   DBMAESTRO_USE_SSL             Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE           Auth type (default: DBmaestroAccount)
#   DBMAESTRO_PACKAGE_TYPE        Package type Regular|AdHoc (default: Regular)
#   DBMAESTRO_IGNORE_WARNINGS     Ignore script warnings (default: True)
#
# Outputs written to DBM_OUTPUT_FILE:
#   package_created               true|false

$ErrorActionPreference = 'Stop'

$packageName = $env:DBMAESTRO_PACKAGE_NAME
$projectName = $env:DBMAESTRO_PROJECT_NAME
$agentJar = $env:DBMAESTRO_AGENT_JAR
$server = $env:DBMAESTRO_SERVER
$user = $env:DBMAESTRO_USER
$password = $env:DBMAESTRO_PASSWORD
$packagesFolder = if ($env:DBMAESTRO_PACKAGES_FOLDER) { $env:DBMAESTRO_PACKAGES_FOLDER } else { "packages" }
$useSsl = if ($env:DBMAESTRO_USE_SSL) { $env:DBMAESTRO_USE_SSL } else { "True" }
$authType = if ($env:DBMAESTRO_AUTH_TYPE) { $env:DBMAESTRO_AUTH_TYPE } else { "DBmaestroAccount" }
$packageType = if ($env:DBMAESTRO_PACKAGE_TYPE) { $env:DBMAESTRO_PACKAGE_TYPE } else { "Regular" }
$ignoreWarnings = if ($env:DBMAESTRO_IGNORE_WARNINGS) { $env:DBMAESTRO_IGNORE_WARNINGS } else { "True" }

foreach ($v in @('packageName','projectName','agentJar','server','user','password')) {
    if (-not (Get-Variable -Name $v -ValueOnly)) {
        Write-Host "ERROR: DBMAESTRO_$(($v -creplace '([A-Z])', '_$1').ToUpper().TrimStart('_')) is required"
        exit 1
    }
}

# Validate package folder
$packagePath = Join-Path $packagesFolder $packageName
if (-not (Test-Path -Path $packagePath -PathType Container)) {
    Write-Host "ERROR: Folder $packageName does not exist in $packagesFolder"
    exit 1
}
Write-Host "Found package folder: $packageName"

# Create manifest file
Write-Host "Creating manifest for package $packageName"
& java -jar "$agentJar" -CreateManifestFile `
    -PathToScriptsFolder "$packagePath" `
    -Operation "CreateOrUpdate" `
    -PackageType "$packageType"
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: Failed to create manifest file"; exit 1 }

# Create zip archive
$zipFile = "$packageName.zip"
$zipPath = Join-Path (Get-Location) $zipFile
Write-Host "Creating zip archive from $packageName"
if (Test-Path -Path $zipPath) { Remove-Item -Path $zipPath -Force }
Compress-Archive -Path "$packagePath\*" -DestinationPath $zipPath -CompressionLevel Optimal
$fileSize = (Get-Item -Path $zipPath).Length
Write-Host "Zip archive created: $zipFile (Size: $fileSize bytes)"

# Create package in DBmaestro
Write-Host "Creating package $packageName in DBmaestro"
& java -jar "$agentJar" -Package `
    -ProjectName "$projectName" `
    -IgnoreScriptWarnings "$ignoreWarnings" `
    -FilePath "$zipFile" `
    -Server "$server" `
    -UseSSL "$useSsl" `
    -AuthType "$authType" `
    -UserName "$user" `
    -Password "$password"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Package created successfully"
    Write-Host "package_created=true"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "package_created=true" }
} else {
    Write-Host "Failed to create package"
    if ($env:DBM_OUTPUT_FILE) { Add-Content -Path $env:DBM_OUTPUT_FILE -Value "package_created=false" }
    exit 1
}
