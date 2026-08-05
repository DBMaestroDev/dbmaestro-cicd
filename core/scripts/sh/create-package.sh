#!/usr/bin/env bash
# create-package.sh — Create a DBmaestro package (manifest + archive + upload)
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME        Name of the package to create (required)
#   DBMAESTRO_PROJECT_NAME        DBmaestro project name (required)
#   DBMAESTRO_AGENT_JAR           Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER              DBmaestro server hostname (required)
#   DBMAESTRO_USER                DBmaestro username (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_PASSWORD            DBmaestro password (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_ACCESS_TOKEN_FILE_PATH  Path to an access-token file (optional; "none"/empty = disabled).
#                                     When set, used INSTEAD of DBMAESTRO_AUTH_TYPE/USER/PASSWORD.
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
USER="${DBMAESTRO_USER:-}"
PASSWORD="${DBMAESTRO_PASSWORD:-}"
PACKAGES_FOLDER="${DBMAESTRO_PACKAGES_FOLDER:-packages}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"
PACKAGE_TYPE="${DBMAESTRO_PACKAGE_TYPE:-Regular}"
IGNORE_WARNINGS="${DBMAESTRO_IGNORE_WARNINGS:-True}"
ACCESS_TOKEN_FILE_PATH="${DBMAESTRO_ACCESS_TOKEN_FILE_PATH:-}"
[ "$ACCESS_TOKEN_FILE_PATH" = "none" ] && ACCESS_TOKEN_FILE_PATH=""

if [ -z "$ACCESS_TOKEN_FILE_PATH" ]; then
  : "${USER:?DBMAESTRO_USER is required}"
  : "${PASSWORD:?DBMAESTRO_PASSWORD is required}"
fi

if [ -n "$ACCESS_TOKEN_FILE_PATH" ]; then
  AUTH_ARGS=(-AccessTokenFilePath "$ACCESS_TOKEN_FILE_PATH")
else
  AUTH_ARGS=(-AuthType "$AUTH_TYPE" -UserName "$USER" -Password "$PASSWORD")
fi

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
  "${AUTH_ARGS[@]}"

echo "Package created successfully"
echo "package_created=true"

if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
  echo "package_created=true" >> "$DBM_OUTPUT_FILE"
fi
