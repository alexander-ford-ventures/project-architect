#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Tests for check_16_phase_gates.py (Sketch B, check ID B16, BLOCKER).
#
# Covers bug #4 from the v2.1.5 md2pdf live test: an agent (document-author)
# was dispatched for phase_4 before phase_3's pattern-validation research had
# returned. This check is the loud safety net that catches such lapses by
# requiring every phase_progress entry with logged work to have
# prerequisites_satisfied=true.
#
# Truth-table covered here:
#   - bad fixture (phase-without-prereq)                 -> BLOCKER fail naming phase_4 (False)
#   - clean-bundle (no phase_progress)                   -> INFO pass "no phase_progress"
#   - healthy: all phases with work have prereqs=true    -> BLOCKER pass
#   - prereqs missing entirely (key absent)              -> BLOCKER fail "missing"
#   - prereqs=null                                       -> BLOCKER fail "null"
#   - prereqs=false explicitly                           -> BLOCKER fail "False"
#   - prereqs=non-bool string ("yes")                    -> BLOCKER fail (strict True check)
#   - entry exists but no work logged                    -> skipped, INFO pass
#   - multiple phases bad → all listed (sorted)
#   - completed_at only (no started_at)                  -> counts as work
#   - agents_dispatched non-empty                        -> counts as work
#   - decisions_recorded > 0                             -> counts as work
#   - decisions_recorded == 0                            -> does NOT count as work
#   - agents_dispatched = []                             -> does NOT count as work
#   - no state.json                                      -> INFO pass (deferred)
#   - malformed state.json                               -> INFO pass (deferred)
#   - state.json root is array                           -> INFO pass (deferred)
#   - phase_progress not a dict (list)                   -> INFO pass "no phase_progress"
#   - phase_obj not a dict (string)                      -> treated as no-work, skipped
#   - state.phase_progress = {} (empty)                  -> INFO pass
#   - JSON-validity loop over every output

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_16_phase_gates.py"
assert_file_exists "$CHECK" "check_16 must exist"
assert_executable "$CHECK" "check_16 must be executable"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_16 fully"
  test_summary
  exit 0
fi

# (1) Bad fixture: phase_4 has work but prerequisites_satisfied=false → BLOCKER fail.
#     phase_3 has work but prereqs=true → must NOT appear in detail.
RESULT_BAD=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/phase-without-prereq")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
CHECK_NAME_BAD=$(echo "$RESULT_BAD" | jq -r .check)
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$PASSED_BAD" "false" "phase-without-prereq fixture must FAIL"
assert_eq "$SEVERITY_BAD" "BLOCKER" "severity must be BLOCKER"
assert_eq "$ID_BAD" "B16" "id must be B16"
assert_eq "$CHECK_NAME_BAD" "phase_gates" "check name must be phase_gates"
assert_contains "$DETAIL_BAD" "phase_4" "detail must name phase_4"
assert_contains "$DETAIL_BAD" "False" "detail must show the explicit False value"
assert_contains "$DETAIL_BAD" "1 phase(s)" "detail must report count=1"
assert_not_contains "$DETAIL_BAD" "phase_3" "phase_3 (prereqs=true) must NOT appear"
assert_contains "$REMEDIATION_BAD" "prerequisites_satisfied=true" "remediation must reference the field"
assert_contains "$REMEDIATION_BAD" "audit the bundle" "remediation must instruct audit + re-run"
assert_eq "$AUTOFIX_BAD" "false" "requires human audit; auto_fixable=false"

# (2) Clean-bundle: state.json = {"phase":"complete"}. No phase_progress.
#     Expected INFO pass "no phase_progress".
RESULT_CLEAN=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_eq "$PASSED_CLEAN" "true" "clean-bundle (no phase_progress) must PASS"
assert_eq "$SEVERITY_CLEAN" "INFO" "clean-bundle severity must be INFO"
assert_contains "$DETAIL_CLEAN" "no phase_progress" "clean-bundle detail must mention 'no phase_progress'"

