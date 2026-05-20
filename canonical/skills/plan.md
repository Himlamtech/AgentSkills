---
name: plan
description: >
  Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Use before coding starts. Produces a living doc that separates current state from target state with concrete file impact and test specs.
triggers:
  - "plan this"
  - "write a proposal"
  - "design doc"
  - "before we implement"
  - "document this feature"
---

# Plan

Write implementation-ready engineering docs. Not descriptive -- actionable. Every claim must be code-backed or explicitly labeled as an assumption.

## Decision Contract

Before writing, lock these down:

- target question
- target behavior
- acceptance criteria
- source scope
- out-of-scope boundary
- open questions

If the request is about a new model, method, vendor, or recent change, ground the plan in current sources first and label stale or missing evidence.

## Objective

Produce a document that makes three things unambiguous:
- **What exists today** -- verified from actual code, not inferred
- **What the target state is** -- proposed behavior with clear boundaries
- **What must change** -- concrete files, config deltas, test specs

## Step 1 -- Read before writing

Read the repo before forming any claim. Do not write from the feature request alone.

**Reading order:**
1. Engineering guides, architecture docs, coding standards -- whatever convention files exist in the repo
2. The proposal, issue, or feature request
3. Tests and configs in the affected area -- they reveal contracts before implementation does
4. The current owning implementation path end to end
5. Adjacent schemas, migrations, manifests if the change touches them
6. Current working tree diff if relevant

**Rules:**
- If a source does not exist, mark every claim derived from it as `[Assumption]`
- Do not fabricate file paths, module names, class names, or behavior
- If you are unsure whether something exists, say so -- do not guess
- Do not turn research notes into shipped behavior; keep research findings in `[Current]` and proposed changes in `[Target]`

## Step 2 -- Label every claim

Use these labels inline throughout the document. Every non-trivial statement must be traceable.

| Label | Meaning |
|-------|---------|
| `[Current]` | Verified in actual code right now |
| `[Target]` | Proposed -- does not exist yet |
| `[Gap]` | Delta between current and target that must be closed |
| `[Assumption]` | Not verified -- source not found or ambiguous |
| `[Risk]` | Known failure mode or uncertainty that could block delivery |
| `[Open question]` | Must be answered before implementation can start safely |
| `[Dependency]` | External blocker -- another team, service, or unmerged ticket |

## Step 3 -- Write the document

Sections 1-4 are always required. Sections 5, 6, 7 are non-optional for any non-trivial change -- skipping them means the doc is not implementation-ready.

### 1. Overview

- What is being built and why it matters now
- User or business value in concrete terms -- not "improve UX" but "user can do X without Y step"
- Explicit scope boundary: what is out of scope and why
- Key assumptions and open questions surfaced upfront, not buried at the end

### 2. Current state `[Current]`

Code-backed description only. Do not pad with generic architecture prose.

- Relevant architecture: which layers, modules, and services own this area
- Current user or system flow: who triggers what, in what order, what the system returns
- Existing APIs, services, config keys, schemas, DB tables, jobs, queues involved -- name them exactly as they appear in the codebase
- Known limitations, technical debt, or mismatches with the proposal -- be specific

If something is partially implemented, state exactly which parts exist and which do not.

### 3. Target behavior `[Target]`

Describe proposed behavior with enough precision that an engineer can implement it without follow-up questions.

- Actors and trigger points
- Step-by-step sequence of events -- not a vague summary
- Sync vs async boundaries: where does the caller block? where does work continue in the background?
- Error handling: what happens on timeout, invalid input, partial failure, permission denied?
- Auth, multi-tenancy, rate limiting concerns if applicable
- What the system must NOT do (negative scope) when relevant

Include a Mermaid diagram only when the flow has branching, async steps, or multiple actors interacting. Skip for linear single-actor flows -- a diagram of a straight line adds noise, not clarity.

```mermaid
sequenceDiagram
  Actor->>Service: trigger
  Service-->>Queue: enqueue job
  Worker->>DB: persist result
```

### 4. Implementation approach `[Gap]`

How the target behavior fits into the current architecture. Be precise -- "we'll add a service" is not an implementation approach.

- Which layer and module owns the new behavior, and why that layer
- Interfaces to add or change -- show the actual function signature, not a description of it
- **File and function reuse rule:** prefer modifying an existing file over creating a new one. Prefer extending an existing function over writing a new one. When proposing a new file or function, explicitly justify why no existing owner can absorb this responsibility. Creating a new file + deprecating an old one that does the same job is always wrong.
- Config delta: exact keys to add or change, which hardcoded values move to config, what the runtime fallback is when config is missing
- Compat surfaces: if backward compatibility is needed during transition, label every surface with `# COMPAT: <reason> -- DELETE after <milestone>`. Every compat surface must have a concrete, dated removal condition. "Remove later" is not acceptable.
- **Abstraction rule:** do not propose an interface, base class, registry, strategy, or factory unless a second concrete caller is already identified in this task. Name the second caller explicitly or drop the abstraction entirely.

