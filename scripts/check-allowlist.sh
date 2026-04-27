#!/usr/bin/env bash
# Fails the workflow if the repo that sent this dispatch isn't listed in
# tracked-repos.yml. This is a sanity check to catch typos and runaway costs,
# not a security boundary — see SECURITY.md for the real auth model.
set -euo pipefail

: "${DISPATCH_REPO:?DISPATCH_REPO must be set (the client_payload.repo value)}"

if ! yq -e '.repos[].name | select(. == strenv(DISPATCH_REPO))' tracked-repos.yml >/dev/null; then
  echo "::error::Repo '$DISPATCH_REPO' is not in tracked-repos.yml — refusing to act."
  exit 1
fi
