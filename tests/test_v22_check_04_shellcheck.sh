#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Tests for check_04_shellcheck.sh (Sketch B, check ID B04, BLOCKER).

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_04_shellcheck.sh"
assert_file_exists "$CHECK" "check_04 must exist"

# Skip whole test gracefully if shellcheck isn't installed.
if ! command -v shellcheck >/dev/null 2>&1; then
  echo "SKIP: shellcheck not installed; cannot test check_04 fully"
  test_summary
  exit 0
fi

# Clean fixture (clean-bundle has no .sh files) → trivial pass.
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture must pass (no .sh files)"

# Project root scan: should pass because tests/fixtures/ is excluded
# (only checks "production" .sh files like agents/ and tests/lib/, all of which
# are shellcheck-clean as of Task 13).
RESULT_PROJECT=$(bash "$CHECK" "$REPO_ROOT")
PASSED_PROJECT=$(echo "$RESULT_PROJECT" | jq -r .passed)
assert_eq "$PASSED_PROJECT" "true" "project-root scan must pass (fixtures excluded)"

# Bad-hook fixture in isolation: a project root that IS a temp dir holding the
# bad .sh, with NO tests/fixtures/ ancestor.
BAD_TMP=$(mktemp -d)
mkdir -p "$BAD_TMP"
cp "$REPO_ROOT/tests/fixtures/bad-hook/hook.sh" "$BAD_TMP/hook.sh"
RESULT_BAD=$(bash "$CHECK" "$BAD_TMP")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "bad-hook fixture (outside tests/fixtures/) must fail"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "BLOCKER" "shellcheck failures are BLOCKER"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "hook.sh" "detail must name the failing script"
# Detail should include at least one SC code (e.g., SC2164/SC2154) so a human
# can grep the wiki. We accept any SC[0-9]+ token to stay resilient to which
# specific warning fires in future shellcheck versions.
if [[ "$DETAIL_BAD" =~ SC[0-9]+ ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_MESSAGES+=("FAIL: detail must include a shellcheck SC code; got: $DETAIL_BAD")
fi
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
