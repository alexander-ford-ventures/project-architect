#!/usr/bin/env bash
source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_01_links.sh"
assert_file_exists "$CHECK" "check_01_links.sh must exist"

# Clean fixture: passed=true
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle" "$REPO_ROOT/tests/fixtures/clean-bundle/docs/_architect_state.json")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture must pass"

# Broken fixture: passed=false
RESULT_BROKEN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/broken-link" "$REPO_ROOT/tests/fixtures/broken-link/docs/_architect_state.json")
PASSED_BROKEN=$(echo "$RESULT_BROKEN" | jq -r .passed)
assert_eq "$PASSED_BROKEN" "false" "broken-link fixture must fail"
SEVERITY=$(echo "$RESULT_BROKEN" | jq -r .severity)
assert_eq "$SEVERITY" "BLOCKER" "broken link must be a BLOCKER"
DETAIL=$(echo "$RESULT_BROKEN" | jq -r .detail)
assert_contains "$DETAIL" "does-not-exist.md" "detail must name the broken link target"

test_summary
