#!/bin/sh
# Assert the built tree carries every package this repository ingests.
#
# `owfeed doctor` reads the tree and asks whether what is there is correct, and it
# knows about the packages owfeed.yml builds. Neither can see a package that is
# absent because its fetch produced nothing: the ingest list lives in
# packages/*/upstream.sh, and that is what this compares against.
#
# The failure it exists for is quiet. A tree carrying one of three packages on a
# release line passes every other check and publishes an incomplete feed, and the
# first report comes from a user whose `apk update` stopped offering an upgrade.
#
# Usage: tools/check-tree.sh [out]
set -eu

OUT="${1:-out}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rc=0

# present <line> <arch> <pattern>
present() {
	dir="$OUT/releases/$1/$2"
	[ -d "$dir" ] || return 1
	set -- "$dir"/$3
	[ -e "$1" ]
}

# want <line> <arch-list> <pattern> <label>
#
# One line per package per release line, not one per architecture: a package that
# failed to fetch is missing from all of them, and 36 identical lines bury whatever
# else went wrong.
want() {
	line="$1"; arches="$2"; pattern="$3"; label="$4"
	missing=""; total=0
	for arch in $arches; do
		total=$((total + 1))
		present "$line" "$arch" "$pattern" || missing="$missing $arch"
	done
	[ -n "$missing" ] || return 0
	# shellcheck disable=SC2086
	set -- $missing
	echo "MISSING $label on $line: absent from $# of $total architectures (e.g. $1)" >&2
	rc=1
}

# The architectures a release line publishes, taken from the tree rather than the
# lock: a line whose directories are all absent is itself the finding.
arches_of() {
	[ -d "$OUT/releases/$1" ] || return 0
	find "$OUT/releases/$1" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

for dir in "$ROOT"/packages/*/; do
	name="$(basename "$dir")"
	# Each package is read in a subshell so one entry's variables cannot leak into
	# the next -- upstream.sh files set overlapping names, and a stale ARTIFACT_IPK
	# would turn a missing package into a passing check.
	(
		. "$dir/upstream.sh"
		[ "${ENABLED:-yes}" = "yes" ] || exit 0

		case "$KIND" in
		apk)
			want "25.12" "$(arches_of 25.12)" "$ARTIFACT" "$name $VERSION"
			[ -n "${ARTIFACT_IPK:-}" ] &&
				want "24.10" "$(arches_of 24.10)" "$ARTIFACT_IPK" "$name $VERSION"
			;;
		binaries)
			# One artifact serves several architectures; the tree must carry the
			# package in each of them, under either container.
			arches="$(echo "$ARTIFACTS" | while read -r _ _ a; do echo "$a"; done)"
			want "25.12" "$arches" "$name-$VERSION.apk" "$name $VERSION"
			want "24.10" "$arches" "${name}_${VERSION}_*.ipk" "$name $VERSION"
			;;
		esac
		exit $rc
	) || rc=1
done

[ "$rc" -eq 0 ] && echo "every enabled package is present on every line it declares"
exit "$rc"
