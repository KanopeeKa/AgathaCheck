#!/usr/bin/env python3
"""Measure architecture size from Git-tracked files; writes Markdown to /tmp."""
from __future__ import annotations
import argparse, collections, datetime as dt, json, os, re, subprocess
from pathlib import Path, PurePosixPath

EXT={'.dart','.js','.mjs','.cjs','.ts','.tsx','.jsx','.sh','.sql'}
DESIGN=('artifacts/','attached_assets/','screenshots/','.canvas/')
BUILD=('build/','flutter_app/build/','.dart_tool/','coverage/','dist/','out/')
DEPS=('node_modules/','vendor/','.pub-cache/')
GEN_SUFFIX=('.g.dart','.freezed.dart','.mocks.dart','.gen.dart')
GEN_NAMES={'flutter_app/lib/l10n/app_localizations.dart'}
TEST_PARTS={'test','tests','__tests__','e2e'}

def git(root,*args): return subprocess.check_output(['git','-C',str(root),*args],text=True)
def under(p,roots): return any(p==r.rstrip('/') or p.startswith(r.rstrip('/')+'/') for r in roots)
def istest(p):
    return bool(set(PurePosixPath(p).parts)&TEST_PARTS) or bool(re.search(r'(?:^|[._-])(test|spec)\.[^.]+$',PurePosixPath(p).name.lower()))
def lines(path):
    """Physical and heuristic nonblank/noncomment line counts."""
    is_sql=path.suffix.lower()=='.sql'
    text=path.read_text(encoding='utf-8',errors='replace'); ls=text.splitlines(); n=0; block=False
    for raw in ls:
        s=raw.strip()
        if not s: continue
        while s:
            if block:
                j=s.find('*/')
                if j<0: s=''; break
                block=False; s=s[j+2:].strip(); continue
            if s.startswith('/*'): block=True; s=s[2:].strip(); continue
            if s.startswith('//') or s.startswith('#') or s.startswith('*') or (is_sql and s.startswith('--')): s=''; break
            j=s.find('/*')
            if j>=0:
                if s[:j].strip(): n+=1
                block=True; s=s[j+2:].strip(); continue
            n+=1; break
    return len(ls),n
def table(head,rows,align=None):
    if not rows:return '_None._\n'
    rows=[[str(x) for x in r] for r in rows]; widths=[len(x) for x in head]
    for r in rows:
        for i,x in enumerate(r):widths[i]=max(widths[i],len(x))
    fmt=lambda r:'| '+' | '.join(str(x).ljust(widths[i]) for i,x in enumerate(r))+' |'
    sep=[]
    for i,w in enumerate(widths):
        a=align[i] if align else 'left'; sep.append((':' if a=='left' else '')+'-'*max(3,w-1)+(':' if a=='right' else ''))
    return '\n'.join([fmt(head),'| '+' | '.join(sep)+' |',*[fmt(r) for r in rows]])+'\n'
def grouped(paths,metric,key):
    g=collections.defaultdict(list)
    for p in paths:g[key(p)].append(p)
    return [(k,len(v),f'{sum(metric[p][0] for p in v):,}',f'{sum(metric[p][1] for p in v):,}') for k,v in sorted(g.items())]
def scc(graph):
    ix=0; stack=[]; on=set(); ids={}; low={}; out=[]
    def visit(v):
        nonlocal ix
        ids[v]=low[v]=ix;ix+=1;stack.append(v);on.add(v)
        for w in graph.get(v,()):
            if w not in ids:visit(w);low[v]=min(low[v],low[w])
            elif w in on:low[v]=min(low[v],ids[w])
        if low[v]==ids[v]:
            c=[]
            while True:
                w=stack.pop();on.remove(w);c.append(w)
                if w==v:break
            if len(c)>1:out.append(sorted(c))
    for v in sorted(graph):
        if v not in ids:visit(v)
    return sorted(out)

