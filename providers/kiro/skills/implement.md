---
inclusion: manual
description: "Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code with smallest complete diff."
---

# Implement

Turn an approved target state into verified code. Smallest complete diff. No placeholders. No skipped verification.

## Contract

Before writing code, lock these down (state in response):

1. Target behavior (what must be true when done)
2. Acceptance criteria (observable, testable)
3. Source of truth for current behavior
4. Exact change boundary (what files, what NOT to touch)
5. Verification surface (which tests to run)

If any is fuzzy → tighten before editing code.

## Reading Order

1. Engineering guides, architecture docs, coding standards
2. Plan doc, proposal, issue, or feature request
3. **Tests and configs in affected area first** — they define contracts
4. Current owning implementation path end to end
5. Current working tree diff

Key questions before writing:
- What is the exact acceptance criterion?
- What does the existing test suite expect?
- What conventions govern this module (naming, structure, error handling)?
- What existing utilities already cover part of this work?
- What is explicitly out of scope?

## Declare Change Set

Before coding, declare intent:

| Path | Action | What changes | Why |
|------|--------|-------------|-----|

Update this table as implementation progresses — it is the audit trail.

## Reuse Check

Before creating anything new:
1. Search for existing utility/helper/service that handles this. Found → use it.
2. Existing function extendable without violating contract → extend it.
3. Existing file owns this responsibility → modify it.
4. Similar logic in two places → consolidate, do not add a third.

## Verification

ALL three must pass:

| Criterion | Meaning |
|-----------|---------|
| Acceptance passes | Requested behavior works end to end |
| Negative path tested | Invalid input, error state, or permission denied |
| No regression | Affected area suite still green |

NOT verification: heavy mocking, happy-path only, "looks right" reasoning, asserting mock calls.

If a real test fails → fix immediately. Do not document around it.

## Resume Protocol

When resuming interrupted work, determine phase first:

| Phase | Signal |
|-------|--------|
| `implementation` | Unimplemented rows in change set |
| `testing` | Code complete, no test output recorded |
| `completed` | All verified |

Do not repeat finished work. Do not skip phases.

## Output Format

```markdown
## Implementation: <name>

### Summary
<2-4 sentences: what was done, approach, what was excluded>

### File Impact
| Path | Action | What changed |
|------|--------|-------------|

### Verification
- Acceptance: ✅/❌ <detail>
- Negative path: ✅/❌ <scenario>
- Regression: ✅/❌ <suite checked>

### Remaining Risks
- ...
```

## Guardrails (implement-specific)

- Do not leave placeholder/stub/TODO in final output.
- Do not skip verification — "it looks right" is not enough.
- Do not rewrite unrelated modules.
- Do not mark phase complete if verification criterion unmet.
- Do not create new file when existing owner can absorb the change.
- Do not create new function when existing one can be extended.
