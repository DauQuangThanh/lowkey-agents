#!/bin/bash
# =============================================================================
# elicit-requirements.sh — Phase 3: Functional Requirements Elicitation
# Category-by-category guided requirements gathering.
# Output: $BA_OUTPUT_DIR/03-requirements.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


OUTPUT_FILE="$BA_OUTPUT_DIR/03-requirements.md"
AREA="Requirements Elicitation"

start_debts=$(ba_current_debt_count)

REQ_COUNT=0
REQUIREMENTS=()

add_req() {
  REQ_COUNT=$((REQ_COUNT + 1))
  local id
  id=$(printf "FR-%03d" "$REQ_COUNT")
  REQUIREMENTS+=("$id|$1|$2|$3")
}

TOTAL_CATEGORIES=14
CAT_NUM=0

category_header() {
  CAT_NUM=$((CAT_NUM + 1))
  local cat="$1" desc="$2"
  echo ""
  ba_dim "  Category $CAT_NUM of $TOTAL_CATEGORIES"
  printf '%b%b── %s ──%b\n' "$BA_CYAN" "$BA_BOLD" "$cat" "$BA_NC"
  ba_dim "  $desc"
}

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "📝  Step 3 of 7 — Requirements Elicitation"
ba_dim "  I'll go through common feature categories one at a time."
ba_dim "  For each, answer y (yes) or n (no)."
echo ""

# ── 1. User Accounts ─────────────────────────────────────────────────────────
category_header "User Accounts" "Login, registration, profiles, and roles (who can see/do what)"
yn=$(ba_ask_yn "Does your system need User Accounts?")
if [ "$yn" = "yes" ]; then
  echo ""
  ba_dim "  Which of these do you need? (y/n for each)"
  has_reg=$(ba_ask_yn "  User registration (sign up with email/password)?")
  has_social=$(ba_ask_yn "  Social login (e.g. 'Sign in with Google')?")
  has_mfa=$(ba_ask_yn "  Two-factor authentication (extra security code at login)?")
  has_roles=$(ba_ask_yn "  Different roles/permissions (e.g. Admin vs Regular User)?")
  has_profile=$(ba_ask_yn "  User profiles (name, photo, preferences)?")
  has_reset=$(ba_ask_yn "  Password reset via email?")

  roles_detail="Standard roles"
  if [ "$has_roles" = "yes" ]; then
    roles_detail=$(ba_ask "  Briefly describe the roles needed (e.g. 'Admin, Manager, Staff, Customer'):")
    [ -z "$roles_detail" ] && roles_detail="Standard roles"
  fi

  [ "$has_reg" = "yes" ] && add_req "User Accounts" "Users can register, log in, and manage their accounts" "Must Have"
  [ "$has_social" = "yes" ] && add_req "User Accounts" "Users can log in using Google or similar social provider" "Should Have"
  [ "$has_mfa" = "yes" ] && add_req "User Accounts" "Two-factor authentication (MFA) available for users" "Should Have"
  [ "$has_roles" = "yes" ] && add_req "User Accounts" "Role-based access control: $roles_detail" "Must Have"
  [ "$has_profile" = "yes" ] && add_req "User Accounts" "Users can view and edit their profile information" "Should Have"
  [ "$has_reset" = "yes" ] && add_req "User Accounts" "Users can reset their password via email" "Must Have"
fi

# ── 2. Data Management ────────────────────────────────────────────────────────
category_header "Data Management" "Creating, viewing, editing, and deleting records (the core data of your system)"
yn=$(ba_ask_yn "Does your system need Data Management?")
if [ "$yn" = "yes" ]; then
  echo ""
  ba_dim "  What is the main type of data your system manages?"
  data_type=$(ba_ask "  (e.g. 'customer orders', 'patient records', 'inventory items')")
  if [ -z "$data_type" ]; then
    data_type="records"
    ba_add_debt "$AREA" "Core data type not specified" \
      "The main data entity of the system was not named" \
      "Cannot design data model or core screens"
  fi
  has_bulk=$(ba_ask_yn "  Do users need to import/export data via spreadsheet (CSV/Excel)?")
  has_search=$(ba_ask_yn "  Do users need to search or filter records?")
  has_history=$(ba_ask_yn "  Should the system keep a history of changes to records?")

  add_req "Data Management" "Users can create, view, edit, and delete $data_type" "Must Have"
  [ "$has_bulk" = "yes" ] && add_req "Data Management" "Users can import/export $data_type via CSV or Excel" "Should Have"
  [ "$has_search" = "yes" ] && add_req "Data Management" "Users can search and filter $data_type by key fields" "Must Have"
  [ "$has_history" = "yes" ] && add_req "Data Management" "System maintains an audit history of changes to $data_type" "Should Have"
fi

