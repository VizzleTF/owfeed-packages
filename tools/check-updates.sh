#!/bin/sh
# Notice new upstream releases and propose them as pull requests.
#
# It proposes; it does not publish. This feed's key is a trust anchor for every
# package name on every subscriber's router, so a job that fetched whatever an
# upstream pushed in the last hour and signed it would be handing that authority to
# five other repositories. The sha256 pins would become decoration too: recomputed
# from whatever arrived, they would attest to nothing.
#
# What a pull request carries instead is evidence — a diff containing only a
# version and its checksums, and a CI run that builds, indexes, checks and installs
# the result on a real OpenWrt image before anyone merges it.
set -eu

BRANCH_PREFIX="update"

# What, besides this feed, vouches for the bytes. A detached signature published
# beside the artifact is provenance; a checksum served by the same host from the
# same release is not, because whoever can replace one can replace the other.
signature_note() {
	if [ -f "$1/$2.sig" ]; then
		echo "Upstream publishes a detached signature beside this artifact (\`$2.sig\`)."
	else
		echo "Upstream publishes no signature for this artifact, so the pin below is all there is."
	fi
}
for up in packages/*/upstream.sh; do
	dir="$(dirname "$up")"
	name="$(basename "$dir")"

	# Subshell: each package's variables stay its own.
	(
		. "./$up"
		current="${VERSION%-r*}"
		latest="$(gh release view --repo "$REPO" --json tagName -q .tagName | sed 's/^v//')"

		[ -n "$latest" ] || { echo "$name: upstream has no releases" >&2; exit 0; }
		if [ "$current" = "$latest" ]; then
			echo "$name: $current is current"
			exit 0
		fi
		echo "$name: $current -> $latest"

		branch="${BRANCH_PREFIX}/${name}-${latest}"
		if gh pr list --head "$branch" --state open --json number -q '.[0].number' | grep -q .; then
			echo "$name: a pull request for $latest is already open"
			exit 0
		fi

		tmp="$(mktemp -d)"
		trap 'rm -rf "$tmp"' EXIT
		gh release download "v$latest" --repo "$REPO" --dir "$tmp" --pattern '*' >/dev/null

		# Rewrite the pins from the bytes that actually arrived. Nothing else in the
		# file is touched, so the diff is a version and its checksums.
		new="$tmp/upstream.sh"
		cp "$up" "$new"
		sed -i "s|^VERSION=.*|VERSION=\"${latest}-r1\"|" "$new"

		if [ -n "${ARTIFACT:-}" ]; then
			file="$(echo "$ARTIFACT" | sed "s/${current}/${latest}/g")"
			[ -f "$tmp/$file" ] || { echo "$name: release v$latest has no $file" >&2; exit 1; }
			sum="$(sha256sum "$tmp/$file" | cut -d' ' -f1)"
			sed -i "s|^ARTIFACT=.*|ARTIFACT=\"${file}\"|" "$new"
			sed -i "s|^SHA256=.*|SHA256=\"${sum}\"|" "$new"
			evidence="$(signature_note "$tmp" "$file")"
		else
			block=""
			echo "$ARTIFACTS" | while read -r a _; do
				[ -n "$a" ] || continue
				[ -f "$tmp/$a" ] || { echo "$name: release v$latest has no $a" >&2; exit 1; }
				printf '%s  %s\n' "$a" "$(sha256sum "$tmp/$a" | cut -d' ' -f1)"
			done > "$tmp/pins"
			block="$(cat "$tmp/pins")"
			awk -v block="$block" '
				/^ARTIFACTS="/ { print; print block; skip = 1; next }
				skip && /^"/    { print; skip = 0; next }
				!skip           { print }
			' "$up" > "$new.tmp" && mv "$new.tmp" "$new"
			sed -i "s|^VERSION=.*|VERSION=\"${latest}-r1\"|" "$new"
			evidence="upstream publishes checksums only, so this needs a human"
		fi

		git checkout -q -b "$branch" origin/main
		cp "$new" "$up"
		git add "$up"
		git commit -q -m "$name: $current -> $latest

$evidence

Pins were recomputed from the bytes the release actually served."
		git push -q -u origin "$branch"

		url="$(gh pr create --title "$name: $current -> $latest" --body "Upstream released \`v$latest\`.

$evidence

The diff is a version and its checksums, recomputed from the bytes the release
served. CI builds the feed, indexes it, runs \`owfeed doctor\`, and installs the
result on a real OpenWrt image before this can be merged.")"
		echo "$name: $url"

		# Auto-merge is offered only where someone other than this feed vouches for
		# the bytes. CI still has to be green: this asks GitHub to merge when the
		# checks pass, it does not bypass them.
		if [ "${AUTO_MERGE:-no}" = "yes" ]; then
			gh pr merge --squash --auto --delete-branch "$url" >/dev/null
			echo "$name: will merge itself once the checks pass"
		fi
		git checkout -q main
	)
done
