#!/usr/bin/env bash
# Posts a `meowser-update` repository_dispatch at the meowser repo with the
# diff and PR metadata for a just-merged PR. Reads PR fields from
# $GITHUB_EVENT_PATH (set by GitHub Actions) so we never round-trip strings
# through YAML interpolation.
set -euo pipefail

EVENT="${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH must be set (run under GitHub Actions)}"
: "${GITHUB_REPOSITORY:?must be set}"
: "${GH_TOKEN:?MEOWSER_DISPATCH_TOKEN must be exposed as GH_TOKEN}"
: "${MEOWSER_OWNER:?must be set to the owner of the meowser repo}"
DIFF_BYTES="${DIFF_BYTES:-50000}"

# Pull PR fields from the event JSON. Using jq here means strings are handled
# safely regardless of their content.
PR_NUMBER=$(jq -r '.pull_request.number'           "$EVENT")
PR_TITLE=$( jq -r '.pull_request.title'            "$EVENT")
PR_BODY=$(  jq -r '.pull_request.body // ""'       "$EVENT")
ACTOR=$(    jq -r '.pull_request.user.login'       "$EVENT")
BASE_SHA=$( jq -r '.pull_request.base.sha'         "$EVENT")
HEAD_SHA=$( jq -r '.pull_request.head.sha'         "$EVENT")
MERGE_SHA=$(jq -r '.pull_request.merge_commit_sha' "$EVENT")

# Compute the actual delta that landed on the default branch. base..merge
# works for plain merges, squash merges, and rebase merges alike.
CHANGED_FILES=$(git diff --name-only "$BASE_SHA" "$MERGE_SHA" | jq -R . | jq -sc .)
DIFF=$(git diff "$BASE_SHA" "$MERGE_SHA" | head -c "$DIFF_BYTES")

# Assemble the dispatch payload with jq so all string escaping is correct.
jq -n \
  --arg repo             "$GITHUB_REPOSITORY" \
  --argjson pr_number    "$PR_NUMBER" \
  --arg pr_title         "$PR_TITLE" \
  --arg pr_body          "$PR_BODY" \
  --arg merge_commit_sha "$MERGE_SHA" \
  --arg base_sha         "$BASE_SHA" \
  --arg head_sha         "$HEAD_SHA" \
  --arg actor            "$ACTOR" \
  --arg diff             "$DIFF" \
  --argjson files        "$CHANGED_FILES" \
  '{
    event_type: "meowser-update",
    client_payload: {
      repo: $repo,
      pr_number: $pr_number,
      pr_title: $pr_title,
      pr_body: $pr_body,
      merge_commit_sha: $merge_commit_sha,
      base_sha: $base_sha,
      head_sha: $head_sha,
      actor: $actor,
      diff: $diff,
      changed_files: $files
    }
  }' \
| gh api -X POST "repos/${MEOWSER_OWNER}/meowser/dispatches" --input -
