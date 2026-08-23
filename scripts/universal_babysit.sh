#!/bin/bash

# Universal Babysit Script for Agatha Track
# Integrates with existing babysit infrastructure
# Handles: review collection, conflict resolution, CI fixing, merging
# Usage: ./scripts/universal_babysit.sh --pr <number|url> [--merge] [--dry-run] [--model composer-2.5]

REPO_ROOT=$(git rev-parse --show-toplevel)
PR_NUMBER=""
PR_URL=""
PR_DATA=""
MERGE_AFTER_FIX=false
DRY_RUN=false
MODEL="composer-2.5"
MAX_ITERATIONS=10
ITERATION=0
FIXES_APPLIED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      shift
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        PR_NUMBER="$1"
        PR_URL="https://github.com/KanopeeKa/AgathaCheck/pull/$1"
      elif [[ "$1" =~ ^https://github.com/.*/pull/([0-9]+) ]]; then
        PR_NUMBER="${BASH_REMATCH[1]}"
        PR_URL="$1"
      else
        PR_URL="$1"
        PR_NUMBER=$(echo "$1" | grep -oE '[0-9]+' | tail -1)
      fi
      ;;
    --merge)
      MERGE_AFTER_FIX=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --model)
      shift
      MODEL="$1"
      ;;
    --iterations)
      shift
      MAX_ITERATIONS="$1"
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 --pr <number|url> [--merge] [--dry-run] [--model composer-2.5] [--iterations N]"
      exit 1
      ;;
  esac
  shift
done

# Validate PR number
if [[ -z "$PR_NUMBER" ]]; then
  echo "${RED}Error: --pr argument is required${NC}"
  exit 1
fi

echo -e "${GREEN}=== Universal Babysit for PR #$PR_NUMBER ===${NC}"
echo "Model: $MODEL"
echo "Merge after fix: $MERGE_AFTER_FIX"
echo "Dry run: $DRY_RUN"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# Get PR data using gh CLI
get_pr_data() {
  PR_DATA=$(gh pr view "$PR_NUMBER" --repo KanopeeKa/AgathaCheck --json number,title,state,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,reviewRequests,statusCheckRollup 2>/dev/null || echo "{}")
  
  if [[ -z "$PR_DATA" || "$PR_DATA" == "{}" ]]; then
    echo "${RED}Error: Could not fetch PR data${NC}"
    return 1
  fi
  
  echo "$PR_DATA" > /tmp/pr_data_$PR_NUMBER.json
  return 0
}

# Check if we should halt
should_halt() {
  local pr_data="$1"
  
  # Check for do-not-merge label - this is a true halt condition
  if echo "$pr_data" | jq -e '.labels[]?.name == "do-not-merge"' >/dev/null 2>&1; then
    echo "${RED}Halt: do-not-merge label present${NC}"
    return 0
  fi
  
  # Check for autonomous-revoked label
  if echo "$pr_data" | jq -e '.labels[]?.name == "autonomous-revoked"' >/dev/null 2>&1; then
    echo "${RED}Halt: autonomous-revoked label present${NC}"
    return 0
  fi
  
  # BLOCKED merge state due to CI failures should NOT halt - babysit should fix them!
  
  # Check if draft and merge intended - don't halt, just note
  if echo "$pr_data" | jq -e '.isDraft == true' >/dev/null 2>&1 && [[ "$MERGE_AFTER_FIX" == true ]]; then
    echo "${YELLOW}Note: PR is draft, will mark ready for review after fixes${NC}"
    return 1
  fi
  
  # Check mergeable status - CONFLICTING can be resolved by babysit
  local mergeable=$(echo "$pr_data" | jq -r '.mergeable // "UNKNOWN"')
  local merge_state=$(echo "$pr_data" | jq -r '.mergeStateStatus // "UNKNOWN"')
  
  if [[ "$mergeable" == "CONFLICTING" ]]; then
    echo "${YELLOW}Note: PR has merge conflicts - babysit will resolve${NC}"
    return 1
  fi
  
  # BLOCKED due to CI is expected - babysit will fix and retry
  if [[ "$merge_state" == "BLOCKED" ]]; then
    echo "${YELLOW}Note: Merge blocked by CI - babysit will fix and retry${NC}"
    return 1
  fi
  
  return 1
}

