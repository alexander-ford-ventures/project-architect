#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

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

for check_script in "${CHECKS_DIR}"/check_*.{sh,py}; do
  [[ -f "$check_script" ]] || continue
  case "$check_script" in
    *.sh) RESULT=$(bash "$check_script" "$PROJECT_ROOT" "$STATE_PATH" "$CATALOG_PATH" "$ADR_DIR" 2>&1) ;;
    *.py) RESULT=$(python3 "$check_script" "$PROJECT_ROOT" "$STATE_PATH" "$CATALOG_PATH" "$ADR_DIR" 2>&1) ;;
  esac

  PASSED=$(echo "$RESULT" | jq -r .passed 2>/dev/null || echo "true")
  SEVERITY=$(echo "$RESULT" | jq -r .severity 2>/dev/null || echo "INFO")

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
  echo "    ${FINDINGS[$i]}$([ $i -lt $((${#FINDINGS[@]} - 1)) ] && echo ',' || echo '')"
done
echo '  ]'
echo '}'
