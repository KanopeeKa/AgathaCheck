---
title: Auto-fix script for documentation PRs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [documentation]
---

#!/bin/bash

# Auto-fix script for documentation PRs
# Integrates with Agatha Track's babysit infrastructure
# Usage: ./scripts/auto_fix_docs.sh --pr <number|url> [--dry-run]

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
DRY_RUN=false
PR_NUMBER=""
PR_URL=""
FIXED_ISSUES=0
MAX_ITERATIONS=3
ITERATION=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      shift
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        PR_NUMBER="$1"
      elif [[ "$1" =~ ^https://github.com/.*/pull/([0-9]+) ]]; then
        PR_NUMBER="${BASH_REMATCH[1]}"
      else
        PR_URL="$1"
      fi
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

# Get PR info
if [[ -z "$PR_NUMBER" && -z "$PR_URL" ]]; then
  echo "Error: --pr argument is required"
  exit 1
fi

# Resolve PR number
if [[ -n "$PR_URL" ]]; then
  PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+' | tail -1)
fi

if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: Could not determine PR number"
  exit 1
fi

echo "Auto-fixing documentation issues for PR #$PR_NUMBER"

# Function to collect review threads
collect_reviews() {
  local pr_num="$1"
  node "$REPO_ROOT/scripts/babysit_pr_reviews.js" collect --pr "$pr_num" 2>/dev/null | \
    jq -r '.threads[] | select(.isResolved == false) | @base64' | \
    while read -r line; do
      echo "$line" | base64 -d
    done
}

# Function to apply fixes for common issues
apply_fixes() {
  local threads_json="$1"
  local fixes_applied=0

  # Parse threads and apply fixes
  echo "$threads_json" | jq -c '.[]' | while read -r thread; do
    local path=$(echo "$thread" | jq -r '.path // empty')
    local line=$(echo "$thread" | jq -r '.line // empty')
    local body=$(echo "$thread" | jq -r '.body // empty')
    local author=$(echo "$thread" | jq -r '.author.login // empty')

    if [[ -z "$path" || -z "$body" ]]; then
      continue
    fi

    echo "  Processing review: $path:$line"

    # Fix 1: Broken markdown links
    if echo "$body" | grep -qi "broken.*link\|invalid.*link\|does not exist"; then
      echo "    -> Fixing broken link"
      # Extract the problematic link from the comment
      local bad_link=$(echo "$body" | grep -oE '\[[^\]]*\]\([^)]*\)' | head -1)
      if [[ -n "$bad_link" ]]; then
        # Try to find the correct path
        local link_path=$(echo "$bad_link" | grep -oE '\([^)]*\)' | tr -d '()')
        local fixed_link=$(echo "$link_path" | sed 's|^API\.md|docs/architecture/api-reference.md|; s|^docs/|/docs/|')
        
        if [[ -f "$REPO_ROOT/${link_path#/}" || -f "$REPO_ROOT/${link_path#/}.md" ]]; then
          sed -i "s|${bad_link}|${bad_link}|g" "$REPO_ROOT/$path"
          fixes_applied=$((fixes_applied + 1))
        fi
      fi
    fi

    # Fix 2: Missing metadata headers
    if echo "$body" | grep -qi "missing.*metadata\|frontmatter\|header"; then
      echo "    -> Adding metadata header"
      if ! head -1 "$REPO_ROOT/$path" | grep -q '^---$'; then
        # Extract title from first heading
        local title=$(grep -m1 '^# ' "$REPO_ROOT/$path" | sed 's/^# //' | head -c 60)
        local date=$(date +%Y-%m-%d)
        
        # Create frontmatter
        cat > /tmp/frontmatter.txt << EOF
---
title: $title
owner: Documentation Team
audience: both
status: active
last_updated: $date
tags: [documentation]
---

EOF
        # Prepend to file
        cat /tmp/frontmatter.txt "$REPO_ROOT/$path" > /tmp/temp_file && \
          mv /tmp/temp_file "$REPO_ROOT/$path"
        fixes_applied=$((fixes_applied + 1))
      fi
    fi

    # Fix 3: Outdated references
    if echo "$body" | grep -qi "outdated\|old.*path\|moved.*to"; then
      echo "    -> Updating outdated reference"
      if echo "$body" | grep -q "API\.md"; then
        sed -i 's|API\.md|docs/architecture/api-reference.md|g' "$REPO_ROOT/$path"
        fixes_applied=$((fixes_applied + 1))
      fi
    fi

    # Fix 4: Relative path to absolute
    if echo "$body" | grep -qi "relative.*path\|absolute.*path"; then
      echo "    -> Converting relative to absolute paths"
      # Find all relative markdown links and convert
      grep -n '\[.*\](\./' "$REPO_ROOT/$path" | while read -r match; do
        local line_num=$(echo "$match" | cut -d: -f1)
        local rel_path=$(echo "$match" | grep -oE '\./[^)]*' | head -1)
        local abs_path=$(echo "$rel_path" | sed 's|\./||g')
        sed -i "${line_num}s|${rel_path}|/${abs_path}|g" "$REPO_ROOT/$path"
        fixes_applied=$((fixes_applied + 1))
      done
    fi

  done

  echo "  Applied $fixes_applied fixes"
  return $fixes_applied
}

# Function to handle merge conflicts
resolve_conflicts() {
  echo "Checking for merge conflicts..."
  
  if git ls-files --unmerged | grep -q .; then
    echo "  Merge conflicts detected"
    
    # Use existing babysit sync script
    ./scripts/babysit_sync_base.sh --pr "$PR_NUMBER" --push
    
    # Check if conflicts remain
    if git ls-files --unmerged | grep -q .; then
      echo "  Conflicts remain after sync"
      return 1
    fi
    
    echo "  Conflicts resolved"
    return 0
  fi
  
  echo "  No conflicts"
  return 0
}

# Function to run validation
run_validation() {
  echo "Running validation..."
  if ./scripts/validate_docs.sh --strict 2>&1; then
    echo "  Validation passed"
    return 0
  else
    echo "  Validation failed"
    return 1
  fi
}

# Main loop
while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
  ITERATION=$((ITERATION + 1))
  echo ""
  echo "=== Iteration $ITERATION ==="

  # Step 1: Sync with base
  echo "Syncing with base branch..."
  ./scripts/babysit_sync_base.sh --pr "$PR_NUMBER" --check

  # Step 2: Collect reviews
  echo "Collecting review threads..."
  REVIEW_THREADS=$(collect_reviews "$PR_NUMBER")
  
  if [[ -z "$REVIEW_THREADS" ]]; then
    echo "  No unresolved review threads"
  else
    echo "  Found $(echo "$REVIEW_THREADS" | jq -s 'length') unresolved threads"
    echo "$REVIEW_THREADS" | jq .
  fi

  # Step 3: Apply fixes
  if [[ -n "$REVIEW_THREADS" ]]; then
    echo "Applying fixes..."
    apply_fixes "$REVIEW_THREADS"
  fi

  # Step 4: Resolve conflicts
  resolve_conflicts

  # Step 5: Run validation
  if run_validation; then
    echo "All issues resolved!"
    
    # Mark as ready for review
    if [[ "$DRY_RUN" == false ]]; then
      echo "Marking PR as ready for review..."
      gh pr ready "$PR_NUMBER" --repo "$REPO_ROOT"
    else
      echo "[DRY RUN] Would mark PR as ready for review"
    fi
    
    exit 0
  fi

  # Step 6: Commit changes
  if [[ "$DRY_RUN" == false ]]; then
    git add -A
    git commit -m "docs: auto-fix review issues (iteration $ITERATION)" || true
    git push origin HEAD
  else
    echo "[DRY RUN] Would commit and push changes"
  fi

done

echo "Max iterations ($MAX_ITERATIONS) reached"
exit 1
