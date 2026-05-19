#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Check 5 (B05): every .json file under <project_root> is valid JSON (jq -e .).
# Excludes test fixtures and standard build/vendor/cache dirs via find_project_files.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan)
#
# Truth-table:
#   - jq not installed                → INFO    passed=true   detail="jq not installed; check skipped"
#   - no .json files                  → BLOCKER passed=true   detail="no JSON files to check"
#   - all .json files valid           → BLOCKER passed=true   detail="all N JSON file(s) valid"
#   - one or more .json invalid       → BLOCKER passed=false  detail="<count> invalid JSON file(s): <paths>"
#
# Severity rationale:
#   - BLOCKER for genuine failures: invalid JSON in settings/state/plugin manifests
#     breaks downstream agents and Claude Code itself. Must block Phase 5 transition.
#   - INFO for the not-installed graceful-degradation path so projects whose CI
#     environment lacks the binary aren't blocked by the auditor.
#
# Known limitations:
#   - Skips ALL .json under tests/fixtures/ — these are presumed-test-input (the
#     auditor must not flag its own fixtures as bugs).
#   - Skips standard build/vendor dirs (centralized in _lib.sh::find_project_files)
#     so external-project audits don't flag third-party manifests the project
#     doesn't own.
#   - Does NOT inspect JSONC (//-commented JSON) or JSON5; `jq empty` rejects both.
#     If the project ever adopts those formats, add a separate check or relax this.
#   - auto_fixable=false — JSON syntax errors require human judgment about intent.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"

if ! command -v jq >/dev/null 2>&1; then
  emit_pass "B05" "INFO" "json_valid" "jq not installed; check skipped"
  exit 0
fi

# Find every .json file under PROJECT_ROOT via the shared helper.
JSON_FILES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && JSON_FILES+=("$f")
done < <(find_project_files "$PROJECT_ROOT" -name "*.json")

if [[ ${#JSON_FILES[@]} -eq 0 ]]; then
  emit_pass "B05" "BLOCKER" "json_valid" "no JSON files to check"
  exit 0
fi

# Validate each .json file with `jq -e . >/dev/null` (cheap parse-only check).
# NOTE: do NOT use `jq empty` here — it exits 0 on empty/whitespace-only input,
# silently letting a 0-byte state.json sneak past the BLOCKER. `jq -e .` requires
# at least one value and fails on empty input, which is the exact failure class
# this check exists to catch.
FAILURES=()
for f in "${JSON_FILES[@]}"; do
  if ! jq -e . "$f" >/dev/null 2>&1; then
    FAILURES+=("$(relpath "$f")")
  fi
done

if [[ ${#FAILURES[@]} -eq 0 ]]; then
  emit_pass "B05" "BLOCKER" "json_valid" "all ${#JSON_FILES[@]} JSON file(s) valid"
  exit 0
fi

# Join failures with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${FAILURES[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#FAILURES[@]} invalid JSON file(s): ${JOINED}"
# UTF-8-safe character truncation via the _lib.sh helper.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B05" "BLOCKER" "json_valid" "$DETAIL_TRUNC" "run 'jq -e . <file>' on each invalid file and fix the syntax error" false
