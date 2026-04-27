#!/usr/bin/env bash
# Reads a prompt file into a workflow output. Used by both the update and
# reconcile workflows so the prompt body can be interpolated into the
# claude-code-action `prompt:` input. The heredoc-style multi-line GitHub
# Actions output format requires a delimiter that does not appear in the body.
set -euo pipefail

: "${PROMPT_FILE:?PROMPT_FILE must be set (e.g. prompts/update.md)}"
: "${OUTPUT_KEY:?OUTPUT_KEY must be set (e.g. body)}"
: "${GITHUB_OUTPUT:?must be set (run under GitHub Actions)}"

DELIM="MEOWSER_EOF_$(date +%s)_$$"

{
  echo "${OUTPUT_KEY}<<${DELIM}"
  cat "$PROMPT_FILE"
  echo "$DELIM"
} >> "$GITHUB_OUTPUT"
