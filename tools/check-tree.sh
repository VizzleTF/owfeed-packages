#!/bin/sh
# Assert the built tree carries everything the fetch put in it.
#
# `owfeed doctor` reads the tree and asks whether what is there is correct, and it
# knows about packages owfeed.yml builds. Neither can see a package that is absent
# because its fetch produced nothing — and the packages this feed carries are fetched,
# not built, so owfeed.yml does not list them at all.
#
# The failure this exists for is quiet. A tree carrying one of three packages on a
# release line passes every other check and publishes an incomplete feed, and the
# first report comes from a user whose `apk update` stopped offering an upgrade.
#
# tools/fetch.sh records each file it stages in dist/staged.txt, so this compares the
# built tree against what was actually fetched rather than re-deriving each package's
# shape. Re-deriving is how the check and the thing it checks drift apart.
#
# Usage: tools/check-tree.sh [out]
set -eu

OUT="${1:-out}"
DIST="${DIST:-dist}"
STAGED="$DIST/staged.txt"
rc=0

[ -f "$STAGED" ] || { echo "$STAGED is missing; run tools/fetch.sh first" >&2; exit 1; }

# apk is 25.12 and later, ipk is 24.10 and earlier. The same split owfeed.yml makes,
# and the only thing here that has to agree with it.
line_of() {
	case "$1" in
	*.apk) echo "25.12" ;;
	*.ipk) echo "24.10" ;;
	*) echo "" ;;
	esac
}

# The architectures a release line publishes, read from the tree: a line whose
# directories are all absent is itself the finding.
arches_of() {
	[ -d "$OUT/releases/$1" ] || return 0
	find "$OUT/releases/$1" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

while read -r name arch file; do
	[ -n "${name:-}" ] || continue
	line="$(line_of "$file")"
	[ -n "$line" ] || { echo "MISSING $name: $file is neither an apk nor an ipk" >&2; rc=1; continue; }

	# noarch and all are fanned out to every architecture on their line; anything
	# else belongs in exactly the one it names.
	case "$arch" in
	noarch|all) want="$(arches_of "$line")" ;;
	*) want="$arch" ;;
	esac

	missing=""; total=0
	for a in $want; do
		total=$((total + 1))
		[ -f "$OUT/releases/$line/$a/$file" ] || missing="$missing $a"
	done

	if [ "$total" -eq 0 ]; then
		echo "MISSING $name $file on $line: the release line has no directories at all" >&2
		rc=1
		continue
	fi
	[ -n "$missing" ] || continue

	# One line per package per release line, not one per architecture: a package
	# that failed to fetch is absent from all of them, and thirty-six identical
	# lines bury whatever else went wrong.
	# shellcheck disable=SC2086
	set -- $missing
	echo "MISSING $name $file on $line: absent from $# of $total architecture(s) (e.g. $1)" >&2
	rc=1
done < "$STAGED"

[ "$rc" -eq 0 ] && echo "every fetched package reached the tree"
exit "$rc"
