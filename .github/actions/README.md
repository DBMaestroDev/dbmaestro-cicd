# DBmaestro GitHub Actions and Reusable Workflows

This directory contains composite actions and reusable workflows for DBmaestro package management.

## Directory Structure

```
.github/
├── actions/
│   ├── create-package/
│   │   └── action.yml                          # Composite action for package creation
│   └── precheck-package/
│       └── action.yml                          # Composite action for precheck validation
└── workflows/
    ├── reusable-build-validate.yml             # Reusable workflow (accepts package list)
    ├── example-caller-workflow.yml             # Example: manual package selection
    ├── example-caller-workflow-git-changes.yml # Example: detect git changes + call reusable
    └── example-direct-actions.yml              # Example: using actions directly
```

## Composite Actions

### create-package

Creates a DBmaestro package from a folder, including manifest creation, tar archiving, and package upload.

**Usage:**
```yaml
- uses: ./.github/actions/create-package
  with:
    package-name: 'V15'
    project-name: 'Demo-PSQL'
    packages-folder: 'packages'
    agent-jar-path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'
    dbmaestro-server: ${{ secrets.DBMAESTRO_SERVER }}
    username: ${{ secrets.DBMAESTRO_USER }}
    password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### precheck-package

Validates a DBmaestro package using precheck operation.

**Usage:**
```yaml
- uses: ./.github/actions/precheck-package
  with:
    package-name: 'V15'
    project-name: 'Demo-PSQL'
    agent-jar-path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'
    dbmaestro-server: ${{ secrets.DBMAESTRO_SERVER }}
    username: ${{ secrets.DBMAESTRO_USER }}
    password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

## Reusable Workflow

### reusable-build-validate.yml

A reusable workflow that builds and validates DBmaestro packages. It accepts a JSON array of packages to process.

**Important:** This workflow does NOT detect changed packages. The caller must provide the package list.

**Usage:**
```yaml
jobs:
  build:
    uses: ./.github/workflows/reusable-build-validate.yml
    with:
      project-name: 'Demo-PSQL'
      packages-matrix: '[{"package":"V15"},{"package":"V16"}]'
      runner: 'ubuntu-latest'
    secrets:
      dbmaestro-server: ${{ vars.DBMAESTRO_SERVER }}
      dbmaestro-user: ${{ secrets.DBMAESTRO_USER }}
      dbmaestro-password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

## Examples

See these example workflows:

### 1. example-caller-workflow.yml
Shows how to call the reusable workflow with **manual package selection**. User inputs comma-separated package names via workflow_dispatch.

### 2. example-caller-workflow-git-changes.yml  
Shows how to **detect changed packages from git** and pass them to the reusable workflow. Ideal for PR workflows.

### 3. example-direct-actions.yml
Shows how to use the composite actions directly for more granular control.

## Configuration

### Required Secrets
- `DBMAESTRO_USER` - DBmaestro username
- `DBMAESTRO_PASSWORD` - DBmaestro password or automation token

### Required Variables
- `DBMAESTRO_SERVER` - DBmaestro server hostname

### Common Inputs

#### For Composite Actions:
| Input | Description | Default |
|-------|-------------|---------|
| `project-name` | DBmaestro project name | Required |
| `package-name` | Name of the package | Required |
| `agent-jar-path` | Path to DBmaestro agent JAR | `/opt/dbmaestro/agent/DBmaestroAgent.jar` |
| `use-ssl` | Use SSL for connection | `True` |
| `auth-type` | Authentication type | `DBmaestroAccount` |
| `package-type` | Package type | `Regular` |
| `packages-folder` | Root folder for packages | `packages` |

#### For Reusable Workflow:
| Input | Description | Default |
|-------|-------------|---------|
| `project-name` | DBmaestro project name | Required |
| `packages-matrix` | JSON array of packages (e.g., `[{"package":"V15"}]`) | Required |
| `agent-jar-path` | Path to DBmaestro agent JAR | `/opt/dbmaestro/agent/DBmaestroAgent.jar` |
| `use-ssl` | Use SSL for connection | `True` |
| `auth-type` | Authentication type | `DBmaestroAccount` |
| `package-type` | Package type | `Regular` |
| `packages-folder` | Root folder for packages | `packages` |
| `runner` | Runner type | `ubuntu-latest` |

## Benefits

### Using Composite Actions
- ✅ Reusable across multiple workflows
- ✅ Single source of truth for package operations
- ✅ Easy to maintain and update
- ✅ Can be used granularly or combined

### Using Reusable Workflows
- ✅ Separates package detection from package processing
- ✅ Flexible - caller decides how to provide package list (git changes, manual input, etc.)
- ✅ Consistent build/validate process across projects
- ✅ Handles matrix jobs automatically
- ✅ Centralized logic that's testable and maintainable
- ✅ Can be reused for different triggering scenarios (PR, manual, scheduled)

## Windows vs Linux

All actions and workflows shown here use Linux runners (`ubuntu-latest`) with bash scripts.

For Windows runners:
- Change `agent-jar-path` to Windows path: `C:\\Program Files (x86)\\DBmaestro\\DOP Server\\Agent\\DBmaestroAgent.jar`
- Update action shells from `bash` to `pwsh` or `powershell`
- Replace `tar` command with PowerShell's `Compress-Archive` or `tar` (available in PowerShell 5.1+)
- Use PowerShell syntax for environment variables (`$env:VAR` instead of `$VAR`)

## Best Practices

### When to Use What

**Use Reusable Workflow (`reusable-build-validate.yml`) when:**
- You need consistent build/validate process across multiple scenarios
- You want to handle multiple packages in parallel
- You already have the package list (from git detection, manual input, API, etc.)

**Use Composite Actions directly when:**
- You need granular control over the workflow structure
- You're building a single package
- You want to add custom steps between create and validate
- You're creating a new reusable workflow with different logic

**Use Git Change Detection (`example-caller-workflow-git-changes.yml`) when:**
- Working with pull requests
- Only changed packages should be processed
- Automated CI/CD based on git commits

**Use Manual Selection (`example-caller-workflow.yml`) when:**
- Running on-demand builds
- Testing specific packages
- Deploying selected packages to environments

### General Best Practices

1. **Separate concerns** - Detect packages in caller, process in reusable workflow
2. **Use composite actions** for reusable building blocks
3. **Always validate** packages with precheck before deployment
4. **Use secrets** for credentials, never hardcode
5. **Test** with `workflow_dispatch` before automating with PR triggers
6. **Use matrix strategy** to process multiple packages consistently
