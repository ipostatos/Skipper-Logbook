#!/usr/bin/env bash
#
# Extract named screenshot attachments from an .xcresult bundle into a flat
# folder of PNGs. Primary path uses `xcparse` (robust across Xcode versions);
# falls back to `xcresulttool` if xcparse is unavailable.
#
# Usage: extract-screenshots.sh <path/to/Result.xcresult> <output-dir>
set -euo pipefail

XCRESULT="${1:?usage: extract-screenshots.sh <xcresult> <outdir>}"
OUTDIR="${2:?usage: extract-screenshots.sh <xcresult> <outdir>}"

mkdir -p "$OUTDIR"

if command -v xcparse >/dev/null 2>&1; then
  echo "→ extracting with xcparse"
  # --test uses the attachment's own name for the filename.
  xcparse screenshots --test "$XCRESULT" "$OUTDIR"
else
  echo "→ xcparse not found; falling back to xcresulttool"
  # Enumerate attachments and export each by id, naming by its suggested name.
  # Xcode 16's xcresulttool requires the `object` subcommand + `--legacy` for
  # the classic JSON graph; older Xcode accepts the same without `object`.
  TMP_JSON="$(mktemp)"
  xcrun xcresulttool get object --legacy --format json --path "$XCRESULT" > "$TMP_JSON" 2>/dev/null \
    || xcrun xcresulttool get --legacy --format json --path "$XCRESULT" > "$TMP_JSON" 2>/dev/null \
    || xcrun xcresulttool get --format json --path "$XCRESULT" > "$TMP_JSON"

  export_by_id() {
    local rid="$1" dest="$2"
    xcrun xcresulttool export object --legacy --type file --id "$rid" \
      --path "$XCRESULT" --output-path "$dest" 2>/dev/null \
    || xcrun xcresulttool export --legacy --type file --id "$rid" \
      --path "$XCRESULT" --output-path "$dest" 2>/dev/null \
    || xcrun xcresulttool export --type file --id "$rid" \
      --path "$XCRESULT" --output-path "$dest" 2>/dev/null || true
  }
  export -f export_by_id
  export XCRESULT

  python3 - "$OUTDIR" "$TMP_JSON" <<'PY'
import json, subprocess, sys, os
outdir, jpath = sys.argv[1], sys.argv[2]
data = json.load(open(jpath))
seen = set()

def walk(node):
    if isinstance(node, dict):
        pr = node.get("payloadRef", {})
        rid = pr.get("id", {}).get("_value")
        fn = node.get("filename", {}).get("_value") or node.get("name", {}).get("_value")
        if rid and fn and fn.lower().endswith((".png", ".jpg", ".jpeg", ".heic")):
            dest = os.path.join(outdir, fn)
            key = (rid, fn)
            if key not in seen:
                seen.add(key)
                subprocess.run(["bash", "-lc", f'export_by_id "{rid}" "{dest}"'], check=False)
        for v in node.values():
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)

walk(data)
PY
fi

echo "→ screenshots in $OUTDIR:"
ls -la "$OUTDIR" || true
COUNT="$(find "$OUTDIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) | wc -l | tr -d ' ')"
echo "→ captured $COUNT image(s)"
if [ "$COUNT" -eq 0 ]; then
  echo "::warning::No screenshots were extracted from the xcresult."
fi
