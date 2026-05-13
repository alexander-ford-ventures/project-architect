#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
assert_eq "$PLUGIN_VERSION" "2.2.0" "plugin.json version must be 2.2.0"

CHANGELOG_CONTENT=$(cat "$CHANGELOG")
assert_contains "$CHANGELOG_CONTENT" 'v2.2.0' 'CHANGELOG must have v2.2.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'Sketch B' 'CHANGELOG must mention Sketch B (auditor)'
assert_contains "$CHANGELOG_CONTENT" 'Sketch C' 'CHANGELOG must mention Sketch C (runtime budgets)'
assert_contains "$CHANGELOG_CONTENT" 'Sketch D' 'CHANGELOG must mention Sketch D (multi-session lifecycle)'
assert_contains "$CHANGELOG_CONTENT" 'Sketch A' 'CHANGELOG must mention Sketch A (inline validators)'
assert_contains "$CHANGELOG_CONTENT" 'CLI-UX' 'CHANGELOG must mention CLI-UX picker (Sketch E)'

test_summary
