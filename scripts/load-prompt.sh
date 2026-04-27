#!/usr/bin/env bash
# Loads a prompt file (e.g. prompts/update.md) into a GitHub Actions step
# output so a later step can pass it to claude-code-action's `prompt:` input.
#
# Prompts are multi-line markdown, so we use the multi-line output format
# ("key<<DELIM\n...body...\nDELIM"). The delimiter is randomized to make
# sure it can't accidentally appear inside the prompt body.
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
