---
name: implement
description: "Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code changes. Triggers on: \"implement this\", \"code this up\", \"build it\", \"make the changes\", \"continue\"."
---

# Implement

Turn an approved target state into verified code. Smallest complete diff. No placeholders. No skipped verification.

## Implementation Contract

Before writing code, lock these down:

- target behavior
- acceptance criteria
- source of truth for current behavior
- exact change boundary
- verification surface

If any of these are fuzzy, tighten them before editing code.

## Objective

Produce the minimal complete implementation that satisfies the requested behavior -- aligned with current architecture, conventions, and runtime constraints. Do not over-build. Do not under-verify.

## Step 1 -- Read before touching any file

Read in this order:

1. Engineering guides, architecture docs, coding standards -- whatever convention files exist in the repo
2. The Plan doc, proposal, issue, or feature request
3. **Tests and configs in the affected area first** -- they define contracts before implementation does
4. The current owning implementation path end to end
5. Current working tree diff -- understand what has already changed

**Key questions to answer before writing a single line:**
- What is the exact acceptance criterion -- what observable behavior must exist when done?
- What does the existing test suite expect from the areas being changed?
- What conventions govern naming, structure, error handling, and logging in this module?
- What existing utilities, helpers, or services already cover part of this work?
- Are there any existing functions that can be extended rather than replaced?
- What part of the request is explicitly out of scope for this diff?

## Step 2 -- Declare the minimal change set

Before writing code, declare intent:

| Path | Action | What changes | Why |
|------|--------|-------------|-----|
| `path/to/file.py` | Modify | Add `cancel()` with state guard | Domain owns state machine |
| `config/settings.yaml` | Modify | Add `order.cancel_timeout_seconds: 30` | Replace hardcoded value |
| `tests/test_cancel.py` | Add | Coverage for new cancel paths | New behavior |

Mark tentative paths explicitly. Update this table as implementation progresses -- it is the audit trail for the Review step.

**Reuse rules -- check before creating anything new:**
- Search for an existing utility, helper, or service that already handles any part of this work. If found, use it.
- If an existing function can be extended without violating its contract, extend it -- do not write a parallel version.
- If an existing file owns this responsibility, modify it -- do not create a new file and deprecate the old one. That is always wrong.
- If similar logic already exists in two places, consolidate into one -- do not add a third copy.

## Step 3 -- Code discipline

These rules apply to every line written. Violating them is a defect, not a style issue.

### No over-engineering

Do not introduce an abstraction -- interface, base class, registry, factory, strategy pattern -- unless a **second concrete caller already exists** in this task or codebase. One caller = no abstraction. Name the second caller or write direct code.

Do not add async, caching, retry, or event indirection without a named, observable failure mode it prevents. "It might be useful later" is not a reason.

If the simplest direct implementation works, ship it. Every layer of indirection is a permanent maintenance cost.

### SOLID is mandatory

All new code and refactors must follow SOLID at the smallest practical scope.

- Keep one responsibility per module, class, and function.
- Extend existing owners instead of splitting behavior across parallel paths.
- Depend on stable contracts, not concrete implementation details, when a boundary already exists.
- Prefer composition over inheritance unless the existing hierarchy is already the owning contract.
- Do not introduce abstractions without a second concrete caller or a real reuse boundary.

### Modify existing before creating new

Before creating a new file, find the file that owns this responsibility and modify it.  
Before creating a new function, find the function that can be extended and extend it.  
Before creating a new class, check whether an existing class can absorb this behavior.

When creating something new is genuinely necessary, state the reason explicitly in a comment or issue note: "No existing owner for this responsibility because X."

### Compat surfaces are temporary by definition

If backward-compat code is needed to pass tests during a transition, add it with:

```python
# COMPAT: <reason> -- DELETE after <milestone or ticket number>
```

**Once tests pass, delete the compat surface immediately.** Do not leave it for a follow-up that never happens. If deletion must be deferred, it must go into the implementation report under "Compat surfaces remaining" with a concrete owner and removal date.

### Comments: explain why, not what

Every non-trivial function, class, module, and critical logic block must have a docstring or inline comment that explains **why it exists or what contract it enforces** -- not a restatement of what the code does. Reading the code already tells you what it does.

