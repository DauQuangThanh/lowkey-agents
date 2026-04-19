#!/bin/bash

# OPS Skill: ops-cicd (Phase 1)
# CI/CD Pipeline Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/01-cicd-pipeline.md"

# Banner
ops_banner "Phase 1: CI/CD Pipeline Design"

# Q1: CI/CD Platform
cicd_platform=$(ops_ask_choice \
    "Which CI/CD platform will you use?" \
    "GitHub Actions" \
    "GitLab CI" \
    "Azure DevOps" \
    "Jenkins" \
    "CircleCI" \
    "ArgoCD" \
    "Other / Not decided yet")

# Q2: Branching Strategy
branching_strategy=$(ops_ask_choice \
    "Which branching strategy?" \
    "GitFlow (release branches, main is production)" \
    "Trunk-based (feature branches, main always deployable)" \
    "GitHub Flow (pull requests, main is latest release)" \
    "Other / Hybrid approach")

# Q3: Build Stages
echo -e "${OPS_BLUE}Which build stages do you need? (select all that apply)${OPS_NC}"
declare -a build_stages
[ $(ops_ask_yn "Linting?") ] && build_stages+=("Lint")
[ $(ops_ask_yn "Unit tests?") ] && build_stages+=("Test")
[ $(ops_ask_yn "Build artifact?") ] && build_stages+=("Build")
[ $(ops_ask_yn "Package/containerize?") ] && build_stages+=("Package")
[ $(ops_ask_yn "Security scanning?") ] && build_stages+=("Security Scan")
[ $(ops_ask_yn "Integration tests?") ] && build_stages+=("Integration Tests")

# Q4: Artifact Storage
artifact_storage=$(ops_ask_choice \
    "Where do you store build artifacts?" \
    "Container Registry (ECR/GCR/ACR/Docker Hub)" \
    "AWS S3 / Azure Blob / GCS" \
    "Artifactory / Nexus" \
    "Not decided yet")

# Q5: Pipeline Triggers
echo -e "${OPS_BLUE}What triggers deployments? (select all that apply)${OPS_NC}"
declare -a triggers
[ $(ops_ask_yn "Push to branch?") ] && triggers+=("Push to branch")
[ $(ops_ask_yn "Pull Request / Merge Request?") ] && triggers+=("Pull Request")
[ $(ops_ask_yn "Scheduled (nightly/weekly)?") ] && triggers+=("Scheduled")
[ $(ops_ask_yn "Manual trigger?") ] && triggers+=("Manual")

# Q6: Environment Promotion
echo -e "${OPS_BLUE}Describe your environment promotion path (e.g., dev → qa → staging → prod)${OPS_NC}"
promotion_path=$(ops_ask "Example: dev -> staging -> prod, or dev -> qa -> staging -> prod")

# Q7: Approval Gates
approval_gates=$(ops_ask_choice \
    "How do you control production deployments?" \
    "Manual approval required before prod deployment" \
    "Automated checks only (no manual gate)" \
    "Hybrid (automated checks + manual approval)" \
    "Not applicable (continuous deployment)")

# Q8: Notification Channels
echo -e "${OPS_BLUE}Which notification channels should alert teams? (select all that apply)${OPS_NC}"
declare -a notifications
[ $(ops_ask_yn "Slack?") ] && notifications+=("Slack")
[ $(ops_ask_yn "Email?") ] && notifications+=("Email")
[ $(ops_ask_yn "Teams?") ] && notifications+=("Microsoft Teams")
[ $(ops_ask_yn "PagerDuty?") ] && notifications+=("PagerDuty")
[ $(ops_ask_yn "Custom webhooks?") ] && notifications+=("Custom Webhooks")

# Generate output
ops_banner "Generating Pipeline Specification"

{
    cat <<'EOF'
# Phase 1: CI/CD Pipeline Design

## Overview

This document defines the CI/CD pipeline architecture for the project. It covers source control strategy, build execution, artifact management, environment promotion, approval gates, and team notifications.

---

## 1. Pipeline Platform

EOF

    echo "**Selected Platform**: $cicd_platform"
    echo ""
    echo "### Platform Rationale"
    case "$(to_lower "$cicd_platform")" in
        "github actions")
            cat <<'GITHUB'
