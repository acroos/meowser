# Meowser — Build Plan

## Goal

A fork-able service catalog repo that auto-updates itself from changes in tracked repos and audits itself on a schedule. All LLM work runs via [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) inside GitHub Actions. **No application code** — the repo's logic is markdown prompts, YAML workflows, JSON Schema, and a small set of single-purpose `bash` scripts that exist purely to be readable and testable glue for the workflows. No language runtime to install beyond what's already on the GitHub-hosted runner (`bash`, `jq`, `yq`, `git`, `gh`, `npx`).

## Core decisions (locked)

| Decision | Choice | Rationale |
| --- | --- | --- |
| Storage format | Markdown + YAML frontmatter under `services/`, one file per service | Per `idea.md`; balances determinism (frontmatter) with LLM-readable narrative (body) |
| Trigger | `repository_dispatch` from tracked repos → meowser workflow | Fork-friendly; no central server |
| LLM execution | `anthropics/claude-code-action@v1` | Removes the need for any Python/Node code, an Anthropic SDK wrapper, or our own PR-creation plumbing |
| Auth from tracked repo → meowser | Fine-grained PAT stored as a secret in each tracked repo | Simplest fork story |
| Auth meowser → meowser (PR creation) | Default workflow `GITHUB_TOKEN` | Default and zero-config; the action uses it automatically |
| LLM provider | Anthropic API via `ANTHROPIC_API_KEY` secret | Default and easiest to support; provider can be swapped later via the action's other auth modes |
| Default model & cost knobs | Surfaced as workflow `env` / repo Variables, not hard-coded | User asked for "easy to configure" |
| Validation | JSON Schema + `yq`/`ajv-cli` snippet in CI workflow | The single ~5-line shell block in the entire repo; catches LLM hallucinations before merge |
| Demo strategy | Separate sibling repo (`meowser-demo-service`) | User-selected; gives a realistic end-to-end demo |

Each of these gets its own decision record under `docs/decisions/` per the global decisions guide.

## Repo layout (target)

```
meowser/
├── README.md                          # Fork-and-go pitch + quickstart
├── AGENTS.md                          # Agent-facing repo guide, decision index, Pre-push checks
├── CLAUDE.md                          # Symlink → AGENTS.md
├── LICENSE                            # already present
├── .gitignore
├── docs/
│   ├── idea.md                        # moved from repo root
│   ├── plan.md                        # this file
│   ├── architecture.md                # how dispatch + reconcile flows work, with diagram
│   ├── adoption.md                    # step-by-step for adding a new tracked repo
│   ├── service-spec.md                # annotated example of the catalog format
│   ├── demo.md                        # how to run the demo
│   └── decisions/
│       ├── 2026-04-26-storage-format.md
│       ├── 2026-04-26-trigger-mechanism.md
│       ├── 2026-04-26-llm-execution.md
│       ├── 2026-04-26-auth-model.md
│       ├── 2026-04-26-validation.md
│       └── 2026-04-26-demo-strategy.md
├── services/
│   └── .gitkeep                       # populated over time by the agent
├── schema/
│   └── service.schema.json            # JSON Schema for the YAML frontmatter
├── prompts/
│   ├── update.md                      # system prompt for dispatch-driven updates
│   └── reconcile.md                   # system prompt for scheduled audits
├── scripts/
│   ├── check-allowlist.sh             # gate step in on-dispatch-update.yml
│   ├── load-prompt.sh                 # read prompts/<name>.md into a workflow output
│   ├── list-tracked-repos.sh          # emit reconcile.yml's matrix JSON
│   └── validate-services.sh           # validate every services/*.md against schema
├── tracked-repos.yml                  # allowlist of repos meowser will accept dispatches from
├── examples/
│   ├── tracked-repo-workflow.yml      # the workflow to copy into a tracked repo
│   └── notify-meowser.sh              # the script the workflow above calls
├── .github/
│   ├── workflows/
│   │   ├── on-dispatch-update.yml     # repository_dispatch handler
│   │   ├── reconcile.yml              # daily cron audit
│   │   ├── validate.yml               # PR check: schema validation
│   │   └── lint-scripts.yml           # PR check: shellcheck, only when scripts/** changes
│   └── PULL_REQUEST_TEMPLATE.md
```

Sibling repo (separate, created in Phase 6):

```
meowser-demo-service/
├── README.md                          # "fake service for demoing meowser"
├── openapi.yaml                       # something concrete to react to
├── events.yaml                        # event schema for the event-based example
├── src/                               # tiny stub app — just enough to look real
└── .github/workflows/notify-meowser.yml
```

## Phases

Each phase is independently mergeable. Order matters because later phases depend on earlier artifacts.

### Phase 0 — Decision records and meta scaffolding

