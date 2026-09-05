# Protocol: dependency-review

**When:** Adding or upgrading npm/pub dependencies, security-sensitive libraries.

---

## 1. Assess

- Why needed vs existing in-repo solution
- Maintenance status and license
- Security history (`npm audit`, advisories)
- Transitive weight
- Node/Flutter version compatibility
- Bundle/app size impact

## 2. Invariants

- No dependency for trivial one-liner convenience
- Crypto/security: mature libraries only — no custom crypto
- High/critical npm audit → linked issue or fix before merge (CI blocks high+)

## 3. Verification

```bash
cd server && npm audit
cd e2e && npm audit
```