def server_review_scope(root, candidates, entry='server/bin/server.js'):
    """Approximate active route-registration dependencies; not runtime import closure."""
    candidates=set(candidates); seen=set(); todo=[entry]
    irx=re.compile(r"(?:\bimport\s+(?:[^'\"]*?\s+from\s+)?|\bexport\s+[^'\"]*?\s+from\s+|\brequire\s*\()\s*['\"]([^'\"]+)['\"]",re.M)
    gated={('../routes/organizations.js'),('../routes/fosterPlacements.js'),('../routes/custodyTransfers.js')}
    while todo:
        p=todo.pop()
        if p in seen or p not in candidates:continue
        seen.add(p); text=(root/p).read_text(encoding='utf-8',errors='replace')
        for spec in irx.findall(text):
            if p=='server/bin/server.js' and spec in gated:continue
            if not spec.startswith('.'):continue
            q=os.path.normpath(str(PurePosixPath(p).parent/spec)).replace('\\','/')
            choices=(q,q+'.js',q+'.mjs',q+'/index.js')
            target=next((x for x in choices if x in candidates),None)
            if target and target not in seen:todo.append(target)
    return sorted(seen)

def shelter_family_server(p):
    """Conservative quality-review exclusion, not a runtime claim."""
    if not p.startswith('server/lib/'):return False
    name=PurePosixPath(p).name
    return bool(re.match(r'^(org|adoption|foster|fostering)',name,re.I)) or name in {'custodyTransfers.js','sessionDetail.js','deriveSessionStatus.js'}

def function_spans(root, paths):
    """Single-line-signature brace-span heuristic for JS/Dart; deliberately narrow."""
    found=[]
    control=re.compile(r'^\s*(if|for|while|switch|catch|else|try|do)\b')
    sig=re.compile(r'^\s*(?:export\s+)?(?:async\s+)?(?:function\s+)?(?:[\w<>?,.\[\] ]+\s+)?([A-Za-z_$][\w$]*)\s*\([^;{}]*\)\s*(?:async\s*)?(?:=>\s*)?\{\s*$')
    for p in paths:
        if PurePosixPath(p).suffix not in {'.js','.mjs','.ts','.tsx','.dart'}:continue
        raw=(root/p).read_text(encoding='utf-8',errors='replace').splitlines()
        clean=[]; block=False
        for line in raw:
            x=line
            if block:
                j=x.find('*/')
                if j<0:clean.append('');continue
                x=x[j+2:];block=False
            x=re.sub(r'//.*','',x)
            while '/*' in x:
                a=x.find('/*');b=x.find('*/',a+2)
                if b<0:x=x[:a];block=True;break
                x=x[:a]+x[b+2:]
            x=re.sub(r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"|`(?:\\.|[^`\\])*`",'""',x)
            clean.append(x)
        for i,line in enumerate(clean):
            m=sig.match(line)
            if not m or control.match(line):continue
            depth=0;started=False
            for j in range(i,len(clean)):
                depth+=clean[j].count('{')-clean[j].count('}')
                started=started or '{' in clean[j]
                if started and depth<=0:
                    found.append((j-i+1,p,i+1,m.group(1)));break
    return sorted(found,key=lambda x:(-x[0],x[1],x[2]))

