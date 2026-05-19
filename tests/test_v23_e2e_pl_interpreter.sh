#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
#
# E2E fixture test (programming-language interpreter, Rust-host tree-walking
# implementation of an educational language called "lume"). Exercises the
# full Phase 4 → 5 → 6 → 7 → 8 audit chain by running run_all.sh against
# a representative pre-Phase-4 bundle that selects the PL track (Sketch E +
# Sketch F: programming_language sub_type with impl_strategy=tree_walking_interpreter,
# host_runtime=rust_host, paradigm=multi_paradigm, type_system=dynamic).
# (v2.3 Task 13.)

source "$(dirname "$0")/lib/test_helpers.sh"

FIXTURE="$REPO_ROOT/tests/fixtures/e2e-programming-language-interpreter"
RUNNER="$REPO_ROOT/agents/quality-gate-auditor/run_all.sh"

assert_dir_exists "$FIXTURE" "e2e-programming-language-interpreter fixture must exist"
assert_file_exists "$FIXTURE/docs/_architect_state.json" "fixture state.json must exist"
assert_file_exists "$RUNNER" "auditor runner must exist"

# Fixture must encode the PL interpreter track (Sketch E + Sketch F decision keys)
STATE_JSON=$(cat "$FIXTURE/docs/_architect_state.json")
SUB_TYPE=$(echo "$STATE_JSON" | jq -r '.decisions.project.sub_type')
IMPL=$(echo "$STATE_JSON" | jq -r '.decisions.impl_strategy')
HR=$(echo "$STATE_JSON" | jq -r '.decisions.host_runtime')
PD=$(echo "$STATE_JSON" | jq -r '.decisions.paradigm')
TS=$(echo "$STATE_JSON" | jq -r '.decisions.type_system')
LANGUAGE=$(echo "$STATE_JSON" | jq -r '.decisions.tech_stack.language')
assert_eq "$SUB_TYPE" "educational_language" "fixture must declare project.sub_type=educational_language"
assert_eq "$IMPL" "tree_walking_interpreter" "fixture must declare impl_strategy=tree_walking_interpreter"
assert_eq "$HR" "rust_host" "fixture must declare host_runtime=rust_host"
assert_eq "$PD" "multi_paradigm" "fixture must declare paradigm=multi_paradigm"
assert_eq "$TS" "dynamic" "fixture must declare type_system=dynamic"
assert_eq "$LANGUAGE" "rust" "fixture must declare tech_stack.language=rust"

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
