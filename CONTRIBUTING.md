# Adding a package

Open a pull request. CI runs the whole pipeline against it — build, sign, index, check — with a
throwaway key, so nothing from a fork touches the feed's own key.

## What a package needs

Two things: a script that produces what should be installed, and an entry in `owfeed.yml`.

```
packages/<name>/fetch.sh     produces staging/<name>/… or dist/…
owfeed.yml                   one entry under packages:
```

**`fetch.sh` must pin what it downloads by sha256.** A checksum served by the same host from the
same release is not a verification of it; a pin recorded in this repository is.

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

`owfeed doctor` gates the pull request. The findings that catch most first attempts:

- `arch: all` — apk rejects it. Use `noarch`.
- `/etc/config/foo` shipped but not in `conffiles:` — sysupgrade would replace the user's settings
  with the package defaults on every firmware upgrade, silently.
- `.po` files in the payload — LuCI reads compiled `.lmo`. Point `i18n.from:` at them instead.
- A version apk cannot parse — after `~` only hex digits, `-r<n>` last.

Each finding says what it costs and what to do.

## Updating a package

Bump the version and the sha256 pins in its `fetch.sh`, in one pull request. Nothing else changes.
