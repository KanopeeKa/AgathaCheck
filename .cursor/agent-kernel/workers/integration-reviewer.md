# Worker brief: integration reviewer

Independent final pass before phase PR ready or post-parallel merge.

## Inputs

- PR diff or phase branch vs base
- `router_risk`, `protocols[]` from Router
- Ownership map if sprint parallel work

## Checklist

- [ ] Matches phase single-sentence outcome
- [ ] No AuthZ bypass or data exposure
- [ ] No API breakage for mobile clients (if API touched)
- [ ] Migration safe (if DB touched)
- [ ] Tests match invariants in `testing.md`
- [ ] Shelter regression considered if shared code touched (Pet Care work)
- [ ] No dead code / drive-by refactors
- [ ] Strengthen did not silently widen scope

Return: must-fix list, nits, merge recommendation.
