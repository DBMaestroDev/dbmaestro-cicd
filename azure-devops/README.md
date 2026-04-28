# Azure DevOps � DBmaestro CI/CD Library

Step templates and pipeline templates for DBmaestro package management and environment upgrades. All logic is delegated to the platform-agnostic scripts in [`core/scripts/`](../core/scripts/).

Each template supports both runner types:
- **Linux** (`useWindows: false`) � Bash via `Bash@3` task, on any Linux agent
- **Windows** (`useWindows: true`) � PowerShell via `PowerShell@2` (`pwsh`) task, on a Linux agent with `pwsh` installed **or** a native Windows agent

> Templates are referenced from the `dbmaestro-cicd` repository resource using `@dbmaestro-cicd`.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Choosing Linux vs Windows templates](#choosing-linux-vs-windows-templates)
- [Repository Resource Setup](#repository-resource-setup)
- [Step Template Reference](#step-template-reference)
- [Full Pipeline Template](#full-pipeline-template)
- [Pipeline Variables and Secrets](#pipeline-variables-and-secrets)
- [Example Pipelines](#example-pipelines)

---

## Quick Start

1. Add the `dbmaestro-cicd` repository resource to your pipeline.
2. Call the deploy template using `extends:`.

```yaml
# azure-pipelines.yml
resources:
  repositories:
    - repository: dbmaestro-cicd
      type: github
      name: DBMaestroDev/dbmaestro-cicd
      endpoint: github-dbmaestro     # your GitHub service connection
      ref: v1

extends:
  template: azure-devops/templates/deploy.yml@dbmaestro-cicd
  parameters:
    server: $(DBMAESTRO_SERVER)
    projectName: 'Demo-PSQL'
    targetEnvironment: 'Release_Source'
    agentJarPath: '/home/runner/DBmaestroAgent.jar'
    useWindows: false
    pool: 'dbmaestro-runner'
```

---

## Repository Resource Setup

Since `dbmaestro-cicd` is hosted on GitHub, use `type: github` and a GitHub service connection.

**Prerequisites:** Create a GitHub service connection in Azure DevOps under **Project Settings → Service connections → New service connection → GitHub**. Name it (e.g. `github-dbmaestro`). Azure DevOps requires a service connection to reference any external GitHub repository, even public ones.

Add this block to any pipeline that uses templates from this library:

```yaml
resources:
  repositories:
    - repository: dbmaestro-cicd
      type: github
      name: DBMaestroDev/dbmaestro-cicd
      endpoint: github-dbmaestro     # your GitHub service connection name
      ref: v1                       # or refs/tags/v1
```

Then reference templates as: `template: azure-devops/templates/<name>.yml@dbmaestro-cicd`

---

## Step Template Reference

Step templates insert one or more steps into a job. Use `- template:` inside a `steps:` block.

### `get-cli-jar.yml`

Downloads the DBmaestro agent JAR from GitHub releases.

```yaml
steps:
  - template: azure-devops/templates/get-cli-jar.yml@dbmaestro-cicd
    parameters:
      version: '26.1.0.13224'
      jarPath: '/home/runner/DBmaestroAgent.jar'
      useWindows: false
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `version` | Yes | � | JAR version, e.g. `26.1.0.13224` |
| `jarPath` | Yes | � | Destination path on the agent |
| `useWindows` | | `false` | Use PowerShell instead of Bash |

---

### `create-package.yml`

Creates a DBmaestro package from a source folder.

```yaml
steps:
  - template: azure-devops/templates/create-package.yml@dbmaestro-cicd
    parameters:
      packageName: 'V15'
      projectName: 'Demo-PSQL'
      server: $(DBMAESTRO_SERVER)
      user: $(DBMAESTRO_USER)
      password: $(DBMAESTRO_PASSWORD)
      agentJarPath: '/home/runner/DBmaestroAgent.jar'
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `packageName` | Yes | � | Package name |
| `projectName` | Yes | � | DBmaestro project name |
| `server` | Yes | � | Agent server (`host:port`) |
| `user` | Yes | � | DBmaestro username |
| `password` | Yes | � | DBmaestro password (secret variable) |
| `agentJarPath` | Yes | � | Path to agent JAR |
| `packagesFolder` | | `packages` | Root folder with package sub-directories |
| `useSsl` | | `True` | Enable SSL |
| `authType` | | `DBmaestroAccount` | Authentication type |
| `packageType` | | `Regular` | `Regular` or `AdHoc` |
| `ignoreWarnings` | | `True` | Ignore script warnings |
| `useWindows` | | `false` | Use PowerShell |

---

### `precheck-package.yml`

Validates a package using the DBmaestro PreCheck operation.

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `packageName` | Yes | � | Package name |
| `projectName` | Yes | � | DBmaestro project name |
| `server` | Yes | � | Agent server (`host:port`) |
| `user` | Yes | � | DBmaestro username |
| `password` | Yes | � | DBmaestro password (secret variable) |
| `agentJarPath` | Yes | � | Path to agent JAR |
| `useSsl` | | `True` | Enable SSL |
| `authType` | | `DBmaestroAccount` | Authentication type |
| `useWindows` | | `false` | Use PowerShell |

---

### `upgrade-environment.yml`

Upgrades a DBmaestro target environment.

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `packageName` | | `` | Package(s) to upgrade (empty = from detect) |
| `projectName` | Yes | � | DBmaestro project name |
| `targetEnvironment` | Yes | � | Environment name |
| `server` | Yes | � | Agent server (`host:port`) |
| `user` | Yes | � | DBmaestro username |
| `password` | Yes | � | DBmaestro password (secret variable) |
| `agentJarPath` | Yes | � | Path to agent JAR |
| `detectFromPush` | | `false` | Detect packages from push |
| `isPullRequest` | | `false` | Run as PR validation |
| `useSsl` | | `True` | Enable SSL |
| `authType` | | `DBmaestroAccount` | Authentication type |
| `useWindows` | | `false` | Use PowerShell |

---

### `build-from-source.yml`

Builds a package from source control.

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `packageName` | Yes | � | Package name |
| `projectName` | Yes | � | DBmaestro project name |
| `envName` | | `Dev_Env_1` | Development environment name |
| `versionType` | | `` | `Tasks`, `Specific Commit`, or empty (all) |
| `additionalInformation` | | `` | Task IDs or commit hash |
| `server` | Yes | � | Agent server (`host:port`) |
| `user` | Yes | � | DBmaestro username |
| `password` | Yes | � | DBmaestro password (secret variable) |
| `agentJarPath` | Yes | � | Path to agent JAR |
| `useSsl` | | `True` | Enable SSL |
| `authType` | | `DBmaestroAccount` | Authentication type |
| `useWindows` | | `false` | Use PowerShell |

---

### `detect-packages.yml`

Detects changed packages from git diff.

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `detectFromPush` | | `false` | Detect from push commit |
| `isPullRequest` | | `false` | Detect from PR diff |
| `baseRef` | | `` | Base branch to compare against |
| `packageName` | | `` | Manual override for package name |
| `useWindows` | | `false` | Use PowerShell |

Outputs are written to `$(Agent.TempDirectory)/detect_output.env` and published as pipeline variables with `##vso[task.setvariable]`.

---

## Full Pipeline Template

`azure-devops/templates/deploy.yml` provides a complete multi-stage pipeline.

**Stages:** `DBmaestro_Setup` ? `DBmaestro_Build` ? `DBmaestro_Deploy`

**Usage via `extends:`:**

```yaml
resources:
  repositories:
    - repository: dbmaestro-cicd
      type: github
      name: DBMaestroDev/dbmaestro-cicd
      endpoint: github-dbmaestro
      ref: v1

extends:
  template: azure-devops/templates/deploy.yml@dbmaestro-cicd
  parameters:
    server: $(DBMAESTRO_SERVER)
    projectName: 'Demo-PSQL'
    targetEnvironment: 'Release_Source'
    agentJarPath: '/home/runner/DBmaestroAgent.jar'
    dbmaestroVersion: '26.1.0.13224'
    packages:
      - name: 'V15'
      - name: 'V16'
    useWindows: false
    linuxPool: 'dbmaestro-linux'
```

**Top-level parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `server` | Yes | � | Agent server (`host:port`) |
| `projectName` | Yes | � | DBmaestro project name |
| `targetEnvironment` | Yes | � | Target environment name |
| `agentJarPath` | | `/home/runner/DBmaestroAgent.jar` | JAR path on the runner |
| `dbmaestroVersion` | | `26.1.0.13224` | JAR version to download |
| `packages` | | `[]` | List of `{name: string}` objects |
| `detectFromPush` | | `false` | Auto-detect packages from push |
| `packagesFolder` | | `packages` | Root packages folder |
| `useSsl` | | `True` | Enable SSL |
| `authType` | | `DBmaestroAccount` | Authentication type |
| `useWindows` | | `false` | Use PowerShell tasks |
| `pool` | | `dbmaestro-runner` | Self-hosted agent pool name |

---

## Choosing Linux vs Windows templates

Every step template accepts a `useWindows` boolean parameter (default `false`). Set it to `true` to use PowerShell tasks instead of Bash, and point the job at a Windows agent pool.

| `useWindows` | Task used | Shell | Agent pool |
|--------------|-----------|-------|------------|
| `false` (default) | `Bash@3` | Bash | Linux self-hosted (`dbmaestro-runner`) |
| `true` | `PowerShell@2` | `pwsh` | Linux self-hosted with `pwsh` (`dbmaestro-runner`), **or** Windows self-hosted |

### Switching a step template from Linux to Windows

Set `useWindows: true` and change the `pool:` on the enclosing job:

```yaml
# Linux (default)
jobs:
  - job: BuildPackages
    pool:
      name: dbmaestro-runner
    steps:
      - template: azure-devops/templates/create-package.yml@dbmaestro-cicd
        parameters:
          packageName: 'V15'
          projectName: 'Demo-PSQL'
          useWindows: false   # default, can be omitted
          # ...

# PowerShell on same Linux runner (or a Windows runner) � flip useWindows
jobs:
  - job: BuildPackages
    pool:
      name: dbmaestro-runner
    steps:
      - template: azure-devops/templates/create-package.yml@dbmaestro-cicd
        parameters:
          packageName: 'V15'
          projectName: 'Demo-PSQL'
          useWindows: true
          agentJarPath: '/home/runner/DBmaestroAgent.jar'
          # ...
```

> All parameter names are identical between Linux and Windows. Only `useWindows` and `agentJarPath` need to change. The `pool` stays the same when using a Linux runner with `pwsh` installed.

### Switching the full deploy pipeline to PowerShell

When using `deploy.yml` via `extends:`, set `useWindows: true`. The same `dbmaestro-runner` pool can be used if it has `pwsh` installed, or point it at a dedicated Windows pool:

```yaml
extends:
  template: azure-devops/templates/deploy.yml@dbmaestro-cicd
  parameters:
    server: $(DBMAESTRO_SERVER)
    projectName: 'Demo-PSQL'
    targetEnvironment: 'Release_Source'
    agentJarPath: '/home/runner/DBmaestroAgent.jar'
    useWindows: true
    pool: 'dbmaestro-runner'
```

---

## Pipeline Variables and Secrets

Configure in **Pipelines ? Library ? Variable groups** or directly in the pipeline UI:

| Name | Secret | Description |
|------|--------|-------------|
| `DBMAESTRO_PASSWORD` | **Yes** | DBmaestro account password |
| `DBMAESTRO_SERVER` | | Agent hostname and port, e.g. `agent01.local:8017` |
| `DBMAESTRO_USER` | | DBmaestro username |

Reference secrets in YAML as `$(DBMAESTRO_PASSWORD)` and pass them through the `env:` map on tasks to avoid leaking to logs.

---

## Example Pipelines

Ready-to-use examples are in [`examples/azure-devops/`](../examples/azure-devops/):

| File | Description |
|------|-------------|
| `azure-pipelines.yml` | Minimal starter using `deploy.yml` via `extends:` |
| `example-build-branch-name.yml` | Uses the branch/PR source branch as the package name |
| `example-build-direct-actions.yml` | Calls step templates directly with a manual parameter |
| `example-build-git-changes.yml` | Auto-detects changed packages from git diff |
| `example-build-manual-input.yml` | Manual comma-separated package list as a pipeline parameter |
| `example-build-source-control.yml` | Build from source (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Upgrade with push, PR, and manual triggers + `lockBehavior: sequential` |

### Using an example as your pipeline

Copy the relevant example file to your repository root as `azure-pipelines.yml`, point your Azure DevOps pipeline at it, and update the `parameters:` defaults to match your environment.
