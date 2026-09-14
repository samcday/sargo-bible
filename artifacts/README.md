# Stock artifacts

Content-addressed manifests of the Google-published artifacts this book cites,
with every known mirror. The repository stores hashes, not blobs. A reader
with any copy of a file can prove it is the real one; a reader with none can
fetch it from whichever mirror is still alive:

```sh
artifacts/fetch.sh sargo-sp2a.220505.008-factory-071e368a.zip /tmp
```

`fetch.sh` walks the mirror list in order and deletes anything whose SHA-256
does not match the manifest.

| Manifest | Build | Contents |
| --- | --- | --- |
| [`SP2A.220505.008.json`](SP2A.220505.008.json) | the final sargo build | factory image, full OTA, both driver tarballs, hashes of the boot/bootloader/radio images inside |

Mirror policy, in order of trust:

1. Google's `dl.google.com` URL (canonical; may vanish).
2. A GitHub release on this repository (`stock-<BUILD>`), one asset per file. Free, no bandwidth metering, deletable only by the repository owner.
3. Wayback Machine captures of the canonical URL, cited with the `id_` raw-content form so the bytes come back unmodified. Only captures whose download hashed correctly are listed.
4. An Internet Archive *item* (planned; requires an archive.org account to upload).

Source code is archived separately: the kernel commit is in Software Heritage as
`swh:1:rev:ab4493f31457eea175568b18b8300d4d12aaeea8` and the snapshot of
`https://android.googlesource.com/kernel/msm` taken 2026-09-14 includes branch
`android-msm-bonito-4.9-android12L` at that commit.

Git LFS was considered and rejected: the free tier's 10 GB monthly bandwidth
would be exhausted by a handful of clones of a 1.8 GB file, whereas release
assets carry no such meter.
