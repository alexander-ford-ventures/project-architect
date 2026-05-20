#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
#
# E2E fixture test (Python TUI, full-screen Textual app). Exercises the full
# Phase 4 → 5 → 6 → 7 → 8 audit chain by running run_all.sh against a
# representative pre-Phase-4 bundle that selects Sketch E's Python CLI-UX track
# (textual, rich, prompt_toolkit, typer). (Task 54, sketch E.)

source "$(dirname "$0")/lib/test_helpers.sh"

FIXTURE="$REPO_ROOT/tests/fixtures/e2e-python-tui"
RUNNER="$REPO_ROOT/agents/quality-gate-auditor/run_all.sh"

assert_dir_exists "$FIXTURE" "e2e-python-tui fixture must exist"
assert_file_exists "$FIXTURE/docs/_architect_state.json" "fixture state.json must exist"
assert_file_exists "$RUNNER" "auditor runner must exist"

# Fixture must encode the Python TUI track (sketch E)
STATE_JSON=$(cat "$FIXTURE/docs/_architect_state.json")
LANGUAGE=$(echo "$STATE_JSON" | jq -r '.decisions.tech_stack.language')
EXPERIENCE=$(echo "$STATE_JSON" | jq -r '.decisions.cli_experience_model')
TUI_LIB=$(echo "$STATE_JSON" | jq -r '.decisions.cli_ux_libraries.tui_framework')
assert_eq "$LANGUAGE" "python" "fixture must declare tech_stack.language=python"
assert_eq "$EXPERIENCE" "full_tui" "fixture must declare cli_experience_model=full_tui"
assert_eq "$TUI_LIB" "textual" "fixture must declare cli_ux_libraries.tui_framework=textual"

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
[[ "$BLOCKER_COUNT" -le 3 ]] && PASS_COUNT=$((PASS_COUNT + 1)) || { FAIL_COUNT=$((FAIL_COUNT + 1)); FAIL_MESSAGES+=("FAIL: BLOCKER count $BLOCKER_COUNT exceeds threshold (3)"); }

test_summary
