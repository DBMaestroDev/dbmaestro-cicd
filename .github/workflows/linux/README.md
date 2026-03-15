# Reusable Upgrade Environment Workflow (Linux)

This directory contains a Linux-compatible reusable workflow and composite actions for upgrading environments using DBmaestro with bash scripts.

## Components Created

### 1. Reusable Workflow
**File:** `.github/workflows/linux/reusable-upgrade-environment.yml`

A reusable workflow that runs on Linux runners using bash scripts.

**Key Features:**
- Uses bash instead of PowerShell
- Default runner: `ubuntu-latest` (configurable)
- Default agent path: `/opt/dbmaestro/agent/DBmaestroAgent.jar`
- Supports manual input, push-based detection, and pull request events
- Detects changed packages automatically
- Runs upgrades sequentially (max-parallel: 1)
- Posts PR comments with detected packages

### 2. Composite Actions (Linux/Bash)

#### a. Detect Changed Packages
**Location:** `.github/actions/linux/detect-changed-packages/action.yml`

Bash-based package detection from:
- Manual comma-separated input
- Git diff from push events
- Git diff from pull requests

**Outputs:**
- `matrix`: JSON matrix for parallel job execution
- `has-packages`: Boolean indicating if packages were detected
- `packages`: JSON array of package names
- `packages-list`: Comma-separated list of packages

#### b. Upgrade Environment
**Location:** `.github/actions/linux/upgrade-environment/action.yml`

Executes the DBmaestro upgrade command using bash.

**Features:**
- Normalizes environment names (replaces underscores with spaces)
- Creates GitHub step summary with upgrade details
- Executes Java-based DBmaestro agent
- Error handling with exit codes

#### c. PR Comment
**Location:** `.github/actions/linux/pr-comment/action.yml`

Posts a formatted comment on pull requests (platform-agnostic using github-script).

## Differences from PowerShell Version

| Aspect | PowerShell Version | Linux Version |
|--------|-------------------|---------------|
| **Shell** | PowerShell 5.1 | Bash |
| **Runner Default** | `self-hosted` (Windows) | `ubuntu-latest` |
| **Agent Path** | `C:\Program Files (x86)\DBmaestro\...` | `/opt/dbmaestro/agent/...` |
| **Script Location** | `.github/actions/powershell/` | `.github/actions/linux/` |
| **Path Separators** | Backslash `\` | Forward slash `/` |
| **Array Handling** | PowerShell arrays `@()` | Bash arrays `()` |
| **JSON Creation** | `ConvertTo-Json` | Manual string construction |

## Usage

### Calling the Reusable Workflow

From another workflow file, call the reusable workflow using the `uses` keyword:

```yaml
jobs:
  upgrade:
    uses: ./.github/workflows/linux/reusable-upgrade-environment.yml
    with:
      package_name: 'V15,V16'  # Optional: comma-separated packages
      target_environment: 'QA_Env_1'  # Required: target environment
      project_name: 'Demo-PSQL'  # Optional: defaults to Demo-PSQL
      agent_jar_path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'  # Optional
      detect_from_push: true  # Optional: detect from git push
      is_pull_request: false  # Optional: set to true for PR events
      runner: 'ubuntu-latest'  # Optional: defaults to ubuntu-latest
    secrets:
      DBMAESTRO_SERVER: ${{ vars.DBMAESTRO_SERVER }}
      DBMAESTRO_USER: ${{ secrets.DBMAESTRO_USER }}
      DBMAESTRO_PASSWORD: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### Example Workflow

See `.github/workflows/linux/example-upgrade-usage.yml` for a complete example that handles:
- Manual workflow dispatch
- Push events with automatic package detection
- Pull request events with comments

### Using Composite Actions Directly

You can also use the composite actions directly in your workflows:

```yaml
steps:
  - name: Detect Packages
    id: detect
    uses: ./.github/actions/linux/detect-changed-packages
    with:
      package_name: 'V15,V16'
      detect_from_push: false

  - name: Upgrade
    uses: ./.github/actions/linux/upgrade-environment
    with:
      package_name: 'V15'
      target_environment: 'QA_Env_1'
      project_name: 'Demo-PSQL'
      agent_jar_path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'
      dbmaestro_server: ${{ vars.DBMAESTRO_SERVER }}
      dbmaestro_user: ${{ secrets.DBMAESTRO_USER }}
      dbmaestro_password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

## Requirements

### Linux Environment
- Ubuntu 18.04+ or compatible Linux distribution
- Java Runtime Environment (JRE) installed
- DBmaestro Agent JAR file available at configured path
- Git installed for package detection

### Runner Configuration
The workflow can run on:
- **ubuntu-latest** (GitHub-hosted runner) - Default
- **self-hosted** (your own Linux runner)

Configure via the `runner` input parameter.

## Configuration

### Required Secrets
- `DBMAESTRO_USER`: DBmaestro username
- `DBMAESTRO_PASSWORD`: DBmaestro password

### Required Variables
- `DBMAESTRO_SERVER`: DBmaestro server URL

### Optional Inputs
- `project_name`: Default is 'Demo-PSQL'
- `agent_jar_path`: Default is '/opt/dbmaestro/agent/DBmaestroAgent.jar'
- `use_ssl`: Default is 'True'
- `runner`: Default is 'ubuntu-latest'

## Benefits

1. **Cross-Platform**: Run on any Linux environment (GitHub-hosted or self-hosted)
2. **Standard Tool**: Uses bash, available on all Linux systems
3. **Cost-Effective**: Can use free GitHub-hosted runners
4. **Portable**: Works consistently across different Linux distributions
5. **Reusable**: Define once, use in multiple workflows

## Choosing Between Linux and PowerShell Versions

Use **Linux version** when:
- Running on GitHub-hosted runners (ubuntu-latest)
- Using Linux-based self-hosted runners
- Agent is installed on Linux systems
- You prefer bash scripting

Use **PowerShell version** when:
- Running on Windows self-hosted runners
- Agent is installed on Windows systems
- You have existing PowerShell infrastructure
- Windows-specific integrations are needed

## Migration Path

If migrating from PowerShell to Linux:

1. Update agent installation path in workflows
2. Change runner type from `self-hosted` (Windows) to `ubuntu-latest` or Linux self-hosted
3. Update workflow references from `powershell/` to `linux/`
4. Ensure DBmaestro agent is installed on Linux runner
5. Test with a non-production environment first

## Example Migration

**Before (PowerShell):**
```yaml
uses: ./.github/workflows/powershell/reusable-upgrade-environment.yml
with:
  agent_jar_path: 'C:\Program Files (x86)\DBmaestro\DOP Server\Agent\DBmaestroAgent.jar'
```

**After (Linux):**
```yaml
uses: ./.github/workflows/linux/reusable-upgrade-environment.yml
with:
  agent_jar_path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'
  runner: 'ubuntu-latest'
```

## Troubleshooting

### Java Not Found
Ensure Java is installed on the runner:
```yaml
- name: Setup Java
  uses: actions/setup-java@v3
  with:
    distribution: 'temurin'
    java-version: '11'
```

### Agent JAR Not Found
Verify the path in your workflow inputs or install the agent:
```bash
sudo mkdir -p /opt/dbmaestro/agent
sudo cp DBmaestroAgent.jar /opt/dbmaestro/agent/
```

### Permission Denied
Ensure the JAR file has execute permissions:
```bash
sudo chmod +r /opt/dbmaestro/agent/DBmaestroAgent.jar
```
