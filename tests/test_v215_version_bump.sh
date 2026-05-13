#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

assert_file_exists "$PLUGIN_JSON" "plugin.json must exist"

VERSION=$(jq -r .version "$PLUGIN_JSON")
assert_eq "$VERSION" "2.1.5" "plugin version must be 2.1.5"

assert_file_exists "$CHANGELOG" "CHANGELOG.md must exist"
CHANGELOG_CONTENT=$(cat "$CHANGELOG")
assert_contains "$CHANGELOG_CONTENT" 'v2.1.5' 'CHANGELOG must have v2.1.5 entry'
assert_contains "$CHANGELOG_CONTENT" 'bug #1' 'CHANGELOG must reference bug #1'
assert_contains "$CHANGELOG_CONTENT" 'bug #14' 'CHANGELOG must reference bug #14'

test_summary
