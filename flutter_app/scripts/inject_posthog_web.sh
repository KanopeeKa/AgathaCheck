#!/usr/bin/env bash
# Injects PostHog web snippet into web/index.html before flutter build.
# Requires POSTHOG_API_KEY in the environment. If unset, removes the snippet block.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/web/index.html"
BEGIN='<!-- POSTHOG_WEB_BEGIN -->'
END='<!-- POSTHOG_WEB_END -->'

if [ ! -f "$INDEX" ]; then
  echo "inject_posthog_web: index.html not found at $INDEX" >&2
  exit 1
fi

if [ -z "${POSTHOG_API_KEY:-}" ]; then
  echo "inject_posthog_web: POSTHOG_API_KEY unset — removing PostHog web snippet"
  python3 - "$INDEX" "$BEGIN" "$END" <<'PY'
import sys
from pathlib import Path

path, begin, end = sys.argv[1:4]
text = Path(path).read_text()
if begin in text and end in text:
    start = text.index(begin)
    stop = text.index(end) + len(end)
    Path(path).write_text(text[:start] + text[stop:])
PY
  exit 0
fi

echo "inject_posthog_web: injecting PostHog EU web snippet"
python3 - "$INDEX" "$BEGIN" "$END" "$POSTHOG_API_KEY" <<'PY'
import sys
from pathlib import Path

path, begin, end, api_key = sys.argv[1:5]
text = Path(path).read_text()
snippet = f'''{begin}
  <script>
    !function(t,e){{var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){{function g(t,e){{var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){{t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}}}(p=t.createElement("script")).type="text/javascript",p.crossOrigin="anonymous",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){{var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e}},u.people.toString=function(){{return u.toString(1)+".people (stub)"}},o="capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags getFeatureFlag getFeatureFlagResult reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys getNextSurveyStep onSessionId".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])}},e.__SV=1)}}(document,window.posthog||[]);
    posthog.init("{api_key}", {{
      api_host: "https://eu.i.posthog.com",
      opt_out_capturing_by_default: true,
      persistence: "localStorage+cookie"
    }});
  </script>
{end}'''

if begin in text and end in text:
    start = text.index(begin)
    stop = text.index(end) + len(end)
    text = text[:start] + snippet + text[stop:]
else:
    text = text.replace('</head>', snippet + '\n</head>', 1)

Path(path).write_text(text)
PY
