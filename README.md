# DBmaestro CI/CD Library

Reusable pipeline templates for automating [DBmaestro](https://www.dbmaestro.com/) database deployments — build packages, validate them, and promote them across environments. Supports **GitHub Actions**, **GitLab CI**, and **Azure DevOps** from a single shared core.

---

## Where to start

**New to this library?** Pick your platform and follow its setup guide:

| Platform | Setup guide | What's included |
|----------|-------------|-----------------|
| GitHub Actions | [examples/github/README.md](examples/github/README.md) | Composite actions + reusable workflows |
| Azure DevOps | [examples/azure-devops/README.md](examples/azure-devops/README.md) | Step templates + multi-stage pipelines |
| GitLab CI | [examples/gitlab/README.md](examples/gitlab/README.md) | Hidden job templates |

Each guide covers: prerequisites, secrets/variables, runner setup, approval gates, and a step-by-step walkthrough.

---

## What this library does

A typical DBmaestro pipeline has three stages:

```
1. Detect      — find which database packages changed in this PR or push
2. Build       — create the package and run a PreCheck (validation)
3. Upgrade     — promote the package to a target environment
```

This library provides pre-built implementations of all three stages for each CI/CD platform. You copy an example, fill in your project name and credentials, and the pipeline is ready to run.

---

## Example pipelines

Six scenarios are provided for each platform under `examples/{platform}/`:

| Example | Trigger | What it does |
|---------|---------|--------------|
| `example-integrated-pr-workflow` | PR + merge | **Recommended starting point.** Builds and validates on PR, upgrades `Release_Source` on merge, then prompts for approval before upgrading `Prod_Env_1`. |
| `example-build-git-changes` | PR / push | Auto-detects which packages changed via git diff and builds only those. |
| `example-build-manual-input` | Manual trigger | You specify package names at pipeline runtime — no detection needed. |
| `example-build-branch-name` | PR / push | Uses the branch or MR name as the package name. |
| `example-build-source-control` | Manual trigger | Builds from DBmaestro source control (all tasks / specific tasks / specific commit). |
| `example-upgrade-environment` | Push / manual | Standalone environment upgrade with serialization to prevent concurrent runs. |

---

## Repository structure

```
.
├── core/scripts/          # Platform-agnostic Bash (sh/) and PowerShell (ps/) scripts
│
├── .github/
│   ├── actions/           # Composite actions — sh/ (Linux) and ps/ (Windows/pwsh)
│   └── workflows/         # Reusable workflows (sh-build-validate, sh-upgrade-environment, …)
│
├── gitlab/templates/      # GitLab CI hidden job templates
├── azure-devops/templates/ # Azure DevOps step and job templates
│
└── examples/
    ├── github/            # Ready-to-use GitHub Actions workflows + setup guide
    ├── gitlab/            # Ready-to-use GitLab CI pipelines + setup guide
    └── azure-devops/      # Ready-to-use Azure DevOps pipelines + setup guide
```

All platform wrappers delegate to `core/scripts/` — the scripts are the single source of truth and can be run directly without any CI/CD platform if needed.

---

## Linux vs Windows

Each platform has two variants:

| Variant | Runner requirement | When to use |
|---------|--------------------|-------------|
| `sh` / Bash | Linux runner | Default — recommended for most setups |
| `ps` / PowerShell | Windows runner **or** Linux runner with `pwsh` | Required for Windows-only environments |

The examples default to the `sh` (Linux/Bash) variant.

---

## Platform-specific references

Deep-dive documentation for each platform's available actions, inputs, and outputs:

- [GitHub Actions reference](.github/README.md)
- [GitLab CI reference](gitlab/README.md)
- [Azure DevOps reference](azure-devops/README.md)
