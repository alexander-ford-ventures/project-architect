#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 3 (B03): every state.decisions leaf (non-metadata) is mentioned by key OR value in docs/.
# Catches decisions that exist in state but are silently undocumented.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory containing docs/)
#   $2 = STATE_PATH (path to docs/_architect_state.json); defaults to $PROJECT_ROOT/docs/_architect_state.json
#
# Truth-table:
#   no state.json                            → PASS (INFO, nothing to verify)
#   no docs/ directory                       → PASS (INFO, nothing to search)
#   state.decisions absent or all metadata   → PASS (WARNING, trivially satisfied)
#   every non-metadata leaf is mentioned     → PASS (WARNING)
#     in docs by either its key or value
#   any non-metadata leaf is undocumented    → FAIL (WARNING, auto_fixable=false)
#
# Known limitations:
#   - Case-sensitive substring search (decision value "Rust" won't match doc text "rust").
#     Spec doesn't require case-insensitivity; can be refined per future feedback.
#   - Metadata-only leaves are intentionally skipped: adr, alternatives_considered, status,
#     date, confidence, decision_keys. These are ADR bookkeeping, not user-facing decisions.
#   - Array leaves are not enumerated (they are typically alternatives_considered/decision_keys
#     metadata fields and are skipped to avoid false positives).

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"
DOCS_DIR="${PROJECT_ROOT}/docs"

if [[ ! -f "$STATE_PATH" ]]; then
  emit_pass "B03" "INFO" "decisions_in_docs" "no state.json"
  exit 0
fi

if [[ ! -d "$DOCS_DIR" ]]; then
  emit_pass "B03" "INFO" "decisions_in_docs" "no docs/ directory"
  exit 0
fi

# Concatenate all doc content into a single search corpus (case-sensitive substring search).
CORPUS=$(find "$DOCS_DIR" -name "*.md" -type f -exec cat {} + 2>/dev/null)

# Walk decision leaves via jq. Output one record per leaf as "<dotted-path>\t<value>".
# The recursive jq filter enumerates non-array/object leaves. Arrays are skipped (typically
# metadata like alternatives_considered).
METADATA_KEYS_RE='^(adr|alternatives_considered|status|date|confidence|decision_keys)$'

UNDOCUMENTED=()
while IFS=$'\t' read -r path value; do
  [[ -z "$path" ]] && continue
  # The last segment of the dotted path is the leaf key
  leaf_key="${path##*.}"
  # Skip metadata bookkeeping
  [[ "$leaf_key" =~ $METADATA_KEYS_RE ]] && continue
  # Skip null/empty values
  [[ "$value" == "null" || -z "$value" ]] && continue
  # Search corpus for either the value OR the leaf key (case-sensitive substring)
  if [[ "$CORPUS" == *"$value"* ]] || [[ "$CORPUS" == *"$leaf_key"* ]]; then
    : # documented
  else
    UNDOCUMENTED+=("${path}=${value}")
  fi
done < <(jq -r '
  def walk_leaves(prefix):
    if type == "object" then
      to_entries[] | .key as $k | .value | walk_leaves(if prefix == "" then $k else "\(prefix).\($k)" end)
    elif type == "array" then
      empty
    else
      "\(prefix)\t\(. // "null")"
    end;
  (.decisions // {}) | walk_leaves("")
' "$STATE_PATH" 2>/dev/null)

if [[ ${#UNDOCUMENTED[@]} -eq 0 ]]; then
  emit_pass "B03" "WARNING" "decisions_in_docs" "all decisions are mentioned in docs"
  exit 0
fi

# Join with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${UNDOCUMENTED[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#UNDOCUMENTED[@]} undocumented decision(s): ${JOINED}"
# Use the truncate_json_string helper from _lib.sh (UTF-8-safe character truncation),
# then pipe through `jq -r .` to recover the raw bash string for emit_fail.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B03" "WARNING" "decisions_in_docs" "$DETAIL_TRUNC" "mention each decision (by key or value) in at least one docs/*.md" false
