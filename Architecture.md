# DBmaestro CI/CD Library

A cross-platform library for automating DBmaestro database deployments across GitHub Actions, GitLab CI, and Azure DevOps.

## Architecture

```
+---------------------------------------------------------------+
|                        examples/                              |
|   Ready-to-use pipeline configs per platform                  |
|   (github/, gitlab/, azure-devops/)                           |
+---------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+---------------+  +----------------+  +-------------------+
|   .github/    |  |   gitlab/      |  | azure-devops/     |
|   Wrappers    |  |   Wrappers     |  | Wrappers          |
|   & Actions   |  |   & Templates  |  | & Templates       |
+---------------+  +----------------+  +-------------------+
        \                   |                   /
         \                  |                  /
          v                 v                 v
+---------------------------------------------------------------+
|                         core/                                 |
|   Platform-agnostic scripts (bash + PowerShell)               |
|   +-------------------------+                                 |
|   | scripts/                |                                 |
|   |   detect-packages       |                                 |
|   |   create-package        |                                 |
|   |   precheck-package      |                                 |
|   |   upgrade-environment   |                                 |
|   |   build-from-source     |                                 |
|   |   get-cli-jar           |                                 |
|   +-------------------------+                                 |
+---------------------------------------------------------------+
```

## Supported Platforms

### CI/CD Systems

| CI/CD System    | Status    |
|-----------------|-----------|
| GitHub Actions  | Supported |
| GitLab CI       | Supported |
| Azure DevOps    | Supported |

## Quick Start

### GitHub Actions

Reference the reusable workflows from your repository workflow:

```yaml
jobs:
  deploy:
    uses: DBMaestroDev/dbmaestro-cicd/.github/workflows/sh-upgrade-environment.yml@main
    secrets: inherit
```

See [.github/README.md](.github/README.md) for detailed setup.

### GitLab CI

Include the shared templates in your `.gitlab-ci.yml`:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/DBMaestroDev/dbmaestro-cicd/main/gitlab/templates/deploy.yml'
```

See [gitlab/README.md](gitlab/README.md) for detailed setup.

### Azure DevOps

Reference the pipeline templates from your `azure-pipelines.yml`:

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
```

See [azure-devops/README.md](azure-devops/README.md) for detailed setup.

## Directory Structure

```
dbmaestro-cicd/
  core/                    # Platform-agnostic scripts
    scripts/
      sh/                  # Bash scripts (Linux runners)
      ps/                  # PowerShell scripts (Linux+pwsh or Windows runners)
  .github/                 # GitHub Actions wrappers
    actions/
      sh/                  # Composite actions (bash)
      ps/                  # Composite actions (PowerShell)
    workflows/             # Reusable workflows (sh-* and ps-*)
  gitlab/                  # GitLab CI templates
    templates/
  azure-devops/            # Azure DevOps pipeline templates
    templates/
  examples/                # Ready-to-use example pipelines
    github/
    gitlab/
    azure-devops/
```

## Core Operations

### Deployment Scripts

| Operation              | Description                                                    |
|------------------------|----------------------------------------------------------------|
| `detect-packages`      | Detect changed packages from git diff, push, or manual input  |
| `create-package`       | Create a DBmaestro package from a folder (manifest + tar + upload) |
| `precheck-package`     | Validate a package using the DBmaestro precheck operation      |
| `upgrade-environment`  | Upgrade a target environment with a specific package           |
| `build-from-source`    | Build a package from source control (tasks or specific commit) |
| `get-cli-jar`          | Download the DBmaestro Agent JAR file by version               |

## Runner Model

All platforms are designed to run on a single self-hosted Linux runner (`dbmaestro-runner`) with `pwsh` installed. This runner can execute both bash (`sh/`) and PowerShell (`ps/`) scripts without OS switching. A native Windows runner is also supported for `ps/` workflows.

## Platform-Specific Documentation

- [GitHub Actions Setup](.github/README.md)
- [GitLab CI Setup](gitlab/README.md)
- [Azure DevOps Setup](azure-devops/README.md)

## Contributing

1. Core scripts live in `core/` and must remain platform-agnostic. Do not add CI/CD-specific logic to core scripts.
2. Each CI/CD platform wrapper lives in its own top-level directory and calls core scripts.
3. Provide both bash (`sh/`) and PowerShell (`ps/`) variants for any new core script.
4. Add example pipeline configurations under `examples/<platform>/` for new features.
5. Test changes against all supported platforms before merging.
