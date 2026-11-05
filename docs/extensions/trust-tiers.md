# Trust tiers

| Tier | Meaning | Hooks |
| --- | --- | --- |
| `official` | Maintained by the Kiln team | Allowed |
| `verified` | Reviewed and checksum-verified | Allowed |
| `community` | From the community | Explicit approval required |

`HookPolicy` in the SDK rejects hooks from community-tier extensions unless the
user approves them (`--yes`). The foundation-phase installer does not execute
hooks automatically; extensions that have hooks are reported so the user can
decide.

A later registry phase adds archive checksums, release signatures/metadata, and
trust checks before install.
