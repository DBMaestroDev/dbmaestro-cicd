# DBmaestro CI/CD Library

A cross-platform library for automating [DBmaestro](https://www.dbmaestro.com/) database deployments. Provides platform-agnostic core scripts wrapped in native CI/CD constructs for GitHub Actions, GitLab CI, and Azure DevOps.

---

## Repository Structure

```
.
├── core/                          # Platform-agnostic scripts (the source of truth)
│   └── scripts/
│       ├── sh/                    # Bash scripts (Linux runners)
│       │   ├── detect-packages.sh
│       │   ├── create-package.sh
│       │   ├── precheck-package.sh
│       │   ├── upgrade-environment.sh
│       │   ├── build-from-source.sh
│       │   └── get-cli-jar.sh
│       └── ps/                    # PowerShell scripts (Linux runner with pwsh, or Windows runner)
│           ├── detect-packages.ps1
│           ├── create-package.ps1
│           ├── precheck-package.ps1
│           ├── upgrade-environment.ps1
│           ├── build-from-source.ps1
│           └── get-cli-jar.ps1
│
├── .github/                       # GitHub Actions wrappers
│   ├── actions/
│   │   ├── sh/                    # Composite actions (Linux)
│   │   │   ├── detect-changed-packages/
│   │   │   ├── create-package/
│   │   │   ├── precheck-package/
│   │   │   ├── upgrade-environment/
│   │   │   ├── build-from-source-control/
│   │   │   ├── get-cli-jar/
│   │   │   └── pr-comment/
│   │   └── ps/                    # Composite actions (PowerShell/Windows)
│   │       ├── detect-changed-packages/
│   │       ├── create-package/
│   │       ├── upgrade-environment/
│   │       ├── get-cli-jar/
│   │       └── pr-comment/
│   └── workflows/                 # Reusable workflows
│       ├── sh-build-validate.yml
│       ├── sh-build-source-control.yml
│       ├── sh-upgrade-environment.yml
│       └── ps-upgrade-environment.yml
│
├── gitlab/
│   └── templates/                 # GitLab CI hidden job templates
│       ├── detect-packages.yml
│       ├── create-package.yml
│       ├── precheck-package.yml
│       ├── upgrade-environment.yml
│       ├── build-from-source.yml
│       ├── get-cli-jar.yml
│       └── deploy.yml             # Full pipeline template (all stages)
│
├── azure-devops/
│   └── templates/                 # Azure DevOps step templates
│       ├── detect-packages.yml
│       ├── create-package.yml
│       ├── precheck-package.yml
│       ├── upgrade-environment.yml
│       ├── build-from-source.yml
│       ├── get-cli-jar.yml
│       └── deploy.yml             # Multi-stage pipeline template
│
└── examples/                      # Ready-to-use pipeline configs
    ├── github/                    # GitHub Actions examples
    ├── gitlab/                    # GitLab CI examples
    └── azure-devops/              # Azure DevOps examples
```

---

## Core Scripts

All logic lives in `core/scripts/` and is shared across all CI/CD platforms. Scripts communicate via environment variables (inputs) and a key=value output file (`$DBM_OUTPUT_FILE`).

| Script | Description | Key Inputs | Outputs |
|--------|-------------|------------|---------|
| `detect-packages` | Detects changed packages from git diff, push, or manual input | `DETECT_IS_PULL_REQUEST`, `DETECT_BASE_REF`, `DETECT_FROM_PUSH`, `DETECT_PACKAGE_NAME` | `has_packages`, `packages_list`, `matrix`, `packages` |
| `get-cli-jar` | Downloads the DBmaestro agent JAR from GitHub releases | `DBMAESTRO_VERSION`, `DBMAESTRO_AGENT_JAR` | `download_success` |
| `create-package` | Creates a manifest + archive and uploads to DBmaestro | `DBMAESTRO_PACKAGE_NAME`, `DBMAESTRO_PROJECT_NAME`, `DBMAESTRO_PACKAGES_FOLDER`, `DBMAESTRO_PACKAGE_TYPE` | `package_created` |
| `precheck-package` | Runs a DBmaestro PreCheck (validation) on a package | `DBMAESTRO_PACKAGE_NAME`, `DBMAESTRO_PROJECT_NAME` | `validation_passed` |
| `upgrade-environment` | Upgrades a DBmaestro target environment | `DBMAESTRO_TARGET_ENV`, `DBMAESTRO_PACKAGE_NAME` | — |
| `build-from-source` | Builds a package from source control (tasks/commit/all) | `DBMAESTRO_ENV_NAME`, `DBMAESTRO_VERSION_TYPE`, `DBMAESTRO_ADDITIONAL_INFORMATION` | — |

**Common inputs for all scripts:**

| Variable | Description |
|----------|-------------|
| `DBMAESTRO_SERVER` | Agent hostname and port (`host:port`) |
| `DBMAESTRO_USER` | DBmaestro username |
| `DBMAESTRO_PASSWORD` | DBmaestro password (always passed as a secret) |
| `DBMAESTRO_USE_SSL` | Enable SSL (`True` / `False`) |
| `DBMAESTRO_AUTH_TYPE` | Authentication type (`DBmaestroAccount`) |
| `DBMAESTRO_AGENT_JAR` | Path to the DBmaestro agent JAR file |
| `DBM_OUTPUT_FILE` | Path where the script writes key=value outputs |

---

## Platform Support

| Platform | Wrappers | Reusable pipeline | Examples |
|----------|----------|-------------------|---------|
| GitHub Actions | Composite actions (sh + ps) | Reusable workflows | `examples/github/` |
| GitLab CI | Hidden job templates (sh + ps) | `gitlab/templates/deploy.yml` | `examples/gitlab/` |
| Azure DevOps | Step templates (sh + ps) | `azure-devops/templates/deploy.yml` | `examples/azure-devops/` |

---

## Example Scenarios

Six end-to-end scenarios are provided for each platform:

| Example | Description |
|---------|-------------|
| `example-build-branch-name` | Uses the branch/MR name as the package name |
| `example-build-direct-actions` | Calls templates directly with a comma-separated package list |
| `example-build-git-changes` | Auto-detects changed packages from git diff |
| `example-build-manual-input` | Manually specify packages via pipeline trigger input |
| `example-build-source-control` | Builds from source control (all / specific tasks / specific commit) |
| `example-upgrade-environment` | Upgrades an environment with concurrency protection |

---

## Platform-specific READMEs

- [GitHub Actions →](.github/README.md)
- [GitLab CI →](gitlab/README.md)
- [Azure DevOps →](azure-devops/README.md)
