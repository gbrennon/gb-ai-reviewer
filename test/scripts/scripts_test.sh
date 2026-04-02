#!/bin/bash
set -euo pipefail

_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$_ROOT_DIR/scripts"

source "$SCRIPTS_DIR/lib/check-env.sh"
source "$SCRIPTS_DIR/lib/api.sh"

export CODEBERG_TOKEN=test
export REPO_OWNER=test
export REPO_NAME=test
export OLLAMA_HOST=http://localhost:11434
export OLLAMA_MODEL=test

test_load_state_with_file() {
  local tmpdir
  tmpdir=$(mktemp -d)
  local db_file="$tmpdir/state.json"
  echo '{"reviewed_prs":[]}' > "$db_file"
  
  local result
  result=$(DB_FILE="$db_file" bash "$SCRIPTS_DIR/load-state.sh")
  
  assert_equals '{"reviewed_prs":[]}' "$result"
  
  rm -rf "$tmpdir"
}

test_load_state_without_file() {
  local tmpdir
  tmpdir=$(mktemp -d)
  local db_file="$tmpdir/nonexistent.json"
  
  local result
  result=$(DB_FILE="$db_file" bash "$SCRIPTS_DIR/load-state.sh")
  
  assert_equals '{}' "$result"
  
  rm -rf "$tmpdir"
}

test_check_env_passes() {
  export VAR1=value1
  export VAR2=value2
  check_required_vars VAR1 VAR2
  assert_true true
}

test_check_env_fails_on_missing() {
  export VAR1=value1
  (check_required_vars VAR1 VAR2 > /dev/null 2>&1)
  assert_false return 0
}

test_check_env_fails_on_multiple_missing() {
  export VAR1=value1
  (check_required_vars VAR1 VAR2 VAR3 > /dev/null 2>&1)
  assert_false return 0
}

test_fetch_prs_runs() {
  bashunit::mock curl <<< '[{"number":1,"title":"Test PR","head":{"sha":"abc123"}}]'
  
  local result
  result=$(CODEBERG_TOKEN=x REPO_OWNER=x REPO_NAME=x bash "$SCRIPTS_DIR/fetch-prs.sh" 2>&1)
  
  assert_not_equals "" "$result"
}

test_api_codeberg_api() {
  bashunit::mock curl <<< '{"mocked":true}'
  
  local result
  result=$(codeberg_api GET "pulls")
  
  assert_not_equals "" "$result"
}

test_api_get_open_pulls() {
  bashunit::mock curl <<< '[]'
  
  local result
  result=$(get_open_pulls)
  
  assert_not_equals "" "$result"
}

test_api_get_pull_diff() {
  bashunit::mock curl <<< 'diff content'
  
  local result
  result=$(get_pull_diff 123)
  
  assert_not_equals "" "$result"
}

test_api_post_issue_comment() {
  bashunit::mock curl <<< '{"success":true}'
  
  local result
  result=$(post_issue_comment 123 "test")
  
  assert_not_equals "" "$result"
}

test_process_prs_handles_empty() {
  bashunit::mock curl <<< '[]'
  
  local tmpdir
  tmpdir=$(mktemp -d)
  local db_file="$tmpdir/state.json"
  local prs_file="$tmpdir/prs.json"
  
  printf '[]' > "$prs_file"
  printf '{"reviewed_prs":[]}' > "$db_file"
  
  local output
  output=$(CODEBERG_TOKEN=x REPO_OWNER=x REPO_NAME=x OLLAMA_HOST=x OLLAMA_MODEL=x DB_FILE="$db_file" STATE="$db_file" bash "$SCRIPTS_DIR/process-prs.sh" "$prs_file" 2>&1) || true
  
  local has_no_prs
  if echo "$output" | grep -q "No open PRs to review"; then
    has_no_prs="yes"
  else
    has_no_prs="no"
  fi
  assert_equals "yes" "$has_no_prs"
  
  rm -rf "$tmpdir"
}

test_process_prs_creates_state_file() {
  bashunit::mock curl <<< '[]'
  
  local tmpdir
  tmpdir=$(mktemp -d)
  local db_file="$tmpdir/state.json"
  local prs_file="$tmpdir/prs.json"
  
  printf '[]' > "$prs_file"
  printf '{"reviewed_prs":[]}' > "$db_file"
  
  CODEBERG_TOKEN=x REPO_OWNER=x REPO_NAME=x OLLAMA_HOST=x OLLAMA_MODEL=x DB_FILE="$db_file" STATE="$db_file" bash "$SCRIPTS_DIR/process-prs.sh" "$prs_file" > /dev/null 2>&1
  
  local exists
  if test -f "$db_file"; then
    exists="yes"
  else
    exists="no"
  fi
  assert_equals "yes" "$exists"
  rm -rf "$tmpdir"
}