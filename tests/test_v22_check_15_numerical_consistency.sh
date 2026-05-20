#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Tests for check_15_numerical_consistency.py (Sketch B, check ID B15, WARNING).
#
# Covers bug #10 from the v2.1.5 md2pdf live test: aggressive performance
# targets (cold_start=0.5s against baseline=3.0s) were written into state
# without any stretch_disclaimer, so downstream readers treated them as firm
# commitments. The check surfaces such gaps loudly without blocking Phase 5.
#
# Truth-table covered here:
#   - bad fixture (aggressive-perf-target)               -> WARNING fail naming cold_start_seconds_max
#   - clean-bundle (no decisions key)                    -> INFO pass "no performance_targets"
#   - healthy: reasonable targets (ratio > 0.7)          -> WARNING pass
#   - aggressive WITH top-level stretch_disclaimer       -> WARNING pass
#   - aggressive WITH per-key disclaimer                 -> WARNING pass
#   - mixed: 2 targets, one aggressive one not           -> WARNING fail listing only the aggressive
#   - no performance_targets at all                      -> INFO pass
#   - performance_targets present but no matching pairs  -> INFO pass (pair_count=0)
#   - no decisions.architecture key                      -> INFO pass
#   - bare '_max' key (e.g. p95_latency_max)             -> uses '<base>_typical' baseline strategy
#   - '_target' key suffix                               -> handled identically to '_max'
#   - state.json missing                                 -> INFO pass (deferred)
#   - malformed state.json                               -> INFO pass (deferred)
#   - state.json root is array                           -> INFO pass (deferred)
#   - boolean target value (e.g. true)                   -> skipped, not numeric
#   - zero or negative baseline                          -> skipped (no meaningful ratio)
#   - top-level field check (id, severity, check, etc.)
#   - JSON validity loop over every output

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_15_numerical_consistency.py"
assert_file_exists "$CHECK" "check_15 must exist"
assert_executable "$CHECK" "check_15 must be executable"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_15 fully"
  test_summary
  exit 0
fi

# (1) Bad fixture: cold_start_seconds_max=0.5 vs baseline.cold_start_typical_seconds=3.0
#     → ratio 0.17 → aggressive, no disclaimer → WARNING fail.
#     warm_start_seconds_max=0.5 vs baseline=0.4 → ratio 1.25 → not aggressive,
#     should NOT appear in detail.
RESULT_BAD=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/aggressive-perf-target")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
CHECK_NAME_BAD=$(echo "$RESULT_BAD" | jq -r .check)
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$PASSED_BAD" "false" "aggressive-perf-target fixture must FAIL"
assert_eq "$SEVERITY_BAD" "WARNING" "severity must be WARNING"
assert_eq "$ID_BAD" "B15" "id must be B15"
assert_eq "$CHECK_NAME_BAD" "numerical_consistency" "check name must be numerical_consistency"
assert_contains "$DETAIL_BAD" "cold_start_seconds_max" "detail must name aggressive target key"
assert_contains "$DETAIL_BAD" "baseline=3.0" "detail must include baseline value 3.0"
assert_contains "$DETAIL_BAD" "ratio=0.17" "detail must include computed ratio 0.17"
assert_contains "$DETAIL_BAD" "1 aggressive target" "detail must report count=1 (warm_start excluded)"
assert_not_contains "$DETAIL_BAD" "warm_start_seconds_max" "warm_start (ratio 1.25) must NOT appear"
assert_contains "$REMEDIATION_BAD" "stretch_disclaimer" "remediation must reference stretch_disclaimer"
assert_eq "$AUTOFIX_BAD" "false" "requires human judgement; auto_fixable=false"

# (2) Clean-bundle: state.json = {"phase":"complete"}. No performance_targets.
#     Expected INFO pass "no performance_targets".
RESULT_CLEAN=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_eq "$PASSED_CLEAN" "true" "clean-bundle (no decisions) must PASS"
assert_eq "$SEVERITY_CLEAN" "INFO" "clean-bundle severity must be INFO"
assert_contains "$DETAIL_CLEAN" "no performance_targets" "clean-bundle detail must mention 'no performance_targets'"

