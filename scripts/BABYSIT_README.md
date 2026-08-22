# Babysit Automation for Agatha Track

This directory contains automated PR babysitting and validation scripts that integrate with Agatha Track's existing agent infrastructure.

## Overview

| Script | Purpose | Integration |
|--------|---------|-------------|
| `validate_docs.sh` | Documentation integrity validation | Standalone, CI, babysit |
| `auto_fix_docs.sh` | Auto-fix common documentation issues | GitHub Actions, CLI |
| `universal_babysit.sh` | Full PR babysit workflow | CLI, executes existing skills |

## Quick Start

### 1. Validate Documentation

```bash
# Run validation on current repo
./scripts/validate_docs.sh

# Strict mode (exit on any issue)
./scripts/validate_docs.sh --strict

# Check specific directory
./scripts/validate_docs.sh  # Checks all markdown files
```

### 2. Auto-Fix Documentation Issues

```bash
# Auto-fix issues in current PR
./scripts/auto_fix_docs.sh --pr 696

# Dry run (show what would be fixed)
./scripts/auto_fix_docs.sh --pr 696 --dry-run
```

### 3. Full Babysit Workflow

```bash
# Babysit a PR (collect reviews, fix, merge)
./scripts/universal_babysit.sh --pr 696 --merge

# Babysit without merging
./scripts/universal_babysit.sh --pr 696

# Dry run
./scripts/universal_babysit.sh --pr 696 --dry-run
```

## GitHub Actions Integration

The repository includes a workflow file at `.github/workflows/docs-validation.yml` that:

1. **Triggers on**: PRs touching markdown files
2. **Runs**: Documentation validation on every push
3. **Comments**: Posts validation results as PR comments
4. **Auto-fixes**: Attempts to auto-fix common issues
5. **Blocks merge**: If validation fails

### Customizing the Workflow

To enable auto-fix in CI, update `.github/workflows/docs-validation.yml`:

```yaml
jobs:
  auto-fix-docs:
    needs: validate-docs
    if: failure() && needs.validate-docs.result == 'failure'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/auto_fix_docs.sh --pr ${{ github.event.pull_request.number }}
```

## Integration with Existing Skills

These scripts integrate with Agatha Track's existing agent infrastructure:

### Used By These Scripts

| Existing Script | Used By | Purpose |
|----------------|---------|---------|
| `babysit_pr_reviews.js` | `universal_babysit.sh`, `auto_fix_docs.sh` | Collect review threads |
| `babysit_sync_base.sh` | `universal_babysit.sh` | Sync with base branch |
| `pre-push-changed.sh` | `universal_babysit.sh` | Pre-push validation |

### Compatible With These Skills

| Skill | Compatibility | Notes |
|-------|--------------|-------|
| `/babysit` | ✅ Full | Lightweight mode |
| `/babysit-plus` | ✅ Full | Autonomous PR operator |
| `/babysit-uat` | ✅ Full | Final PR to main |
| `/execute-plan` | ✅ Partial | Use for phase delegation |

## Features

### Validation Script (`validate_docs.sh`)

Checks:
- ✅ Broken markdown links (including anchor links)
- ✅ Missing YAML frontmatter headers
- ✅ Duplicate content patterns
- ✅ References to archived documentation
- ✅ Metadata header consistency

**Exit codes:**
- `0`: All checks passed
- `1`: Validation errors found

### Auto-Fix Script (`auto_fix_docs.sh`)

Auto-fixes:
- ✅ Broken links (API.md → docs/api-reference.md)
- ✅ Missing metadata headers
- ✅ Outdated references
- ✅ Relative to absolute path conversions
- ✅ Merge conflict resolution (simple cases)

**Limitations:**
- Only fixes issues it can confidently resolve
- Posts summary of fixes applied
- Requires manual review for complex issues

### Universal Babysit (`universal_babysit.sh`)

Full workflow:
1. ✅ Sync with base branch
2. ✅ Collect review threads (Copilot, human)
3. ✅ Triage and classify comments
4. ✅ Apply auto-fixes
5. ✅ Resolve merge conflicts
6. ✅ Run pre-push validation
7. ✅ Wait for CI
8. ✅ Merge when ready

**Options:**
- `--pr <number|url>`: Required, PR to babysit
- `--merge`: Merge PR after all issues resolved
- `--dry-run`: Show what would happen without making changes
- `--model`: Specify model (default: composer-2.5)
- `--iterations N`: Max iterations (default: 10)

## Usage Patterns

### Pattern 1: Manual PR Babysitting

