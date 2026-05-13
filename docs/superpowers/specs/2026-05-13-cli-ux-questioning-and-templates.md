<!-- Author: Vladimir Dukelic <vladimir@dukelic.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/siliconyouth/project-architect) -->

---
name: CLI UX questioning + templates (cross-language)
date: 2026-05-13
status: SHIPPED. Phase 1 universal question landed in v2.1.5 (commit ad32619, tag v2.1.5); per-language Phase 2 picker + CLI_UX_DESIGN.md template landed in v2.2.0 as Sketch E (plan Tasks 50-52, commits 26fd1ef / 70b0121 / fdc6a5a, tag v2.2.0).
audience: future v2.x design decision
---

# CLI-UX questioning expansion + new template (cross-language)

## Why this file exists

During the live test of v2.1.4 against md2pdf, the user noticed Phase 1's Batch 4 (CLI-specific questions) covered tech stack but **never asked about CLI-as-product-experience**: interactive prompts vs one-shot vs full TUI, styling, banners, progress indicators. For md2pdf the answer is "minimal one-shot," but the question must be asked because for tools like atuin/gitui/lazygit/zellij (Rust), gh/charm/fzf-go (Go), textual demos (Python), oclif apps (Node), gem CLIs (Ruby) the answer is "full TUI" — and that's a Phase 1 architecture decision.

This sketch (v2) **separates language-agnostic UX design questions from per-language library recommendations**, matching how the existing skill structures Phase 1 (what) vs Phase 2 (how).

## Design principle

```
Phase 1 (what / universal):     Experience model + UX intent
                ↓
Phase 2 (how / per-language):    Routes to a per-language library picker
```

The experience model question is the same for everyone. The library set differs per language. This way, the question once and routes appropriately whether you're in Rust, Go, Python, Node, Ruby, C#, Java, or Bash.

## Phase 1 expansion — language-agnostic UX questions (insert into Batch 4)

### Gate question — CLI experience model

> Which best describes your tool's interaction style?
> 1. **One-shot** (input → output → exit) — md2pdf, jq, ripgrep, fd, gh CLI, kubectl
> 2. **Interactive prompts** (CLI asks user, then runs) — `npm init`, `cargo init`, `gh repo create`, Cookiecutter
> 3. **Full TUI** (keyboard-driven persistent terminal UI) — atuin/gitui/lazygit/zellij/helix (Rust), gh dash (Go), textual demos (Python), tig
> 4. **Hybrid** (one-shot default + optional interactive flag) — git (`git rebase -i`), aws-cli (`aws configure`)

### Universal UX intent (asked unless answer was 1)

**Q-style-1**: Visual style?
- Minimal (text only, no color, no banner)
- Branded (banner + colors + spinners + progress)

**Q-style-2**: Output format(s)?
- Human-only (default; pretty)
- Human + `--json` (machine pipe)
- `--quiet` / `--verbose` discipline (split with sub-toggle)

**Q-style-3**: Color policy?
- Auto-detect (NO_COLOR, FORCE_COLOR, CI, tty) — recommended default
- Always-color (force, even in non-tty)
- Never-color (text only)

**Q-style-4**: Accessibility commitments?
- NO_COLOR support (mandatory baseline)
- Screen-reader friendly (no purely-visual cues; semantic exit codes)
- Low-bandwidth/SSH (banner sizes, animation throttling, no high-frequency redraws)

### TUI-specific (if option 3 chosen)

**Q-tui-1**: Input/UX patterns? (multi-select)
- Vi-style modal navigation
- Emacs-style chord
- Arrow keys + Tab + Enter only
- Mouse-aware

**Q-tui-2**: Persistence? (multi-select)
- Reads/writes a config file (TOML/YAML/JSON) at `~/.config/$tool/`
- Maintains a session/history database (e.g., SQLite)
- Pure ephemeral

## Phase 2 routing — per-language library recommendations

The orchestrator routes here based on `decisions.tech_stack.language` AND the experience model answer. Below: the 2026-validated library set per language.

### 🦀 Rust

