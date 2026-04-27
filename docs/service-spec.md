# Service Catalog Format

Every catalogued service lives at `services/<kebab-case-name>.md`. The file has two parts:

1. **YAML frontmatter** — structured, schema-validated fields. Validated against `schema/service.schema.json` in CI.
2. **Markdown body** — prose for LLMs and humans. Free-form, but follow the section conventions below.

---

## Frontmatter reference

Required fields: `name`, `repo`, `topics`, `dependencies`.

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Human-readable, unique across the catalog. Used as the dependency reference value in other entries. |
| `repo` | string | `owner/name` GitHub repo. |
| `topics` | string[] | Keywords someone might use in a prompt to find this service. At least one required. |
| `dependencies` | string[] | `name` values of other catalog entries this service depends on. Empty array if none. |
| `openapi` | string (uri-reference) | URL or repo-relative path to the OpenAPI spec. Omit for non-HTTP services. |
| `events` | object[] | Events emitted or consumed. Each has `topic` (string), `direction` (`emit`\|`consume`), and optional `payload_ref`. |
| `auth` | string | How other services authenticate to this one. |
| `owners` | string[] | Team or person owners (free-form). |
| `slack_channel` | string | Primary Slack channel, must match `#[a-z0-9-]+`. |
| `last_reconciled_at` | string (date-time) | Set by the reconciliation agent when it corrects drift. Never set by the update flow. |

---

## Annotated example

```markdown
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

    POST /orders
    Authorization: Bearer <jwt>
    Idempotency-Key: <uuid>
    Content-Type: application/json

    { "items": [{ "sku": "ABC-123", "qty": 2 }], "customer_id": "cust_42" }
```

---

## Body section conventions

The agent is not required to use every section — only the ones supported by the source repo's content.

| Section | Purpose |
| --- | --- |
| `## What it does` | One-paragraph summary of the service's responsibility |
| `## When to use it` | Bullet list of the right scenarios for this service |
| `## When not to use it` | Adjacent services to redirect to instead |
| `## Common pitfalls` | Non-obvious gotchas that would trip up a caller |
| `## Auth` | Prose expanding on the `auth` frontmatter field |
| `## Examples` | Representative HTTP requests or event payloads |
