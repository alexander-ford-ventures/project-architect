#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Test for v2.2 task 42: claude-md-author consumes CLAUDE_MD_PLAN.md (sketch D).

source "$(dirname "$0")/lib/test_helpers.sh"

AGENT="$REPO_ROOT/agents/claude-md-author.md"
CONTENT=$(cat "$AGENT")

# plan_path input listed
assert_contains "$CONTENT" 'plan_path' 'must list plan_path as an input'
assert_contains "$CONTENT" 'CLAUDE_MD_PLAN.md' 'must reference CLAUDE_MD_PLAN.md as the plan source'

# Workflow reads plan, substitutes placeholders
assert_contains "$CONTENT" 'Workflow' 'must have Workflow section'
assert_contains "$CONTENT" 'plan-driven' 'workflow must mention plan-driven'

# Commit with architect(phase-7) subject
assert_contains "$CONTENT" 'architect(phase-7): execute CLAUDE_MD_PLAN' 'must use architect(phase-7) commit subject'

# Per-subfolder support
assert_contains "$CONTENT" 'Per-subfolder' 'must handle per-subfolder CLAUDE.mds from plan'

test_summary
