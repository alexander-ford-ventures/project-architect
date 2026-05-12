---
template_name: EXPERIMENTS
generate_when: "decisions.feature_flags.enabled == true OR decisions.ab_testing.enabled == true"
required_decisions: []
optional_decisions: [feature_flags.provider, ab_testing.provider, experiment_lifecycle]
depends_on: []
revision_triggers: [feature_flags.provider, ab_testing.provider]
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Experiments: {{project_name}}

## Feature-Flag Provider
Provider chosen (LaunchDarkly / Statsig / PostHog / Unleash / Flagsmith / self-hosted) with one-paragraph rationale, ADR link, SDK locations (server / client / edge), and the local-dev override mechanism. Note evaluation latency budgets and the bootstrap/fallback behavior on provider outage.

## Flag Lifecycle
Lifecycle states (proposed -> rolling out -> rolled out -> cleanup -> removed), naming convention, ownership requirement (each flag has an owner and an expected removal date), and the dashboard or list where active flags live. Include the cleanup SLA (e.g., "rolled-out flags removed within 30 days").

## A/B Test Framework
Test framework (statistical engine, SDK, dashboard), the supported test types (A/B, multivariate, holdout, switchback), the minimum-detectable-effect and power defaults, and the relationship to the feature-flag provider (same SDK or separate). Cite ADR.

## Targeting & Rollout Strategy
Targeting primitives (user attributes, tenant tier, environment, geo, percentage, allowlist) and the standard rollout ladder (0% -> 1% -> 10% -> 50% -> 100%) with the gating criteria between steps. Note guardrail metrics that must hold and the automatic rollback trigger.

## Experiment Analysis
Where results are read (provider dashboard / data-warehouse query / internal tool), the canonical success metric per experiment family, multiple-comparison and segmentation policies, and the review cadence. Link to ANALYTICS_AND_TELEMETRY.md for the underlying event sources.

## Sunset / Clean-up Policy
The explicit policy for removing finished experiments and rolled-out flags: who owns it, the SLA, the lint or CI check that flags stale entries, and the consequence of missing the deadline. Prevents the codebase from accumulating dead branches and forgotten flags.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