# (3) Healthy: reasonable targets (ratio > 0.7) → WARNING pass.
#     cold_start_seconds_max=2.5 vs baseline=3.0 → ratio 0.83 (17% improvement, reasonable).
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs"
cat > "$HEALTHY_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "cold_start_seconds_max": 2.5,
        "warm_start_seconds_max": 0.35,
        "baseline": {
          "cold_start_typical_seconds": 3.0,
          "warm_start_typical_seconds": 0.4
        }
      }
    }
  }
}
EOF
RESULT_HEALTHY=$(python3 "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_eq "$PASSED_HEALTHY" "true" "healthy (ratios > 0.7) must PASS"
assert_eq "$SEVERITY_HEALTHY" "WARNING" "healthy severity must be WARNING"
assert_contains "$DETAIL_HEALTHY" "2 target/baseline pair(s) reasonable" "healthy detail must report count=2"
rm -rf "$HEALTHY_TMP"

# (4) Aggressive WITH top-level stretch_disclaimer → WARNING pass.
DISCLAIM_TOP_TMP=$(mktemp -d)
mkdir -p "$DISCLAIM_TOP_TMP/docs"
cat > "$DISCLAIM_TOP_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "stretch_disclaimer": "all targets are aspirational; firm SLO is baseline-equivalent",
        "cold_start_seconds_max": 0.5,
        "baseline": {
          "cold_start_typical_seconds": 3.0
        }
      }
    }
  }
}
EOF
RESULT_DISCLAIM_TOP=$(python3 "$CHECK" "$DISCLAIM_TOP_TMP")
PASSED_DISCLAIM_TOP=$(echo "$RESULT_DISCLAIM_TOP" | jq -r .passed)
DETAIL_DISCLAIM_TOP=$(echo "$RESULT_DISCLAIM_TOP" | jq -r .detail)
assert_eq "$PASSED_DISCLAIM_TOP" "true" "aggressive WITH top-level disclaimer must PASS"
assert_contains "$DETAIL_DISCLAIM_TOP" "1 target/baseline pair(s) reasonable" "disclaimer detail must report count=1"
rm -rf "$DISCLAIM_TOP_TMP"

# (5) Aggressive WITH per-key disclaimer → WARNING pass.
DISCLAIM_KEY_TMP=$(mktemp -d)
mkdir -p "$DISCLAIM_KEY_TMP/docs"
cat > "$DISCLAIM_KEY_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "cold_start_seconds_max": 0.5,
        "cold_start_seconds_max_stretch_disclaimer": "this is an aspirational target — firm SLO is 2.0s",
        "baseline": {
          "cold_start_typical_seconds": 3.0
        }
      }
    }
  }
}
EOF
RESULT_DISCLAIM_KEY=$(python3 "$CHECK" "$DISCLAIM_KEY_TMP")
PASSED_DISCLAIM_KEY=$(echo "$RESULT_DISCLAIM_KEY" | jq -r .passed)
DETAIL_DISCLAIM_KEY=$(echo "$RESULT_DISCLAIM_KEY" | jq -r .detail)
assert_eq "$PASSED_DISCLAIM_KEY" "true" "aggressive WITH per-key disclaimer must PASS"
assert_contains "$DETAIL_DISCLAIM_KEY" "1 target/baseline pair(s)" "per-key disclaimer detail must report count=1"
rm -rf "$DISCLAIM_KEY_TMP"

# (6) Mixed: 2 targets, one aggressive one not. Only the aggressive should
#     appear in the fail detail.
MIXED_TMP=$(mktemp -d)
mkdir -p "$MIXED_TMP/docs"
cat > "$MIXED_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "cold_start_seconds_max": 0.3,
        "warm_start_seconds_max": 0.35,
        "baseline": {
          "cold_start_typical_seconds": 3.0,
          "warm_start_typical_seconds": 0.4
        }
      }
    }
  }
}
EOF
RESULT_MIXED=$(python3 "$CHECK" "$MIXED_TMP")
PASSED_MIXED=$(echo "$RESULT_MIXED" | jq -r .passed)
DETAIL_MIXED=$(echo "$RESULT_MIXED" | jq -r .detail)
assert_eq "$PASSED_MIXED" "false" "mixed (one aggressive) must FAIL"
assert_contains "$DETAIL_MIXED" "cold_start_seconds_max" "mixed-fail must name cold_start"
assert_not_contains "$DETAIL_MIXED" "warm_start_seconds_max" "warm_start (ratio 0.875) must NOT appear"
assert_contains "$DETAIL_MIXED" "1 aggressive target" "mixed-fail must report count=1"
rm -rf "$MIXED_TMP"

