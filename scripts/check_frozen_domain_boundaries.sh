#!/usr/bin/env bash
# Fail when active production code imports frozen Shelter/Fostering modules.
# Roots and patterns are driven by docs/engineering/frozen-domains/manifest.json.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" "$@" <<'PY'
"""Manifest-driven frozen domain boundary checker."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

# Gated mount point for frozen HTTP routers when ENABLE_FROZEN_DOMAINS=true.
SERVER_MOUNT_ALLOWLIST = frozenset(
    {
        "server/bin/server.js",
    }
)

ACTIVE_FLUTTER_ROOT = "flutter_app/lib"
ACTIVE_SERVER_ROOTS = (
    "server/routes",
    "server/lib",
    "server/bin",
)

DART_IMPORT_RE = re.compile(
    r"^\s*(?:import|export|part)\s+"
    r"(?:\w+\s+)?"
    r"['\"]([^'\"]+)['\"]",
    re.MULTILINE,
)

JS_IMPORT_RE = re.compile(
    r"""(?:import\s+[\s\S]*?\sfrom\s+|import\s*)['"]([^'"]+)['"]""",
    re.MULTILINE,
)


def repo_root_from_argv() -> Path:
    return Path(sys.argv[1]).resolve()


def parse_args(argv: list[str]) -> tuple[Path, Path]:
    root = repo_root_from_argv()
    manifest = root / "docs/engineering/frozen-domains/manifest.json"
    args = argv[2:]
    i = 0
    while i < len(args):
        if args[i] == "--root" and i + 1 < len(args):
            root = Path(args[i + 1]).resolve()
            i += 2
        elif args[i] == "--manifest" and i + 1 < len(args):
            manifest = Path(args[i + 1]).resolve()
            i += 2
        else:
            raise SystemExit(f"Unknown argument: {args[i]}")
    return root, manifest


def rel_posix(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def under_prefix(rel: str, prefix: str) -> bool:
    prefix = prefix.rstrip("/")
    return rel == prefix or rel.startswith(prefix + "/")


def expand_frozen_server_roots(roots: list[str]) -> list[str]:
    expanded: list[str] = []
    for root in roots:
        root = root.rstrip("/")
        expanded.append(root)
        if not root.endswith(".js") and not root.endswith(".mjs"):
            expanded.append(f"{root}.js")
    return expanded


def dart_frozen_tokens(source_roots: list[str]) -> list[str]:
    tokens: list[str] = []
    for root in source_roots:
        parts = Path(root).parts
        if "features" in parts:
            idx = parts.index("features")
            if idx + 1 < len(parts):
                feature = parts[idx + 1]
                tokens.append(f"features/{feature}/")
                tokens.append(f"/{feature}/presentation/")
                tokens.append(f"/{feature}/domain/")
                tokens.append(f"/{feature}/data/")
    return tokens


def server_frozen_tokens(server_roots: list[str]) -> list[str]:
    tokens: list[str] = []
    for root in server_roots:
        rel = root.removeprefix("server/")
        if rel.endswith(".js"):
            rel = rel[:-3]
        tokens.append(rel)
        tokens.append(rel + "/")
    return tokens


def is_frozen_production_file(rel: str, frozen_flutter: list[str], frozen_server: list[str]) -> bool:
    return any(under_prefix(rel, p) for p in frozen_flutter + frozen_server)


def iter_active_dart_files(root: Path, manifest: dict) -> list[Path]:
    lib_root = root / ACTIVE_FLUTTER_ROOT
    if not lib_root.is_dir():
        return []
    frozen = manifest.get("sourceRoots", [])
    remove_surfaces = set(manifest.get("activeSurfacesToRemove", []))
    files: list[Path] = []
    for path in sorted(lib_root.rglob("*.dart")):
        rel = rel_posix(path, root)
        if is_frozen_production_file(rel, frozen, []):
            continue
        if rel in remove_surfaces:
            continue
        files.append(path)
    return files


def iter_active_server_files(root: Path, manifest: dict) -> list[Path]:
    frozen = expand_frozen_server_roots(manifest.get("serverRoots", []))
    files: list[Path] = []
    for base in ACTIVE_SERVER_ROOTS:
        base_path = root / base
        if not base_path.is_dir():
            continue
        for path in sorted(base_path.rglob("*")):
            if not path.is_file():
                continue
            if path.suffix not in {".js", ".mjs"}:
                continue
            rel = rel_posix(path, root)
            if is_frozen_production_file(rel, [], frozen):
                continue
            if rel in SERVER_MOUNT_ALLOWLIST:
                continue
            files.append(path)
    return files


def dart_import_violations(text: str, tokens: list[str]) -> list[str]:
    hits: list[str] = []
    for match in DART_IMPORT_RE.finditer(text):
        spec = match.group(1)
        for token in tokens:
            if token in spec:
                hits.append(spec)
                break
    return hits


def js_import_violations(text: str, tokens: list[str]) -> list[str]:
    hits: list[str] = []
    for match in JS_IMPORT_RE.finditer(text):
        spec = match.group(1)
        normalized = spec.replace("\\", "/")
        for token in tokens:
            bare = token.rstrip("/")
            if (
                bare in normalized
                or f"/{bare}/" in normalized
                or normalized.endswith(f"/{bare}")
                or normalized.startswith(f"{bare}/")
            ):
                hits.append(spec)
                break
    return hits


def scan_files(
    files: list[Path],
    root: Path,
    kind: str,
    tokens: list[str],
    import_checker,
) -> list[str]:
    violations: list[str] = []
    for path in files:
        rel = rel_posix(path, root)
        text = path.read_text(encoding="utf-8", errors="replace")
        hits = import_checker(text, tokens)
        for hit in hits:
            violations.append(f"{rel}: imports frozen {kind} path `{hit}`")
    return violations


def run_check(root: Path, manifest_path: Path) -> int:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    dart_tokens = dart_frozen_tokens(manifest.get("sourceRoots", []))
    server_tokens = server_frozen_tokens(manifest.get("serverRoots", []))

    dart_files = iter_active_dart_files(root, manifest)
    server_files = iter_active_server_files(root, manifest)

    violations: list[str] = []
    violations.extend(scan_files(dart_files, root, "Flutter", dart_tokens, dart_import_violations))
    violations.extend(scan_files(server_files, root, "server", server_tokens, js_import_violations))

    if violations:
        print("::error::Frozen domain boundary violation(s):")
        for line in violations:
            print(f"::error::{line}")
        print(
            "::error::Active production code must not import frozen "
            "organization/fostering_session modules (see manifest.json)."
        )
        return 1

    print("Frozen domain boundary check: OK")
    print(
        f"  scanned {len(dart_files)} active Dart files, "
        f"{len(server_files)} active server files"
    )
    return 0


def main() -> None:
    root, manifest_path = parse_args(sys.argv)
    if not manifest_path.is_file():
        print(f"::error::Missing manifest: {manifest_path}", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(run_check(root, manifest_path))


if __name__ == "__main__":
    main()
PY
