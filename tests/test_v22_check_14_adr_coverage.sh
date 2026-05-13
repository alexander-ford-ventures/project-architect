#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Tests for check_14_adr_coverage.py (Sketch B, check ID B14, WARNING).
#
# Covers bug #11 from the v2.1.5 md2pdf live test: a real i18n decision was
# recorded with multiple alternatives in state.decisions but no ADR was filed
# in docs/decisions/, so the "why did we pick X?" archeology was lost.
#
# Truth-table covered here:
#   - bad fixture (decision-without-adr)        -> WARNING fail naming tech_stack.language
#   - clean-bundle (no decisions key)           -> WARNING pass "no high-stakes"
#   - healthy tempdir (decision + matching ADR) -> WARNING pass
#   - multi-key ADR (one ADR covers 2 keys)     -> WARNING pass for BOTH
#   - alternatives < 2 (just 1)                 -> not high-stakes, WARNING pass
#   - decision value=null                       -> not high-stakes, WARNING pass
#   - nested grouping (tech_stack.framework)    -> dotted path resolves, pass
#   - malformed ADR frontmatter                 -> ADR ignored, decision flagged
#   - state.json missing                        -> INFO pass (deferred)
#   - malformed state.json                      -> INFO pass (deferred)
#   - state.json root is array (non-object)     -> INFO pass (deferred)
#   - JSON validity loop over every output

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_14_adr_coverage.py"
assert_file_exists "$CHECK" "check_14 must exist"
assert_executable "$CHECK" "check_14 must be executable"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_14 fully"
  test_summary
  exit 0
fi

# (1) Bad fixture: state has tech_stack.language with alternatives, but only
#     ADR covers legal.license (unrelated). Expected WARNING fail naming
#     tech_stack.language.
RESULT_BAD=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/decision-without-adr")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
CHECK_NAME_BAD=$(echo "$RESULT_BAD" | jq -r .check)
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$PASSED_BAD" "false" "decision-without-adr fixture must FAIL"
assert_eq "$SEVERITY_BAD" "WARNING" "severity must be WARNING"
assert_eq "$ID_BAD" "B14" "id must be B14"
assert_eq "$CHECK_NAME_BAD" "adr_coverage" "check name must be adr_coverage"
assert_contains "$DETAIL_BAD" "tech_stack.language" "detail must name dotted path tech_stack.language"
assert_contains "$DETAIL_BAD" "rust" "detail must include chosen value 'rust'"
assert_contains "$DETAIL_BAD" "3 alternatives" "detail must include alternatives count"
assert_contains "$REMEDIATION_BAD" "decision_keys" "remediation must reference decision_keys"
assert_eq "$AUTOFIX_BAD" "false" "ADR authorship requires human; auto_fixable=false"

# (2) Clean-bundle: state.json = {"phase":"complete"}. No decisions at all.
#     Expected WARNING pass "no high-stakes".
RESULT_CLEAN=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_eq "$PASSED_CLEAN" "true" "clean-bundle (no decisions) must PASS"
assert_eq "$SEVERITY_CLEAN" "WARNING" "clean-bundle severity must be WARNING"
assert_contains "$DETAIL_CLEAN" "no high-stakes" "clean-bundle detail must mention 'no high-stakes'"

# (3) Healthy: state has tech_stack.language with alternatives AND a matching
#     ADR. Expected WARNING pass.
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs/decisions"
cat > "$HEALTHY_TMP/docs/_architect_state.json" <<'EOF'
{
  "schema_version": "2.0",
  "phase": "phase_4",
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["go", "python", "rust"]
    }
  }
}
EOF
cat > "$HEALTHY_TMP/docs/decisions/0001-language.md" <<'EOF'
---
adr_id: "0001"
title: Choose Rust
status: accepted
decision_keys: ["tech_stack.language"]
---

# Choose Rust because of zero-cost abstractions and memory safety.
EOF
RESULT_HEALTHY=$(python3 "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_eq "$PASSED_HEALTHY" "true" "healthy (decision + matching ADR) must PASS"
assert_contains "$DETAIL_HEALTHY" "all 1 high-stakes decision(s)" "healthy detail must report count=1"
rm -rf "$HEALTHY_TMP"

# (4) Multi-key ADR: one ADR's decision_keys covers BOTH tech_stack.language
#     AND runtime.executor. Both should pass.
MULTIKEY_TMP=$(mktemp -d)
mkdir -p "$MULTIKEY_TMP/docs/decisions"
cat > "$MULTIKEY_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["go", "rust"]
    },
    "runtime": {
      "executor": "tokio",
      "executor_alternatives_considered": ["tokio", "async-std", "smol"]
    }
  }
}
EOF
cat > "$MULTIKEY_TMP/docs/decisions/0001-async-stack.md" <<'EOF'
---
adr_id: "0001"
title: Rust + Tokio
status: accepted
decision_keys: ["tech_stack.language", "runtime.executor"]
---

