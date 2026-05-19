#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

AGENT="$REPO_ROOT/agents/decision-revisor.md"
CONTENT=$(cat "$AGENT")

# Must have explicit scope discipline section
assert_contains "$CONTENT" 'Scope discipline' 'decision-revisor must have a Scope discipline section'

# Must explicitly forbid auditing unrelated docs
assert_contains "$CONTENT" 'Do NOT audit' 'must explicitly forbid auditing out-of-scope docs'

# Must instruct to surface out-of-scope findings as Phase 5 menu items
assert_contains "$CONTENT" 'Phase 5' 'must route out-of-scope findings to Phase 5 menu'

# Must mention the affected_docs limit
assert_contains "$CONTENT" 'affected_docs' 'must reference affected_docs as the scope boundary'

test_summary
