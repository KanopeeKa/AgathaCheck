#!/usr/bin/env bash
# Block cross-feature imports in the care_item leaf module (EX-10 / F3).
# Legacy detail UI under presentation/detail/ is baselined in check_feature_imports.js.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" "$@" <<'PY'
"""Care Item leaf import boundary (care-next-occurrence-c1a7 §18.15 EX-10)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

CARE_ITEM = "flutter_app/lib/features/care_item"
LEAF_DIRS = (
    f"{CARE_ITEM}/application",
    f"{CARE_ITEM}/domain",
    f"{CARE_ITEM}/data",
    f"{CARE_ITEM}/presentation/occurrence",
    f"{CARE_ITEM}/presentation/sheets",
)
LEAF_FILES = (f"{CARE_ITEM}/presentation/care_completion_flow.dart",)
FEATURES = "flutter_app/lib/features"
ALLOWED_PREFIXES = (
    "flutter_app/lib/core",
    "flutter_app/lib/l10n",
    CARE_ITEM,
)
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".mocks.dart")

DIRECTIVE_RE = re.compile(
    r"^\s*(?:import|export|part)\s+(?:\w+\s+)?['\"]([^'\"]+)['\"]",
    re.MULTILINE,
)


def parse_args(argv: list[str]) -> Path:
    root = Path(argv[1]).resolve()
    args = argv[2:]
    i = 0
    while i < len(args):
        if args[i] == "--root" and i + 1 < len(args):
            root = Path(args[i + 1]).resolve()
            i += 2
        else:
            raise SystemExit(f"Unknown argument: {args[i]}")
    return root


def rel_posix(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def under(rel: str, prefix: str) -> bool:
    prefix = prefix.rstrip("/")
    return rel == prefix or rel.startswith(prefix + "/")


def is_generated(rel: str) -> bool:
    return any(rel.endswith(s) for s in GENERATED_SUFFIXES) or under(
        rel, "flutter_app/lib/l10n"
    )


def leaf_dart_files(root: Path) -> list[Path]:
    out: list[Path] = []
    for prefix in LEAF_DIRS:
        base = root / prefix
        if not base.is_dir():
            continue
        for path in base.rglob("*.dart"):
            rel = rel_posix(path, root)
            if is_generated(rel):
                continue
            out.append(path)
    for rel in LEAF_FILES:
        path = root / rel
        if path.is_file():
            out.append(path)
    return sorted(out)


APP_PACKAGE = "pet_profile_app"


def resolve_uri(root: Path, importer: Path, uri: str) -> str | None:
    if uri.startswith("dart:"):
        return None
    if uri.startswith("package:"):
        rest = uri[len("package:") :]
        pkg, _, subpath = rest.partition("/")
        if pkg != APP_PACKAGE or not subpath:
            return None
        target = (root / "flutter_app" / "lib" / subpath).resolve()
        try:
            return rel_posix(target, root)
        except ValueError:
            return None
    target = (importer.parent / uri).resolve()
    try:
        return rel_posix(target, root)
    except ValueError:
        return None


def forbidden_target(rel: str) -> bool:
    if any(under(rel, p) for p in ALLOWED_PREFIXES):
        return False
    if under(rel, FEATURES):
        return not under(rel, CARE_ITEM)
    return False


def main() -> int:
    root = parse_args(sys.argv)
    violations: list[str] = []

    for dart_file in leaf_dart_files(root):
        text = dart_file.read_text(encoding="utf-8")
        importer_rel = rel_posix(dart_file, root)
        for match in DIRECTIVE_RE.finditer(text):
            uri = match.group(1)
            target_rel = resolve_uri(root, dart_file, uri)
            if target_rel is None:
                continue
            if forbidden_target(target_rel):
                violations.append(
                    f"{importer_rel}: {uri} -> {target_rel}"
                )

    if violations:
        print("::error::Care Item leaf boundary violation(s):", file=sys.stderr)
        for line in sorted(violations):
            print(f"  {line}", file=sys.stderr)
        print(
            "Leaf paths must import core/l10n and care_item only "
            "(care-next-occurrence-c1a7 EX-10).",
            file=sys.stderr,
        )
        return 1

    print("Care Item leaf boundary check: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
