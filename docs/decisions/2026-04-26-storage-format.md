**status:** "accepted"

---

# Markdown + YAML frontmatter per service, one file in `services/`

## Context and Problem Statement

Meowser needs to store structured metadata (OpenAPI location, events, dependencies, auth) alongside human/LLM-readable prose for each service. The format must be readable by both LLMs and deterministic tooling (schema validation, grep).

## Considered Options

* Markdown with YAML frontmatter, one file per service under `services/`
* Pure YAML/JSON registry file listing all services
* Database-backed catalog (e.g., Backstage)

## Decision Outcome

Chosen option: "Markdown with YAML frontmatter, one file per service under `services/`", because it satisfies both consumers: frontmatter gives deterministic, schema-validatable fields while the markdown body gives LLMs narrative context to answer open-ended questions. One file per service keeps diffs small and focused.

### Consequences

* Good, because frontmatter can be validated with `yq` + JSON Schema without any runtime.
* Good, because LLMs can read the full file and answer both structured and ambiguous queries.
* Good, because per-file diffs are easy to review and attribute.
* Bad, because YAML frontmatter in markdown files isn't a universal standard — tooling must know to strip the body before parsing.