# Rust + Tokio chosen together because the Tokio ecosystem dictates Rust.
EOF
RESULT_MULTIKEY=$(python3 "$CHECK" "$MULTIKEY_TMP")
PASSED_MULTIKEY=$(echo "$RESULT_MULTIKEY" | jq -r .passed)
DETAIL_MULTIKEY=$(echo "$RESULT_MULTIKEY" | jq -r .detail)
assert_eq "$PASSED_MULTIKEY" "true" "multi-key ADR must cover BOTH decisions (PASS)"
assert_contains "$DETAIL_MULTIKEY" "all 2 high-stakes decision(s)" "multi-key detail must report count=2"
rm -rf "$MULTIKEY_TMP"

# (5) Alternatives < 2 (just 1 entry in alternatives_considered): decision
#     is NOT high-stakes, so no ADR required, WARNING pass.
ONEALT_TMP=$(mktemp -d)
mkdir -p "$ONEALT_TMP/docs"
cat > "$ONEALT_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["rust"]
    }
  }
}
EOF
RESULT_ONEALT=$(python3 "$CHECK" "$ONEALT_TMP")
PASSED_ONEALT=$(echo "$RESULT_ONEALT" | jq -r .passed)
DETAIL_ONEALT=$(echo "$RESULT_ONEALT" | jq -r .detail)
assert_eq "$PASSED_ONEALT" "true" "1-alternative decision is NOT high-stakes; must PASS"
assert_contains "$DETAIL_ONEALT" "no high-stakes" "1-alt detail must say 'no high-stakes'"
rm -rf "$ONEALT_TMP"

# (6) Decision value is null: not yet decided, skip; WARNING pass.
NULLVAL_TMP=$(mktemp -d)
mkdir -p "$NULLVAL_TMP/docs"
cat > "$NULLVAL_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": null,
      "language_alternatives_considered": ["go", "rust"]
    }
  }
}
EOF
RESULT_NULLVAL=$(python3 "$CHECK" "$NULLVAL_TMP")
PASSED_NULLVAL=$(echo "$RESULT_NULLVAL" | jq -r .passed)
DETAIL_NULLVAL=$(echo "$RESULT_NULLVAL" | jq -r .detail)
assert_eq "$PASSED_NULLVAL" "true" "null decision (not yet chosen) must PASS"
assert_contains "$DETAIL_NULLVAL" "no high-stakes" "null-value detail must say 'no high-stakes'"
rm -rf "$NULLVAL_TMP"

# (7) Nested grouping resolves to dotted path correctly. Confirms recursion
#     produces "tech_stack.framework" not "framework" or "tech_stack.tech_stack.framework".
NESTED_TMP=$(mktemp -d)
mkdir -p "$NESTED_TMP/docs/decisions"
cat > "$NESTED_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "framework": "axum",
      "framework_alternatives_considered": ["axum", "actix", "rocket"]
    }
  }
}
EOF
cat > "$NESTED_TMP/docs/decisions/0001-framework.md" <<'EOF'
---
adr_id: "0001"
title: Axum
status: accepted
decision_keys: ["tech_stack.framework"]
---

# Axum.
EOF
RESULT_NESTED=$(python3 "$CHECK" "$NESTED_TMP")
PASSED_NESTED=$(echo "$RESULT_NESTED" | jq -r .passed)
assert_eq "$PASSED_NESTED" "true" "nested grouping dotted path must match ADR's decision_keys"
rm -rf "$NESTED_TMP"

# (8) Malformed ADR frontmatter: ADR contributes no keys; decision flagged
#     as uncovered (safe default — broken YAML can't claim coverage).
BADADR_TMP=$(mktemp -d)
mkdir -p "$BADADR_TMP/docs/decisions"
cat > "$BADADR_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["go", "rust"]
    }
  }
}
EOF
cat > "$BADADR_TMP/docs/decisions/0001-broken.md" <<'EOF'
---
title: Broken
decision_keys: [unclosed bracket
status: accepted
---

# Body.
EOF
RESULT_BADADR=$(python3 "$CHECK" "$BADADR_TMP")
PASSED_BADADR=$(echo "$RESULT_BADADR" | jq -r .passed)
DETAIL_BADADR=$(echo "$RESULT_BADADR" | jq -r .detail)
assert_eq "$PASSED_BADADR" "false" "malformed ADR must NOT count as coverage; decision flagged"
assert_contains "$DETAIL_BADADR" "tech_stack.language" "malformed-ADR detail must name uncovered decision"
rm -rf "$BADADR_TMP"

# (9) No state.json: INFO pass (deferred to json_valid).
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(python3 "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
DETAIL_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .detail)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS"
assert_eq "$SEVERITY_NOSTATE" "INFO" "no-state severity must be INFO"
assert_contains "$DETAIL_NOSTATE" "missing" "no-state detail must mention missing"
rm -rf "$NOSTATE_TMP"

# (10) Malformed state.json: INFO pass (deferred).
MALFORMED_TMP=$(mktemp -d)
mkdir -p "$MALFORMED_TMP/docs"
printf '{this is not json\n' > "$MALFORMED_TMP/docs/_architect_state.json"
RESULT_MALFORMED=$(python3 "$CHECK" "$MALFORMED_TMP")
PASSED_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .passed)
SEVERITY_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .severity)
DETAIL_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .detail)
assert_eq "$PASSED_MALFORMED" "true" "malformed state.json must PASS (deferred)"
assert_eq "$SEVERITY_MALFORMED" "INFO" "malformed-state severity must be INFO"
assert_contains "$DETAIL_MALFORMED" "deferred" "malformed detail must mention deferral"
rm -rf "$MALFORMED_TMP"