**Why first:** the global guide requires decision records, and AGENTS.md/CLAUDE.md should reference them as they're written. Locking decisions on disk first prevents drift.

Deliverables:
- `docs/decisions/2026-04-26-storage-format.md`
- `docs/decisions/2026-04-26-trigger-mechanism.md`
- `docs/decisions/2026-04-26-llm-execution.md`
- `docs/decisions/2026-04-26-auth-model.md`
- `docs/decisions/2026-04-26-validation.md`
- `docs/decisions/2026-04-26-demo-strategy.md`
- `AGENTS.md` — agent-facing repo guide; indexes each decision with one-line context per global convention; will also hold the **`## Pre-push checks`** section once Phase 5 lands
- `CLAUDE.md` — symlink to `AGENTS.md` (`ln -s AGENTS.md CLAUDE.md`) so Claude Code and other AGENTS.md-aware tools share one source of truth
- `.gitignore` — minimal (macOS, editor noise)
- Move `idea.md` → `docs/idea.md`
- One commit per decision record per the global guide

### Phase 1 — Catalog format

The contract every later phase relies on.

Deliverables:
- `schema/service.schema.json` — full JSON Schema (see [Design § service.schema.json](#designservice-schemajson))
- `docs/service-spec.md` — annotated example using the schema (see [Design § Annotated service.md example](#designannotated-servicemd-example))
- `services/.gitkeep`

### Phase 2 — Update workflow (dispatch-driven, no code)

The hot path. Triggered when a tracked repo changes.

Deliverables:
- `prompts/update.md` — system prompt for incremental updates (see [Design § prompts/update.md](#designpromptsupdatemd))
- `scripts/check-allowlist.sh` (see [Design § scripts/check-allowlist.sh](#designscriptscheck-allowlistsh))
- `scripts/load-prompt.sh` — shared with Phase 4 (see [Design § scripts/load-prompt.sh](#designscriptsload-promptsh))
- `.github/workflows/on-dispatch-update.yml` — repository_dispatch handler with allowlist gate (see [Design § on-dispatch-update.yml](#designon-dispatch-updateyml))
- `tracked-repos.yml` — allowlist file (see [Design § tracked-repos.yml](#designtracked-reposyml))
- Repo Variables documented in README (see [Design § Repo Variables](#designrepo-variables))
- PR body must `@`-mention `${{ github.event.client_payload.actor }}` for informal review (the actor lives in the tracked repo, not necessarily a meowser collaborator, so we mention rather than `requestReviewers`)

### Phase 3 — Tracked-repo dispatch snippet

What downstream repos copy in.

Deliverables:
- `examples/tracked-repo-workflow.yml` — drop-in workflow that calls the script below (see [Design § examples/tracked-repo-workflow.yml](#designexamplestracked-repo-workflowyml))
- `examples/notify-meowser.sh` — the actual payload-building and dispatch logic (see [Design § examples/notify-meowser.sh](#designexamplesnotify-meowsersh))
- See also [Design § Dispatch payload shape](#designdispatch-payload-shape)
- `docs/adoption.md` — five-step adoption guide:
  1. Create a fine-grained PAT scoped only to the meowser repo with permissions `Metadata: Read` and `Contents: Read and Write` (the latter is what GitHub currently requires to call the `/dispatches` endpoint; re-verify against current GH docs when writing this guide)
  2. Add it to your tracked repo as `MEOWSER_DISPATCH_TOKEN`
  3. Copy `examples/tracked-repo-workflow.yml` into `.github/workflows/notify-meowser.yml` in your repo
  4. Open a PR against meowser adding your repo to `tracked-repos.yml`
  5. Push a change; watch the PR appear in meowser within ~2 minutes

### Phase 4 — Reconciliation workflow (scheduled, no code)

Counters drift; runs even when nothing has changed. **No PR is created when no drift is found** — the successful workflow run is itself the audit signal. `last_reconciled_at` is therefore only set/updated when the agent actually corrects something.

Deliverables:
- `prompts/reconcile.md` — system prompt for the audit agent (see [Design § prompts/reconcile.md](#designpromptsreconcilemd))
- `scripts/list-tracked-repos.sh` (see [Design § scripts/list-tracked-repos.sh](#designscriptslist-tracked-repossh))
- `.github/workflows/reconcile.yml` — daily cron + `workflow_dispatch`, matrix over `tracked-repos.yml` (see [Design § reconcile.yml](#designreconcileyml))

### Phase 5 — Validation workflow

Catches LLM hallucinations before merge. Tiny, but the only piece of "logic" in the whole repo.

Deliverables:
- `scripts/validate-services.sh` (see [Design § scripts/validate-services.sh](#designscriptsvalidate-servicessh))
- `.github/workflows/validate.yml` — workflow that calls the script (see [Design § validate.yml](#designvalidateyml))
- `.github/workflows/lint-scripts.yml` — shellcheck on `scripts/**` and `examples/*.sh`, gated by `paths:` so it only runs when those files change (see [Design § lint-scripts.yml](#designlint-scriptsyml))
- `tests/fixtures/_invalid.md` — deliberately broken fixture used by a one-shot acceptance test (run locally before merging the workflow)

### Phase 6 — Sibling demo repo

Lives at `github.com/<your-handle>/meowser-demo-service` (or wherever you choose).

Deliverables (in the sibling repo, not in meowser):
- A minimal but realistic stub service:
  - `openapi.yaml` describing 1–2 endpoints (e.g., `POST /widgets`, `GET /widgets/{id}`)
  - `events.yaml` describing 1 emitted event (e.g., `widget.created`)
  - `src/` with placeholder files (so the OpenAPI/events have something to "describe"; could be empty stubs)
- `README.md` linking back to meowser, explaining the demo's purpose
- `.github/workflows/notify-meowser.yml` — the snippet from Phase 3, configured

In meowser:
- `docs/demo.md` — script for the demo:
  1. Fork both repos
  2. Set up the secrets per `docs/adoption.md`
  3. Push a meaningful change to the demo repo (rename an endpoint, add an event field)
  4. Watch a PR appear in meowser within ~2 minutes
  5. Inspect the PR; merge if it looks right

### Phase 7 — Repo hygiene and meta files

What makes the repo presentable and pleasant to fork.

Deliverables:
- `README.md`:
  - One-paragraph pitch (lifted from `idea.md`)
  - "Fork it and follow `docs/adoption.md`"
  - Architecture ASCII diagram — see [Design § Architecture diagram](#designarchitecture-diagram)
  - Repo-Variables table — see [Design § Repo Variables](#designrepo-variables)
  - Link to demo repo
  - Production caveats (cost, monitoring, what to expect)
- `AGENTS.md` (single agent-facing doc; `CLAUDE.md` is a symlink to it from Phase 0):
  - Directory map
  - Where the catalog lives, how the prompts are structured
  - "Iterate on prompts in this repo with `claude` locally before pushing"
  - Decision-record index with one-line "use when…" hint per global convention
  - **`## Pre-push checks`** section per global convention — list the validate workflow's commands so the pull-request-creator agent runs them before pushing
- `.github/PULL_REQUEST_TEMPLATE.md`:
  - Distinguishes human PRs from agent PRs (agent PRs check: "diff matches the change", "frontmatter still validates", "topics still accurate", "body still readable")
- `SECURITY.md`:
  - How to revoke `MEOWSER_DISPATCH_TOKEN`
  - What the dispatch token can and cannot do
  - What to do if a malicious dispatch slips past the allowlist gate

### Phase 8 — Release readiness

- End-to-end smoke test: real PR in demo repo → real PR in meowser → schema validation green
- Tag `v0.1.0`
- Add a "production caveats" section to README (cost expectations, monitoring suggestions, known failure modes — e.g., infinite update loop if meowser ever tracks itself, LLM-invented topics that don't reflect reality, slow runs on large diffs)

## Concrete designs

These are the actual artifacts the phases produce, written down so we don't re-design them mid-build. Workflow YAML and prompts are *sketches*: the structure, control flow, and inputs/outputs are the design; final string-tuning happens during the phase itself.

### Design: `service.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/<owner>/meowser/schema/service.schema.json",
  "title": "Meowser Service Entry",
  "type": "object",
  "additionalProperties": false,
  "required": ["name", "repo", "topics", "dependencies"],
  "properties": {
    "name": {
      "type": "string",
      "description": "Human-readable service name. Should be unique across the catalog.",
      "minLength": 1
    },
    "repo": {
      "type": "string",
      "description": "GitHub repo in 'owner/name' format.",
      "pattern": "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$"
    },
    "topics": {
      "type": "array",
      "description": "Keywords describing functionality. Should include words a user might use in a prompt to find this service.",
      "items": { "type": "string", "minLength": 1 },
      "minItems": 1,
      "uniqueItems": true
    },
    "dependencies": {
      "type": "array",
      "description": "Other services in this catalog that this service depends on. Each entry is a 'name' from another service.md.",
      "items": { "type": "string", "minLength": 1 },
      "uniqueItems": true
    },
    "openapi": {
      "type": "string",
      "description": "URL or repo-relative path to the OpenAPI spec. Omit for non-HTTP services.",
      "format": "uri-reference"
    },
    "events": {
      "type": "array",
      "description": "Events this service emits or consumes. Omit if not event-driven.",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["topic", "direction"],
        "properties": {
          "topic": { "type": "string", "minLength": 1 },
          "direction": { "enum": ["emit", "consume"] },
          "payload_ref": {
            "type": "string",
            "description": "URL or repo-relative path to the payload schema."
          }
        }
      },
      "uniqueItems": true
    },
    "auth": {
      "type": "string",
      "description": "How other services authenticate to this one (e.g., 'mTLS', 'JWT via shared issuer', 'none / internal-only')."
    },
    "owners": {
      "type": "array",
      "description": "Team or person owners. Free-form (e.g., '@platform-team', 'jane@example.com').",
      "items": { "type": "string", "minLength": 1 },
      "uniqueItems": true
    },
    "slack_channel": {
      "type": "string",
      "description": "Primary Slack channel for this service.",
      "pattern": "^#[a-z0-9-]+$"
    },
    "last_reconciled_at": {
      "type": "string",
      "description": "ISO 8601 timestamp of the last reconciliation run that made a change to this entry. Absent if reconciliation has never modified this entry. Not set by the update flow.",
      "format": "date-time"
    }
  }
}
```

### Design: Annotated `service.md` example

This is what a real catalog entry looks like. Lives at `services/orders-api.md`.

````markdown
---
name: orders-api
repo: acme/orders-api
topics:
  - order processing
  - checkout
  - cart
  - inventory reservation
dependencies:
  - inventory-service
  - payments-api
openapi: https://github.com/acme/orders-api/blob/main/openapi.yaml
events:
  - topic: order.created
    direction: emit
    payload_ref: https://github.com/acme/orders-api/blob/main/events/order-created.schema.json
  - topic: payment.succeeded
    direction: consume
auth: JWT issued by acme-auth, validated against jwks.acme.internal
owners:
  - "@orders-team"
slack_channel: "#orders"
last_reconciled_at: "2026-04-26T12:00:00Z"
---

## What it does

Owns the order lifecycle: cart → checkout → reservation → fulfillment handoff. Emits `order.created` after a successful checkout for downstream services to react to.

## When to use it

- You need to create, update, or look up an order.
- You need to reserve inventory as part of a checkout.
- You want to listen for a new order.

## When not to use it

- You're looking for fulfillment status post-shipment — that's `fulfillment-api`.
- You need pre-checkout cart-only operations — those live in `cart-bff`.

## Common pitfalls

- `POST /orders` is not idempotent without an `Idempotency-Key` header; double-clicks will create duplicates.
- The `inventory-service` reservation is held for 15 minutes; long checkouts will release it.

## Auth

JWT issued by `acme-auth`. The `aud` claim must include `orders-api`. See `auth` in the frontmatter.

## Examples

```http
POST /orders
Authorization: Bearer <jwt>
Idempotency-Key: <uuid>
Content-Type: application/json

{ "items": [{ "sku": "ABC-123", "qty": 2 }], "customer_id": "cust_42" }
```
````

### Design: `tracked-repos.yml`

```yaml
# Allowlist of repos meowser will accept repository_dispatch events from.
# Adding a repo here doesn't require any code changes — workflows read this
# file at runtime to gate incoming events and to enumerate the reconcile matrix.
# A repo's catalog entries are discovered by the agent via the `repo:` field
# in each services/*.md frontmatter — there is no separate index to maintain.
repos:
  - name: acme/orders-api
  - name: acme/inventory-service
```

### Design: Dispatch payload shape

`client_payload` POSTed by tracked repos to `repos/<owner>/meowser/dispatches`:

```json
{
  "event_type": "meowser-update",
  "client_payload": {
    "repo": "acme/orders-api",
    "pr_number": 142,
    "pr_title": "Rename POST /checkout → POST /orders",
    "pr_body": "<PR description body, truncated>",
    "merge_commit_sha": "abc123def456",
    "base_sha": "fed987cba654",
    "head_sha": "111222333444",
    "actor": "alice",
    "changed_files": ["src/handlers/checkout.py", "openapi.yaml"],
    "diff": "<unified diff base_sha..merge_commit_sha, truncated to 50 KB by the tracked-repo workflow>"
  }
}
```

All fields are required. The trigger is always a merged PR (see [Design § examples/tracked-repo-workflow.yml](#designexamplestracked-repo-workflowyml)) — direct pushes to the default branch are intentionally not supported, since well-managed repos go through PR review and the PR carries richer context (title, body, author) than a raw commit.

### Design: `on-dispatch-update.yml`

```yaml
name: Update from tracked repo

on:
  repository_dispatch:
    types: [meowser-update]

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Allowlist gate
        env:
          DISPATCH_REPO: ${{ github.event.client_payload.repo }}
        run: ./scripts/check-allowlist.sh

      - id: load_prompt
        env:
          PROMPT_FILE: prompts/update.md
          OUTPUT_KEY: body
        run: ./scripts/load-prompt.sh

      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_args: |
            --model ${{ vars.MEOWSER_MODEL || 'claude-sonnet-4-6' }}
            --max-turns ${{ vars.MEOWSER_MAX_TURNS || '12' }}
            --allowedTools Edit,Read,Write,Glob,Grep
          prompt: |
            ${{ steps.load_prompt.outputs.body }}

            ## Change context

            - Source repo: ${{ github.event.client_payload.repo }}
            - PR: #${{ github.event.client_payload.pr_number }} — "${{ github.event.client_payload.pr_title }}"
            - PR author: @${{ github.event.client_payload.actor }}
            - Merge commit: ${{ github.event.client_payload.merge_commit_sha }}
            - Changed files: ${{ toJSON(github.event.client_payload.changed_files) }}

            ## PR description

            ${{ github.event.client_payload.pr_body }}

            ## Diff (base..merge)

            ```diff
            ${{ github.event.client_payload.diff }}
            ```

            When you open the PR, include this line in the body so the change author is notified:

            > cc @${{ github.event.client_payload.actor }} — catalog updates from acme/<repo>#${{ github.event.client_payload.pr_number }}.
```

### Design: `reconcile.yml`

```yaml
name: Daily reconciliation

on:
  schedule:
    - cron: '0 8 * * *'   # 08:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  enumerate:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.list.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
      - id: list
        run: ./scripts/list-tracked-repos.sh

  reconcile:
    needs: enumerate
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJSON(needs.enumerate.outputs.matrix) }}
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
      - id: load_prompt
        env:
          PROMPT_FILE: prompts/reconcile.md
          OUTPUT_KEY: body
        run: ./scripts/load-prompt.sh
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_args: |
            --model ${{ vars.MEOWSER_RECONCILE_MODEL || 'claude-opus-4-7' }}
            --max-turns ${{ vars.MEOWSER_RECONCILE_MAX_TURNS || '30' }}
            --allowedTools Edit,Read,Write,Glob,Grep,Bash
          prompt: |
            ${{ steps.load_prompt.outputs.body }}

            ## Target

            Reconcile the catalog entry for: ${{ matrix.repo }}
```

### Design: `validate.yml`

```yaml
name: Validate catalog

on:
  pull_request:
    paths:
      - 'services/**'
      - 'schema/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate every service.md frontmatter
        run: ./scripts/validate-services.sh
```

### Design: `lint-scripts.yml`

```yaml
name: Lint scripts

on:
  pull_request:
    paths:
      - 'scripts/**'
      - 'examples/*.sh'

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # shellcheck is preinstalled on ubuntu-latest runners.
      - run: shellcheck scripts/*.sh examples/*.sh
```

### Design: `scripts/check-allowlist.sh`

```bash
#!/usr/bin/env bash
# Misconfiguration trap and cost cap. NOT a security control — see SECURITY.md.
# Exits non-zero if the dispatching repo isn't listed in tracked-repos.yml.
set -euo pipefail

: "${DISPATCH_REPO:?DISPATCH_REPO must be set (the client_payload.repo value)}"

if ! yq -e '.repos[].name | select(. == strenv(DISPATCH_REPO))' tracked-repos.yml >/dev/null; then
  echo "::error::Repo '$DISPATCH_REPO' is not in tracked-repos.yml — refusing to act."
  exit 1
fi
```

### Design: `scripts/load-prompt.sh`

```bash
#!/usr/bin/env bash
# Reads a prompt file into a workflow output. Used by both the update and
# reconcile workflows so the prompt body can be interpolated into the
# claude-code-action `prompt:` input. The heredoc-style multi-line GitHub
# Actions output format requires a delimiter that does not appear in the body.
set -euo pipefail

: "${PROMPT_FILE:?PROMPT_FILE must be set (e.g. prompts/update.md)}"
: "${OUTPUT_KEY:?OUTPUT_KEY must be set (e.g. body)}"
: "${GITHUB_OUTPUT:?must be set (run under GitHub Actions)}"

DELIM="MEOWSER_EOF_$(date +%s)_$$"

{
  echo "${OUTPUT_KEY}<<${DELIM}"
  cat "$PROMPT_FILE"
  echo "$DELIM"
} >> "$GITHUB_OUTPUT"
```

### Design: `scripts/list-tracked-repos.sh`

```bash
#!/usr/bin/env bash
# Emits the GitHub Actions matrix JSON for reconcile.yml. Each tracked repo
# becomes its own matrix entry so the daily audit fans out one job per repo.
set -euo pipefail

: "${GITHUB_OUTPUT:?must be set (run under GitHub Actions)}"

matrix=$(yq -o=json '{"include": [.repos[] | {"repo": .name}]}' tracked-repos.yml)
echo "matrix=${matrix}" >> "$GITHUB_OUTPUT"
```

### Design: `scripts/validate-services.sh`

```bash
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
```

### Design: `examples/tracked-repo-workflow.yml`

A tracked repo copies **two** files: `examples/tracked-repo-workflow.yml` into `.github/workflows/notify-meowser.yml`, and `examples/notify-meowser.sh` into `.github/scripts/notify-meowser.sh`. The workflow stays trivial; all real logic lives in the script.

```yaml
# .github/workflows/notify-meowser.yml
name: Notify meowser

on:
  pull_request:
    types: [closed]
    branches: [main]   # change to your default branch if not 'main'

jobs:
  notify:
    if: ${{ github.event.pull_request.merged == true }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          # Fetch enough history that base_sha and merge_commit_sha are both reachable.
          fetch-depth: 0

      - name: Notify meowser
        env:
          GH_TOKEN: ${{ secrets.MEOWSER_DISPATCH_TOKEN }}
          MEOWSER_OWNER: <MEOWSER_OWNER>   # replace at adoption time
          DIFF_BYTES: 50000
        run: ./.github/scripts/notify-meowser.sh
```

The `pr_body` shell-escaping concern goes away: the script reads PR fields directly from `$GITHUB_EVENT_PATH` (the JSON file GitHub Actions writes for every event) instead of through YAML interpolation, so quotes/backticks/newlines in PR bodies are handled correctly by `jq`.

### Design: `examples/notify-meowser.sh`

```bash
#!/usr/bin/env bash
# Posts a `meowser-update` repository_dispatch at the meowser repo with the
# diff and PR metadata for a just-merged PR. Reads PR fields from
# $GITHUB_EVENT_PATH (set by GitHub Actions) so we never round-trip strings
# through YAML interpolation.
set -euo pipefail

EVENT="${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH must be set (run under GitHub Actions)}"
: "${GITHUB_REPOSITORY:?must be set}"
: "${GH_TOKEN:?MEOWSER_DISPATCH_TOKEN must be exposed as GH_TOKEN}"
: "${MEOWSER_OWNER:?must be set to the owner of the meowser repo}"
DIFF_BYTES="${DIFF_BYTES:-50000}"

# Pull PR fields from the event JSON. Using jq here means strings are handled
# safely regardless of their content.
PR_NUMBER=$(jq -r '.pull_request.number'              "$EVENT")
PR_TITLE=$( jq -r '.pull_request.title'               "$EVENT")
PR_BODY=$(  jq -r '.pull_request.body // ""'          "$EVENT")
ACTOR=$(    jq -r '.pull_request.user.login'          "$EVENT")
BASE_SHA=$( jq -r '.pull_request.base.sha'            "$EVENT")
HEAD_SHA=$( jq -r '.pull_request.head.sha'            "$EVENT")
MERGE_SHA=$(jq -r '.pull_request.merge_commit_sha'    "$EVENT")

# Compute the actual delta that landed on the default branch. base..merge
# works for plain merges, squash merges, and rebase merges alike.
CHANGED_FILES=$(git diff --name-only "$BASE_SHA" "$MERGE_SHA" | jq -R . | jq -sc .)
DIFF=$(git diff "$BASE_SHA" "$MERGE_SHA" | head -c "$DIFF_BYTES")

# Assemble the dispatch payload with jq so all string escaping is correct.
jq -n \
  --arg repo             "$GITHUB_REPOSITORY" \
  --argjson pr_number    "$PR_NUMBER" \
  --arg pr_title         "$PR_TITLE" \
  --arg pr_body          "$PR_BODY" \
  --arg merge_commit_sha "$MERGE_SHA" \
  --arg base_sha         "$BASE_SHA" \
  --arg head_sha         "$HEAD_SHA" \
  --arg actor            "$ACTOR" \
  --arg diff             "$DIFF" \
  --argjson files        "$CHANGED_FILES" \
  '{
    event_type: "meowser-update",
    client_payload: {
      repo: $repo,
      pr_number: $pr_number,
      pr_title: $pr_title,
      pr_body: $pr_body,
      merge_commit_sha: $merge_commit_sha,
      base_sha: $base_sha,
      head_sha: $head_sha,
      actor: $actor,
      diff: $diff,
      changed_files: $files
    }
  }' \
| gh api -X POST "repos/${MEOWSER_OWNER}/meowser/dispatches" --input -
```

### Design: `prompts/update.md`

```markdown
You are the meowser catalog update agent. Your job is to keep the markdown service catalog in this repo synchronized with changes that just happened in a tracked source repository.

## Inputs

You will receive:
- A "Change context" block (source repo, PR number, PR title, PR author, merge-commit SHA, changed-file list)
- A "PR description" block (the merged PR's body)
- A "Diff" block (unified diff between the PR's base and merge commit, truncated to 50 KB)

Every dispatch corresponds to a merged PR — there is no other trigger. The change comes from a repo on the allowlist in `tracked-repos.yml`. The workflow has already verified this; you can trust it.

## What to do

1. Read `schema/service.schema.json` so you know the frontmatter contract.
2. Read `docs/service-spec.md` so you know the body conventions.
3. Find the matching entries under `services/` by Grep'ing the frontmatter for `repo: <source repo>`. There may be zero, one, or many matches.
   - Zero matches: create a new file at `services/<kebab-case-name>.md` following the spec.
   - One or many: edit only those files, only where the diff implies a change.
4. Preserve existing field ordering and prose unless the diff explicitly contradicts it.
5. Do **not** touch the `last_reconciled_at` field. It belongs to the reconciliation flow.

## What NOT to do

- Do not invent fields that aren't in the schema.
- Do not add `topics` that aren't supported by either the diff or existing prose.
- Do not edit any file outside `services/`.
- Do not edit files for services unrelated to the source repo.
- Do not run `Bash` (your tools are restricted to Edit, Read, Write, Glob, Grep).

## Output

When you finish, write a short, factual commit message and a PR description summarizing what changed and why. Include the `cc @<actor>` line that the workflow appended to the prompt. The action handles branch creation, push, and PR opening — you don't call any GitHub APIs yourself.
```

### Design: `prompts/reconcile.md`

```markdown
You are the meowser reconciliation agent. Your job is to verify a single catalog entry against the live state of its source repo and fix any drift.

## Inputs

You will receive a "Target" line naming the source repo (e.g., `acme/orders-api`).

## What to do

1. Read `services/` and find the entry whose `repo:` frontmatter matches the target. If none exists, stop and write a PR description noting that the target is on the allowlist but has no catalog entry yet.
2. Shallow-clone the target repo into `/tmp/target`:
   ```
   git clone --depth=1 https://github.com/<target> /tmp/target
   ```
3. For each frontmatter field, verify against the live repo:
   - `openapi`: file exists at the referenced path.
   - `events`: each `payload_ref` exists; topic names still appear in the source.
   - `dependencies`: each named service is still imported / called from the source. Use Grep for import statements, HTTP-client config, broker config, etc.
   - `topics`: still reflect the surface area visible in README, public APIs, and event topics.
4. Skim the README and `openapi.yaml` (if present) and confirm the prose body still describes the service accurately.
5. **Bias toward no change.** Only edit when drift is concrete and you can point to specific evidence in the live repo. If nothing is wrong, **do nothing** — do not commit, do not open a PR, do not even touch `last_reconciled_at`. The successful workflow run itself is the evidence that the audit ran. The on-success no-PR case is the *expected* case for a healthy catalog.
6. If you find drift, update the relevant frontmatter and prose, set `last_reconciled_at` to the current UTC time, and write a PR description that lists each finding with the evidence (file path + line, or quoted snippet).

## What NOT to do

- Do not edit entries for any other repo than the target.
- Do not "improve" prose stylistically — only correct factual drift.
- Do not invent topics, dependencies, or events that you can't trace to evidence in the live repo.
```

### Design: Repo Variables

Documented in README so adopters know what they can override. All have sensible defaults baked into the workflows via `${{ vars.X || 'default' }}`.

| Variable | Default | Where used | Purpose |
| --- | --- | --- | --- |
| `MEOWSER_MODEL` | `claude-sonnet-4-6` | `on-dispatch-update.yml` | Model for the hot-path update agent |
| `MEOWSER_MAX_TURNS` | `12` | `on-dispatch-update.yml` | Caps tool-call iterations on the update agent |
| `MEOWSER_RECONCILE_MODEL` | `claude-opus-4-7` | `reconcile.yml` | Reasoning-heavier model for the audit agent |
| `MEOWSER_RECONCILE_MAX_TURNS` | `30` | `reconcile.yml` | Higher ceiling because reconciliation explores the cloned repo |

Secrets (separate from Variables — these can't have defaults):

| Secret | Where set | Purpose |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | meowser repo | Auth for `claude-code-action` |
| `MEOWSER_DISPATCH_TOKEN` | each tracked repo | Fine-grained PAT used by the tracked-repo workflow to POST to meowser's `/dispatches` |

### Design: Architecture diagram

For `README.md` and `docs/architecture.md`:

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

### Design: Fine-grained PAT scopes (for `docs/adoption.md`)

When creating `MEOWSER_DISPATCH_TOKEN`:

- **Repository access:** Only select repositories → just the meowser repo.
- **Repository permissions:**
  - `Metadata`: Read (required by GitHub for any fine-grained PAT)
  - `Contents`: Read and write (required to POST `/repos/<owner>/<repo>/dispatches` per current GitHub docs)
- **Account permissions:** none.

`docs/adoption.md` should include a screenshot or step-by-step click-through for the GitHub PAT-creation UI; surface the exact "Repository permissions" page where these are set.

### Design: `PULL_REQUEST_TEMPLATE.md`

```markdown
<!-- For human PRs: delete the agent checklist below. -->
<!-- For PRs opened by claude-code-action: keep the agent checklist; reviewers tick it. -->

## Summary

<!-- One or two sentences. -->

## Why

<!-- The motivating change in a tracked repo, or the drift detected during reconciliation. -->

---

### Agent-PR review checklist

- [ ] The frontmatter still validates against `schema/service.schema.json` (CI confirms this)
- [ ] The diff matches the change in the source repo cited above
- [ ] `topics` still reflect what the service actually does
- [ ] The prose body is still accurate and readable
- [ ] No edits leaked into files outside `services/`
- [ ] If `last_reconciled_at` was updated, the change actually warranted it
```

### Design: `SECURITY.md`

```markdown
# Security

## Tokens in use

| Token | Lives in | Permissions | What it can do |
| --- | --- | --- | --- |
| `ANTHROPIC_API_KEY` | meowser repo secrets | n/a | Calls Anthropic API on meowser's behalf during workflow runs |
| `MEOWSER_DISPATCH_TOKEN` | each tracked repo's secrets | Fine-grained PAT scoped to meowser; `Metadata: Read`, `Contents: Read/Write` | POSTs `repository_dispatch` events at meowser to trigger updates |

## What the allowlist gate does and doesn't do

Every `repository_dispatch` is gated by the `tracked-repos.yml` allowlist before the LLM runs. **This is not the primary security control** — it's mostly a misconfiguration trap and a cost cap.

The gate **does**:
- Reject dispatches naming a `client_payload.repo` not in `tracked-repos.yml` (fails fast on a copy-paste of the snippet into an un-onboarded repo)
- Bound LLM cost to a known set of source repos
- Give operators a single auditable file describing what meowser trusts

The gate **does not**:
- Prevent a leaked `MEOWSER_DISPATCH_TOKEN` from being used to impersonate *any* allowlisted repo (the attacker can pick any name from `tracked-repos.yml`)
- Protect against a malicious diff payload — the gate only checks the `repo` field

The actual defense against forged or malicious dispatches is **human PR review on meowser**, backed by the schema-validation CI workflow. Branch protection on meowser's default branch (require review, require passing checks) is therefore mandatory for production use.

## Revocation

If a `MEOWSER_DISPATCH_TOKEN` is compromised:
1. Revoke the PAT in GitHub → Settings → Developer settings → Fine-grained tokens.
2. Rotate the secret in any tracked repo using it.
3. Inspect recent meowser PRs for any unexpected catalog changes.

If `ANTHROPIC_API_KEY` is compromised:
1. Rotate the key in the Anthropic console.
2. Update the secret in meowser repo settings.
3. Review Anthropic billing for unexpected usage.

## Threat model

In scope (the design considers and addresses these):
- Random external attackers — cannot fire a dispatch at all without a valid `MEOWSER_DISPATCH_TOKEN`.
- Misconfigured tracked-repo workflows — caught by the allowlist gate.

Out of scope (the design relies on human review + branch protection, not the workflow code):
- A malicious commit in a *legitimately tracked* repo can produce a misleading PR in meowser. The validate workflow catches schema violations but cannot judge prose accuracy. **Human review of agent PRs is the last line of defense.**
- A leaked `MEOWSER_DISPATCH_TOKEN` from any tracked repo can be used to forge dispatches naming any *other* allowlisted repo, with attacker-supplied diff content. Same defense: human review.
- A compromised meowser maintainer account. Standard GitHub branch protection on meowser's default branch (require review, require passing checks, restrict who can push) is **mandatory**, not optional.
```



These don't block starting Phase 0; flagging so we agree as they come up:

1. **Bash tool exposure on the update workflow** — Phase 2 currently restricts to `Edit,Read,Write,Glob,Grep`. If the agent ever needs `Bash` to git-clone the tracked repo for richer context, we'll add it then.
2. **Reconciliation matrix size** — daily over a large catalog could get expensive. Once we have >5 tracked repos, may want to stagger (e.g., one per day on rotation).

## Definition of done for v0.1.0

- A user can fork meowser, create the demo sibling repo, follow `docs/adoption.md`, push a change to the demo, and see a meaningful PR appear in their meowser fork within ~2 minutes.
- The validate workflow is green on the empty initial state.
- All six decision records exist, are accepted, and are referenced from `AGENTS.md`.
- `README.md` and `AGENTS.md` (with `CLAUDE.md` symlink) are written and accurate.
