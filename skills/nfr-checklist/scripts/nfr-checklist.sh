#!/bin/bash
# =============================================================================
# nfr-checklist.sh — Phase 5: Non-Functional Requirements Checklist
# Captures quality attributes: performance, security, scalability, etc.
# Output: $BA_OUTPUT_DIR/05-nfr.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


OUTPUT_FILE="$BA_OUTPUT_DIR/05-nfr.md"
AREA="Non-Functional Requirements"

start_debts=$(ba_current_debt_count)

NFRS=()
add_nfr() { NFRS+=("| **$1** | $2 | $3 |"); }

nfr_section() {
  local num="$1" total="$2" area="$3" plain_desc="$4"
  echo ""
  ba_dim "  $num of $total"
  printf '%b%b── %s ──%b\n' "$BA_CYAN" "$BA_BOLD" "$area" "$BA_NC"
  ba_dim "  $plain_desc"
}

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "⚙  Step 5 of 7 — Non-Functional Requirements"
ba_dim "  These questions are about HOW the system should behave — not WHAT it does."
ba_dim "  Examples: how fast, how secure, how many users it can handle at once."
echo ""

# ── 1. Performance ────────────────────────────────────────────────────────────
nfr_section 1 9 "Performance" "How fast the system must respond to users"
yn=$(ba_ask_yn "Is performance a concern for your project?")
if [ "$yn" = "yes" ]; then
  echo ""
  users=$(ba_ask_choice "  How many users do you expect at the same time?" \
    "Under 10 — Very small team" \
    "10–100 — Small organisation" \
    "100–1,000 — Medium sized" \
    "1,000–10,000 — Large" \
    "Over 10,000 — Public scale")
  load_time=$(ba_ask_choice "  How fast should pages/actions load?" \
    "Under 1 second (instant feel)" \
    "Under 3 seconds (acceptable)" \
    "Under 5 seconds (tolerable)" \
    "No strict requirement")
  add_nfr "Performance" "Concurrent users: $users | Page load target: $load_time" "Must Have"
fi

# ── 2. Security ───────────────────────────────────────────────────────────────
nfr_section 2 9 "Security" "Protecting data and preventing unauthorised access"
yn=$(ba_ask_yn "Does the system handle sensitive or private data?")
if [ "$yn" = "yes" ]; then
  echo ""
  data_type=$(ba_ask_choice "  What kind of sensitive data? (choose the most sensitive)" \
    "General personal info (names, emails, addresses)" \
    "Financial data (payment info, bank details)" \
    "Health or medical records" \
    "Legal or confidential business data" \
    "Multiple types — all of the above")
  has_encryption=$(ba_ask_yn "  Must data be encrypted at rest AND in transit (HTTPS)?")
  has_audit=$(ba_ask_yn "  Must security events (logins, failed attempts) be logged?")

  enc_note="Yes — encryption required (HTTPS + at-rest)"
  [ "$has_encryption" = "no" ] && enc_note="Standard HTTPS only"
  audit_note="Yes"
  [ "$has_audit" = "no" ] && audit_note="No"

  add_nfr "Security" "Sensitive data type: $data_type | Encryption: $enc_note | Audit log: $audit_note" "Must Have"
  ba_add_debt "$AREA" "Security requirements need expert review" \
    "Security NFRs captured but need review by a security professional" \
    "Compliance gaps may create legal risk"
fi

# ── 3. Scalability ────────────────────────────────────────────────────────────
nfr_section 3 9 "Scalability" "How much the system might grow in users or data"
yn=$(ba_ask_yn "Do you expect significant growth in users or data in the next 1–3 years?")
if [ "$yn" = "yes" ]; then
  echo ""
  growth=$(ba_ask_choice "  Expected growth rate:" \
    "2× — Double in size" \
    "5× — Five times bigger" \
    "10× — Ten times bigger" \
    "100×+ — Massive growth (public product)")
  add_nfr "Scalability" "System must scale to $growth current capacity within 1–3 years" "Should Have"
fi

# ── 4. Availability ───────────────────────────────────────────────────────────
nfr_section 4 9 "Availability / Uptime" "How often the system must be running without downtime"
yn=$(ba_ask_yn "Is high availability or uptime important?")
if [ "$yn" = "yes" ]; then
  echo ""
  uptime=$(ba_ask_choice "  Required availability level:" \
    "99% — About 3.6 days downtime per year (business hours only)" \
    "99.5% — About 1.8 days downtime per year" \
    "99.9% — About 8.7 hours downtime per year (standard SLA)" \
    "99.99% — About 52 minutes downtime per year (high availability)" \
    "24/7 zero tolerance — Mission critical")
  maint_window=$(ba_ask_yn "  Can maintenance happen at night/weekends? (planned downtime OK?)")
  maint_note="Planned maintenance windows allowed"
  [ "$maint_window" = "no" ] && maint_note="No planned downtime — zero-downtime deployments required"
  add_nfr "Availability" "Target: $uptime | Maintenance: $maint_note" "Must Have"
fi

# ── 5. Usability ─────────────────────────────────────────────────────────────
nfr_section 5 9 "Usability & Accessibility" "How easy the system is to use"
yn=$(ba_ask_yn "Are there specific usability or accessibility requirements?")
if [ "$yn" = "yes" ]; then
  echo ""
  has_a11y=$(ba_ask_yn "  Must the system comply with accessibility standards (e.g. for visually impaired users)?")
  user_skill=$(ba_ask_choice "  What is the expected technical skill level of most users?" \
    "Non-technical — No IT background" \
    "Mixed — Some technical, some not" \
    "Technical — All users are IT-savvy")
  a11y_note="No formal standard"
  [ "$has_a11y" = "yes" ] && a11y_note="WCAG 2.1 AA compliance required"
  add_nfr "Usability" "Target user skill: $user_skill | Accessibility: $a11y_note" "Should Have"
