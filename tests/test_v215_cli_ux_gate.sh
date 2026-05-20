#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

QF="$REPO_ROOT/skills/project-architect/references/questioning-flow.md"
SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"

QF_CONTENT=$(cat "$QF")
SKILL_CONTENT=$(cat "$SKILL")

# questioning-flow.md must contain the universal gate question
assert_contains "$QF_CONTENT" 'CLI experience model' 'questioning-flow.md must define the CLI experience model gate question'
assert_contains "$QF_CONTENT" 'one-shot' 'gate question must include one-shot option'
assert_contains "$QF_CONTENT" 'Interactive prompts' 'gate question must include interactive prompts option'
assert_contains "$QF_CONTENT" 'Full TUI' 'gate question must include full TUI option'
assert_contains "$QF_CONTENT" 'Hybrid' 'gate question must include hybrid option'

# SKILL.md Phase 1 must route through this question for CLI sub_types
assert_contains "$SKILL_CONTENT" 'cli_experience_model' 'SKILL.md must reference cli_experience_model decision key'

test_summary
