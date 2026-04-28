#!/usr/bin/env bash
# detect-packages.sh — Detect changed DBmaestro packages from git diff or manual input
#
# Environment variables (inputs):
#   DETECT_IS_PULL_REQUEST   true|false   Detect changed files between base and HEAD (PR mode)
#   DETECT_BASE_REF          string       Base branch for PR diff (optional)
#   DETECT_FROM_PUSH         true|false   Detect changed files from last push commit
#   DETECT_PACKAGE_NAME      string       Comma-separated package names (manual input)
#
# Outputs written to DBM_OUTPUT_FILE (key=value pairs, compatible with GITHUB_OUTPUT / dotenv):
#   has_packages             true|false
#   packages_list            comma-separated list (or "None")
#   packages                 JSON array
#   matrix                   JSON array of {"package":"<name>"} objects

set -e

declare -a packages

is_pull_request="${DETECT_IS_PULL_REQUEST:-false}"
detect_from_push="${DETECT_FROM_PUSH:-false}"
base_ref="${DETECT_BASE_REF:-}"
package_name="${DETECT_PACKAGE_NAME:-}"

if [[ "$is_pull_request" == "true" ]]; then
  echo "Detecting packages for Pull Request"
  if [[ -n "$base_ref" ]]; then
    changed_files=$(git diff --name-only "origin/$base_ref" HEAD)
  else
    changed_files=$(git diff --name-only HEAD~1 HEAD)
  fi
  echo "Changed files: $changed_files"

  while IFS= read -r file; do
    if [[ "$file" =~ ^packages/([^/]+) ]]; then
      pkg="${BASH_REMATCH[1]}"
      if [[ ! " ${packages[*]} " =~ " ${pkg} " ]]; then
        packages+=("$pkg")
      fi
    fi
  done <<< "$changed_files"

elif [[ -n "$package_name" ]]; then
  echo "Package input: $package_name"
  IFS=',' read -ra pkg_array <<< "$package_name"
  for pkg in "${pkg_array[@]}"; do
    pkg=$(echo "$pkg" | xargs)
    if [[ -n "$pkg" ]]; then
      packages+=("$pkg")
    fi
  done

elif [[ "$detect_from_push" == "true" ]]; then
  changed_files=$(git diff --name-only HEAD~1 HEAD)
  echo "Changed files: $changed_files"

  while IFS= read -r file; do
    if [[ "$file" =~ ^packages/([^/]+) ]]; then
      pkg="${BASH_REMATCH[1]}"
      if [[ ! " ${packages[*]} " =~ " ${pkg} " ]]; then
        packages+=("$pkg")
      fi
    fi
  done <<< "$changed_files"
fi

# Sort alphabetically
if [[ ${#packages[@]} -gt 0 ]]; then
  IFS=$'\n' packages=($(sort <<<"${packages[*]}"))
  unset IFS
fi

if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No packages detected"
  has_packages="false"
  packages_list="None"
  matrix='[{"package":""}]'
  packages_json="[]"
else
  echo "Detected packages: ${packages[*]}"
  has_packages="true"

  packages_list=$(IFS=', '; echo "${packages[*]}")

  matrix="["
  first=true
  for pkg in "${packages[@]}"; do
    [[ "$first" == "true" ]] && first=false || matrix+=","
    matrix+="{\"package\":\"$pkg\"}"
  done
  matrix+="]"

  packages_json="["
  first=true
  for pkg in "${packages[@]}"; do
    [[ "$first" == "true" ]] && first=false || packages_json+=","
    packages_json+="\"$pkg\""
  done
  packages_json+="]"
fi

echo "has_packages=$has_packages"
echo "packages_list=$packages_list"
echo "matrix=$matrix"
echo "packages=$packages_json"

if [[ -n "${DBM_OUTPUT_FILE:-}" ]]; then
  echo "has_packages=$has_packages" >> "$DBM_OUTPUT_FILE"
  echo "packages_list=$packages_list" >> "$DBM_OUTPUT_FILE"
  echo "matrix=$matrix" >> "$DBM_OUTPUT_FILE"
  echo "packages=$packages_json" >> "$DBM_OUTPUT_FILE"
fi
