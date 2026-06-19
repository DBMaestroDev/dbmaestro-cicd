#!/usr/bin/env bash
# tag-package.sh — Add a tag to a DBmaestro package
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Package name to tag (required)
#   DBMAESTRO_TAG_TYPE_NAME   Tag type name (required, e.g. "Task")
#   DBMAESTRO_TAG_NAME        Tag name/value to apply (required)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server URL (required)
#   DBMAESTRO_USER            DBmaestro username (required)
#   DBMAESTRO_PASSWORD        DBmaestro password (required)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
TAG_TYPE_NAME="${DBMAESTRO_TAG_TYPE_NAME:?DBMAESTRO_TAG_TYPE_NAME is required}"
TAG_NAME="${DBMAESTRO_TAG_NAME:?DBMAESTRO_TAG_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"

echo "==== Tagging package: $PACKAGE_NAME ===="
echo "==== Project name: $PROJECT_NAME ===="
echo "==== Tag type: $TAG_TYPE_NAME ===="
echo "==== Tag name: $TAG_NAME ===="

java -jar "$AGENT_JAR" -AddTag \
  -ProjectName "$PROJECT_NAME" \
  -PackageName "$PACKAGE_NAME" \
  -TagTypeName "$TAG_TYPE_NAME" \
  -TagName "$TAG_NAME" \
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  -AuthType "$AUTH_TYPE" \
  -UserName "$USER" \
  -Password "$PASSWORD"

echo "==== Package $PACKAGE_NAME tagged successfully ===="
