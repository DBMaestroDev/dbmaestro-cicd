# GitLab CI — Setup Guide

This guide walks through everything needed to run the DBmaestro example pipelines in this folder on GitLab CI.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Configure CI/CD Variables](#step-1--configure-cicd-variables)
- [Step 2 — Configure a GitLab Runner](#step-2--configure-a-gitlab-runner)
- [Step 3 — Configure Merge Request Approvals](#step-3--configure-merge-request-approvals)
- [Step 4 — Add the Pipeline to Your Repository](#step-4--add-the-pipeline-to-your-repository)
- [Example Pipelines](#example-pipelines)
- [Pipeline Reference — Integrated Workflow Pattern](#pipeline-reference--integrated-workflow-pattern)
- [Approval Gate for Production Upgrades](#approval-gate-for-production-upgrades)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| GitLab runner | Self-hosted runner registered to your project or group. Tag it to match `RUNNER_TAG` (default: `dbmaestro-runner`). |
| DBmaestro server | Accessible from the runner. Note the hostname and port (e.g. `agent01.local:8017`). |
| DBmaestro credentials | Username and password for the account that will create/upgrade packages. |
| GitLab repository | The repository containing your `packages/` folder with DBmaestro package sub-directories. |
| Internet access on runner | Required to download the DBmaestro agent JAR from GitHub releases at pipeline runtime. Only needed when `DBMAESTRO_VERSION` is set. |

---

## Step 1 — Configure CI/CD Variables

Go to **Settings → CI/CD → Variables** and add the following. Click **Add variable** for each.

### Required Variables

| Variable | Type | Protected | Masked | Example value | Description |
|----------|------|-----------|--------|---------------|-------------|
| `DBMAESTRO_PASSWORD` | Variable | Yes | **Yes** | `••••••••` | DBmaestro account password. Always mask this variable. |
| `DBMAESTRO_SERVER` | Variable | No | No | `agent01.local:8017` | DBmaestro agent server in `host:port` format |
| `DBMAESTRO_USER` | Variable | No | No | `dbm_user` | DBmaestro username |

### Recommended Variables

| Variable | Default (if not set) | Description |
|----------|----------------------|-------------|
| `DBMAESTRO_PROJECT_NAME` | *(set in pipeline YAML)* | DBmaestro project name |
| `DBMAESTRO_TARGET_ENV` | *(set in pipeline YAML)* | Target environment name (e.g. `Release_Source`) |
| `DBMAESTRO_AGENT_JAR` | `/home/runner/DBmaestroAgent.jar` | Path where the JAR will be downloaded on the runner |
| `DBMAESTRO_VERSION` | *(empty)* | Agent JAR version to download (e.g. `26.1.3.13473`). **Set this to enable automatic JAR download.** Leave empty if the JAR is pre-installed on the runner. |
| `DBMAESTRO_PACKAGES_FOLDER` | `packages` | Root folder containing package sub-directories |
| `DBMAESTRO_PACKAGE_TYPE` | `Regular` | `Regular` or `AdHoc` |
| `DBMAESTRO_USE_SSL` | `True` | Set `False` to disable SSL |
| `DBMAESTRO_AUTH_TYPE` | `DBmaestroAccount` | Authentication type |

> **Protected variables** are only available to jobs running on protected branches or tags. If your pipelines run on feature branches, do not mark variables as protected unless you also protect those branches.

> **Group-level variables** (Settings at the group level) are inherited by all projects in the group, which is useful for sharing `DBMAESTRO_SERVER`, `DBMAESTRO_USER`, and `DBMAESTRO_PASSWORD` across multiple repositories.

---

## Step 2 — Configure a GitLab Runner

### Register a self-hosted runner

1. Go to **Settings → CI/CD → Runners → New project runner**
2. Set a tag (e.g. `dbmaestro-runner`) — this tag is used in pipeline `tags:` to route jobs to this runner
3. Follow the registration instructions for your OS
4. Choose **Shell** executor for direct script execution, or **Docker** with a suitable image

### Runner requirements

| Requirement | Notes |
|-------------|-------|
| `git` | Must be installed and available in `PATH` |
| `java` (JRE 11+) | Required to run the DBmaestro agent JAR |
| `curl` or `wget` | Required by the `get-cli-jar` script to download the JAR |
| `bash` | Required for Linux template variants (default) |
| `pwsh` (PowerShell Core) | Required only for `-windows` template variants |
| Network access to DBmaestro server | The runner must reach `DBMAESTRO_SERVER` |

### Linux vs Windows runner

All example pipelines default to Linux (Bash). To use PowerShell on a Windows runner or a Linux runner with `pwsh`:
- Change `extends:` to the `-windows` variant (e.g. `.create-package-windows`)
- Ensure the runner has `pwsh` installed and the runner tag matches

---

## Step 3 — Configure Merge Request Approvals

### Require approval before merge (GitLab Premium / Ultimate)

1. Go to **Settings → Merge requests → Merge request approvals**
2. Click **Add approval rule**
3. Set **Rule name** (e.g. `DBmaestro Deployment`)
4. Set **Approvals required** to `1`
5. Under **Add approvers**, add the specific user(s) who must approve
6. Click **Add approval rule**

> **GitLab Free:** MR approval rules are not available. Use the **Protected branches** setting to restrict who can push or merge directly, and rely on code review via MR comments instead.

### Require pipeline to pass before merge

1. Go to **Settings → Merge requests**
2. Enable **Pipelines must succeed**
3. This ensures the build + validate pipeline must pass before the MR can be merged

### Protected branches

1. Go to **Settings → Repository → Protected branches**
2. Add `main` (or your default branch)
3. Set **Allowed to merge** to `Maintainers` (or a specific role)
4. Set **Allowed to push** to `No one` to force all changes through MRs

---

## Step 4 — Add the Pipeline to Your Repository

Copy the example file to your repository root as `.gitlab-ci.yml`:

```
examples/gitlab/.gitlab-ci.yml          →  .gitlab-ci.yml
examples/gitlab/example-build-git-changes.yml  →  .gitlab-ci.yml  (alternative)
```

Then update the `variables:` section at the top to match your environment:

```yaml
variables:
  DBMAESTRO_PROJECT_NAME: 'Demo-PSQL'
  DBMAESTRO_TARGET_ENV: 'Release_Source'
  DBMAESTRO_AGENT_JAR: '/home/runner/DBmaestroAgent.jar'
  # DBMAESTRO_VERSION — set in Settings → CI/CD → Variables (leave empty if JAR is pre-installed)
  # DBMAESTRO_SERVER, DBMAESTRO_USER, DBMAESTRO_PASSWORD — set as CI/CD variables, not in YAML
```

Commit and push. The pipeline activates on the next push or MR.

---

## Example Pipelines

| File | Trigger | Description |
|------|---------|-------------|
| `.gitlab-ci.yml` | Push + MR | Minimal starter using the `deploy.yml` full-pipeline template |
| `example-build-git-changes.yml` | MR | Auto-detects changed packages from MR diff and builds them |
| `example-build-manual-input.yml` | Manual (web) | Specify package names via `PACKAGE_NAMES_INPUT` variable |
| `example-build-branch-name.yml` | Push + MR | Uses the MR source branch name as the package name |
| `example-build-source-control.yml` | Manual (web) | Build from source control (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Push + MR + web | Standalone environment upgrade with `resource_group:` serialization |

---

## Pipeline Reference — Integrated Workflow Pattern

GitLab CI does not have a dedicated integrated PR workflow example in this folder (it uses the `deploy.yml` full-pipeline template instead). The standard pattern across all GitLab examples is:

```
Merge Request opened/updated
  └─ setup         Downloads the DBmaestro CLI JAR (artifact passed to later jobs)
  └─ detect        Detects changed packages from MR diff
  └─ create        Creates each changed package (needs: detect)
  └─ validate      Runs PreCheck on each package (needs: create)
  └─ deploy        Upgrades the target environment (needs: validate, is_pull_request=true)

Push to default branch (MR merged)
  └─ setup         Downloads the CLI JAR
  └─ detect        Detects packages from push commit diff
  └─ deploy        Upgrades the target environment
```

### Job dependencies

Jobs use `needs:` to chain in sequence and pass outputs (via `dotenv` artifacts) downstream:

```yaml
validate:
  extends: .precheck-package
  needs:
    - job: create
      artifacts: true   # receives package name output from create
```

### Serialization

Use `resource_group:` on the deploy job to prevent concurrent upgrades to the same environment:

```yaml
deploy:
  extends: .upgrade-environment
  resource_group: $DBMAESTRO_TARGET_ENV   # one upgrade per environment at a time
```

---

## Approval Gate for Production Upgrades

GitLab does not have a built-in pipeline approval gate (that feature is GitLab Ultimate only under **Environments → Protected environments**). The recommended patterns for enforcing a manual gate before a production upgrade are:

### Option 1 — Manual trigger (all plans)

Split into two pipelines:
1. An automatic pipeline that builds, validates, and upgrades the staging environment
2. A separate pipeline with `when: manual` on the production deploy job:

```yaml
upgrade_prod:
  extends: .upgrade-environment
  when: manual          # job appears in the UI but does not run until clicked
  variables:
    DBMAESTRO_TARGET_ENV: 'Prod_Env_1'
```

The job will appear with a ▶ play button in the pipeline UI. A team member must click it to trigger the upgrade.

### Option 2 — Protected environments (GitLab Ultimate)

1. Go to **Settings → CI/CD → Protected environments**
2. Add `Prod_Env_1`
3. Set **Allowed to deploy** to the role or user who must approve
4. Jobs targeting that environment will be held until an allowed user approves

### Option 3 — MR approval + separate deploy branch

Maintain a separate `release` or `prod` branch. An upgrade to production only happens when a merge is made to that branch, which requires MR approval. This enforces a human gate without pipeline-level approval features.

---

## Troubleshooting

**`DBMAESTRO_PASSWORD: variable not found` / empty password**
The variable is not set or is set as **Protected** but the pipeline is running on an unprotected branch. Either remove the Protected flag or protect the branch.

**`java: command not found`**
The runner does not have Java installed. Install a JRE 11+ on the runner machine.

**`curl: command not found` / JAR download fails**
Install `curl` on the runner or check that the runner has outbound internet access to GitHub releases.

**Pipeline does not trigger on MR**
Ensure the `.gitlab-ci.yml` includes `workflow: rules:` or job-level `rules:` that match `$CI_PIPELINE_SOURCE == "merge_request_event"`. The examples include this already.

**`DETECT_FROM_PUSH` detects no packages on merge**
Set `fetch-depth: 0` equivalent in GitLab by adding `GIT_DEPTH: 0` as a variable on the detect job. Shallow clones miss the diff history needed for detection.

```yaml
detect:
  extends: .detect-packages
  variables:
    GIT_DEPTH: '0'
    DETECT_FROM_PUSH: 'true'
```

**Approval (`when: manual`) job not visible**
The manual job only appears in the pipeline graph after all its `needs:` jobs complete successfully. If an upstream job failed, the manual job may not be shown.
