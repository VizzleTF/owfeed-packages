# Pinned upstream keys

The public keys of the people whose packages this feed carries, in usign form. A release is
verified against the key pinned here before it is ingested, so this feed's signature means *the
author signed this*, not *this downloaded successfully*.

Pinned rather than fetched: whoever can replace an artifact can replace the signature beside it and
the key it names. A key is only a check once it comes from somewhere the attacker does not control,
and here that is this repository's history.

Adding or changing a key is the one diff in this repository that deserves a second look. Verify the
key out of band — against the author's repository, a fingerprint they published elsewhere, anything
that is not the release you are about to trust it for.

| key | id | covers |
|---|---|---|
| `vizzletf-release.pub` | `18c63865e2bcf8d6` | `luci-theme-footstrap`, `luci-app-footstrap-updater` |
| `podkop-updater.pub` | `37ddece4c0eef357` | `podkop-updater` |

A key per upstream repository rather than one per person is what this feed wants, and the table
above does not yet meet it: `vizzletf-release.pub` covers two repositories, because one release
pipeline signs both.

The reason to want it: a signature says who wrote something and never what it is about, so one key
across several repositories is how a manifest lifted from one of them verifies perfectly as
another. `owfeed` checks the `repo` line in the manifest as well, and that closes the hole on its
own — which is why the shared key is tolerable rather than urgent. What separate keys would add is
blast radius: a compromise of one would reach nothing else.

Adding or changing a key is the diff `.github/CODEOWNERS` names. Auto-merge cannot reach it by
construction rather than by a check: it is only ever requested on a pull request the hourly job
itself opened, and that job writes one file — `packages/<name>/upstream.sh` — refusing even that
when the diff moves anything but the version and its checksums. A key arrives in a pull request a
person opened, and those are never auto-merged.

The code-owner review is not enforced by a branch rule. That needs a reviewer who is not the
author, and with a single maintainer it would block every key addition permanently rather than
gate it. Turn it on when there is a second maintainer.
