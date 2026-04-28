#!/usr/bin/env bash
# build-from-source.sh — Build a DBmaestro package from source control
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

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
ENV_NAME="${DBMAESTRO_ENV_NAME:?DBMAESTRO_ENV_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
VERSION_TYPE="${DBMAESTRO_VERSION_TYPE:-}"
ADDITIONAL_INFO="${DBMAESTRO_ADDITIONAL_INFORMATION:-}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"

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
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  -AuthType "$AUTH_TYPE" \
  -UserName "$USER" \
  -Password "$PASSWORD"

echo "Package $PACKAGE_NAME built successfully"
