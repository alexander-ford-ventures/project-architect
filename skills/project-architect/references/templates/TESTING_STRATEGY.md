---
template_name: TESTING_STRATEGY
generate_when: "decisions.scale != \"hobby\" OR decisions.project.type != \"library\""
required_decisions: [testing.unit_framework]
optional_decisions: [testing.integration_framework, testing.e2e_framework, testing.visual_framework, testing.coverage_target]
depends_on: []
revision_triggers: [testing.unit_framework, testing.integration_framework, testing.e2e_framework, testing.coverage_target]
---

# Testing Strategy: {{project_name}}

## Testing Philosophy
One paragraph: how this project balances unit / integration / e2e (test pyramid vs trophy vs honeycomb), the role of TDD, and any explicit non-goals.

## Testing Stack
Table: test type | tool | coverage target. Rows for unit, integration, e2e, visual / snapshot, performance, accessibility, and contract testing as applicable.

## Test Structure
Directory convention (`__tests__/` vs co-located vs separate top-level), filename pattern, fixture/mocks location, and helper-utility conventions.

## Key Testing Scenarios
Bulleted list of critical user paths that must always be tested (signup, checkout, primary domain workflow, etc.) regardless of refactors.

## Test Data Strategy
How test data is created (factories / fixtures / Faker / record-replay), database isolation (per-test / per-suite / shared), and any deterministic-seed rules.

## CI Integration
How tests run in CI (matrix, sharding, parallelization), retry policy for flakes, and reporting (annotations, summaries, screenshots, traces).

## Performance Testing
Tools (k6 / Artillery / Lighthouse CI / autocannon), key scenarios, target thresholds, and where results are archived. Skip this section if no performance testing is planned.

## Revision Log
(none yet)
