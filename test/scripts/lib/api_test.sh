#!/bin/bash
set -euo pipefail

SCRIPTS_DIR=/home/gbrennon/Documents/repos/gbrennon/ai-review-template/scripts

source "$SCRIPTS_DIR/lib/api.sh"

export CODEBERG_TOKEN=test_token
export REPO_OWNER=test_owner
export REPO_NAME=test_repo

test_codeberg_api_get_mocks_curl() {
  bashunit::mock curl <<< '{"mocked": true}'
  
  local result
  result=$(codeberg_api GET "pulls")
  
  assert_not_equals "" "$result"
}

test_codeberg_api_post_mocks_curl() {
  bashunit::mock curl <<< '{"success": true}'
  
  local result
  result=$(codeberg_api POST "issues/1/comments" -d '{"body":"test"}')
  
  assert_not_equals "" "$result"
}

test_codeberg_api_default_mocks_curl() {
  bashunit::mock curl <<< '{"default": true}'
  
  local result
  result=$(codeberg_api "pulls")
  
  assert_not_equals "" "$result"
}

test_codeberg_api_with_extra_args_mocks_curl() {
  bashunit::mock curl <<< '{"extra": true}'
  
  local result
  result=$(codeberg_api GET "pulls" -H "X-Test: value")
  
  assert_not_equals "" "$result"
}

test_codeberg_api_put_mocks_curl() {
  bashunit::mock curl <<< '{"put": true}'
  
  local result
  result=$(codeberg_api PUT "repos/contents")
  
  assert_not_equals "" "$result"
}

test_codeberg_api_delete_mocks_curl() {
  bashunit::mock curl <<< '{"delete": true}'
  
  local result
  result=$(codeberg_api DELETE "repos/contents")
  
  assert_not_equals "" "$result"
}

test_get_open_pulls_mocks_curl() {
  bashunit::mock curl <<< '[{"number":1}]'
  
  local result
  result=$(get_open_pulls)
  
  assert_not_equals "" "$result"
}

test_get_pull_diff_mocks_curl() {
  bashunit::mock curl <<< 'diff content'
  
  local result
  result=$(get_pull_diff 123)
  
  assert_not_equals "" "$result"
}

test_get_pull_diff_different_pr() {
  bashunit::mock curl <<< 'diff2'
  
  local result
  result=$(get_pull_diff 456)
  
  assert_not_equals "" "$result"
}

test_post_issue_comment_mocks_curl() {
  bashunit::mock curl <<< '{"id":1}'
  
  local result
  result=$(post_issue_comment 123 "test")
  
  assert_not_equals "" "$result"
}

test_post_issue_comment_different() {
  bashunit::mock curl <<< '{"id":2}'
  
  local result
  result=$(post_issue_comment 789 "comment")
  
  assert_not_equals "" "$result"
}

test_codeberg_api_spy_verifies_call() {
  bashunit::spy curl
  
  codeberg_api GET "pulls"
  
  assert_have_been_called curl
}

test_get_open_pulls_spy_verifies_call() {
  bashunit::spy curl
  
  get_open_pulls
  
  assert_have_been_called curl
}

test_get_pull_diff_spy_verifies_call() {
  bashunit::spy curl
  
  get_pull_diff 123
  
  assert_have_been_called curl
}

test_post_issue_comment_spy_verifies_call() {
  bashunit::spy curl
  
  post_issue_comment 123 "test"
  
  assert_have_been_called curl
}

test_multiple_api_calls_spy() {
  bashunit::spy curl
  
  get_open_pulls
  get_pull_diff 1
  post_issue_comment 2 "test"
  
  assert_have_been_called_times 3 curl
}