- **Strengths**: Native GitHub integration, free for public repos, strong community.
- **Best For**: GitHub-hosted projects, teams already in GitHub ecosystem.
- **Considerations**: Limited to GitHub, pricing for private repos with high compute usage.
GITHUB
            ;;
        "gitlab ci")
            cat <<'GITLAB'
- **Strengths**: Native CI/CD in GitLab, powerful, self-hostable.
- **Best For**: GitLab repositories, teams wanting full DevOps control.
- **Considerations**: Separate GitLab instance required for self-hosted.
GITLAB
            ;;
        "azure devops")
            cat <<'AZURE'
- **Strengths**: Deep Azure integration, powerful pipelines, YAML-based.
- **Best For**: Microsoft stack projects, Azure-deployed services.
- **Considerations**: Can be complex; free tier limitations.
AZURE
            ;;
        "jenkins")
            cat <<'JENKINS'
- **Strengths**: Self-hosted, extremely extensible, industry standard.
- **Best For**: Organizations needing full control, complex workflows.
- **Considerations**: Requires operational overhead, plugin management.
JENKINS
            ;;
        "circleci")
            cat <<'CIRCLE'
- **Strengths**: Cloud-native, easy setup, excellent documentation.
- **Best For**: SaaS-first teams, simple to complex pipelines.
- **Considerations**: Pricing can escalate with usage; less customization than Jenkins.
CIRCLE
            ;;
        "argocd")
            cat <<'ARGO'
- **Strengths**: GitOps native, Kubernetes-first, declarative.
- **Best For**: Kubernetes-based deployments, GitOps workflows.
- **Considerations**: Requires Kubernetes cluster; focuses on deployment, not build.
ARGO
            ;;
        *)
            echo "- Not yet decided. Recommend evaluating against team preferences and existing tooling."
            ;;
    esac

    echo ""
    echo "---"
    echo ""
    echo "## 2. Branching Strategy"
    echo ""
    echo "**Selected Strategy**: $branching_strategy"
    echo ""
    echo "### Strategy Details"
    case "$(to_lower "$branching_strategy")" in
        *"gitflow"*)
            cat <<'GF'
```
main (production, tagged releases)
  ├── release/v1.2.0 (release branch, merge to main and develop)
  └── hotfix/critical-bug (hotfix, merge to main and develop)
develop (integration, prerelease testing)
  ├── feature/new-auth
  ├── feature/refactor-api
  └── bugfix/login-issue (dev team branches)
```

- **Push to main**: Only merges from release/ or hotfix/ branches.
- **Push to develop**: Feature and bugfix branches merged after review.
- **Release Process**: Create release/ branch, bump version, release to main, tag, merge back to develop.
- **Hotfix Process**: Create hotfix/ from main, fix, merge to main (tag), merge to develop.
- **Pros**: Clear release management, supports multiple versions in production.
- **Cons**: More branches, complex merge management.
GF
            ;;
        *"trunk-based"*)
            cat <<'TB'
```
main (always deployable, source of truth)
  ├── feature/new-auth (short-lived, daily commits)
  ├── feature/refactor-api
  └── bugfix/login-issue
```

- **Push to main**: Only via PR after automated checks pass.
- **Feature branches**: Small, short-lived (1-2 days max).
- **Release**: Tag commit on main; deploy that tag to production.
- **Hotfix**: Branch from tag, fix, merge to main, re-tag.
- **Pros**: Simple, enables continuous deployment, less merge conflict.
- **Cons**: Requires strong test coverage and discipline.
TB
            ;;
        *"github flow"*)
            cat <<'GH'
```
main (production)
  ├── feature/new-auth (PR-based)
  ├── feature/refactor-api
  └── bugfix/login-issue
```

- **Push to main**: Only via approved Pull Request.
- **PR workflow**: Branch → Commit → PR → Review → Merge → Deploy.
- **Deploy**: Merged PRs automatically or manually deployed to production.
- **Hotfix**: PR directly from main, merged and deployed immediately.
- **Pros**: Simple, PR-centric, good for small teams.
- **Cons**: Less formal release management; harder for multi-version support.
GH
            ;;
        *)
            echo "- Custom or hybrid approach selected. Define branches and merge rules in pipeline configuration."
            ;;
    esac

    echo ""
    echo "---"
    echo ""
    echo "## 3. Build Stages"
    echo ""
    echo "**Selected Stages**: ${build_stages[*]:-None selected}"
    echo ""
    echo "### Stage Execution"
    cat <<'STAGES'
