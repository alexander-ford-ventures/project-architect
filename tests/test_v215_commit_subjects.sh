#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

MD_AUTHOR="$REPO_ROOT/agents/claude-md-author.md"
TOOL_AUTHOR="$REPO_ROOT/agents/claude-tooling-author.md"

MD_CONTENT=$(cat "$MD_AUTHOR")
TOOL_CONTENT=$(cat "$TOOL_AUTHOR")

# Both agents must mention the architect(phase-N) commit convention
assert_contains "$MD_CONTENT" 'architect(phase-' 'claude-md-author must use architect(phase-N) commit subject'
assert_contains "$TOOL_CONTENT" 'architect(phase-' 'claude-tooling-author must use architect(phase-N) commit subject'

# Both must explicitly forbid the chore: prefix for their own work
assert_contains "$MD_CONTENT" 'NOT use chore:' 'claude-md-author must explicitly forbid chore: prefix'
assert_contains "$TOOL_CONTENT" 'NOT use chore:' 'claude-tooling-author must explicitly forbid chore: prefix'

test_summary
