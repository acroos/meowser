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