Build stages run sequentially (unless parallel is configured). Each stage can be parallelized further:

```
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
```

STAGES

    echo "### Stage Skipping Rules"
    echo ""
    echo "Some stages can be skipped based on branch or change type:"
    echo "- **Lint/Test**: Skip on docs-only changes (\.md, docs/ folder)"
    echo "- **Security Scan**: Always run (security-critical)"
    echo "- **Integration Tests**: Run on PRs to main; skip on feature branches if time-constrained"
    echo ""

    echo "---"
    echo ""
    echo "## 4. Artifact Storage & Management"
    echo ""
    echo "**Selected Storage**: $artifact_storage"
    echo ""
    echo "### Artifact Retention Policy"
    cat <<'RETENTION'
- **Production builds**: Keep indefinitely (tag with version).
- **Staging builds**: Keep for 30 days or last 20 builds.
- **Development builds**: Keep for 7 days or last 10 builds.
- **Failed builds**: Delete after 3 days (save space).
RETENTION

    echo ""
    echo "### Container Registry (if applicable)"
    echo ""
    echo "Example: Docker image tagging strategy"
    cat <<'TAGS'
```
registry.example.com/myapp:latest          # Latest commit to main
registry.example.com/myapp:v1.2.0          # Release tag
registry.example.com/myapp:sha-abc123      # Specific commit
registry.example.com/myapp:staging-latest  # Latest staging
registry.example.com/myapp:dev-latest      # Latest dev
```
TAGS

    echo ""
    echo "---"
    echo ""
    echo "## 5. Pipeline Triggers"
    echo ""
    echo "**Enabled Triggers**: ${triggers[*]:-None selected}"
    echo ""
    echo "### Trigger Rules"
    cat <<'TRIGGERS'
| Trigger | Stages | Destination | Manual Gate? |
|---------|--------|-------------|-------------|
| Push to main | All | Production | Per approval config |
| Push to develop/dev | Lint, Test, Build, Package | Staging | Usually automatic |
| Pull Request | Lint, Test, Build (no deploy) | Preview | No gate |
| Scheduled (nightly) | All | Staging (smoke tests) | Notification only |
| Manual | All | Any (user selects) | Always manual |
TRIGGERS

    echo ""
    echo "---"
    echo ""
    echo "## 6. Environment Promotion"
    echo ""
    echo "**Promotion Path**: $promotion_path"
    echo ""
    echo "### Promotion Rules"
    cat <<'PROMO'
- **Automatic**: Merge to branch automatically triggers deployment to corresponding environment.
- **Manual**: Merge happens; operator manually triggers promotion (e.g., via CLI or dashboard).
- **Gated**: Merge + automated checks + manual approval before each step.

Example (automatic promotion):
```
Push to feature/* → Build & test (fail = notification, no deploy)
Push to develop   → Build & test → Deploy to staging (automatic)
Merge to main     → Build & test → Deploy to production (with manual approval gate)
```
PROMO

    echo ""
    echo "---"
    echo ""
    echo "## 7. Approval Gates & Access Control"
    echo ""
    echo "**Approval Strategy**: $approval_gates"
    echo ""
    echo "### Production Deployment Matrix"
    cat <<'APPROVAL'
| Role | Can Approve | Can Deploy | Can Rollback |
|------|-------------|-----------|------------|
| Developer | No | No | No |
| Release Manager | Yes | Yes | Yes |
| DevOps / SRE | Yes | Yes | Yes |
| Engineering Manager | Yes (by config) | No | No |
| On-Call | Yes (during incidents) | Yes | Yes |
APPROVAL

    echo ""
    echo "### Branch Protection Rules"
    echo ""
    echo "For **main** (production):"
    echo "- Require PR review (min 2 reviewers recommended)"
    echo "- Require status checks to pass (lint, test, build)"
    echo "- Dismiss stale PR approvals on new commits"
    echo "- Require up-to-date branches before merge"
    echo "- Restrict who can merge (release managers / ops only)"
    echo ""
    echo "For **develop** (staging):"
    echo "- Require PR review (min 1 reviewer)"
    echo "- Require status checks to pass"
    echo "- Allow auto-merge after review"
    echo ""

    echo "---"
    echo ""
    echo "## 8. Notifications & Alerting"
    echo ""
    echo "**Notification Channels**: ${notifications[*]:-None selected}"
    echo ""
    echo "### Notification Rules"
    cat <<'NOTIF'