# (7) No performance_targets at all → INFO pass.
NOPT_TMP=$(mktemp -d)
mkdir -p "$NOPT_TMP/docs"
cat > "$NOPT_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "language": "rust"
    }
  }
}
EOF
RESULT_NOPT=$(python3 "$CHECK" "$NOPT_TMP")
PASSED_NOPT=$(echo "$RESULT_NOPT" | jq -r .passed)
SEVERITY_NOPT=$(echo "$RESULT_NOPT" | jq -r .severity)
DETAIL_NOPT=$(echo "$RESULT_NOPT" | jq -r .detail)
assert_eq "$PASSED_NOPT" "true" "no performance_targets must PASS"
assert_eq "$SEVERITY_NOPT" "INFO" "no-perf-targets severity must be INFO"
assert_contains "$DETAIL_NOPT" "no performance_targets" "no-perf-targets detail correct"
rm -rf "$NOPT_TMP"

# (8) performance_targets exists but no matching baseline pairs → INFO pass.
NOPAIRS_TMP=$(mktemp -d)
mkdir -p "$NOPAIRS_TMP/docs"
cat > "$NOPAIRS_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "cold_start_seconds_max": 0.5,
        "baseline": {
          "unrelated_field_typical": 99
        }
      }
    }
  }
}
EOF
RESULT_NOPAIRS=$(python3 "$CHECK" "$NOPAIRS_TMP")
PASSED_NOPAIRS=$(echo "$RESULT_NOPAIRS" | jq -r .passed)
SEVERITY_NOPAIRS=$(echo "$RESULT_NOPAIRS" | jq -r .severity)
DETAIL_NOPAIRS=$(echo "$RESULT_NOPAIRS" | jq -r .detail)
assert_eq "$PASSED_NOPAIRS" "true" "no detectable pairs must PASS"
assert_eq "$SEVERITY_NOPAIRS" "INFO" "no-pairs severity must be INFO"
assert_contains "$DETAIL_NOPAIRS" "no target/baseline pairs detected" "no-pairs detail correct"
rm -rf "$NOPAIRS_TMP"

# (9) No decisions.architecture key → INFO pass "no performance_targets".
NOARCH_TMP=$(mktemp -d)
mkdir -p "$NOARCH_TMP/docs"
cat > "$NOARCH_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "tech_stack": {"language": "rust"}
  }
}
EOF
RESULT_NOARCH=$(python3 "$CHECK" "$NOARCH_TMP")
PASSED_NOARCH=$(echo "$RESULT_NOARCH" | jq -r .passed)
DETAIL_NOARCH=$(echo "$RESULT_NOARCH" | jq -r .detail)
assert_eq "$PASSED_NOARCH" "true" "no decisions.architecture must PASS"
assert_contains "$DETAIL_NOARCH" "no performance_targets" "no-arch detail correct"
rm -rf "$NOARCH_TMP"

# (10) Bare '_max' key with '<base>_typical' baseline. Confirms strategy 2.
BAREMAX_TMP=$(mktemp -d)
mkdir -p "$BAREMAX_TMP/docs"
cat > "$BAREMAX_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "p95_latency_max": 30,
        "baseline": {
          "p95_latency_typical": 200
        }
      }
    }
  }
}
EOF
RESULT_BAREMAX=$(python3 "$CHECK" "$BAREMAX_TMP")
PASSED_BAREMAX=$(echo "$RESULT_BAREMAX" | jq -r .passed)
DETAIL_BAREMAX=$(echo "$RESULT_BAREMAX" | jq -r .detail)
assert_eq "$PASSED_BAREMAX" "false" "bare _max (30 vs 200 = 0.15 ratio) must FAIL"
assert_contains "$DETAIL_BAREMAX" "p95_latency_max" "bare-_max detail must name p95_latency_max"
assert_contains "$DETAIL_BAREMAX" "baseline=200" "bare-_max detail must include baseline=200"
rm -rf "$BAREMAX_TMP"

# (11) '_target' suffix handled identically to '_max'.
TARGETSUFFIX_TMP=$(mktemp -d)
mkdir -p "$TARGETSUFFIX_TMP/docs"
cat > "$TARGETSUFFIX_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "throughput_target": 10,
        "baseline": {
          "throughput_typical": 100
        }
      }
    }
  }
}
EOF
RESULT_TARGETSUFFIX=$(python3 "$CHECK" "$TARGETSUFFIX_TMP")
PASSED_TARGETSUFFIX=$(echo "$RESULT_TARGETSUFFIX" | jq -r .passed)
DETAIL_TARGETSUFFIX=$(echo "$RESULT_TARGETSUFFIX" | jq -r .detail)
assert_eq "$PASSED_TARGETSUFFIX" "false" "_target suffix (10 vs 100 = 0.1 ratio) must FAIL"
assert_contains "$DETAIL_TARGETSUFFIX" "throughput_target" "_target detail must name throughput_target"
rm -rf "$TARGETSUFFIX_TMP"

