#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

# Runs all 16 quality-gate-auditor checks and aggregates results into a single JSON.
# Usage: run_all.sh <project_root> <state_path> [catalog_path] [adr_dir]

set -uo pipefail

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"
CATALOG_PATH="${3:-${CLAUDE_PLUGIN_ROOT:-.}/skills/project-architect/references/templates}"
ADR_DIR="${4:-${PROJECT_ROOT}/docs/decisions}"

CHECKS_DIR="$(dirname "$0")/checks"

declare -a FINDINGS
BLOCKER=0
WARNING=0
INFO=0

mapfile -t CHECK_SCRIPTS < <(find "$CHECKS_DIR" -maxdepth 1 -type f \( -name 'check_*.sh' -o -name 'check_*.py' \) 2>/dev/null | sort)

for check_script in "${CHECK_SCRIPTS[@]}"; do
  [[ -f "$check_script" ]] || continue
  case "$check_script" in
    *.sh) RAW=$(bash "$check_script" "$PROJECT_ROOT" "$STATE_PATH" "$CATALOG_PATH" "$ADR_DIR" 2>&1) ;;
    *.py) RAW=$(python3 "$check_script" "$PROJECT_ROOT" "$STATE_PATH" "$CATALOG_PATH" "$ADR_DIR" 2>&1) ;;
  esac

  if echo "$RAW" | jq -e . >/dev/null 2>&1; then
    RESULT="$RAW"
  else
    # Check script crashed or returned non-JSON. Synthesize a BLOCKER finding so it
    # surfaces in the audit AND the aggregate stays valid JSON.
    ESCAPED=$(printf '%s' "$RAW" | jq -Rs .)
    CHECK_NAME=$(basename "$check_script")
    RESULT="{\"id\":\"INTERNAL_ERROR\",\"severity\":\"BLOCKER\",\"check\":\"${CHECK_NAME}\",\"passed\":false,\"detail\":\"check script did not return valid JSON\",\"remediation\":${ESCAPED},\"auto_fixable\":false}"
  fi

  PASSED=$(echo "$RESULT" | jq -r .passed)
  SEVERITY=$(echo "$RESULT" | jq -r .severity)

  if [[ "$PASSED" == "false" ]]; then
    case "$SEVERITY" in
      BLOCKER) BLOCKER=$((BLOCKER + 1)) ;;
      WARNING) WARNING=$((WARNING + 1)) ;;
      INFO) INFO=$((INFO + 1)) ;;
    esac
  fi

  FINDINGS+=("$RESULT")
done

# Build aggregate JSON
echo '{'
echo "  \"summary\": { \"blocker\": $BLOCKER, \"warning\": $WARNING, \"info\": $INFO },"
echo '  "findings": ['
for i in "${!FINDINGS[@]}"; do
  echo "    ${FINDINGS[$i]}$([ "$i" -lt $((${#FINDINGS[@]} - 1)) ] && echo ',' || echo '')"
done
echo '  ],'
echo '  "phase_5_seed_items": []'
echo '}'
