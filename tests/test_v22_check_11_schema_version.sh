#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Tests for check_11_schema_version.sh (Sketch B, check ID B11, WARNING).
# Covers bug #1 from the v2.1.5 md2pdf live test: state.schema_version was
# incorrectly initialized to the plugin's release version, conflating the
# state-schema version with the plugin version.

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_11_schema_version.sh"
assert_file_exists "$CHECK" "check_11 must exist"
assert_executable "$CHECK" "check_11 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed (the check
# uses jq to parse state.json). The check itself emits INFO-pass when state is
# unreadable, but functional verification of the WARNING paths requires jq.
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_11 fully"
  test_summary
  exit 0
fi

# (1) Bad fixture: schema_version="2.1.5", plugin_version="2.1.5" — wrong on
#     BOTH counts (not "2.0" AND they match). Confirm the check names both
#     problems in the detail so authors can fix everything in one pass.
RESULT_BAD=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/schema-version-as-plugin-version")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "bad fixture must FAIL (schema=plugin=2.1.5)"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "WARNING" "schema_version failure severity must be WARNING"
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
assert_eq "$ID_BAD" "B11" "id must be B11"
CHECK_BAD=$(echo "$RESULT_BAD" | jq -r .check)
assert_eq "$CHECK_BAD" "schema_version" "check name must be schema_version"
AUTO_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$AUTO_BAD" "true" "schema_version failure must be auto_fixable"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "2.1.5" "detail must name the offending value"
assert_contains "$DETAIL_BAD" "expected '2.0'" "detail must state expected value"
assert_contains "$DETAIL_BAD" "bug #1" "detail must cite bug #1 (collision case)"

# (2) Clean-bundle fixture: state.json={"phase":"complete"} — parseable, but
#     schema_version is absent. Expected WARNING fail "missing".
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "false" "clean-bundle (no schema_version key) must FAIL"
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_contains "$DETAIL_CLEAN" "missing" "clean-bundle detail must say 'missing'"

# (3) Healthy tempdir: schema_version="2.0", plugin_version="2.2.0" (distinct).
#     Expected WARNING pass naming both versions.
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs"
cat > "$HEALTHY_TMP/docs/_architect_state.json" <<'EOF'
{
  "schema_version": "2.0",
  "plugin_version": "2.2.0",
  "phase": "phase_5"
}
EOF
RESULT_HEALTHY=$(bash "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
assert_eq "$PASSED_HEALTHY" "true" "healthy state (schema=2.0, plugin=2.2.0) must pass"
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
assert_eq "$SEVERITY_HEALTHY" "WARNING" "pass severity must be WARNING (check ran)"
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_contains "$DETAIL_HEALTHY" "2.0" "pass detail must name schema_version=2.0"
assert_contains "$DETAIL_HEALTHY" "2.2.0" "pass detail must name plugin_version=2.2.0"
rm -rf "$HEALTHY_TMP"

# (4) Missing-schema_version tempdir: state has plugin_version but no
#     schema_version key. Expected WARNING fail "missing".
MISSING_TMP=$(mktemp -d)
mkdir -p "$MISSING_TMP/docs"
cat > "$MISSING_TMP/docs/_architect_state.json" <<'EOF'
{
  "plugin_version": "2.2.0",
  "phase": "phase_2"
}
EOF
RESULT_MISSING=$(bash "$CHECK" "$MISSING_TMP")
PASSED_MISSING=$(echo "$RESULT_MISSING" | jq -r .passed)
assert_eq "$PASSED_MISSING" "false" "missing schema_version must FAIL"
DETAIL_MISSING=$(echo "$RESULT_MISSING" | jq -r .detail)
assert_contains "$DETAIL_MISSING" "missing" "missing-field detail must say 'missing'"
assert_not_contains "$DETAIL_MISSING" "bug #1" "missing field must NOT trigger the collision message"
rm -rf "$MISSING_TMP"

# (5) Wrong-schema_version tempdir: schema_version="1.0", plugin_version="2.2.0".
#     Expected WARNING fail "expected '2.0'" but NOT the collision message
#     (versions differ).
WRONG_TMP=$(mktemp -d)
mkdir -p "$WRONG_TMP/docs"
cat > "$WRONG_TMP/docs/_architect_state.json" <<'EOF'
{
  "schema_version": "1.0",
  "plugin_version": "2.2.0",
  "phase": "phase_3"
}
EOF
RESULT_WRONG=$(bash "$CHECK" "$WRONG_TMP")
PASSED_WRONG=$(echo "$RESULT_WRONG" | jq -r .passed)
assert_eq "$PASSED_WRONG" "false" "wrong schema_version (1.0) must FAIL"
DETAIL_WRONG=$(echo "$RESULT_WRONG" | jq -r .detail)
assert_contains "$DETAIL_WRONG" "expected '2.0'" "wrong-value detail must say 'expected 2.0'"
assert_contains "$DETAIL_WRONG" "'1.0'" "wrong-value detail must name the offending value"
assert_not_contains "$DETAIL_WRONG" "bug #1" "differing versions must NOT trigger collision message"
rm -rf "$WRONG_TMP"

# (6) Malformed state.json tempdir: unparseable JSON. Expected INFO pass
#     (deferred to check_05_json_valid).
MALFORMED_TMP=$(mktemp -d)
mkdir -p "$MALFORMED_TMP/docs"
printf '{this is not json\n' > "$MALFORMED_TMP/docs/_architect_state.json"
RESULT_MALFORMED=$(bash "$CHECK" "$MALFORMED_TMP")
PASSED_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .passed)
assert_eq "$PASSED_MALFORMED" "true" "malformed state.json must PASS (deferred)"
SEVERITY_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .severity)
assert_eq "$SEVERITY_MALFORMED" "INFO" "malformed-state severity must be INFO"
DETAIL_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .detail)
assert_contains "$DETAIL_MALFORMED" "deferred" "malformed detail must mention deferral"
rm -rf "$MALFORMED_TMP"

# (7) No state.json tempdir: state file absent entirely. Expected INFO pass.
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(bash "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS (deferred)"
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
assert_eq "$SEVERITY_NOSTATE" "INFO" "no-state severity must be INFO"
rm -rf "$NOSTATE_TMP"

# (8) schema_version="2.0" but no plugin_version. Expected pass — the check
#     can't compare against a missing value, so it doesn't claim a collision.
NOPLUGIN_TMP=$(mktemp -d)
mkdir -p "$NOPLUGIN_TMP/docs"
cat > "$NOPLUGIN_TMP/docs/_architect_state.json" <<'EOF'
{
  "schema_version": "2.0",
  "phase": "phase_1"
}
EOF
RESULT_NOPLUGIN=$(bash "$CHECK" "$NOPLUGIN_TMP")
PASSED_NOPLUGIN=$(echo "$RESULT_NOPLUGIN" | jq -r .passed)
assert_eq "$PASSED_NOPLUGIN" "true" "schema=2.0, no plugin_version must pass"
rm -rf "$NOPLUGIN_TMP"

# (9) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" "$RESULT_MISSING" \
         "$RESULT_WRONG" "$RESULT_MALFORMED" "$RESULT_NOSTATE" "$RESULT_NOPLUGIN"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
