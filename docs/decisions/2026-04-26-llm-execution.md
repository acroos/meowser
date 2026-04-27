**status:** "accepted"

---

# Use `anthropics/claude-code-action@v1` for all LLM work

## Context and Problem Statement

The catalog update and reconciliation flows need an LLM to read diffs/live repos and edit markdown files. We need a way to run that LLM inside GitHub Actions without maintaining SDK wrappers, PR-creation plumbing, or language runtimes.

## Considered Options

* `anthropics/claude-code-action@v1` — GitHub Action that runs Claude with tool use
* Custom Python/Node script using the Anthropic SDK
* Self-hosted runner with a full agent framework

## Decision Outcome

Chosen option: "`anthropics/claude-code-action@v1`", because it eliminates all application code: no SDK wrapper, no PR-creation logic, no language runtime to install. The action handles branch creation, file edits, commit, and PR opening natively. The repo stays purely declarative (prompts, YAML, scripts).

### Consequences

* Good, because the repo contains no application code to maintain or test beyond shell scripts.
* Good, because model and turn limits are workflow `env` / repo Variables — easy to configure.
* Good, because the action is maintained by Anthropic and tracks new Claude capabilities.
* Bad, because we're coupled to one action's interface; swapping providers requires rewriting workflows.
