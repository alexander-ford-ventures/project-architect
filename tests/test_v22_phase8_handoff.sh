#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
CONTENT=$(cat "$SKILL")

assert_contains "$CONTENT" 'Phase 8: Handoff' 'must have Phase 8 heading'
assert_contains "$CONTENT" 'restart Claude Code' 'handoff message must instruct restart'
assert_contains "$CONTENT" '/exit' 'handoff message must mention /exit'
assert_contains "$CONTENT" '/scaffold' 'handoff must list /scaffold'
assert_contains "$CONTENT" '/implement' 'handoff must list /implement'
assert_contains "$CONTENT" '/iterate-design' 'handoff must list /iterate-design'
assert_contains "$CONTENT" 'phase = "complete"' 'Phase 8 must set phase=complete'
assert_contains "$CONTENT" 'prerequisites_satisfied = true' 'must mark prereqs satisfied'
assert_contains "$CONTENT" 'Architect session ending' 'must have session-ending message'

test_summary
