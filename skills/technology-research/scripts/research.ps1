# =============================================================================
# research.ps1 — Phase 2: Technology Research (PowerShell)
# Output: $ArchOutputDir\02-technology-research.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }


$OutputFile = Join-Path $script:ArchOutputDir "02-technology-research.md"
$Area       = "Technology Research"

$startTDebts = Get-Arch-TDebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-Arch-Banner "🔍  Step 2 of 6 — Technology Research"
Write-Arch-Dim "  For each decision area in scope, we'll capture 2–3 candidate technologies"
Write-Arch-Dim "  with their trade-offs. The agent should pair this with WebSearch/WebFetch"
Write-Arch-Dim "  to verify facts — never cite a version or price you haven't confirmed."
Write-Host ""

# ── Init output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$header = @"
# Technology Research

> Captured: $DateNow

Candidate technologies per architectural decision area. Each candidate is rated for
fit against the constraints captured in ``01-architecture-intake.md``.

| Field | Meaning |
|---|---|
| Maturity | Emerging / Established / Declining |
| Licence | MIT / Apache / Commercial / Mixed / Other |
| Hosting | Self-host / Managed / Both |
| Cost | `$ low / `$`$ medium / `$`$`$ high |
| Fit | High / Medium / Low (against our constraints) |

---

"@
$header | Set-Content -Path $OutputFile -Encoding UTF8

# ── Per-candidate capture helper ─────────────────────────────────────────────
function Capture-Candidate {
  param([string]$AreaName, [string]$CandName)
  Write-Host "    Candidate: $CandName" -ForegroundColor Cyan

  $maturity = Ask-Arch-Choice "    Maturity?" @(
    "Emerging — < 2 years old, small community",
    "Established — widely adopted, strong community",
    "Declining — still usable but shrinking ecosystem",
    "Unknown"
  )
  if ($maturity -eq "Unknown") {
    Add-Arch-TDebt -Area $AreaName -Title "Maturity unknown for $CandName" `
      -Description "Candidate's maturity was not verified this session" `
      -Impact "Risk of picking a declining or unproven technology"
  }

  $licence = Ask-Arch-Text "    Licence? (e.g. MIT, Apache 2.0, Commercial, BSL, or 'TBD — verify')"
  if ([string]::IsNullOrWhiteSpace($licence)) { $licence = "TBD — verify" }
  if ($licence -eq "TBD — verify") {
    Add-Arch-TDebt -Area $AreaName -Title "Licence not verified for $CandName" `
      -Description "Licence terms not confirmed this session" `
      -Impact "Legal/procurement risk — may block adoption"
  }

  $hosting = Ask-Arch-Choice "    Hosting model?" @(
    "Self-host only",
    "Managed / SaaS only",
    "Both — self-host or managed",
    "Unknown"
  )

  $cost = Ask-Arch-Choice "    Typical cost signal?" @(
    "`$ — low (free / cheap)",
    "`$`$ — medium",
    "`$`$`$ — high (enterprise)",
    "Unknown"
  )

  $pros = Ask-Arch-Text "    Top pros? (one line — comma-separated)"
  if ([string]::IsNullOrWhiteSpace($pros)) { $pros = "TBD" }

  $cons = Ask-Arch-Text "    Top cons / risks? (one line — comma-separated)"
  if ([string]::IsNullOrWhiteSpace($cons)) { $cons = "TBD" }

  $fit = Ask-Arch-Choice "    Fit against our constraints?" @(
    "High — strongly aligned",
    "Medium — mostly aligned, some gaps",
    "Low — significant gaps"
  )

  Add-Content -Path $OutputFile -Value "| $CandName | $maturity | $licence | $hosting | $cost | $pros | $cons | $fit |" -Encoding UTF8
}

# ── Per-area walker ───────────────────────────────────────────────────────────
function Walk-Area {
  param([string]$AreaTitle, [string]$Hint)
  Write-Host ""
  Write-Host "── $AreaTitle ──" -ForegroundColor Cyan
  Write-Arch-Dim "  $Hint"
  Write-Host ""

  $inScope = Ask-Arch-YN "Is [$AreaTitle] in scope for this architecture?"
  if ($inScope -eq "no") {
    Add-Content -Path $OutputFile -Encoding UTF8 -Value @"

## $AreaTitle

_Not in scope for this architecture._

"@
    return
  }

  Add-Content -Path $OutputFile -Encoding UTF8 -Value @"

## $AreaTitle

| Candidate | Maturity | Licence | Hosting | Cost | Pros | Cons | Fit |
|---|---|---|---|---|---|---|---|
"@

  $added = 0
  while ($true) {
    if ($added -ge 4) { Write-Arch-Dim "  Reached 4 candidates — moving on."; break }
    $candName = Ask-Arch-Text "  Candidate name? (e.g. 'PostgreSQL 16', 'Node.js 20 LTS') — Enter to stop"
    if ([string]::IsNullOrWhiteSpace($candName)) { break }
    Capture-Candidate -AreaName $AreaTitle -CandName $candName
    $added++
    Write-Host ""
    $more = Ask-Arch-YN "  Add another candidate for [$AreaTitle]?"
    if ($more -eq "no") { break }
  }

  if ($added -lt 2) {
    Add-Arch-TDebt -Area $AreaTitle -Title "Fewer than 2 candidates captured for $AreaTitle" `
      -Description "Only $added candidate(s) recorded — comparison is weak" `
      -Impact "Decision may be biased / not justifiable"
  }

  Add-Content -Path $OutputFile -Value "" -Encoding UTF8
}

# ── Walk all decision areas ───────────────────────────────────────────────────
Walk-Area "Frontend framework & rendering"      "React / Vue / Angular / Svelte / server-rendered; SPA vs SSR vs SSG; styling"
Walk-Area "Backend runtime & language"          "Node.js, Python, Go, Java/Kotlin, .NET, Ruby, Rust"
Walk-Area "API style"                           "REST, GraphQL, gRPC, tRPC, or event-driven"
Walk-Area "Database(s)"                         "Relational (PostgreSQL, MySQL, SQL Server), Document (MongoDB, DynamoDB), KV (Redis), Search (OpenSearch), Analytics (BigQuery, Snowflake), Vector"
Walk-Area "Messaging / eventing"                "Kafka, RabbitMQ, SQS/SNS, NATS, Google Pub/Sub, or none"
Walk-Area "Caching"                             "In-process, Redis, CDN, or none"
Walk-Area "Identity & access"                   "Build vs Auth0 / Cognito / Entra ID / Keycloak; session vs JWT/OIDC"
Walk-Area "Hosting & compute"                   "Kubernetes (EKS/AKS/GKE), ECS, Cloud Run, Lambda/Functions, App Service, VMs"
Walk-Area "Observability"                       "OpenTelemetry + Grafana/Loki/Tempo, Datadog, New Relic, CloudWatch, Azure Monitor"
Walk-Area "CI/CD"                               "GitHub Actions, GitLab CI, Azure DevOps, Jenkins, CircleCI"
Walk-Area "Security tooling"                    "Secrets manager, WAF, SAST/DAST, dependency scanning"
Walk-Area "AI / ML services (if applicable)"    "Model hosting, vector store, orchestration framework"

# ── Finish ───────────────────────────────────────────────────────────────────
$endTDebts = Get-Arch-TDebtCount
$newTDebts = $endTDebts - $startTDebts

Write-Arch-SuccessRule "✅ Technology Research Complete"
Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newTDebts -gt 0) {
  Write-Host "  ⚠  $newTDebts technical debt(s) logged to: $script:ArchTDebtFile" -ForegroundColor Yellow
}
Write-Host ""
