# sargo-bible

A thoroughly-researched, provenance-first reference for the **Google Pixel 3a
(`google/sargo`, Qualcomm SDM670)** — how the device actually works, with every
load-bearing claim tied to evidence: Google's published kernel sources, exact
stock build identifiers, hash-pinned firmware manifests, and working
implementations you can read and run.

Derived from the sargo bring-up work in
[samcday/pocketfed](https://github.com/samcday/pocketfed) (Fedora-based mobile
distro), [samcday/linux](https://github.com/samcday/linux), and
[samcday/sam-sargo](https://github.com/samcday/sam-sargo) (daily driver).

## The rules of this book

1. **No claim without proof.** Statements link a primary source: a Google
   source tree, a pinned build ID, a commit, a COPR build, or a measured
   on-device artifact. "Someone on the internet said" is not evidence.
2. **Stock provenance is pinned to exact builds.** The device's stock vendor
   is `SP2A.220505.008/8782922` — the *final* OTA Google shipped for sargo
   (September 2022 farewell build). Anything describing "stock" behavior is
   anchored to that build, not folklore.
3. **Volatile links get archive.org deep links.** Personal forges, gists, and
   pages that can rot are snapshotted (Wayback Machine) and cited with their
   timestamp, next to the live URL.
4. **Vendored beats remembered.** Where a source matters long-term (firmware
   manifests, kernels, protocol notes), the repo points at the exact vendored
   tree or hash rather than describing it from memory.
5. **Dense, machine-readable markdown.** Tables, short sections, explicit
   evidence columns — structured so tools (e.g. DeepWiki) can index it and
   humans can audit it.

## Chapters

- [fingerprint.md](fingerprint.md) — the FPC1020 + QSEE fingerprint stack:
  hardware pins, stock Android architecture, the secure-world protocol
  (QSEECOM app loading, FPC command map, Gatekeeper/Keymaster enrollment
  authorization, RPMB storage), the mainline implementation, and the
  acceptance evidence. **First vertical slice.**

## Local source map (the living parts)

| Tree | Role |
| --- | --- |
| `~/src/pocketfed` | distro + per-device evidence (`devices/google-sargo/diagnostics/`, `devices/google-sargo/fingerprint-trial/`) |
| `~/src/pocketfed-kernel-fpc-pool` | production kernel `.12` worktree (QSEECOM transport + `fpc1020` companion) |
| `~/src/sdm670-linux-patches` | sdm670 mainline patch stack |
| `~/src/sam-sargo` | daily-driver image; hardware issues tracked here (e.g. [#11](https://github.com/samcday/sam-sargo/issues/11)) |
| COPR [`samcday/kernel-sdm670-mainline`](https://copr.fedorainfracloud.org/coprs/samcday/kernel-sdm670-mainline/), [`samcday/pocketfed`](https://copr.fedorainfracloud.org/coprs/samcday/pocketfed/) | signed ARM64 package feeds |

## Status

Seeded 2026-09-14 with the fingerprint vertical slice. Later chapters
(camera, modem/eSIM, display, storage/boot contract) should follow the same
shape: one dense markdown file per subsystem, evidence-first, with the
stock-side contract separated from the Linux-side implementation.
