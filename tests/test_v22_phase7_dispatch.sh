#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
CONTENT=$(cat "$SKILL")

# Phase 7 exists with menu options
assert_contains "$CONTENT" 'Phase 7: Tooling Execution' 'must have Phase 7 heading'
assert_contains "$CONTENT" 'CLAUDE_MD_PLAN' 'Phase 7 must reference CLAUDE_MD_PLAN'
assert_contains "$CONTENT" 'CLAUDE_TOOLING_PLAN' 'Phase 7 must reference CLAUDE_TOOLING_PLAN'
assert_contains "$CONTENT" 'SCAFFOLD_PLAN' 'Phase 7 must reference SCAFFOLD_PLAN handoff'

# Each option dispatches the right agent
assert_contains "$CONTENT" 'claude-md-author' 'option a must dispatch claude-md-author'
assert_contains "$CONTENT" 'claude-tooling-author' 'option b must dispatch claude-tooling-author'
assert_contains "$CONTENT" 'superpowers:writing-plans' 'option c must hand off to superpowers'

# Phase 7 reads plan docs as input
assert_contains "$CONTENT" 'plan_path' 'Phase 7 must pass plan_path to agents'

# Re-dispatch auditor after each execution
assert_contains "$CONTENT" 'quality-gate-auditor' 'Phase 7 must re-validate via auditor'

# Phase 8 transition
assert_contains "$CONTENT" 'phase_8' 'Phase 7 must transition to phase_8'

test_summary
