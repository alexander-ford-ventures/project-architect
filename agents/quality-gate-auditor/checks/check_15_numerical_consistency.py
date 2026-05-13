#!/usr/bin/env python3
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
"""Check 15 (B15): performance_targets in state.decisions.architecture must not
be more than 30% better than their baseline_typical counterparts unless an
explicit stretch_disclaimer is recorded.

This check exists to catch bug #10 from the v2.1.5 md2pdf live test: the
orchestrator wrote aggressive cold-start and warm-start targets (cold_start=
0.5s, warm_start=0.2s) without any indication that these were stretch goals.
Downstream readers — humans planning capacity, CI configuring p95 alerts,
auditors writing SLOs — interpreted them as firm commitments. When the
shipped artifact hit cold_start=2.8s, the project looked like it had missed
by 5x even though the team had never genuinely committed to the aggressive
number.

The fix is sociotechnical, not algorithmic: surface the gap loudly and let
the author either (a) admit the target is aspirational by attaching a
stretch_disclaimer or (b) relax the target to something consistent with the
measured baseline. Either way the document stops lying to its readers.

------------------------------------------------------------------------------
WHAT GETS CHECKED
------------------------------------------------------------------------------
Walk state.decisions.architecture.performance_targets. For each numeric
top-level key K that ends in '_max' or '_target' (a commitment), try to find
a matching baseline_typical value under performance_targets.baseline.<base>.
If `target < AGGRESSIVE_RATIO * baseline_typical` (default 0.7, i.e. the
target claims >30% improvement over typical), the pair is "aggressive" and
must be acknowledged with a disclaimer.

Pair-matching strategies (in order of preference; first match wins):
  - For keys ending in '_seconds_max':
      strip '_seconds_max' → base; try baseline.<base>_typical_seconds,
      then baseline.<base>_seconds_typical, then baseline.<base>_typical.
  - For keys ending in '_max':
      strip '_max' → base; try baseline.<base>_typical, then
      baseline.<base>_typical_value.

(`_target` is treated identically to '_max' for tail-matching purposes; some
authors prefer "p95_latency_target" to "p95_latency_max", and both mean the
same thing in this context.)

Disclaimer recognition (any ONE of the following neutralizes ALL findings):
  1. performance_targets.stretch_disclaimer (string, top-level)         OR
  2. performance_targets.<K>_stretch_disclaimer (string, per-key)
where K is the offending target's exact key.

------------------------------------------------------------------------------
WHY WARNING, NOT BLOCKER
------------------------------------------------------------------------------
A mismatched numeric commitment doesn't break runtime, doesn't fail compile,
doesn't crash the orchestrator. But it silently corrodes the document's
contract with its readers — and every downstream artifact (Slack post,
README badge, marketing one-pager) inherits the lie. WARNING surfaces it
loudly without blocking the Phase 5 transition; the author can choose to
ship anyway after explicit acknowledgment.

------------------------------------------------------------------------------
TRUTH-TABLE
------------------------------------------------------------------------------
  - state.json missing or unparseable                  → INFO    pass (defer)
  - state.json root not an object                      → INFO    pass (defer)
  - decisions.architecture.performance_targets absent  → INFO    pass
  - performance_targets present but no <K>/baseline    → INFO    pass
    pairs detectable (e.g. only baseline, only targets,
    or names don't match any strategy)
  - all detected pairs reasonable (ratio >= 0.7)       → WARNING pass
  - one or more pairs aggressive WITH disclaimer       → WARNING pass
  - one or more pairs aggressive WITHOUT disclaimer    → WARNING fail listing
    each (key=target, baseline=typical, ratio=X.XX)

------------------------------------------------------------------------------
auto_fixable: FALSE
------------------------------------------------------------------------------
The author has to decide: relax the target (changes a commitment) or attach
a disclaimer (admits the commitment is aspirational). Both choices change
the document's contract with its readers and require human judgement.

This is the FOURTH Python check in the auditor suite. JSON output is emitted
directly via json.dumps() because `_lib.sh` is bash-only.
"""

import json
import os
import sys

# Targets that claim more than 30% improvement over baseline are flagged.
# 0.7 chosen empirically: typical engineering wins from a single-iteration
# optimization run from ~5% (refactor) to ~30% (algorithm swap); anything
# beyond is a campaign, not an estimate, and warrants explicit acknowledgment.
AGGRESSIVE_RATIO = 0.7