# (12) No state.json: INFO pass (deferred to json_valid).
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(python3 "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
DETAIL_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .detail)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS"
assert_eq "$SEVERITY_NOSTATE" "INFO" "no-state severity must be INFO"
assert_contains "$DETAIL_NOSTATE" "missing" "no-state detail must mention missing"
rm -rf "$NOSTATE_TMP"

# (13) Malformed state.json: INFO pass (deferred).
MALFORMED_TMP=$(mktemp -d)
mkdir -p "$MALFORMED_TMP/docs"
printf '{this is not json\n' > "$MALFORMED_TMP/docs/_architect_state.json"
RESULT_MALFORMED=$(python3 "$CHECK" "$MALFORMED_TMP")
PASSED_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .passed)
SEVERITY_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .severity)
DETAIL_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .detail)
assert_eq "$PASSED_MALFORMED" "true" "malformed state.json must PASS (deferred)"
assert_eq "$SEVERITY_MALFORMED" "INFO" "malformed-state severity must be INFO"
assert_contains "$DETAIL_MALFORMED" "deferred" "malformed detail must mention deferral"
rm -rf "$MALFORMED_TMP"

# (14) Non-object state.json root (array): INFO pass (deferred).
NONOBJ_TMP=$(mktemp -d)
mkdir -p "$NONOBJ_TMP/docs"
printf '[1,2,3]\n' > "$NONOBJ_TMP/docs/_architect_state.json"
RESULT_NONOBJ=$(python3 "$CHECK" "$NONOBJ_TMP")
PASSED_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .passed)
SEVERITY_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .severity)
DETAIL_NONOBJ=$(echo "$RESULT_NONOBJ" | jq -r .detail)
assert_eq "$PASSED_NONOBJ" "true" "non-object state.json root must PASS (deferred)"
assert_eq "$SEVERITY_NONOBJ" "INFO" "non-object root severity must be INFO"
assert_contains "$DETAIL_NONOBJ" "not an object" "non-object detail must mention 'not an object'"
rm -rf "$NONOBJ_TMP"

# (15) Boolean target value (a "flag_max" set to true): skipped as non-numeric.
BOOL_TMP=$(mktemp -d)
mkdir -p "$BOOL_TMP/docs"
cat > "$BOOL_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "feature_flag_max": true,
        "baseline": {
          "feature_flag_typical": false
        }
      }
    }
  }
}
EOF
RESULT_BOOL=$(python3 "$CHECK" "$BOOL_TMP")
PASSED_BOOL=$(echo "$RESULT_BOOL" | jq -r .passed)
DETAIL_BOOL=$(echo "$RESULT_BOOL" | jq -r .detail)
assert_eq "$PASSED_BOOL" "true" "boolean target must be skipped (non-numeric)"
assert_contains "$DETAIL_BOOL" "no target/baseline pairs detected" "boolean target detail correct"
rm -rf "$BOOL_TMP"

# (16) Zero baseline: skipped (no meaningful ratio).
ZEROBASELINE_TMP=$(mktemp -d)
mkdir -p "$ZEROBASELINE_TMP/docs"
cat > "$ZEROBASELINE_TMP/docs/_architect_state.json" <<'EOF'
{
  "decisions": {
    "architecture": {
      "performance_targets": {
        "errors_max": 0,
        "baseline": {
          "errors_typical": 0
        }
      }
    }
  }
}
EOF
RESULT_ZEROBASELINE=$(python3 "$CHECK" "$ZEROBASELINE_TMP")
PASSED_ZEROBASELINE=$(echo "$RESULT_ZEROBASELINE" | jq -r .passed)
DETAIL_ZEROBASELINE=$(echo "$RESULT_ZEROBASELINE" | jq -r .detail)
assert_eq "$PASSED_ZEROBASELINE" "true" "zero baseline must be skipped"
assert_contains "$DETAIL_ZEROBASELINE" "no target/baseline pairs detected" "zero-baseline detail correct"
rm -rf "$ZEROBASELINE_TMP"

# (17) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" "$RESULT_DISCLAIM_TOP" \
         "$RESULT_DISCLAIM_KEY" "$RESULT_MIXED" "$RESULT_NOPT" "$RESULT_NOPAIRS" \
         "$RESULT_NOARCH" "$RESULT_BAREMAX" "$RESULT_TARGETSUFFIX" \
         "$RESULT_NOSTATE" "$RESULT_MALFORMED" "$RESULT_NONOBJ" "$RESULT_BOOL" \
         "$RESULT_ZEROBASELINE"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
