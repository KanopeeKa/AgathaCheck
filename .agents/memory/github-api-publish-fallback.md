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

Repository `permissions.push` describes account-level repository access, not
the effective OAuth permissions for every file path.

**Why:** A healthy connection successfully created blobs and an ordinary-file
tree, but tree creation touching an Actions workflow returned 404. The offered
reauthorization scopes included `repo`, not `workflow`. Successful repository
reads therefore did not establish that the complete change could be published.

**How to apply:** Diagnose path-specific write failures before claiming push
access has recovered. Preserve the complete local history; do not omit required
workflow changes or work around provider restrictions. Reauthorization is only
useful when it can offer the missing permission; otherwise use an authorized
Git push path with workflow-file access.

Successful fetching from a public repository does not prove that Git's write
credentials are valid.

**Why:** Public reads can succeed without authentication, while a push rejects
the credentials. A Git pane's generic rejection message does not distinguish
this from divergent history or branch rules.

**How to apply:** Check history and branch rules without changing them. For an
explicitly authorized token in Replit Secrets, test authenticated `/user` access
inside a process that never logs the token. A 401 `Bad credentials` identifies
an authentication failure; do not attempt to fix it by rewriting branch history.

Repair an authorized push without silently replacing the user's saved Git
credential configuration.

**Why:** The editor's Git login and an independently authorized push can use
different credential paths. A successful push through one path does not prove
that the Git pane's saved login has been repaired.

**How to apply:** Prefer command-scoped authentication for the authorized
operation. Keep credentials in Replit Secrets, never in remote URLs or logs.
Check workflow-file write permission separately from repository push access.