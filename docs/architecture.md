# Architecture

Meowser has two active flows (update and reconcile) and one passive flow (validation). All three run inside GitHub Actions with no application servers.

## Flows

```
┌──────────────────────────┐                      ┌─────────────────────────────────────┐
│   Tracked repo           │                      │   Meowser repo                      │
│   (e.g. orders-api)      │                      │                                     │
│                          │                      │   on repository_dispatch            │
│   on push to main:       │                      │     │                               │
│     notify-meowser.yml   │  POST /dispatches    │     ▼ allowlist gate                │
│       computes diff      │ ───────────────────► │   claude-code-action                │
│       POSTs payload      │  (PAT-authenticated) │     • prompt = prompts/update.md    │
│                          │                      │     • inputs = client_payload       │
│                          │                      │     • edits services/*.md           │
│                          │                      │     • opens PR (cc @actor)          │
└──────────────────────────┘                      │                                     │
                                                  │   on schedule (daily, matrix per    │
                                                  │   tracked repo):                    │
                                                  │     │                               │
                                                  │     ▼                               │
                                                  │   claude-code-action                │
                                                  │     • prompt = prompts/reconcile.md │
                                                  │     • clones target repo            │
                                                  │     • opens PR if drift found       │
                                                  │                                     │
                                                  │   on pull_request (services/**):    │
                                                  │     validate.yml                    │
                                                  │       yq + ajv-cli vs schema        │
                                                  └─────────────────────────────────────┘
```

## Update flow (hot path)

Triggered by a `repository_dispatch` event POSTed from a tracked repo after a PR merges.

1. `on-dispatch-update.yml` receives the event.
2. `scripts/check-allowlist.sh` gates on `tracked-repos.yml` — rejects unknown repos immediately.
3. `scripts/load-prompt.sh` reads `prompts/update.md` into a workflow output.
4. `anthropics/claude-code-action` runs with the prompt + `client_payload` (diff, PR metadata).
5. The agent edits `services/*.md` and opens a PR, mentioning the PR author.

## Reconcile flow (daily audit)

Runs on a schedule (08:00 UTC) and on `workflow_dispatch`.

1. `reconcile.yml` calls `scripts/list-tracked-repos.sh` to build a matrix from `tracked-repos.yml`.
2. One job per tracked repo fans out.
3. Each job runs `claude-code-action` with `prompts/reconcile.md` and the target repo name.
4. The agent shallow-clones the live repo, checks for drift, and opens a PR only if corrections are needed.

## Validation flow (PR check)

Runs on every PR that touches `services/**` or `schema/**`.

1. `validate.yml` calls `scripts/validate-services.sh`.
2. The script extracts YAML frontmatter from each `services/*.md` with `yq` and validates it against `schema/service.schema.json` using `ajv-cli`.
3. CI fails if any file has invalid frontmatter, blocking merge until fixed.

## Key files

| File | Role |
| --- | --- |
| `tracked-repos.yml` | Single source of truth for which repos meowser trusts and reconciles |
| `schema/service.schema.json` | Contract for all catalog entry frontmatter |
| `prompts/update.md` | System prompt for the update agent |
| `prompts/reconcile.md` | System prompt for the reconcile agent |
| `scripts/` | Glue between workflows and tools; no business logic |
