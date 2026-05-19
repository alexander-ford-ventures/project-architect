#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Check 11 (B11): state.schema_version must equal "2.0" AND must NOT match
# state.plugin_version. Catches bug #1 from the md2pdf live test where
# schema_version was incorrectly initialized to the plugin's release version
# (e.g. "2.1.5"), conflating two separate concepts.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#   $2 = STATE_PATH   (path to state.json; defaults to PROJECT_ROOT/docs/_architect_state.json)
#
# Truth-table:
#   - state.json missing or unparseable                          → INFO    pass (deferred to json_valid)
#   - schema_version absent                                      → WARNING fail "state.schema_version is missing"
#   - schema_version != "2.0"                                    → WARNING fail "schema_version is 'X', expected '2.0'"
#   - schema_version == plugin_version (both non-empty)          → WARNING fail "schema_version and plugin_version both equal 'X' (bug #1 — they must be distinct)"
#   - schema_version == "2.0" AND distinct from plugin_version   → WARNING pass "schema_version=2.0 (separate from plugin_version=<v>)"
#
# Severity rationale:
#   - WARNING (not BLOCKER): a mismatched schema_version does not in itself
#     corrupt state — but it confuses every downstream agent that branches on
#     schema_version, and propagates the bug-#1 confusion. WARNING surfaces it
#     loudly without halting Phase 5 transition.
#   - INFO when state.json is unreadable: a separate BLOCKER (check_05) already
#     fires on that path. Duplicating it here would inflate the failure count
#     without adding signal.
#
# Known limitations:
#   - Hard-codes "2.0" as the expected schema version. Bumping the schema
#     forces a code change here (intentional: schema version bumps are
#     coordinated events that should touch every consumer).
#   - Does NOT validate that plugin_version is well-formed semver; that is the
#     job of a future plugin-manifest check (B-future).
#   - auto_fixable=true: setting state.schema_version="2.0" is a mechanical
#     edit the orchestrator can apply without judgement (the value is fixed).

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"

if [[ ! -f "$STATE_PATH" ]] || ! require_valid_json "$STATE_PATH"; then
  emit_pass "B11" "INFO" "schema_version" \
    "state.json missing or unparseable (deferred to json_valid)"
  exit 0
fi

SCHEMA_VERSION=$(jq -r '.schema_version // ""' "$STATE_PATH" 2>/dev/null)
PLUGIN_VERSION=$(jq -r '.plugin_version // ""' "$STATE_PATH" 2>/dev/null)

PROBLEMS=()

if [[ -z "$SCHEMA_VERSION" ]]; then
  PROBLEMS+=("state.schema_version is missing")
elif [[ "$SCHEMA_VERSION" != "2.0" ]]; then
  PROBLEMS+=("state.schema_version is '$SCHEMA_VERSION', expected '2.0'")
fi

# Bug #1: schema_version (state-schema version) was being initialized to the
# plugin's release version. They must be distinct values, even if some future
# coincidence makes plugin_version=="2.0" — flag it so the author fixes
# whichever side is mis-set.
if [[ -n "$SCHEMA_VERSION" && -n "$PLUGIN_VERSION" && "$SCHEMA_VERSION" == "$PLUGIN_VERSION" ]]; then
  PROBLEMS+=("schema_version and plugin_version both equal '$SCHEMA_VERSION' (bug #1 — they must be distinct)")
fi

if [[ ${#PROBLEMS[@]} -eq 0 ]]; then
  if [[ -n "$PLUGIN_VERSION" ]]; then
    emit_pass "B11" "WARNING" "schema_version" \
      "schema_version=2.0 (separate from plugin_version=$PLUGIN_VERSION)"
  else
    emit_pass "B11" "WARNING" "schema_version" \
      "schema_version=2.0 (plugin_version absent — not checked)"
  fi
  exit 0
fi

# Join problems with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${PROBLEMS[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

# UTF-8-safe character truncation via the _lib.sh helper.
DETAIL_TRUNC=$(truncate_json_string "$JOINED" 300 | jq -r .)
emit_fail "B11" "WARNING" "schema_version" "$DETAIL_TRUNC" \
  "set state.schema_version='2.0' (the state-schema version, not plugin version) — distinct from state.plugin_version" \
  true
