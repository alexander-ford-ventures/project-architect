#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 4 (B04): every .sh file under <project_root> passes shellcheck -s bash -S warning.
# Excludes test fixtures (tests/fixtures/) and common build/vendor dirs (.git, node_modules,
# target, dist, build, .venv, __pycache__).
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan)
#
# Truth-table:
#   - binary not installed             → PASS (INFO,    detail="shellcheck not installed; check skipped")
#   - no .sh files                     → PASS (BLOCKER, detail="no shell scripts to check")
#   - all .sh files clean              → PASS (BLOCKER, detail="all N shell script(s) pass shellcheck")
#   - any .sh fails                    → FAIL (BLOCKER, detail names failing scripts + SC codes)
#
# Severity rationale:
#   - BLOCKER for genuine failures: shellcheck warnings/errors are real defects that
#     should block Phase 5 transition.
#   - INFO for the not-installed graceful-degradation path so projects whose CI
#     environment lacks the binary aren't blocked by the auditor.
#
# Known limitations:
#   - Skips ALL .sh under tests/fixtures/ — these are presumed-test-input (the
#     auditor must not flag its own fixtures as bugs).
#   - Skips standard build/vendor dirs so external-project audits don't flag
#     third-party shell code the project doesn't own.
#   - auto_fixable=false — shellcheck issues require human judgment.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"

if ! command -v shellcheck >/dev/null 2>&1; then
  emit_pass "B04" "INFO" "shellcheck" "shellcheck not installed; check skipped"
  exit 0
fi

# Find every .sh file under PROJECT_ROOT, excluding fixtures and build dirs.
SH_FILES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && SH_FILES+=("$f")
done < <(
  find "$PROJECT_ROOT" -type f -name "*.sh" \
    -not -path "*/tests/fixtures/*" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/target/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/.venv/*" \
    -not -path "*/__pycache__/*" \
    2>/dev/null
)

if [[ ${#SH_FILES[@]} -eq 0 ]]; then
  emit_pass "B04" "BLOCKER" "shellcheck" "no shell scripts to check"
  exit 0
fi

# Run shellcheck against each file; collect failures with first few SC codes.
FAILURES=()
for f in "${SH_FILES[@]}"; do
  if ! OUTPUT=$(shellcheck -s bash -S warning "$f" 2>&1); then
    # Extract distinct SC codes for a compact summary in the detail.
    SUMMARY=$(echo "$OUTPUT" | grep -oE 'SC[0-9]+' | sort -u | head -3 | tr '\n' ',' | sed 's/,$//')
    FAILURES+=("$(relpath "$f") [${SUMMARY:-unknown}]")
  fi
done

if [[ ${#FAILURES[@]} -eq 0 ]]; then
  emit_pass "B04" "BLOCKER" "shellcheck" "all ${#SH_FILES[@]} shell script(s) pass shellcheck"
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

DETAIL="${#FAILURES[@]} failing shell script(s): ${JOINED}"
# Use the truncate_json_string helper from _lib.sh (UTF-8-safe character truncation),
# then pipe through `jq -r .` to recover the raw bash string for emit_fail.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B04" "BLOCKER" "shellcheck" "$DETAIL_TRUNC" "run 'shellcheck -s bash -S warning <file>' and fix each warning" false
