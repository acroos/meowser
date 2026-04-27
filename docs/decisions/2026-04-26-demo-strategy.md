**status:** "accepted"

---

# Demo via a separate sibling repo (`meowser-demo-service`)

## Context and Problem Statement

Meowser needs a realistic end-to-end demo: a tracked repo changes, a dispatch fires, an agent PR appears in meowser. The demo must work in a fork and demonstrate real catalog generation without polluting meowser's own `services/` directory.

## Considered Options

* Separate sibling repo (`meowser-demo-service`) that forks independently alongside meowser
* Inline demo fixtures committed directly to `meowser` (synthetic dispatch, pre-written catalog entry)
* No demo; documentation-only walkthrough

## Decision Outcome

Chosen option: "Separate sibling repo", because it exercises the full flow (real `repository_dispatch`, real diff, real agent PR) rather than mocking any part of it. Forks of meowser pair with forks of the demo repo, making the demo identical to production use.

### Consequences

* Good, because the demo is identical to real adoption — no special-casing in the workflows.
* Good, because `meowser`'s `services/` directory starts empty and is only populated by a live dispatch.
* Bad, because the demo requires managing two repos; adopters must fork both and cross-wire secrets.
