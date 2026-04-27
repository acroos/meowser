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
