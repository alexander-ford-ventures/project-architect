#!/usr/bin/env python3
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
"""Check 14 (B14): every "high-stakes" decision in state.decisions must be
covered by an ADR in docs/decisions/ whose YAML frontmatter `decision_keys`
list contains the decision's dotted-path key.

This catches bug #11 from the v2.1.5 md2pdf live test: a real i18n decision
recorded multiple alternatives in state but no ADR was filed, so the "why
did we pick X?" archeology was permanently lost.

------------------------------------------------------------------------------
WHAT QUALIFIES AS "HIGH-STAKES"
------------------------------------------------------------------------------
A decision leaf is "high-stakes" iff:
  1. its value is a scalar (str/int/float/bool) and non-null, AND
  2. its parent object has a SIBLING key named "<leaf>_alternatives_considered"
     whose value is a list of length >= 2.

This mirrors the convention established by the orchestrator: when the user
faces a real tradeoff with multiple credible options, the orchestrator writes
the chosen option AND the alternatives into state, and the team is expected
to file an ADR documenting why this option won.

Example state.decisions (excerpt):
    {
      "tech_stack": {
        "language": "rust",
        "language_alternatives_considered": ["go", "python", "rust"]
      }
    }

→ `tech_stack.language` is high-stakes (3 alternatives).  An ADR with
`decision_keys: ["tech_stack.language"]` is required.

A decision with only ONE alternative (or zero, or a non-list value) is NOT
high-stakes — it's a default pick, not a tradeoff, and we don't burden the
author with an ADR for it.

------------------------------------------------------------------------------
ADR MATCHING
------------------------------------------------------------------------------
For each .md file under docs/decisions/, we parse the leading `---`-bounded
YAML frontmatter and read `decision_keys` (must be a list of strings). The
union of all such lists across all ADRs is the set of "covered" decision
paths. A high-stakes decision is covered iff its dotted path appears in that
set; otherwise the check fails and the decision is listed.

A single ADR may cover MULTIPLE decision keys (when one architectural choice
locks in several state keys at once) — that's why decision_keys is a list.

ADRs with malformed YAML frontmatter are silently ignored for the purpose of
this check (a separate check, B10/yaml_frontmatter, is responsible for
flagging that). The effect is conservative: if an ADR's YAML is broken, its
decision_keys are unreadable and any high-stakes decision it was meant to
cover will show up here as uncovered — which is exactly the safe answer.

------------------------------------------------------------------------------
SEVERITY: WARNING
------------------------------------------------------------------------------
A missing ADR doesn't break runtime — generated docs still ship, code still
compiles, tests still run. But it silently corrodes the project's decision
archeology, which is the whole reason ADRs exist. WARNING surfaces this
loudly without blocking the Phase-5 transition.

------------------------------------------------------------------------------
TRUTH-TABLE
------------------------------------------------------------------------------
  - state.json missing or unparseable                       → INFO pass (defer to json_valid)
  - state.json root not an object                           → INFO pass (defer to schema)
  - state.decisions absent OR no high-stakes leaves         → WARNING pass "no high-stakes decisions to cover"
  - all high-stakes decisions covered by some ADR           → WARNING pass "all N high-stakes decision(s) have ADRs"
  - one or more high-stakes decisions lack a matching ADR   → WARNING fail listing each (dotted-path + alt count)

------------------------------------------------------------------------------
auto_fixable: FALSE
------------------------------------------------------------------------------
The author has to write the ADR body — there's no mechanical way to derive
"why did we pick rust over go" from state alone. The auditor can't
hallucinate rationale.

This is the THIRD Python check in the auditor suite. As with checks 10 and
12, JSON output is emitted directly via json.dumps() because `_lib.sh`
is bash-only.
"""

import json
import os
import sys

try:
    import yaml
except ImportError:
    # Graceful degradation: PyYAML missing → emit INFO pass so run_all.sh
    # keeps producing valid JSON. The remediation field tells the operator
    # what to install.
    print(json.dumps({
        "id": "B14",
        "severity": "INFO",
        "check": "adr_coverage",
        "passed": True,
        "detail": "PyYAML not installed; check skipped",
        "remediation": "pip install pyyaml",
        "auto_fixable": False,
    }))
    sys.exit(0)


def extract_frontmatter(content):
    """Return parsed YAML frontmatter dict, or {} if absent/invalid.

    Grammar (matches check_10's parser):
      - First line of file must be exactly `---` (after strip)
      - Some subsequent line must be exactly `---` (after strip)
      - Body between (exclusive) is the YAML to parse
    Malformed YAML returns {} — that ADR contributes no decision_keys and
    any decision it was supposed to cover will surface as uncovered, which
    is the safe (false-negative-resistant) outcome.
    """
    if not content.startswith("---"):
        return {}
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            try:
                parsed = yaml.safe_load("\n".join(lines[1:i]))
            except yaml.YAMLError:
                return {}
            return parsed if isinstance(parsed, dict) else {}
    return {}


