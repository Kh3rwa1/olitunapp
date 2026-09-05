# Progress reset release validation

## Verified

The corrected explicit-reset implementation passed 108 focused Flutter profile tests and full static analysis with fatal infos on Flutter 3.47.2 / Dart 3.13.2. Evidence is in `PROGRESS_HARDENING_DIAGNOSTICS.txt` at commit `7076870f00d6dff34ccb31036fbf80ae4a71299e`. This includes the main-branch updates already merged into the feature branch. Temporary preparation tooling was removed.

Reset is explicit rather than inferred from empty stats. A higher synchronization epoch wins before ordinary same-epoch merging; legacy data uses epoch zero. Tests cover persistence, cloud reset upload, rejection of older cloud progress, normal empty-update safety, notifier success and failure.

## Before release

- Require normal full CI on the final branch head; focused tests do not replace it.
- Exercise online reset, offline reset, reconnect, app restart and two-device synchronization in staging.
- Check account switching and preferences isolation with separate test users.
- Verify legacy-client rollout behavior before relying on reset generations across every installed client.

## Known limits

This is not a durable reward ledger or an exactly-once synchronization guarantee. Same-generation concurrent counters, an offline reset against an unseen newer remote generation, and same-device mutation serialization remain follow-up work. Old clients do not understand reset generations and can still write legacy progress.

No merge, deployment, production-data operation or permission migration was performed by this implementation pass.
