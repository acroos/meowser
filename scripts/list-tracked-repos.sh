#!/usr/bin/env bash
# Builds the job matrix for the scheduled reconcile workflow: one matrix
# entry per repo in tracked-repos.yml, so the daily audit runs each repo
# in its own parallel job. Output is written to $GITHUB_OUTPUT for the
# next workflow step to consume.
set -euo pipefail

: "${GITHUB_OUTPUT:?must be set (run under GitHub Actions)}"

matrix=$(yq -o=json '{"include": [.repos[] | {"repo": .name}]}' tracked-repos.yml)
echo "matrix=${matrix}" >> "$GITHUB_OUTPUT"
