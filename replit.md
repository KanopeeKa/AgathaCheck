---
title: AgathaTrack (PetProfileApp)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-13
tags: [development,environment]
---
# AgathaTrack (PetProfileApp)

## Overview
AgathaTrack is a modular Flutter web application (Node.js API + PostgreSQL) for pet management and care coordination —
pet profiles, care and health tracking, weight, contacts, sharing, organisations (shelters, foster teams), reports,
notifications, GDPR data rights. Guardians, shelters, foster teams and organisations are the users.

**Where things are:** domain map `docs/architecture/index.md` · product behaviour = canonical docs under
`docs/domains/<domain>/` · CI/CD gates `docs/pipelines/ci-cd-gates.md` · dependencies `flutter_app/pubspec.yaml`,
`server/package.json`.

**Do not add product behaviour, schemas or feature lists to this file** — they go in the canonical doc for that
capability (`docs/domains/documentation/standards.md`). This file holds Replit-specific mechanics only.

## Rules (shared with every agent)
`AGENTS.md` is the shared rulebook — precedence, when to ask (critical questions only), autonomy and merging,
toolchain and test commands. Path rules: `.cursor/rules/*.mdc`; procedures: `.cursor/skills/`. When two written
sources conflict, follow `AGENTS.md` §Precedence and fix the losing text; do not stop to ask unless `AGENTS.md`
§When to ask applies.

## User preferences
- Clean architecture with feature-driven structure; TDD/BDD; dartdoc; production-ready CI; EU GDPR compliance.
- Inspect first, change second: smallest safe change; be conservative around UAT deploy, Playwright E2E, auth/session
  handling and environment-specific behaviour.
- PRs to `main` are enforced by branch protection (`ci-gate / CI passed` + CodeQL `Analyze JavaScript` required).
  Sensitive paths (`.github/scripts/agent-safety-lib.js`) are blocked on `replit/*` branches by
  `agent-pr-safety-gate.yml`.

## Replit mechanics
1. **Pre-PR critical self-review** — `.cursor/rules/pr-hygiene.mdc`; canonical-docs sync when behaviour changes.
2. **Rebase your branch** before pushing: `git fetch origin && git rebase origin/main`.
3. **Push** without embedding the token in the URL:
   ```bash
   git -c credential.helper='!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f' \
     push origin HEAD:refs/heads/replit/<topic>
   ```
   If the sandbox blocks local commits, push files via `PUT /repos/KanopeeKa/AgathaCheck/contents/<path>` (base64
   content, current blob SHA, branch name).
4. **Open the PR** via the GitHub REST API with `GITHUB_TOKEN`, ready (not draft), with `## Docs` in the body.
5. **Review:** Copilot (`POST /repos/KanopeeKa/AgathaCheck/pulls/{n}/requested_reviewers` with
   `{"reviewers":["copilot-pull-request-reviewer"]}` when credits allow). Bugbot is retired. Triage threads per
   `docs/agent-efficiency/autonomous-pr-policy.md`.
6. **CI:** poll `GET /repos/KanopeeKa/AgathaCheck/commits/{sha}/check-runs` every 60–90 s and fix failures (Flutter
   shards ~3–5 min, full suite ~8–10 min). New blocking jobs go in ci-gate `needs` and `scripts/ci/assert-ci-gate.sh`.
7. **Merge** per `AGENTS.md` §Autonomy and merging. After merge: `git fetch origin && git checkout main && git reset --hard origin/main`.

Replit runtime lessons (preview toolchain, test PostgreSQL, Nix/Chromium): `.agents/memory/MEMORY.md` → Replit entries.
