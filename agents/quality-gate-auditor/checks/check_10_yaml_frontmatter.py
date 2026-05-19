#!/usr/bin/env python3
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
"""Check 10 (B10): every docs/**/*.md frontmatter parses via yaml.safe_load.

YAML frontmatter is the `---`-bounded block at the top of a markdown file,
e.g.:

    ---
    title: ADR-001
    status: accepted
    ---

    # Body...

This check walks every .md file under <project_root>/docs/, identifies
files that begin with a `---` line and have a closing `---` on its own
line, and validates that PyYAML can parse the block between the markers.
A parse failure is reported as a BLOCKER finding listing the relative
path plus the first line of the parse error.

Truth-table:
  - no docs/ dir              -> INFO    pass "no docs/ directory"
  - no .md files              -> INFO    pass "no markdown files to check"
  - no files have frontmatter -> BLOCKER pass "0 frontmatter blocks found"
  - all frontmatter valid     -> BLOCKER pass "all N frontmatter block(s) valid"
  - some invalid              -> BLOCKER fail "<count> file(s) have invalid
                                 frontmatter: <relpath>: <yaml-error>; ..."

Severity rationale:
  - BLOCKER on the failure path: malformed frontmatter breaks downstream
    consumers (catalog discovery, ADR indexing, claude-md-author template
    substitution). Phase 5 cannot ship until each file parses cleanly.
  - INFO on the empty-corpus paths (no docs/, no .md): the check has
    nothing to verify and must not claim a positive verdict on an empty
    input.
  - BLOCKER pass on the "0 frontmatter blocks" path: the check did run
    end-to-end and found zero violations, so it asserts the positive
    BLOCKER-grade verdict (consistent with the other BLOCKER checks).

Graceful degradation:
  - If PyYAML is not installed on the auditor host the check emits an
    INFO pass and exits 0 rather than crashing run_all.sh. The
    remediation field tells the user to install pyyaml.

auto_fixable: false. YAML syntax errors require human judgment — the
auditor can't safely guess which indentation level the author intended.

This is the FIRST Python check in the auditor suite. Bash's `_lib.sh` is
not source-able from Python, so this script formats its own JSON via
json.dumps() (which handles UTF-8 and escaping correctly out of the box).
"""

import json
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    # Graceful degradation: PyYAML missing. Emit an INFO pass so the
    # aggregator (run_all.sh) keeps producing valid JSON; the
    # remediation field tells the operator what to install.
    print(json.dumps({
        "id": "B10",
        "severity": "INFO",
        "check": "yaml_frontmatter",
        "passed": True,
        "detail": "PyYAML not installed; check skipped",
        "remediation": "pip install pyyaml",
        "auto_fixable": False,
    }))
    sys.exit(0)


# Directory names to prune during the walk. Mirrors _lib.sh::find_project_files
# minus "tests" (we MUST descend into tests/fixtures/<this-fixture>/docs/ when
# the audit target IS a fixture directory). The tests/fixtures/ guard below
# kicks in only when the audit target is the WHOLE repo, not a fixture path.
EXCLUDE_DIR_NAMES = {
    ".git", "node_modules", "vendor", "Pods",
    "target", "dist", "build",
    ".venv", ".tox", "__pycache__",
    ".mypy_cache", ".pytest_cache", ".ruff_cache",
    ".ipynb_checkpoints", ".next", ".terraform", "coverage",
    ".cache", ".serena", ".claude", ".gradle", "bower_components",
    ".idea", ".vscode",
}

# Path fragments to exclude when scanning a real project (NOT when the
# project_root is itself a fixture). Keeps the whole-repo self-audit from
# tripping over deliberately malformed fixture YAML.
EXCLUDE_PATH_FRAGMENTS = ("/tests/fixtures/",)


def extract_frontmatter(content: str):
    """Return the YAML text between leading `---` markers, or None.

    The grammar is intentionally strict to match how downstream consumers
    (Jekyll/Hugo-style frontmatter, ADR tooling) parse the block:
      - The file must start with a line that is exactly "---" (after strip).
      - Some subsequent line must also be exactly "---" (after strip).
      - The text between (exclusive) is the frontmatter body.
    A file with no opening `---` or no closing `---` is treated as
    having no frontmatter (returns None — the file is silently skipped).
    """
    if not content.startswith("---"):
        return None
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    # Find closing marker on its own line (after the opener).
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            return "\n".join(lines[1:i])
    return None