# (3) Healthy: every phase with work has prerequisites_satisfied=true → BLOCKER pass.
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs"
cat > "$HEALTHY_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_1": {"started_at": "2026-05-13T00:00:00Z", "completed_at": "2026-05-13T00:30:00Z", "prerequisites_satisfied": true},
    "phase_2": {"started_at": "2026-05-13T00:31:00Z", "completed_at": "2026-05-13T01:00:00Z", "prerequisites_satisfied": true},
    "phase_3": {"started_at": "2026-05-13T01:01:00Z", "agents_dispatched": ["pattern-validator"], "prerequisites_satisfied": true}
  }
}
EOF
RESULT_HEALTHY=$(python3 "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_eq "$PASSED_HEALTHY" "true" "healthy (all prereqs=true) must PASS"
assert_eq "$SEVERITY_HEALTHY" "BLOCKER" "healthy severity must be BLOCKER"
assert_contains "$DETAIL_HEALTHY" "all 3 phase(s)" "healthy detail must report count=3"
assert_contains "$DETAIL_HEALTHY" "prerequisites_satisfied=true" "healthy detail must reference the field"
rm -rf "$HEALTHY_TMP"

# (4) prerequisites_satisfied key absent: must fail with "missing".
MISSING_TMP=$(mktemp -d)
mkdir -p "$MISSING_TMP/docs"
cat > "$MISSING_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"started_at": "2026-05-13T00:00:00Z", "completed_at": "2026-05-13T00:30:00Z"}
  }
}
EOF
RESULT_MISSING=$(python3 "$CHECK" "$MISSING_TMP")
PASSED_MISSING=$(echo "$RESULT_MISSING" | jq -r .passed)
DETAIL_MISSING=$(echo "$RESULT_MISSING" | jq -r .detail)
assert_eq "$PASSED_MISSING" "false" "missing prereqs key must FAIL"
assert_contains "$DETAIL_MISSING" "phase_2" "missing-key detail must name phase_2"
assert_contains "$DETAIL_MISSING" "missing" "missing-key detail must say 'missing'"
rm -rf "$MISSING_TMP"

# (5) prerequisites_satisfied=null: must fail with "null".
NULL_TMP=$(mktemp -d)
mkdir -p "$NULL_TMP/docs"
cat > "$NULL_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"started_at": "2026-05-13T00:00:00Z", "prerequisites_satisfied": null}
  }
}
EOF
RESULT_NULL=$(python3 "$CHECK" "$NULL_TMP")
PASSED_NULL=$(echo "$RESULT_NULL" | jq -r .passed)
DETAIL_NULL=$(echo "$RESULT_NULL" | jq -r .detail)
assert_eq "$PASSED_NULL" "false" "null prereqs must FAIL"
assert_contains "$DETAIL_NULL" "phase_2" "null detail must name phase_2"
assert_contains "$DETAIL_NULL" "null" "null detail must say 'null'"
rm -rf "$NULL_TMP"

# (6) prerequisites_satisfied set to a non-bool string ("yes"): must fail (strict True check).
WRONGTYPE_TMP=$(mktemp -d)
mkdir -p "$WRONGTYPE_TMP/docs"
cat > "$WRONGTYPE_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"started_at": "2026-05-13T00:00:00Z", "prerequisites_satisfied": "yes"}
  }
}
EOF
RESULT_WRONGTYPE=$(python3 "$CHECK" "$WRONGTYPE_TMP")
PASSED_WRONGTYPE=$(echo "$RESULT_WRONGTYPE" | jq -r .passed)
DETAIL_WRONGTYPE=$(echo "$RESULT_WRONGTYPE" | jq -r .detail)
assert_eq "$PASSED_WRONGTYPE" "false" "non-bool string prereqs must FAIL"
assert_contains "$DETAIL_WRONGTYPE" "phase_2" "wrong-type detail must name phase_2"
assert_contains "$DETAIL_WRONGTYPE" "yes" "wrong-type detail must include the offending value"
rm -rf "$WRONGTYPE_TMP"

# (7) Entry exists but no work logged: skipped → INFO pass.
#     (Entry just created by orchestrator; prereqs unset is fine.)
NOWORK_TMP=$(mktemp -d)
mkdir -p "$NOWORK_TMP/docs"
cat > "$NOWORK_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_5": {"agents_dispatched": [], "decisions_recorded": 0}
  }
}
EOF
RESULT_NOWORK=$(python3 "$CHECK" "$NOWORK_TMP")
PASSED_NOWORK=$(echo "$RESULT_NOWORK" | jq -r .passed)
SEVERITY_NOWORK=$(echo "$RESULT_NOWORK" | jq -r .severity)
DETAIL_NOWORK=$(echo "$RESULT_NOWORK" | jq -r .detail)
assert_eq "$PASSED_NOWORK" "true" "no-work entry must PASS"
assert_eq "$SEVERITY_NOWORK" "INFO" "no-work severity must be INFO"
assert_contains "$DETAIL_NOWORK" "no work logged yet" "no-work detail correct"
rm -rf "$NOWORK_TMP"

