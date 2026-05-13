#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Tests for check_12_iso8601_timestamps.py (Sketch B, check ID B12, WARNING).
#
# Covers bug #2 from the v2.1.5 md2pdf live test: state.started_at was
# written as a date-only string ("2026-05-13") instead of a full ISO8601
# datetime ("2026-05-13T04:00:00Z"). Downstream consumers (lock-stale
# detection, "what changed in the last hour" queries, audit log diffing)
# silently coerce the bare date to midnight, producing nonsense answers.
#
# Truth-table covered here:
#   - bad fixture (started_at date-only)  -> WARNING fail naming started_at
#   - clean-bundle state.json (no ts)     -> WARNING pass
#   - healthy tempdir (all ts ok)         -> WARNING pass
#   - locked_at=null                      -> not flagged (nullable)
#   - non-string ts                       -> flagged
#   - phase_progress.X.completed_at bad   -> flagged
#   - documents_generated[i].generated_at -> flagged
#   - research_findings[i].dispatched_at  -> flagged
#   - no state.json                       -> INFO pass (deferred)
#   - malformed state.json                -> INFO pass (deferred)
#   - state.json root is not object       -> INFO pass (deferred)

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_12_iso8601_timestamps.py"
assert_file_exists "$CHECK" "check_12 must exist"
assert_executable "$CHECK" "check_12 must be executable"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_12 fully"
  test_summary
  exit 0
fi

# (1) Bad fixture: started_at is date-only "2026-05-13".
#     Expected WARNING fail naming started_at AND "date-only".
RESULT_BAD=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/date-only-timestamp")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
CHECK_NAME_BAD=$(echo "$RESULT_BAD" | jq -r .check)
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$PASSED_BAD" "false" "date-only fixture must FAIL"
assert_eq "$SEVERITY_BAD" "WARNING" "date-only severity must be WARNING"
assert_eq "$ID_BAD" "B12" "id must be B12"
assert_eq "$CHECK_NAME_BAD" "iso8601_timestamps" "check name must be iso8601_timestamps"
assert_contains "$DETAIL_BAD" "started_at" "detail must name started_at"
assert_contains "$DETAIL_BAD" "date-only" "detail must say 'date-only'"
assert_contains "$DETAIL_BAD" "1 timestamp" "detail must report exactly 1 malformed field (last_updated_at is OK)"
assert_contains "$REMEDIATION_BAD" "ISO8601" "remediation must mention ISO8601"
assert_eq "$AUTOFIX_BAD" "true" "date-only must be auto_fixable (mechanical rewrite)"

# (2) Clean-bundle fixture: state.json={"phase":"complete"} — has no timestamp
#     fields at all. Expected WARNING pass.
RESULT_CLEAN=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_eq "$PASSED_CLEAN" "true" "clean-bundle (no timestamps) must PASS"
assert_eq "$SEVERITY_CLEAN" "WARNING" "clean-bundle severity must be WARNING (check ran)"
assert_contains "$DETAIL_CLEAN" "all known timestamp fields" "clean-bundle detail must confirm all fields valid"

# (3) Healthy tempdir: all timestamps are correct ISO8601 datetimes.
#     Expected WARNING pass.
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs"
cat > "$HEALTHY_TMP/docs/_architect_state.json" <<'EOF'
{
  "schema_version": "2.0",
  "plugin_version": "2.2.0",
  "phase": "phase_5",
  "started_at": "2026-05-13T01:00:00Z",
  "last_updated_at": "2026-05-13T04:30:15Z",
  "locked_at": null,
  "phase_progress": {
    "phase_0": {"completed_at": "2026-05-13T01:05:00Z"},
    "phase_1": {"completed_at": "2026-05-13T01:10:00+00:00"}
  },
  "documents_generated": [
    {"name": "ROADMAP.md", "generated_at": "2026-05-13T02:00:00Z"},
    {"name": "ADR-001.md", "generated_at": "2026-05-13T02:30:45.123Z"}
  ],
  "research_findings": [
    {"topic": "auth", "dispatched_at": "2026-05-13T03:00:00Z"}
  ]
}
EOF
RESULT_HEALTHY=$(python3 "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_eq "$PASSED_HEALTHY" "true" "healthy (all timestamps ISO8601) must PASS"
assert_eq "$SEVERITY_HEALTHY" "WARNING" "healthy severity must be WARNING"
assert_contains "$DETAIL_HEALTHY" "all known timestamp fields" "healthy detail must confirm all valid"
rm -rf "$HEALTHY_TMP"

# (4) Nullable locked_at: explicit null must NOT be flagged.
NULL_LOCKED_TMP=$(mktemp -d)
mkdir -p "$NULL_LOCKED_TMP/docs"
cat > "$NULL_LOCKED_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": "2026-05-13T01:00:00Z",
  "last_updated_at": "2026-05-13T04:00:00Z",
  "locked_at": null
}
EOF
RESULT_NULL=$(python3 "$CHECK" "$NULL_LOCKED_TMP")
PASSED_NULL=$(echo "$RESULT_NULL" | jq -r .passed)
DETAIL_NULL=$(echo "$RESULT_NULL" | jq -r .detail)
assert_eq "$PASSED_NULL" "true" "locked_at=null must PASS (nullable field)"
assert_not_contains "$DETAIL_NULL" "locked_at" "null locked_at must NOT appear in detail"
rm -rf "$NULL_LOCKED_TMP"

