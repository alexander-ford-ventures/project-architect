#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
#
# Test: phase_progress[N].prerequisites_satisfied schema field (v2.2, bug #4 fix)
#
# Asserts:
#   - state-schema.md documents the prerequisites_satisfied field
#   - state-schema.md explains the phase-boundary gate concept
#   - state-schema.md lists phase_4 / phase_5 prerequisites
#   - state-schema.md references pattern-validation research as a phase_4 prereq
#   - SKILL.md Phase 4 entry verifies phase_3.prerequisites_satisfied
#   - SKILL.md Phase 4 entry references bug #4
source "$(dirname "$0")/lib/test_helpers.sh"

SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"
SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"

CONTENT=$(cat "$SCHEMA")
assert_contains "$CONTENT" 'prerequisites_satisfied' 'state-schema.md must document prerequisites_satisfied'
assert_contains "$CONTENT" 'phase-boundary gate' 'must explain phase-boundary gate concept'
assert_contains "$CONTENT" 'phase_4' 'must list phase_4 prerequisites'
assert_contains "$CONTENT" 'phase_5' 'must list phase_5 prerequisites'
assert_contains "$CONTENT" 'pattern-validation' 'must reference pattern-validation research as phase_4 prereq'

SKILL_CONTENT=$(cat "$SKILL")
assert_contains "$SKILL_CONTENT" 'phase_progress.phase_3.prerequisites_satisfied' 'Phase 4 entry must verify Phase 3 prereqs'
assert_contains "$SKILL_CONTENT" 'bug #4' 'Phase 4 entry gate must reference bug #4 fix'

test_summary
