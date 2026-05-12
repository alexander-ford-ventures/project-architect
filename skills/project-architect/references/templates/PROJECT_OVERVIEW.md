---
template_name: PROJECT_OVERVIEW
generate_when: "always"
required_decisions:
  - project.name
  - project.elevator_pitch
  - project.type
  - project.subtype
  - project.target_users
  - project.scale
optional_decisions:
  - project.constraints
  - project.preexisting
depends_on: []
revision_triggers:
  - project.name
  - project.type
  - project.subtype
  - project.scale
---

# {{project_name}}

## Vision
One paragraph: what it is, who it's for, why it matters. Pulled from `project.elevator_pitch` and expanded with target users.

## Project Type
{{project.type}} → {{project.subtype}}. {{project.stage}}.

## Tech Stack Summary
Table: layer | technology | one-line rationale. Pulled from all `language.*`, `frontend.*`, `backend.*`, `database.*`, `auth.*`, `hosting.*` decisions.

## Architecture Diagram
Mermaid or ASCII showing major components and data flow. Composed from tech stack + Phase 3 architecture decisions.

## Document Index
Table: document | description | status. Includes only docs actually generated for this project.

## Key Decisions Log
Brief table of major decisions with ADR ID, decision, rationale (one line each).

## Constraints & Non-Goals
Pulled from `project.constraints` plus any explicit out-of-scope items captured in Phase 1.

## Revision Log
(none yet)
