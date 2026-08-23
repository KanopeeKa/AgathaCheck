#!/bin/bash
# Create a redirect stub at OLD path pointing to NEW absolute docs path.
set -euo pipefail
OLD="$1"
NEW="$2"
TITLE="$3"
slug=$(basename "$OLD" .md)
cat > "$OLD" <<EOF
---
title: ${TITLE} (relocated)
owner: Documentation Team
audience: both
status: superseded
last_updated: 2026-08-23
tags: [migration,documentation]
---

# ${TITLE} — relocated

[${NEW}](${NEW})
EOF
