---
name: Replit Chromium Nix runtime
description: Replit Playwright Chromium needs explicit Nix graphics and desktop libraries in addition to the chromium package.
---

Declare `glib`, `gtk3`, `nss`, `atk`, `cups`, `pango`, `libdrm`, `mesa`, `libglvnd`, and the required X11 libraries in `.replit` when browser validation must run reproducibly.

**Why:** The Playwright-downloaded browser may fail on missing `libglib-2.0.so.0` or `libgbm.so.1` even when the Chromium package is present.

**How to apply:** Provision the libraries through the package-management tooling and validate with a headless Chromium smoke launch; do not rely on `playwright install --with-deps` because apt is unavailable in Replit.