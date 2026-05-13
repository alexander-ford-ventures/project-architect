#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"

SKILL_CONTENT=$(cat "$SKILL")
SCHEMA_CONTENT=$(cat "$SCHEMA")

# Phase 6 must NOT delete state.json
assert_not_contains "$SKILL_CONTENT" 'delete docs/_architect_state.json' 'Phase 6 must NOT delete state.json'
assert_not_contains "$SKILL_CONTENT" 'rm docs/_architect_state.json' 'Phase 6 must NOT rm state.json'

# Must explicitly state state.json is preserved
assert_contains "$SKILL_CONTENT" 'state.json is preserved' 'Phase 6 must explicitly preserve state.json'

# state-schema.md lifecycle table must reflect this
assert_not_contains "$SCHEMA_CONTENT" 'Delete `state.json`' 'state-schema.md lifecycle must NOT say to delete state.json'

test_summary
