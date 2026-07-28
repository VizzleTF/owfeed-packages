# Runbook

*[Русская версия](RUNBOOK_ru.md)*

Operating the feed. For adding or updating a package, see [CONTRIBUTING.md](CONTRIBUTING.md).

## What runs when

| when | what | key present? |
|---|---|---|
| pull request | fetch → build → sign → index → doctor → smoke | a throwaway one |
| push to `main` | job 1: fetch → build | **no** |
| | job 2: sign → index → smoke → verify → publish → Pages | **yes**, behind `environment: feed` |
| hourly | ask each upstream for its latest release; open a pull request if there is one | no |

The split on `main` is the point: the fetch scripts execute values contributed by pull requests, and
that job has no key. The key appears only after the built bytes are already in an artifact.

---

## A pull request is red

Read the finding. Each says what it costs and what to do. The ones with non-obvious causes:

**`OWF207` — configuration shipped but not declared.** The package installs `/etc/config/foo` and
`conffiles:` does not list it. sysupgrade reads `.conffiles_static` to decide what survives a
firmware upgrade, so the user's settings would be replaced by your defaults on every upgrade, with
nothing reported.

**`smoke` failed but `doctor` passed.** The tree is coherent and a router will not take it. Read the
container output: usually a dependency that does not resolve on a stock image, or a file installed
somewhere nothing looks.

**`sha256 … pinned …`** in the fetch step. The upstream replaced a release in place. Do not update
the pin to make it pass — find out why the bytes changed first.

---

## An update pull request appeared and I do not recognise the version

The bot opens one for any upstream release. Look at the diff: it must be a version and its
checksums, nothing else. If it touches anything more, something is wrong with the bot rather than
with the release.

To hold an update, close the pull request; the bot will not reopen the same one. To stop a package
updating itself, set `AUTO_MERGE="no"` in its `upstream.sh`.

---

## Publishing failed

The publish job is a separate job with the key. Common causes:

**`$OWFEED_SIGN_KEY is empty`.** The secret is missing, or the run started before it existed.
Re-run the job.

**`owfeed verify` reports `OWF513`.** A version already published has different contents than what
is about to replace it. Either a package changed without a version bump, or a build stopped being
reproducible — check that `SOURCE_DATE_EPOCH` is still set in the workflow. Do not publish over it:
bump the revision instead.

**Pages did not update.** Deployment is `actions/deploy-pages`; check that job, not the feed.

---

## Checking what subscribers actually see

```sh
owfeed verify                 # over the documented URL, no local tree needed
owfeed verify out             # also compares what is about to replace what is live
```

It fetches the published key and index and reports redirects apk will not follow, packages the live
index names that are missing or the wrong size, and versions being republished with different
contents.

From a router's point of view, in one command:

```sh
owfeed smoke                  # installs the built feed on a real OpenWrt image
```

---

## The signing key

It lives in the `OWFEED_SIGN_KEY` secret and nowhere else in this repository. `.gitignore` covers
`*.pem` so it cannot be committed by accident.

**There is no revocation.** apk has no CRL, no expiry, and no way to say a key is dead. If the key
leaks, every subscriber has to install a new one by hand — there is no path that reaches a router
which is offline when it matters.

To rotate: generate a new key, publish both public keys for an overlap window, sign the index with
both, then drop the old one. `apk` matches keys by identity rather than by filename, so several can
coexist on a device and the overlap costs nothing. owfeed does not yet have a command for this; the
steps are in its design document.

---

## Adding a key to `keys/`

That is the one diff in this repository that deserves a second look. A pinned key is what makes a
signature mean anything, so verify it out of band — against the author's repository, a fingerprint
they published somewhere else, anything that is not the release you are about to trust it for.

---

## Things that are not automatic, on purpose

**Publishing is not.** The hourly job proposes; it never signs. A job that fetched whatever an
upstream pushed in the last hour and signed it would hand this feed's key to every upstream at once.

**Merging is not, unless the author signed.** `AUTO_MERGE="yes"` is offered only where a detached
signature is verified against a pinned key.

**Architecture coverage is not.** `owfeed.lock` records which architectures the feed publishes for,
and `--frozen-lock` fails the build when upstream's list moves. Run `owfeed lock --update` and read
the diff — what the feed covers is part of its contract with subscribers.
