# owfeed community packages

An OpenWrt package feed for **both release lines** — apk for 25.12 and later, opkg for 24.10 and
earlier — built and published by [owfeed](https://github.com/owfeed/owfeed).

## Install

Which set you run depends on your release: 25.12 and later is apk, 24.10 and earlier is opkg.

### OpenWrt 25.12 and later

```sh
# HTTPS on a stock image needs these two first.
apk add ca-bundle libustream-mbedtls

wget https://repo.owfeed.org/owfeed-packages.pem -O /etc/apk/keys/owfeed-packages.pem
echo "https://repo.owfeed.org/releases/25.12/$(cat /etc/apk/arch)/packages.adb" > /etc/apk/repositories.d/owfeed-packages.list

# Neither of those two files survives a sysupgrade on its own.
printf '%s\n' /etc/apk/keys/owfeed-packages.pem /etc/apk/repositories.d/owfeed-packages.list >> /etc/sysupgrade.conf

apk update && apk add podkop-updater
```

### OpenWrt 24.10 and earlier

```sh
# The key file's NAME is its id — opkg looks it up by that.
wget https://repo.owfeed.org/9040356b214084da -O /etc/opkg/keys/9040356b214084da

echo "src/gz owfeed-packages https://repo.owfeed.org/releases/24.10/$(. /etc/openwrt_release; echo $DISTRIB_ARCH)" >> /etc/opkg/customfeeds.conf

opkg update && opkg install podkop-updater
```

> **Do not install the package file directly.** On 25.12 `apk add ./file.apk` writes a pin on the
> package's content hash into `/etc/apk/world`, and that file survives sysupgrade — the package
> would never upgrade from this feed again. Add the repository and install by name.

> **Attended Sysupgrade will not carry these packages across.** `owut` forwards no custom
> repositories, and the sysupgrade server's `repository_allow_list` is empty by default, which
> denies everything.

> **Installing the key trusts this feed for every package name.** It validates an index claiming any
> name at all, so this feed could offer a higher version of a base package and win. Install it
> because you trust who publishes it.

## What this feed's signature means

Everything here is signed with this feed's keys — two of them, because each package manager verifies
only its own scheme: apk checks EC prime256v1, opkg checks usign. It has to be this feed's key and
not the authors': trust flows from the signed index, and only this feed can sign an index describing
everything this feed carries. Signing packages with their authors' keys instead would mean installing every
author's key on your router, and each one would be a trust anchor for *every* package name, not just
theirs.

So the question is what this feed checked before it signed. Every package here is built by its
author and verified against a key pinned in [`keys/`](keys/) before it is ingested, so the feed's
signature means *the author signed this* rather than *this downloaded successfully*. Nothing in this
repository is rebuilt: a feed that rebuilds someone's package ships something they never tested.

`podkop-updater` goes one further and publishes a signed inventory of its whole release, so the
size and hash of every package come from a document its author signed rather than from a table
copied into this repository by hand.

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

## Whose packages these are

Every package here declares its licence and its upstream, and both travel into the index and into
`apk info` on the router — a user can always find out whose software they installed.

Where a package is copyleft, its **corresponding source is served from this feed**, at
[`/sources/`](https://repo.owfeed.org/sources/index.txt) — the same origin as the binary, which is
what GPLv2 §3 asks of anyone distributing one. A copyleft package with no source in the tree fails
the publish, so this is a gate rather than an intention.

Redistributing someone else's work needs more than a licence that allows it, and
[LEGAL.md](LEGAL.md) is where this feed writes down what it read and what it decided.
*([Русский](LEGAL_ru.md))*

## Adding a package

Start with the [cookbook](https://owfeed.org/cookbook/) if you have not published a package
before — it covers building and signing one, which is what has to happen before this feed can
carry it. *([Русский](https://owfeed.org/cookbook/ru/))*

A package here is a file of values — a version, its checksums, which key signs it. There is no
per-package script.

- [CONTRIBUTING.md](CONTRIBUTING.md) — adding a package, updating one, letting it update itself
  *([Русский](CONTRIBUTING_ru.md))*
- [RUNBOOK.md](RUNBOOK.md) — what runs when, and what to do when something is red
  *([Русский](RUNBOOK_ru.md))*

Pull requests run the whole pipeline with a throwaway key, so a fork never comes near the feed's own.

This feed is one end of a longer lifecycle: [owlab](https://github.com/owfeed/owlab) is where a
package is developed and proven to work, [owfeed](https://github.com/owfeed/owfeed) is where it is
signed and indexed, and this repository decides whose keys it trusts and hands the result to routers.
[ECOSYSTEM.md](https://github.com/owfeed/owfeed/blob/main/docs/ECOSYSTEM.md) is where the boundary
between the three is written down — including why nothing is ever built here.
[STATUS.md](STATUS.md) says how much of this feed's side of it exists, and what is still open.
