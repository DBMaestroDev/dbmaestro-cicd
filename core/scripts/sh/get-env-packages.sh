#!/usr/bin/env bash
# get-env-packages.sh — Retrieve the package list for a DBmaestro environment
#
# Environment variables (inputs):
#   DBMAESTRO_PROJECT_NAME    DBmaestro project name (required)
#   DBMAESTRO_ENV_NAME        DBmaestro environment name (required)
#   DBMAESTRO_AGENT_JAR       Path to DBmaestroAgent.jar (required)
#   DBMAESTRO_SERVER          DBmaestro server hostname (required)
#   DBMAESTRO_USER            DBmaestro username (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_PASSWORD        DBmaestro password (required unless DBMAESTRO_ACCESS_TOKEN_FILE_PATH is set)
#   DBMAESTRO_ACCESS_TOKEN_FILE_PATH  Path to an access-token file (optional; "none"/empty = disabled).
#                                     When set, used INSTEAD of DBMAESTRO_AUTH_TYPE/USER/PASSWORD.
#   DBMAESTRO_FILE_PATH       Output file for the retrieved package list (default: packages.json)
#   DBMAESTRO_USE_SSL         Use SSL (default: True)
#   DBMAESTRO_AUTH_TYPE       Auth type (default: DBmaestroAccount)
#
# Outputs written to DBM_OUTPUT_FILE:
#   packages_file             path to the retrieved package list file

set -e

PROJECT_NAME="${DBMAESTRO_PROJECT_NAME:?DBMAESTRO_PROJECT_NAME is required}"
ENV_NAME="${DBMAESTRO_ENV_NAME:?DBMAESTRO_ENV_NAME is required}"
AGENT_JAR="${DBMAESTRO_AGENT_JAR:?DBMAESTRO_AGENT_JAR is required}"
SERVER="${DBMAESTRO_SERVER:?DBMAESTRO_SERVER is required}"
USER="${DBMAESTRO_USER:-}"
PASSWORD="${DBMAESTRO_PASSWORD:-}"
FILE_PATH="${DBMAESTRO_FILE_PATH:-packages.json}"
USE_SSL="${DBMAESTRO_USE_SSL:-True}"
AUTH_TYPE="${DBMAESTRO_AUTH_TYPE:-DBmaestroAccount}"
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

echo "Retrieving packages for environment $ENV_NAME"
java -jar "$AGENT_JAR" -GetEnvPackages \
  -ProjectName "$PROJECT_NAME" \
  -EnvName "$ENV_NAME" \
  -FilePath "$FILE_PATH" \
  -Server "$SERVER" \
  -UseSSL "$USE_SSL" \
  "${AUTH_ARGS[@]}"

echo "Retrieved packages successfully"
echo "packages_file=$FILE_PATH"

if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
  echo "packages_file=$FILE_PATH" >> "$DBM_OUTPUT_FILE"
fi
