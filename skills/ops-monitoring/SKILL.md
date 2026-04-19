---
name: ops-monitoring
description: "Design monitoring and observability: logs, metrics, traces (three pillars), alerting rules, on-call rotation, SLO/SLI definitions, dashboard requirements, and incident response planning. Produces observability architecture, alert templates, SLO matrix, and incident response runbook skeleton."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 4
---

# Phase 4: Monitoring & Observability Design

## Overview

This skill guides you through designing comprehensive monitoring and observability: logs, metrics, traces, alerting, on-call, SLO/SLI, dashboards, and incident response.

## Session Flow

1. Loads output directory and debt file paths
2. Asks 8 strategic questions about observability preferences
3. Generates detailed monitoring specification including:
   - Three pillars: logs, metrics, traces
   - Alerting rules and thresholds
   - On-call rotation strategy
   - SLO/SLI definitions per service
   - Dashboard specifications
   - Incident response playbook skeleton

## Key Decisions

- **Logs**: ELK Stack, Loki, CloudWatch, Splunk, Datadog
- **Metrics**: Prometheus, Datadog, CloudWatch, New Relic, Grafana
- **Traces**: Jaeger, Zipkin, OpenTelemetry, X-Ray, Datadog
- **Alerting**: Critical thresholds, escalation policies, on-call notification
- **On-Call**: PagerDuty, OpsGenie, custom, informal rotation
- **SLO/SLI**: Availability, latency, error rate targets
- **Dashboards**: System health, application performance, business metrics
- **Incident Response**: Escalation paths, communication channels, postmortem process

## Output

- `ops-output/04-monitoring.md`: Complete monitoring specification
- `ops-output/07-ops-debts.md`: Updated with monitoring-related debt

## Usage

```bash
# Bash (Linux/macOS)
./scripts/monitoring.sh

# PowerShell (Windows)
./scripts/monitoring.ps1
```

## Notes

- Observability is foundational: if you can't measure it, you can't improve it.
- The three pillars (logs, metrics, traces) work together; don't implement just one.
- SLO/SLI definitions drive reliability engineering; define them early.
- Incident response playbooks prevent panic and reduce MTTR.