| Need | Library | Notes |
|---|---|---|
| TUI framework | **`ratatui`** | Active fork of tui-rs; immediate-mode; dominant in 2026. Used by gitui/atuin/bottom. |
| TUI alternative | `cursive` | Declarative, batteries-included, less popular |
| Terminal backend | **`crossterm`** | Cross-platform default for ratatui |
| Backend alt (Unix-only) | `termion` | Lighter dep tree, Unix-only |
| Backend alt (powerful) | `termwiz` | wezterm's; mouse + sixel; heaviest |
| Prompts | **`inquire`** for rich UX, **`dialoguer`** for simple | `requestty` for Inquirer.js parity; `cliclack` modern |
| Progress | **`indicatif`** | 136M+ downloads, MultiProgress, Sync/Send |
| Progress alt | `kdam` | tqdm port, 4× faster, gradient colors |
| Color | **`owo-colors`** | Zero-alloc, no_std, full env detection |
| Color alt | `anstream` | Stream wrapper |
| Banners | `tui-banner` (modern, zero-dep) / `figrs` (FIGlet) / `Blocklet` (Unicode block) | All viable |

### 🐹 Go

| Need | Library | Notes |
|---|---|---|
| TUI framework | **`bubbletea`** (Charmbracelet) | The Elm Architecture: Init/Update/View. Dominant choice. |
| Styling | **`lipgloss`** (Charmbracelet) | CSS-like style declarations for terminal layouts |
| Components | **`bubbles`** (Charmbracelet) | List, table, spinner, viewport, text input — paired with bubbletea |
| Prompts | **`huh`** (Charmbracelet) or `survey` | huh is the modern Charm-ecosystem mate; survey is the classic |
| Progress | **`mpb`** | Multi-progress bars |
| Color | `lipgloss` covers it; or `fatih/color` for plain CLI | Lipgloss is canonical with Charm stack |
| Banners | `figure` or `go-figure` | FIGlet implementations |
| All-in-one alt | `wish` (SSH-based TUI hosting) | When you want bubbletea apps over SSH |

### 🐍 Python

| Need | Library | Notes |
|---|---|---|
| TUI framework | **`textual`** | Modern async-powered TUI, built on rich. 16.7M colors, mouse, smooth animation. |
| Rich console | **`rich`** | Styling, tables, syntax highlighting, progress, markdown rendering |
| Prompts / REPL | **`prompt_toolkit`** | King of REPLs and advanced shell prompts; autocomplete, history, keybindings |
| Simple prompts | `click.prompt` / `typer` built-ins | Built into the CLI parser |
| CLI parser | **`click`** or **`typer`** (typer = click + type hints) | typer is the modern recommendation |
| Progress | `rich.progress` (preferred) or `tqdm` | Rich integrates with the console |
| Color | rich (preferred) or `colorama` (simple) | rich does NO_COLOR detection |
| Banners | `pyfiglet` or `art` | art has more fonts |

### 🟨 Node.js / TypeScript

| Need | Library | Notes |
|---|---|---|
| TUI framework | **`ink`** | React for the terminal — components → stdout. Used by GitHub CLI's reactive bits. |
| TUI alternative | `blessed` / `neo-blessed` | Older but established |
| TUI new entrant | `opentui` | Newer, watch space |
| Prompts | **`@clack/prompts`** (modern) or `inquirer` (classic) or `enquirer` (stylish) | clack is the 2026 modern pick; inquirer is dominant install base |
| Task lists | **`listr2`** | "Task list" pattern — beautiful for multi-step CLIs (npm install, scaffolders) |
| Color | **`chalk`** | Universal default |
| Color alt | `kleur`, `picocolors` | Lighter alternatives |
| Progress | `cli-progress` or `ora` (spinner-only) | ora dominates spinners |
| Banners | `figlet` (npm) | FIGlet bindings |
| CLI scaffold | **`oclif`** (Salesforce) or `commander` | oclif for big multi-command CLIs |

### 💎 Ruby

