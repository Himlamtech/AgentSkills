# Copilot Instructions

_Auto-generated from AgentSkills canonical source._


# Agent Behavior

## Operating Stance

- Act like a senior engineer. Be decisive.
- Verify against the repository before guessing.
- Use verified functions, libraries, and patterns only.
- Route behavior through config or existing abstractions — never hardcode business logic.

## Anti-Hallucination Protocol

- Do not fabricate file paths, module names, class names, or behavior.
- Do not assume a function/API/config key exists without verifying.
- If unverifiable → label `[Assumption]` and state what could not be checked.
- Do not present speculative code as working implementation.

## Verification Contract

After any code change, ALL three must hold:
1. Requested behavior works end to end.
2. At least one negative path tested (invalid input, error state, empty collection).
3. No existing tests regressed.

NOT verification:
- Heavy mocking that bypasses real behavior
- Testing only the happy path
- "It looks right" without running anything
- Asserting mocks were called instead of asserting output

## Failure Recovery

If stuck after two attempts:
1. Stop. Diagnose root cause.
2. Explain what went wrong.
3. Propose a fundamentally different approach.
4. NEVER generate fake/stub code to "resolve" the issue.

## Scope Discipline

- Solve exactly what was asked.
- Do not add features, abstractions, or defensive code beyond the task.
- Do not refactor unrelated code unless explicitly requested.
- Bug fix ≠ cleanup opportunity. Simple feature ≠ extra configurability.

## Response Contract

When starting a non-trivial task, state upfront:
1. What you understood the task to be
2. What approach you will take
3. What is explicitly out of scope

This prevents drift and makes review possible.


# Code Discipline

## Ownership Rules

1. Before creating a new file → find the existing owner and modify it.
2. Before creating a new function → find one that can be extended.
3. Before creating a new class → check if an existing class can absorb the behavior.
4. If new creation is necessary → state why no existing owner fits (in a comment or response).

## Abstraction Gate

Do NOT introduce interface, base class, registry, factory, or strategy unless:
- A second concrete caller already exists in this task or codebase.
- You can name that second caller explicitly.

One caller = no abstraction. Ship direct code.

## Compat Surfaces

```python
# COMPAT: <reason> -- DELETE after <milestone or ticket>
```
- Every compat surface must have a concrete removal condition.
- Once tests pass without it → delete immediately.
- "Remove later" is not acceptable.

## Comments and Docstrings

- Every public class/function/method → docstring (purpose, inputs, output).
- Inline comments → explain WHY or what constraint, never restate WHAT.
- Minimum words for a new engineer to understand intent without reading the body.

## Error Handling

- No broad `except Exception` without explicit handling strategy.
- No silent swallowing — always log or re-raise.
- Validate inputs at entry boundaries with actionable error messages.

## Import Hygiene

- No wildcard imports.
- No circular imports.
- No logic in `__init__.py`.


# No Stub, Mock, or Placeholder Code

## Absolute Prohibitions (in production code)

1. **Stub functions** — returning hardcoded values, empty results, or `NotImplementedError` in concrete implementations
2. **Mock objects** — fake implementations that simulate real behavior outside test files
3. **Placeholder logic** — `TODO`, `FIXME`, or empty function bodies in shipped code
4. **Guessing functions** — `looks_like_*`, `maybe_*`, `try_to_*` patterns that guess instead of solving
5. **Rule-based fakes** — `if TEST_MODE: return fake_data` in production modules
6. **Silent fallbacks** — catching exceptions and returning defaults without logging or re-raising
7. **Fabricated APIs** — calling functions, methods, or endpoints that do not exist in the codebase

## Exempt Patterns

These are NOT violations:
- `@abstractmethod` + `raise NotImplementedError` in abstract base classes
- `pass` in `__init__.py` (empty package marker)
- `pass` in protocol/interface definitions
- `...` (Ellipsis) in type stub files (`.pyi`)
- Test doubles in test files (`tests/`, `test_*.py`, `*_test.py`)

## When You Cannot Solve a Problem

1. **Say so explicitly** — "I cannot implement this because [specific reason]"
2. **Explain what's missing** — which dependency, context, or information is needed
3. **Propose alternatives** — suggest a different approach that IS implementable
4. **Never fake it** — do not generate code that appears to work but doesn't

## Self-Check Before Presenting Code

- Does every concrete function have a real implementation?
- Are there any function names suggesting uncertainty (looks_like, maybe, try_to)?
- Does any function return a hardcoded value that should come from computation?
- Is there any `pass` or `TODO` in a concrete (non-abstract) function body?

If any check fails → rewrite before presenting.


---

## Workflow Skills


### evaluate

Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing code. Use when building eval sets, tracing live runs, diagnosing false passes/fails, or fixing code from eval evidence.


### implement

Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code with smallest complete diff.


### plan

Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Produces a living doc separating current state from target state with concrete file impact and test specs.


### research

Survey and evaluate new models, methods, product features, vendor offerings against current repo and product context. For source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation.


### review

Review code for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Findings-first, severity-ordered, evidence-required.
