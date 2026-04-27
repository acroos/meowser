---
name: broken-service
repo: acme/broken
invented_field: this field does not exist in the schema
# Missing required fields: topics, dependencies
---

This fixture is intentionally invalid. It is used to verify that
validate-services.sh exits non-zero and emits a CI error annotation
when a service entry fails schema validation.
