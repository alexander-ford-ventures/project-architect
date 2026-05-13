#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"
SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"

SCHEMA_CONTENT=$(cat "$SCHEMA")
SKILL_CONTENT=$(cat "$SKILL")

# Schema must document all 3 new fields
assert_contains "$SCHEMA_CONTENT" '`locked`' 'state-schema must document locked field'
assert_contains "$SCHEMA_CONTENT" '`version`' 'state-schema must document version field'
assert_contains "$SCHEMA_CONTENT" '`locked_at`' 'state-schema must document locked_at field'
assert_contains "$SCHEMA_CONTENT" 'v1.0' 'must reference v1.0 as initial lock version'

# Phase enum must include phase_7 and phase_8
assert_contains "$SCHEMA_CONTENT" 'phase_7' 'phase enum must include phase_7'
assert_contains "$SCHEMA_CONTENT" 'phase_8' 'phase enum must include phase_8'

# SKILL.md Phase 6 must set these fields
assert_contains "$SKILL_CONTENT" '.locked = true' 'Phase 6 must set state.locked=true'
assert_contains "$SKILL_CONTENT" '.version = "v1.0"' 'Phase 6 must set state.version="v1.0"'
assert_contains "$SKILL_CONTENT" 'locked_at' 'Phase 6 must set locked_at timestamp'

test_summary
