#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
#
# E2E fixture test (Rust CLI, md2pdf-style). Exercises the full Phase 4 → 5 → 6 → 7 → 8
# audit chain by running run_all.sh against a representative pre-Phase-4 bundle.
# (Task 53, sketch B+C+D.)

source "$(dirname "$0")/lib/test_helpers.sh"

FIXTURE="$REPO_ROOT/tests/fixtures/e2e-rust-cli"
RUNNER="$REPO_ROOT/agents/quality-gate-auditor/run_all.sh"

assert_dir_exists "$FIXTURE" "e2e-rust-cli fixture must exist"
assert_file_exists "$FIXTURE/docs/_architect_state.json" "fixture state.json must exist"
assert_file_exists "$RUNNER" "auditor runner must exist"

# Run the auditor against the fixture
RESULT=$(bash "$RUNNER" "$FIXTURE" "$FIXTURE/docs/_architect_state.json" 2>&1)

# Output must be valid JSON
if echo "$RESULT" | jq -e . >/dev/null 2>&1; then
  PASS_COUNT=$((PASS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_MESSAGES+=("FAIL: auditor output is not valid JSON: $RESULT")
fi

# Output must have summary + findings keys
SUMMARY=$(echo "$RESULT" | jq -r '.summary // {} | tostring')
assert_contains "$SUMMARY" 'blocker' 'summary must include blocker count'
assert_contains "$SUMMARY" 'warning' 'summary must include warning count'
assert_contains "$SUMMARY" 'info' 'summary must include info count'

FINDINGS_COUNT=$(echo "$RESULT" | jq '.findings | length')
[[ "$FINDINGS_COUNT" -ge 1 ]] && PASS_COUNT=$((PASS_COUNT + 1)) || { FAIL_COUNT=$((FAIL_COUNT + 1)); FAIL_MESSAGES+=("FAIL: findings array should have at least 1 entry"); }

# BLOCKER count should be acceptable (the fixture is designed to pass most checks)
BLOCKER_COUNT=$(echo "$RESULT" | jq -r '.summary.blocker')
# Acceptable: 0 BLOCKERs ideally, but a few are OK for an e2e fixture (e.g., adr_coverage may flag missing ADRs)
[[ "$BLOCKER_COUNT" -le 3 ]] && PASS_COUNT=$((PASS_COUNT + 1)) || { FAIL_COUNT=$((FAIL_COUNT + 1)); FAIL_MESSAGES+=("FAIL: BLOCKER count $BLOCKER_COUNT exceeds threshold (3)"); }

test_summary
