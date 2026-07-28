# Adding a package

Open a pull request. CI runs the whole pipeline against it — build, sign, index, check — with a
throwaway key, so nothing from a fork touches the feed's own key.

## What a package needs

```
packages/<name>/upstream.sh   the version and its sha256 pins — data, no logic
packages/<name>/fetch.sh      sources upstream.sh, downloads, verifies, stages
owfeed.yml                    one entry under packages:, unless the upstream ships a built .apk
```

The split is what lets the hourly job update a package: it rewrites `upstream.sh` and nothing else,
so the diff a reviewer sees is a version and its checksums.

**Everything downloaded is pinned by sha256.** A checksum served by the same host from the same
release is not a verification of it — whoever can replace one can replace the other. A pin recorded
in this repository is.

**Where the author signs their releases, that signature is checked too.** Set `SIG_KEY` and
`SIG_KEY_ID` in `upstream.sh`, pin the key under [`keys/`](keys/), and `fetch.sh` runs
`owfeed verify-artifact` before the package enters the feed. A pin proves the bytes have not changed
since someone looked at them; a signature says who produced them. Only the second one can justify an
update merging itself.

## Two shapes

**A. The upstream already publishes a built `.apk`.** Take it as it is. Its own CI compiled whatever
needed compiling, and rebuilding here would produce something the maintainer never tested. Drop it
into `dist/noarch/` (or `dist/<arch>/`) and it is signed and indexed unchanged — see
`packages/luci-theme-footstrap/fetch.sh`.

**B. The upstream publishes binaries or files, not a package.** Stage them into
`staging/<name>/…` the way they should install — the payload *is* a piece of the root filesystem —
and add a `packages:` entry so owfeed builds them. See `packages/podkop-updater/fetch.sh`.

For a compiled binary, list the architectures it runs on and template the path:

```yaml
- name: mytool
  build: mkpkg
  arch: [x86_64, aarch64_generic, mipsel_24kc]
  files: ./staging/mytool/{arch}
```

A static binary — Go, Rust — needs no OpenWrt SDK, only a build for the right target. One upstream
artifact usually serves several OpenWrt architectures that share a GOARCH; the fetch script does
that mapping.

## What CI will refuse

`owfeed doctor` gates the pull request, and `owfeed smoke` installs the result on a real OpenWrt
image afterwards — following the published install snippet, and failing if `apk` asks for
`--allow-untrusted`. Between them they catch a package that builds cleanly and cannot be installed.

The findings that catch most first attempts:

- `arch: all` — apk rejects it. Use `noarch`.
- `/etc/config/foo` shipped but not in `conffiles:` — sysupgrade would replace the user's settings
  with the package defaults on every firmware upgrade, silently.
- `.po` files in the payload — LuCI reads compiled `.lmo`. Point `i18n.from:` at them instead.
- A version apk cannot parse — after `~` only hex digits, `-r<n>` last.

Each finding says what it costs and what to do.

## Updating a package

Usually you do not: an hourly job notices new upstream releases and opens the pull request for you,
with the pins recomputed from the bytes that release served.

To do it by hand, edit `upstream.sh` — the version and the checksums — and open a pull request.
Nothing else changes.

### Automatic merging

`AUTO_MERGE="yes"` in `upstream.sh` asks GitHub to merge the update once the checks pass. It is
offered only where the upstream publishes a detached signature beside its artifact, because that is
provenance from someone other than this feed. Where an upstream publishes checksums alone, an update
waits for a person: a checksum from the same host as the artifact tells you the download was not
corrupted, not that it was not replaced.

The checks are not bypassed in either case.
