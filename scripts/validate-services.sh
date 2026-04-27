#!/usr/bin/env bash
# Validates every services/*.md frontmatter against schema/service.schema.json.
# Emits a GitHub Actions error annotation per failing file, then exits non-zero
# at the end. We do NOT exit on first failure so reviewers see all problems
# in a single CI run.
set -euo pipefail
shopt -s nullglob

fail=0
for f in services/*.md; do
  # yq pulls the YAML frontmatter only, dropping the markdown body.
  yq --front-matter=extract '.' "$f" -o=json > /tmp/fm.json
  if ! npx -y ajv-cli@5 validate \
        -s schema/service.schema.json \
        -d /tmp/fm.json \
        --strict=false; then
    echo "::error file=$f::Frontmatter failed schema validation"
    fail=1
  fi
done

exit "$fail"
