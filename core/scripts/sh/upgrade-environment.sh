#!/usr/bin/env bash
# upgrade-environment.sh — Upgrade a DBmaestro target environment with a package
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Package name to upgrade (required unless DBMAESTRO_TAG_NAME is set)
#   DBMAESTRO_TAG_NAME        Tag name to upgrade (use instead of DBMAESTRO_PACKAGE_NAME)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_TARGET_ENV      Target environment name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server URL (required)
#   DBMAESTRO_USER            DBmaestro username (required)
#   DBMAESTRO_PASSWORD        DBmaestro password (required)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:-}"
TAG_NAME="${DBMAESTRO_TAG_NAME:-}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
TARGET_ENV="${DBMAESTRO_TARGET_ENV:?DBMAESTRO_TARGET_ENV is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"

if [ -z "$PACKAGE_NAME" ] && [ -z "$TAG_NAME" ]; then
  echo "ERROR: Either DBMAESTRO_PACKAGE_NAME or DBMAESTRO_TAG_NAME is required"
  exit 1
fi
if [ -n "$PACKAGE_NAME" ] && [ -n "$TAG_NAME" ]; then
  echo "ERROR: DBMAESTRO_PACKAGE_NAME and DBMAESTRO_TAG_NAME cannot both be set"
  exit 1
fi

echo "==== Upgrade on $TARGET_ENV environment... ===="
echo "==== Project name: $PROJECT_NAME ===="
echo "==== Agent JAR: $AGENT_JAR ===="

if [ -n "$TAG_NAME" ]; then
  echo "==== Tag name: $TAG_NAME ===="
  java -jar "$AGENT_JAR" -Upgrade \
    -ProjectName "$PROJECT_NAME" \
    -EnvName "$TARGET_ENV" \
    -TagName "$TAG_NAME" \
    -Server "$SERVER" \
    -UseSSL "$USE_SSL" \
    -AuthType "$AUTH_TYPE" \
    -UserName "$USER" \
    -Password "$PASSWORD"
else
  echo "==== Package name: $PACKAGE_NAME ===="
  java -jar "$AGENT_JAR" -Upgrade \
    -ProjectName "$PROJECT_NAME" \
    -EnvName "$TARGET_ENV" \
    -PackageName "$PACKAGE_NAME" \
    -Server "$SERVER" \
    -UseSSL "$USE_SSL" \
    -AuthType "$AUTH_TYPE" \
    -UserName "$USER" \
    -Password "$PASSWORD"
fi

echo "==== Upgrade on $TARGET_ENV environment completed successfully ===="
