# Meowser — Agent Guide

Meowser is a fork-able service catalog repo that auto-updates itself from changes in tracked repos and audits itself on a schedule. All LLM work runs via `anthropics/claude-code-action` inside GitHub Actions. **No application code** — logic lives in markdown prompts, YAML workflows, JSON Schema, and single-purpose bash scripts.

## Directory map

```
meowser/
├── docs/
│   ├── idea.md                  # original project idea
│   ├── plan.md                  # phased build plan with concrete designs
│   ├── architecture.md          # dispatch + reconcile flows (Phase 7)
│   ├── adoption.md              # step-by-step for adding a tracked repo (Phase 3)
│   ├── service-spec.md          # annotated catalog entry example
│   ├── demo.md                  # demo walkthrough (Phase 6)
│   └── decisions/               # decision records (one per locked design choice)
├── services/                    # one .md per catalogued service; populated by the agent
├── schema/
│   └── service.schema.json      # JSON Schema for services/*.md frontmatter
├── prompts/
│   ├── update.md                # system prompt for dispatch-driven updates (Phase 2)
│   └── reconcile.md             # system prompt for scheduled audits (Phase 4)
├── scripts/                     # single-purpose bash scripts called by workflows
├── examples/                    # drop-in files for tracked repos to copy (Phase 3)
├── tracked-repos.yml            # allowlist of repos meowser accepts dispatches from (Phase 2)
└── .github/workflows/           # CI/CD workflows
```

## Where the catalog lives

`services/` — one markdown file per service, named `<kebab-case-service-name>.md`. The YAML frontmatter is validated against `schema/service.schema.json`. The body is free-form prose for LLM consumption.

## How the prompts work

`prompts/update.md` and `prompts/reconcile.md` are loaded at workflow runtime by `scripts/load-prompt.sh` and passed verbatim to `claude-code-action`. Iterate on prompts locally with `claude` before pushing.

## Decision records

Each locked design choice has a record under `docs/decisions/`. Check the relevant record before proposing changes in that area.

| Decision | File | Use when… |
| --- | --- | --- |
| Storage format (markdown + frontmatter, one file per service) | `docs/decisions/2026-04-26-storage-format.md` | Changing how catalog entries are structured or stored |
| Trigger mechanism (`repository_dispatch`) | `docs/decisions/2026-04-26-trigger-mechanism.md` | Changing how tracked repos signal meowser |
| LLM execution (`claude-code-action`) | `docs/decisions/2026-04-26-llm-execution.md` | Changing the LLM provider, action, or how prompts are passed |
| Auth model (fine-grained PAT + GITHUB_TOKEN) | `docs/decisions/2026-04-26-auth-model.md` | Changing how tracked repos or meowser itself authenticates |
| Validation (JSON Schema + yq/ajv-cli) | `docs/decisions/2026-04-26-validation.md` | Changing frontmatter structure or the CI validation approach |
| Demo strategy (sibling repo) | `docs/decisions/2026-04-26-demo-strategy.md` | Setting up or modifying the end-to-end demo |

## Pre-push checks

Run these before pushing any branch that touches `services/` or `schema/`:

```bash
./scripts/validate-services.sh
```

Run this before pushing any branch that touches `scripts/` or `examples/*.sh`:

```bash
shellcheck scripts/*.sh examples/*.sh
```
