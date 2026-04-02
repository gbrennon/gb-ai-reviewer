#!/bin/bash
set -euo pipefail

SCRIPTS_DIR=/home/gbrennon/Documents/repos/gbrennon/ai-review-template/scripts

source "$SCRIPTS_DIR/lib/check-env.sh"

test_check_env_all_defined() {
  export VAR1=value1 VAR2=value2 VAR3=value3
  check_required_vars VAR1 VAR2 VAR3
  assert_true true
}

test_check_env_single_missing() {
  export VAR1=value1
  (check_required_vars VAR1 VAR2 > /dev/null 2>&1)
  assert_false return 0
}

test_check_env_multiple_missing() {
  export VAR1=value1
  (check_required_vars VAR1 VAR2 VAR3 > /dev/null 2>&1)
  assert_false return 0
}

test_check_env_empty_string() {
  export VAR1=""
  (check_required_vars VAR1 > /dev/null 2>&1)
  assert_false return 0
}

test_check_env_all_missing() {
  unset VAR1 VAR2 VAR3
  (check_required_vars VAR1 VAR2 VAR3 > /dev/null 2>&1)
  assert_false return 0
}

test_check_env_single_var() {
  export VAR1=value1
  check_required_vars VAR1
  assert_true true
}

test_check_env_two_vars() {
  export VAR1=value1 VAR2=value2
  check_required_vars VAR1 VAR2
  assert_true true
}

test_check_env_five_vars() {
  export VAR1=a VAR2=b VAR3=c VAR4=d VAR5=e
  check_required_vars VAR1 VAR2 VAR3 VAR4 VAR5
  assert_true true
}

test_check_env_unset_in_middle() {
  export VAR1=value1 VAR2=value2 VAR3=value3
  unset VAR2
  (check_required_vars VAR1 VAR2 VAR3 > /dev/null 2>&1)
  assert_false return 0
}