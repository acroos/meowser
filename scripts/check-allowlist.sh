#!/usr/bin/env bash
# Misconfiguration trap and cost cap. NOT a security control — see SECURITY.md.
# Exits non-zero if the dispatching repo isn't listed in tracked-repos.yml.
set -euo pipefail

: "${DISPATCH_REPO:?DISPATCH_REPO must be set (the client_payload.repo value)}"

if ! yq -e '.repos[].name | select(. == strenv(DISPATCH_REPO))' tracked-repos.yml >/dev/null; then
  echo "::error::Repo '$DISPATCH_REPO' is not in tracked-repos.yml — refusing to act."
  exit 1
fi
