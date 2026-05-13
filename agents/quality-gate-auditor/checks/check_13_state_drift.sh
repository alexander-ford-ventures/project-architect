#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 13 (B13): state.last_updated_at must be no more than 60s older than
# git HEAD's commit timestamp. Catches drift where someone committed code but
# forgot to refresh state.json — a class of bug where state and history fall
# out of sync and downstream tooling (resume, audit log, lock-stale detection)
# silently reads stale answers.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#   $2 = STATE_PATH   (path to state.json; defaults to PROJECT_ROOT/docs/_architect_state.json)
#
# Truth-table:
#   - PROJECT_ROOT is NOT a git repository                       → INFO    pass "not a git repository"
#   - state.json missing or unparseable                          → INFO    pass (deferred to json_valid)
#   - state.last_updated_at absent                               → INFO    pass "early phase or pre-update"
#   - state.last_updated_at unparseable as ISO8601               → INFO    pass (deferred to iso8601_timestamps)
#   - HEAD commit time absent (no commits in repo)               → INFO    pass "no commits"
#   - HEAD time - state time ≤ 60s (within grace)                → WARNING pass "within 60s of HEAD commit"
#   - HEAD time - state time > 60s                               → WARNING fail "state.last_updated_at lags HEAD commit by Ns"
#
# Severity rationale:
#   - WARNING (not BLOCKER): drift doesn't corrupt anything immediately, but
#     it confuses every downstream consumer that branches on freshness. The
#     fix is mechanical (rewrite last_updated_at to current time), so the
#     finding is auto_fixable.
#   - INFO when the check can't make a positive claim: non-git dirs,
#     unreadable state, missing timestamps, unparseable timestamps. Each
#     has a dedicated upstream check (json_valid, iso8601_timestamps); we
#     defer rather than duplicate signal.
#
# Why 60-second grace:
#   The orchestrator routinely commits and updates state in immediate sequence
#   (commit → write state.last_updated_at → commit state). Between those two
#   commits a tiny lag is normal. 60s is generous enough to absorb slow disks
#   and tight enough to catch real "forgot to update state" bugs.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"

# Not a git repo? Defer.
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  emit_pass "B13" "INFO" "state_drift" "not a git repository"
  exit 0
fi

if [[ ! -f "$STATE_PATH" ]] || ! require_valid_json "$STATE_PATH"; then
  emit_pass "B13" "INFO" "state_drift" \
    "state.json missing or unparseable (deferred to json_valid)"
  exit 0
fi

LAST_UPDATED=$(jq -r '.last_updated_at // ""' "$STATE_PATH" 2>/dev/null)
if [[ -z "$LAST_UPDATED" || "$LAST_UPDATED" == "null" ]]; then
  emit_pass "B13" "INFO" "state_drift" \
    "state.last_updated_at not set (early phase or pre-update)"
  exit 0
fi

# Parse state's last_updated_at to unix epoch via Python (portable across
# macOS/BSD/GNU date, accepts both 'Z' and '+00:00' offsets). The state value
# is passed through an environment variable to avoid shell-injection issues
# with funky characters.
STATE_EPOCH=$(STATE_TS="$LAST_UPDATED" python3 -c "
import os, sys
from datetime import datetime
v = os.environ['STATE_TS']
v = v.replace('Z', '+00:00') if v.endswith('Z') else v
try:
    print(int(datetime.fromisoformat(v).timestamp()))
except Exception:
    sys.exit(1)
" 2>/dev/null)
if [[ -z "$STATE_EPOCH" ]]; then
  emit_pass "B13" "INFO" "state_drift" \
    "state.last_updated_at unparseable (deferred to iso8601_timestamps)"
  exit 0
fi

# HEAD commit unix epoch (committer time). Empty if the repo has no commits.
HEAD_EPOCH=$(git -C "$PROJECT_ROOT" log -1 --format=%ct 2>/dev/null)
if [[ -z "$HEAD_EPOCH" ]]; then
  emit_pass "B13" "INFO" "state_drift" "no commits in repo"
  exit 0
fi

DELTA=$((HEAD_EPOCH - STATE_EPOCH))

# state ahead of (or equal to) HEAD, or within the 60s grace window.
if [[ $DELTA -le 60 ]]; then
  emit_pass "B13" "WARNING" "state_drift" \
    "state.last_updated_at within 60s of HEAD commit (delta=${DELTA}s)"
  exit 0
fi

DETAIL="state.last_updated_at lags HEAD commit by ${DELTA}s; commit code without state.json refresh detected"
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B13" "WARNING" "state_drift" "$DETAIL_TRUNC" \
  "update state.last_updated_at after commits (set to current time via 'date -u +%Y-%m-%dT%H:%M:%SZ')" \
  true
