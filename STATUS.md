# What is built in this feed, and what is not

*[ECOSYSTEM.md](https://github.com/VizzleTF/owfeed/blob/main/docs/ECOSYSTEM.md) in
owfeed says where the boundaries between owlab, owfeed and this feed run and why.
This file says how much of this feed's side of that exists, as of 2026-07-28.*

It lives here rather than in the shared document because a shared status file goes
stale on exactly the facts none of its own CI touches. Beside the thing it
describes, a claim that stops being true is a line in the pull request that made
it untrue.

## Working, and verified rather than assumed

| | Evidence |
|---|---|
| Feed updates reaching a router | Released updater 1.2.0 → hourly bot opened a PR → auto-merge → publish → both branches offer `1.2.0-r1` |
| Self-updater migrating off a content pin | 0.11.5 pinned by hash → `check` answers `v0.11.6` from the local index → upgrade lands and leaves the package unpinned |
| Auto-merge tier rules | Six scenarios exercised in a real git repository: manifest/minor merges, major bump holds, `binaries` holds, no `SIG_KEY` holds, a diff touching `SIG_KEY_ID` holds, the daily ceiling holds |
| Verify before read | `tools/fetch.sh` checks the signature before parsing, and cross-checks `repo` and `tag` inside the manifest — the signature says *who*, never *what about* |
| Ingest without a key | The build job runs contributed fetch scripts and never sees the signing key; the key appears only after the bytes are already in an artifact |

## Built but not yet exercised in anger

- **The intake funnel** (`.github/ISSUE_TEMPLATE/package-request.yml` plus
  `.github/workflows/intake.yml`) answers correctly when run by hand against a
  real release. No third party has used it, so the first genuine request is still
  the first genuine test.

## Not built, and why

**`publish.yml` and `pr.yml` on owfeed's reusable `feed.yml`.** Both are
hand-written copies of a workflow owfeed ships, and the usage comment in that
workflow describes this pipeline. The duplication has a live cost — two pipelines
mean a green pull request does not prove the published one still works — and it is
deliberate for now. `feed.yml` used to take the signing keys as `workflow_call`
secrets, which would have forced them out of the `feed` environment and into
repository scope, where the hourly update job and every pull-request check could
reach them. owfeed's publish job now reads the environment secret by name instead,
so the migration is unblocked in principle; what it waits on is an owfeed release
carrying that, and one live run confirming which repository's environment
resolves. Moving a signing key on the strength of a documentation reading is not
a thing to do to a feed that is already serving routers.

**A consumer job in `pr.yml`.** `owfeed smoke` proves the channel installs without
`--allow-untrusted`; nothing yet proves the package that came through it works.
`owlab test --feed` is the tool, and its obstacle — how a router in a container
addresses an HTTP server on the runner — is fixed in owlab by the `{host}` token.
This lands once that is in an owlab release.

**CODEOWNERS as a mechanism.** `keys/` is named, and no branch rule enforces the
review. With a single maintainer a required review blocks every key addition
permanently instead of gating it, because the author of a pull request cannot
approve their own. Auto-merge cannot reach `keys/` regardless — it is only ever
requested on pull requests the update job itself opened, and that job writes one
`upstream.sh`. The review becomes a mechanism on the day there is a second
maintainer, and until then it is a convention.

**An author signature on any package here.** Every package is signed by the feed;
none carries its author's own in-package EC signature, so the additive-signature
property `CONTRIBUTING.md` describes is true of the design and demonstrated by
nothing. `owfeed sign` no longer needs a feed config, so the tooling is not the
obstacle — it needs an author to generate a key and add a repository secret.

## Known contradictions

One key, `keys/vizzletf-release.pub`, covers two upstream repositories while
`keys/README.md` asks for one key per repository. `owfeed verify-artifact` checks
the manifest's `repo` line, so a manifest cannot be lifted from one to the other
and the shared key is tolerable — what separate keys would buy is blast radius,
not correctness. The doctrine says so out loud rather than being quietly
contradicted by the table beneath it.

## Where to look

- [CONTRIBUTING.md](CONTRIBUTING.md) — how a package gets in, and the tiers *([по-русски](CONTRIBUTING_ru.md))*
- [RUNBOOK.md](RUNBOOK.md) — operating it *([по-русски](RUNBOOK_ru.md))*
- [LEGAL.md](LEGAL.md) — what this feed will and will not carry *([по-русски](LEGAL_ru.md))*
