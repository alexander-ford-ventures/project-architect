<!--
Author: Alexander Ford <alex@alexfordlabs.com>
Repository: https://github.com/alexfordlabs/project-architect
License: MIT
-->

# Runtime Budgets Reference

Per-agent budget catalog and the orchestrator's observer-wrapper logic.

## Per-agent budget table

| Agent | typical_minutes | max_minutes | Notes |
|---|---|---|---|
| research-scout | 5 | 15 | Web fetches dominate; bounded by `max_results` |
| document-author | 3 | 10 | Single template fill; well-bounded |
| decision-revisor | 5 | 12 | Surgical patch; touches ≤4 docs |
| claude-md-author | 3 | 8 | Hierarchy of small files |
| claude-tooling-author | 10 | 20 | Many small files (settings, hooks, commands) |
| quality-gate-auditor | 5 | 12 | Read-only; bounded by 16-check count |

## Observer wrapper

The orchestrator wraps every `Agent({...})` dispatch with observation logic. The observer **never blocks** — it only surfaces telemetry.

### What the observer does

```
when dispatching agent X with budget {typical, max}:
  start_time = now()
  log "dispatching X (budget: typical={typical}min, max={max}min)"

while X is running:
  on each progress message from X:
    last_progress = now()
    log "X: <progress message>"
  if (now() - last_progress) > (typical / 3) minutes:
    log "X silent for too long; agent may be stuck"
  if (now() - start_time) > max minutes:
    log "X over max budget — consider Esc + re-dispatch with tighter scope"
    # Do NOT auto-kill — some work legitimately takes longer

when X returns:
  elapsed = now() - start_time
  agent_work_time = elapsed   # total includes user-wait if user was prompted; for cleaner accounting, use elapsed during dispatch only
  log "X returned in {elapsed}min (budget: {typical}/{max})"
  if elapsed > typical:
    record telemetry: { agent: X, elapsed, scope: <dispatch_envelope_summary> }
    add to phase_5_seed_items: "agent X cost {elapsed}min (typical {typical}min) — review scope"
```

### Why observation, not enforcement

Auto-killing an agent is risky: some legitimate work takes longer (large input, complex revision, network slowness). The observer model:
- Surfaces cost overruns in real time (so user can intervene)
- Records telemetry for v2.3+ tuning (which agents repeatedly overrun?)
- Pre-populates Phase 5 menu with "review scope of agent X" items
- Never silently kills work-in-progress

### Timer attribution

The visible elapsed time for an agent dispatch can include **user-wait time** (architect blocked on `AskUserQuestion`). For cost analysis, the observer SHOULD subtract user-wait intervals to compute `agent_work_time`. For user transparency, show `total_elapsed`.

This is a UX detail; v2.2 implements only `total_elapsed` tracking. v2.3 may add detailed attribution.

## State.json fields

Every dispatched agent appends an entry to `state.agent_dispatches`:

```json
{
  "agent": "decision-revisor",
  "phase": "phase_5",
  "dispatched_at": "2026-05-13T01:23:00Z",
  "returned_at": "2026-05-13T01:54:30Z",
  "elapsed_minutes": 31.5,
  "budget_typical": 5,
  "budget_max": 12,
  "over_budget": true,
  "over_budget_factor": 6.3,
  "scope_summary": "html_allowlist — patch 4 docs"
}
```

The auditor (Sketch B) reads this array; check 9 / 13 etc. consume it for findings.

---

*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
