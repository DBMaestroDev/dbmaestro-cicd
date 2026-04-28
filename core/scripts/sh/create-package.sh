#!/usr/bin/env bash
# create-package.sh — Create a DBmaestro package (manifest + archive + upload)
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

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
PACKAGES_FOLDER="${DBMAESTRO_PACKAGES_FOLDER:-packages}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"
PACKAGE_TYPE="${DBMAESTRO_PACKAGE_TYPE:-Regular}"
IGNORE_WARNINGS="${DBMAESTRO_IGNORE_WARNINGS:-True}"

# Validate package folder exists
if [ ! -d "$PACKAGES_FOLDER/$PACKAGE_NAME" ]; then
  echo "ERROR: Folder $PACKAGE_NAME does not exist in $PACKAGES_FOLDER"
  exit 1
fi
echo "Found package folder: $PACKAGE_NAME"

# Create manifest file
echo "Creating manifest for package $PACKAGE_NAME"
java -jar "$AGENT_JAR" -CreateManifestFile \
  -PathToScriptsFolder "$PACKAGES_FOLDER/$PACKAGE_NAME" \
  -Operation "CreateOrUpdate" \
  -PackageType "$PACKAGE_TYPE"

# Create tar archive
echo "Creating tar archive from $PACKAGE_NAME"
(cd "$PACKAGES_FOLDER" && tar -cf "../${PACKAGE_NAME}.tar" "$PACKAGE_NAME")
echo "Tar archive created: ${PACKAGE_NAME}.tar"

# Create package in DBmaestro
echo "Creating package $PACKAGE_NAME in DBmaestro"
java -jar "$AGENT_JAR" -Package \
  -ProjectName "$PROJECT_NAME" \
  -IgnoreScriptWarnings "$IGNORE_WARNINGS" \
  -FilePath "${PACKAGE_NAME}.tar" \
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  -AuthType "$AUTH_TYPE" \
  -UserName "$USER" \
  -Password "$PASSWORD"

echo "Package created successfully"
echo "package_created=true"

if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
  echo "package_created=true" >> "$DBM_OUTPUT_FILE"
fi