# ── 3. Reporting & Analytics ──────────────────────────────────────────────────
category_header "Reporting & Analytics" "Charts, dashboards, summaries, and data exports"
yn=$(ba_ask_yn "Does your system need Reporting & Analytics?")
if [ "$yn" = "yes" ]; then
  echo ""
  report_type=$(ba_ask_choice "  What kind of reporting is most important?" \
    "Simple summary tables (total counts, basic stats)" \
    "Charts and graphs (trends over time, comparisons)" \
    "Full dashboard with multiple views" \
    "Scheduled reports sent by email" \
    "All of the above")
  has_export=$(ba_ask_yn "  Can users export reports to PDF or Excel?")

  add_req "Reporting" "System provides $report_type for relevant data" "Must Have"
  [ "$has_export" = "yes" ] && add_req "Reporting" "Users can export reports to PDF and/or Excel format" "Should Have"
fi

# ── 4. Notifications ──────────────────────────────────────────────────────────
category_header "Notifications" "Automatic alerts sent to users when something happens"
yn=$(ba_ask_yn "Does your system need Notifications?")
if [ "$yn" = "yes" ]; then
  echo ""
  notif_channel=$(ba_ask_choice "  How should notifications be delivered?" \
    "Email only" \
    "In-app notifications only (a bell icon inside the system)" \
    "Both email and in-app" \
    "SMS text messages" \
    "Multiple channels — I'll specify later")
  if [ "$notif_channel" = "Multiple channels — I'll specify later" ]; then
    ba_add_debt "$AREA" "Notification channels not specified" \
      "Multiple channels were indicated but not confirmed" \
      "Cannot implement notification system without knowing channels"
  fi

  notif_trigger=$(ba_ask "  What should trigger a notification? (e.g. 'when a new order is placed', 'when a task is assigned to me')")
  if [ -z "$notif_trigger" ]; then
    notif_trigger="TBD"
    ba_add_debt "$AREA" "Notification triggers not defined" \
      "Events that trigger notifications were not specified" \
      "Cannot build notification logic"
  fi

  add_req "Notifications" "System sends notifications via $notif_channel when: $notif_trigger" "Must Have"
fi

# ── 5. Integrations ───────────────────────────────────────────────────────────
category_header "Integrations" "Connecting with other software systems (e.g. accounting, CRM, payment gateways)"
yn=$(ba_ask_yn "Does your system need Integrations?")
if [ "$yn" = "yes" ]; then
  echo ""
  integration_name=$(ba_ask "  What system(s) should it connect to? (e.g. 'Salesforce, QuickBooks, Stripe')")
  if [ -z "$integration_name" ]; then
    integration_name="TBD"
    ba_add_debt "$AREA" "Integration targets not specified" \
      "Integrations were confirmed but no systems were named" \
      "Cannot estimate integration complexity or cost"
  fi
  add_req "Integrations" "System integrates with: $integration_name" "Must Have"
fi

# ── 6. Payments ───────────────────────────────────────────────────────────────
category_header "Payments" "Accepting online payments, subscriptions, or invoicing"
yn=$(ba_ask_yn "Does your system need Payments?")
if [ "$yn" = "yes" ]; then
  echo ""
  payment_type=$(ba_ask_choice "  What type of payment processing is needed?" \
    "One-time payments (e.g. purchase a product)" \
    "Recurring subscriptions (e.g. monthly/annual plan)" \
    "Invoice generation and manual payment" \
    "All of the above")
  add_req "Payments" "System supports $payment_type" "Must Have"
  ba_add_debt "$AREA" "Payment provider not selected" \
    "Payment processing is required but no provider (e.g. Stripe, PayPal) was chosen" \
    "Technology and compliance decisions depend on provider"
fi

# ── 7. File Handling ──────────────────────────────────────────────────────────
category_header "File Handling" "Uploading, downloading, and managing documents, images, or attachments"
yn=$(ba_ask_yn "Does your system need File Handling?")
if [ "$yn" = "yes" ]; then
  echo ""
  file_types=$(ba_ask "  What file types? (e.g. 'PDF, images, Word documents')")
  if [ -z "$file_types" ]; then
    file_types="TBD"
    ba_add_debt "$AREA" "Accepted file types not specified" \
      "File handling is needed but accepted formats not confirmed" \
      "Storage, validation, and security rules depend on file types"
  fi
  add_req "File Handling" "Users can upload, download, and manage files: $file_types" "Must Have"
fi

# ── 8. Workflows & Approvals ─────────────────────────────────────────────────
category_header "Workflows & Approvals" "Multi-step processes where actions must be reviewed or approved"
yn=$(ba_ask_yn "Does your system need Workflows & Approvals?")
if [ "$yn" = "yes" ]; then
  echo ""
  workflow_desc=$(ba_ask "  Describe the main approval workflow in plain terms (e.g. 'Staff submits leave request → Manager approves → HR records it')")
  if [ -z "$workflow_desc" ]; then
    workflow_desc="TBD"
    ba_add_debt "$AREA" "Approval workflow not described" \
      "An approval workflow is needed but steps are undefined" \
      "Cannot design workflow engine or state machine"
  fi
  add_req "Workflows" "System supports the following approval workflow: $workflow_desc" "Must Have"
fi

