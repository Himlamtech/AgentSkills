---
inclusion: auto
description: "Core coding standards: SOLID, file ownership, abstraction rules, comment conventions, error handling, and import hygiene. Enforced across all interactions."
---

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
