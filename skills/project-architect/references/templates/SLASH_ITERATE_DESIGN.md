<!-- Author: Alexander Ford <alex@alexfordlabs.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/alexfordlabs/project-architect) -->

---
template_name: SLASH_ITERATE_DESIGN
target_path: .claude/commands/iterate-design.md
generate_when: always
depends_on: []
---

# Slash command template: `/iterate-design`

When `claude-tooling-author` consumes this template in Phase 7, it produces `.claude/commands/iterate-design.md`.

## Target file content

```markdown
---
description: "Re-open the locked architecture for revision (bumps v1.0 → v1.1-draft)"
---

Re-launch `project-architect:project-architect` to revise the locked design.

Steps:

1. Read `docs/_architect_state.json` — confirm `state.locked == true` and `state.version`.
2. If locked: prompt the user to confirm unlocking. On confirmation:
   - Set `state.locked = false`
   - Bump `state.version = "<prev>+0.1-draft"` (e.g., "v1.0" → "v1.1-draft")
   - Set `state.locked_at = null`
   - Snapshot the locked v1.0 docs to `docs/versions/v1.0/` for reference
3. Invoke `Skill: project-architect:project-architect`. The skill resumes from Phase 5 with the previously-locked decisions loaded.
4. After the user iterates and approves, Phase 6 re-locks at the bumped version (e.g., "v1.1").

If the state is already unlocked (mid-iteration), this command resumes the in-progress iteration without further prompting.
```

---

*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
