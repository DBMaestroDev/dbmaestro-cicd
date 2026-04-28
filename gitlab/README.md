# GitLab CI � DBmaestro CI/CD Library

Hidden job templates for DBmaestro package management and environment upgrades. All logic is delegated to the platform-agnostic scripts in [`core/scripts/`](../core/scripts/).

Two variants are available for every template:
- **Linux** (default) � Bash scripts, `image:` or shell executor on Linux
- **Windows** (suffix `-windows`) � PowerShell scripts, shell executor on a Linux runner with `pwsh` **or** a native Windows runner

> Templates are loaded via GitLab `include: remote:` using raw GitHub URLs from the public `DBMaestroDev/dbmaestro-cicd` repository.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Choosing Linux vs Windows templates](#choosing-linux-vs-windows-templates)
- [Template Reference](#template-reference)
- [Full Pipeline Template](#full-pipeline-template)
- [CI/CD Variables](#cicd-variables)
- [Example Pipelines](#example-pipelines)

---

## Quick Start

Add the following to your repository `.gitlab-ci.yml`:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/DBMaestroDev/dbmaestro-cicd/main/gitlab/templates/deploy.yml'

variables:
  DBMAESTRO_SERVER: 'agent01.dbmaestro.local:8017'
  DBMAESTRO_USER: 'dbm_user'
  DBMAESTRO_PROJECT_NAME: 'Demo-PSQL'
  DBMAESTRO_TARGET_ENV: 'Release_Source'
  DBMAESTRO_AGENT_JAR: '/home/runner/DBmaestroAgent.jar'
  # DBMAESTRO_PASSWORD is a masked CI/CD secret variable
```

The `deploy.yml` template provides a full pipeline with stages: `setup ? detect ? create ? validate ? deploy`.

---

## Template Reference

All templates use hidden jobs (prefixed with `.`) and are activated via `extends:`.

### `.get-cli-jar` / `.get-cli-jar-windows`

Downloads the DBmaestro agent JAR from GitHub releases.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DBMAESTRO_VERSION` | Yes | � | Agent JAR version, e.g. `26.1.0.13224` |
| `DBMAESTRO_AGENT_JAR` | Yes | � | Destination path for the JAR |

Artifact: the downloaded JAR is stored as a job artifact passed to subsequent jobs.

---

### `.detect-packages` / `.detect-packages-mr` / `.detect-packages-windows`

Detects changed packages from git diff (push or MR).

| Variable | Required | Description |
|----------|----------|-------------|
| `DETECT_FROM_PUSH` | | Set `true` to detect from the commit push diff |
| `DETECT_IS_PULL_REQUEST` | | Set `true` for MR-triggered pipelines |
| `DETECT_BASE_REF` | | Base branch to compare against |
| `DETECT_PACKAGE_NAME` | | Manually override the package name |

Output: `dotenv` artifact with `has_packages`, `packages_list`, `matrix`, `packages`.

Use `.detect-packages-mr` for merge request pipelines � it pre-sets `DETECT_IS_PULL_REQUEST=true`.

---

### `.create-package` / `.create-package-windows`

Creates a DBmaestro package from a source folder.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DBMAESTRO_PACKAGE_NAME` | Yes | � | Package name |
| `DBMAESTRO_PROJECT_NAME` | Yes | � | DBmaestro project name |
| `DBMAESTRO_PACKAGES_FOLDER` | | `packages` | Root folder with package sub-directories |
| `DBMAESTRO_PACKAGE_TYPE` | | `Regular` | `Regular` or `AdHoc` |
| `DBMAESTRO_AGENT_JAR` | Yes | � | Path to agent JAR |
| `DBMAESTRO_SERVER` | Yes | � | Server in `host:port` format |
| `DBMAESTRO_USER` | Yes | � | DBmaestro username |
| `DBMAESTRO_PASSWORD` | Yes | � | DBmaestro password (masked variable) |
| `DBMAESTRO_USE_SSL` | | `True` | Enable SSL |
| `DBMAESTRO_AUTH_TYPE` | | `DBmaestroAccount` | Authentication type |

---

### `.precheck-package` / `.precheck-package-windows`

Validates a package using the DBmaestro PreCheck operation.

Inherits the same `DBMAESTRO_*` variables as `.create-package` (minus `PACKAGES_FOLDER` and `PACKAGE_TYPE`).

Output: `dotenv` artifact with `validation_passed`.

---

### `.upgrade-environment` / `.upgrade-environment-windows`

Upgrades a DBmaestro target environment.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DBMAESTRO_TARGET_ENV` | Yes | � | Environment name to upgrade |
| `DBMAESTRO_PACKAGE_NAME` | | `` | Package(s) to upgrade (empty = from detect stage) |
| `DETECT_IS_PULL_REQUEST` | | `false` | Set `true` to run as PR/MR validation |

---

### `.build-from-source` / `.build-from-source-windows`

Builds a package from source control (all changes, tasks, or specific commit).

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DBMAESTRO_PACKAGE_NAME` | Yes | � | Package name |
| `DBMAESTRO_ENV_NAME` | | `Dev_Env_1` | Development environment name |
| `DBMAESTRO_VERSION_TYPE` | | `` | `Tasks`, `Specific Commit`, or empty |
| `DBMAESTRO_ADDITIONAL_INFORMATION` | | `` | Task IDs or commit hash |

---

## Full Pipeline Template

`gitlab/templates/deploy.yml` provides a complete multi-stage pipeline.

**Stages:** `setup` ? `detect` ? `create` ? `validate` ? `deploy`

**Required variables (project or group level):**

| Variable | Description |
|----------|-------------|
| `DBMAESTRO_SERVER` | Agent server (`host:port`) |
| `DBMAESTRO_USER` | DBmaestro username |
| `DBMAESTRO_PASSWORD` | DBmaestro password **(masked secret)** |
| `DBMAESTRO_PROJECT_NAME` | DBmaestro project name |
| `DBMAESTRO_TARGET_ENV` | Target environment name |
| `DBMAESTRO_AGENT_JAR` | Path to agent JAR on the runner |
| `DBMAESTRO_VERSION` | Agent JAR version to download |

**Pipeline trigger rules (defaults):**
- Push to default branch ? detect from push, upgrade environment
- Merge request ? detect from MR diff, create + precheck + upgrade
- Web (manual) ? all stages, uses provided variables

---

## Choosing Linux vs Windows templates

Every template has a Linux (default) and a Windows variant. The only difference is the shell used to call the `core/scripts/` scripts.

| Variant | Template suffix | Shell | Runner requirement |
|---------|----------------|-------|--------------------|
| Linux (default) | *(none)* | Bash | Any Linux runner with `image:` or shell executor |
| Windows | `-windows` | PowerShell (`pwsh`) | Linux runner with `pwsh` installed, **or** native Windows runner |
### Switching to the Windows variant

Change the `extends:` value to the `-windows` template name and set `tags:` to target a Windows runner:

```yaml
# Linux (default)
create_package:
  extends: .create-package
  tags:
    - dbmaestro-runner
  variables:
    DBMAESTRO_PACKAGE_NAME: 'V15'
    DBMAESTRO_PROJECT_NAME: 'Demo-PSQL'
    # ... other variables

# Windows � add -windows suffix; retag to a runner with pwsh installed
create_package:
  extends: .create-package-windows
  tags:
    - dbmaestro-runner
  variables:
    DBMAESTRO_PACKAGE_NAME: 'V15'
    DBMAESTRO_PROJECT_NAME: 'Demo-PSQL'
    # ... other variables
```

> All CI/CD variable names (`DBMAESTRO_*`) are identical between Linux and Windows variants. Only the `extends:` value and runner `tags:` need to change.

### Mixing Linux and Windows jobs in one pipeline

You can use different variants in different jobs � for example, detect on Linux and create on Windows:

```yaml
detect:
  extends: .detect-packages-mr
  tags: [dbmaestro-runner]

create:
  extends: .create-package-windows
  tags: [dbmaestro-runner]
  needs: [detect]
```

---

## CI/CD Variables

Set these in **Settings ? CI/CD ? Variables** at the project or group level:

| Variable | Protected | Masked | Description |
|----------|-----------|--------|-------------|
| `DBMAESTRO_PASSWORD` | Yes | **Yes** | DBmaestro account password |
| `DBMAESTRO_SERVER` | | | Agent hostname and port |
| `DBMAESTRO_USER` | | | DBmaestro username |
| `DBMAESTRO_PROJECT_NAME` | | | DBmaestro project name |
| `DBMAESTRO_AGENT_JAR` | | | JAR path on the runner |
| `DBMAESTRO_VERSION` | | | Agent JAR version |

---

## Example Pipelines

Ready-to-use examples are in [`examples/gitlab/`](../examples/gitlab/):

| File | Description |
|------|-------------|
| `.gitlab-ci.yml` | Minimal starter using `deploy.yml` |
| `example-build-branch-name.yml` | Uses the MR/branch name as the package name |
| `example-build-direct-actions.yml` | Calls templates directly with a manual variable input |
| `example-build-git-changes.yml` | Auto-detects changed packages from MR diff |
| `example-build-manual-input.yml` | Manual package list via `PACKAGE_NAMES_INPUT` variable + summary job |
| `example-build-source-control.yml` | Build from source (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Upgrade with push, MR, and web triggers + `resource_group:` serialization |

### Using an example as your pipeline

Copy the relevant example file to your repository root as `.gitlab-ci.yml` and update the variables section to match your environment.
