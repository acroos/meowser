# Adding a Tracked Repo to Meowser

Five steps to wire up a new repo so meowser auto-updates its catalog entry whenever a PR merges.

---

## Step 1 — Create a fine-grained PAT scoped to meowser

In GitHub: **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**

Configure it as follows:

- **Resource owner:** the account or org that owns your meowser fork
- **Repository access:** Only select repositories → choose only the meowser repo
- **Repository permissions:**
  - `Metadata`: Read (required by GitHub for all fine-grained PATs)
  - `Contents`: Read and write (required to POST to the `/dispatches` endpoint)
- **Account permissions:** none

Give the token a descriptive name like `meowser-dispatch-<your-repo-name>` and set a reasonable expiration.

> **Security note:** This token can only trigger `repository_dispatch` events on the meowser repo. It cannot read your code, open PRs, or touch any other repository. See `SECURITY.md` for the full threat model.

---

## Step 2 — Add the PAT as a secret in your tracked repo

In your tracked repo: **Settings → Secrets and variables → Actions → New repository secret**

- **Name:** `MEOWSER_DISPATCH_TOKEN`
- **Value:** the token from Step 1

---

## Step 3 — Add the dispatch workflow to your repo

Copy one file from the meowser repo into your tracked repo:

| Source (meowser) | Destination (your repo) |
| --- | --- |
| `examples/tracked-repo-workflow.yml` | `.github/workflows/notify-meowser.yml` |

Then edit it:

- Replace both `<MEOWSER_OWNER>` placeholders with the GitHub username or org that owns your meowser fork.
- If your default branch isn't `main`, update the `branches:` list.

The workflow is just a thin caller — the dispatch logic lives in meowser's reusable workflow (`.github/workflows/notify.yml`) and is pulled in via `uses:`. That way, when meowser changes its dispatch payload, you don't need to copy a new script — you just bump the `@v1` ref.

Commit and push the file.

---

## Step 4 — Open a PR against meowser to add your repo to the allowlist

Edit `tracked-repos.yml` in the meowser repo and add an entry:

```yaml
repos:
  - name: your-org/your-repo
```

Open a PR. Once it merges, meowser will accept dispatches from your repo.

---

## Step 5 — Verify end-to-end

Merge a PR in your tracked repo. Within ~2 minutes you should see:

1. The `notify-meowser` workflow run green in your repo's Actions tab.
2. A new PR appear in the meowser repo updating (or creating) the catalog entry for your service.

If the dispatch workflow fails, check:
- The `MEOWSER_DISPATCH_TOKEN` secret is set and hasn't expired.
- `MEOWSER_OWNER` in the workflow matches the actual meowser repo owner.
- Your repo is listed in `tracked-repos.yml` and that PR has merged.
