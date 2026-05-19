#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Test for v2.2 task 43: claude-tooling-author consumes CLAUDE_TOOLING_PLAN.md
# and writes the 3 router slash commands from SLASH_* templates (sketch D).

source "$(dirname "$0")/lib/test_helpers.sh"

AGENT="$REPO_ROOT/agents/claude-tooling-author.md"
CONTENT=$(cat "$AGENT")

# plan_path input listed
assert_contains "$CONTENT" 'plan_path' 'must list plan_path as input'
assert_contains "$CONTENT" 'CLAUDE_TOOLING_PLAN.md' 'must reference CLAUDE_TOOLING_PLAN.md'

# Workflow is plan-driven
assert_contains "$CONTENT" 'plan-driven' 'workflow must mention plan-driven'

# Slash command generation
assert_contains "$CONTENT" 'SLASH_SCAFFOLD' 'must generate from SLASH_SCAFFOLD template'
assert_contains "$CONTENT" 'SLASH_IMPLEMENT' 'must generate from SLASH_IMPLEMENT template'
assert_contains "$CONTENT" 'SLASH_ITERATE_DESIGN' 'must generate from SLASH_ITERATE_DESIGN template'
assert_contains "$CONTENT" '.claude/commands/scaffold.md' 'must write scaffold.md to .claude/commands/'
assert_contains "$CONTENT" '.claude/commands/implement.md' 'must write implement.md'
assert_contains "$CONTENT" '.claude/commands/iterate-design.md' 'must write iterate-design.md'

# Commit subject
assert_contains "$CONTENT" 'architect(phase-7): execute CLAUDE_TOOLING_PLAN' 'must use architect(phase-7) commit subject'

test_summary
