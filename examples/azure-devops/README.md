# Azure DevOps — Setup Guide

This guide walks through everything needed to run the DBmaestro example pipelines in this folder on Azure DevOps.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Create a GitHub Service Connection](#step-1--create-a-github-service-connection)
- [Step 2 — Configure Pipeline Variables](#step-2--configure-pipeline-variables)
- [Step 3 — Configure the Prod_Env_1 Approval Gate](#step-3--configure-the-prod_env_1-approval-gate)
- [Step 4 — Configure Branch Policies](#step-4--configure-branch-policies)
- [Step 5 — Create the Pipeline in Azure DevOps](#step-5--create-the-pipeline-in-azure-devops)
- [Example Pipelines](#example-pipelines)
- [Pipeline Reference — Integrated PR Workflow](#pipeline-reference--integrated-pr-workflow)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Self-hosted agent | Linux or Windows agent registered in an Azure DevOps agent pool. Default pool name: `dbmaestro-runner`. |
| DBmaestro server | Accessible from the agent. Note the hostname and port (e.g. `agent01.local:8017`). |
| DBmaestro credentials | Username and password for the account that will create/upgrade packages. |
| GitHub repository | The repository containing your `packages/` folder with DBmaestro package sub-directories. |
| Azure DevOps project | An Azure DevOps project where you will create pipelines. |

---

## Step 1 — Create a GitHub Service Connection

The pipelines reference templates from the public `DBMaestroDev/dbmaestro-cicd` GitHub repository. Azure DevOps requires a service connection to access any external GitHub repository, even a public one.

1. Go to **Project Settings → Service connections → New service connection → GitHub**
2. Choose **Personal Access Token** as the authentication method
3. Paste a GitHub PAT with `public_repo` scope (read-only access to public repos is sufficient)
4. Name the connection `dbmaestro-cicd` (this name is referenced in every example pipeline under `endpoint:`)
5. Check **Grant access permission to all pipelines**
6. Click **Save**

> If you name the connection something other than `dbmaestro-cicd`, update the `endpoint:` field in every example file you use.

---

## Step 2 — Configure Pipeline Variables

Variables can be set at the pipeline level or in a Variable Group (Library).

### Using a Variable Group (recommended for shared values)

1. Go to **Pipelines → Library → + Variable group**
2. Name it (e.g. `dbmaestro-vars`)
3. Add the variables below
4. Link the group to your pipeline: open the pipeline → **Edit → Variables → Variable groups → Link variable group**

### Required Variables

| Variable | Example value | Secret | Description |
|----------|---------------|--------|-------------|
| `DBMAESTRO_PASSWORD` | `••••••••` | **Yes** | DBmaestro account password. Click the lock icon to mark as secret. |
| `DBMAESTRO_SERVER` | `agent01.local:8017` | No | DBmaestro agent server in `host:port` format |
| `DBMAESTRO_USER` | `dbm_user` | No | DBmaestro username |
| `CLI_VERSION` | *(empty)* | No | DBmaestro agent JAR version to download (e.g. `26.1.3.13473`). When set, the JAR is downloaded at that version (re-downloaded only if the version changes). Leave empty if the JAR is pre-installed on the agent. |

> **Access-token auth:** every step template also accepts `accessTokenFilePath` as an alternative to `user`/`password` — see [`azure-devops/README.md`](../../azure-devops/README.md) for details. These examples use the user/password flow for simplicity.

### Pipeline Parameters (set defaults directly in the YAML)

The integrated PR workflow uses `parameters:` at the top of the file. Edit these defaults to match your environment before running the pipeline:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `projectName` | `Demo-PSQL` | DBmaestro project name |
| `targetEnvironment` | `Release_Source` | Primary environment upgraded on merge |
| `packagesFolder` | `packages` | Root folder containing package sub-directories |
| `agentJarPath` | `$(Pipeline.Workspace)/DBmaestroAgent.jar` | Path to the DBmaestro agent JAR on the agent |
| `useSsl` | `True` | Set `False` to disable SSL |
| `authType` | `DBmaestroAccount` | Authentication type |
| `packageType` | `Regular` | `Regular` or `AdHoc` |
| `runnerPool` | `dbmaestro-runner` | Agent pool name |

> **JAR download behaviour:** when `CLI_VERSION` is set, the JAR is downloaded at that version (a version marker avoids re-downloading the same version). When empty, the pipeline assumes the JAR is pre-installed on the agent.

> **Available versions:** see the published tags/releases at [DBMaestroDev/DBmaestroCLI](https://github.com/DBMaestroDev/DBmaestroCLI). `CLI_VERSION` accepts either format, e.g. `26.1.3.13473` or `v26.1.3.13473`.

---

## Step 3 — Configure the Prod_Env_1 Approval Gate

The integrated PR workflow uses a `deployment` job targeting an Azure DevOps **Environment** named `Prod_Env_1`. The pipeline pauses at that stage until a designated approver reviews it in the Azure DevOps UI.

### Create the environment and add an approval check

1. Go to **Pipelines → Environments → New environment**
2. Name it exactly `Prod_Env_1` (must match the `environment:` value in the `UpgradeProd` stage)
3. Set **Resource** to `None`
4. Click **Create**
5. Open the `Prod_Env_1` environment → click the **⋮** menu → **Approvals and checks**
6. Click **+** → **Approvals**
7. Add the user(s) or group(s) who must approve before the upgrade runs
8. Optionally set a timeout (e.g. 1 day) after which the stage auto-rejects if not approved
9. Click **Create**

When the `UpgradeProd` stage starts, Azure DevOps will send a notification to the listed approvers. They open the pipeline run and click **Review → Approve** to allow the stage to proceed.

---

## Step 4 — Configure Branch Policies

To require PR approval before code can be merged into `main`:

1. Go to **Project Settings → Repositories → [your repo] → Policies** (or **Repos → Branches → main → Branch policies**)
2. Enable **Require a minimum number of reviewers** → set to `1`
3. Enable **Check for linked work items** (optional)
4. Under **Build validation**, click **+** and add your pipeline as a required status check
   - This ensures build + validate must pass before the PR can be completed
5. Optionally enable **Automatically include code reviewers** and add a specific user or team

### Require approval from a specific person

Under **Automatically include code reviewers**:
- Add the person's name
- Set **Policy requirement** to **Required**
- This person must approve every PR targeting `main`

---

## Step 5 — Create the Pipeline in Azure DevOps

1. Go to **Pipelines → New pipeline**
2. Select **Azure Repos Git** or **GitHub** (wherever your code repository lives)
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select the branch and path to the example file (e.g. `examples/azure-devops/example-integrated-pr-workflow.yml`)
   - Alternatively, copy the file to your repository root as `azure-pipelines.yml`
6. Click **Continue → Run**

On the first run, Azure DevOps will ask for permission to access the `dbmaestro-cicd` GitHub service connection. Click **Permit**.

---

## Example Pipelines

| File | Trigger | Description |
|------|---------|-------------|
| `example-integrated-pr-workflow.yml` | PR + push to `main` | Build & validate on PR, upgrade Release_Source on merge, approval gate + upgrade Prod_Env_1 |
| `azure-pipelines.yml` | Push to `main` + PR | Minimal starter using the `deploy.yml` full-pipeline template |
| `example-build-git-changes.yml` | PR + manual | Auto-detects changed packages from git diff and builds them |
| `example-build-manual-input.yml` | Manual (parameters) | Specify package names as a pipeline parameter |
| `example-build-branch-name.yml` | PR + manual | Uses the source branch name as the package name |
| `example-build-source-control.yml` | Manual (parameters) | Build from source control (all / tasks / specific commit) |
| `example-upgrade-environment.yml` | Push + PR + manual | Standalone environment upgrade with `lockBehavior: sequential` |

---

## Pipeline Reference — Integrated PR Workflow

```
Pull Request opened/updated → main
  └─ Setup                    Downloads the DBmaestro CLI JAR
  └─ Detect                   Finds which packages/ sub-dirs changed vs base branch
  └─ BuildAndValidate         Creates + prechecks each changed package (sequential)

Push to main (PR merged)
  └─ Setup                    Downloads the DBmaestro CLI JAR
  └─ UpgradeReleaseSource     Detects packages from the merge commit, upgrades Release_Source
  └─ UpgradeProd              Pauses for approval → upgrades Prod_Env_1
```

### Stage conditions

| Stage | Runs when |
|-------|-----------|
| `Setup` | Always |
| `Detect` | `Build.Reason == PullRequest` only |
| `BuildAndValidate` | `Build.Reason == PullRequest` only, after Detect |
| `UpgradeReleaseSource` | `Build.Reason == IndividualCI` (push/merge) only |
| `UpgradeProd` | After `UpgradeReleaseSource` succeeds + approval granted |

### Serialization

`lockBehavior: sequential` is set on the upgrade stages. If two merges happen in quick succession, the second upgrade waits for the first to finish rather than running concurrently or being cancelled.

### Linux vs Windows

All example pipelines default to `useWindows: false` (Bash). To switch to PowerShell:

1. Set `useWindows: true` on each template call
2. Ensure your agent pool has `pwsh` installed (or use a Windows agent)

The agent pool name (`runnerPool` parameter) stays the same if the agent supports both.

---

## Troubleshooting

**`Unable to locate executable file: 'pwsh'`**  
The agent is Linux-only and does not have PowerShell Core installed. Either install `pwsh` on the agent or set `useWindows: false` on all template calls.

**`Could not find a usable repository resource with alias 'dbmaestro-cicd'`**  
The GitHub service connection name in the pipeline's `endpoint:` field does not match the connection created in Project Settings. Verify the name matches exactly.

**Pipeline asks for permission on first run**  
Azure DevOps requires explicit permission the first time a pipeline accesses a service connection or agent pool. Click **View → Permit** on each resource prompt.

**`DBMAESTRO_PACKAGE_NAME: DBMAESTRO_PACKAGE_NAME is required`**  
The upgrade stage ran without detecting any packages. This usually means `detect-packages` ran but found no changes, or the `detectPackages.packages_list` output variable was not passed correctly. Verify the detect step ran in the same job and that `detectFromPush: true` is set for merge-triggered runs.

**Approval notification not sent**  
Check that the environment `Prod_Env_1` exists under **Pipelines → Environments** and has an approval check configured. The pipeline will not pause if no checks are set on the environment.

**Variables not resolving (`$(DBMAESTRO_SERVER)` is empty)**  
Ensure the variable is defined at the pipeline level, in a linked variable group, or in the pipeline's settings UI. Variables defined only in the YAML `parameters:` block are not automatically available as `$(NAME)` — pass them explicitly via `env:` or as template parameters.
