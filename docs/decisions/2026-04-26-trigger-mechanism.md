**status:** "accepted"

---

# `repository_dispatch` from tracked repos to trigger meowser updates

## Context and Problem Statement

When a tracked repo merges a PR, meowser needs to learn about it and update its catalog. The trigger mechanism determines how that signal travels from the tracked repo to meowser.

## Considered Options

* `repository_dispatch` event POSTed from each tracked repo's workflow
* Webhook registered centrally (requires a running server)
* Polling meowser on a schedule for all repos

## Decision Outcome

Chosen option: "`repository_dispatch`", because it is fork-friendly (no central server required), uses only GitHub primitives (a PAT + a workflow), and carries arbitrary JSON context (diff, PR metadata) in `client_payload`.

### Consequences

* Good, because any fork of meowser works identically — no server to redeploy.
* Good, because dispatches are authenticated (require a PAT scoped to the meowser repo).
* Good, because `client_payload` carries rich context (diff, PR title, actor) the LLM needs.
* Bad, because a leaked PAT can forge dispatches — mitigated by the allowlist gate and human PR review (see `docs/decisions/2026-04-26-auth-model.md`).