def find_baseline(baseline_obj, target_key):
    """Given a target key (e.g. 'cold_start_seconds_max') and a baseline dict,
    find a matching numeric baseline value or return None.

    Pair-matching strategies (first hit wins):

      1. target ends in '_seconds_max':
         strip '_seconds_max' → base; try, in order:
           - <base>_typical_seconds  (the canonical form used in our spec)
           - <base>_seconds_typical  (mirror form some authors prefer)
           - <base>_typical          (units inferred from target's unit)

      2. target ends in '_max' (but not '_seconds_max'):
         strip '_max' → base; try, in order:
           - <base>_typical
           - <base>_typical_value

      3. target ends in '_target' (treated like '_max' for tail-matching):
         strip '_target' → base; try same suffixes as '_max'.

    Non-dict baseline, missing keys, and non-numeric matched values all
    return None — callers treat None as "no pair detected, skip".
    """
    if not isinstance(baseline_obj, dict):
        return None

    def _lookup(candidates):
        for cand in candidates:
            val = baseline_obj.get(cand)
            if isinstance(val, (int, float)) and not isinstance(val, bool):
                return val
        return None

    if target_key.endswith("_seconds_max"):
        base = target_key[: -len("_seconds_max")]
        return _lookup([
            f"{base}_typical_seconds",
            f"{base}_seconds_typical",
            f"{base}_typical",
        ])

    if target_key.endswith("_max"):
        base = target_key[: -len("_max")]
        return _lookup([f"{base}_typical", f"{base}_typical_value"])

    if target_key.endswith("_target"):
        base = target_key[: -len("_target")]
        return _lookup([f"{base}_typical", f"{base}_typical_value"])

    return None


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
            "id": "B15",
            "severity": "INFO",
            "check": "numerical_consistency",
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
            "id": "B15",
            "severity": "INFO",
            "check": "numerical_consistency",
            "passed": True,
            "detail": f"state.json unparseable (deferred to json_valid): {e}",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not isinstance(state, dict):
        emit({
            "id": "B15",
            "severity": "INFO",
            "check": "numerical_consistency",
            "passed": True,
            "detail": "state.json root is not an object (deferred to json_valid/schema)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    decisions = state.get("decisions") or {}
    architecture = decisions.get("architecture") if isinstance(decisions, dict) else None
    pt = architecture.get("performance_targets") if isinstance(architecture, dict) else None

    if not isinstance(pt, dict) or not pt:
        emit({
            "id": "B15",
            "severity": "INFO",
            "check": "numerical_consistency",
            "passed": True,
            "detail": "no performance_targets to check",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    baseline = pt.get("baseline") if isinstance(pt.get("baseline"), dict) else {}
    top_level_disclaimer = pt.get("stretch_disclaimer")

    issues = []
    pair_count = 0
    for key, target_val in pt.items():
        # Bools are an int subclass in Python; explicitly exclude them so
        # `"some_flag_max": true` doesn't get treated as a numeric commitment.
        if not isinstance(target_val, (int, float)) or isinstance(target_val, bool):
            continue
        if not (key.endswith("_max") or key.endswith("_target")):
            continue
        # Skip the per-key disclaimer fields themselves (they end in
        # _stretch_disclaimer but typically aren't numeric anyway — defensive).
        if key.endswith("_stretch_disclaimer"):
            continue

        baseline_val = find_baseline(baseline, key)
        if baseline_val is None or baseline_val <= 0:
            # Either no matching baseline was registered OR the baseline is
            # zero/negative (can't compute a meaningful ratio). Skip silently.
            continue
        pair_count += 1
        ratio = target_val / baseline_val
        if ratio < AGGRESSIVE_RATIO:
            per_key_disclaimer = pt.get(f"{key}_stretch_disclaimer")
            if top_level_disclaimer or per_key_disclaimer:
                # Disclaimer present — author has acknowledged the stretch.
                continue
            issues.append(
                f"{key}={target_val} (baseline={baseline_val}, ratio={ratio:.2f})"
            )

    if pair_count == 0:
        # performance_targets exists but no target/baseline pair could be
        # resolved — nothing to compare against, so nothing to warn about.
        emit({
            "id": "B15",
            "severity": "INFO",
            "check": "numerical_consistency",
            "passed": True,
            "detail": "no target/baseline pairs detected",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not issues:
        emit({
            "id": "B15",
            "severity": "WARNING",
            "check": "numerical_consistency",
            "passed": True,
            "detail": f"all {pair_count} target/baseline pair(s) reasonable (or disclaimed)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    joined = "; ".join(issues)
    detail = f"{len(issues)} aggressive target(s) without stretch_disclaimer: {joined}"
    if len(detail) > 300:
        detail = detail[:297] + "..."

    emit({
        "id": "B15",
        "severity": "WARNING",
        "check": "numerical_consistency",
        "passed": False,
        "detail": detail,
        "remediation": (
            "either add 'stretch_disclaimer: <reason>' to performance_targets "
            "(or per-key '<key>_stretch_disclaimer: <reason>'), or relax the "
            "target(s) so they're within 30% of the baseline_typical value"
        ),
        "auto_fixable": False,
    })


if __name__ == "__main__":
    main()
