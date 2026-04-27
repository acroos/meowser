# Meowser

**service-CATalog-super-lite** — a fork-able repo that auto-updates a markdown service catalog whenever a tracked repo merges a PR, and audits itself daily for drift. All LLM work runs via [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) inside GitHub Actions. No servers, no SDKs, no language runtimes beyond what's already on the runner.

**Fork it and follow [`docs/adoption.md`](docs/adoption.md).**

---

## How it works

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
                                                  │   on schedule (daily, matrix):      │
                                                  │     claude-code-action              │
                                                  │     • prompt = prompts/reconcile.md │
                                                  │     • clones target repo            │
                                                  │     • opens PR if drift found       │
                                                  │                                     │
                                                  │   on pull_request (services/**):    │
                                                  │     validate.yml                    │
                                                  │       yq + ajv-cli vs schema        │
                                                  └─────────────────────────────────────┘
```

See [`docs/architecture.md`](docs/architecture.md) for a full walkthrough of each flow.

---

## Quickstart

1. **Fork this repo.**
2. Add `ANTHROPIC_API_KEY` as a repository secret (Settings → Secrets and variables → Actions).
3. Follow [`docs/adoption.md`](docs/adoption.md) to wire up your first tracked repo.
4. Optionally run the demo: [`docs/demo.md`](docs/demo.md).

---

## Configuring the agent

All tunable knobs are GitHub repository **Variables** (Settings → Secrets and variables → Actions → Variables). Secrets are separate.

### Variables

| Variable | Default | Workflow | Purpose |
| --- | --- | --- | --- |
| `MEOWSER_MODEL` | `claude-sonnet-4-6` | `on-dispatch-update.yml` | Model for the hot-path update agent |
| `MEOWSER_MAX_TURNS` | `12` | `on-dispatch-update.yml` | Caps tool-call iterations for the update agent |
| `MEOWSER_RECONCILE_MODEL` | `claude-opus-4-7` | `reconcile.yml` | Model for the daily audit agent |
| `MEOWSER_RECONCILE_MAX_TURNS` | `30` | `reconcile.yml` | Higher ceiling for reconciliation (explores cloned repos) |

### Secrets

| Secret | Set in | Purpose |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | meowser repo | Auth for `claude-code-action` |
| `MEOWSER_DISPATCH_TOKEN` | each tracked repo | Fine-grained PAT used by the tracked-repo workflow to POST to meowser's `/dispatches` |

---

## Production caveats

- **Cost:** Each dispatch or reconcile job consumes Anthropic API tokens. A single update on a small diff typically costs a few cents. Monitor via the Anthropic console; set billing alerts.
- **Infinite-loop risk:** Do not add meowser itself to `tracked-repos.yml`. A change to meowser would trigger a dispatch that edits meowser, which would trigger another dispatch, and so on.
- **LLM accuracy:** The agent may invent topics or misread a diff. The `validate` CI check catches schema violations, but prose accuracy requires human review. Branch protection (require review + passing checks) is strongly recommended for production use.
- **Slow runs on large diffs:** The diff is truncated to 50 KB by the tracked-repo workflow. Very large refactors may produce incomplete context; the agent will note this in the PR description.
- **Reconciliation at scale:** The daily reconcile fans out one job per tracked repo. Past ~20 repos, consider staggering runs (e.g., a subset per day) to manage cost and runner concurrency.

---

## Demo

See [`meowser-demo-service`](https://github.com/your-github-handle/meowser-demo-service) and [`docs/demo.md`](docs/demo.md).
