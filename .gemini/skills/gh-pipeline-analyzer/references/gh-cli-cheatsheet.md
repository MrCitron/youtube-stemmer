# GitHub CLI Cheatsheet for Workflows

## Runs
- `gh run list`: List recent runs.
- `gh run list --status failure`: List only failed runs.
- `gh run view <run-id>`: View status of a specific run.
- `gh run view <run-id> --log`: View logs for a run.
- `gh run view <run-id> --log --job <job-name>`: View logs for a specific job.
- `gh run rerun <run-id>`: Rerun a failed run.

## Workflows
- `gh workflow list`: List all workflows.
- `gh workflow view <workflow-id>`: View status of a workflow.
- `gh workflow run <workflow-id>`: Trigger a workflow manually (workflow_dispatch).

## Common Flags
- `--limit 1`: Show only the most recent item.
- `--json`: Output in JSON format (useful with `--jq`).
- `--jq`: Filter JSON output using jq expressions.