fi

# ── 6. Data Retention ─────────────────────────────────────────────────────────
nfr_section 6 9 "Data Retention" "How long data must be kept and when it can be deleted"
yn=$(ba_ask_yn "Are there rules about how long data must be stored?")
if [ "$yn" = "yes" ]; then
  echo ""
  retention=$(ba_ask_choice "  How long must records be kept?" \
    "1 year" \
    "3 years" \
    "5 years" \
    "7 years (common legal/tax requirement)" \
    "Indefinitely" \
    "Defined by regulation — not yet confirmed")
  if [ "$retention" = "Defined by regulation — not yet confirmed" ]; then
    ba_add_debt "$AREA" "Data retention period not confirmed" \
      "Retention is required but the specific duration is not confirmed" \
      "Legal and storage architecture depend on this"
  fi
  add_nfr "Data Retention" "Records must be retained for: $retention" "Must Have"
fi

# ── 7. Compliance ─────────────────────────────────────────────────────────────
nfr_section 7 9 "Regulatory Compliance" "Legal or industry standards the system must meet"
yn=$(ba_ask_yn "Must the system comply with any specific regulations or standards?")
if [ "$yn" = "yes" ]; then
  echo ""
  ba_dim "  Check all that apply (y/n for each):"
  has_gdpr=$(ba_ask_yn "  GDPR — European data privacy rules?")
  has_hipaa=$(ba_ask_yn "  HIPAA — US healthcare data rules?")
  has_pci=$(ba_ask_yn "  PCI-DSS — Payment card security rules?")
  has_iso=$(ba_ask_yn "  ISO 27001 — Information security management?")
  has_other_reg=$(ba_ask_yn "  Any other regulation not listed?")
  other_reg=""
  if [ "$has_other_reg" = "yes" ]; then
    other_reg=$(ba_ask "  Name the regulation(s):")
    if [ -z "$other_reg" ]; then
      ba_add_debt "$AREA" "Unknown compliance requirement" \
        "User indicated other regulations but did not specify" \
        "Legal exposure if compliance missed"
    fi
  fi

  compliance_list=""
  [ "$has_gdpr"  = "yes" ] && compliance_list="${compliance_list}GDPR, "
  [ "$has_hipaa" = "yes" ] && compliance_list="${compliance_list}HIPAA, "
  [ "$has_pci"   = "yes" ] && compliance_list="${compliance_list}PCI-DSS, "
  [ "$has_iso"   = "yes" ] && compliance_list="${compliance_list}ISO 27001, "
  [ -n "$other_reg" ] && compliance_list="${compliance_list}${other_reg}, "
  # Trim trailing ", "
  compliance_list=$(printf '%s' "$compliance_list" | sed -e 's/, $//')

  [ -n "$compliance_list" ] && add_nfr "Compliance" "Must comply with: $compliance_list" "Must Have"
  ba_add_debt "$AREA" "Compliance requirements need legal review" \
    "Compliance standards identified but not yet validated with legal/compliance team" \
    "Non-compliance creates legal and financial risk"
fi

# ── 8. Backup & Recovery ──────────────────────────────────────────────────────
nfr_section 8 9 "Backup & Disaster Recovery" "What happens if the system fails or data is lost"
yn=$(ba_ask_yn "Do you have requirements for backup and recovery?")
if [ "$yn" = "yes" ]; then
  echo ""
  rto=$(ba_ask_choice "  RTO — How quickly must the system be back online after a failure?" \
    "Under 1 hour" \
    "Under 4 hours" \
    "Under 24 hours" \
    "Within 1 week" \
    "No strict requirement")
  rpo=$(ba_ask_choice "  RPO — How much data loss is acceptable in a worst case?" \
    "Zero — No data can be lost" \
    "Up to 1 hour of data" \
    "Up to 24 hours of data" \
    "Up to 1 week of data")
  add_nfr "Backup & Recovery" "Recovery Time Objective (RTO): $rto | Recovery Point Objective (RPO): $rpo" "Must Have"
fi

# ── 9. Other NFR ─────────────────────────────────────────────────────────────
nfr_section 9 9 "Other Quality Requirements" "Anything else about how the system must behave"
yn=$(ba_ask_yn "Any other quality or constraint requirements not covered?")
if [ "$yn" = "yes" ]; then
  other_nfr=$(ba_ask "  Describe briefly:")
  if [ -z "$other_nfr" ]; then
    other_nfr="TBD"
    ba_add_debt "$AREA" "Additional NFR not specified" \
      "User indicated another quality requirement but did not provide detail" \
      "May affect architecture"
  fi
  add_nfr "Other" "$other_nfr" "TBD"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
ba_success_rule "✅ Non-Functional Requirements Summary (${#NFRS[@]} captured)"
for n in "${NFRS[@]+"${NFRS[@]}"}"; do printf '  %s\n' "$n"; done
echo ""

if ! ba_confirm_save "Save? (y=save / n=redo)"; then
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Non-Functional Requirements"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## NFR Table"
  echo ""
  echo "| Area | Requirement | Priority |"
  echo "|---|---|---|"
  for n in "${NFRS[@]+"${NFRS[@]}"}"; do echo "$n"; done
  echo ""
  echo "## Notes"
  echo ""
  echo "NFR count: ${#NFRS[@]}"
  echo ""
  echo "> ⚠ Non-functional requirements should be reviewed by a technical architect"
  echo "> to ensure they are realistic and achievable within budget."
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ba_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$BA_GREEN" "$OUTPUT_FILE" "$BA_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d debt(s) logged.%b\n' "$BA_YELLOW" "$new_debts" "$BA_NC"
fi
echo ""
