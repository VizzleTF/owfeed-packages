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

A key per upstream repository rather than one per person, which is why the same author appears
twice. A signature says who wrote something and never what it is about, so one key across several
repositories is how a manifest lifted from one of them verifies perfectly as another. `owfeed`
checks the `repo` line in the manifest as well, which closes that on its own — the separate keys
mean the question does not arise, and a compromise of one reaches nothing else.
