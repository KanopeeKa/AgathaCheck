---
name: Flutter root-user warning breaks the version gate — set BOT=true
description: In root containers, flutter prints its "running as root" warning before the version line, so the Flutter version gate fails; export BOT=true first.
---

**Symptom:** the Flutter version gate (`agatha_flutter_verify` in `scripts/flutter-sdk.sh`, used by
`cloud-install.sh` and pre-push) fails with `Expected Flutter 3.44.0; found: Woah! You appear to be
trying to run flutter as the 'root' user...` even though `/opt/flutter` is the right version.

**Cause:** cloud agent containers (Claude Code cloud, Cursor Cloud) run as `root`. Flutter prints its
root-user warning **before** `Flutter 3.44.0 • channel …`, and the gate only reads the first line of
`flutter --version`.

**Fix (first try, environment only — never commit it):** export `BOT=true` for the session, then rerun.
Flutter skips the root warning when `BOT=true`.

```bash
export BOT=true
```

Do not rebuild the image, reinstall Flutter, or chase a "wrong version" — the SDK is fine. If the SDK
also refuses to run, add `git config --global --add safe.directory '*'` (same family of container
fixes; see `docs/agent-efficiency/plans/execute-plan-v2.md` §Repo conventions).
