---
template_name: PLATFORMS
generate_when: "decisions.platforms.length > 1"
required_decisions: [platforms]
optional_decisions: [code_sharing_strategy, platform_specific.*]
depends_on: []
revision_triggers: [platforms, code_sharing_strategy]
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Platforms: {{project_name}}

## Supported Platforms
Table: platform | tech | priority | min version. One row per target (web, iOS, Android, macOS, Windows, Linux, etc.) with the framework chosen and minimum supported OS.

## Code Sharing Strategy
How code is shared across platforms (monorepo with shared core, Kotlin Multiplatform, React Native, native per platform), what's shared vs duplicated, and where the boundary lives.

## Platform-Specific Considerations
One subsection per platform. Each captures: distribution (App Store / Play / web / sideload), native APIs used, required permissions, offline behavior, on-device storage strategy, push notification stack, and deep-link / universal-link scheme.

## Sync Strategy
How state is synchronized across a user's devices (CRDT / event log / last-write-wins / manual), conflict-resolution rules, and offline-queue handling.

## Release Strategy
Versioning scheme (per platform or unified semver), release cadence, update mechanism (App Store / Play / Sparkle / auto-update server / OTA bundle), and rollback plan.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