# (8) Multiple bad phases: every offender must appear, sorted.
MULTIBAD_TMP=$(mktemp -d)
mkdir -p "$MULTIBAD_TMP/docs"
cat > "$MULTIBAD_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_3": {"started_at": "2026-05-13T00:00:00Z", "prerequisites_satisfied": false},
    "phase_4": {"started_at": "2026-05-13T00:30:00Z"},
    "phase_2": {"started_at": "2026-05-13T01:00:00Z", "prerequisites_satisfied": true}
  }
}
EOF
RESULT_MULTIBAD=$(python3 "$CHECK" "$MULTIBAD_TMP")
PASSED_MULTIBAD=$(echo "$RESULT_MULTIBAD" | jq -r .passed)
DETAIL_MULTIBAD=$(echo "$RESULT_MULTIBAD" | jq -r .detail)
assert_eq "$PASSED_MULTIBAD" "false" "multi-bad must FAIL"
assert_contains "$DETAIL_MULTIBAD" "phase_3" "multi-bad detail must include phase_3"
assert_contains "$DETAIL_MULTIBAD" "phase_4" "multi-bad detail must include phase_4"
assert_not_contains "$DETAIL_MULTIBAD" "phase_2:" "phase_2 (prereqs=true) must NOT appear with colon"
assert_contains "$DETAIL_MULTIBAD" "2 phase(s)" "multi-bad must report count=2"
rm -rf "$MULTIBAD_TMP"

# (9) Only completed_at set (no started_at): still counts as work.
COMPLETED_ONLY_TMP=$(mktemp -d)
mkdir -p "$COMPLETED_ONLY_TMP/docs"
cat > "$COMPLETED_ONLY_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"completed_at": "2026-05-13T00:30:00Z"}
  }
}
EOF
RESULT_COMPLETED_ONLY=$(python3 "$CHECK" "$COMPLETED_ONLY_TMP")
PASSED_COMPLETED_ONLY=$(echo "$RESULT_COMPLETED_ONLY" | jq -r .passed)
DETAIL_COMPLETED_ONLY=$(echo "$RESULT_COMPLETED_ONLY" | jq -r .detail)
assert_eq "$PASSED_COMPLETED_ONLY" "false" "completed_at-only with missing prereqs must FAIL"
assert_contains "$DETAIL_COMPLETED_ONLY" "phase_2" "completed_at-only must name phase_2"
rm -rf "$COMPLETED_ONLY_TMP"

# (10) Only agents_dispatched non-empty: counts as work.
AGENTS_ONLY_TMP=$(mktemp -d)
mkdir -p "$AGENTS_ONLY_TMP/docs"
cat > "$AGENTS_ONLY_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"agents_dispatched": ["scout"]}
  }
}
EOF
RESULT_AGENTS_ONLY=$(python3 "$CHECK" "$AGENTS_ONLY_TMP")
PASSED_AGENTS_ONLY=$(echo "$RESULT_AGENTS_ONLY" | jq -r .passed)
assert_eq "$PASSED_AGENTS_ONLY" "false" "agents_dispatched non-empty with missing prereqs must FAIL"
rm -rf "$AGENTS_ONLY_TMP"

# (11) decisions_recorded > 0: counts as work.
DECISIONS_RECORDED_TMP=$(mktemp -d)
mkdir -p "$DECISIONS_RECORDED_TMP/docs"
cat > "$DECISIONS_RECORDED_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase_progress": {
    "phase_2": {"decisions_recorded": 3}
  }
}
EOF
RESULT_DECISIONS_RECORDED=$(python3 "$CHECK" "$DECISIONS_RECORDED_TMP")
PASSED_DECISIONS_RECORDED=$(echo "$RESULT_DECISIONS_RECORDED" | jq -r .passed)
assert_eq "$PASSED_DECISIONS_RECORDED" "false" "decisions_recorded>0 with missing prereqs must FAIL"
rm -rf "$DECISIONS_RECORDED_TMP"

# (12) State has phase_progress = {} (empty dict): INFO pass.
EMPTYPP_TMP=$(mktemp -d)
mkdir -p "$EMPTYPP_TMP/docs"
cat > "$EMPTYPP_TMP/docs/_architect_state.json" <<'EOF'
{"phase_progress": {}}
EOF
RESULT_EMPTYPP=$(python3 "$CHECK" "$EMPTYPP_TMP")
PASSED_EMPTYPP=$(echo "$RESULT_EMPTYPP" | jq -r .passed)
SEVERITY_EMPTYPP=$(echo "$RESULT_EMPTYPP" | jq -r .severity)
DETAIL_EMPTYPP=$(echo "$RESULT_EMPTYPP" | jq -r .detail)
assert_eq "$PASSED_EMPTYPP" "true" "empty phase_progress must PASS"
assert_eq "$SEVERITY_EMPTYPP" "INFO" "empty phase_progress severity must be INFO"
assert_contains "$DETAIL_EMPTYPP" "no phase_progress" "empty-PP detail correct"
rm -rf "$EMPTYPP_TMP"

