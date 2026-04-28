#!/usr/bin/env bash
# get-cli-jar.sh — Download the DBmaestro Agent JAR file
#
# Environment variables (inputs):
#   DBMAESTRO_VERSION     Version to download, e.g. 26.1.0.13224 (required)
#   DBMAESTRO_JAR_PATH    Destination path including filename (required)
#
# Outputs written to DBM_OUTPUT_FILE:
#   download_success      true|false

set -e

VERSION="${DBMAESTRO_VERSION:?DBMAESTRO_VERSION is required}"
JAR_PATH="${DBMAESTRO_JAR_PATH:?DBMAESTRO_JAR_PATH is required}"
JAR_URL="https://raw.githubusercontent.com/DBMaestroDev/dbm_jar/refs/tags/v${VERSION}/DBmaestroAgent.jar"

echo "Downloading DBmaestro Agent JAR version ${VERSION}"
echo "From: ${JAR_URL}"
echo "To: ${JAR_PATH}"

JAR_DIR=$(dirname "${JAR_PATH}")
if [ ! -d "${JAR_DIR}" ]; then
  echo "Creating directory: ${JAR_DIR}"
  mkdir -p "${JAR_DIR}"
fi

if curl -fsSL -o "${JAR_PATH}" "${JAR_URL}"; then
  if [ -f "${JAR_PATH}" ] && [ -s "${JAR_PATH}" ]; then
    FILE_SIZE=$(stat -f%z "${JAR_PATH}" 2>/dev/null || stat -c%s "${JAR_PATH}" 2>/dev/null || echo "unknown")
    echo "Successfully downloaded JAR file to ${JAR_PATH} (${FILE_SIZE} bytes)"
    echo "download_success=true"
    if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
      echo "download_success=true" >> "$DBM_OUTPUT_FILE"
    fi
  else
    echo "ERROR: Downloaded file is empty or does not exist"
    echo "download_success=false"
    if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
      echo "download_success=false" >> "$DBM_OUTPUT_FILE"
    fi
    exit 1
  fi
else
  echo "ERROR: Failed to download JAR file from ${JAR_URL}"
  echo "Please verify the version exists in the repository"
  echo "download_success=false"
  if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
    echo "download_success=false" >> "$DBM_OUTPUT_FILE"
  fi
  exit 1
fi