```python
# Good -- explains why and the constraint
# Retry up to 3× with exponential backoff -- downstream has transient 503s under load.
# Do not increase beyond 3: SLA requires <2s p95 response time.
async def fetch_with_retry(url: str) -> Response: ...

# Bad -- restates the code
# This function fetches a URL and retries on failure.
async def fetch_with_retry(url: str) -> Response: ...
```

Target: minimum words for a new engineer to understand intent without reading the body. Too long = defect. Missing entirely on non-trivial code or critical logic = defect.

### No mocks, stubs, or fakes in production code

Test doubles belong exclusively in test files. Never in `src/`, `app/`, or any production module.

Do not ship rule-based fallback logic that mimics a real service. If a dependency is unavailable in a given environment, raise an explicit, actionable error -- do not silently return fake data.

```python
# Wrong -- silent fake in production code
def get_user(user_id: str) -> User:
    if settings.TEST_MODE:
        return User(id=user_id, name="Test User")  # fake
    return self.repo.find(user_id)

# Right -- fail explicitly, keep test doubles in test files
def get_user(user_id: str) -> User:
    return self.repo.find(user_id)  # raises NotFoundError if missing
```

## Step 4 -- Verification contract

Verification is incomplete unless all three criteria are met:

| Criterion | What it means |
|-----------|--------------|
| Acceptance scenario passes | The originally requested behavior works end to end |
| At least one negative path tested | Invalid input, error state, empty collection, or permission denied |
| No existing tests regressed | Affected area suite still green |

**Common verification mistakes that do not count as verification:**
- Mocking so much that the test does not exercise real behavior
- Running tests on a different code path than what changed
- Testing only the happy path
- Marking "verified" based on static reasoning without actually running anything
- Writing a test that asserts mocks were called rather than asserting observable output

**For AI-system or E2E behavior -- real test format:**

```text
Input:    <exact user input or API call -- no paraphrasing>
Setup:    <fixtures, seed data, environment state required>
Expected: <behavior in plain language -- what the system does, not just what it returns>
Pass rule: <observable, objective criterion>
Fail rule: <what failure looks like -- hallucination pattern, wrong format, missing field, wrong status>
```

If a real test fails -> fix the implementation immediately. Do not document around it or defer.

## Step 5 -- Continue workflow

When resuming an interrupted task, determine the current phase before doing anything else.

| Phase | Signal |
|-------|--------|
| `implementation` | File impact table has unimplemented rows; code changes incomplete |
| `testing` | Code complete; test files modified but no run output recorded |
| `deployment` | Tests passing; no deploy confirmation |
| `documentation` | Deploy done; docs or config comments not updated |
| `completed` | All above confirmed |

Determine phase by inspecting: git diff, test output files, deploy logs. If ambiguous, re-run targeted tests to confirm current state. Do not repeat already-finished work. Do not skip a phase because resuming feels like starting fresh.

## Output format

```markdown
## Implementation: <feature or fix name>

### Summary
<2-4 sentences: what was done, what approach was taken, what was deliberately excluded>

### File impact
| Path | Action | What changed |
|------|--------|-------------|
| ... | ... | ... |

### Compat surfaces remaining
- `path/to/file:line` -- COMPAT: reason -- DELETE by: <milestone> -- Owner: <name>
(or: none)

### Verification results
- Acceptance scenario: ✅ / ❌ <detail>
- Negative path tested: ✅ / ❌ <which scenario>
- Regression check: ✅ / ❌ <suite or area checked>

### Remaining risks
- ...
```

## Guardrails

- Do not leave placeholder, stub, or TODO code in final output.
- Do not skip the verification contract -- "it looks right" is not verification.
- Do not write tests that only mock everything -- they must exercise real behavior.
- Do not rewrite unrelated modules to make the diff feel cleaner.
- Do not mark a phase complete if its verification criterion is not met.
- Do not deploy using guesswork -- use the project's established deploy path only when explicitly in scope.
- Do not add a new abstraction without naming the second concrete caller that justifies it.
- Do not create a new file when an existing file owns the responsibility.
- Do not create a new function when an existing function can be extended.
- Do not leave a compat surface alive after tests pass -- delete it now.
- Do not place mocks, stubs, or fakes in production code.
- Do not write comments that restate what the code does -- explain why.