# (13) phase_progress is a list (wrong type): treated as "no phase_progress".
LISTPP_TMP=$(mktemp -d)
mkdir -p "$LISTPP_TMP/docs"
cat > "$LISTPP_TMP/docs/_architect_state.json" <<'EOF'
{"phase_progress": ["phase_1", "phase_2"]}
EOF
RESULT_LISTPP=$(python3 "$CHECK" "$LISTPP_TMP")
PASSED_LISTPP=$(echo "$RESULT_LISTPP" | jq -r .passed)
DETAIL_LISTPP=$(echo "$RESULT_LISTPP" | jq -r .detail)
assert_eq "$PASSED_LISTPP" "true" "list phase_progress must PASS (treated as no phase_progress)"
assert_contains "$DETAIL_LISTPP" "no phase_progress" "list-PP detail correct"
rm -rf "$LISTPP_TMP"

# (14) phase_obj is a string (wrong type): treated as no-work, skipped.
STRINGOBJ_TMP=$(mktemp -d)
mkdir -p "$STRINGOBJ_TMP/docs"
cat > "$STRINGOBJ_TMP/docs/_architect_state.json" <<'EOF'
{"phase_progress": {"phase_1": "garbage-string"}}
EOF
RESULT_STRINGOBJ=$(python3 "$CHECK" "$STRINGOBJ_TMP")
PASSED_STRINGOBJ=$(echo "$RESULT_STRINGOBJ" | jq -r .passed)
DETAIL_STRINGOBJ=$(echo "$RESULT_STRINGOBJ" | jq -r .detail)
assert_eq "$PASSED_STRINGOBJ" "true" "string phase_obj must skip (treated as no work)"
assert_contains "$DETAIL_STRINGOBJ" "no work logged yet" "string-obj detail correct"
rm -rf "$STRINGOBJ_TMP"

# (15) decisions_recorded == 0: does NOT count as work; passes.
ZERODECISIONS_TMP=$(mktemp -d)
mkdir -p "$ZERODECISIONS_TMP/docs"
cat > "$ZERODECISIONS_TMP/docs/_architect_state.json" <<'EOF'
{"phase_progress": {"phase_2": {"decisions_recorded": 0}}}
EOF
RESULT_ZERODECISIONS=$(python3 "$CHECK" "$ZERODECISIONS_TMP")
PASSED_ZERODECISIONS=$(echo "$RESULT_ZERODECISIONS" | jq -r .passed)
DETAIL_ZERODECISIONS=$(echo "$RESULT_ZERODECISIONS" | jq -r .detail)
assert_eq "$PASSED_ZERODECISIONS" "true" "decisions_recorded=0 must PASS (no work)"
assert_contains "$DETAIL_ZERODECISIONS" "no work logged yet" "zero-decisions detail correct"
rm -rf "$ZERODECISIONS_TMP"

# (16) No state.json: INFO pass (deferred to json_valid).
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(python3 "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
DETAIL_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .detail)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS"
assert_eq "$SEVERITY_NOSTATE" "INFO" "no-state severity must be INFO"
assert_contains "$DETAIL_NOSTATE" "missing" "no-state detail must mention missing"
rm -rf "$NOSTATE_TMP"

# (17) Malformed state.json: INFO pass (deferred).
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

# (18) Non-object state.json root (array): INFO pass (deferred).
NONOBJ_TMP=$(mktemp -d)
mkdir -p "$NONOBJ_TMP/docs"
printf '[1,2,3]\n' > "$NONOBJ_TMP/docs/_architect_state.json"
RESULT_NONOBJ=$(python3 "$CHECK" "$NONOBJ_TMP")
PASSED_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .passed)
SEVERITY_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .severity)
DETAIL_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .detail)
assert_eq "$PASSED_NONOBJ" "true" "non-object root must PASS (deferred)"
assert_eq "$SEVERITY_NONOBJ" "INFO" "non-object root severity must be INFO"
assert_contains "$DETAIL_NONOBJ" "not an object" "non-object detail must mention 'not an object'"
rm -rf "$NONOBJ_TMP"

# (19) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" "$RESULT_MISSING" \
         "$RESULT_NULL" "$RESULT_WRONGTYPE" "$RESULT_NOWORK" "$RESULT_MULTIBAD" \
         "$RESULT_COMPLETED_ONLY" "$RESULT_AGENTS_ONLY" "$RESULT_DECISIONS_RECORDED" \
         "$RESULT_EMPTYPP" "$RESULT_LISTPP" "$RESULT_STRINGOBJ" \
         "$RESULT_ZERODECISIONS" "$RESULT_NOSTATE" "$RESULT_MALFORMED" \
         "$RESULT_NONOBJ"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