### 5. File impact

Show the full change surface. Be specific -- "various files" is not acceptable.

```text
project/
├── src/
│   ├── domain/
│   │   └── order.py          ← Modify: add cancel() with state guard
│   └── infrastructure/
│       └── order_repo.py     ← Modify: persist cancellation
├── tests/
│   └── test_order_cancel.py  ← Add: unit + integration specs
└── config/
    └── settings.yaml         ← Modify: add order.cancel_timeout_seconds
```

| Path | Action | What changes | Why |
|------|--------|-------------|-----|
| `src/domain/order.py` | Modify | Add `cancel()` with state validation | Domain owns the state machine |
| `config/settings.yaml` | Modify | Add `order.cancel_timeout_seconds: 30` | Replace hardcoded value |
| `tests/test_order_cancel.py` | Add | Happy path + invalid state + timeout | New behavior needs coverage |

Also cover explicitly:
- Config keys added, changed, or removed and their default values
- API contract changes: request/response shape, status codes, headers
- DB schema changes and whether a migration is required
- Permission or auth model changes
- Observability: new logs, metrics, traces added or changed

### 6. Test specs

Define coverage for every critical path. A failing real test = implementation bug, not a doc gap.

**Unit and integration scenarios:**

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Happy path | Valid order in `pending` state | State → `cancelled`, event emitted | -- |
| Wrong state | Order already `shipped` | `InvalidStateError` raised | Must not silently ignore |
| Invalid input | `order_id = None` | `ValueError` with specific message | Validate at entry boundary |
| Concurrent cancel | Two simultaneous requests | One succeeds, one gets 409 | Requires row-level lock |
| Timeout | Downstream slow | Retry N times then raise | N from config |

**Real tests (required for AI-facing or E2E paths):**

```text
Input:    POST /orders/123/cancel with valid auth token
Setup:    Order 123 in DB with status=pending, user has cancel permission
Expected: Response 200, DB status=cancelled, cancellation event in queue
Pass rule: All three conditions verified in a single test run against real DB and queue
Fail rule: Any condition missing, or DB status still=pending after 200 response
```

For AI system behavior -- also define:
- Keywords or structural patterns that must appear in the response
- Patterns that constitute a failure: hallucination, wrong format, refusal when the answer is known

### 7. Definition of done

- [ ] Real tests pass -- not just unit tests
- [ ] Config updated with correct keys and documented defaults
- [ ] All compat surfaces deleted or explicitly deferred with a removal ticket and owner
- [ ] Observability in place: logs at entry/exit of changed critical paths, metrics for new async work
- [ ] No `[Assumption]` items unresolved that would block correct implementation
- [ ] No `[Open question]` items unanswered that would change the design

## Code discipline

Every design decision in this document must follow these rules. Violating them in the plan means the implementation will inherit the defect.

**No over-engineering.** Do not propose an abstraction with one caller. Do not propose async, caching, or retry without naming the specific failure mode it prevents. The simplest design that satisfies the requirement is the correct design.

**Modify before create.** Propose modifying an existing file or function before creating a new one. Justify every new file and function explicitly. Creating a new file alongside a deprecated old one doing the same job is always wrong.

**Compat is temporary.** Every compat surface must have a concrete deletion condition tied to a milestone or ticket. No open-ended compat surfaces.

**Comments explain why, not what.** Every non-trivial function and class gets a one-line comment explaining why it exists or what contract it enforces -- not a restatement of the code. Too long = defect. Too short = defect. The minimum words needed for a new engineer to understand intent without reading the body.

**No mocks or fakes in production code.** Test doubles belong in test files only. If a dependency is unavailable in some environment, the system must fail explicitly -- not silently fall back to fake behavior.

## Guardrails

- Do not present proposals as shipped behavior -- use `[Target]`.
- Do not invent file paths, module names, or signatures -- verify or label `[Assumption]`.
- Do not write a generic implementation section that ignores actual repo ownership.
- Do not hide conflicts between the proposal and what the codebase currently supports.
- Do not omit Sections 5 and 6 for non-trivial changes -- they are the implementation contract.
- Do not propose a new abstraction without naming its second caller.
- Do not mark DB schema changes as approved implicitly -- flag as `[Dependency]` requiring sign-off.
- Do not accept compat surfaces without a concrete, dated removal condition.
