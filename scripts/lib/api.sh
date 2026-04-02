#!/bin/bash
set -euo pipefail

codeberg_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    shift 2
    
    curl -s -X "$method" \
        -H "Authorization: token $CODEBERG_TOKEN" \
        -H "Content-Type: application/json" \
        "https://codeberg.org/api/v1/repos/$REPO_OWNER/$REPO_NAME/$endpoint" \
        "$@"
}

get_open_pulls() {
    codeberg_api GET "pulls?state=open"
}

get_pull_diff() {
    local pr_number="$1"
    codeberg_api GET "pulls/$pr_number.diff"
}

post_issue_comment() {
    local pr_number="$1"
    local body="$2"
    
    codeberg_api POST "issues/$pr_number/comments" \
        -d "{\"body\": \"$body\"}"
}