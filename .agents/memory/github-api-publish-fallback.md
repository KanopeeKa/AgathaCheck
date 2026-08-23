---
name: GitHub API publishing fallback
description: Safely publish a verified local branch when the shell cannot authenticate to GitHub but the connected GitHub OAuth account can.
---

When a normal `git push` fails due to unavailable shell credentials, use the authenticated GitHub connection only after confirming the user asked to publish or create a pull request. Do not handle or request a raw token.

**Why:** Replit’s shell Git transport and the connected GitHub OAuth integration can have different credential availability. A failed shell push does not necessarily mean the connected GitHub account cannot publish.

**How to apply:** Preserve the local branch, verify the remote base SHA still equals the locally validated base, and never overwrite an existing remote feature branch. Use GitHub’s Git data API to create blobs, a derived tree, one commit, and the branch ref, then create and verify the pull request. Stop if the base advanced or the ref already exists.

Keep connector writes in small, independently verified steps: preflight the base/ref, create the derived tree and feature ref, create the PR, then read back the PR and changed-file list. Large all-in-one impure transactions can fail during durable-runtime replay before execution.

When an impure Node helper needs the repository, pass the workspace root explicitly rather than relying on `process.cwd()`, which may not be callable in that sandbox. Parse Git index output inside the impure process; tool-output transport can strip tab delimiters.