#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Check 2 (B02): every ADR's affected_docs entry is either generated OR explicitly deferred.
# Catches bug #5 (live-test regression: ADR-promised docs silently dropped).
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory; unused for this check but kept for interface symmetry)
#   $2 = STATE_PATH (path to docs/_architect_state.json); defaults to $PROJECT_ROOT/docs/_architect_state.json
#
# Truth-table:
#   no state.json                                              → PASS (INFO, nothing to verify)
#   state.json has no adrs_filed (or empty)                    → PASS (BLOCKER severity, trivially satisfied)
#   every ADR's affected_docs is in documents_generated OR
#     in deferred_docs                                          → PASS
#   any ADR-promised doc is missing AND not deferred           → FAIL (BLOCKER, auto_fixable=true)
#
# Known limitations (documented for downstream consumers):
#   - Membership is by basename only. ADR entries like "docs/PROJECT_OVERVIEW.md" and
#     "PROJECT_OVERVIEW.md" both compare against the basename "PROJECT_OVERVIEW.md".
#     This intentionally ignores path-prefix discrepancies between ADR YAML and state.json.
#   - documents_generated[].name is taken verbatim and ".md" is appended to form the basename.
#     If an entry already ends with ".md", the suffix is normalised below to avoid "X.md.md".

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"

if [[ ! -f "$STATE_PATH" ]]; then
  emit_pass "B02" "INFO" "adr_affected_docs" "no state.json"
  exit 0
fi

# Defer the JSON-validity verdict to check_05 (json_valid, BLOCKER). If state
# is unparseable we must NOT emit a positive claim ("all affected_docs generated
# or deferred") that downstream readers would trust.
if ! require_valid_json "$STATE_PATH"; then
  emit_pass "B02" "INFO" "adr_affected_docs" "state.json unparseable (deferred to json_valid check)"
  exit 0
fi

# Build the sets of generated and deferred docs (basenames).
# Normalise "name" entries so trailing ".md" is preserved exactly once.
GENERATED=$(jq -r '
  .documents_generated[]?
  | (.name // "")
  | select(length > 0)
  | if endswith(".md") then . else . + ".md" end
' "$STATE_PATH" 2>/dev/null | sort -u)

DEFERRED=$(jq -r '.deferred_docs[]?' "$STATE_PATH" 2>/dev/null | sort -u)

# For each ADR's affected_docs, check membership against generated ∪ deferred.
PROBLEMS=()
while IFS=$'\t' read -r adr_id doc; do
  [[ -z "$doc" ]] && continue
  # Strip path prefix like "docs/" if present — membership is by basename.
  doc_basename="${doc##*/}"
  if printf '%s\n' "$GENERATED" | grep -Fxq "$doc_basename"; then
    : # generated — ok
  elif printf '%s\n' "$DEFERRED" | grep -Fxq "$doc_basename"; then
    : # deferred — ok
  else
    PROBLEMS+=("ADR ${adr_id} promised ${doc_basename} but not generated/deferred")
  fi
done < <(jq -r '.adrs_filed[]? | .id as $id | .affected_docs[]? | "\($id)\t\(.)"' "$STATE_PATH" 2>/dev/null)

if [[ ${#PROBLEMS[@]} -eq 0 ]]; then
  emit_pass "B02" "BLOCKER" "adr_affected_docs" "all ADR affected_docs are generated or deferred"
  exit 0
fi

# Join with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${PROBLEMS[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#PROBLEMS[@]} ADR-promised doc(s) missing: ${JOINED}"
# UTF-8-safe character truncation via jq: encode → slice as chars → decode.
# jq strings are UTF-8 and `.[start:end]` is character-indexed, so we never
# slice mid-multibyte-codepoint and produce invalid JSON in emit_fail.
DETAIL_TRUNC=$(printf '%s' "$DETAIL" | jq -Rs --argjson n 300 '.[0:$n]' | jq -r .)
# auto_fixable=true: orchestrator can either generate the missing doc or add it to state.deferred_docs.
emit_fail "B02" "BLOCKER" "adr_affected_docs" "$DETAIL_TRUNC" "generate the missing docs OR add them to state.deferred_docs with rationale" true
