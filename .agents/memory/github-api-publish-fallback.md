---
name: GitHub API publishing fallback
description: Safely publish a verified local branch when the shell cannot authenticate to GitHub but the connected GitHub OAuth account can.
---

When a normal `git push` fails due to unavailable shell credentials, use the authenticated GitHub connection only after confirming the user asked to publish or create a pull request. Do not handle or request a raw token.

**Why:** Replit’s shell Git transport and the connected GitHub OAuth integration can have different credential availability. A failed shell push does not necessarily mean the connected GitHub account cannot publish.

**How to apply:** Preserve the local branch and verify the remote base SHA still equals the locally validated base. For a new branch, stop if the ref already exists. For an explicitly authorized push to an existing shared branch, reproduce the local commits in parent order, verify every returned tree and commit SHA matches locally, recheck the expected remote tip immediately before updating, and use `force: false`. Stop if the remote tip moved. Never replace another writer's history or silently squash the local commits.

Keep connector writes in small, independently verified steps: preflight the base/ref, create the derived tree and feature ref, create the PR, then read back the PR and changed-file list. Large all-in-one impure transactions can fail during durable-runtime replay before execution.

After a ref update, the PR's cached head can briefly lag behind the actual ref.
Verify both before dispatching SHA-specific validation; do not treat that brief
lag as evidence that the push failed.

When an impure Node helper needs the repository, pass the workspace root explicitly rather than relying on `process.cwd()`, which may not be callable in that sandbox. Parse Git index output inside the impure process; tool-output transport can strip tab delimiters.