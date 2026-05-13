#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
#
# Shared helpers for quality-gate-auditor check scripts. Source from each
# checks/check_NN_*.sh as: source "$(dirname "$0")/_lib.sh"
#
# Provides: emit_pass, emit_fail, truncate_json_string, relpath, is_external_url,
#           read_md_corpus, require_valid_json

# emit_pass <id> <severity> <check_name> <detail_text>
# Emits a passing JSON finding to stdout. <detail_text> is JSON-escaped.
emit_pass() {
  local id="$1" severity="$2" check="$3" detail="$4"
  local detail_json
  detail_json=$(printf '%s' "$detail" | jq -Rs .)
  printf '{"id":"%s","severity":"%s","check":"%s","passed":true,"detail":%s,"remediation":"","auto_fixable":false}\n' \
    "$id" "$severity" "$check" "$detail_json"
}

# emit_fail <id> <severity> <check_name> <detail_text> <remediation_text> [auto_fixable]
# Emits a failing JSON finding to stdout. <detail_text> and <remediation_text> are JSON-escaped.
# auto_fixable defaults to false; pass "true" to flag a finding the orchestrator can auto-fix.
emit_fail() {
  local id="$1" severity="$2" check="$3" detail="$4" remediation="$5"
  local auto_fixable="${6:-false}"
  local detail_json rem_json
  detail_json=$(printf '%s' "$detail" | jq -Rs .)
  rem_json=$(printf '%s' "$remediation" | jq -Rs .)
  printf '{"id":"%s","severity":"%s","check":"%s","passed":false,"detail":%s,"remediation":%s,"auto_fixable":%s}\n' \
    "$id" "$severity" "$check" "$detail_json" "$rem_json" "$auto_fixable"
}

# truncate_json_string <text> <max_chars>
# Returns a JSON-encoded string truncated to at most <max_chars> characters.
# Uses jq for UTF-8-safe character-level (not byte-level) slicing.
truncate_json_string() {
  local text="$1" max_chars="$2"
  printf '%s' "$text" | jq -Rs --argjson n "$max_chars" '.[0:$n]'
}

# relpath <path>
# Strip $PROJECT_ROOT/ prefix from <path>. PROJECT_ROOT must be set in caller's scope.
# Pattern is quoted to handle paths with shell-glob metacharacters ([], *, ?).
relpath() {
  local p="$1"
  printf '%s' "${p##"$PROJECT_ROOT"/}"
}

# is_external_url <path>
# Returns 0 (true) if <path> is an external URL or scheme-prefixed reference
# the checker should NOT try to resolve on the local filesystem.
# Covers: http://, https://, ftp://, mailto:, ssh://, git://, file://,
# protocol-relative //host/path, and any scheme://... form.
is_external_url() {
  local p="$1"
  [[ "$p" == *://* ]] && return 0
  [[ "$p" == //* ]] && return 0
  [[ "$p" == mailto:* ]] && return 0
  [[ "$p" == tel:* ]] && return 0
  return 1
}

# read_md_corpus <docs_dir>
# Concatenate every .md file under <docs_dir> into stdout, stripping NUL bytes
# (which trigger bash command-substitution warnings on binary content).
# Quiet on a missing directory.
read_md_corpus() {
  local docs_dir="$1"
  [[ -d "$docs_dir" ]] || return 0
  find "$docs_dir" -name "*.md" -type f -exec cat {} + 2>/dev/null | tr -d '\0'
}

# require_valid_json <path>
# Returns 0 (success) if the file exists AND is valid JSON. Returns 1 otherwise.
# Callers should defer to check_05_json_valid for the BLOCKER verdict; this
# helper just lets each check decline to make a positive claim when state is
# unreadable.
require_valid_json() {
  local path="$1"
  [[ -f "$path" ]] || return 1
  jq -e . "$path" >/dev/null 2>&1
}
