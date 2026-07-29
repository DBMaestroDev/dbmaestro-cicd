# GitHub Actions — Setup Guide

This guide walks through everything needed to run the DBmaestro example pipelines in this folder on GitHub Actions.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Configure Repository Secrets](#step-1--configure-repository-secrets)
- [Step 2 — Configure Repository Variables](#step-2--configure-repository-variables)
- [Step 3 — Configure the Prod_Env_1 Approval Gate](#step-3--configure-the-prod_env_1-approval-gate)
- [Step 4 — Configure Branch Protection](#step-4--configure-branch-protection)
- [Step 5 — Add the Workflow to Your Repository](#step-5--add-the-workflow-to-your-repository)
- [Example Pipelines](#example-pipelines)
- [Workflow Reference — Integrated PR Workflow](#workflow-reference--integrated-pr-workflow)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Self-hosted runner | Linux runner with the DBmaestro agent JAR pre-installed or downloaded at runtime. Label it to match `RUNNER` (default: `dbmaestro-runner`). |
| DBmaestro server | Accessible from the runner. Note the hostname and port (e.g. `agent01.local:8017`). |
| DBmaestro credentials | Username and password for the account that will create/upgrade packages. |
| GitHub repository | The repository containing your `packages/` folder with DBmaestro package sub-directories. |

---

## Step 1 — Configure Repository Secrets

Go to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret name | Description |
|-------------|-------------|
| `DBMAESTRO_PASSWORD` | DBmaestro account password. Mark as secret — it will be masked in logs. |

---

## Step 2 — Configure Repository Variables

Go to **Settings → Secrets and variables → Actions → Variables** and add the following.  
Variables are not masked in logs. Do not store passwords here.

### Required

| Variable | Example value | Description |
|----------|---------------|-------------|
| `DBMAESTRO_SERVER` | `agent01.local:8017` | DBmaestro agent server in `host:port` format |
| `DBMAESTRO_USER` | `dbm_user` | DBmaestro username |

### Configurable (have defaults in the workflow)

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_NAME` | `Demo-PSQL` | DBmaestro project name |
| `RELEASE_ENVIRONMENT` | `Release_Source` | Environment upgraded on merge |
| `PROD_ENVIRONMENT` | `Prod_Env_1` | Environment upgraded after approval |
| `PACKAGES_FOLDER` | `packages` | Root folder containing package sub-directories in your repo |
| `AGENT_JAR_PATH` | `/home/runner/DBmaestroAgent.jar` | Path to the DBmaestro agent JAR on the runner |
| `USE_SSL` | `True` | Set `False` to disable SSL |
| `AUTH_TYPE` | `DBmaestroAccount` | Authentication type |
| `PACKAGE_TYPE` | `Regular` | `Regular` or `AdHoc` |
| `RUNNER` | `dbmaestro-runner` | Runner label (`runs-on:` value) |
| `CLI_VERSION` | *(empty)* | DBmaestro agent JAR version to download (e.g. `26.1.3.13473`). When set, each job downloads the JAR at that version (re-downloads only if the version changes). Leave empty if the JAR is pre-installed on the runner. |

> **Note:** Variables in the `env:` block of a workflow cannot be used in job-level `with:`, `runs-on:`, or `if:` fields — that is why these are repository variables (`vars.*`) rather than workflow `env:` entries.

> **JAR download behaviour:** when `CLI_VERSION` is set, each workflow job downloads the JAR at that version (a local version marker avoids re-downloading the same version). When `CLI_VERSION` is empty, the workflow assumes the JAR is already present at `AGENT_JAR_PATH` and skips the download entirely.

> **Available versions:** see the published tags/releases at [DBMaestroDev/DBmaestroCLI](https://github.com/DBMaestroDev/DBmaestroCLI). `CLI_VERSION` accepts either format, e.g. `26.1.3.13473` or `v26.1.3.13473`.

---

## Step 3 — Configure the Prod_Env_1 Approval Gate

The integrated PR workflow pauses before upgrading `Prod_Env_1` and waits for a manual approval. This is enforced via a **GitHub Environment**.

1. Go to **Settings → Environments → New environment**
2. Name it exactly `Prod_Env_1` (must match the `environment:` value in the workflow)
3. Click **Required reviewers** → add the GitHub username(s) who must approve
4. Optionally set a **wait timer** (e.g. 10 minutes) to add a delay after approval
5. Click **Save protection rules**

When the `approve_prod` job runs, GitHub will pause the workflow and send a notification to the listed reviewers. They click **Review deployments** in the Actions UI to approve or reject.

> **GitHub Team plan:** Environment protection rules (required reviewers) are **not available** on private repositories under the Team plan. They are available on public repositories or under GitHub Enterprise. If your plan does not support this feature, use a separate `workflow_dispatch` workflow to trigger the Prod upgrade manually instead.

---

## Step 4 — Configure Branch Protection

To require PR approval before code can be merged into `main`:

1. Go to **Settings → Branches → Add rule** (or edit the existing rule for `main`)
2. Branch name pattern: `main`
3. Enable **Require a pull request before merging**
4. Set **Required number of approvals** to `1` (or more)
5. Enable **Require status checks to pass before merging**
   - Add the `Build and Validate` check (it appears after the first workflow run)
6. Enable **Do not allow bypassing the above settings** to enforce even for admins

### Require approval from a specific person

Create a `.github/CODEOWNERS` file in your repository:

```
# All files require approval from this person before merging
* @their-github-username
```

With `Require review from Code Owners` enabled in the branch rule, that specific person must approve every PR.

---

## Step 5 — Add the Workflow to Your Repository

Copy the example file to your repository's `.github/workflows/` folder:

```
examples/github/example-integrated-pr-workflow.yml
  →  .github/workflows/example-integrated-pr-workflow.yml
```

Then commit and push. The workflow activates immediately on the next pull request or push to `main`.

---

## Example Pipelines

| File | Trigger | Description |
|------|---------|-------------|
| `example-integrated-pr-workflow.yml` | PR + push to `main` | Build & validate on PR, upgrade Release_Source on merge, approval gate + upgrade Prod_Env_1 |
| `example-build-git-changes.yml` | PR + `workflow_dispatch` | Auto-detects changed packages from git diff and builds them |
| `example-build-manual-input.yml` | `workflow_dispatch` | Manual comma-separated package list |
| `example-build-branch-name.yml` | PR + `workflow_dispatch` | Uses the branch or PR name as the package name |
| `example-build-source-control.yml` | `workflow_dispatch` | Build from source control (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Push + PR + `workflow_dispatch` | Standalone environment upgrade with concurrency guard |

---

## Workflow Reference — Integrated PR Workflow

```
Pull Request opened/updated
  └─ detect_changed_packages     Finds which packages/ sub-dirs changed vs base branch
  └─ build_and_validate          Creates + precheks each changed package (sequential)

Push to main (PR merged)
  └─ upgrade_release_source      Detects packages from the merge commit, upgrades Release_Source
  └─ approve_prod                Pauses — waits for manual approval from a reviewer
  └─ upgrade_prod                Upgrades Prod_Env_1 with the same packages
```

### Job conditions

| Job | Runs when |
|-----|-----------|
| `detect_changed_packages` | `pull_request` event only |
| `build_and_validate` | `pull_request` event + packages were detected |
| `upgrade_release_source` | `push` event only (i.e. after merge) |
| `approve_prod` | `push` event only, after `upgrade_release_source` succeeds |
| `upgrade_prod` | `push` event only, after `approve_prod` is approved |

### Concurrency

The workflow uses `concurrency: group: dbmaestro-${{ github.ref_name }}` with `cancel-in-progress: false`. This means a second run on the same branch will queue behind the first — it will not cancel an upgrade already in progress.

---

## Troubleshooting

**`Unrecognized named-value: 'env'`**  
`env` context is not available in `runs-on:`, `with:`, or `if:` at the job level. Use `vars.*` (repository variables) instead.

**`environment: Prod_Env_1` has no effect / no approval prompt**  
The environment must be created in **Settings → Environments** with at least one required reviewer. On GitHub Team plan with private repos, this feature is unavailable — use a manual `workflow_dispatch` trigger instead.

**`Unrecognized named-value: 'vars'`**  
The `vars` context requires GitHub Actions runner version 2.295.0 or later. Update your self-hosted runner.

**Build passes but upgrade finds no packages**  
The `detect_from_push: true` flag compares the merge commit SHA to its parent. Ensure `fetch-depth: 0` is set on the checkout step, or the git history is too shallow to detect the diff.

**Runner not found**  
Verify the runner label matches the `RUNNER` variable exactly. Check **Settings → Actions → Runners** to see registered runners and their labels.
