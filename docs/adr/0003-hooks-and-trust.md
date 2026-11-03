# 0003 — Hooks run only after trust-tier confirmation

## Decision

Hooks are allowed only for `official`/`verified` extensions or after explicit
user approval. The foundation phase does not execute hooks automatically;
existing hooks are reported.

## Rationale

Hooks run arbitrary code on the user's machine. The trust surface must be as
small as possible. Declarative validation (prompts) is safer than hooks.

## Consequences

- `dio` uses no hooks; URL/int validation is done by `PromptSpec`.
- `codegen` will need a hook later because it runs `build_runner`.
- `firebase` can use `manual_steps` + doctor instead of a hook.
