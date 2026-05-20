---
inclusion: manual
description: "Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Produces a living doc separating current state from target state with concrete file impact and test specs."
---

# Plan

Write implementation-ready engineering docs. Not descriptive — actionable. Every claim must be code-backed or labeled as assumption.

## Contract

Before writing, lock these down (state them in your response):

1. Target question / behavior
2. Acceptance criteria
3. Source scope (which code areas to read)
4. Out-of-scope boundary
5. Open questions

If any item is unclear → ask one clarifying question or state assumption and proceed.

## Reading Order

1. Engineering guides, architecture docs, coding standards in the repo
2. The proposal, issue, or feature request
3. Tests and configs in the affected area (they define contracts before code does)
4. The current owning implementation path end to end
5. Adjacent schemas, migrations, manifests if touched
6. Current working tree diff if relevant

Rules:
- Source not found → mark claims as `[Assumption]`
- Never fabricate paths, names, or behavior
- Research findings stay in `[Current]`; proposed changes in `[Target]`

## Claim Labels

Every non-trivial statement must carry one:

| Label | Meaning |
|-------|---------|
| `[Current]` | Verified in actual code |
| `[Target]` | Proposed — does not exist yet |
| `[Gap]` | Delta to close |
| `[Assumption]` | Not verified |
| `[Risk]` | Known failure mode |
| `[Open question]` | Must answer before implementing |
| `[Dependency]` | External blocker |

## Document Structure

### 1. Overview
- What is being built, why now, business value in concrete terms
- Scope boundary and out-of-scope
- Key assumptions and open questions upfront

### 2. Current State `[Current]`
- Code-backed only — no generic architecture prose
- Name exact modules, APIs, config keys, schemas, tables
- Known limitations and mismatches with proposal

### 3. Target Behavior `[Target]`
- Precise enough for implementation without follow-up questions
- Actors, triggers, step-by-step sequence
- Sync/async boundaries, error handling, auth concerns
- Negative scope: what the system must NOT do
- Mermaid diagram only for branching/async/multi-actor flows

### 4. Implementation Approach `[Gap]`
- Which layer/module owns new behavior and why
- Actual function signatures (not descriptions)
- Config delta: exact keys, defaults, fallbacks
- Compat surfaces with `# COMPAT: reason -- DELETE after milestone`

### 5. File Impact

| Path | Action | What changes | Why |
|------|--------|-------------|-----|

Cover: config keys, API contracts, DB schema, permissions, observability.

### 6. Test Specs

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|

Include: happy path, wrong state, invalid input, concurrent access, timeout.

### 7. Definition of Done
- [ ] Real tests pass
- [ ] Config updated
- [ ] Compat surfaces resolved
- [ ] Observability in place
- [ ] No unresolved `[Assumption]` or `[Open question]`

## Guardrails (plan-specific)

- Do not present proposals as shipped behavior.
- Do not omit Sections 5-6 for non-trivial changes.
- Do not propose abstractions without naming the second caller.
- Do not mark DB schema changes as approved implicitly — flag as `[Dependency]`.
- Do not hide conflicts between proposal and current codebase.
