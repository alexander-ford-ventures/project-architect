#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Tests for check_06_claude_md_hierarchy.sh (Sketch B, check ID B06, WARNING).
# Covers the bug-#8 anti-pattern: multi-subfolder project with only a root
# CLAUDE.md and no per-subfolder CLAUDE.mds.

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_06_claude_md_hierarchy.sh"
assert_file_exists "$CHECK" "check_06 must exist"
assert_executable "$CHECK" "check_06 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed (the check
# uses jq to parse state.json). The check itself emits INFO-pass when state is
# unreadable, but we still want to lock down its functional truth-table here.
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_06 fully"
  test_summary
  exit 0
fi

# (1) Clean fixture (clean-bundle has no CLAUDE.md and state lacks
#     decisions.project.has_subfolders) → trivial INFO pass.
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture must pass (no has_subfolders)"
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
assert_eq "$SEVERITY_CLEAN" "INFO" "clean-fixture severity must be INFO (nothing to verify)"

# (2) root-only-claude-md fixture: has_subfolders=true, root CLAUDE.md present,
#     zero subfolder CLAUDE.mds → WARNING fail.
RESULT_BAD=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/root-only-claude-md")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "root-only fixture must FAIL (no subfolder CLAUDE.md)"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "WARNING" "root-only failure severity must be WARNING"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "subfolder" "detail must mention subfolder"
assert_contains "$DETAIL_BAD" "CLAUDE.md" "detail must mention CLAUDE.md"

# (3) Healthy hierarchy: root CLAUDE.md + at least one subfolder CLAUDE.md +
#     state has has_subfolders=true → WARNING pass.
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/src" "$HEALTHY_TMP/docs"
printf '# root\n' > "$HEALTHY_TMP/CLAUDE.md"
printf '# src\n'  > "$HEALTHY_TMP/src/CLAUDE.md"
printf '{"decisions":{"project":{"has_subfolders":true}}}\n' \
  > "$HEALTHY_TMP/docs/_architect_state.json"
RESULT_HEALTHY=$(bash "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
assert_eq "$PASSED_HEALTHY" "true" "healthy hierarchy (root + subfolder CLAUDE.mds) must pass"
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
assert_eq "$SEVERITY_HEALTHY" "WARNING" "healthy-hierarchy severity must be WARNING (check ran)"
rm -rf "$HEALTHY_TMP"

# (4) has_subfolders=false: monolithic project, only root CLAUDE.md → INFO pass.
MONO_TMP=$(mktemp -d)
mkdir -p "$MONO_TMP/docs"
printf '# root only\n' > "$MONO_TMP/CLAUDE.md"
printf '{"decisions":{"project":{"has_subfolders":false}}}\n' \
  > "$MONO_TMP/docs/_architect_state.json"
RESULT_MONO=$(bash "$CHECK" "$MONO_TMP")
PASSED_MONO=$(echo "$RESULT_MONO" | jq -r .passed)
assert_eq "$PASSED_MONO" "true" "has_subfolders=false fixture must pass (no hierarchy required)"
SEVERITY_MONO=$(echo "$RESULT_MONO" | jq -r .severity)
assert_eq "$SEVERITY_MONO" "INFO" "has_subfolders=false severity must be INFO"
rm -rf "$MONO_TMP"

# (5) No state.json → INFO pass (deferred to check_05).
NOSTATE_TMP=$(mktemp -d)
printf '# orphan\n' > "$NOSTATE_TMP/CLAUDE.md"
RESULT_NOSTATE=$(bash "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
assert_eq "$PASSED_NOSTATE" "true" "no-state fixture must pass (deferred to json_valid)"
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
assert_eq "$SEVERITY_NOSTATE" "INFO" "no-state severity must be INFO"
rm -rf "$NOSTATE_TMP"

# (6) has_subfolders=true but no root CLAUDE.md → INFO pass (B06 is not the
#     gate that demands a root CLAUDE.md; that's a future check / Phase-7 job).
NOROOT_TMP=$(mktemp -d)
mkdir -p "$NOROOT_TMP/src" "$NOROOT_TMP/docs"
printf '// src only\n' > "$NOROOT_TMP/src/lib.rs"
printf '{"decisions":{"project":{"has_subfolders":true}}}\n' \
  > "$NOROOT_TMP/docs/_architect_state.json"
RESULT_NOROOT=$(bash "$CHECK" "$NOROOT_TMP")
PASSED_NOROOT=$(echo "$RESULT_NOROOT" | jq -r .passed)
assert_eq "$PASSED_NOROOT" "true" "no-root-CLAUDE.md fixture must pass (not B06's job)"
SEVERITY_NOROOT=$(echo "$RESULT_NOROOT" | jq -r .severity)
assert_eq "$SEVERITY_NOROOT" "INFO" "no-root-CLAUDE.md severity must be INFO"
rm -rf "$NOROOT_TMP"

# (7) JSON-validity loop: every emitted finding must be valid JSON.
for r in "$RESULT_CLEAN" "$RESULT_BAD" "$RESULT_HEALTHY" "$RESULT_MONO" \
         "$RESULT_NOSTATE" "$RESULT_NOROOT"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
