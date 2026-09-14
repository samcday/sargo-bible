#!/bin/sh
# Re-fetch every vendored file at the pinned commit and compare hashes.
set -eu
cd "$(dirname "$0")"
C=ab4493f31457eea175568b18b8300d4d12aaeea8
rc=0
while read -r sum path; do
  p=${path#./}
  got=$(curl -fsS "https://android.googlesource.com/kernel/msm/+/$C/$p?format=TEXT" | base64 -d | sha256sum | cut -c1-64)
  if [ "$got" = "$sum" ]; then echo "ok   $p"; else echo "FAIL $p (upstream $got)"; rc=1; fi
done < SHA256SUMS
sha256sum -c --quiet SHA256SUMS && echo "ok   local copies match SHA256SUMS"
exit $rc
