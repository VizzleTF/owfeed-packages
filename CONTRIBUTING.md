# Adding and updating packages

*[Русская версия](CONTRIBUTING_ru.md)*

A package in this feed is **a file of values**. There is no per-package script: one shared
implementation fetches every package, so an update rewrites data rather than code, and adding a
package does not start with copying somebody else's shell.

```
packages/<name>/upstream.sh   the version, the checksums, which key signs it
packages/<name>/files/…       optional: what the feed adds, e.g. an init script
keys/…                        pinned public keys of the people whose packages we carry
owfeed.yml                    a packages: entry, only when owfeed has to build it
```

---

## I want to add a package

Which of two shapes it is depends on what the upstream publishes.

### It publishes a built `.apk`

Nothing to build. The feed distributes exactly what the author released and adds its signature.

```sh
# packages/luci-theme-footstrap/upstream.sh
KIND="apk"
REPO="VizzleTF/luci-theme-footstrap"
VERSION="0.11.6-r1"
ARTIFACT="luci-theme-footstrap-0.11.6-r1.apk"
SHA256="e2e7bde2…"

SIG_KEY="keys/vizzletf-release.pub"     # when the author signs releases
SIG_KEY_ID="18c63865e2bcf8d6"
AUTO_MERGE="yes"
```

That is the whole package. **No entry in `owfeed.yml`** — owfeed is not building anything.

### It publishes binaries or loose files

owfeed builds the package, so there are two files: the values, and an `owfeed.yml` entry describing
what comes out.

```sh
# packages/podkop-updater/upstream.sh
KIND="binaries"
REPO="VizzleTF/podkop_autoupdater"
VERSION="0.3.4-r1"
BINARY_DEST="/usr/bin/podkop_updater"

# <artifact>  <sha256>  <the OpenWrt architectures it runs on>
ARTIFACTS="
podkop_updater-amd64  2d64d66c…  x86_64
podkop_updater-arm64  ba045eaa…  aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic
"
AUTO_MERGE="no"
```

```yaml
# owfeed.yml
- name: podkop-updater
  build: mkpkg
  arch: [x86_64, aarch64_cortex-a53, aarch64_cortex-a72, aarch64_generic]
  version-from: file:./staging/podkop-updater.version
  files: ./staging/podkop-updater/{arch}
  description: "One line. LuCI truncates past 512 bytes."
```

Anything the feed itself ships — an init script, a default config — goes in
`packages/<name>/files/` and is copied into every architecture.

A static binary needs the right build target and no OpenWrt SDK, so one upstream artifact usually
serves several OpenWrt architectures. Which ones is a judgement about what upstream's builds
actually run on, which is why it lives beside the package and not inside a tool.

### Then

```sh
./tools/fetch.sh packages/<name>
owfeed build && owfeed sign && owfeed index && owfeed doctor && owfeed smoke
```

Open a pull request. CI runs exactly that with a throwaway key, so nothing from a fork comes near
the feed's own.

---

## I want to update a package

Usually you do not. An hourly job asks each upstream for its latest release and opens the pull
request for you, with the checksums recomputed from the bytes that release served.

By hand: edit `VERSION` and the checksums in `upstream.sh`. Nothing else changes.

```sh
./tools/fetch.sh packages/<name>     # fails if a checksum does not match
```

---

## I want it to update itself

`AUTO_MERGE="yes"` asks GitHub to merge an update once the checks pass.

It is offered **only where the upstream publishes a detached signature** beside its artifact, and
that signature is verified against a key pinned in `keys/`. That is provenance from someone other
than this feed. Where an upstream publishes checksums alone, an update waits for a person: a
checksum served by the same host as the artifact tells you the download was not corrupted, not that
it was not replaced.

The checks are never skipped either way.

---

## I build in my own CI and want my package in this feed

You do not push into this feed, and that is deliberate. Publishing here would need either this
feed's signing key or write access to it, and either one would let every contributor publish
anything under this feed's name — including a higher version of `dropbear`.

So nothing crosses the boundary in either direction:

```
your repository                              this feed
──────────────                               ─────────
owfeed build                                 hourly: sees your release
owfeed sign          ← your key              verifies your signature against keys/
publish a release    ──────────────────────► adds the feed's signature
                                             indexes, publishes
```

You never hold this feed's key. This feed never holds a token for your repository.

**Your signature is not stripped.** apk signature blocks are additive, so the package a router
installs carries yours *and* this feed's. A subscriber who installs your public key too can verify
you directly; one who trusts only this feed still works.

### On your side

[`examples/gitlab-ci.yml`](examples/gitlab-ci.yml) and [`examples/owfeed.yml`](examples/owfeed.yml)
are a working pair. In short:

```sh
owfeed build
owfeed sign                       # your key, from a masked CI variable
owfeed doctor --require-origin    # every package says which repository it is from
owfeed smoke                      # it installs on a real OpenWrt image
# publish dist/ as release assets
```

`--require-origin` is not ceremony. The `url:` is carried into the index and shown by `apk info` on
the router, so it is the only thing telling a user who published what they installed. `repo-commit:
env:CI_COMMIT_SHA` records which commit produced it.

### On this side

One pull request, once, adding `packages/<name>/upstream.sh` with your repository, your public key
and the first pin — plus your key under `keys/`. After that the hourly job follows your releases and
opens the updates itself.

Adding your key is the diff that deserves a second look, so expect it to be read carefully. That is
the moment this feed decides to vouch for you; everything after it is mechanical.

---

## What the checks will refuse

`owfeed doctor` and `owfeed smoke` gate every pull request. The findings that catch most first
attempts:

| | |
|---|---|
| `arch: all` | apk rejects it as uninstallable. Use `noarch`. |
| `/etc/config/foo` shipped but not in `conffiles:` | sysupgrade replaces the user's settings with your defaults on every firmware upgrade, silently. |
| `.po` files in the payload | LuCI reads compiled `.lmo`. Point `i18n.from:` at them. |
| A version apk cannot parse | after `~` only hex digits; `-r<n>` last. |
| A package that builds and will not install | `smoke` installs the feed on a real OpenWrt image and fails if apk asks for `--allow-untrusted`. |

Each finding says what it costs and what to do about it.

---

## Why a pin, and why a key

**Everything downloaded is pinned by sha256 in this repository.** A checksum served by the same host
from the same release is not a verification of it — whoever can replace one can replace the other. A
pin recorded here is, because it came from a moment a person looked at it.

**Where the author signs, that signature is checked too**, against a key pinned in `keys/`. A pin
proves the bytes have not changed since someone looked; a signature says who produced them. Only the
second can justify an update merging itself.

Everything in this feed is signed with **the feed's** key, not the authors'. That is not a
preference: apk takes its trust from the signed index, and only this feed can sign an index
describing everything this feed carries. Signing packages with their authors' keys would mean
installing every author's key on every router, each one a trust anchor for *every* package name
rather than for theirs.

So the feed's signature is worth exactly what was checked before it was applied. That is what these
rules are for.
