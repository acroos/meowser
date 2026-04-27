#!/usr/bin/env bash
# Checks that the YAML frontmatter of every services/*.md file matches
# schema/service.schema.json.
#
# Each failure becomes a GitHub Actions error annotation (so it shows up
# inline on the PR), and we keep going after the first failure so a single
# CI run reports every broken file at once. Exit code is non-zero if any
# file failed.
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
