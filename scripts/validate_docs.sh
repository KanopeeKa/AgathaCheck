#!/bin/bash

# Script to validate documentation integrity
# Checks for broken links, missing metadata, and duplicate content
# Usage: ./scripts/validate_docs.sh [--strict]

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
STRICT=false
ERRORS=0

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=true ;;
  esac
done

echo "🔍 Validating documentation..."
echo "Repository root: $REPO_ROOT"
echo "Strict mode: $STRICT"
echo ""

# 1. Check for broken markdown links
echo "📚 Checking for broken links in markdown files..."

# Find all markdown files (excluding .git, node_modules, etc.)
MD_FILES=$(find "$REPO_ROOT" -name "*.md" -type f \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/artifacts/*" \
  -not -path "*/.agents/*" \
  -not -path "*/.cursor/*" \
  -not -path "*/.github/*" \
  2>/dev/null)

BROKEN_LINKS=0
for filepath in $MD_FILES; do
  # Extract markdown links
  while IFS= read -r line; do
    # Skip if line doesn't contain markdown link
    if ! echo "$line" | grep -qE '\[[^\]]*\]\([^)]*\)'; then
      continue
    fi
    
    # Extract the path from the link
    link=$(echo "$line" | grep -oE '\[[^\]]*\]\([^)]*\)')
    path=$(echo "$link" | grep -oE '\([^)]*\)' | tr -d '()')
    
    # Skip non-file links
    if echo "$path" | grep -qE '^https?://|^#|^mailto:|^ftp://'; then
      continue
    fi
    
    # Skip anchor links
    if echo "$path" | grep -qE '#'; then
      continue
    fi
    
    # Handle relative paths - convert to absolute
    if echo "$path" | grep -qE '^\./|^\.\./'; then
      # Get directory of current file
      dir=$(dirname "$filepath")
      # Resolve relative path
      abs_path=$(cd "$dir" && realpath -s "$path" 2>/dev/null || echo "")
      if [[ -z "$abs_path" ]]; then
        abs_path="$REPO_ROOT/$path"
      fi
    else
      abs_path="$REPO_ROOT/$path"
    fi
    
    # Check if file exists (handle both .md and without extension)
    if [[ -f "$abs_path" ]]; then
      continue
    elif [[ -f "${abs_path}.md" ]]; then
      continue
    elif [[ -d "$abs_path" ]]; then
      continue
    else
      echo "  ❌ Broken link in $filepath: $link"
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done < "$filepath"
done

if [[ $BROKEN_LINKS -eq 0 ]]; then
  echo "  ✅ All links are valid"
else
  echo "  ❌ Found $BROKEN_LINKS broken links"
fi

# 2. Check for metadata headers in docs/
echo ""
echo "📋 Checking for metadata headers in docs/..."

MISSING_HEADERS=0
for filepath in $(find "$REPO_ROOT/docs" -name "*.md" -type f); do
  if ! grep -q '^---$' "$filepath"; then
    echo "  ⚠️  Missing metadata header: $filepath"
    MISSING_HEADERS=$((MISSING_HEADERS + 1))
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $MISSING_HEADERS -eq 0 ]]; then
  echo "  ✅ All docs have metadata headers"
else
  echo "  ❌ Found $MISSING_HEADERS files without headers"
fi

# 3. Check for metadata headers in root .md files
echo ""
echo "📋 Checking for metadata headers in root .md files..."

ROOT_MISSING=0
for filepath in "$REPO_ROOT"/*.md; do
  if [[ -f "$filepath" ]] && ! grep -q '^---$' "$filepath"; then
    echo "  ⚠️  Missing metadata header: $filepath"
    ROOT_MISSING=$((ROOT_MISSING + 1))
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ROOT_MISSING -eq 0 ]]; then
  echo "  ✅ All root .md files have metadata headers"
else
  echo "  ❌ Found $ROOT_MISSING root files without headers"
fi

# 4. Check for duplicate content (basic check)
echo ""
echo "🔬 Checking for potential duplicate content..."

DUPLICATE_PATTERNS=(
  "pre-push.sh"
  "flutter pub get"
  "npm ci"
  "flutter analyze"
  "npx jest"
  "sudo pg_ctlcluster"
)

DUPLICATE_FOUND=0
for pattern in "${DUPLICATE_PATTERNS[@]}"; do
  COUNT=$(grep -r --include="*.md" "$pattern" "$REPO_ROOT/docs" 2>/dev/null | wc -l)
  if [[ $COUNT -gt 5 ]]; then
    echo "  ⚠️  Pattern '$pattern' appears $COUNT times in docs/ (may indicate duplication)"
    DUPLICATE_FOUND=$((DUPLICATE_FOUND + 1))
    if [[ "$STRICT" == true ]]; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

if [[ $DUPLICATE_FOUND -eq 0 ]]; then
  echo "  ✅ No obvious duplicate content detected"
else
  echo "  ℹ️  Found $DUPLICATE_FOUND patterns that may indicate duplication"
fi

# 5. Check for archived docs being referenced as active
echo ""
echo "🗃️  Checking for references to archived docs..."

ARCHIVED_REFERENCES=0
for filepath in $(find "$REPO_ROOT" -name "*.md" -type f -not -path "*/docs/archived/*" -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null); do
  if grep -qE 'docs/design/navigation-v2\.md|docs/experience-split-plan\.md|docs/quality/review-2026-07-08\.md' "$filepath" 2>/dev/null; then
    # Check if it's referencing the archived version
    if ! grep -qE 'docs/archived/navigation-v2\.md|docs/archived/experience-split-plan\.md|docs/archived/quality-review-2026-07-08\.md' "$filepath" 2>/dev/null; then
      echo "  ⚠️  Non-archived reference to archived doc in: $filepath"
      ARCHIVED_REFERENCES=$((ARCHIVED_REFERENCES + 1))
      if [[ "$STRICT" == true ]]; then
        ERRORS=$((ERRORS + 1))
      fi
    fi
  fi
done

if [[ $ARCHIVED_REFERENCES -eq 0 ]]; then
  echo "  ✅ All archived doc references are correct"
else
  echo "  ℹ️  Found $ARCHIVED_REFERENCES references to archived docs"
fi

# Final report
echo ""
echo "=== Documentation Validation Report ==="
echo "Broken links: $BROKEN_LINKS"
echo "Missing headers (docs/): $MISSING_HEADERS"
echo "Missing headers (root): $ROOT_MISSING"
echo "Potential duplicates: $DUPLICATE_FOUND"
echo "Archived references: $ARCHIVED_REFERENCES"
echo "Total errors: $ERRORS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
  echo "✅ All documentation checks passed!"
  exit 0
else
  echo "❌ Found $ERRORS documentation issues."
  exit 1
fi
