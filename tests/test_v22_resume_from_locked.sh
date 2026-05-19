#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
CONTENT=$(cat "$SKILL")

# Resumability section handles state.locked == true
assert_contains "$CONTENT" 'state.locked == true' 'Resumability must handle locked state'
assert_contains "$CONTENT" 'Resume from locked' 'must have Resume from locked subsection'

# Refuse silent overwrite
assert_contains "$CONTENT" 'design is locked' 'must surface locked status to user'

# Three options
assert_contains "$CONTENT" 'Unlock and revise' 'option (a) must offer unlock + revise'
assert_contains "$CONTENT" 'read-only' 'option (b) must offer read-only snapshot'

# Unlock mechanics
assert_contains "$CONTENT" 'locked = false' 'on unlock must set state.locked = false'
assert_contains "$CONTENT" 'draft' 'version bump must include draft suffix (e.g. v1.0 → v1.1-draft)'

# /iterate-design tie-in
assert_contains "$CONTENT" '/iterate-design' 'must tie in /iterate-design slash command path'

test_summary
