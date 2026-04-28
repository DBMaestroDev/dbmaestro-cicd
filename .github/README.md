# GitHub Actions — DBmaestro CI/CD Library

Reusable workflows and composite actions for DBmaestro package management and environment upgrades. All logic is delegated to the platform-agnostic scripts in [`core/scripts/`](../core/scripts/).

Two variants are provided:
- **`sh/`** — Bash scripts, for Linux runners
- **`ps/`** — PowerShell (`pwsh`) scripts, for Linux runners with `pwsh` installed **or** native Windows runners

> Actions are consumed from the `DBMaestroDev/github` repository using the `@v1` tag.  
> Example: `DBMaestroDev/github/.github/actions/sh/create-package@v1`

---

## Table of Contents

- [Quick Start](#quick-start)
- [Choosing sh vs ps (Linux vs Windows)](#choosing-sh-vs-ps-linux-vs-windows)
- [Reusable Workflows](#reusable-workflows)
- [Composite Actions](#composite-actions)
- [Example Pipelines](#example-pipelines)
- [Required Secrets and Variables](#required-secrets-and-variables)

---

## Quick Start

```yaml
# .github/workflows/my-build.yml
name: Build Packages
on:
  workflow_dispatch:
    inputs:
      packages:
        description: 'Package names (comma-separated)'
        required: true
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.m.outputs.matrix }}
    steps:
      - id: m
        run: |
          IFS=',' read -ra PKGS <<< "${{ inputs.packages }}"
          matrix="["; first=true
          for p in "${PKGS[@]}"; do
            p=$(echo "$p" | xargs); [ -z "$p" ] && continue
            [ "$first" = false ] && matrix="$matrix,"
            matrix="$matrix{\"package\":\"$p\"}"; first=false
          done
          echo "matrix=$matrix]" >> $GITHUB_OUTPUT
  build:
    needs: prepare
    uses: DBMaestroDev/github/.github/workflows/sh-build-validate.yml@v1
    with:
      project_name: 'Demo-PSQL'
      packages_matrix: ${{ needs.prepare.outputs.matrix }}
      runner: 'dbmaestro-linux'
      dbmaestro_server: ${{ vars.DBMAESTRO_SERVER }}
      dbmaestro_user: ${{ vars.DBMAESTRO_USER }}
    secrets:
      DBMAESTRO_PASSWORD: ${{ secrets.DBMAESTRO_PASSWORD }}
```

---

## Reusable Workflows

### `sh-build-validate.yml` — Build and Validate (Linux)

Builds and validates packages from a JSON matrix (create → precheck, sequential).

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `project_name` | Yes | — | DBmaestro project name |
| `packages_matrix` | Yes | — | JSON array e.g. `[{"package":"V15"}]` |
| `packages_folder` | | `packages` | Folder containing package sub-directories |
| `agent_jar_path` | | `/home/runner/DBmaestroAgent.jar` | Path to the DBmaestro agent JAR |
| `use_ssl` | | `True` | Enable SSL |
| `auth_type` | | `DBmaestroAccount` | Authentication type |
| `package_type` | | `Regular` | `Regular` or `AdHoc` |
| `runner` | | `dbmaestro-runner` | Runner label |
| `dbmaestro_server` | Yes | — | Server in `host:port` format |
| `dbmaestro_user` | Yes | — | DBmaestro username |

Secret required: `DBMAESTRO_PASSWORD`

---

### `sh-build-source-control.yml` — Build from Source Control (Linux)

Builds a package from source control (all changes, specific tasks, or a specific commit).

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `package_name` | Yes | — | Package name |
| `project_name` | Yes | — | DBmaestro project name |
| `environment-name` | | `Dev_Env_1` | Development environment name |
| `version_type` | | `` | `Tasks`, `Specific Commit`, or empty (all) |
| `additional_information` | | `` | Task IDs or commit hash |
| `agent_jar_path` | | `/home/runner/DBmaestroAgent.jar` | Path to JAR |
| `use_ssl` | | `True` | Enable SSL |
| `auth_type` | | `DBmaestroAccount` | Authentication type |
| `runner` | | `dbmaestro-runner` | Runner label |
| `dbmaestro_server` | Yes | — | Server in `host:port` format |
| `dbmaestro_user` | Yes | — | DBmaestro username |

Secret required: `DBMAESTRO_PASSWORD`

---

### `sh-upgrade-environment.yml` — Upgrade Environment (Linux)

Upgrades a DBmaestro target environment. Supports push detection, PR mode, and manual input.

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `package_name` | | `` | Comma-separated packages (empty = auto-detect) |
| `target_environment` | Yes | — | Environment to upgrade |
| `project_name` | | `Demo-PSQL` | DBmaestro project name |
| `agent_jar_path` | | `/home/runner/DBmaestroAgent.jar` | Path to JAR |
| `detect_from_push` | | `false` | Detect packages from the push commit |
| `is_pull_request` | | `false` | Set `true` for PR-triggered runs |
| `use_ssl` | | `True` | Enable SSL |
| `auth_type` | | `DBmaestroAccount` | Authentication type |
| `runner` | | `dbmaestro-runner` | Runner label |
| `dbmaestro_server` | Yes | — | Server in `host:port` format |
| `dbmaestro_user` | Yes | — | DBmaestro username |

Secret required: `DBMAESTRO_PASSWORD`

---

### `ps-upgrade-environment.yml` — Upgrade Environment (PowerShell)

Identical behavior to `sh-upgrade-environment.yml` but uses `pwsh`. Runs on a Linux runner with `pwsh` installed or a native Windows runner.

---

### `ps-build-validate.yml` — Build and Validate (PowerShell)

PowerShell equivalent of `sh-build-validate.yml`. Runs on a Linux runner with `pwsh` installed or a native Windows runner; calls `ps/create-package` and `ps/precheck-package` actions.

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `project_name` | Yes | — | DBmaestro project name |
| `packages_matrix` | Yes | — | JSON array e.g. `[{"package":"V15"}]` |
| `packages_folder` | | `packages` | Folder containing package sub-directories |
| `agent_jar_path` | | `/home/runner/DBmaestroAgent.jar` | Path to the DBmaestro agent JAR |
| `use_ssl` | | `True` | Enable SSL |
| `auth_type` | | `DBmaestroAccount` | Authentication type |
| `package_type` | | `Regular` | `Regular` or `AdHoc` |
| `runner` | | `dbmaestro-runner` | Runner label |
| `dbmaestro_server` | Yes | — | Server in `host:port` format |
| `dbmaestro_user` | Yes | — | DBmaestro username |

Secret required: `DBMAESTRO_PASSWORD`

---

### `ps-build-source-control.yml` — Build from Source Control (PowerShell)

PowerShell equivalent of `sh-build-source-control.yml`. Runs on a Linux runner with `pwsh` installed or a native Windows runner; calls `ps/build-from-source-control` action.

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `package_name` | Yes | — | Package name |
| `project_name` | Yes | — | DBmaestro project name |
| `environment-name` | | `Dev_Env_1` | Development environment name |
| `version_type` | | `` | `Tasks`, `Specific Commit`, or empty (all) |
| `additional_information` | | `` | Task IDs or commit hash |
| `agent_jar_path` | | `/home/runner/DBmaestroAgent.jar` | Path to JAR |
| `use_ssl` | | `True` | Enable SSL |
| `auth_type` | | `DBmaestroAccount` | Authentication type |
| `runner` | | `dbmaestro-runner` | Runner label |
| `dbmaestro_server` | Yes | — | Server in `host:port` format |
| `dbmaestro_user` | Yes | — | DBmaestro username |

Secret required: `DBMAESTRO_PASSWORD`

---

## Composite Actions

### Linux (`sh/`)

| Action | Description | Key Outputs |
|--------|-------------|-------------|
| `sh/get-cli-jar` | Downloads the DBmaestro agent JAR from GitHub releases | `download_success` |
| `sh/detect-changed-packages` | Detects changed packages from git diff, push, or manual input | `has_packages`, `packages_list`, `matrix` |
| `sh/create-package` | Creates a manifest + archive and uploads to DBmaestro | `package_created` |
| `sh/precheck-package` | Runs a DBmaestro PreCheck validation | `validation_passed` |
| `sh/upgrade-environment` | Upgrades a DBmaestro target environment | — |
| `sh/build-from-source-control` | Builds a package from source control | — |
| `sh/pr-comment` | Posts a PR comment listing detected packages | — |

### PowerShell (`ps/`)

| Action | Description | Key Outputs |
|--------|-------------|-------------|
| `ps/get-cli-jar` | Downloads the DBmaestro agent JAR via `Invoke-WebRequest` | `download_success` |
| `ps/detect-changed-packages` | Detects changed packages (PowerShell equivalent) | `has_packages`, `packages_list`, `matrix` |
| `ps/create-package` | Creates package using PowerShell | `package_created` |
| `ps/precheck-package` | Runs PreCheck validation using PowerShell | `validation_passed` |
| `ps/build-from-source-control` | Builds a package from source control using PowerShell | — |
| `ps/upgrade-environment` | Upgrades environment using PowerShell | — |
| `ps/pr-comment` | Posts PR comment | — |

### Common Inputs (create, precheck, upgrade actions)

| Input | Description |
|-------|-------------|
| `package_name` | Package name |
| `project_name` | DBmaestro project name |
| `agent_jar_path` | Path to DBmaestro agent JAR |
| `dbmaestro_server` | Server in `host:port` format |
| `dbmaestro_user` | DBmaestro username |
| `dbmaestro_password` | DBmaestro password (secret) |
| `use_ssl` | Enable SSL (`True`/`False`) |
| `auth_type` | Authentication type |

---

## Example Pipelines

Ready-to-use examples are in [`examples/github/`](../examples/github/):

| File | Description |
|------|-------------|
| `example-build-branch-name.yml` | Uses the branch/PR name as the package name |
| `example-build-direct-actions.yml` | Calls composite actions directly (no reusable workflow) |
| `example-build-git-changes.yml` | Auto-detects changed packages from git diff |
| `example-build-manual-input.yml` | Manual comma-separated package list via `workflow_dispatch` |
| `example-build-source-control.yml` | Build from source (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Upgrade with push, PR, and dispatch triggers + `concurrency:` guard |

---

## Choosing sh vs ps (Linux bash vs PowerShell)

Both variants run on a Linux runner. Use `ps/` when your team prefers PowerShell, or when the same runner also needs to run PowerShell scripts on other pipelines. A native Windows runner is also supported for either variant — just point `runs-on` at a Windows label.

| Scenario | Use | Shell | Runner requirement |
|----------|-----|-------|--------------------|
| Linux runner (any) | `sh/` actions, `sh-*` workflows | Bash | Linux |
| Linux runner with `pwsh` installed | `ps/` actions, `ps-*` workflows | PowerShell (`pwsh`) | Linux + `pwsh` |
| Native Windows runner | `ps/` actions, `ps-*` workflows | PowerShell (`pwsh`) | Windows |

The recommended default is a single self-hosted Linux runner labelled `dbmaestro-runner` with `pwsh` installed — it can run both `sh/` and `ps/` workflows without OS switching.

### Switching from Linux to Windows — composite actions

Change the action path from `sh/` to `ps/` and point `runs-on` at a Windows runner:

```yaml
# Linux (default)
- uses: DBMaestroDev/github/.github/actions/sh/create-package@v1
  with:
    package_name: V15
    ...

# Windows — just swap sh → ps
- uses: DBMaestroDev/github/.github/actions/ps/create-package@v1
  with:
    package_name: V15
    ...
```

> The input names are identical between `sh/` and `ps/` variants.

### Switching from Linux to Windows — reusable workflows

For upgrade scenarios, swap the workflow file name and runner:

```yaml
# Linux (sh — default)
jobs:
  upgrade:
    uses: DBMaestroDev/github/.github/workflows/sh-upgrade-environment.yml@v1
    with:
      runner: 'dbmaestro-runner'
      ...

# PowerShell (same runner, just swap the workflow name)
jobs:
  upgrade:
    uses: DBMaestroDev/github/.github/workflows/ps-upgrade-environment.yml@v1
    with:
      runner: 'dbmaestro-runner'
      ...
```

> `ps-build-validate` and `ps-build-source-control` workflows do not exist — for Windows build pipelines, call the `ps/` composite actions directly (see `example-build-direct-actions.yml`).

---

## Required Secrets and Variables

Configure in **Settings → Secrets and variables → Actions**:

| Name | Type | Description |
|------|------|-------------|
| `DBMAESTRO_PASSWORD` | Secret | DBmaestro account password |
| `DBMAESTRO_SERVER` | Variable | Agent hostname and port, e.g. `agent01.local:8017` |
| `DBMAESTRO_USER` | Variable | DBmaestro username |
