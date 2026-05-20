<!-- Author: Alexander Ford <alex@alexfordlabs.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/alexfordlabs/project-architect) -->

---
template_name: SLASH_SCAFFOLD
target_path: .claude/commands/scaffold.md
generate_when: always
depends_on:
  - SCAFFOLD_PLAN.md
---

# Slash command template: `/scaffold`

When `claude-tooling-author` consumes this template in Phase 7, it produces `.claude/commands/scaffold.md`. The content below is what gets written (verbatim, no substitution other than the conditional language-specific snippets which `claude-tooling-author` may inline based on `state.decisions.tech_stack.language`).

## Target file content

```markdown
---
description: "Scaffold the codebase from docs/SCAFFOLD_PLAN.md"
---

Scaffold the codebase from `docs/SCAFFOLD_PLAN.md` using `superpowers:writing-plans` + `subagent-driven-development`.

Steps Claude will take:

1. Read `docs/SCAFFOLD_PLAN.md` — the plan describes build manifest, src/ tree, license files, toolchain pin, and bootstrap commands.
2. Read `docs/_architect_state.json` to confirm the project is locked at v1.0.
3. Invoke `Skill: superpowers:writing-plans` with `spec_path: docs/SCAFFOLD_PLAN.md` and execution mode `subagent-driven-development`.
4. Superpowers writes the implementation plan, then dispatches subagents to execute it.

After scaffolding:
- The codebase exists in src/ (and sibling dirs per the plan)
- All ADRs are crossed-referenced in source comments where the plan calls for it
- A `chore: bootstrap scaffold` commit lands

Fallback: if `superpowers:writing-plans` isn't installed, see `docs/NEXT_STEP_PLAN.md` for manual bootstrap.
```

---

*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
