# AI Reviewer Setup

Automated AI code review using local Ollama. Runs on local Forgejo Actions, posts reviews to Codeberg PRs.

## Prerequisites

### 1. Ollama Running

Ensure Ollama is accessible. If using the gb-ollama-container:

```bash
cd ~/repos/gbrennon/gb-ollama-container
docker compose up -d
```

The default host is `http://host.containers.internal:11434` (for podman).

### 2. Pull the Model

```bash
ollama pull deepseek-coder:6.7b
```

Or use a different model and update `OLLAMA_MODEL` in workflow.

### 3. Codeberg Personal Access Token

1. Go to Codeberg → Settings → Applications → Generate new token
2. Scopes: `repo` (full repo access)
3. Copy the token

## Configuration

### Secrets (Forgejo Repo Settings → Secrets)

Add these secrets to your local Forgejo repository:

| Secret | Description | Example |
|--------|-------------|---------|
| `CODEBERG_TOKEN` | Codeberg PAT with `repo` scope | `b3b...xxx` |
| `REPO_OWNER` | Codeberg user or org | `myusername` |
| `REPO_NAME` | Codeberg repository name | `my-project` |

### Environment Variables (Optional)

Configure via workflow inputs or default values:

| Variable | Description | Default |
|----------|-------------|---------|
| `POLLING_CRON` | Cron expression for polling | `*/10 * * * *` (every 10 min) |
| `OLLAMA_HOST` | Ollama API endpoint | `http://host.containers.internal:11434` |
| `OLLAMA_MODEL` | Model to use | `deepseek-coder:6.7b` |
| `DB_PATH` | Path to JSON state file | `/data/reviewed_prs.json` |

## Workflow Behavior

### 1. Trigger
- Runs automatically every 10 minutes (configurable via `POLLING_CRON`)
- Also runs on `push` events to trigger immediate review

### 2. Fetch Open PRs
- Calls Codeberg API: `GET /repos/{owner}/{repo}/pulls?state=open`

### 3. Check for New Commits
- Loads reviewed PRs from JSON state file (`DB_PATH`)
- For each open PR:
  - Gets PR's latest commit SHA
  - If SHA matches last reviewed → skip (no new commits)
  - If SHA changed or new → proceed to review

### 4. Get Diff & Review
- Fetches PR diff: `GET /repos/{owner}/{repo}/pulls/{number}.diff`
- Sends diff to Ollama with review prompt
- Parses response

### 5. Post Review Comment
- Posts comment to Codeberg PR: `POST /repos/{owner}/{repo}/issues/{number}/comments`
- Updates JSON state file with:
  ```json
  {
    "pr_number": 5,
    "reviewed_at": "2024-01-15T10:30:00Z",
    "commit_sha": "abc123..."
  }
  ```

### 6. Idempotency
- Same PR with same commit SHA → skipped
- New commit on existing PR → re-reviewed
- New PR → reviewed

## Idempotency & State Management

The workflow maintains a JSON "database" at `DB_PATH` (default: `/data/reviewed_prs.json`):

```json
{
  "repo": "my-project",
  "owner": "myusername",
  "reviewed_prs": [
    {
      "number": 1,
      "commit_sha": "abc123def",
      "reviewed_at": "2024-01-15T10:30:00Z"
    },
    {
      "number": 2,
      "commit_sha": "xyz789uvw",
      "reviewed_at": "2024-01-15T11:00:00Z"
    }
  ]
}
```

**Logic:**
1. Load existing state from JSON file
2. For each open PR, compare current `head.sha` with stored `commit_sha`
3. Match → no new commits, skip
4. Mismatch or new → run review, update state

**Note:** The JSON file is stored in the runner's workspace. For persistence across runs, ensure the runner uses a mounted volume.

## Customization

### Change Polling Interval

Edit `POLLING_CRON` in workflow:

```yaml
env:
  POLLING_CRON: '*/30 * * * *'  # Every 30 minutes
```

### Change Model

```yaml
env:
  OLLAMA_MODEL: 'codellama:7b'
```

### Add Review Criteria

Edit the `prompt` section in workflow.yml to customize what the AI focuses on.

## Testing

1. Create a test PR on Codeberg
2. Wait for next poll (or push to trigger workflow)
3. Check PR comments for AI review
4. Verify state file updates: look for `reviewed_prs.json` in runner logs

## Troubleshooting

See [Troubleshooting](03-troubleshooting.md) for common issues.