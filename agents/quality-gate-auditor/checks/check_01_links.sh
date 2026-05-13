#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 1: every markdown link in docs/*.md points to an existing file.

set -uo pipefail

PROJECT_ROOT="${1:-.}"
DOCS_DIR="${PROJECT_ROOT}/docs"

BROKEN=()

if [[ ! -d "$DOCS_DIR" ]]; then
  echo '{"id":"B01","severity":"INFO","check":"link_integrity","passed":true,"detail":"no docs/ directory","remediation":"","auto_fixable":false}'
  exit 0
fi

while IFS= read -r mdfile; do
  # Extract link targets like [text](path.md) or [text](path.md#anchor)
  while IFS= read -r target; do
    # Strip anchor if present
    path_only="${target%%#*}"
    # Skip empty (pure anchor) and absolute URLs
    [[ -z "$path_only" ]] && continue
    [[ "$path_only" == http*://* ]] && continue
    [[ "$path_only" == mailto:* ]] && continue
    # Resolve relative to mdfile's directory
    base_dir=$(dirname "$mdfile")
    resolved="$base_dir/$path_only"
    if [[ ! -e "$resolved" ]]; then
      BROKEN+=("${mdfile##$PROJECT_ROOT/} → ${target}")
    fi
  done < <(grep -oE '\]\([^)]+\)' "$mdfile" | sed -E 's/\]\(([^)]+)\)/\1/')
done < <(find "$DOCS_DIR" -name "*.md" -type f)

if [[ ${#BROKEN[@]} -eq 0 ]]; then
  echo '{"id":"B01","severity":"BLOCKER","check":"link_integrity","passed":true,"detail":"all links resolve","remediation":"","auto_fixable":false}'
else
  # Join BROKEN[*] with ", " separator. Using printf + sed avoids mutating IFS
  # globally (which semgrep flags as risky) and is safe for arbitrary content
  # since the jq -Rs . pass below re-escapes everything for JSON.
  JOINED=$(printf '%s, ' "${BROKEN[@]}")
  JOINED="${JOINED%, }"  # strip trailing ", "
  TRUNCATED=$(printf '%s' "$JOINED" | head -c 200)
  DETAIL="${#BROKEN[@]} broken link(s): ${TRUNCATED}"
  printf '{"id":"B01","severity":"BLOCKER","check":"link_integrity","passed":false,"detail":%s,"remediation":"fix each broken link or remove it","auto_fixable":false}\n' "$(jq -Rs . <<<"$DETAIL")"
fi
