#!/usr/bin/env bash
# build-from-source.sh — Build a DBmaestro package from source control
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME            Name of the package to build (required)
#   DBMAESTRO_PROJECT_NAME            DBmaestro project name (required)
#   DBMAESTRO_ENV_NAME                Development environment name (required)
#   DBMAESTRO_AGENT_JAR               Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER                  DBmaestro server URL (required)
#   DBMAESTRO_USER                    DBmaestro username (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_PASSWORD                DBmaestro password (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_ACCESS_TOKEN_FILE_PATH  Path to an access-token file (optional; "none"/empty = disabled).
#                                     When set, used INSTEAD of DBMAESTRO_AUTH_TYPE/USER/PASSWORD.
#   DBMAESTRO_VERSION_TYPE            Tasks or Specific Commit (default: "")
#   DBMAESTRO_ADDITIONAL_INFORMATION  Task list or commit hash (default: "")
#   DBMAESTRO_USE_SSL                 Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE               Auth type (default: DBmaestroAccount)
#   DBMAESTRO_CREATE_DOWNGRADE_SCRIPTS  Create downgrade scripts (default: True)

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
ENV_NAME="${DBMAESTRO_ENV_NAME:?DBMAESTRO_ENV_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:-}"
PASSWORD="${DBMAESTRO_PASSWORD:-}"
VERSION_TYPE="${DBMAESTRO_VERSION_TYPE:-}"
ADDITIONAL_INFO="${DBMAESTRO_ADDITIONAL_INFORMATION:-}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"
CREATE_DOWNGRADE_SCRIPTS="${DBMAESTRO_CREATE_DOWNGRADE_SCRIPTS:-True}"
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

echo "==== Building package: $PACKAGE_NAME ===="
echo "Project: $PROJECT_NAME"
echo "Environment: $ENV_NAME"
echo "Version Type: $VERSION_TYPE"
echo "Additional Information: $ADDITIONAL_INFO"

java -jar "$AGENT_JAR" -Build \
  -ProjectName "$PROJECT_NAME" \
  -EnvName "$ENV_NAME" \
  -VersionType "$VERSION_TYPE" \
  -AdditionalInformation "$ADDITIONAL_INFO" \
  -CreatePackage True \
  -PackageName "$PACKAGE_NAME" \
  -CreateDowngradeScripts $CREATE_DOWNGRADE_SCRIPTS \
  -Server "$SERVER" \
  -UseSSL $USE_SSL \
  "${AUTH_ARGS[@]}"

echo "Package $PACKAGE_NAME built successfully"