| Need | Library | Notes |
|---|---|---|
| Toolkit (covers most) | **`tty`** (piotrmurach) — meta-gem | Provides: tty-prompt, tty-progressbar, tty-spinner, tty-cursor, tty-table, tty-tree, tty-screen, tty-config |
| Prompts | **`tty-prompt`** | Beautiful + powerful interactive prompts |
| Progress | **`tty-progressbar`** | Multi-progress, pause/resume |
| Spinners | **`tty-spinner`** | Many styles |
| Color | **`pastel`** (TTY) | Foundation for tty-* color usage |
| TUI framework | (none dominant — not Ruby's strength) | For full TUI, use components ad-hoc; Ruby community tends toward simpler CLIs |
| Banners | `artii` | FIGlet binding |

### 🟦 C# / .NET

| Need | Library | Notes |
|---|---|---|
| Rich console (most CLIs) | **`Spectre.Console`** | The gold standard now: color, prompts, tables, status, progress, charts, markup |
| CLI framework | `Spectre.Console.Cli` (built on Spectre.Console) or `System.CommandLine` | Cli adds settings binding, validation, DI |
| Full TUI | **`Terminal.Gui`** (gui-cs) | Cross-platform TUI; Miguel de Icaza; 10.7K stars; 1.6M NuGet DLs |
| Spectre extension | `SharpConsoleUI` | Builds on Spectre.Console for richer interactions |

### Other languages — outline

| Language | TUI | Prompts | Progress | Color | Banner |
|---|---|---|---|---|---|
| **C/C++** | `ncurses` (classic), **`FTXUI`** (modern, header-only C++) | `linenoise` / `readline` | custom or `indicators` | ANSI codes manually or `rang` | FIGlet C bindings |
| **Java/Kotlin** | **`Lanterna`** | **`JLine`** | progressbar (jakob1379) | JLine + ANSI | jfiglet |
| **Bash / POSIX** | `dialog` / `whiptail` (interactive); avoid full TUI | `read` builtins | `pv` / progress shell function | tput sequences | `figlet` (system command) |
| **Elixir** | `ratatouille` (ratatui-inspired) | `mix tasks` interactivity | `progress_bar` | `IO.ANSI` | n/a — uncommon |

## New template: `CLI_UX_DESIGN.md`

For projects where `decisions.cli_experience_model` is set (i.e., for CLI types).

**Frontmatter:**
```yaml
---
generate_when: project.sub_type in ["cli_tool", "cli_with_subcommands", "tui_app", "interactive_cli"]
required_decisions:
  - cli_experience_model
  - cli_visual_style
  - cli_color_policy
revision_triggers:
  - cli_experience_model
  - cli_ux_libs.*
depends_on:
  - PROJECT_REQUIREMENTS.md
  - CLI_REFERENCE.md
  - ARCHITECTURE.md
  - TECH_STACK.md
---
```

**Sections (drafted; expand each from state.decisions):**

1. **Interaction model** — one-shot / prompts / TUI / hybrid + the rationale
2. **Key bindings** — TUI-only; full keymap (Vi vs Emacs vs Arrow-Tab) + reasoning
3. **Visual design**
   - Color policy (NO_COLOR, CI, tty detection)
   - Banner (yes/no; if yes: source library, font choice, colorization)
   - Progress reporting (library + style)
   - Spinner styles (if any)
4. **Output formats**
   - Default (human)
   - `--json` if structured output is in scope
   - `--quiet` / `--verbose` discipline
5. **Error message conventions** — colors, prefix (`error:`, `warning:`), suggestion lines
6. **Accessibility**
   - NO_COLOR support (always required)
   - Screen-reader friendliness (no purely-visual cues; semantic exit codes)
   - Low-bandwidth/SSH considerations
7. **Help text style** — flag style, examples included, color in help
8. **Library inventory** — table of every CLI-UX library used (rendered from `decisions.cli_ux_libs`)

## SKILL.md routing logic

Add to phase routing:

```
# Phase 1 Batch 4 (CLI sub-questions)
if project.sub_type in ["cli_tool", "cli_with_subcommands", "tui_app", "interactive_cli"]:
  ask gate: cli_experience_model
  if not "one_shot":
    ask universal UX intent (style, output_format, color_policy, accessibility)
  if "tui" in cli_experience_model:
    ask tui-specific (input_patterns, persistence)

# Phase 2 routing
if cli_experience_model != "one_shot":
  pick the per-language library set above based on tech_stack.language
  store in decisions.cli_ux_libs.*
  enable template generation: CLI_UX_DESIGN.md
```

## Implementation cost estimate

| Artifact | LOC | Time |
|---|---|---|
| Phase 1 Batch 4 question additions in `questioning-flow.md` | ~80 (universal questions only) | 1h |
| Phase 2 per-language picker in `questioning-flow.md` | ~100 (covers all 7 language families) | 1.5h |
| `CLI_UX_DESIGN.md` template with `generate_when` + sections | ~250 | 3h |
| `tech-stack-options.md` per-language CLI-UX sections | ~30/lang × 7 = 210 | 3h |
| SKILL.md routing logic + state schema additions | ~30 | 30m |
| Tests against fixtures (Rust+md2pdf style; Python+textual; Go+bubbletea; Ruby+TTY) | — | 3h |

**Total: ~1.5 working days of focused work.**

## Why this is genuinely new (not "we covered it"):

The existing `tech-stack-options.md` has CLI parser (clap, click, commander, etc.) but no rows for prompts, TUI, color, progress, banners — and the questioning has "what does it do" but not "how does the user experience it." These are independent dimensions: a TUI app and a one-shot CLI both use a CLI parser, but they have totally different UX architectures.

## Decision options for the user

1. **Defer to v2.2** alongside the validation sketches — package the v2.x efforts together
2. **Ship in v2.1.5** as Phase 1 question expansion only (no template, no per-language picker) — fastest user-visible win
3. **Hold for v2.3** — let validation ship first; this is independent

## Sources (10 searches, 6 languages)

### Rust
- [ratatui — GitHub](https://github.com/ratatui/ratatui)
- [Ratatui FAQ](https://ratatui.rs/faq/)
- [cursive — GitHub](https://github.com/gyscos/cursive)
- [Comparison of Rust CLI Prompts](https://fadeevab.com/comparison-of-rust-cli-prompts/)
- [inquire — GitHub](https://github.com/mikaelmello/inquire)
- [requestty — GitHub](https://github.com/Lutetium-Vanadium/requestty/)
- [indicatif — GitHub](https://github.com/console-rs/indicatif)
- [kdam — Lib.rs](https://lib.rs/crates/kdam)
- [Managing colors in Rust — Rain's CLI recommendations](https://rust-cli-recommendations.sunshowers.io/managing-colors-in-rust.html)
- [owo-colors — Lib.rs](https://lib.rs/crates/owo-colors)
- [tui-banner — Cinematic ANSI Banners](https://dev.to/zhang_lei_d5d577e6d0b5421/cinematic-ansi-banners-for-rust-1ceo)
- [Blocklet — Lib.rs](https://lib.rs/crates/blocklet)

### Go
- [bubbletea — GitHub](https://github.com/charmbracelet/bubbletea)
- [lipgloss — GitHub](https://github.com/charmbracelet/lipgloss)
- [Charm — GitHub](https://github.com/charmbracelet)
- [Building a TUI app in Go (Bubbletea)](https://themarkokovacevic.com/posts/terminal-ui-with-bubbletea/)
- [Go vs Rust for TUI Development](https://blog.tng.sh/2026/03/go-vs-rust-for-tui-development-deep.html)

### Python
- [Textual — Real Python](https://realpython.com/python-textual/)
- [prompt-toolkit — GitHub](https://github.com/prompt-toolkit/python-prompt-toolkit)
- [5 Best Python TUI Libraries](https://dev.to/lazy_code/5-best-python-tui-libraries-for-building-text-based-user-interfaces-5fdi)
- [Textual: The Python Library for Creating TUI](https://www.geeksveda.com/textual-create-tui-in-python/)

### Node.js / TypeScript
- [Ink vs @clack/prompts vs Enquirer 2026 — PkgPulse Guides](https://www.pkgpulse.com/guides/ink-vs-clack-vs-enquirer-interactive-cli-nodejs-2026)
- [listr2 — GitHub](https://github.com/listr2/listr2)
- [Building Terminal Interfaces with Node.js](https://blog.openreplay.com/building-terminal-interfaces-nodejs/)
- [Inquirer Node.js Complete Guide 2026](https://copyprogramming.com/howto/inquirer-on-node-js)
- [opentui — GitHub](https://github.com/anomalyco/opentui)

### Ruby
- [TTY toolkit — homepage](https://ttytoolkit.org/)
- [tty — GitHub](https://github.com/piotrmurach/tty)
- [tty-progressbar — GitHub](https://github.com/piotrmurach/tty-progressbar)
- [TTY Components](https://ttytoolkit.org/components/)
- [Beautify Your Command Line Project with TTY Gems](https://medium.com/@bellex0/beautify-your-command-line-project-with-tty-gems-4a563948b23a)

### C# / .NET
- [Spectre.Console Documentation](https://spectreconsole.net/)
- [Terminal.Gui — GitHub](https://github.com/gui-cs/Terminal.Gui)
- [Building Terminal UIs in .NET (SharpConsoleUI)](https://dev.to/nikolaos_protopapas_d3bd6/building-terminal-uis-in-net-how-sharpconsoleui-complements-terminalgui-hb9)
- [Crafting beautiful interactive console apps with Spectre.Console](https://anthonysimmon.com/beautiful-interactive-console-apps-with-system-commandline-and-spectre-console/)

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
