#!/bin/sh
# Notice new upstream releases and propose them as pull requests.
#
# It proposes; it does not publish. This feed's key is a trust anchor for every
# package name on every subscriber's router, so a job that fetched whatever an
# upstream pushed in the last hour and signed it would hand that authority to every
# upstream at once. The checksum pins would stop meaning anything too: recomputed
# from whatever arrived, they would attest to nothing.
#
# What a pull request carries instead is evidence — a diff containing a version and
# its checksums and nothing else, and a run that builds, indexes, checks and
# installs the result on a real OpenWrt image before anyone merges it.
set -eu

for up in packages/*/upstream.sh; do
	dir="$(dirname "$up")"
	name="$(basename "$dir")"

	# A subshell per package: one package's variables never leak into the next.
	(
		. "./$up"
		current="${VERSION%-r*}"
		latest="$(gh release view --repo "$REPO" --json tagName -q .tagName 2>/dev/null | sed 's/^v//')"

		[ -n "$latest" ] || { echo "$name: upstream has no releases"; exit 0; }
		[ "$current" != "$latest" ] || { echo "$name: $current is current"; exit 0; }

		branch="update/${name}-${latest}"
		if gh pr list --head "$branch" --state open --json number -q '.[0].number' | grep -q .; then
			echo "$name: a pull request for $latest is already open"
			exit 0
		fi
		echo "$name: $current -> $latest"

		tmp="$(mktemp -d)"
		trap 'rm -rf "$tmp"' EXIT
		gh release download "v$latest" --repo "$REPO" --dir "$tmp" --pattern '*' >/dev/null

		# Recompute the pins from the bytes the release actually served, rewriting
		# values in place. Nothing but data changes, so the diff is readable.
		sed -i "s|^VERSION=.*|VERSION=\"${latest}-r1\"|" "$up"

		case "$KIND" in
		apk)
			file="$(echo "$ARTIFACT" | sed "s/${current}/${latest}/g")"
			[ -f "$tmp/$file" ] || { echo "$name: v$latest publishes no $file" >&2; exit 1; }
			sed -i "s|^ARTIFACT=.*|ARTIFACT=\"${file}\"|" "$up"
			sed -i "s|^SHA256=.*|SHA256=\"$(sha256sum "$tmp/$file" | cut -d' ' -f1)\"|" "$up"
			;;
		binaries)
			# Rewrite only the checksum column, so the architecture mapping — which is
			# a human decision about what upstream's builds actually run on — survives
			# untouched.
			echo "$ARTIFACTS" | while read -r artifact _ arches; do
				[ -n "$artifact" ] || continue
				[ -f "$tmp/$artifact" ] || { echo "$name: v$latest publishes no $artifact" >&2; exit 1; }
				printf '%s  %s  %s\n' "$artifact" "$(sha256sum "$tmp/$artifact" | cut -d' ' -f1)" "$arches"
			done > "$tmp/table"
			awk -v table="$(cat "$tmp/table")" '
				/^ARTIFACTS="/ { print; print table; inside = 1; next }
				inside && /^"/ { print; inside = 0; next }
				!inside        { print }
			' "$up" > "$tmp/new" && mv "$tmp/new" "$up"
			;;
		esac

		if [ -n "${SIG_KEY:-}" ]; then
			evidence="Upstream publishes a detached signature; it is verified against the pinned key before this is ingested."
		else
			evidence="Upstream publishes no signature, so the checksums below are all there is. This needs a person."
		fi

		git checkout -q -b "$branch"
		git commit -q "$up" -m "$name: $current -> $latest

$evidence

Pins recomputed from the bytes the release served."
		git push -q -u origin "$branch"

		url="$(gh pr create --title "$name: $current -> $latest" --body "Upstream released \`v$latest\`.

$evidence

The diff is a version and its checksums, recomputed from the bytes the release served. CI builds the
feed, indexes it, runs \`owfeed doctor\`, and installs the result on a real OpenWrt image before this
can be merged.")"
		echo "$name: $url"

		# Auto-merge is offered only where someone other than this feed vouches for the
		# bytes. This asks GitHub to merge once the checks pass; it does not skip them.
		if [ "${AUTO_MERGE:-no}" = "yes" ]; then
			gh pr merge --squash --auto --delete-branch "$url" >/dev/null
			echo "$name: will merge itself once the checks pass"
		fi
		git checkout -q -
		git checkout -q "$up"
	)
done
