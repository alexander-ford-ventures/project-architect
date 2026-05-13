#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Tests for check_05_json_valid.sh (Sketch B, check ID B05, BLOCKER).

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_05_json_valid.sh"
assert_file_exists "$CHECK" "check_05 must exist"

# Skip whole test gracefully if jq isn't installed (the check itself emits INFO,
# so functional verification of the BLOCKER path requires jq).
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_05 fully"
  test_summary
  exit 0
fi

# Clean fixture (clean-bundle has no .json files) → trivial pass.
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture must pass (no .json files)"

# Project root scan: should pass because tests/fixtures/ is excluded
# (only checks "production" .json files like state.json, plugin.json, all valid
# as of the v2.1.5 release).
RESULT_PROJECT=$(bash "$CHECK" "$REPO_ROOT")
PASSED_PROJECT=$(echo "$RESULT_PROJECT" | jq -r .passed)
assert_eq "$PASSED_PROJECT" "true" "project-root scan must pass (fixtures excluded)"

# Bad-settings-json fixture in isolation: a project root that IS a temp dir
# holding the bad .json, with NO tests/fixtures/ ancestor.
BAD_TMP=$(mktemp -d)
mkdir -p "$BAD_TMP"
cp "$REPO_ROOT/tests/fixtures/bad-settings-json/settings.json" "$BAD_TMP/settings.json"
RESULT_BAD=$(bash "$CHECK" "$BAD_TMP")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "bad-settings-json fixture (outside tests/fixtures/) must fail"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "BLOCKER" "json_valid failures are BLOCKER"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "settings.json" "detail must name the failing JSON file"
assert_contains "$DETAIL_BAD" "invalid JSON" "detail must label the failure mode"
rm -rf "$BAD_TMP"

# All outputs valid JSON.
for r in "$RESULT_CLEAN" "$RESULT_PROJECT" "$RESULT_BAD"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
