---
name: code-discipline
description: >
  Core coding standards enforced across all agent interactions. Covers SOLID principles,
  file ownership, abstraction rules, comment conventions, and error handling.
inclusion: always
priority: high
---

# Code Discipline

## SOLID Principles

- One responsibility per module, class, and function.
- Extend existing owners instead of splitting behavior across parallel paths.
- Depend on stable contracts, not concrete implementation details.
- Prefer composition over inheritance unless the existing hierarchy is the owning contract.
- Do not introduce abstractions without a second concrete caller.

## File and Function Ownership

- Before creating a new file, find the file that owns this responsibility and modify it.
- Before creating a new function, find the function that can be extended and extend it.
- Before creating a new class, check whether an existing class can absorb this behavior.
- When creating something new is genuinely necessary, state the reason explicitly.

## No Over-Engineering

- Do not introduce an abstraction (interface, base class, registry, factory, strategy) unless a second concrete caller already exists.
- Do not add async, caching, retry, or event indirection without a named, observable failure mode it prevents.
- If the simplest direct implementation works, ship it.

## Compat Surfaces

Every compat surface must have:
```python
# COMPAT: <reason> -- DELETE after <milestone or ticket>
```
Once tests pass, delete the compat surface immediately.

## Comments and Docstrings

- Every public class, function, and method must have a docstring.
- Docstrings explain: purpose, main inputs, output/side effect.
- Inline comments explain WHY, not WHAT.
- No banner comments, no noise, no restating the code.

```python
# Good — explains constraint
# Retry up to 3x with backoff — downstream has transient 503s under load.
# Do not increase beyond 3: SLA requires <2s p95 response time.
async def fetch_with_retry(url: str) -> Response: ...

# Bad — restates the code
# This function fetches a URL and retries on failure.
async def fetch_with_retry(url: str) -> Response: ...
```

## Error Handling

- No broad `except Exception` without a clear handling strategy.
- No silent swallowing of errors.
- Fail explicitly with actionable error messages.
- Validate inputs at entry boundaries.

## Import Rules

- No wildcard imports.
- No circular imports.
- No logic in `__init__.py`.
