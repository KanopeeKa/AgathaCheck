#!/usr/bin/env python3
"""Generate draft execute-plan snapshots from the child plan markdown (single source of truth).

Usage: python3 .agents/plans/active-codebase-completion-e41f.gen_snapshots.py <out_dir>

Always write to a scratch <out_dir> and copy only the draft child you changed. The output has
null approval fields and a pending roadmap: never copy the roadmap or a stamped child (D, or any
bootstrapped child) over the files in .agents/plans/.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]  # repo root when run from .agents/plans/
PLANS = REPO / '.agents/plans'
ROADMAP = 'active-codebase-completion-e41f'
REVIEW = 'docs/architecture/reviews/active-codebase-review.md'
CHILDREN = [
    'active-codebase-batch-d-guardrails-e41f',
    'active-codebase-batch-e-backend-integrity-e41f',
    'active-codebase-batch-f-account-erasure-e41f',
    'active-codebase-batch-g-client-authority-e41f',
    'active-codebase-batch-h-ports-transport-e41f',
    'active-codebase-batch-i1-public-apis-e41f',
    'active-codebase-batch-i2-acyclic-graph-e41f',
    'active-codebase-batch-j-standards-e41f',
    'active-codebase-batch-k-final-acceptance-e41f',
]
GRANT = f'standing grant — roadmap {ROADMAP} (pending approve-autonomous {ROADMAP})'


def field(block, name):
    m = re.search(r'\|\s*\*\*' + re.escape(name) + r'\*\*\s*\|\s*`([^`]*)`\s*\|', block)
    if not m:
        raise SystemExit(f'missing field {name}')
    return m.group(1)


def fenced(block, label):
    m = re.search(r'\*\*' + re.escape(label) + r':\*\*\s*\n\s*```\n(.*?)```', block, re.S)
    if not m:
        raise SystemExit(f'missing fenced block {label}')
    return [ln.strip() for ln in m.group(1).splitlines() if ln.strip()]


def parse_child(plan_id):
    text = (PLANS / f'{plan_id}.md').read_text()
    base = field(text, 'base_branch')
    parts = re.split(r'\n### Phase ', text)[1:]
    phases = []
    for part in parts:
        header, _, body = part.partition('\n')
        title = header.split('—', 1)[1].strip() if '—' in header else header.strip()
        phases.append({
            'id': field(body, 'id'),
            'title': title,
            'branch': field(body, 'branch'),
            'allowed_paths': fenced(body, 'allowed_paths'),
            'forbidden_paths': fenced(body, 'forbidden_paths'),
            'allowed_exceptions': fenced(body, 'allowed_exceptions'),
            'spawn_allowed': field(body, 'spawn_allowed') == 'true',
            'spawn_config': None,
            'merge_method': 'squash',
            'exit_checklist': field(body, 'exit_checklist'),
            'status': 'pending',
            'status_reason': None,
            'status_detail': None,
            'debt_issue_refs': [],
            'pr_url': None,
            'pr_head_sha': None,
            'merge_commit': None,
        })
    ids = [p['id'] for p in phases]
    if ids != [str(i) for i in range(1, len(ids) + 1)]:
        raise SystemExit(f'{plan_id}: phase ids not sequential: {ids}')
    if phases[-1]['branch'] != base:
        raise SystemExit(f'{plan_id}: last phase branch must be the integration branch')
    return {
        'schema_version': 1,
        'plan_id': plan_id,
        'programme_ref': REVIEW,
        'approved_at': None,
        'approved_by': GRANT,
        'approved_until': None,
        'autonomy': 'active',
        'default_merge_mode': 'auto',
        'base_branch': base,
        'control_issue': None,
        'artifact_branch_policy': 'phase-branch',
        'phases': phases,
        'content_hash': None,
    }


def roadmap():
    return {
        'schema_version': 1,
        'plan_id': ROADMAP,
        'plan_kind': 'roadmap',
        'programme_ref': REVIEW,
        'approved_at': None,
        'approved_by': f'pending approve-autonomous {ROADMAP}',
        'approved_until': None,
        'autonomy': 'active',
        'default_merge_mode': 'auto',
        'base_branch': 'main',
        'control_issue': None,
        'artifact_branch_policy': 'phase-branch',
        'current_child_plan_id': None,
        'child_plans': [
            {'plan_id': c, 'status': 'pending', 'pr_url': None, 'merge_commit': None}
            for c in CHILDREN
        ],
        'phases': [{
            'id': 'orchestrate',
            'title': 'Roadmap orchestration (child plan bootstrap + tracking)',
            'branch': 'cursor/active-codebase-completion-orchestrate-e41f',
            'allowed_paths': [
                f'.agents/plans/{ROADMAP}.*',
                '.agents/plans/active-codebase-batch-*-e41f.*',
                'docs/architecture/reviews/**',
            ],
            'forbidden_paths': ['.github/workflows/**', 'server/**', 'flutter_app/**', 'e2e/**'],
            'allowed_exceptions': ['docs'],
            'spawn_allowed': False,
            'spawn_config': None,
            'merge_method': 'squash',
            'exit_checklist': 'governance',
            'status': 'pending',
            'status_reason': None,
            'status_detail': None,
            'debt_issue_refs': [],
            'pr_url': None,
            'merge_commit': None,
        }],
        'content_hash': None,
    }


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    out_dir = Path(sys.argv[1])
    snaps = {ROADMAP: roadmap()}
    for c in CHILDREN:
        snaps[c] = parse_child(c)
    for pid, snap in snaps.items():
        (out_dir / f'{pid}.snapshot.json').write_text(json.dumps(snap, indent=2, ensure_ascii=False) + '\n')
        n = len(snap['phases'])
        print(f'{pid}: {n} phase(s)')


if __name__ == '__main__':
    main()
