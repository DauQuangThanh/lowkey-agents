# OPS Skill: ops-cicd (Phase 1)
# CI/CD Pipeline Design

param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }


$outputFile = Join-Path $script:OPSOutputDir "01-cicd-pipeline.md"

# Banner
Write-OPS-Banner "Phase 1: CI/CD Pipeline Design"

# Q1: CI/CD Platform
$cicdPlatform = Ask-OPS-Choice `
    "Which CI/CD platform will you use?" `
    "GitHub Actions", `
    "GitLab CI", `
    "Azure DevOps", `
    "Jenkins", `
    "CircleCI", `
    "ArgoCD", `
    "Other / Not decided yet"

# Q2: Branching Strategy
$branchingStrategy = Ask-OPS-Choice `
    "Which branching strategy?" `
    "GitFlow (release branches, main is production)", `
    "Trunk-based (feature branches, main always deployable)", `
    "GitHub Flow (pull requests, main is latest release)", `
    "Other / Hybrid approach"

# Q3: Build Stages
Write-Host -ForegroundColor Blue "Which build stages do you need? (select all that apply)"
$buildStages = @()
if (Ask-OPS-YN "Linting?") { $buildStages += "Lint" }
if (Ask-OPS-YN "Unit tests?") { $buildStages += "Test" }
if (Ask-OPS-YN "Build artifact?") { $buildStages += "Build" }
if (Ask-OPS-YN "Package/containerize?") { $buildStages += "Package" }
if (Ask-OPS-YN "Security scanning?") { $buildStages += "Security Scan" }
if (Ask-OPS-YN "Integration tests?") { $buildStages += "Integration Tests" }

# Q4: Artifact Storage
$artifactStorage = Ask-OPS-Choice `
    "Where do you store build artifacts?" `
    "Container Registry (ECR/GCR/ACR/Docker Hub)", `
    "AWS S3 / Azure Blob / GCS", `
    "Artifactory / Nexus", `
    "Not decided yet"

# Q5: Pipeline Triggers
Write-Host -ForegroundColor Blue "What triggers deployments? (select all that apply)"
$triggers = @()
if (Ask-OPS-YN "Push to branch?") { $triggers += "Push to branch" }
if (Ask-OPS-YN "Pull Request / Merge Request?") { $triggers += "Pull Request" }
if (Ask-OPS-YN "Scheduled (nightly/weekly)?") { $triggers += "Scheduled" }
if (Ask-OPS-YN "Manual trigger?") { $triggers += "Manual" }

# Q6: Environment Promotion
Write-Host -ForegroundColor Blue "Describe your environment promotion path (e.g., dev -> qa -> staging -> prod)"
$promotionPath = Read-Host "Example: dev -> staging -> prod, or dev -> qa -> staging -> prod"