def find_high_stakes_decisions(decisions_obj, prefix=""):
    """Walk state.decisions and yield (dotted_path, value, alternatives_list).

    Definition of "high-stakes" (see module docstring): a scalar leaf whose
    parent dict has a sibling `<leaf>_alternatives_considered` list of
    length >= 2.

    Recursion handles nested groupings (e.g. tech_stack.language,
    tech_stack.framework, runtime.executor). The prefix accumulates the
    dotted path; "" means the leaf is directly under decisions.
    """
    if not isinstance(decisions_obj, dict):
        return
    for key, value in decisions_obj.items():
        if isinstance(value, dict):
            sub_prefix = f"{prefix}.{key}" if prefix else key
            yield from find_high_stakes_decisions(value, sub_prefix)
            continue
        # Treat None as "decision not yet made" — not high-stakes.
        if value is None:
            continue
        # Only scalar leaves are decisions. Lists are typically the
        # `_alternatives_considered` arrays themselves, not decisions.
        if not isinstance(value, (str, int, float, bool)):
            continue
        # Skip the alternative-list keys themselves (they're metadata,
        # not decisions). Otherwise a key literally named
        # "foo_alternatives_considered" with a scalar value would be
        # interpreted as a decision — defensive but cheap.
        if key.endswith("_alternatives_considered"):
            continue
        alt_key = f"{key}_alternatives_considered"
        alternatives = decisions_obj.get(alt_key)
        if isinstance(alternatives, list) and len(alternatives) >= 2:
            dotted = f"{prefix}.{key}" if prefix else key
            yield (dotted, value, alternatives)


def collect_covered_keys(adr_dir):
    """Return the union of decision_keys declared by every ADR's frontmatter.

    Iterates docs/decisions/*.md, parses frontmatter, accumulates string
    entries from each ADR's `decision_keys` list. Unreadable files and
    malformed frontmatter are silently skipped (see module docstring).
    """
    covered = set()
    if not os.path.isdir(adr_dir):
        return covered
    try:
        entries = sorted(os.listdir(adr_dir))
    except OSError:
        return covered
    for fname in entries:
        if not fname.endswith(".md"):
            continue
        full_path = os.path.join(adr_dir, fname)
        try:
            with open(full_path, "r", encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except OSError:
            continue
        fm = extract_frontmatter(content)
        keys = fm.get("decision_keys")
        if isinstance(keys, list):
            for k in keys:
                if isinstance(k, str):
                    covered.add(k)
    return covered


def emit(payload):
    """Print a single JSON object to stdout (auditor's wire contract)."""
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
            "id": "B14",
            "severity": "INFO",
            "check": "adr_coverage",
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
            "id": "B14",
            "severity": "INFO",
            "check": "adr_coverage",
            "passed": True,
            "detail": f"state.json unparseable (deferred to json_valid): {e}",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not isinstance(state, dict):
        emit({
            "id": "B14",
            "severity": "INFO",
            "check": "adr_coverage",
            "passed": True,
            "detail": "state.json root is not an object (deferred to json_valid/schema)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    decisions = state.get("decisions") or {}
    high_stakes = list(find_high_stakes_decisions(decisions))

    if not high_stakes:
        # Check ran end-to-end and found no decisions that warrant ADRs.
        # Emit a WARNING-grade positive verdict (consistent severity with
        # the failure path).
        emit({
            "id": "B14",
            "severity": "WARNING",
            "check": "adr_coverage",
            "passed": True,
            "detail": "no high-stakes decisions to cover (none have >=2 alternatives_considered)",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    adr_dir = os.path.join(project_root, "docs", "decisions")
    covered_keys = collect_covered_keys(adr_dir)

    missing = []
    for dotted, value, alternatives in high_stakes:
        if dotted not in covered_keys:
            # Use repr() on the chosen value so quoting/whitespace are
            # unambiguous in the report (matches check_12's style).
            missing.append(
                f"{dotted} (chose {value!r} from {len(alternatives)} alternatives)"
            )

    if not missing:
        emit({
            "id": "B14",
            "severity": "WARNING",
            "check": "adr_coverage",
            "passed": True,
            "detail": f"all {len(high_stakes)} high-stakes decision(s) have ADRs",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    joined = "; ".join(missing)
    detail = f"{len(missing)} high-stakes decision(s) without ADR: {joined}"
    if len(detail) > 300:
        detail = detail[:297] + "..."

    emit({
        "id": "B14",
        "severity": "WARNING",
        "check": "adr_coverage",
        "passed": False,
        "detail": detail,
        "remediation": (
            "file an ADR for each missing decision: create "
            "docs/decisions/NNNN-<slug>.md with YAML frontmatter "
            "`decision_keys: [\"<dotted.path>\"]` and a body explaining "
            "why the chosen value beat its alternatives"
        ),
        "auto_fixable": False,
    })


if __name__ == "__main__":
    main()
