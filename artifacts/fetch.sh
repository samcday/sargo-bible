#!/bin/sh
# Fetch one stock artifact from the first mirror that serves it, and refuse
# anything whose SHA-256 does not match the manifest.
#   artifacts/fetch.sh <artifact-name> [destination-dir]
# Names and mirrors come from artifacts/<build>.json. Needs curl, python3, sha256sum.
set -eu
name=$1; dest=${2:-.}
here=$(cd "$(dirname "$0")" && pwd)
python3 - "$here" "$name" <<'PY' | {
import json,sys,glob
here,name=sys.argv[1],sys.argv[2]
for f in glob.glob(here+'/*.json'):
    m=json.load(open(f))
    for a in m['artifacts']:
        if a['name']==name:
            print(a['sha256'], a['bytes']); [print(u) for u in a['mirrors']]; sys.exit(0)
sys.exit('unknown artifact: '+name)
PY
  read -r want size
  while read -r url; do
    echo "trying $url" >&2
    if curl -fL --retry 3 -o "$dest/$name.part" "$url"; then
      got=$(sha256sum "$dest/$name.part" | cut -c1-64)
      if [ "$got" = "$want" ]; then mv "$dest/$name.part" "$dest/$name"; echo "ok $name ($size bytes) sha256 $got"; exit 0; fi
      echo "hash mismatch from $url: $got" >&2; rm -f "$dest/$name.part"
    fi
  done
  echo "no mirror served a matching $name" >&2; exit 1
}