# Sync with base branch
sync_base() {
  echo -e "${YELLOW}Syncing with base branch...${NC}"
  
  local base_branch=$(echo "$PR_DATA" | jq -r '.baseRefName')
  local head_branch=$(echo "$PR_DATA" | jq -r '.headRefName')
  
  # Use existing babysit sync script
  if [[ -f "$REPO_ROOT/scripts/babysit_sync_base.sh" ]]; then
    if ./scripts/babysit_sync_base.sh --pr "$PR_NUMBER" --push; then
      echo -e "${GREEN}  Synced successfully${NC}"
      return 0
    else
      echo -e "${RED}  Sync failed${NC}"
      return 1
    fi
  else
    echo -e "${YELLOW}  babysit_sync_base.sh not found, manual sync${NC}"
    git fetch origin "$base_branch"
    if git rebase "origin/$base_branch" 2>/dev/null; then
      if [[ "$DRY_RUN" == false ]]; then
        git push origin HEAD --force-with-lease
      fi
      return 0
    else
      return 1
    fi
  fi
}

# Collect and triage review threads
collect_and_triage() {
  echo -e "${YELLOW}Collecting review threads...${NC}"
  
  local collect_output
  collect_output=$(node "$REPO_ROOT/scripts/babysit_pr_reviews.js" collect --pr "$PR_NUMBER" 2>/dev/null || echo "{}")
  
  if [[ -z "$collect_output" || "$collect_output" == "{}" ]]; then
    echo "  No review threads found"
    return 0
  fi
  
  # Save to file for processing
  echo "$collect_output" > /tmp/review_threads_$PR_NUMBER.json
  
  # Check for Copilot threads
  local copilot_count=$(echo "$collect_output" | jq '.summary.copilotCount // 0')
  local total_threads=$(echo "$collect_output" | jq '.threads | length // 0')
  
  echo "  Found $total_threads total threads ($copilot_count from Copilot)"
  
  if [[ $copilot_count -gt 0 || $total_threads -gt 0 ]]; then
    echo "  Triage required"
    
    # Post triage comment
    local triage_comment="## Babysit Triage Summary

PR: #$PR_NUMBER  
Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')  
Status: Triage in progress

Review Threads Found: $total_threads
- Copilot: $copilot_count threads
- Human: $((total_threads - copilot_count)) threads

Next Steps
- Triaging all unresolved threads
- Applying fixes for must-fix issues
- Creating debt issues for deferred concerns
- Pushing fixes and re-running CI"
    
    if [[ "$DRY_RUN" == false ]]; then
      echo "$triage_comment" | gh pr comment "$PR_NUMBER" --repo KanopeeKa/AgathaCheck --body-file -
    else
      echo "  [DRY RUN] Would post triage comment"
    fi
    
    return 1
  fi
  
  echo -e "${GREEN}  No unresolved threads${NC}"
  return 0
}

