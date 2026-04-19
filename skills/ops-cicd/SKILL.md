---
name: ops-cicd
description: "Design and document a comprehensive CI/CD pipeline architecture: branching strategy, build stages, artifact storage, environment promotion, approval gates, and notification channels. Produces a detailed pipeline specification with YAML templates, branch protection rules, and deployment approval matrices."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 1
---

# Phase 1: CI/CD Pipeline Design

## Overview

This skill guides you through designing a complete CI/CD pipeline for your project. It covers source control strategy, build stages, artifact management, environment promotion, approval gates, and notifications.

## Session Flow

1. Loads output directory and debt file paths
2. Asks 8 strategic questions about your pipeline preferences
3. Generates a detailed pipeline specification including:
   - Architecture overview
   - YAML templates for your chosen platform
   - Branch protection and promotion strategy
   - Approval gate matrix
   - Notification configuration

## Key Decisions

- **CI/CD Platform**: GitHub Actions, GitLab CI, Azure DevOps, Jenkins, CircleCI, ArgoCD
- **Branching Strategy**: GitFlow, Trunk-based, GitHub Flow
- **Build Stages**: Lint, test, build, package, security scan, deploy
- **Artifact Storage**: Container registry, S3, Artifactory, Nexus
- **Pipeline Triggers**: Push, PR, scheduled, manual, webhook
- **Environment Promotion**: dev → QA → staging → prod (configurable hops)
- **Approval Gates**: Manual vs. automated gatekeeping
- **Notifications**: Slack, Email, Teams, PagerDuty, custom webhooks

## Output

- `ops-output/01-cicd-pipeline.md`: Complete pipeline specification
- `ops-output/07-ops-debts.md`: Updated with any cicd-related debt (appended)

## Usage

```bash
# Bash (Linux/macOS)
./scripts/cicd.sh

# PowerShell (Windows)
./scripts/cicd.ps1
```

## Template Examples

### GitHub Actions Pipeline
```yaml
name: Build & Deploy
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm run test

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t app:${{ github.sha }} .

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/dev'
    runs-on: ubuntu-latest
    steps:
      - run: ./scripts/deploy-staging.sh

  deploy-prod:
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: ./scripts/deploy-prod.sh
```

### GitFlow Branching
```
main (production)
  ├── release/v1.2.0
  └── hotfix/critical-bug
develop (staging)
  ├── feature/new-auth
  ├── feature/refactor-api
  └── bugfix/login-issue
```

## Notes

- All outputs are idempotent; re-running updates the output files.
- Debt items are tracked separately for ops-level prioritization.
- Output assumes team wants to move toward automation; manual gates are documented but discouraged.
