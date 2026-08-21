---
name: GitHub API publishing fallback
description: Safely publish a verified local branch when the shell cannot authenticate to GitHub but the connected GitHub OAuth account can.
---

When a normal `git push` fails due to unavailable shell credentials, use the authenticated GitHub connection only after confirming the user asked to publish or create a pull request. Do not handle or request a raw token.

**Why:** Replit’s shell Git transport and the connected GitHub OAuth integration can have different credential availability. A failed shell push does not necessarily mean the connected GitHub account cannot publish.

**How to apply:** Preserve the local branch, verify the remote base SHA still equals the locally validated base, and never overwrite an existing remote feature branch. Use GitHub’s Git data API to create blobs, a derived tree, one commit, and the branch ref, then create and verify the pull request. Stop if the base advanced or the ref already exists.