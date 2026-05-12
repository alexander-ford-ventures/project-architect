---
template_name: SLO_AND_ERROR_BUDGETS
generate_when: "decisions.scale >= 'growth'"
required_decisions: []
optional_decisions: [slo.targets, slo.error_budget_policy]
depends_on: [MONITORING_AND_OBSERVABILITY]
revision_triggers: [monitoring.*, slo.targets]
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# SLOs and Error Budgets: {{project_name}}

> 📌 **Status:** v{{document_version}} · **Last revised:** {{last_revised_date}} · **ADRs:** {{adr_links}}

## Table of contents
- [🚦 SLI Definitions](#sli-definitions)
- [🚦 SLO Targets](#slo-targets)
- [🚦 Error Budget Policy](#error-budget-policy)
- [🚦 Burn-Rate Alerting](#burn-rate-alerting)
- [↻ Revision Log](#revision-log)

## 🚦 SLI Definitions
Per-service indicators and how they're computed. Table: service | SLI | numerator | denominator | data source. Cover at minimum availability (good requests / total requests), latency (requests faster than threshold / total), and correctness (successful workflows / attempted) for each user-facing surface.

## 🚦 SLO Targets
Table: service | SLI | target (e.g., 99.9% availability over 30 days) | rolling window | error budget (minutes / requests). The targets here drive alerting, on-call urgency, and engineering investment trade-offs.

## 🚦 Error Budget Policy
What happens when budget is consumed: e.g., > 50% burned this quarter freezes risky launches, > 100% burned mandates a reliability sprint. Includes who arbitrates exceptions and how budget exhaustion rolls over.

## 🚦 Burn-Rate Alerting
Multi-window multi-burn-rate alert configuration (e.g., 2% budget in 1 hour pages, 10% in 6 hours pages). Table: alert | window | threshold | severity | runbook link. Anchored to MONITORING_AND_OBSERVABILITY.md.

## ↻ Revision Log

| Date | Decision key | Change | ADR |
|---|---|---|---|
| _(none yet)_ |  |  |  |

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