# Apply fixes based on review threads
apply_fixes() {
  local threads_file="/tmp/review_threads_$PR_NUMBER.json"
  
  if [[ ! -f "$threads_file" ]]; then
    echo "  No review threads file"
    return 0
  fi
  
  echo -e "${YELLOW}Applying fixes...${NC}"
  
  local threads=$(cat "$threads_file")
  local fixes_applied=0
  
  # Process each thread
  echo "$threads" | jq -c '.threads[] | select(.isResolved == false)' | while read -r thread; do
    local path=$(echo "$thread" | jq -r '.path // empty')
    local line=$(echo "$thread" | jq -r '.line // empty')
    local body=$(echo "$thread" | jq -r '.body // empty')
    local author=$(echo "$thread" | jq -r '.author.login // "unknown"')
    
    if [[ -z "$path" || -z "$body" ]]; then
      continue
    fi
    
    echo "  Processing: $path:$line ($author)"
    
    # Skip if file doesn't exist
    if [[ ! -f "$REPO_ROOT/$path" ]]; then
      echo "    -> File not found, skipping"
      continue
    fi
    
    # Fix 1: Broken links
    if echo "$body" | grep -qi "broken.*link\|invalid.*link\|does not exist\|file not found"; then
      echo "    -> Fixing broken link"
      local bad_link=$(echo "$body" | grep -oE '\[[^\]]*\]\([^)]*\)' | head -1)
      if [[ -n "$bad_link" ]]; then
        local link_path=$(echo "$bad_link" | grep -oE '\([^)]*\)' | tr -d '()' | sed 's/#.*//')
        if [[ "$link_path" == "API.md" ]]; then
          sed -i "s|${bad_link}|[API Reference](/docs/architecture/api-reference.md)|g" "$REPO_ROOT/$path"
          fixes_applied=$((fixes_applied + 1))
        elif [[ "$link_path" == "./API.md" ]]; then
          sed -i "s|${bad_link}|[API Reference](/docs/architecture/api-reference.md)|g" "$REPO_ROOT/$path"
          fixes_applied=$((fixes_applied + 1))
        fi
      fi
    fi
    
    # Fix 2: Missing metadata/frontmatter
    if echo "$body" | grep -qi "missing.*metadata\|frontmatter\|header\|yaml"; then
      echo "    -> Adding metadata header"
      if ! head -1 "$REPO_ROOT/$path" | grep -q '^---$'; then
        local title=$(grep -m1 '^# ' "$REPO_ROOT/$path" | sed 's/^# //' | head -c 60 || echo "Untitled")
        local date=$(date +%Y-%m-%d)
        
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
        (cat /tmp/frontmatter.txt && cat "$REPO_ROOT/$path") > /tmp/new_file
        mv /tmp/new_file "$REPO_ROOT/$path"
        fixes_applied=$((fixes_applied + 1))
      fi
    fi
    
    # Fix 3: Outdated references
    if echo "$body" | grep -qi "outdated\|old.*path\|moved\|renamed"; then
      echo "    -> Updating outdated references"
      if echo "$body" | grep -qi "API\.md"; then
        sed -i 's|API\.md|docs/architecture/api-reference.md|g' "$REPO_ROOT/$path"
        fixes_applied=$((fixes_applied + 1))
      fi
    fi
    
    # Fix 4: Relative to absolute paths
    if echo "$body" | grep -qi "relative.*path\|use.*absolute"; then
      echo "    -> Converting relative to absolute paths"
      sed -i 's|\./|/|g' "$REPO_ROOT/$path"
      fixes_applied=$((fixes_applied + 1))
    fi
    
  done
  
  FIXES_APPLIED=$((FIXES_APPLIED + fixes_applied))
  echo -e "  ${GREEN}Applied $fixes_applied fixes in this iteration${NC}"
  return $((fixes_applied > 0 ? 0 : 1))
}

# Resolve merge conflicts
resolve_conflicts() {
  echo -e "${YELLOW}Checking for merge conflicts...${NC}"
  
  if git ls-files --unmerged | grep -q .; then
    echo "  Merge conflicts detected"
    
    local conflicts=$(git ls-files --unmerged)
    local resolved=0
    
    for file in $conflicts; do
      echo "    Processing: $file"
      
      if git checkout --ours "$file" 2>/dev/null; then
        echo "      -> Kept our version"
        resolved=$((resolved + 1))
      elif git checkout --theirs "$file" 2>/dev/null; then
        echo "      -> Kept their version"
        resolved=$((resolved + 1))
      else
        echo "      -> Manual resolution required"
      fi
    done
    
    if [[ $resolved -gt 0 ]]; then
      echo -e "  ${GREEN}Auto-resolved $resolved conflicts${NC}"
      git add -A
      if [[ "$DRY_RUN" == false ]]; then
        git commit -m "chore: auto-resolve merge conflicts" || true
      fi
    fi
    
    if git ls-files --unmerged | grep -q .; then
      echo -e "  ${RED}Conflicts remain, manual resolution needed${NC}"
      return 1
    fi
    
    echo -e "  ${GREEN}All conflicts resolved${NC}"
    return 0
  fi
  
  echo "  No conflicts"
  return 0
}

# Run pre-push validation
run_prepush() {
  echo -e "${YELLOW}Running pre-push validation...${NC}"
  
  if [[ -f "$REPO_ROOT/scripts/pre-push-changed.sh" ]]; then
    if ./scripts/pre-push-changed.sh; then
      echo -e "  ${GREEN}pre-push-changed.sh passed${NC}"
      return 0
    else
      echo -e "  ${RED}pre-push-changed.sh failed${NC}"
      return 1
    fi
  fi
  
  echo "  pre-push-changed.sh not found, skipping"
  return 0
}

