<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Questioning Flow Reference

The interview is a tree: **universal kickoff** (always asked) → **per-type drill-down** (one branch) → **architecture deep dive** (per-area). Skip questions that prior answers render irrelevant.

## Table of Contents
- [Universal Kickoff (Phase 0)](#universal-kickoff-phase-0)
- [Per-Type Drill-Downs (Phase 1)](#per-type-drill-downs-phase-1)
- [Tech Stack Drill-Downs (Phase 2)](#tech-stack-drill-downs-phase-2)
- [Cost Modeling (Phase 2.5)](#cost-modeling-phase-25)
- [Architecture Deep Dive (Phase 3)](#architecture-deep-dive-phase-3)
- [Routing Rules](#routing-rules)

---

## Universal Kickoff (Phase 0)

Always asked first, in 3 `AskUserQuestion` batches.

### Batch 1 — Identity & Type
1. **Elevator pitch.** One sentence: what is it, who is it for, why does it exist? *(open-ended)*
2. **Top-level project type.** *(multiple-choice from the taxonomy below)*
3. **Sub-type within that category.** *(multiple-choice; options depend on Q2)*

### Batch 2 — Stage & Problem
4. **Project stage.** *(multiple-choice: greenfield / extending existing / rewriting / migrating / PoC only)*
5. **Primary problem & target users.** *(open-ended)*

### Batch 3 — Constraints & Scale
6. **Constraints.** *(multi-select: budget tight / regulated (GDPR/HIPAA/PCI-DSS/SOC2) / tight timeline / pre-existing tech mandates / open-source vs proprietary)*
7. **Team & scale.** *(multiple-choice combining team size {solo / small / larger} × scale tier {hobby / MVP / growth / enterprise})*
8. **Hard pre-existing decisions.** "Must be on AWS", "Must use Postgres", etc. *(open-ended)*

After Batch 3: dispatch `research-scout` for **domain research** (similar projects, pitfalls for this type/domain, regulatory implications, market context). Findings → `docs/research/phase0-domain.md`.

### Top-level project type taxonomy

```
Web application          → SaaS | marketplace | content/blog | dashboard | social | portfolio
                           | internal tool | e-commerce | course/LMS | community forum
                           | wiki/knowledge base | newsletter platform
Mobile application       → consumer | B2B | enterprise | utility | game (→ Game)
                           | health & fitness | finance/banking | productivity
                           | media (streaming/social)
Multi-platform system    → web + mobile + desktop + API combined
API / backend service    → REST | GraphQL | gRPC | WebSocket | event-driven | hybrid
                           | webhook receiver | proxy/gateway | batch processor | scheduled service
CLI tool                 → developer tool | system utility | data/CSV tool | network/security tool
                           | package manager | build tool | scaffolder | REPL | productivity CLI
Library / SDK / package  → SDK for a service | framework | utility lib | type lib
                           | language binding / FFI | code generator | linter/formatter | test library
Desktop application      → macOS | Windows | Linux | cross-platform
                           | full app | menu bar / tray utility | system extension | daemon
Browser extension        → Chrome/Edge | Firefox | Safari | cross-browser
                           | productivity | content filter | DevTools | security/privacy
Game                     → 2D | 3D | mobile | web | console | VR/AR
AI/ML application        → model training | inference serving | RAG | agents | classical ML
                           | computer vision | NLP | recommendation | time-series
                           | reinforcement | multi-modal
Data pipeline / ETL      → batch | streaming | hybrid
                           | ETL | reverse-ETL | CDC | analytics pipeline | feature store
Embedded / firmware/IoT  → MCU class (Cortex-M / RP2 / ESP32 / STM32) | edge gateway | hardware combo
Infrastructure tool      → IaC | CLI for infra | platform / internal developer platform
                           | cluster operator | observability/monitoring tool | CI/CD tool | networking
Claude Code plugin       → command-focused | skill-focused | agent-focused | full plugin
MCP server               → stdio | HTTP/SSE | Cloudflare Workers | other host
                           | tool-focused | resource-focused | prompt-focused | full
Programming language     → general-purpose | DSL | query language | configuration language
                           | educational | transpiler target  (v2.3 — sketch F)
Web3 / smart contracts   → EVM (Solidity) | Solana (Rust/Anchor) | Move (Aptos/Sui) | Cairo (Starknet)
Scientific / research    → numerical sim | data analysis (notebooks) | reproducible study
                           | bioinformatics | geospatial/GIS
AR / VR / spatial        → visionOS | Meta Quest | mobile AR (ARKit/ARCore) | WebXR
Other                    → describe; route to closest neighbor
```

---

## Per-Type Drill-Downs (Phase 1)

Adaptive — keep asking batches until each relevant area is locked. Typical 3–7 batches per project. Dispatch ad-hoc `research-scout` on red flags (see `research-prompts.md`). End-of-phase: `research-scout` for scope realism.

### Web application
- Which platforms (web only / web + PWA / web + mobile)? Browser support floor?
- Offline / sync requirements?
- Public-facing vs auth-walled? Sign-up flow expectations?
- Real-time features (chat, presence, live updates)?
- Content / media handling (uploads, video, large files)?
- Search needs (full-text, faceted, semantic)?

### Mobile application
- Platforms (iOS / Android / both / cross-platform)? Minimum OS versions?
- Distribution (App Store + Play / TestFlight / enterprise / sideload)?
- Offline capability and sync model?
- Push notifications and background tasks?
- Native integrations needed (camera, biometrics, payments, HealthKit, location)?

### Multi-platform system
- Which platforms in scope (web / iOS / Android / macOS / Windows / Linux / API)?
- Code-sharing strategy goal (max share / per-platform native UI)?
- Sync / state model across clients?
- Release cadence per platform?

### API / backend service
- Consumers (internal-only / public-API / partner-only / SDK-distributed)?
- Sync vs async vs event-driven boundary?
- Auth required at the API edge?
- Versioning policy (URL path / header / none)?
- Rate-limiting needs?
- Real-time delivery (WebSocket / SSE / polling)?

### CLI tool
- Distribution channel (homebrew / cargo / npm / pip / binary release / pkg manager combos)?
- Interactive vs strictly scriptable? TTY assumptions?
- Config file format (TOML / YAML / JSON / env)?
- Plugin / extension model?
- Cross-platform (Windows in scope)?
- Telemetry policy (opt-in / opt-out / none)?

#### CLI experience model (universal gate — added v2.1.5)

For CLI projects (`sub_type` in `cli_tool`, `cli_with_subcommands`, `tui_app`, `interactive_cli`), ask this universal question via `AskUserQuestion`:

**Q: CLI experience model — which best describes your tool's interaction style?**

| Option | Description | Examples |
|---|---|---|
| **One-shot** | Input → output → exit. No prompts, no UI state. | md2pdf, jq, ripgrep, fd, gh CLI, kubectl |
| **Interactive prompts** | CLI asks the user via prompts, then runs. | `npm init`, `cargo init`, `gh repo create`, Cookiecutter |
| **Full TUI** | Keyboard-driven persistent terminal UI. | atuin, gitui, lazygit, zellij, helix, gh dash, tig |
| **Hybrid** | One-shot default + optional interactive flag. | git (`git rebase -i`), aws-cli (`aws configure`) |

Save the answer to `state.decisions.cli_experience_model`.

**Routing:**
- `one-shot` → skip the rest of CLI-UX questions
- `interactive_prompts` → ask universal UX intent (style, output_format, color_policy, accessibility)
- `tui` → ask universal UX intent + TUI-specific (input_patterns, persistence)
- `hybrid` → ask both prompts + TUI questions

The per-language library picker (`ratatui` vs `bubbletea` vs `textual` vs `ink` vs etc.) is asked in Phase 2 (added in v2.2). v2.1.5 only asks the universal experience-model question — the language-specific options come later.

#### Universal UX intent (asked unless answer was `one-shot`)

**Q-style-1**: Visual style?
- Minimal (text only, no color, no banner)
- Branded (banner + colors + spinners + progress)

**Q-style-2**: Output format(s)?
- Human-only (default)
- Human + `--json` (machine-pipe)
- `--quiet` / `--verbose` discipline

**Q-style-3**: Color policy?
- Auto-detect (NO_COLOR, FORCE_COLOR, CI, tty) — recommended default
- Always-color (force, even in non-tty)
- Never-color (text-only)

**Q-style-4**: Accessibility commitments?
- NO_COLOR support (mandatory baseline)
- Screen-reader friendly (no purely-visual cues; semantic exit codes)
- Low-bandwidth/SSH (banner sizes, animation throttling)

#### TUI-specific (only if `tui` or `hybrid` chosen)

**Q-tui-1**: Input/UX patterns? (multi-select)
- Vi-style modal navigation
- Emacs-style chord
- Arrow keys + Tab + Enter only
- Mouse-aware

**Q-tui-2**: Persistence? (multi-select)
- Reads/writes a config file (TOML/YAML/JSON) at `~/.config/$tool/`
- Maintains a session/history database (e.g., SQLite)
- Pure ephemeral

### Library / SDK / package
- Target consumers (other devs / specific platform / public)?
- Public-API discipline (semver, deprecation policy)?
- Bundled docs site (Mintlify / TypeDoc / Sphinx / Rustdoc)?
- Example projects shipped alongside?
- Tree-shaking / bundle-size targets?
- TypeScript types shipped?

### Desktop application
- macOS / Windows / Linux / cross? Native vs Electron vs Tauri?
- Distribution (App Store / Developer ID + notarization / direct download / package managers)?
- Auto-update mechanism?
- System integration (menu bar, tray, services, file associations, deep links)?
- Sandboxing requirements?

### Browser extension
- Manifest V3? Cross-browser (Chrome / Firefox / Safari / Edge)?
- Permissions (content scripts / activeTab / host permissions / declarativeNetRequest)?
- DevTools panel / sidebar / popup?
- Distribution (Chrome Web Store / Mozilla Add-ons / enterprise self-host)?
- Data sync (chrome.storage.sync limits)?

### Game
- Engine (Unity / Unreal / Godot / custom / web-native)?
- 2D / 3D / hybrid?
- Single-player / multiplayer (netcode requirements)?
- Platforms (mobile / PC / console / web / VR-AR)?
- Monetization (paid / freemium / IAP / subscription / ads)?
- Save / progression storage (local / cloud)?

### AI/ML application
- Training vs inference vs both?
- Model source (own model / fine-tuned / API-only / open weights / mixture)?
- Dataset handling and provenance?
- Evaluation framework / benchmarks?
- Inference latency targets?
- Cost ceiling per request?
- Vector store needs (RAG / semantic search)?

### Data pipeline
- Sources / sinks (databases, warehouses, APIs, files)?
- Batch / streaming / hybrid?
- Orchestrator (Airflow / Dagster / Prefect / Argo / cron / managed)?
- Schedule / SLA?
- Schema evolution policy?
- Data quality / observability (Great Expectations / Soda / OpenLineage)?

### Embedded / IoT
- MCU class / SoC (Cortex-M / ESP32 / RP2 / STM32 / Linux SoC)?
- RTOS? Bare-metal?
- Power budget?
- Connectivity (BLE / Wi-Fi / LoRa / cellular / none)?
- OTA update mechanism?
- Hardware combo (PCB design / off-the-shelf dev board)?

### Infrastructure tool
- Target users (own team / customers / OSS community)?
- Cloud focus (multi-cloud / single)?
- IaC integration (Terraform / Pulumi / CDK / CloudFormation / Crossplane)?
- Operator / controller model (Kubernetes)?
- Observability / logging / metrics?

### Claude Code plugin
- Components (skills / commands / agents / hooks / MCP servers / mix)?
- Triggers (slash command / natural language / file change / event)?
- Distribution (own marketplace / Anthropic marketplace / private)?
- Configurable per project (`.claude/plugin-name.local.md`)?

### MCP server
- Host environment (stdio / HTTP+SSE / Cloudflare Workers / Vercel / other)?
- Surface (tools / resources / prompts / mix)?
- Auth model (OAuth / API key / none)?
- Stateful (durable per-user) or stateless?
- Languages (TypeScript / Python / Rust / Go)?

### Web3 / smart contracts
- Chain (Ethereum / L2s / Solana / Aptos / Sui / Starknet)?
- Smart-contract language (Solidity / Rust / Move / Cairo)?
- Indexing layer (The Graph / Goldsky / custom)?
- Front-end integration (RainbowKit / wagmi / web3.js / ethers / web3.swift)?
- Upgradeability pattern?
- Audit budget / firm?

### Scientific / research
- Reproducibility requirements (environment freeze, seeds, container/Nix)?
- Notebook vs scripts vs both?
- Data scale (fits-in-RAM / out-of-core / cluster)?
- Computation backend (NumPy / JAX / PyTorch / cuDF / Spark / Ray)?
- Publication / pre-print artifacts?
- Domain-specific tooling (bioinformatics, geospatial, etc.)?

### AR / VR / spatial
- Headset / device target (visionOS / Quest / smartphone AR / WebXR)?
- Tracking / input (controllers / hand tracking / gaze / voice)?
- Rendering engine (Unity / Unreal / RealityKit / Three.js / custom)?
- Mixed-reality vs immersive?
- Multi-user / shared sessions?
- App-store distribution?

### Programming language design (v2.3 — sketch F)

This batch fires when the user's pitch (Phase 0) or any later answer mentions designing a **programming language**, a **compiler**, an **interpreter**, a **DSL**, or a **transpiler** — and the project type was either chosen as `Programming language` or routed here from `Library / SDK` (a language embedded as a host library) or `CLI tool` (a language shipped behind a `lang run …` CLI). The orchestrator should re-confirm the intent before drilling in: language design is a different shape of project than a normal library/CLI, with its own template set (Phase 4) and its own follow-up questions in Phases 2 and 3.

#### Phase 1 → Programming language sub_type routing

Ask via `AskUserQuestion` (single-select):

**Q-pl-1:** Which best describes the **scope** of the language you want to design?

| Option | One-line cue | Examples |
|---|---|---|
| **General-purpose language** | Full stdlib, broad use cases, you expect users to write whole applications in it. | Rust, Go, Python, Zig, Gleam |
| **Domain-specific language** | Narrow grammar, embedded inside a host program or workflow; one problem domain. | HCL (Terraform), regex, jq, Cue, Dhall |
| **Query language** | Reads/filters/aggregates over a data store; the runtime is a query engine, not a general VM. | SQL, GraphQL, KQL, PromQL, Cypher |
| **Configuration language** | Declarative, deterministic, no general computation; outputs structured data. | Nix, Starlark, Jsonnet, KCL |
| **Educational language** | Teaching-first; simplicity and pedagogy beat performance and ecosystem. | Scratch, Logo, Pyret, Hedy |
| **Transpiler target** | You compile a *source* language **to** an existing target language (your output is code, not a binary). | TypeScript → JS, Elm → JS, Kotlin → JVM/JS/Native, ReScript → JS |

The orchestrator saves the chosen variant to `state.decisions.project.sub_type` using the exact enum value from `references/state-schema.md` (see Task 1, v2.3):

- `general_purpose_language`
- `domain_specific_language`
- `query_language`
- `configuration_language`
- `educational_language`
- `transpiler_target`

If the user describes something that straddles two variants (e.g. "a DSL that's also a query language"), pick the *narrower* one — DSL beats general-purpose, query beats DSL when the grammar is built around data retrieval. Edge cases are recorded as ADRs and surfaced to the user before Phase 4.

**Cross-references:**
- **Phase 2** picks up with the PL-specific batch (added v2.3 — Task 11): `impl_strategy` (tree-walking interpreter / bytecode VM / native compiler / transpiler / hosted-embedded) and, when `impl_strategy` is anything but a tree-walking interpreter, a follow-up `host_runtime` question (LLVM / MLIR / Cranelift / QBE / Truffle / JVM / BEAM / WASM / WASM component / JS host / Python-embedded / Rust-host / native-no-runtime / custom-VM). Compare table in `tech-stack-options.md` § PL implementation backends (v2.3 — Task 12).
- **Phase 3** adds the `paradigm` and `type_system` axes (v2.3 — Task 11).
- **Phase 4** generates the 7 PL templates registered in `document-catalog.md` (v2.3 — Task 9): `LANGUAGE_GRAMMAR.md`, `SEMANTICS.md`, `TYPE_SYSTEM.md`, `STDLIB.md`, `TOOLCHAIN.md`, `BOOTSTRAP_PLAN.md`, `STABILITY_AND_RFC.md`. Their `generate_when` filters key off `state.decisions.project.sub_type` being one of the 6 PL sub_types above.

**Skip the rest of the per-type drill-down** (web-app questions, mobile questions, etc.) once a PL sub_type has been chosen — the language-design batches in Phases 2 and 3 take over.

---

## Tech Stack Drill-Downs (Phase 2)

For each category that applies (skip categories based on prior answers — see Routing Rules). See `tech-stack-options.md` for option tables.

Grouped batches:
1. **Language & runtime** (+ build/package manager)
2. **Frontend framework** (skip if no frontend)
3. **Backend framework** (skip if pure client-side)
4. **Database + ORM** (skip if no persistence)
5. **Authentication** (skip if no accounts)
6. **Hosting (frontend + backend separately) + CDN**
7. **Styling & UI** (skip if no frontend)
8. **Payments** (skip if no monetization)
9. **Email / notifications** (skip if not needed)
10. **File storage** (skip if no files)
11. **AI / ML integration** (skip if no AI features)
12. **Observability stack** (skip if scale = hobby)
13. **Testing stack**
14. **CI / CD**

For each major decision, the orchestrator files an ADR (one per major: language, framework choice, db engine, auth provider, host, etc.).

End-of-phase: `research-scout` on stack-combination gotchas. Findings → `docs/research/phase2-stack.md`.

### Per-language CLI-UX library picker (v2.2 — sketch E)

**Routing:** When `state.decisions.tech_stack.language` is set AND `state.decisions.cli_experience_model != "one_shot"`, ask the per-language picker below. The picker offers a 4-library shortlist per language for TUI / prompts / progress / color, gated on the universal CLI-experience-model answer captured in Phase 1 (v2.1.5).

This sub-question runs once the language has been picked in Phase 2's "Language & runtime" batch. It deliberately follows the language decision because the shortlist depends on which ecosystem the project lives in. Save the selected libraries to `state.decisions.cli_ux_libraries` (object keyed by concern → library name).

#### Rust

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI framework | `ratatui` | `crossterm` (lower-level), `cursive` |
| Interactive prompts | `inquire` | `dialoguer` |
| Progress bars | `indicatif` | `pbr` |
| Color | `owo-colors` | `colored`, `nu-ansi-term` |

#### Go

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI framework | `bubbletea` | `tview` |
| Styling | `lipgloss` | `aec` |
| Interactive forms | `huh` | `survey` |
| Progress bars | `mpb` | `progressbar` |

#### Python

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI framework | `textual` | `urwid` |
| Rich output / colors | `rich` | `colorama` |
| Interactive prompts | `prompt_toolkit` | `questionary`, `inquirer` |
| CLI framework | `typer` | `click`, `argparse` |

#### Node

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI framework | `ink` | `blessed` |
| Interactive prompts | `@clack/prompts` | `inquirer`, `prompts` |
| Task list / progress | `listr2` | `ora` |
| Color | `chalk` | `kleur`, `picocolors` |

#### Ruby

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI / forms / progress / color | TTY toolkit (`tty-prompt`, `tty-spinner`, `tty-progressbar`, `pastel`) | `curses` (stdlib) |

#### C#

| Concern | Recommended | Alternatives |
|---|---|---|
| TUI framework | `Spectre.Console` | (stdlib `System.Console`) |
| TUI app (windowed) | `Terminal.Gui` | (rarely needed for CLI) |

**Skip the picker** if `cli_experience_model == "one_shot"` (e.g., a script that emits text and exits — no need for color or progress libraries). For other language ecosystems not in this table (Java, Kotlin, Elixir, Swift, etc.), fall back to a free-form research-scout dispatch and record findings in `docs/research/phase2-cli-ux.md`.

The selected libraries feed into `CLI_UX_DESIGN.md` (added v2.2) and influence the dependency footprint in Phase 4 (`SCAFFOLD_PLAN.md`).

---

## Cost Modeling (Phase 2.5)

1. Dispatch `research-scout` with the pricing-research prompt (see `research-prompts.md`).
2. Walk the user through the findings: base costs, per-unit costs, hidden line items, free-tier limits.
3. Optionally revise tech-stack decisions in light of cost reality (any revision spawns the `decision-revisor`).
4. Capture cost estimates in `COST_MODEL.md` at MVP / growth / enterprise tiers.

---

## Architecture Deep Dive (Phase 3)

Per-area drill-downs. Only ask about areas that apply (per prior phases). Each area concludes a "ready to record" question — if yes, file an ADR.

### Auth (if auth chosen)
- Session strategy (JWT / cookies / hybrid)?
- Token storage (httpOnly / secure storage / both)?
- RBAC / ABAC / simple permissions?
- Multi-tenancy isolation model?
- OAuth providers list?
- Lockout / rate-limit policy?
- MFA support (TOTP / passkeys / SMS)?

### Database design (if DB chosen)
- Normalization level (3NF / denormalized / event-sourced)?
- Migration strategy (code-first / SQL-first / hybrid)?
- Key entities + relationships (high-level ERD)?
- Soft vs hard deletes?
- Audit-logging needs?
- Read replicas / sharding?
- Multi-tenancy data isolation (shared DB / schema-per-tenant / DB-per-tenant)?

### API design (if API)
- Style (REST / GraphQL / gRPC / tRPC / hybrid)?
- Versioning (URL path / header / none)?
- Rate-limiting policy?
- Pagination (cursor / offset / keyset)?
- API docs (OpenAPI / GraphQL introspection / manual)?
- Real-time channel (WebSocket / SSE / polling)?
- Webhook outbound (events, retry, signature)?

### Security architecture (if regulated OR security flagged)
- Encryption at rest / in transit?
- Secret management (env vars / Vault / Infisical / KMS)?
- Input validation library / schema enforcement?
- CORS policy?
- CSP?
- Dep-vuln scanning (Snyk / GitHub Advanced Security / Trivy)?
- Post-quantum / E2E encryption needs?
- Compliance gates (SOC2 / HIPAA / PCI-DSS / GDPR)?

### Frontend architecture (if frontend)
- State management (Context / Zustand / Redux / Jotai / signals)?
- Data fetching (TanStack Query / SWR / tRPC / Apollo)?
- Routing model (file-based / manual)?
- Rendering strategy (SSR / SSG / CSR / ISR / mix)?
- i18n requirements?
- a11y target (WCAG level)?
- Form library?
- Animation library?

### Testing strategy
- Unit framework (Vitest / Jest / pytest / cargo test / etc.)?
- Integration / API test framework?
- E2E framework (Playwright / Cypress / Detox / XCTest / Espresso)?
- Coverage target?
- CI integration cadence?
- Visual / snapshot tests?

### DevOps & deployment
- Environment tiers (dev / staging / production)?
- CI / CD platform?
- IaC (Terraform / Pulumi / SST / CDK / Crossplane / none)?
- Containerization (Docker / Podman / native)?
- Preview deploys (per-PR / per-branch)?
- Blue-green / canary?

### Monitoring & observability (if scale > MVP)
- Error tracking (Sentry / Bugsnag / Datadog)?
- APM (Datadog / New Relic / Grafana Cloud)?
- Logging (Loki / Datadog / Axiom / CloudWatch)?
- Uptime monitoring?
- Analytics (PostHog / Plausible / Mixpanel / Amplitude)?
- Alerting destinations (Slack / PagerDuty / email)?

### Third-party integrations
- Which services are critical (which are nice-to-have)?
- Webhook handling needs?
- Queue / event system?
- Background jobs / scheduled tasks?
- SDK quality / portability concerns?

After all areas: **inline consistency check** (architect cross-checks decisions; surfaces contradictions for user resolution before doc gen).

End-of-phase: `research-scout` on pattern validation. Findings → `docs/research/phase3-architecture.md`.

---

## Routing Rules

Skip questions when prior answers make them irrelevant.

| Phase 0 answer | Skip in later phases |
|---|---|
| Project type = Library / SDK | Auth, database, hosting, UI, payments, notifications |
| Project type = CLI tool | Frontend, UI, payments (usually), styling |
| No user accounts | All auth questions |
| No persistence | Database, ORM, schema design |
| No frontend | Styling, components, frontend architecture |
| No monetization | Payments & billing |
| Budget = free-tier only | Bias options toward open-source / self-hosted |
| Scale = hobby/personal | Monitoring deep dive, enterprise security, multi-tenancy |
| Solo team | Simplify CI/CD; skip team collaboration tooling |
| No regulatory requirements | Compliance section in security |
| Offline = yes | Add sync strategy, local-first patterns |
| Real-time = yes | WebSocket/SSE architecture, presence model |
| AI features = yes | AI/ML section, vector DB, embeddings |
| Stage = greenfield | Commit on `main`; no branch strategy questions |
| Stage = extending/rewriting/migrating | Create `bootstrap/architect-<date>` branch |
| Project type = Programming language (v2.3) | Skip web/mobile/hosting/auth/payments; run Phase 1 PL sub_type routing → Phase 2 `impl_strategy` + `host_runtime` → Phase 3 `paradigm` + `type_system` → Phase 4 generates the 7 PL templates |

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
