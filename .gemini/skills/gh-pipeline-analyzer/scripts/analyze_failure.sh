#!/bin/bash

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed."
    exit 1
fi

# Get the latest failed run
RUN_ID=$(gh run list --status failure --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "No failed runs found."
    exit 0
fi

echo "Analyzing failed run: $RUN_ID"

# List failed jobs
FAILED_JOBS=$(gh run view $RUN_ID --json jobs --jq '.jobs[] | select(.conclusion=="failure") | .name')

echo "Failed jobs:"
echo "$FAILED_JOBS"
echo "-----------------------------------"

# Extract logs for each failed job and look for common error patterns
for JOB in $FAILED_JOBS; do
    echo "### Logs for Job: $JOB ###"
    gh run view $RUN_ID --log --job "$JOB" | grep -iE "error|fail|exception|fatal|error:" | tail -n 20
    echo "-----------------------------------"
done
