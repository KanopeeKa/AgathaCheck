# PR workflow (Agatha Track)

Canonical policy: `docs/agent-efficiency/atomic-pr-policy.md` — read before opening or reviewing PRs.

## One outcome

- One PR = one verifiable outcome describable in a single sentence.
- Cross-domain changes (UI + API + E2E) are fine when they serve that one outcome.
- Split when the PR mixes independent outcomes (“and also…”).

## Snags (zero untracked debt)

- Trivial same-file fix (≤15 lines, no behavior change) → fix in the PR.
- Small related fix elsewhere → micro-PR or same PR if blocking merge.
- Unrelated or needs a decision → GitHub issue immediately; never silent deferral.

## Verification

- During work: `./scripts/pre-push-changed.sh`
- Before merge to `main`: `./scripts/pre-push.sh`

## Review output format

When reviewing code or PRs: verdict, comment, required or suggested fix, and priority.