# Run documentation validation
run_docs_validation() {
  echo -e "${YELLOW}Running documentation validation...${NC}"
  
  if [[ -f "$REPO_ROOT/scripts/validate_docs.sh" ]]; then
    if ./scripts/validate_docs.sh --strict 2>&1; then
      echo -e "  ${GREEN}Documentation validation passed${NC}"
      return 0
    else
      echo -e "  ${RED}Documentation validation failed${NC}"
      return 1
    fi
  fi
  
  echo "  validate_docs.sh not found, skipping"
  return 0
}

# Check CI status
check_ci() {
  echo -e "${YELLOW}Checking CI status...${NC}"
  
  local ci_status=$(echo "$PR_DATA" | jq -r '.statusCheckRollup.nodes[]?.state // "UNKNOWN"' | head -1)
  local ci_conclusion=$(echo "$PR_DATA" | jq -r '.statusCheckRollup.nodes[]?.conclusion // "UNKNOWN"' | head -1)
  
  echo "  CI Status: $ci_status / $ci_conclusion"
  
  if [[ "$ci_status" == "COMPLETED" && "$ci_conclusion" == "SUCCESS" ]]; then
    echo -e "  ${GREEN}CI passed${NC}"
    return 0
  elif [[ "$ci_status" == "FAILURE" || "$ci_conclusion" == "FAILURE" ]]; then
    echo -e "  ${RED}CI failed${NC}"
    return 1
  else
    echo -e "  ${YELLOW}CI pending or unknown${NC}"
    return 2
  fi
}

# Wait for CI
wait_for_ci() {
  local timeout_min=${1:-30}
  local interval_sec=${2:-30}
  local start_time=$(date +%s)
  
  echo -e "${YELLOW}Waiting for CI (timeout: ${timeout_min}min)...${NC}"
  
  while [[ $(($(date +%s) - start_time)) -lt $((timeout_min * 60)) ]]; do
    get_pr_data >/dev/null 2>&1
    
    local ci_status=$(echo "$PR_DATA" | jq -r '.statusCheckRollup.nodes[]?.state // "UNKNOWN"' | head -1)
    local ci_conclusion=$(echo "$PR_DATA" | jq -r '.statusCheckRollup.nodes[]?.conclusion // "UNKNOWN"' | head -1)
    
    echo "  CI: $ci_status / $ci_conclusion"
    
    if [[ "$ci_status" == "COMPLETED" && "$ci_conclusion" == "SUCCESS" ]]; then
      echo -e "  ${GREEN}CI passed${NC}"
      return 0
    elif [[ "$ci_status" == "FAILURE" || "$ci_conclusion" == "FAILURE" ]]; then
      echo -e "  ${RED}CI failed${NC}"
      return 1
    fi
    
    sleep $interval_sec
  done
  
  echo -e "  ${RED}CI timeout reached${NC}"
  return 1
}

# Merge PR
merge_pr() {
  echo -e "${YELLOW}Attempting to merge PR...${NC}"
  
  local is_draft=$(echo "$PR_DATA" | jq -r '.isDraft // false')
  local mergeable=$(echo "$PR_DATA" | jq -r '.mergeable // "UNKNOWN"')
  local merge_state=$(echo "$PR_DATA" | jq -r '.mergeStateStatus // "UNKNOWN"')
  
  if [[ "$is_draft" == "true" ]]; then
    echo "  PR is draft, marking ready for review"
    if [[ "$DRY_RUN" == false ]]; then
      gh pr ready "$PR_NUMBER" --repo KanopeeKa/AgathaCheck
    else
      echo "  [DRY RUN] Would mark PR as ready"
    fi
    return 1
  fi
  
  if [[ "$mergeable" != "MERGEABLE" ]]; then
    echo -e "  ${RED}PR not mergeable: $mergeable / $merge_state${NC}"
    return 1
  fi
  
  if [[ "$DRY_RUN" == false ]]; then
    echo "  Merging PR..."
    if gh pr merge "$PR_NUMBER" --repo KanopeeKa/AgathaCheck --squash --auto; then
      echo -e "  ${GREEN}PR merged successfully${NC}"
      return 0
    else
      echo -e "  ${RED}Merge failed${NC}"
      return 1
    fi
  else
    echo "  [DRY RUN] Would merge PR"
    return 0
  fi
}

