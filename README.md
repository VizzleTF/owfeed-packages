# owfeed community packages

An OpenWrt 25.12+ apk feed, built and published by [owfeed](https://github.com/VizzleTF/owfeed).

## Installing owfeed community packages

OpenWrt 25.12 and later, any architecture.

```sh
# HTTPS on a stock image needs these two first.
apk add ca-bundle libustream-mbedtls

wget https://vizzletf.github.io/owfeed-packages/owfeed-packages.pem -O /etc/apk/keys/owfeed-packages.pem
echo "https://vizzletf.github.io/owfeed-packages/releases/25.12/$(cat /etc/apk/arch)/packages.adb" > /etc/apk/repositories.d/owfeed-packages.list

# Neither of those two files survives a sysupgrade on its own.
printf '%s\n' /etc/apk/keys/owfeed-packages.pem /etc/apk/repositories.d/owfeed-packages.list >> /etc/sysupgrade.conf

apk update && apk add podkop-updater
```

> **Do not install the .apk file directly.** `apk add ./podkop-updater-*.apk` writes a pin on the package's content hash into `/etc/apk/world`, and that file survives sysupgrade. The package would then never be upgraded from this feed again. Add the repository and install by name.

> **Attended Sysupgrade will not carry these packages across.** `owut` forwards no custom repositories, and the sysupgrade server's `repository_allow_list` is empty by default, which denies everything. Either exclude these packages from the `owut` run and reinstall them afterwards, or use an ordinary `sysupgrade` with the `/etc/sysupgrade.conf` lines above.

> **Installing the key trusts this feed for every package name.** A key in `/etc/apk/keys` validates an index claiming any package name at all, so this feed could offer a higher version of a base package and win. Install it because you trust whoever publishes it, not because a page told you to.


## What is in it

| package | what it is | upstream |
|---|---|---|
| `luci-theme-footstrap` | LuCI theme | [VizzleTF/luci-theme-footstrap](https://github.com/VizzleTF/luci-theme-footstrap) |
| `luci-app-footstrap-updater` | in-LuCI updater for the theme | [VizzleTF/luci-app-footstrap-updater](https://github.com/VizzleTF/luci-app-footstrap-updater) |
| `podkop-updater` | watches podkop releases, drives update and rollback from Telegram | [VizzleTF/podkop_autoupdater](https://github.com/VizzleTF/podkop_autoupdater) |

What the feed actually carries, per architecture, is in its index:
[`index.json`](https://vizzletf.github.io/owfeed-packages/releases/25.12/x86_64/index.json).

## What this feed's signature means

Everything here — the index and every package — is signed with this feed's key. It has to be: apk
takes its trust from the signed index, and only this feed can sign an index describing everything
this feed carries. Signing packages with their authors' keys instead would mean installing every
author's key on your router, and each one would be a trust anchor for *every* package name, not just
theirs.

So the question is what this feed checked before it signed. For the two footstrap packages, the
author's detached signature is verified against a key pinned in [`keys/`](keys/) before the package
is ingested — the feed's signature means *the author signed this*. `podkop-updater` upstream
publishes checksums and no signature, so there the feed attests only that the bytes match a pin a
person recorded, and its updates wait for a person.

## Before you install the key

Putting a key in `/etc/apk/keys` trusts it for **every package name**, not only the ones above. A
feed whose key is compromised can offer a higher version of `dropbear` or `base-files` and win the
resolution, and apk has no revocation — no CRL, no expiry, no way to say a key is dead.

Install it because you trust who publishes it, not because a page told you to.

## Staying current

An hourly job asks each upstream for its latest release. When one appears it opens a pull request
containing a version and its checksums, recomputed from the bytes the release actually served — and
nothing else. CI then builds the feed, indexes it, checks it and installs it on a real OpenWrt image
before it can be merged.

It proposes; it does not publish. A job that fetched whatever an upstream pushed in the last hour
and signed it with this feed's key would be handing that key's authority to every upstream, and
would make the checksum pins decoration: recomputed from whatever arrived, they would attest to
nothing.

Where an upstream publishes a detached signature beside its artifact, that is provenance from
someone other than this feed, and the package may set `AUTO_MERGE="yes"` so the pull request merges
itself once the checks pass. The checks still have to pass.

## Adding a package

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: open a pull request with a fetch script and an
entry in `owfeed.yml`. CI builds, signs and checks it with a throwaway key, so a fork's pull request
never comes near the feed's own.