# (11) Non-object state.json root (array): INFO pass (deferred).
NONOBJ_TMP=$(mktemp -d)
mkdir -p "$NONOBJ_TMP/docs"
printf '[1,2,3]\n' > "$NONOBJ_TMP/docs/_architect_state.json"
RESULT_NONOBJ=$(python3 "$CHECK" "$NONOBJ_TMP")
PASSED_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .passed)
SEVERITY_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .severity)
DETAIL_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .detail)
assert_eq "$PASSED_NONOBJ" "true" "non-object state.json root must PASS (deferred)"
assert_eq "$SEVERITY_NONOBJ" "INFO" "non-object root severity must be INFO"
assert_contains "$DETAIL_NONOBJ" "not an object" "non-object detail must mention 'not an object'"
rm -rf "$NONOBJ_TMP"

# (12) Multiple uncovered decisions: detail must list each, count must match.
MULTI_TMP=$(mktemp -d)
mkdir -p "$MULTI_TMP/docs"
cat > "$MULTI_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["go", "rust"]
    },
    "runtime": {
      "executor": "tokio",
      "executor_alternatives_considered": ["tokio", "async-std"]
    }
  }
}
EOF
RESULT_MULTI=$(python3 "$CHECK" "$MULTI_TMP")
PASSED_MULTI=$(echo "$RESULT_MULTI" | jq -r .passed)
DETAIL_MULTI=$(echo "$RESULT_MULTI" | jq -r .detail)
assert_eq "$PASSED_MULTI" "false" "multiple uncovered decisions must FAIL"
assert_contains "$DETAIL_MULTI" "2 high-stakes" "multi-fail detail must report count=2"
assert_contains "$DETAIL_MULTI" "tech_stack.language" "multi-fail detail must name tech_stack.language"
assert_contains "$DETAIL_MULTI" "runtime.executor" "multi-fail detail must name runtime.executor"
rm -rf "$MULTI_TMP"

# (13) No docs/decisions/ directory at all: high-stakes decisions are
#     uncovered (no ADRs exist). Must FAIL.
NOADRDIR_TMP=$(mktemp -d)
mkdir -p "$NOADRDIR_TMP/docs"
cat > "$NOADRDIR_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {
      "language": "rust",
      "language_alternatives_considered": ["go", "rust"]
    }
  }
}
EOF
RESULT_NOADRDIR=$(python3 "$CHECK" "$NOADRDIR_TMP")
PASSED_NOADRDIR=$(echo "$RESULT_NOADRDIR" | jq -r .passed)
DETAIL_NOADRDIR=$(echo "$RESULT_NOADRDIR" | jq -r .detail)
assert_eq "$PASSED_NOADRDIR" "false" "no docs/decisions/ at all must FAIL (high-stakes uncovered)"
assert_contains "$DETAIL_NOADRDIR" "tech_stack.language" "no-adr-dir detail must name the uncovered decision"
rm -rf "$NOADRDIR_TMP"

# (14) Decision exists but no _alternatives_considered sibling: not high-stakes.
#     Mirrors the convention of a "default pick" — no ADR required.
NOALTS_TMP=$(mktemp -d)
mkdir -p "$NOALTS_TMP/docs"
cat > "$NOALTS_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "project": {
      "name": "WidgetMaker"
    }
  }
}
EOF
RESULT_NOALTS=$(python3 "$CHECK" "$NOALTS_TMP")
PASSED_NOALTS=$(echo "$RESULT_NOALTS" | jq -r .passed)
DETAIL_NOALTS=$(echo "$RESULT_NOALTS" | jq -r .detail)
assert_eq "$PASSED_NOALTS" "true" "decision without _alternatives_considered sibling is not high-stakes; PASS"
assert_contains "$DETAIL_NOALTS" "no high-stakes" "no-alts detail must say 'no high-stakes'"
rm -rf "$NOALTS_TMP"

# (15) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" "$RESULT_MULTIKEY" \
         "$RESULT_ONEALT" "$RESULT_NULLVAL" "$RESULT_NESTED" "$RESULT_BADADR" \
         "$RESULT_NOSTATE" "$RESULT_MALFORMED" "$RESULT_NONOBJ" "$RESULT_MULTI" \
         "$RESULT_NOADRDIR" "$RESULT_NOALTS"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
