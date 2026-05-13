#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 1 (B01): every markdown link target in docs/*.md resolves to an existing file.
#
# Known limitations (documented for downstream consumers):
#   - Filenames containing '(' or ')' are not supported (regex stops at the first ')').
#     Such targets are flagged as broken. Avoid parens in linked filenames.
#   - Inline links inside fenced code blocks (```...```) are scanned as real links.
#     If you intend code-block examples to look like markdown links, expect false positives.
#   - Reference-style links ([text][ref] + [ref]: target) are NOT scanned.
#   - Absolute filesystem paths (starting with /) are SKIPPED (treated as external).

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
DOCS_DIR="${PROJECT_ROOT}/docs"

if [[ ! -d "$DOCS_DIR" ]]; then
  emit_pass "B01" "INFO" "link_integrity" "no docs/ directory"
  exit 0
fi

BROKEN=()

while IFS= read -r mdfile; do
  while IFS= read -r target; do
    # Strip #anchor portion
    path_only="${target%%#*}"
    # Skip pure anchors (e.g., [section](#heading))
    [[ -z "$path_only" ]] && continue
    # Skip external URLs (http/https/ftp/etc.), mailto:, tel:, protocol-relative //...
    is_external_url "$path_only" && continue
    # Skip absolute filesystem paths (link integrity check can't reason about /etc/...)
    [[ "$path_only" == /* ]] && continue
    # Resolve relative to the linking file's directory
    base_dir=$(dirname "$mdfile")
    resolved="${base_dir}/${path_only}"
    if [[ ! -e "$resolved" ]]; then
      BROKEN+=("$(relpath "$mdfile") → ${target}")
    fi
  done < <(grep -oE '\]\([^)]+\)' "$mdfile" | sed -E 's/\]\(([^)]+)\)/\1/')
done < <(find "$DOCS_DIR" -name "*.md" -type f)

if [[ ${#BROKEN[@]} -eq 0 ]]; then
  emit_pass "B01" "BLOCKER" "link_integrity" "all links resolve"
  exit 0
fi

# Join broken entries with ", " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${BROKEN[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}, ${entry}"
  fi
done

DETAIL="${#BROKEN[@]} broken link(s): ${JOINED}"
# UTF-8-safe character truncation via jq: encode → slice as chars → decode.
# jq strings are UTF-8 and `.[start:end]` is character-indexed, so we never
# slice mid-multibyte-codepoint and produce invalid JSON in emit_fail.
DETAIL_TRUNC=$(printf '%s' "$DETAIL" | jq -Rs --argjson n 200 '.[0:$n]' | jq -r .)
emit_fail "B01" "BLOCKER" "link_integrity" "$DETAIL_TRUNC" "fix each broken link or remove it"
