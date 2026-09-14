# Fingerprint firmware manifest, build SP2A.220505.008

`fingerprint-manifest.json` records the 16 stock files a QSEE client needs to
load the sargo fingerprint trusted application: `fpctzappfingerprint.{mdt,b00–b07}`
and `cmnlib64.{mdt,b00–b05}`, all from `/vendor/firmware`. It holds lengths,
SHA-256 digests and ELF structure only. **No firmware bytes are in this
repository.**

The file was produced on a sargo unit from its retained stock vendor
filesystem (`source`, `access` fields describe that read) and later checked
byte-for-byte against `vendor.img` from Google's factory image; see
`provenance.md` §5. Fields:

| Field | Meaning |
| --- | --- |
| `vendor_build` | `ro.vendor.build.fingerprint` of the filesystem the files were read from |
| `files.<name>.bytes`, `.sha256` | length and digest of the exact file |
| `structure.<app>.elf_class`, `.machine`, `.program_headers` | ELF header facts of the `.mdt` |
| `structure.<app>.segment_bytes` | file size of each program header, in order; equals the `.bNN` lengths |
| `structure.<app>.raw_mdt_equals_b00_plus_b01` | the `.mdt` is the concatenation of the first two segments |
| `source`, `block_read_only`, `access`, `captured_at` | how and when the on-device read happened |
