# Running the Meowser Demo

The demo uses a sibling repo, `meowser-demo-service`, to exercise the full end-to-end flow: a PR merges in the demo repo, a dispatch fires, and a catalog PR appears in meowser within ~2 minutes.

## Prerequisites

- Your own fork of [meowser](https://github.com/your-github-handle/meowser)
- Your own fork of [meowser-demo-service](https://github.com/your-github-handle/meowser-demo-service)
- `ANTHROPIC_API_KEY` set as a secret in your meowser fork

## Steps

### 1 — Fork both repos

Fork `meowser` and `meowser-demo-service` under your GitHub account. All demo activity stays in your forks.

### 2 — Set up secrets and the allowlist

Follow `docs/adoption.md` using `meowser-demo-service` as the tracked repo. In summary:

1. Create a fine-grained PAT scoped to your meowser fork (see Step 1 of adoption.md).
2. Add it as `MEOWSER_DISPATCH_TOKEN` in your `meowser-demo-service` fork.
3. The notify workflow is already in `meowser-demo-service` — update `MEOWSER_OWNER` to your GitHub username.
4. Open a PR against your meowser fork adding `your-handle/meowser-demo-service` to `tracked-repos.yml` and merge it.

### 3 — Push a meaningful change to the demo repo

Good examples of changes the agent will react to:

- Rename an endpoint in `openapi.yaml` (e.g., change `POST /widgets` to `POST /items`)
- Add a new event to `events.yaml`
- Update the README description

Open a PR in your `meowser-demo-service` fork with the change and merge it.

### 4 — Watch the PR appear in meowser

Within ~2 minutes of the merge:

1. Check the **Actions** tab of your `meowser-demo-service` fork — the `notify-meowser` workflow should be green.
2. Check the **Pull requests** tab of your meowser fork — a new PR should appear updating (or creating) `services/meowser-demo-service.md`.

### 5 — Review and merge

Inspect the PR using the agent-PR checklist in `.github/PULL_REQUEST_TEMPLATE.md`:

- Does the frontmatter reflect the change you made?
- Is the prose body still accurate?
- Did the `validate` CI check pass?

If everything looks right, merge the PR.

## What to expect

- **First dispatch:** the agent creates `services/meowser-demo-service.md` from scratch.
- **Subsequent dispatches:** the agent edits only the fields implied by the diff.
- **No catalog change needed:** if your PR only touches files unrelated to the service interface (e.g., internal refactors), the agent may open a PR with no frontmatter changes, or open no PR at all if nothing warrants an update.
