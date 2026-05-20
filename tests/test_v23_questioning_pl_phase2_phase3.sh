#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
#
# v2.3 Task 11 — Phase 2 + Phase 3 PL question batches in questioning-flow.md.
# Verifies the reference adds two new sub-sections triggered when
# state.decisions.project.sub_type is one of the 6 PL variants:
#   - Phase 2 PL batch: impl_strategy (5 values) + host_runtime (14 values)
#   - Phase 3 PL batch: paradigm (6 values) + type_system (6 values)
# Each batch must cross-reference its target template(s) and the v2.3 marker.

source "$(dirname "$0")/lib/test_helpers.sh"

REF="$REPO_ROOT/skills/project-architect/references/questioning-flow.md"

assert_file_exists "$REF" 'questioning-flow.md must exist'

CONTENT=$(cat "$REF")

# v2.3 marker for the Phase 2 + Phase 3 PL sections.
assert_contains "$CONTENT" 'v2.3' 'questioning-flow.md must carry a v2.3 marker'

# --- Phase 2 PL section presence ---
# A dedicated Phase 2 PL sub-section must exist with PL-specific batch wording.
assert_contains "$CONTENT" 'Phase 2' 'questioning-flow.md must reference Phase 2'
assert_contains "$CONTENT" 'PL-specific' 'questioning-flow.md must label the Phase 2 PL batch as PL-specific'

# Trigger condition: sub_type in PL set.
assert_contains "$CONTENT" 'project.sub_type' 'Phase 2 PL batch must trigger on state.decisions.project.sub_type'

# --- impl_strategy (5 values) ---
assert_contains "$CONTENT" 'impl_strategy' 'Phase 2 PL batch must introduce impl_strategy axis'
assert_contains "$CONTENT" 'tree_walking_interpreter' 'impl_strategy must include tree_walking_interpreter'
assert_contains "$CONTENT" 'bytecode_vm' 'impl_strategy must include bytecode_vm'
assert_contains "$CONTENT" 'native_compiler' 'impl_strategy must include native_compiler'
assert_contains "$CONTENT" 'transpiler' 'impl_strategy must include transpiler'
assert_contains "$CONTENT" 'hosted_embedded' 'impl_strategy must include hosted_embedded'

# --- host_runtime (14 values; require at least 7 of 14 named verbatim) ---
assert_contains "$CONTENT" 'host_runtime' 'Phase 2 PL batch must introduce host_runtime axis'
HR_HITS=0
for v in llvm mlir cranelift qbe truffle jvm beam wasm wasm_component js_host python_embedded rust_host native_no_runtime custom_vm; do
  if [[ "$CONTENT" == *"$v"* ]]; then
    HR_HITS=$((HR_HITS + 1))
  fi
done
if (( HR_HITS >= 7 )); then
  PASS_COUNT=$((PASS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_MESSAGES+=("FAIL: host_runtime must mention at least 7 of 14 enum values; found only $HR_HITS")
fi

# Cross-reference: Phase 2 PL batch must point at tech-stack-options.md (Task 12).
assert_contains "$CONTENT" 'tech-stack-options.md' 'Phase 2 PL batch must cross-reference tech-stack-options.md'

# --- Phase 3 PL section presence ---
assert_contains "$CONTENT" 'Phase 3' 'questioning-flow.md must reference Phase 3'

# --- paradigm (6 values) ---
assert_contains "$CONTENT" 'paradigm' 'Phase 3 PL batch must introduce paradigm axis'
for v in imperative functional logic oop multi_paradigm data_oriented; do
  assert_contains "$CONTENT" "$v" "paradigm enum must include: $v"
done

# --- type_system (6 values) ---
assert_contains "$CONTENT" 'type_system' 'Phase 3 PL batch must introduce type_system axis'
for v in static_strong static_gradual dynamic dependent affine_linear none_untyped; do
  assert_contains "$CONTENT" "$v" "type_system enum must include: $v"
done

# Cross-references to PL templates.
assert_contains "$CONTENT" 'TYPE_SYSTEM.md' 'Phase 3 PL batch must cross-reference TYPE_SYSTEM.md template'
assert_contains "$CONTENT" 'BOOTSTRAP_PLAN.md' 'Phase 2 PL batch must cross-reference BOOTSTRAP_PLAN.md template'
assert_contains "$CONTENT" 'SEMANTICS.md' 'PL batches must cross-reference SEMANTICS.md template'

# state field writes documented.
assert_contains "$CONTENT" 'state.decisions.impl_strategy' 'Phase 2 PL batch must persist impl_strategy under state.decisions'
assert_contains "$CONTENT" 'state.decisions.host_runtime' 'Phase 2 PL batch must persist host_runtime under state.decisions'
assert_contains "$CONTENT" 'state.decisions.paradigm' 'Phase 3 PL batch must persist paradigm under state.decisions'
assert_contains "$CONTENT" 'state.decisions.type_system' 'Phase 3 PL batch must persist type_system under state.decisions'

test_summary
