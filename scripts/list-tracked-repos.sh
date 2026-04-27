#!/usr/bin/env bash
# Emits the GitHub Actions matrix JSON for reconcile.yml. Each tracked repo
# becomes its own matrix entry so the daily audit fans out one job per repo.
set -euo pipefail

: "${GITHUB_OUTPUT:?must be set (run under GitHub Actions)}"

matrix=$(yq -o=json '{"include": [.repos[] | {"repo": .name}]}' tracked-repos.yml)
echo "matrix=${matrix}" >> "$GITHUB_OUTPUT"