# (5) Non-string timestamp value: integer 12345. Must be flagged.
NONSTRING_TMP=$(mktemp -d)
mkdir -p "$NONSTRING_TMP/docs"
cat > "$NONSTRING_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": 12345,
  "last_updated_at": "2026-05-13T04:00:00Z"
}
EOF
RESULT_NONSTRING=$(python3 "$CHECK" "$NONSTRING_TMP")
PASSED_NONSTRING=$(echo "$RESULT_NONSTRING" | jq -r .passed)
DETAIL_NONSTRING=$(echo "$RESULT_NONSTRING" | jq -r .detail)
assert_eq "$PASSED_NONSTRING" "false" "non-string timestamp must FAIL"
assert_contains "$DETAIL_NONSTRING" "started_at" "non-string detail must name started_at"
assert_contains "$DETAIL_NONSTRING" "non-string" "non-string detail must say 'non-string'"
rm -rf "$NONSTRING_TMP"

# (6) phase_progress.<phase>.completed_at malformed: nested timestamp flagged.
PHASE_BAD_TMP=$(mktemp -d)
mkdir -p "$PHASE_BAD_TMP/docs"
cat > "$PHASE_BAD_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": "2026-05-13T01:00:00Z",
  "last_updated_at": "2026-05-13T04:00:00Z",
  "phase_progress": {
    "phase_0": {"completed_at": "not-a-date"}
  }
}
EOF
RESULT_PHASE=$(python3 "$CHECK" "$PHASE_BAD_TMP")
PASSED_PHASE=$(echo "$RESULT_PHASE" | jq -r .passed)
DETAIL_PHASE=$(echo "$RESULT_PHASE" | jq -r .detail)
assert_eq "$PASSED_PHASE" "false" "malformed phase_progress completed_at must FAIL"
assert_contains "$DETAIL_PHASE" "phase_progress.phase_0.completed_at" "detail must name the nested phase field path"
rm -rf "$PHASE_BAD_TMP"

# (7) documents_generated[0].generated_at malformed: indexed timestamp flagged.
DOC_BAD_TMP=$(mktemp -d)
mkdir -p "$DOC_BAD_TMP/docs"
cat > "$DOC_BAD_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": "2026-05-13T01:00:00Z",
  "last_updated_at": "2026-05-13T04:00:00Z",
  "documents_generated": [
    {"name": "ROADMAP.md", "generated_at": "2026-05-13"}
  ]
}
EOF
RESULT_DOC=$(python3 "$CHECK" "$DOC_BAD_TMP")
PASSED_DOC=$(echo "$RESULT_DOC" | jq -r .passed)
DETAIL_DOC=$(echo "$RESULT_DOC" | jq -r .detail)
assert_eq "$PASSED_DOC" "false" "malformed documents_generated[0].generated_at must FAIL"
assert_contains "$DETAIL_DOC" "documents_generated[0].generated_at" "detail must use indexed array path"
rm -rf "$DOC_BAD_TMP"

# (8) research_findings[0].dispatched_at malformed: flagged similarly.
FINDING_BAD_TMP=$(mktemp -d)
mkdir -p "$FINDING_BAD_TMP/docs"
cat > "$FINDING_BAD_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": "2026-05-13T01:00:00Z",
  "last_updated_at": "2026-05-13T04:00:00Z",
  "research_findings": [
    {"topic": "auth", "dispatched_at": "2026/05/13 04:00:00"}
  ]
}
EOF
RESULT_FINDING=$(python3 "$CHECK" "$FINDING_BAD_TMP")
PASSED_FINDING=$(echo "$RESULT_FINDING" | jq -r .passed)
DETAIL_FINDING=$(echo "$RESULT_FINDING" | jq -r .detail)
assert_eq "$PASSED_FINDING" "false" "malformed research_findings[0].dispatched_at must FAIL"
assert_contains "$DETAIL_FINDING" "research_findings[0].dispatched_at" "detail must use indexed array path"
rm -rf "$FINDING_BAD_TMP"

# (9) No state.json: INFO pass (deferred).
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(python3 "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
DETAIL_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .detail)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS"
assert_eq "$SEVERITY_NOSTATE" "INFO" "no state.json severity must be INFO"
assert_contains "$DETAIL_NOSTATE" "missing" "no-state detail must mention missing"
rm -rf "$NOSTATE_TMP"

# (10) Malformed JSON state.json: INFO pass (deferred to json_valid).
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

# (11) Non-object root state.json (array): INFO pass (deferred).
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

# (12) Multiple failures at once: ensure each is listed in detail.
MULTI_BAD_TMP=$(mktemp -d)
mkdir -p "$MULTI_BAD_TMP/docs"
cat > "$MULTI_BAD_TMP/docs/_architect_state.json" <<'EOF'
{
  "started_at": "2026-05-13",
  "last_updated_at": "yesterday",
  "phase_progress": {
    "phase_0": {"completed_at": "2026-05-13"}
  }
}
EOF
RESULT_MULTI=$(python3 "$CHECK" "$MULTI_BAD_TMP")
PASSED_MULTI=$(echo "$RESULT_MULTI" | jq -r .passed)
DETAIL_MULTI=$(echo "$RESULT_MULTI" | jq -r .detail)
assert_eq "$PASSED_MULTI" "false" "multiple bad timestamps must FAIL"
assert_contains "$DETAIL_MULTI" "3 timestamp" "detail must report count=3"
assert_contains "$DETAIL_MULTI" "started_at" "multi-fail detail must name started_at"
assert_contains "$DETAIL_MULTI" "last_updated_at" "multi-fail detail must name last_updated_at"
assert_contains "$DETAIL_MULTI" "phase_progress.phase_0.completed_at" "multi-fail detail must name phase_progress path"
rm -rf "$MULTI_BAD_TMP"

# (13) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" "$RESULT_NULL" \
         "$RESULT_NONSTRING" "$RESULT_PHASE" "$RESULT_DOC" "$RESULT_FINDING" \
         "$RESULT_NOSTATE" "$RESULT_MALFORMED" "$RESULT_NONOBJ" "$RESULT_MULTI"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
