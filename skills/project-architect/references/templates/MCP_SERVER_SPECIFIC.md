---
template_name: MCP_SERVER_SPECIFIC
generate_when: "decisions.project.type == 'mcp_server'"
required_decisions: [mcp.host_environment, mcp.surface]
optional_decisions: [mcp.auth_model, mcp.statefulness, mcp.language]
depends_on: []
revision_triggers: [mcp.host_environment, mcp.surface, mcp.auth_model]
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# MCP Server Specific: {{project_name}}

## Host Environment (stdio / HTTP+SSE / Cloudflare Workers / Vercel)
Transport / host model: local stdio for Claude Desktop / Claude Code, HTTP+SSE for remote clients, deployed on Cloudflare Workers, Vercel Functions, Fly.io, AWS Lambda, or self-hosted.

## Surface (tools / resources / prompts)
MCP capabilities exposed (tools — verbs, resources — readable URIs, prompts — parameterized templates) and the user-facing problem each surface solves.

## Auth Model
Authentication model (none for local stdio, OAuth 2.1 with PKCE for remote, API key / bearer token, signed user JWT, per-tenant credentials passthrough) and refresh / rotation handling.

## Statefulness (durable per-user vs stateless)
Statefulness posture: stateless request-response, ephemeral per-session memory, durable per-user state (Cloudflare Durable Objects, Postgres-backed sessions), and consistency model.

## Language & SDK Choice
Implementation language and MCP SDK (TypeScript `@modelcontextprotocol/sdk`, Python SDK, Rust SDK, custom transport) with rationale around deployment target and library ecosystem.

## Tool Schema Strategy
Tool input/output schema discipline (Zod / Pydantic / JSON Schema), naming and description conventions for high agent recall, examples in descriptions, and breaking-change policy.

## Testing the Server
Testing approach (MCP Inspector for manual smoke, contract tests against schemas, integration tests in Claude Code, fuzzing tool inputs) and CI gates.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
