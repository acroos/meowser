**status:** "accepted"

---

# Fine-grained PAT for tracked→meowser; default GITHUB_TOKEN for meowser→meowser

## Context and Problem Statement

Two auth paths exist: (1) a tracked repo POSTing a dispatch to meowser, and (2) meowser's own workflow creating branches and PRs. Each needs the least-privilege token that works.

## Considered Options

* Fine-grained PAT scoped only to the meowser repo stored as a secret in each tracked repo; default `GITHUB_TOKEN` for internal meowser workflow operations
* Classic PAT with broad repo permissions
* GitHub App with fine-grained installation tokens

## Decision Outcome

Chosen option: "Fine-grained PAT + default GITHUB_TOKEN", because it minimizes blast radius (leaked PAT can only touch the meowser repo), is zero-config for the meowser side (workflow token is automatic), and has the simplest fork story (adopters create one PAT per tracked repo).

### Consequences

* Good, because a leaked `MEOWSER_DISPATCH_TOKEN` cannot modify the tracked repo it came from.
* Good, because meowser PR creation needs no additional secret setup.
* Good, because fine-grained PATs are auditable and revocable per token.
* Bad, because a leaked token can still forge dispatches naming any allowlisted repo — human PR review is the last defense (see `SECURITY.md`).
* Bad, because adopters must create a PAT manually; GitHub Apps would allow org-wide installation but add complexity.