| Event | Severity | Slack | Email | PagerDuty |
|-------|----------|-------|-------|-----------|
| Build success | Info | #builds (thread) | No | No |
| Build failure | High | @team | Yes | No |
| Deployment to staging | Info | #deploys | No | No |
| Deployment to prod | High | @channel | Yes | On-call (if not 9-5) |
| Rollback | Critical | @team + thread | Yes | Yes |
| Post-deploy smoke test failure | High | #builds | Yes | Yes (after hours) |
NOTIF

    echo ""
    echo "### Slack Webhook Example"
    echo ""
    echo '```bash'
    echo 'curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \'
    echo '  -H "Content-Type: application/json" \'
    echo '  -d "{"text": "Deployment to production: SUCCESS", "channel": "#deploys"}"'
    echo '```'
    echo ""

    echo "---"
    echo ""
    echo "## 9. Pipeline YAML Template"
    echo ""

    case "$(to_lower "$cicd_platform")" in
        "github actions")
            cat <<'GHACTIONS'
### GitHub Actions Example

```yaml
name: Build & Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

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
            -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
            .

  security-scan:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
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
          IMAGE_TAG: ${{ github.sha }}

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
          IMAGE_TAG: ${{ github.sha }}
      - name: Smoke tests
        run: ./scripts/smoke-tests.sh
      - name: Complete canary rollout
        if: success()
        run: ./scripts/complete-canary.sh
```

GHACTIONS
            ;;
        *)
            cat <<'OTHER'
See platform documentation for YAML template examples. Common elements:
- Stages/jobs defined in declarative order
- Environment variables for secrets (use secure storage, never commit)
- Conditional execution (if branches, event types)
- Status checks and notifications
OTHER
            ;;
    esac

    echo ""
    echo "---"
    echo ""
    echo "## 10. OPS Debt & Next Steps"
    echo ""
    echo "### Known Gaps / Debt Items"
    echo ""
    echo "- [ ] Artifact retention policy not automated (manual cleanup)"
    echo "- [ ] No scheduled compliance/dependency scanning (add if security-critical)"
    echo "- [ ] Secret rotation not automated (manual Secrets Manager updates)"
    echo ""
    echo "### Immediate Actions"
    echo ""
    echo "1. **Set up CI/CD repository**: Create or configure pipeline files (.github/workflows/, .gitlab-ci.yml, etc.)"
    echo "2. **Configure artifact storage**: Set up Docker registry, S3 bucket, or Artifactory."
    echo "3. **Create deployment scripts**: Implement deploy-staging.sh, deploy-prod.sh, rollback.sh in ./scripts/."
    echo "4. **Set up notifications**: Configure Slack webhooks, email lists, PagerDuty integrations."
    echo "5. **Test end-to-end**: Trigger pipeline, verify build, deploy to staging, verify deployment."
    echo ""
    echo "---"
    echo ""
    echo "## 11. References"
    echo ""
    echo "- [GitHub Actions Documentation](https://docs.github.com/en/actions)"
    echo "- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)"
    echo "- [Azure DevOps Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/)"
    echo "- [Jenkins Documentation](https://www.jenkins.io/doc/)"
    echo "- [12 Factor App Methodology](https://12factor.net/)"
    echo "- [DORA Metrics & DevOps Assessment](https://dora.dev/)"
    echo ""
    echo "---"
    echo ""
    echo "**Generated**: $(date -u '+%Y-%m-%d %H:%M UTC')"
    echo "**Skill**: ops-cicd"

} > "$OUTPUT_FILE"

ops_success_rule "Pipeline specification written to $OUTPUT_FILE"

# Optional: Add debt items if manual processes detected
if [[ "$artifact_storage" == *"not decided"* ]]; then
    ops_add_debt \
        "Define artifact storage strategy" \
        "Artifact storage platform not yet selected. This blocks pipeline implementation." \
        "high" \
        "ops"
fi

if [[ "$approval_gates" == *"Not applicable"* ]]; then
    ops_add_debt \
        "Continuous Deployment without safety gates" \
        "Continuous deployment enabled without approval gates. Recommend adding manual gates for production." \
        "medium" \
        "ops"
fi

echo ""
echo "Next: Run ops-infrastructure skill to design Infrastructure-as-Code."
echo ""
