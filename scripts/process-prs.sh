#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/check-env.sh"
source "$SCRIPT_DIR/lib/api.sh"

check_required_vars CODEBERG_TOKEN REPO_OWNER REPO_NAME DB_FILE STATE OLLAMA_HOST OLLAMA_MODEL

mkdir -p "$(dirname "$DB_FILE")"

if [ -z "$STATE" ] || [ "$STATE" = "{}" ]; then
    STATE='{"reviewed_prs":[]}'
fi

PRS_JSON="$1"
if [ -z "$PRS_JSON" ] || [ ! -f "$PRS_JSON" ]; then
    echo "Error: PRS_JSON file not provided or not found" >&2
    exit 1
fi

PR_COUNT=$(cat "$PRS_JSON" | jq 'length')
echo "Found $PR_COUNT open PRs"

if [ "$PR_COUNT" = "0" ]; then
    echo "No open PRs to review"
    exit 0
fi

REVIEWED_PRS=$(echo "$STATE" | jq '.reviewed_prs // []')
NEW_REVIEWED_PRS="[]"

for i in $(seq 0 $((PR_COUNT - 1))); do
    PR=$(cat "$PRS_JSON" | jq -r ".[$i]")
    PR_NUMBER=$(echo "$PR" | jq -r '.number')
    PR_TITLE=$(echo "$PR" | jq -r '.title')
    COMMIT_SHA=$(echo "$PR" | jq -r '.head.sha')

    echo "Checking PR #$PR_NUMBER: $PR_TITLE"
    echo "  Commit SHA: $COMMIT_SHA"

    PREV_REVIEW=$(echo "$REVIEWED_PRS" | jq -r ".[] | select(.number == $PR_NUMBER)")

    if [ "$PREV_REVIEW" != "null" ]; then
        PREV_SHA=$(echo "$PREV_REVIEW" | jq -r '.commit_sha')
        if [ "$PREV_SHA" = "$COMMIT_SHA" ]; then
            echo "  Skipping - no new commits since last review"
            NEW_REVIEWED_PRS=$(echo "$NEW_REVIEWED_PRS" | jq ". + [$PREV_REVIEW]")
            continue
        fi
    fi

    echo "  Getting diff for review..."

    DIFF=$(get_pull_diff "$PR_NUMBER")

    if [ $(echo "$DIFF" | wc -c) -lt 100 ]; then
        echo "  Error getting diff: $DIFF"
        continue
    fi

    echo "  Sending to Ollama for review..."
    OLLAMA_RESPONSE=$(curl -s -X POST "$OLLAMA_HOST/api/generate" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"prompt\": \"You are a code reviewer. Review the following git diff and provide constructive feedback. Focus on bugs, security issues, code quality, and potential improvements. Output in markdown format with these sections:\n\n## Issues Found\n- (line/section) - issue description\n\n## Suggestions\n- (line/section) - suggestion\n\n## Summary\nOne sentence overall assessment.\n\nDIFF:\n$DIFF\",
            \"stream\": false
          }")

    REVIEW_BODY=$(echo "$OLLAMA_RESPONSE" | jq -r '.response // empty')

    if [ -z "$REVIEW_BODY" ]; then
        echo "  Error: No response from Ollama"
        continue
    fi

    echo "  Posting review comment..."
    COMMENT_BODY="## AI Code Review\n\n$REVIEW_BODY\n\n---\n*Review by $OLLAMA_MODEL via Forgejo Actions*"

    post_issue_comment "$PR_NUMBER" "$COMMENT_BODY"

    echo "  Review posted successfully"

    NEW_ENTRY=$(jq -n \
        --arg number "$PR_NUMBER" \
        --arg sha "$COMMIT_SHA" \
        --arg title "$PR_TITLE" \
        '{number: ($number | tonumber), commit_sha: $sha, title: $title, reviewed_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")}')
    NEW_REVIEWED_PRS=$(echo "$NEW_REVIEWED_PRS" | jq ". + [$NEW_ENTRY]")
done

echo "$NEW_REVIEWED_PRS" > /tmp/reviewed_prs.json
jq -n "{reviewed_prs: $(cat /tmp/reviewed_prs.json)}" > "$DB_FILE"

echo "State saved to $DB_FILE"
cat "$DB_FILE"
