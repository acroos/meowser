**status:** "accepted"

---

# JSON Schema + `yq`/`ajv-cli` to validate service frontmatter in CI

## Context and Problem Statement

The LLM agent edits `services/*.md` frontmatter. Without validation, hallucinated fields or malformed YAML could silently corrupt the catalog. We need a CI check that catches these before merge.

## Considered Options

* JSON Schema validated by `yq` (frontmatter extraction) + `ajv-cli` (schema check) in a shell script
* Custom validation script (Python/Node) with hand-written field checks
* No automated validation; rely on human PR review

## Decision Outcome

Chosen option: "JSON Schema + `yq`/`ajv-cli`", because both tools are available on GitHub-hosted `ubuntu-latest` runners without any install step (`npx -y ajv-cli@5` fetches on demand), the schema is a standard artifact other tools can consume, and the entire validation block is ~5 lines of shell — keeping the "no application code" constraint.

### Consequences

* Good, because the schema is machine-readable and reusable by editors, linters, and future tooling.
* Good, because the shell block is small, auditable, and doesn't require a language runtime.
* Good, because CI catches LLM hallucinations (invented fields, wrong types) before merge.
* Bad, because `ajv-cli` must be fetched via `npx` — adds a few seconds and a network dependency to CI runs.
* Bad, because schema validation checks structure, not prose accuracy — human review is still required for content correctness.