# ── 9. Communication / Collaboration ─────────────────────────────────────────
category_header "Communication / Collaboration" "In-system messaging, comments, or team collaboration features"
yn=$(ba_ask_yn "Does your system need Communication / Collaboration?")
if [ "$yn" = "yes" ]; then
  echo ""
  comm_type=$(ba_ask_choice "  What kind of communication features are needed?" \
    "Comments on records (like comments on a document)" \
    "Direct messaging between users" \
    "Team channels (like a simple Slack inside the app)" \
    "All of the above")
  add_req "Communication" "System includes: $comm_type" "Should Have"
fi

# ── 10. Mobile Access ─────────────────────────────────────────────────────────
category_header "Mobile Access" "Using the system on phones or tablets"
yn=$(ba_ask_yn "Does your system need Mobile Access?")
if [ "$yn" = "yes" ]; then
  echo ""
  mobile_type=$(ba_ask_choice "  What type of mobile access is required?" \
    "Mobile-friendly website (works in phone browser)" \
    "Native iOS app (Apple)" \
    "Native Android app" \
    "Both iOS and Android native apps")
  add_req "Mobile" "System supports: $mobile_type" "Must Have"
fi

# ── 11. Admin Panel ───────────────────────────────────────────────────────────
category_header "Admin / Configuration Panel" "Settings area where administrators configure the system"
yn=$(ba_ask_yn "Does your system need an Admin Panel?")
if [ "$yn" = "yes" ]; then
  echo ""
  admin_features=$(ba_ask "  What should admins be able to do? (e.g. 'manage users, configure email templates, view system logs')")
  if [ -z "$admin_features" ]; then
    admin_features="Standard admin functions"
    ba_add_debt "$AREA" "Admin panel scope undefined" \
      "An admin panel is needed but features were not specified" \
      "Cannot scope admin module"
  fi
  add_req "Admin" "Admin panel allows: $admin_features" "Must Have"
fi

# ── 12. Multi-language / Multi-region ────────────────────────────────────────
category_header "Multi-language / Multi-region" "Different languages, currencies, or time zones"
yn=$(ba_ask_yn "Does your system need Multi-language or Multi-region support?")
if [ "$yn" = "yes" ]; then
  echo ""
  languages=$(ba_ask "  Which languages/regions? (e.g. 'English and Vietnamese, VND and USD')")
  if [ -z "$languages" ]; then
    languages="TBD"
    ba_add_debt "$AREA" "Languages/regions not specified" \
      "Multi-language support was confirmed but languages not named" \
      "Cannot estimate localisation effort"
  fi
  add_req "Localisation" "System supports: $languages" "Must Have"
fi

# ── 13. Offline Mode ──────────────────────────────────────────────────────────
category_header "Offline Mode" "Using the system without an internet connection"
yn=$(ba_ask_yn "Does your system need Offline Mode?")
if [ "$yn" = "yes" ]; then
  echo ""
  offline_features=$(ba_ask "  What should work offline? (e.g. 'view records and add new ones; sync when back online')")
  if [ -z "$offline_features" ]; then
    offline_features="TBD"
    ba_add_debt "$AREA" "Offline feature scope undefined" \
      "Offline mode confirmed but specific features not defined" \
      "Offline/sync architecture decisions depend on scope"
  fi
  add_req "Offline" "Offline mode supports: $offline_features" "Must Have"
fi

# ── 14. Other ─────────────────────────────────────────────────────────────────
echo ""
ba_dim "  Category $TOTAL_CATEGORIES of $TOTAL_CATEGORIES"
printf '%b%b── Anything Else? ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Is there any other feature that's important but wasn't covered above?"
has_other=$(ba_ask_yn "Any other important features not covered?")
if [ "$has_other" = "yes" ]; then
  other_desc=$(ba_ask "  Describe the feature briefly:")
  [ -z "$other_desc" ] && other_desc="TBD"
  add_req "Other" "$other_desc" "TBD"
  ba_add_debt "$AREA" "Additional feature detail missing" \
    "User indicated another feature but did not provide enough detail: '$other_desc'" \
    "Needs further elicitation"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
ba_success_rule "✅ Requirements Summary ($REQ_COUNT requirements captured)"
for r in "${REQUIREMENTS[@]+"${REQUIREMENTS[@]}"}"; do
  IFS='|' read -r id cat desc pri <<EOF
$r
EOF
  printf '  %b[%s]%b (%s) [%s] %s\n' "$BA_BOLD" "$id" "$BA_NC" "$pri" "$cat" "$desc"
done
echo ""

if ! ba_confirm_save "Save these requirements? (y=save / n=redo)"; then
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Functional Requirements"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Requirements List"
  echo ""
  echo "| ID | Category | Requirement | Priority |"
  echo "|---|---|---|---|"
  for r in "${REQUIREMENTS[@]+"${REQUIREMENTS[@]}"}"; do
    IFS='|' read -r id cat desc pri <<EOF
$r
EOF
    echo "| $id | $cat | $desc | $pri |"
  done
  echo ""
  echo "## Summary"
  echo ""
  echo "Total functional requirements captured: $REQ_COUNT"
  echo ""
} > "$OUTPUT_FILE"

end_debts=$(ba_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$BA_GREEN" "$OUTPUT_FILE" "$BA_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d debt(s) logged.%b\n' "$BA_YELLOW" "$new_debts" "$BA_NC"
fi
echo ""