# Main babysit loop
main() {
  # Get PR data
  if ! get_pr_data; then
    exit 1
  fi
  
  # Check if we should halt
  if should_halt "$PR_DATA"; then
    exit 0
  fi
  
  # Mark as ready if draft
  local is_draft=$(echo "$PR_DATA" | jq -r '.isDraft // false')
  if [[ "$is_draft" == "true" ]]; then
    echo -e "${YELLOW}PR is draft, marking ready for review...${NC}"
    if [[ "$DRY_RUN" == false ]]; then
      gh pr ready "$PR_NUMBER" --repo KanopeeKa/AgathaCheck
    fi
  fi
  
  # Main loop
  while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
    ITERATION=$((ITERATION + 1))
    echo ""
    echo -e "${GREEN}=== Iteration $ITERATION/$MAX_ITERATIONS ===${NC}"
    
    # Step 0: Sync with base
    if ! sync_base; then
      echo -e "${YELLOW}Sync failed, retrying...${NC}"
      continue
    fi
    
    # Step 1: Collect and triage reviews
    if ! collect_and_triage; then
      # Reviews need triage, apply fixes
      if apply_fixes; then
        : # Fixes applied
      else
        echo "  No fixes could be auto-applied"
      fi
    fi
    
    # Step 2: Resolve conflicts
    if ! resolve_conflicts; then
      echo -e "${YELLOW}Conflicts remain, need manual resolution${NC}"
      if [[ "$DRY_RUN" == false ]]; then
        git add -A
        git commit -m "chore: conflict resolution attempt $ITERATION" || true
        git push origin HEAD --force-with-lease || true
      fi
      continue
    fi
    
    # Step 3: Run validations
    if ! run_prepush; then
      echo -e "${YELLOW}Pre-push validation failed${NC}"
      continue
    fi
    
    if ! run_docs_validation; then
      echo -e "${YELLOW}Documentation validation failed${NC}"
      continue
    fi
    
    # Step 4: Push changes
    if [[ "$DRY_RUN" == false ]]; then
      git add -A
      if git diff --cached --quiet; then
        echo "  No changes to push"
      else
        git commit -m "fix: auto-fix review issues (iteration $ITERATION)" || true
        git push origin HEAD --force-with-lease || true
      fi
    else
      echo "  [DRY RUN] Would push changes"
    fi
    
    # Step 5: Wait for CI
    local ci_result
    ci_result=$(check_ci)
    
    case "$ci_result" in
      0)
        echo -e "  ${GREEN}CI passed${NC}"
        ;;
      1)
        echo -e "  ${RED}CI failed, checking logs...${NC}"
        continue
        ;;
      2)
        echo -e "  ${YELLOW}CI pending, waiting...${NC}"
        wait_for_ci 15 30
        ;;
    esac
    
    # Step 6: Re-collect reviews after push
    get_pr_data >/dev/null 2>&1
    if ! collect_and_triage; then
      continue
    fi
    
    # Step 7: Check if all issues resolved
    echo -e "${YELLOW}Checking if all issues resolved...${NC}"
    
    local has_threads=$(echo "$PR_DATA" | jq -r '.reviewRequests.totalCount // 0')
    
    if [[ "$has_threads" == "0" ]]; then
      echo -e "${GREEN}All review threads resolved!${NC}"
      
      # Step 8: Merge if requested
      if [[ "$MERGE_AFTER_FIX" == true ]]; then
        if merge_pr; then
          echo -e "${GREEN}=== PR #$PR_NUMBER MERGED SUCCESSFULLY ===${NC}"
          exit 0
        else
          echo -e "${YELLOW}Merge failed or blocked${NC}"
          exit 1
        fi
      else
        echo -e "${GREEN}=== PR #$PR_NUMBER READY FOR MERGE ===${NC}"
        exit 0
      fi
    fi
    
  done
  
  echo -e "${RED}=== Max iterations ($MAX_ITERATIONS) reached ===${NC}"
  echo "Summary:"
  echo "  - Fixes applied: $FIXES_APPLIED"
  echo "  - Iterations: $ITERATION"
  echo "  - Final status: Requires manual intervention"
  exit 1
}

# Run main
main
