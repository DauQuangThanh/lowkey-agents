#!/bin/bash

# OPS Skill: ops-monitoring (Phase 4)
# Monitoring & Observability Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/04-monitoring.md"

ops_banner "Phase 4: Monitoring & Observability Design"

ops_ask_choice "Logging Platform?" \
    "ELK Stack" \
    "Loki" \
    "CloudWatch" \
    "Splunk" \
    "Datadog" \
    "Not decided yet" > /dev/null

{
    cat <<'EOF'
# Phase 4: Monitoring & Observability Design

## Status

This is a placeholder. Full implementation includes:

1. **Logs** - ELK, Loki, CloudWatch, Splunk, Datadog selection
2. **Metrics** - Prometheus, CloudWatch, Datadog, New Relic
3. **Traces** - Jaeger, Zipkin, OpenTelemetry, X-Ray
4. **Alerting Rules** - Critical thresholds, escalation policies
5. **On-Call Rotation** - PagerDuty, OpsGenie, or custom
6. **SLO/SLI Definitions** - Availability, latency, error rate targets
7. **Dashboard Specifications** - Key metrics per service
8. **Incident Response Playbook** - Escalation and communication

## Three Pillars

- **Logs**: Application and infrastructure logs for debugging
- **Metrics**: Time-series data for performance monitoring
- **Traces**: Request flows across distributed systems

## Next Steps

Run the full skill for complete observability architecture.

EOF
} > "$OUTPUT_FILE"

ops_success_rule "Monitoring specification placeholder written to $OUTPUT_FILE"
echo ""
echo "Next: Run ops-deployment skill."
echo ""
