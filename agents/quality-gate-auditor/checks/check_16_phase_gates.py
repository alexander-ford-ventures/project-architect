#!/usr/bin/env python3
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
"""Check 16 (B16): every state.phase_progress entry with logged work must have
prerequisites_satisfied=true.

This is the auditor's defense against bug #4 from the v2.1.5 md2pdf live test:
an agent (document-author) was dispatched for phase_4 before phase_3's
pattern-validation research had returned, producing downstream documents that
referenced fictional patterns. The fix is sociotechnical — the orchestrator
must set prerequisites_satisfied=true ONLY when all upstream gates have closed
— and this check is the loud safety net that catches lapses.

------------------------------------------------------------------------------
WHAT GETS CHECKED
------------------------------------------------------------------------------
Walk state.phase_progress. For each phase_progress entry that has "any work
logged" (see definition below), assert that its `prerequisites_satisfied`
field equals exactly True (the JSON boolean). Anything else — missing field,
null, false, or some other type — is a failure.

A phase_progress entry is considered "has work logged" iff it has at least
one of:
  - `started_at` set (non-empty truthy)
  - `completed_at` set (non-empty truthy)
  - `agents_dispatched` is a non-empty list
  - `decisions_recorded` is a non-zero number

If a phase_progress entry exists but no work is logged yet, we skip it — the
entry was just initialized by the orchestrator and there's nothing to gate
against.

------------------------------------------------------------------------------
WHY BLOCKER
------------------------------------------------------------------------------
Premature dispatch is in the same severity class as malformed JSON or a
broken link: downstream artifacts produced from an under-resourced phase are
silently wrong. BLOCKER stops the Phase-5 transition so the operator can
audit the bundle and re-run the affected phase.

------------------------------------------------------------------------------
TRUTH-TABLE
------------------------------------------------------------------------------
  - state.json missing or unparseable                  → INFO    pass (defer)
  - state.json root not an object                      → INFO    pass (defer)
  - state.phase_progress absent or empty               → INFO    pass
  - phase_progress entries exist but none have work    → INFO    pass
  - all phases-with-work have prereqs satisfied=true   → BLOCKER pass
  - one or more phases-with-work have prereqs missing  → BLOCKER fail listing
    or != true (false, null, wrong type)                each (phase=value)

------------------------------------------------------------------------------
auto_fixable: FALSE
------------------------------------------------------------------------------
The fix is to audit what happened: was the dispatch genuinely premature, in
which case the bundle is suspect and that phase needs to be re-run? Or did
the prerequisite actually return successfully and the bookkeeping just
wasn't updated? Either way a human has to look at the bundle and decide.

The state schema field `phase_progress.<phase>.prerequisites_satisfied` is
defined in Task 27 (next), but this check reads it directly from state.json
and is robust to it being absent (treats absent as "missing", which fails
the check loudly — exactly what we want during the rollout).

This is the FIFTH and FINAL Python check in the auditor suite, completing
the 16-check v2.2.0 quality-gate. JSON output is emitted directly via
json.dumps() because `_lib.sh` is bash-only.
"""

import json
import os
import sys


def has_work_logged(phase_obj):
    """Return True iff a phase_progress entry has any work logged.

    A phase entry that's been created but not yet started has all of these
    fields absent/empty; in that state we don't enforce prerequisites_satisfied
    because the orchestrator may be in the middle of populating the entry.
    """
    if not isinstance(phase_obj, dict):
        return False
    # Truthy timestamp string counts as "started"/"completed".
    if phase_obj.get("started_at") or phase_obj.get("completed_at"):
        return True
    agents = phase_obj.get("agents_dispatched")
    if isinstance(agents, list) and agents:
        return True
    # Treat any nonzero number (positive or negative) as "decisions recorded".
    # Bool is explicitly excluded since bool is an int subclass in Python.
    decisions = phase_obj.get("decisions_recorded")
    if (
        isinstance(decisions, (int, float))
        and not isinstance(decisions, bool)
        and decisions != 0
    ):
        return True
    return False


def emit(payload):
    """Print a single JSON object to stdout (the auditor's wire contract)."""
    print(json.dumps(payload))


def main():
    project_root = sys.argv[1] if len(sys.argv) > 1 else "."
    state_path = (
        sys.argv[2]
        if len(sys.argv) > 2
        else os.path.join(project_root, "docs", "_architect_state.json")
    )

    if not os.path.isfile(state_path):
        emit({
            "id": "B16",
            "severity": "INFO",
            "check": "phase_gates",
            "passed": True,
            "detail": "state.json missing (deferred to json_valid)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    try:
        with open(state_path, "r", encoding="utf-8") as fh:
            state = json.load(fh)
    except (OSError, json.JSONDecodeError) as e:
        emit({
            "id": "B16",
            "severity": "INFO",
            "check": "phase_gates",
            "passed": True,
            "detail": f"state.json unparseable (deferred to json_valid): {e}",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not isinstance(state, dict):
        emit({
            "id": "B16",
            "severity": "INFO",
            "check": "phase_gates",
            "passed": True,
            "detail": "state.json root is not an object (deferred to json_valid/schema)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    phase_progress = state.get("phase_progress") or {}
    if not isinstance(phase_progress, dict) or not phase_progress:
        emit({
            "id": "B16",
            "severity": "INFO",
            "check": "phase_gates",
            "passed": True,
            "detail": "no phase_progress to check",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    problems = []
    checked = 0
    # Iterate sorted for deterministic detail ordering (test stability + reader sanity).
    for phase_name in sorted(phase_progress.keys()):
        phase_obj = phase_progress[phase_name]
        if not has_work_logged(phase_obj):
            continue
        checked += 1
        prereqs = phase_obj.get("prerequisites_satisfied") if isinstance(phase_obj, dict) else None
        # Strict equality with True — JSON `true` deserializes as Python True.
        # Anything else (missing/None/False/string/number) fails the gate.
        if prereqs is not True:
            if "prerequisites_satisfied" not in phase_obj:
                value_repr = "missing"
            elif prereqs is None:
                value_repr = "null"
            else:
                value_repr = repr(prereqs)
            problems.append(f"{phase_name}: prerequisites_satisfied={value_repr}")

    if checked == 0:
        # Entries exist but every one is empty (no started_at/completed_at/
        # agents_dispatched/decisions_recorded). Nothing to gate.
        emit({
            "id": "B16",
            "severity": "INFO",
            "check": "phase_gates",
            "passed": True,
            "detail": "phase_progress entries exist but no work logged yet",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not problems:
        emit({
            "id": "B16",
            "severity": "BLOCKER",
            "check": "phase_gates",
            "passed": True,
            "detail": f"all {checked} phase(s) with work have prerequisites_satisfied=true",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    joined = "; ".join(problems)
    detail = f"{len(problems)} phase(s) have work but prerequisites NOT satisfied: {joined}"
    if len(detail) > 300:
        detail = detail[:297] + "..."

    emit({
        "id": "B16",
        "severity": "BLOCKER",
        "check": "phase_gates",
        "passed": False,
        "detail": detail,
        "remediation": (
            "set state.phase_progress.<phase>.prerequisites_satisfied=true ONLY when "
            "all upstream prereqs are met; if work was dispatched prematurely, audit "
            "the bundle for that phase and re-run it"
        ),
        "auto_fixable": False,
    })


if __name__ == "__main__":
    main()
