#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"

SKILL_CONTENT=$(cat "$SKILL")
SCHEMA_CONTENT=$(cat "$SCHEMA")

# SKILL.md description list must mention programming language design
assert_contains "$SKILL_CONTENT" 'programming language' 'SKILL.md description must list programming language design as a project type'

# state-schema.md must document all 6 sub_types
for st in general_purpose_language domain_specific_language query_language configuration_language educational_language transpiler_target; do
  assert_contains "$SCHEMA_CONTENT" "$st" "state-schema must document sub_type: $st"
done

# state-schema.md must document all 4 decision axes
for axis in impl_strategy host_runtime paradigm type_system; do
  assert_contains "$SCHEMA_CONTENT" "$axis" "state-schema must document decision axis: $axis"
done

# host_runtime enum: all 14 research-informed values
for hr in llvm mlir cranelift qbe truffle jvm beam wasm wasm_component js_host python_embedded rust_host native_no_runtime custom_vm; do
  assert_contains "$SCHEMA_CONTENT" "$hr" "host_runtime enum must include: $hr"
done

# impl_strategy enum: 5 values
for is in tree_walking_interpreter bytecode_vm native_compiler transpiler hosted_embedded; do
  assert_contains "$SCHEMA_CONTENT" "$is" "impl_strategy enum must include: $is"
done

# paradigm enum: 6 values
for pd in imperative functional logic oop multi_paradigm data_oriented; do
  assert_contains "$SCHEMA_CONTENT" "$pd" "paradigm enum must include: $pd"
done

# type_system enum: 6 values
for ts in static_strong static_gradual dynamic dependent affine_linear none_untyped; do
  assert_contains "$SCHEMA_CONTENT" "$ts" "type_system enum must include: $ts"
done

# v2.3 marker present (so future readers know what added these)
assert_contains "$SCHEMA_CONTENT" 'v2.3' 'state-schema entries must be marked with v2.3 attribution'

test_summary
