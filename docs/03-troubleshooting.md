# Troubleshooting

Common issues with the AI reviewer workflow.

## Workflow Not Running

### Check if workflow is enabled
1. Go to local Forgejo → Repo → Settings → Actions
2. Enable Actions if needed
3. Verify workflow file is in `.forgejo/workflows/`

### Check runner status
```bash
docker compose logs forgejo-runner
```

## Ollama Connection Failed

### Error: `Connection refused` or `Cannot connect to Ollama`

**Cause:** Ollama not reachable from runner container

**Solutions:**

1. **For podman**, use `host.containers.internal`:
   ```yaml
   env:
     OLLAMA_HOST: http://host.containers.internal:11434
   ```

2. **For docker**, use `host.docker.internal`:
   ```yaml
   env:
     OLLAMA_HOST: http://host.docker.internal:11434
   ```

3. **Verify Ollama is running**:
   ```bash
   curl http://localhost:11434/api/tags
   ```

4. **Check container network**:
   - Ensure runner can reach the host
   - For podman, add `--network=host` to runner or use podman-specific DNS

## Model Not Found

### Error: `model 'deepseek-coder:6.7b' not found`

**Solution:**
```bash
# Pull the model on the host running Ollama
ollama pull deepseek-coder:6.7b

# Or update workflow to use available model
env:
  OLLAMA_MODEL: 'codellama:7b'
```

## Codeberg API Errors

### Error: `401 Unauthorized` or `403 Forbidden`

**Cause:** Invalid or insufficient `CODEBERG_TOKEN`

**Solutions:**

1. Verify token has `repo` scope
2. Check token hasn't expired
3. Ensure token is added as secret in Forgejo repo

### Error: `404 Not Found`

**Cause:** Incorrect `REPO_OWNER` or `REPO_NAME`

**Verify:**
- `REPO_OWNER` matches Codeberg username/org exactly
- `REPO_NAME` matches repo name exactly (case-sensitive)

## Duplicate Reviews

### AI reviews same PR multiple times

**Cause:** State file not persisting between runs

**Solutions:**

1. Ensure runner has persistent volume mounted
2. Check `DB_PATH` points to mounted volume path
3. Verify workflow writes to the file (check logs)

### State file path not persisting

Default `/data/` may be ephemeral. Ensure in docker-compose:

```yaml
forgejo-runner:
  volumes:
    - forgejo_runner_data:/data  # Already configured
```

The workflow should use `/data/` for state.

## PR Skipped Unexpectedly

### No new commits but review wanted

**Check:**
1. Look at workflow logs for skip reason
2. Verify commit SHA in API response
3. Check JSON state file for stored SHA

### Force re-review

Manually edit the JSON state file to remove the PR entry, or delete the file (will re-review all PRs).

## Workflow Takes Too Long

### Slow model inference

**Options:**
1. Use smaller model: `deepseek-coder:6.7b` → `codellama:7b`
2. Limit diff size: Add filter to skip large PRs
3. Adjust timeout in workflow

### Too many PRs

Add limit to process only first N PRs:

```yaml
- name: Process PRs
  run: |
    # Process only first 5 PRs
    echo "$PRS" | jq '.[:5]'
```

## Debugging Tips

### View workflow logs

1. Go to local Forgejo → Repo → Actions
2. Click on latest run
3. Expand each step to see output

### Add debug output

Edit workflow.yml, add:

```yaml
- name: Debug
  run: |
    echo "PRs: $PRS"
    echo "State: $STATE"
```

### Test API manually

```bash
# Test Codeberg API
curl -H "Authorization: token $CODEBERG_TOKEN" \
  "https://codeberg.org/api/v1/repos/OWNER/REPO/pulls"

# Test Ollama
curl http://localhost:11434/api/tags
```

## Getting Help

If issues persist:

1. Check workflow logs for specific error messages
2. Verify all secrets are correctly configured
3. Ensure Ollama is accessible from runner container
4. Test APIs manually with curl