# Q7: Approval Gates
$approvalGates = Ask-OPS-Choice `
    "How do you control production deployments?" `
    "Manual approval required before prod deployment", `
    "Automated checks only (no manual gate)", `
    "Hybrid (automated checks + manual approval)", `
    "Not applicable (continuous deployment)"

# Q8: Notification Channels
Write-Host -ForegroundColor Blue "Which notification channels should alert teams? (select all that apply)"
$notifications = @()
if (Ask-OPS-YN "Slack?") { $notifications += "Slack" }
if (Ask-OPS-YN "Email?") { $notifications += "Email" }
if (Ask-OPS-YN "Teams?") { $notifications += "Microsoft Teams" }
if (Ask-OPS-YN "PagerDuty?") { $notifications += "PagerDuty" }
if (Ask-OPS-YN "Custom webhooks?") { $notifications += "Custom Webhooks" }

# Generate output
Write-OPS-Banner "Generating Pipeline Specification"

$content = @"
# Phase 1: CI/CD Pipeline Design

## Overview

This document defines the CI/CD pipeline architecture for the project. It covers source control strategy, build execution, artifact management, environment promotion, approval gates, and team notifications.

---

## 1. Pipeline Platform

**Selected Platform**: $cicdPlatform

### Platform Rationale

"@

switch -Wildcard ($cicdPlatform) {
    "*GitHub Actions*" {
        $content += @"

- **Strengths**: Native GitHub integration, free for public repos, strong community.
- **Best For**: GitHub-hosted projects, teams already in GitHub ecosystem.
- **Considerations**: Limited to GitHub, pricing for private repos with high compute usage.
"@
    }
    "*GitLab CI*" {
        $content += @"

- **Strengths**: Native CI/CD in GitLab, powerful, self-hostable.
- **Best For**: GitLab repositories, teams wanting full DevOps control.
- **Considerations**: Separate GitLab instance required for self-hosted.
"@
    }
    "*Azure DevOps*" {
        $content += @"

- **Strengths**: Deep Azure integration, powerful pipelines, YAML-based.
- **Best For**: Microsoft stack projects, Azure-deployed services.
- **Considerations**: Can be complex; free tier limitations.
"@
    }
    "*Jenkins*" {
        $content += @"

- **Strengths**: Self-hosted, extremely extensible, industry standard.
- **Best For**: Organizations needing full control, complex workflows.
- **Considerations**: Requires operational overhead, plugin management.
"@
    }
    "*CircleCI*" {
        $content += @"

- **Strengths**: Cloud-native, easy setup, excellent documentation.
- **Best For**: SaaS-first teams, simple to complex pipelines.
- **Considerations**: Pricing can escalate with usage; less customization than Jenkins.
"@
    }
    "*ArgoCD*" {
        $content += @"

- **Strengths**: GitOps native, Kubernetes-first, declarative.
- **Best For**: Kubernetes-based deployments, GitOps workflows.
- **Considerations**: Requires Kubernetes cluster; focuses on deployment, not build.
"@
    }
    default {
        $content += "`n- Not yet decided. Recommend evaluating against team preferences and existing tooling.`n"
    }
}

$content += @"

---

## 2. Branching Strategy

**Selected Strategy**: $branchingStrategy

### Strategy Details

"@

switch -Wildcard ($branchingStrategy) {
    "*GitFlow*" {
        $content += @"

\`\`\`
main (production, tagged releases)
  ├── release/v1.2.0 (release branch, merge to main and develop)
  └── hotfix/critical-bug (hotfix, merge to main and develop)
develop (integration, prerelease testing)
  ├── feature/new-auth
  ├── feature/refactor-api
  └── bugfix/login-issue (dev team branches)
\`\`\`

- **Push to main**: Only merges from release/ or hotfix/ branches.
- **Push to develop**: Feature and bugfix branches merged after review.
- **Release Process**: Create release/ branch, bump version, release to main, tag, merge back to develop.
- **Hotfix Process**: Create hotfix/ from main, fix, merge to main (tag), merge to develop.
- **Pros**: Clear release management, supports multiple versions in production.
- **Cons**: More branches, complex merge management.
"@
    }
    "*Trunk-based*" {
        $content += @"

\`\`\`
main (always deployable, source of truth)
  ├── feature/new-auth (short-lived, daily commits)
  ├── feature/refactor-api
  └── bugfix/login-issue
\`\`\`

- **Push to main**: Only via PR after automated checks pass.
- **Feature branches**: Small, short-lived (1-2 days max).
- **Release**: Tag commit on main; deploy that tag to production.
- **Hotfix**: Branch from tag, fix, merge to main, re-tag.
- **Pros**: Simple, enables continuous deployment, less merge conflict.
- **Cons**: Requires strong test coverage and discipline.
"@
    }
    "*GitHub Flow*" {
        $content += @"

\`\`\`
main (production)
  ├── feature/new-auth (PR-based)
  ├── feature/refactor-api
  └── bugfix/login-issue
\`\`\`

- **Push to main**: Only via approved Pull Request.
- **PR workflow**: Branch → Commit → PR → Review → Merge → Deploy.
- **Deploy**: Merged PRs automatically or manually deployed to production.
- **Hotfix**: PR directly from main, merged and deployed immediately.
- **Pros**: Simple, PR-centric, good for small teams.
- **Cons**: Less formal release management; harder for multi-version support.
"@
    }
    default {
        $content += "`n- Custom or hybrid approach selected. Define branches and merge rules in pipeline configuration.`n"
    }
}

$buildStagesStr = if ($buildStages.Count -gt 0) { [string]::Join(", ", $buildStages) } else { "None selected" }

$content += @"

---

## 3. Build Stages

**Selected Stages**: $buildStagesStr

### Stage Execution

Build stages run sequentially (unless parallel is configured). Each stage can be parallelized further:

\`\`\`
┌─────────────┐
│  Lint       │  (code quality, style checks)
└──────┬──────┘
       │
┌──────▼──────────┐
│  Test           │  (unit, integration tests)
└──────┬──────────┘
       │
┌──────▼──────────┐
│  Build          │  (compile, bundle, transpile)
└──────┬──────────┘
       │
┌──────▼──────────┐
│  Package        │  (Docker image, artifact archive)
└──────┬──────────┘
       │
┌──────▼──────────────────┐
│  Security Scan          │  (CVE scan, SAST, secret detection)
└──────┬──────────────────┘
       │
┌──────▼──────────┐
│  Integration    │  (e2e, smoke tests)
└────────────────┘
\`\`\`

### Stage Skipping Rules

Some stages can be skipped based on branch or change type:
- **Lint/Test**: Skip on docs-only changes (\.md, docs/ folder)
- **Security Scan**: Always run (security-critical)
- **Integration Tests**: Run on PRs to main; skip on feature branches if time-constrained

---

## 4. Artifact Storage & Management

**Selected Storage**: $artifactStorage

### Artifact Retention Policy

- **Production builds**: Keep indefinitely (tag with version).
- **Staging builds**: Keep for 30 days or last 20 builds.
- **Development builds**: Keep for 7 days or last 10 builds.
- **Failed builds**: Delete after 3 days (save space).

### Container Registry (if applicable)

Example: Docker image tagging strategy

\`\`\`
registry.example.com/myapp:latest          # Latest commit to main
registry.example.com/myapp:v1.2.0          # Release tag
registry.example.com/myapp:sha-abc123      # Specific commit
registry.example.com/myapp:staging-latest  # Latest staging
registry.example.com/myapp:dev-latest      # Latest dev
\`\`\`

---

## 5. Pipeline Triggers

**Enabled Triggers**: $([string]::Join(", ", $triggers))

### Trigger Rules

| Trigger | Stages | Destination | Manual Gate? |
|---------|--------|-------------|-------------|
| Push to main | All | Production | Per approval config |
| Push to develop/dev | Lint, Test, Build, Package | Staging | Usually automatic |
| Pull Request | Lint, Test, Build (no deploy) | Preview | No gate |
| Scheduled (nightly) | All | Staging (smoke tests) | Notification only |
| Manual | All | Any (user selects) | Always manual |

---

## 6. Environment Promotion

**Promotion Path**: $promotionPath

### Promotion Rules

- **Automatic**: Merge to branch automatically triggers deployment to corresponding environment.
- **Manual**: Merge happens; operator manually triggers promotion (e.g., via CLI or dashboard).
- **Gated**: Merge + automated checks + manual approval before each step.

Example (automatic promotion):
\`\`\`
Push to feature/* → Build & test (fail = notification, no deploy)
Push to develop   → Build & test → Deploy to staging (automatic)
Merge to main     → Build & test → Deploy to production (with manual approval gate)
\`\`\`

---

## 7. Approval Gates & Access Control

**Approval Strategy**: $approvalGates

### Production Deployment Matrix

| Role | Can Approve | Can Deploy | Can Rollback |
|------|-------------|-----------|------------|
| Developer | No | No | No |
| Release Manager | Yes | Yes | Yes |
| DevOps / SRE | Yes | Yes | Yes |
| Engineering Manager | Yes (by config) | No | No |
| On-Call | Yes (during incidents) | Yes | Yes |

### Branch Protection Rules

For **main** (production):
- Require PR review (min 2 reviewers recommended)
- Require status checks to pass (lint, test, build)
- Dismiss stale PR approvals on new commits
- Require up-to-date branches before merge
- Restrict who can merge (release managers / ops only)

For **develop** (staging):
- Require PR review (min 1 reviewer)
- Require status checks to pass
- Allow auto-merge after review

---

## 8. Notifications & Alerting

**Notification Channels**: $([string]::Join(", ", $notifications))

### Notification Rules

| Event | Severity | Slack | Email | PagerDuty |
|-------|----------|-------|-------|-----------|
| Build success | Info | #builds (thread) | No | No |
| Build failure | High | @team | Yes | No |
| Deployment to staging | Info | #deploys | No | No |
| Deployment to prod | High | @channel | Yes | On-call (if not 9-5) |
| Rollback | Critical | @team + thread | Yes | Yes |
| Post-deploy smoke test failure | High | #builds | Yes | Yes (after hours) |

### Slack Webhook Example

\`\`\`bash
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H "Content-Type: application/json" \
  -d '{"text": "Deployment to production: SUCCESS", "channel": "#deploys"}'
\`\`\`

---

## 9. Pipeline YAML Template

### GitHub Actions Example

\`\`\`yaml
name: Build & Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: \${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run linter
        run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: npm run test
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: |
          docker build \
            -t \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:\${{ github.sha }} \
            -t \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:latest \
            .

  security-scan:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:\${{ github.sha }}
          format: sarif
          output: trivy-results.sarif

  deploy-staging:
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to staging
        run: ./scripts/deploy-staging.sh
        env:
          IMAGE_TAG: \${{ github.sha }}

  deploy-prod:
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
      url: https://app.example.com
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production (canary)
        run: ./scripts/deploy-prod-canary.sh
        env:
          IMAGE_TAG: \${{ github.sha }}
      - name: Smoke tests
        run: ./scripts/smoke-tests.sh
      - name: Complete canary rollout
        if: success()
        run: ./scripts/complete-canary.sh
\`\`\`

---

## 10. OPS Debt & Next Steps

### Known Gaps / Debt Items

- [ ] Artifact retention policy not automated (manual cleanup)
- [ ] No scheduled compliance/dependency scanning (add if security-critical)
- [ ] Secret rotation not automated (manual Secrets Manager updates)

### Immediate Actions

1. **Set up CI/CD repository**: Create or configure pipeline files (.github/workflows/, .gitlab-ci.yml, etc.)
2. **Configure artifact storage**: Set up Docker registry, S3 bucket, or Artifactory.
3. **Create deployment scripts**: Implement deploy-staging.sh, deploy-prod.sh, rollback.sh in ./scripts/.
4. **Set up notifications**: Configure Slack webhooks, email lists, PagerDuty integrations.
5. **Test end-to-end**: Trigger pipeline, verify build, deploy to staging, verify deployment.

---

## 11. References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
- [Azure DevOps Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [12 Factor App Methodology](https://12factor.net/)
- [DORA Metrics & DevOps Assessment](https://dora.dev/)

---

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm UTC')
**Skill**: ops-cicd
"@

$content | Set-Content $outputFile

Write-OPS-SuccessRule "Pipeline specification written to $outputFile"

# Optional: Add debt items if manual processes detected
if ($artifactStorage -like "*not decided*") {
    Add-OPS-Debt `
        "Define artifact storage strategy" `
        "Artifact storage platform not yet selected. This blocks pipeline implementation." `
        "high" `
        "ops"
}

if ($approvalGates -like "*Not applicable*") {
    Add-OPS-Debt `
        "Continuous Deployment without safety gates" `
        "Continuous deployment enabled without approval gates. Recommend adding manual gates for production." `
        "medium" `
        "ops"
}

Write-Host ""
Write-Host "Next: Run ops-infrastructure skill to design Infrastructure-as-Code."
Write-Host ""
