# Redistributing other people's packages

*[Русская версия](LEGAL_ru.md)*

**This is not legal advice.** It is what was read in the licences and policies of the packages this
feed carries, written down so the decisions are reviewable rather than assumed.

## The short version

A licence that permits redistribution is not permission to do anything you like. Three separate
things have to hold, and only the first is usually checked:

1. **The copyright licence** must permit redistribution — and its conditions have to be met, which
   for GPL means source availability, not just attribution.
2. **The trademark** is a different right. Open-source licences do not grant it; Apache-2.0 says so
   explicitly, and GPL's silence does not make trademark law go away.
3. **The author's willingness** is neither of those, and is the one that decides whether
   redistributing is a courtesy or a nuisance. A feed that republishes someone's work sends their
   bug reports to them, from an install path they never tested.

## What this feed carries, and under what

| package | licence | redistribution | trademark policy |
|---|---|---|---|
| `luci-theme-footstrap` | Apache-2.0 | permitted, with NOTICE and change statements | none published |
| `luci-app-footstrap-updater` | Apache-2.0 | same | none published |
| `podkop-updater` | MIT | permitted | none published |

### `podkop-updater` declared a licence it did not have

`VizzleTF/podkop_autoupdater` published no `LICENSE` file while this feed declared
`license: MIT` for it. Without one, default copyright applies: nobody has redistribution
rights at all, whatever the repository's visibility suggests — and the claim was already in
the index and read back by `apk info` on every router that installed it.

Fixed upstream rather than in the feed's metadata, because there was no reality for the
metadata to match: `podkop_autoupdater` now carries the MIT licence it was being described
under. Adding the file makes the published claim true; editing the feed would only have made
it quieter.

The general form is worth keeping: a `license:` field is an assertion about someone else's
intentions, and it is trivially possible to publish one nobody made.

## `podkop`, and why it is not enabled

[`itdoginfo/podkop`](https://github.com/itdoginfo/podkop) is GPL-2.0-or-later and publishes a
[trademark policy](https://github.com/itdoginfo/podkop/blob/main/TRADEMARK.md). Both matter, in
different ways.

### The trademark policy permits this, and constrains it

Read plainly, the policy allows what a feed does:

> You can, however, say that you like the Podkop project, that you participate in the Podkop
> community, or that you are providing an unmodified version of the Podkop software.

> When you redistribute an unmodified copy of Podkop software, you must not remove any Podkop
> trademarks, notices, or branding included in the original distribution.

So an unmodified copy, under its own name, with its notices intact, is within the policy. What is
not: presenting it as official or endorsed, and using the name for anything modified.

**Where that bites owfeed.** `owfeed sign` appends this feed's signature to the package file. The
payload is untouched, but the artifact's bytes are not the ones upstream published. Whether that is
still "an unmodified copy" is a judgement, and it is the feed's to defend rather than assume. The
honest position: the *contents* are unmodified and the pin proves it, but the *file* is not
byte-identical to upstream's, and a user comparing checksums will notice.

Rebuilding a package from source would be a further step again. That artifact is this feed's build,
not upstream's, and publishing it under the upstream name is much closer to what the policy
forbids.

### GPL-2.0 asks for something Apache-2.0 does not

GPLv2 §3 conditions binary distribution on source: accompanying it, or a written offer valid for
three years, or — for non-commercial distribution only — passing along the offer you received.

A feed that publishes a GPL binary and links to a GitHub repository has not obviously satisfied any
of the three. Upstream's own distribution is fine; ours is a separate act of distribution with its
own obligations.

This is the part that is genuinely unresolved, and it is why podkop is not in this feed. The
contribution flow was exercised against it on a branch — which is how the `v`-tag assumption in
`tools/fetch.sh` was found and fixed — and the branch was not merged. Nothing is published until
the source obligation has an answer and the author has been asked.

## What we do about it

**Ask.** Every consideration above is cheaper to resolve with a message than with a reading of
GPLv2 §3. An author who says yes has also told you where to send bug reports; one who says no has
saved everyone a dispute. Nothing here is urgent enough to skip that.

**Record what we know.** Every package declares its `license:` and its `url:`, both of which travel
into the index and into `apk info` on the router. `owfeed publish` refuses a package that does not
name its upstream. A user who installs something from this feed can always find out whose it is.

**Do not claim what was not granted.** A licence field is an assertion about someone else's
intentions. Where the upstream has published none, the honest thing is to say so and not publish,
rather than to guess a permissive one.
