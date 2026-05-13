#!/usr/bin/env python3
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
"""Check 12 (B12): every known timestamp field in state.json must parse as a
full ISO8601 *datetime* (date + time, optionally with timezone).

This check exists to catch bug #2 from the v2.1.5 md2pdf live test, where the
orchestrator wrote `started_at: "2026-05-13"` — a date-only value that breaks
every downstream consumer that expects to compare against `datetime.utcnow()`
(e.g. "what changed in the last hour?" queries, audit log diffing, lock-stale
detection).

Severity: WARNING. A malformed timestamp doesn't halt execution — but it
silently corrupts chronological queries and the next user who runs `--resume`
sees an unintelligible state file. WARNING surfaces it loudly without blocking
Phase 5 transition.

Inputs:
  $1 = PROJECT_ROOT  (defaults to ".")
  $2 = STATE_PATH    (defaults to PROJECT_ROOT/docs/_architect_state.json)

Known timestamp fields walked:
  - state.started_at                                     (required, non-null)
  - state.last_updated_at                                (required, non-null)
  - state.locked_at                                      (nullable — null until lock)
  - state.phase_progress.<phase>.completed_at            (per-phase, non-null when set)
  - state.documents_generated[].generated_at             (per-doc, non-null)
  - state.research_findings[].dispatched_at              (per-finding, non-null)

Truth-table:
  - state.json missing or unparseable                     → INFO    pass (deferred to json_valid)
  - all known fields parse as ISO8601 datetime (or null)  → WARNING pass
  - one or more fields malformed                          → WARNING fail listing each

What counts as "ISO8601 datetime" here:
  - Accepts:  2026-05-13T01:23:45Z
              2026-05-13T01:23:45+00:00
              2026-05-13T01:23:45.123Z (microseconds)
              2026-05-13 01:23:45 (space separator — tolerated for portability)
  - Rejects:  2026-05-13 (date-only — no time component)
              "not a date"
              12345 (non-string)
              {} or [] (non-string)

The check requires either a 'T' separator OR a space separator between date and
time. `datetime.fromisoformat("2026-05-13")` happily returns midnight in Python
3.11+, so we can't rely on fromisoformat alone — the post-check is what
distinguishes a full datetime string from a bare date.

auto_fixable=true on the failure path: writing the current UTC time via
`datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")` is a mechanical fix the
orchestrator can apply. (The original timestamp is lost, but the schema
contract is restored — and the next state mutation rewrites these fields
anyway.)

This is the SECOND Python check in the auditor suite. Like check_10, it
formats its own JSON output via json.dumps (which handles UTF-8 escaping)
because `_lib.sh` is bash-only.
"""

import json
import os
import sys
from datetime import datetime


def parse_iso8601_datetime(value):
    """Return (ok: bool, error: str) for `value`.

    Accepts the canonical ISO8601 datetime forms with a 'T' separator, plus
    the (looser) ISO8601 form with a space separator between date and time.
    Rejects bare-date strings ("2026-05-13"), non-strings, and any value
    `datetime.fromisoformat` can't parse.
    """
    if not isinstance(value, str):
        return False, f"non-string value of type {type(value).__name__}"
    # Normalize trailing 'Z' → '+00:00'. Python 3.11+ accepts 'Z' natively, but
    # 3.10 does not — the explicit replace keeps the check portable.
    if value.endswith("Z"):
        normalized = value[:-1] + "+00:00"
    else:
        normalized = value
    try:
        datetime.fromisoformat(normalized)
    except (ValueError, TypeError) as e:
        return False, f"unparseable: {e}"
    # Require an explicit time component. fromisoformat accepts bare dates and
    # returns a datetime at midnight; we want to flag those because they
    # silently coerce to "00:00:00" and confuse downstream comparisons.
    if "T" not in value and " " not in value:
        return False, "date-only (no time component); use full ISO8601 datetime"
    return True, ""


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
            "id": "B12",
            "severity": "INFO",
            "check": "iso8601_timestamps",
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
            "id": "B12",
            "severity": "INFO",
            "check": "iso8601_timestamps",
            "passed": True,
            "detail": f"state.json unparseable (deferred to json_valid): {e}",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not isinstance(state, dict):
        # state.json isn't a JSON object — out of scope here, defer to
        # check_05 (json_valid) and the future schema check.
        emit({
            "id": "B12",
            "severity": "INFO",
            "check": "iso8601_timestamps",
            "passed": True,
            "detail": "state.json root is not an object (deferred to json_valid/schema)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    problems = []

    def check_field(path, value):
        # Nullable fields are allowed to be null (e.g. locked_at is null until
        # state.locked becomes true). Skip explicit nulls; only flag values
        # that *claim to be* a timestamp.
        if value is None:
            return
        ok, err = parse_iso8601_datetime(value)
        if not ok:
            # Render the offending value with repr() so the detail string is
            # unambiguous about whitespace, quoting, and type.
            problems.append(f"{path}={value!r}: {err}")

    # Top-level required-and-nullable timestamps.
    for field in ("started_at", "last_updated_at", "locked_at"):
        if field in state:
            check_field(field, state[field])

    # Per-phase completion timestamps.
    phase_progress = state.get("phase_progress")
    if isinstance(phase_progress, dict):
        for phase_key, phase_obj in phase_progress.items():
            if isinstance(phase_obj, dict) and "completed_at" in phase_obj:
                check_field(
                    f"phase_progress.{phase_key}.completed_at",
                    phase_obj["completed_at"],
                )

    # documents_generated[].generated_at
    docs = state.get("documents_generated")
    if isinstance(docs, list):
        for i, doc in enumerate(docs):
            if isinstance(doc, dict) and "generated_at" in doc:
                check_field(
                    f"documents_generated[{i}].generated_at",
                    doc["generated_at"],
                )

    # research_findings[].dispatched_at
    findings = state.get("research_findings")
    if isinstance(findings, list):
        for i, finding in enumerate(findings):
            if isinstance(finding, dict) and "dispatched_at" in finding:
                check_field(
                    f"research_findings[{i}].dispatched_at",
                    finding["dispatched_at"],
                )

    if not problems:
        emit({
            "id": "B12",
            "severity": "WARNING",
            "check": "iso8601_timestamps",
            "passed": True,
            "detail": "all known timestamp fields are valid ISO8601 datetimes (or null)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    # Build a bounded, comma-joined failure summary. Truncate at 300 chars to
    # match the rest of the suite's wire contract (run_all.sh expects each
    # finding to be a single JSON object on one line).
    joined = "; ".join(problems)
    detail = f"{len(problems)} timestamp field(s) malformed: {joined}"
    if len(detail) > 300:
        detail = detail[:297] + "..."

    emit({
        "id": "B12",
        "severity": "WARNING",
        "check": "iso8601_timestamps",
        "passed": False,
        "detail": detail,
        "remediation": (
            "set each timestamp to ISO8601 datetime form "
            "'YYYY-MM-DDTHH:MM:SSZ' (e.g. via bash "
            "`date -u +\"%Y-%m-%dT%H:%M:%SZ\"` or Python "
            "`datetime.utcnow().strftime(\"%Y-%m-%dT%H:%M:%SZ\")`)"
        ),
        "auto_fixable": True,
    })


if __name__ == "__main__":
    main()
