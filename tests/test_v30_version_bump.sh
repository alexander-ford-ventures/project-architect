#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
assert_eq "$PLUGIN_VERSION" "3.0.0" "plugin.json version must be 3.0.0"

CHANGELOG_CONTENT=$(cat "$CHANGELOG")

# Current entry
assert_contains "$CHANGELOG_CONTENT" 'v3.0.0' 'CHANGELOG must have v3.0.0 entry'

# Regression checks: prior versions retained
assert_contains "$CHANGELOG_CONTENT" 'v2.3.0' 'CHANGELOG must retain v2.3.0 entry (regression check)'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.1' 'CHANGELOG must retain v2.2.1 entry (regression check)'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.0' 'CHANGELOG must retain v2.2.0 entry (regression check)'

# v3.0.0 entry must document the repository move + author handover.
assert_contains "$CHANGELOG_CONTENT" 'alexander-ford-ventures/project-architect' 'CHANGELOG v3.0.0 must reference the new canonical repository path'
assert_contains "$CHANGELOG_CONTENT" 'Alexander Ford' 'CHANGELOG v3.0.0 must name the new author/maintainer'
assert_contains "$CHANGELOG_CONTENT" 'alex@pseudo-lang.com' 'CHANGELOG v3.0.0 must include the new author email'

# Manifest identity must match the new owner.
PLUGIN_AUTHOR_NAME=$(jq -r '.author.name' "$PLUGIN_JSON")
PLUGIN_AUTHOR_EMAIL=$(jq -r '.author.email' "$PLUGIN_JSON")
PLUGIN_REPO=$(jq -r '.repository' "$PLUGIN_JSON")
assert_eq "$PLUGIN_AUTHOR_NAME" "Alexander Ford" "plugin.json author.name must be Alexander Ford"
assert_eq "$PLUGIN_AUTHOR_EMAIL" "alex@pseudo-lang.com" "plugin.json author.email must be alex@pseudo-lang.com"
assert_eq "$PLUGIN_REPO" "https://github.com/alexander-ford-ventures/project-architect" "plugin.json repository must point at alexander-ford-ventures"

# Marketplace identifier (the `name` field in marketplace.json drives `@<name>` installs).
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
MARKETPLACE_NAME=$(jq -r '.name' "$MARKETPLACE_JSON")
assert_eq "$MARKETPLACE_NAME" "alexander-ford-ventures" "marketplace.json name must be 'alexander-ford-ventures' (the @<name> install identifier)"

# LICENSE copyright line carries the new identity.
LICENSE_CONTENT=$(cat "$REPO_ROOT/LICENSE")
assert_contains "$LICENSE_CONTENT" 'Alexander Ford' 'LICENSE must carry Alexander Ford as the copyright holder'
assert_contains "$LICENSE_CONTENT" 'alex@pseudo-lang.com' 'LICENSE must carry the new email'

test_summary
