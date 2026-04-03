# Mirror Codeberg Repo to Local Forgejo

This guide explains how to mirror a Codeberg repository to your local Forgejo instance so the AI reviewer can access PRs.

## Prerequisites

- Access to local Forgejo at `http://localhost:1234`
- Admin or user permissions to create repositories

## Option 1: Via Local Forgejo UI (Recommended)

### Step 1: Create Mirrored Repository

1. Go to your local Forgejo: `http://localhost:1234`
2. Click **+** → **New Repository**
3. Fill in:
   - **Repository Name**: `my-repo` (or your preferred name)
   - **Repository Owner**: your user/org
   - Check **Mirror repository**
4. In **Clone URL**, enter your Codeberg repository:
   ```
   https://codeberg.org/<username>/<repo-name>.git
   ```
5. Set **Sync Interval** to your preference (default: hourly)
6. Click **Create Repository**

### Step 2: Trigger Initial Sync

1. After creation, go to repo **Settings** → **Repository** (or **Mirroring**)
2. Click **Sync Now** to trigger immediate sync
3. Wait a few minutes for initial clone

### Step 3: Verify Sync

1. On repo main page, check the last updated time displayed
2. Go to **Settings** → **Repository** → **Mirroring** to see sync status

## Option 2: Via Forgejo API

```bash
# Replace with your values
FORGEJO_URL="http://localhost:1234"
ADMIN_USER="your-username"
ADMIN_TOKEN="your-admin-token"
CODEBERG_REPO="https://codeberg.org/username/repo.git"
REPO_NAME="repo-name"

curl -X POST "$FORGEJO_URL/api/v1/user/repos" \
  -H "Authorization: token $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$REPO_NAME"'",
    "mirror": true,
    "repo_url": "'"$CODEBERG_REPO"'",
    "sync_interval": 3600
  }'
```

## Syncing PRs from Codeberg

By default, mirrors sync commits and branches. **Pull requests** are synced when:

1. **Enable PR mirroring** in Codeberg repo settings:
   - Go to Codeberg → Your Repo → Settings → Repository
   - Enable "Mirror repository" (if not already)
   - Note: Codeberg push mirroring requires your local Forgejo to be publicly reachable

2. **Alternative**: The AI reviewer fetches PR data directly from Codeberg API (see next section)

## Important: How AI Reviewer Accesses PRs

The AI reviewer workflow fetches PR data from **Codeberg API directly**, not from the local mirror. This ensures:

- Always gets latest PR state
- Can post comments back to Codeberg PR
- No dependency on mirror syncing PRs

You still need to mirror the repo to keep local commits in sync, but PR review happens via Codeberg API.

## Configuring Repo in AI Reviewer

After mirroring, configure the AI reviewer (see [AI Reviewer Setup](02-ai-reviewer.md)):

- `REPO_OWNER`: The Codeberg username/org
- `REPO_NAME`: The Codeberg repo name

## Troubleshooting

- **Sync not working**: Check that the Clone URL is correct and accessible
- **PRs not appearing**: PRs may not auto-sync via pull mirroring; the workflow fetches from Codeberg API instead
- **Permission denied**: Ensure your Forgejo user has repo creation permissions

For more help, see [Troubleshooting](03-troubleshooting.md).