def main():
    a=argparse.ArgumentParser();a.add_argument('--repo');a.add_argument('--output',default='/tmp/architecture-metrics.md');o=a.parse_args()
    root=Path(o.repo).resolve() if o.repo else Path(git(Path.cwd(),'rev-parse','--show-toplevel').strip())
    tracked=[p for p in git(root,'ls-files').splitlines() if p]
    manifest=json.loads((root/'docs/engineering/frozen-domains/manifest.json').read_text())
    frozen=manifest.get('sourceRoots',[])+manifest.get('serverRoots',[])+manifest.get('testRoots',[])
    active_surfaces=set(manifest.get('activeSurfacesToRemove',[]))
    excluded=collections.defaultdict(list); eligible=[]
    for p in tracked:
        if under(p,frozen):excluded['frozen manifest roots'].append(p)
        elif p in active_surfaces:excluded['manifest active surfaces to remove'].append(p)
        elif under(p,DESIGN):excluded['design/media outputs'].append(p)
        elif under(p,BUILD):excluded['build/tool outputs'].append(p)
        elif under(p,DEPS):excluded['dependency outputs'].append(p)
        elif p in GEN_NAMES or p.endswith(GEN_SUFFIX) or (p.startswith('flutter_app/lib/l10n/app_localizations_') and p.endswith('.dart')):excluded['generated source'].append(p)
        else:eligible.append(p)
    code=[p for p in eligible if PurePosixPath(p).suffix.lower() in EXT]
    excluded_code=[p for xs in excluded.values() for p in xs if PurePosixPath(p).suffix.lower() in EXT]
    metric={p:lines(root/p) for p in set(code+excluded_code)}
    flutter=[p for p in code if p.startswith('flutter_app/lib/')]
    server_inventory=[p for p in code if p.startswith('server/') and not istest(p)]
    server_scope=server_review_scope(root,server_inventory)
    server_complement=sorted(set(server_inventory)-set(server_scope))
    shelter_inventory=sorted(p for p in server_inventory if shelter_family_server(p))
    shelter_quality=sorted(set(server_scope)&set(shelter_inventory))
    shelter_complement=sorted(set(shelter_inventory)-set(server_scope))
    server_review=sorted(set(server_scope)-set(shelter_quality))
    all_tests=[p for p in code if istest(p)]
    jest_text=(root/'server/jest.config.active.cjs').read_text()
    frozen_jest={'server/'+x for x in re.findall(r"<rootDir>/(test/[^'\"]+)",jest_text)}
    e2e_text=(root/'e2e/scripts/frozen-e2e-specs.mjs').read_text()
    frozen_e2e_names=set(re.findall(r"['\"]([^'\"]+\.spec\.ts)['\"]",e2e_text))
    frozen_ci_tests=sorted(p for p in all_tests if p in frozen_jest or (p.startswith('e2e/') and PurePosixPath(p).name in frozen_e2e_names))
    tests=sorted(set(all_tests)-set(frozen_ci_tests))
    prod=sorted(set(flutter+server_review))
    def fg(p):
        x=PurePosixPath(p).parts
        if len(x)>=4 and x[2]=='features':return 'feature/'+x[3]
        if len(x)>=4 and x[2]=='core':return 'core/'+x[3]
        return x[2] if len(x)>2 else '(root)'
    def sg(p):
        x=PurePosixPath(p).parts;return x[1] if len(x)>2 else '(root/config)'
    def tg(p):
        for x in ('flutter_app','server','e2e'):
            if p.startswith(x+'/'):return x
        return p.split('/',1)[0]
    # Literal Dart directives only. Resolve package features and normalized relatives.
    rx=re.compile(r'^\s*(?:import|export|part)\s+[\'\"]([^\'\"]+)[\'\"]',re.M)
    ec=collections.Counter();ef=collections.defaultdict(set);graph=collections.defaultdict(set)
    for p in flutter:
        parts=PurePosixPath(p).parts
        if len(parts)<4 or parts[2]!='features':continue
        src=parts[3]
        for spec in rx.findall((root/p).read_text(encoding='utf-8',errors='replace')):
            target=None
            if spec.startswith('package:') and '/features/' in spec:target=spec.split('/features/',1)[1].split('/',1)[0]
            elif spec.startswith('.'):
                resolved=PurePosixPath(os.path.normpath(str(PurePosixPath(p).parent/spec)));rp=resolved.parts
                if len(rp)>=4 and rp[:3]==('flutter_app','lib','features'):target=rp[3]
            if target and target!=src:
                ec[src,target]+=1;ef[src,target].add(p);graph[src].add(target);graph.setdefault(target,set())
    cycles=scc(graph)
    pl=lambda ps:sum(metric[p][0] for p in ps);hl=lambda ps:sum(metric[p][1] for p in ps)
    commit=git(root,'rev-parse','HEAD').strip();stamp=dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    repo_label=git(root,'rev-parse','--show-toplevel').strip()
    try: repo_label=str(root.relative_to(Path(repo_label).resolve()))
    except ValueError: repo_label=str(root)
    script_rel='scripts/architecture/architecture-metrics.py'
    fspans=function_spans(root,prod)[:8]
    out=['---','title: Active codebase metrics headline','owner: Engineering','audience: agent','status: active','last_updated: '+stamp[:10],'tags: [architecture, metrics, generated]','---','','# Architecture size metrics (refined)','',f'Generated: {stamp} (runtime; commit-scoped counts below are stable)',f'Repository: `{repo_label}`',f'Git commit: `{commit}`','',
      '## Exact definitions','',
      '- **Review-scope production (headline):** active Flutter library after manifest/generated exclusions, including exclusion of `manifest.activeSurfacesToRemove`, plus the active server route-registration approximation from `server/bin/server.js`, minus the conservative Shelter-family server list below.',
      '- **Active server route-registration approximation:** recursive literal relative `import`, `export ... from`, and `require()` traversal from `server/bin/server.js`, with the three frozen routers whose `app.use` mounts are gated by `frozenDomainsEnabled()` suppressed as review policy: organizations, fosterPlacements, custodyTransfers. Their imports are static and therefore still load under ESM; only registration is gated. This approximation is not actual runtime import reachability or closure. External and dynamic imports are ignored.',
      '- **Server inventory complement:** tracked server source surviving path exclusions but not selected by that review-scope approximation. This is inventory, not a claim of dead or unloaded code: scripts, alternate entries, dynamic loads, and policy-suppressed imports can appear here.',
      '- **Review-safe tests:** code under a `test`, `tests`, `__tests__`, or `e2e` path segment, or with a `.test`/`.spec` filename, after manifest test-root exclusions, `server/jest.config.active.cjs` ignore entries, and exact spec basenames exported by `e2e/scripts/frozen-e2e-specs.mjs`.',
      '- **Shelter-family quality exclusion:** review-scope `server/lib` basenames beginning `org`, `adoption`, `foster`, or `fostering`, plus `custodyTransfers.js`, `sessionDetail.js`, and `deriveSessionStatus.js`. This conservative lexical list follows frozen Jest/domain naming and prevents frozen/mixed internals entering size ranking; it is not a statement that the modules cannot load.',
      '- Inventory is exactly `git ls-files`; untracked files are absent. Source extensions: '+', '.join(sorted(EXT))+'.',
      '- **Approximate nonblank/noncomment lines are heuristic**, not cloc: blank lines, whole-line comments and block-comment spans are removed; strings and SQL dialects are not parsed.','',
      '## Headline','',table(['Comparable scope','Files','Physical lines','Approx. nonblank noncomment'],[
        ('Review-scope production',len(prod),f'{pl(prod):,}',f'{hl(prod):,}'),
        ('  active Flutter library',len(flutter),f'{pl(flutter):,}',f'{hl(flutter):,}'),
        ('  active server registration approximation',len(server_review),f'{pl(server_review):,}',f'{hl(server_review):,}'),
        ('Review-safe tests',len(tests),f'{pl(tests):,}',f'{hl(tests):,}')],['left','right','right','right']),
      '## Classification audit','',table(['Class','Files','Physical lines','Meaning'],[
        ('Server registration approximation (before family exclusion)',len(server_scope),f'{pl(server_scope):,}','review-policy traversal'),
        ('Shelter-family removed from quality scope',len(shelter_quality),f'{pl(shelter_quality):,}','conservative lexical list'),
        ('Server inventory complement',len(server_complement),f'{pl(server_complement):,}','not selected by approximation'),
        ('Additional frozen CI tests removed',len(frozen_ci_tests),f'{pl(frozen_ci_tests):,}','active Jest + frozen E2E sets')],['left','right','right','left']),
      '### Shelter-family inventory excluded from quality totals/ranking','', 'Every matching file is excluded: `review scope; removed` means it was subtracted from the registration approximation, while `inventory complement` means it did not enter that approximation. Neither label claims runtime loading behavior.','', '\n'.join('- `'+p+'` — '+('review scope; removed' if p in shelter_quality else 'inventory complement') for p in shelter_inventory) if shelter_inventory else '_None._','',
      '### Additional frozen CI tests removed','', 'These are the non-manifest-root files selected by active Jest ignore entries or the frozen E2E set; manifest-root tests are already counted in path exclusions.','', '\n'.join('- `'+p+'`' for p in frozen_ci_tests) if frozen_ci_tests else '_None._','',
      '## Active Flutter library by feature/core','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(flutter,metric,fg),['left','right','right','right']),
      '## Active server route-registration approximation by area','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(server_review,metric,sg),['left','right','right','right']),
      '## Review-safe tests','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(tests,metric,tg),['left','right','right','right'])]
    biggest=sorted(prod,key=lambda p:(-metric[p][0],p))[:15]
    out+=['## Biggest 15 review-scope production files','',table(['File','Physical lines','Heuristic lines'],[(p,f'{metric[p][0]:,}',f'{metric[p][1]:,}') for p in biggest],['left','right','right']),
      '## Function-length heuristic: top 8','',
      'This is deliberately narrow and approximate: only JS/TS/Dart functions whose complete signature and opening brace are on one line are candidates. Comments and simple quoted strings are stripped, then physical lines are counted until braces balance. Multiline signatures are missed; regex literals, interpolation, unusual syntax, or braces in complex strings can distort spans. Use only as a triage signal, never a quality gate.','',
      table(['Function','File:line','Physical span'],[(name,f'{p}:{line}',span) for span,p,line,name in fspans],['left','left','right']),
      '## Cross-feature Flutter imports','',
      'Only literal Dart `import`, `export`, and `part` directives are scanned. Package paths resolve at `flutter_app/lib`; relative paths normalize from the importer. URI conditionals, interpolation, aliases and runtime references are ignored; self-feature edges are omitted.','',
      f'Unique directed feature edges: **{len(ec)}**; matching directives: **{sum(ec.values())}**.','',
      table(['Edge','Importing files','Directives'],[(f'{x} → {y}',len(ef[x,y]),ec[x,y]) for x,y in sorted(ec)],['left','right','right']),
      '### Cycles','',f'Strongly connected multi-feature components: **{len(cycles)}**. Components mean mutual reachability, not every simple cycle.','',
      ('\n'.join('- '+' ↔ '.join(c) for c in cycles)+'\n' if cycles else '_No multi-feature cycle found under these assumptions._\n')]
    er=[]
    for reason in ('frozen manifest roots','manifest active surfaces to remove','generated source','build/tool outputs','dependency outputs','design/media outputs'):
        members=excluded.get(reason,[]);sources=[p for p in members if PurePosixPath(p).suffix.lower() in EXT]
        er.append((reason,len(members),len(sources),f'{pl(sources):,}'))
    out+=['## Exclusions','',table(['Reason','Tracked files','Source files','Source physical lines'],er,['left','right','right','right']),
      f'Tracked files total: **{len(tracked):,}**. Eligible source files after path exclusions: **{len(code):,}**. Files outside exact headline definitions remain inventory only. Frozen CI test removals are classification removals in addition to path exclusions and are reported above.','',
      '## Reproduce','','```sh',f'python3 {script_rel} --repo "$(git rev-parse --show-toplevel)" --output /tmp/architecture-metrics.md','```','']
    Path(o.output).write_text('\n'.join(out),encoding='utf-8');print(o.output)
if __name__=='__main__':main()