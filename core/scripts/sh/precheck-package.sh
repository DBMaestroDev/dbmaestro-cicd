#!/usr/bin/env bash
# precheck-package.sh — Validate a DBmaestro package using precheck operation
#
# Environment variables (inputs):
#   DBMAESTRO_PACKAGE_NAME    Name of the package to validate (required)
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server hostname (required)
#   DBMAESTRO_USER            DBmaestro username (required)
#   DBMAESTRO_PASSWORD        DBmaestro password (required)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)
#
# Outputs written to DBM_OUTPUT_FILE:
#   validation_passed         true|false

set -e

PACKAGE_NAME="${DBMAESTRO_PACKAGE_NAME:?DBMAESTRO_PACKAGE_NAME is required}"
PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:?DBMAESTRO_USER is required}"
PASSWORD="${DBMAESTRO_PASSWORD:?DBMAESTRO_PASSWORD is required}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"

echo "Pre-checking package $PACKAGE_NAME"
java -jar "$AGENT_JAR" -PreCheck \
  -ProjectName "$PROJECT_NAME" \
  -PackageName "$PACKAGE_NAME" \
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  -AuthType "$AUTH_TYPE" \
  -UserName "$USER" \
  -Password "$PASSWORD"

echo "Precheck validation passed"
echo "validation_passed=true"

if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
  echo "validation_passed=true" >> "$DBM_OUTPUT_FILE"
fi