def collect_md_files(docs_dir: str, is_fixture_scope: bool):
    """Walk docs_dir and return every .md file, honoring the exclusion rules.

    Pruning excluded directories in-place during os.walk is the canonical
    pattern (https://docs.python.org/3/library/os.html#os.walk): mutating
    the `dirs` list in place tells os.walk which subtrees to skip.

    When `is_fixture_scope` is True, we do NOT exclude tests/fixtures/ —
    the caller IS a fixture path and that's what we want to scan.
    """
    md_files = []
    for root, dirs, files in os.walk(docs_dir):
        # In-place mutation: prune excluded dirs from the walk.
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIR_NAMES]
        for f in files:
            if not f.endswith(".md"):
                continue
            full_path = os.path.join(root, f)
            if not is_fixture_scope and any(
                frag in full_path for frag in EXCLUDE_PATH_FRAGMENTS
            ):
                continue
            md_files.append(full_path)
    return md_files


def emit(payload: dict) -> None:
    """Print a single JSON object to stdout (the auditor's wire contract)."""
    print(json.dumps(payload))


def main() -> None:
    project_root = sys.argv[1] if len(sys.argv) > 1 else "."
    docs_dir = Path(project_root) / "docs"

    if not docs_dir.is_dir():
        emit({
            "id": "B10",
            "severity": "INFO",
            "check": "yaml_frontmatter",
            "passed": True,
            "detail": "no docs/ directory",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    # Detect whether the audit target IS a fixture path. abspath normalizes
    # ".." and symlinks so the substring check is reliable.
    is_fixture_scope = "/tests/fixtures/" in os.path.abspath(project_root)

    md_files = collect_md_files(str(docs_dir), is_fixture_scope)

    if not md_files:
        emit({
            "id": "B10",
            "severity": "INFO",
            "check": "yaml_frontmatter",
            "passed": True,
            "detail": "no markdown files to check",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    failures = []   # list of "<relpath>: <error excerpt>"
    fm_count = 0    # files with a frontmatter block (valid OR invalid)
    for path in md_files:
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except OSError as e:
            # Unreadable file isn't a YAML failure, but it IS something the
            # auditor must surface. Treat it as a failure with a clear label.
            failures.append(
                f"{os.path.relpath(path, project_root)}: read error: {e}"
            )
            fm_count += 1  # account for it so the count is honest
            continue
        fm = extract_frontmatter(content)
        if fm is None:
            # No frontmatter block — file is out of scope for this check.
            continue
        fm_count += 1
        try:
            yaml.safe_load(fm)
        except yaml.YAMLError as e:
            # Take only the first line of the YAMLError for a compact detail.
            # PyYAML error messages can be multi-line ("while parsing a block
            # mapping\n  in 'x', line N, column M\nexpected ..."), and the
            # first line carries the most useful summary.
            err = str(e).split("\n")[0]
            failures.append(
                f"{os.path.relpath(path, project_root)}: {err}"
            )

    if fm_count == 0:
        # No files had frontmatter at all — the check ran end-to-end and
        # legitimately found zero violations. Emit a BLOCKER-grade positive
        # verdict to match the severity of the failure case.
        emit({
            "id": "B10",
            "severity": "BLOCKER",
            "check": "yaml_frontmatter",
            "passed": True,
            "detail": "0 frontmatter blocks found",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    if not failures:
        emit({
            "id": "B10",
            "severity": "BLOCKER",
            "check": "yaml_frontmatter",
            "passed": True,
            "detail": f"all {fm_count} frontmatter block(s) valid",
            "remediation": "",
            "auto_fixable": False,
        })
        return

    # Some files failed. Build a bounded detail string (max 300 chars
    # character-level, UTF-8-safe via Python string slicing).
    joined = "; ".join(failures)
    detail = f"{len(failures)} file(s) have invalid frontmatter: {joined}"
    if len(detail) > 300:
        detail = detail[:297] + "..."

    emit({
        "id": "B10",
        "severity": "BLOCKER",
        "check": "yaml_frontmatter",
        "passed": False,
        "detail": detail,
        "remediation": (
            "fix YAML syntax in each listed file; run "
            "`python3 -c \"import yaml,sys; "
            "yaml.safe_load(open(sys.argv[1]).read().split('---')[1])\" "
            "<file>` to reproduce the parse error locally"
        ),
        "auto_fixable": False,
    })


if __name__ == "__main__":
    main()
