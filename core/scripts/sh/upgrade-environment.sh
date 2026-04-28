#!/usr/bin/env bash
# upgrade-environment.sh — Upgrade a DBmaestro target environment with a package
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

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
TARGET_ENV="${DBMAESTRO_TARGET_ENV:?DBMAESTRO_TARGET_ENV is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"

if [[ -z "$PACKAGE_NAME" ]]; then
  echo "No package to process"
  exit 1
fi

echo "==== Upgrade package on $TARGET_ENV environment... ===="
echo "==== Package name: $PACKAGE_NAME ===="
echo "==== Project name: $PROJECT_NAME ===="
echo "==== Agent JAR: $AGENT_JAR ===="

java -jar "$AGENT_JAR" -Upgrade \
  -ProjectName "$PROJECT_NAME" \
  -EnvName "$TARGET_ENV" \
  -PackageName "$PACKAGE_NAME" \
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  -AuthType "$AUTH_TYPE" \
  -UserName "$USER" \
  -Password "$PASSWORD"

echo "==== Upgrade package on $TARGET_ENV environment completed successfully ===="
