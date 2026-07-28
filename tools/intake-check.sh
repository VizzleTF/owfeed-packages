#!/bin/sh
# Check a package request before a person spends time on it.
#
# What it can decide: whether the release exists, whether the manifest is signed by
# the key the requester claims is theirs, whether that manifest is a shape this feed
# can read, and which tier the request therefore lands in.
#
# What it cannot decide, and must not appear to: whether the key belongs to who they
# say, or whether this feed should carry the package at all. The key here comes out
# of an issue anybody can open. Using it to verify the manifest proves the release is
# internally coherent — the same key signed the thing it names — and nothing about
# who holds it. Trust happens exactly once, later, when a person commits that key to
# keys/ and their name is on the merge.
#
# Usage: tools/intake-check.sh <issue-body-file> > verdict.md
set -eu

BODY="${1:?usage: tools/intake-check.sh <issue-body-file>}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# GitHub renders an issue form as "### Label" followed by the value. Read the value
# under a heading, stopping at the next one.
field() {
	awk -v want="### $1" '
		$0 == want { collecting = 1; next }
		/^### / { collecting = 0 }
		collecting { print }
	' "$BODY" | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

REPO="$(field 'Repository')"
TAG="$(field 'Release tag to check')"
KIND_RAW="$(field 'What the release publishes')"
MF_URL="$(field 'Manifest URL')"
KEY_ID="$(field 'Key id')"
PUBKEY="$(field 'usign public key')"
LICENCE="$(field 'Licence')"

KIND="${KIND_RAW%% *}"

fail=0
# The format string never starts with a dash: dash's printf reads that as an option
# and exits, which turns every finding into a broken run.
say()  { printf '%s\n' "$*"; }
bad()  { printf '%s\n' "- **${*}**"; fail=1; }
good() { printf '%s\n' "- $*"; }

say "## Automated intake check"
say ""
say "This is a machine reading your release. It decides nothing about whether the feed"
say "will carry the package — that is a person, later, and the key below is not trusted"
say "by anything yet."
say ""
say "\`$REPO\` @ \`$TAG\` — declared shape: \`$KIND\`"
say ""

# The release has to exist before anything else is worth checking.
if ! gh release view "$TAG" --repo "$REPO" --json tagName >/dev/null 2>&1; then
	bad "No release \`$TAG\` in \`$REPO\`, or the repository is private."
	say ""
	say "Nothing else could be checked."
	exit 0
fi
good "Release \`$TAG\` exists."

[ -n "$LICENCE" ] && good "Licence declared: \`$LICENCE\` (a person still reads LEGAL.md against it)."

case "$KIND" in
manifest)
	if [ -z "$MF_URL" ]; then
		bad "The manifest shape needs a manifest URL, and none was given."
	else
		printf '%s\n' "$PUBKEY" > "$WORK/claimed.pub"
		if ! curl -fsSL --max-time 60 "$MF_URL" -o "$WORK/manifest.txt" ||
		   ! curl -fsSL --max-time 60 "$MF_URL.sig" -o "$WORK/manifest.txt.sig"; then
			bad "Could not fetch the manifest and its \`.sig\` from that URL."
		else
			# VERIFY BEFORE READING, exactly as ingest does: every value inside
			# steers a download, so parsing first means acting on unvouched text.
			if owfeed verify-artifact --key "$WORK/claimed.pub" --key-id "$KEY_ID" \
				--signature "$WORK/manifest.txt.sig" "$WORK/manifest.txt" >/dev/null 2>&1; then
				good "The manifest verifies against the key in this request, under id \`$KEY_ID\`."
			else
				bad "The manifest does not verify against that key and id."
			fi

			head="$(head -n1 "$WORK/manifest.txt")"
			if [ "$head" = "owfeed-manifest 1" ]; then
				good "Manifest format: \`owfeed-manifest 1\`."
			else
				bad "Manifest says \`$head\`. This feed reads \`owfeed-manifest 1\`, which \`owfeed release\` writes."
			fi

			short="$(awk '$1=="pkg" && NF!=7 {print NR; exit}' "$WORK/manifest.txt")"
			if [ -n "$short" ]; then
				bad "Line $short does not have seven fields. Expected: \`pkg <name> <format> <file> <size> <sha256> <arch>\` — the seventh is the architecture, and hand-written manifests usually lack it."
			else
				good "Every \`pkg\` line has seven fields."
			fi

			got_repo="$(awk '$1=="repo"{print $2; exit}' "$WORK/manifest.txt")"
			if [ "$got_repo" = "$REPO" ]; then
				good "The manifest names \`$got_repo\`, matching this request."
			else
				bad "The manifest names \`$got_repo\`, not \`$REPO\`. A signature says who wrote something, never what it is about."
			fi
		fi
	fi
	;;
apk)
	good "Finished artifacts. Updates land automatically while the set of containers holds."
	say "  Attach a detached \`.sig\` beside every \`.apk\` and \`.ipk\`; ingest checks each one."
	;;
binaries)
	good "Raw binaries. This shape is carried, but nothing about it is ever merged without a person."
	;;
*)
	bad "Unrecognised shape \`$KIND\`."
	;;
esac

say ""
if [ "$fail" -ne 0 ]; then
	say "### Not ready"
	say ""
	say "Fix the points in bold and edit the issue — this re-runs on every edit."
	exit 0
fi

case "$KIND" in
manifest) tier="A — updates land within the hour, unattended" ;;
apk)      tier="B — updates land automatically while the container set is unchanged" ;;
*)        tier="C — every update waits for a person" ;;
esac
say "### Ready for a person"
say ""
say "Conformance: **$tier**."
say ""
say "What happens next is a pull request adding \`packages/$(basename "$REPO")/upstream.sh\` and"
say "your public key under \`keys/\`. The key is the whole trust decision, so it is read by a"
say "human and merged by hand. Nothing here has trusted it."
