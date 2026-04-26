# Project Idea - Meowser

## TL;DR

service-CATalog-super-lite: an auto-updating service catalog describing when/how a service should be used, optimized for usage by LLMs

## Problem

In a service-oriented architecture, LLMs need a way to understand the current service landscape so they can understand where functionality lives and how to use it. Existing service catalogs like Backstage are great for humans, but a bit heavyweight for LLM usage (they also require a good bit of setup).

## Solution Idea

A system-wide source of truth for services optimized for reads by LLMs and configured to auto-generate updates whenever there are changes to tracked repositories. Details:

### Storage Format

Many formats will work here, but for flexibility I think using markdown (perhaps with some YAML front-matter) is the best option. The front-matter can provide answers to very specific questions while the markdown can provide a description / usage info that an LLM can use to answer more ambiguous queries. Examples of data that should be answered 100% deterministically:

- OpenAPI spec location (for request-based arch)
- Event payloads, event topics (for event-based arch)
- Topics (keywords for the functionality offered by this service, should include any words which people might use in a prompt to describe what this service offers)
- Dependencies (what other services does this depend on)
- Auth info (if applicable, how can other services authenticate with this one)

### Auto-updating

Meowser should live in its own repo with a CI job that can be triggered from many other repos. Any time a changes is made to one of the tracked repos, it should send context about what changes were made to meowser's CI which has a job that passes the changes through an LLM, requesting it to update any relevant docs in meowser's repo, create a PR if there were any updates, and request review from the person who made the changes in the tracked repo.

### Maintenance / Reconciliation

There is _always_ a risk of documentation getting out of date or drifting towards inaccuracy. Meowser should run a periodic job to read the code from each tracked repo and audit its own documentation based on that. We should expect relatively few changes (because it _should_ be up-to-date), but the job should fix any inaccuracies it finds.

## Plan

This repo should be a fork-able working implementation of the solution described above. It should include examples of every piece of functionality
