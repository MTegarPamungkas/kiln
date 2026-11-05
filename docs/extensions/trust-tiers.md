# Trust tiers

| Tier | Meaning | Hooks |
| --- | --- | --- |
| `official` | Maintained by the Kiln team | Allowed |
| `verified` | Reviewed and checksum-verified | Allowed |
| `community` | From the community | Explicit approval required |

`HookPolicy` gates hook execution: `official`/`verified` extensions may run their
hooks only with explicit approval (`--yes`), and community hooks are rejected
without it. The `codegen` extension ships the first install hook (it runs
`build_runner`), which is why hooks are wired into the installer at all.

The `kiln_store` registry client already verifies archive checksums and applies a
trust policy before installing. Publishing to a hosted HTTP registry — as opposed
to a local `registry/` folder — is the remaining step.