```bash
# Start babysitting PR #696
./scripts/universal_babysit.sh --pr 696 --merge

# This will:
# 1. Sync with main
# 2. Collect all review threads
# 3. Apply auto-fixes
# 4. Resolve conflicts
# 5. Push changes
# 6. Wait for CI
# 7. Merge when green
```

### Pattern 2: Documentation-Only Validation

```bash
# Validate all docs
./scripts/validate_docs.sh --strict

# Auto-fix issues
./scripts/auto_fix_docs.sh --pr 696
```

### Pattern 3: CI Integration

Add to your workflow:

```yaml
- name: Validate Documentation
  run: ./scripts/validate_docs.sh --strict

- name: Auto-Fix
  if: failure()
  run: ./scripts/auto_fix_docs.sh --pr ${{ github.event.pull_request.number }}
```

### Pattern 4: Scheduled Validation

```yaml
name: Nightly Documentation Validation
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/validate_docs.sh --strict
```

## Configuration

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `GITHUB_TOKEN` | GitHub API access | Required for PR operations |
| `REPO_ROOT` | Repository root | Auto-detected |

### Customizing Validation Rules

Edit `validate_docs.sh` to:
- Add custom patterns to `DUPLICATE_PATTERNS`
- Modify `ARCHIVED_MAP` for archived files
- Adjust frontmatter requirements in `has_frontmatter()`

### Customizing Auto-Fixes

Edit `auto_fix_docs.sh` to:
- Add new fix patterns
- Modify existing fix logic
- Adjust risk thresholds

## Best Practices

### For Maintainers

1. **Always run validation before merging**
   ```bash
   ./scripts/validate_docs.sh --strict
   ```

2. **Use babysit for complex PRs**
   ```bash
   ./scripts/universal_babysit.sh --pr 696 --merge
   ```

3. **Enable CI validation**
   - Ensure `.github/workflows/docs-validation.yml` is active
   - Add to branch protection rules

### For Contributors

1. **Run validation locally**
   ```bash
   ./scripts/validate_docs.sh
   ```

2. **Fix issues before pushing**
   - Address all validation errors
   - Update outdated links
   - Add missing metadata

3. **Use PR template**
   - Follow the PR template guidelines
   - Link to relevant issues

## Troubleshooting

### Common Issues

**Issue: Validation fails with broken links**
```bash
# Check which links are broken
./scripts/validate_docs.sh 2>&1 | grep "Broken link"

# Fix the specific file
nano docs/some-file.md
```

**Issue: Auto-fix doesn't fix my issue**
- Auto-fix only handles common patterns
- Complex issues require manual fixing
- Check the triage comment for details

**Issue: Babysit gets stuck**
- Increase `--iterations` for complex PRs
- Use `--dry-run` to see what would happen
- Check for merge conflicts manually

### Debug Mode

Add `set -x` at the top of any script to enable debug output:

```bash
# Temporary debug
sed -i '1s|^|set -x\n|' scripts/universal_babysit.sh
./scripts/universal_babysit.sh --pr 696 --dry-run
```

## Performance

| Script | Avg Runtime | Complexity |
|--------|-------------|------------|
| `validate_docs.sh` | 5-10s | O(n) where n = files |
| `auto_fix_docs.sh` | 10-30s | O(n * m) where m = review threads |
| `universal_babysit.sh` | 1-10min | O(iterations * checks) |

**Optimization tips:**
- Limit paths in workflow triggers
- Use `--strict` only when needed
- Cache GitHub API responses

## Security

- ✅ No secrets required for read-only operations
- ✅ `GITHUB_TOKEN` only needed for write operations
- ✅ All scripts validate inputs
- ✅ No external network calls (except GitHub API)

## Contributing

To improve these scripts:

1. **Fork and PR**
   - Follow existing patterns
   - Add tests if possible
   - Document new features

2. **Testing**
   ```bash
   # Test validation
   ./scripts/validate_docs.sh
   
   # Test with real PR
   ./scripts/universal_babysit.sh --pr 696 --dry-run
   ```

3. **Adding new checks**
   - Add to `validate_docs.sh`
   - Add corresponding fixes to `auto_fix_docs.sh`
   - Document in this README

## License

Part of Agatha Track - MIT License

## See Also

- [Agent Efficiency Docs](docs/agent-efficiency/)
- [Autonomous PR Policy](docs/agent-efficiency/autonomous-pr-policy.md)
- [Babysit Plus Skill](.cursor/skills/babysit-plus/SKILL.md)
- [Execute Plan Skill](.cursor/skills/execute-plan/SKILL.md)
