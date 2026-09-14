# Rules of this book (agent-facing)

`sargo-bible` documents how the Google Pixel 3a (`google/sargo`, Qualcomm
SDM670) actually works. The subject is the device as Google shipped it. The
immutable base is the final stock build and the kernel source Google published
for it; everything else (mainline ports, PocketFed, any distro) is at most a
*proof* that the documented understanding is correct.

Read this before writing or editing a chapter.

## 1. Evidence classes

Every load-bearing statement carries one of these tags, in a table column or
inline. A statement without a tag is a draft, not a fact.

| Tag | Meaning | Cite with |
| --- | --- | --- |
| `[G]` | Google-published source or artifact | commit hash, AOSP tag, or Google download URL plus SHA-256 |
| `[S]` | Stock binary from build `SP2A.220505.008`, examined statically | file path inside the image plus SHA-256; ELF offsets where relevant |
| `[M]` | Measured on a real sargo unit | which unit class (daily unit or lab unit), date, and what was probed |
| `[T]` | Third-party document | live URL plus Wayback URL with timestamp |
| `[I]` | Independent implementation proof | public repository URL at a commit, never a local path |

"Someone on the internet said" is not evidence. Press articles are context for
dates only, never for technical claims.

## 2. The pinned base

- Stock build: `google/sargo/sargo:12/SP2A.220505.008/8782922:user/release-keys`, the last build Google shipped for sargo. AOSP tag `android-12.1.0_r27`.
- Kernel source: `kernel/msm` branch `android-msm-bonito-4.9-android12L` at commit `ab4493f31457eea175568b18b8300d4d12aaeea8` (kernel tags `android-12.1.0_r0.17` and `android-12.1.0_r0.23`).
- Firmware identity: SHA-256 of each file, recorded in `vendor/firmware/`.

Cite the commit hash, never a branch name. Branch refs move; hashes do not.
`provenance.md` is the only place that establishes the base. Chapters refer to
it rather than restating it.

## 3. Volatile links

Personal forges, gists, blog posts and support pages rot. Cite them as
`[live](URL) ([archived YYYY-MM-DD](https://web.archive.org/web/TIMESTAMP/URL))`.
If the Wayback Machine has no snapshot, request one
(`https://web.archive.org/save/URL`) before the claim is merged. Google's
`android.googlesource.com` URLs are stable when they contain a commit hash.

## 4. Vendored primary sources

`vendor/` holds small, licence-compatible copies of the exact files chapters
quote (GPLv2 kernel sources, JSON manifests). Each vendored tree has a
`SHA256SUMS` and a note recording where it came from and the exact commit.
Never vendor proprietary firmware bytes or anything derived from them beyond
lengths, hashes and structural metadata. Do not vendor multi-gigabyte trees;
pin them by hash and give the fetch command.

## 5. What is not bible material

- Distro build numbers, package versions, COPR builds, CI runs, RPM names.
- Issue trackers, session logs, chat transcripts, local filesystem paths.
- Implementation narrative ("we tried X, then Y"). Keep the fact and its
  evidence; drop the story.
- Anything private: serial numbers, IMEI/ICCID/EID, network addresses, keys,
  credentials, proprietary binaries or disassembly listings.

If a fact was learned through an implementation, record the fact and tag it
`[M]` or `[S]`. The implementation may be linked once, as `[I]`, in a proof
section.

## 6. Chapter shape

One markdown file per subsystem. Suggested order:

1. Status: one sentence on how well the subsystem is understood, and what proves it.
2. Hardware: pins, buses, power, DT excerpt, all `[G]`/`[M]`.
3. Stock software split: which component does what in the shipped image.
4. Contract: the protocol or register-level interface, as tables.
5. Invariants and failure codes: ordering rules, error values, what they mean.
6. Proof: independent implementations that exercise the contract, `[I]`.
7. Prior art: who worked this out before, `[T]`.
8. Open questions: what is not yet pinned. Say so plainly instead of guessing.

Dense, machine-readable markdown: tables, short sections, an evidence column.
No emoji, no marketing adjectives.

## 7. Editing discipline

- Verify a claim against its cited source before changing it. If the source is
  unreachable, leave the claim and the citation alone and note the date you
  could not reach it.
- Corrections replace the wrong statement; they do not append "actually".
- Keep hashes, offsets and command numbers exactly as measured. Round nothing.
- A number with no evidence class is removed, not kept "for context".
