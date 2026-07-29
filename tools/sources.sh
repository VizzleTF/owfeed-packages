#!/bin/sh
# Publish corresponding source beside the binaries, and refuse to publish a copyleft
# package without it.
#
# This is the check that decides whether this feed may carry a GPL package at all.
#
# GPLv2 §3 gives three ways to distribute a binary: accompany it with source, make a
# written offer good for three years, or -- non-commercially, and only if you were
# given such an offer -- pass that offer along. A feed that publishes a binary and
# links to a repository has done none of them. Upstream distributing its own work is
# upstream's business; re-serving those bytes is a second, separate act of
# distribution that carries the obligation again.
#
# The first option is the only one that needs nobody to remember anything: the source
# sits at the same origin as the binary, served by the same host, for exactly as long
# as the binary is. So that is the one this feed takes, and this script is what makes
# it true rather than intended -- `owfeed publish` is never reached if a copyleft
# package has no source in the tree.
#
# Why the licence is read from the index rather than from upstream.sh: the index is
# built from the metadata inside the package, which its author set. A field in this
# repository would be this feed's opinion about someone else's licence, and would go
# stale the first time upstream relicensed. `apk info` on the router shows the same
# string this reads.
#
# Usage: tools/sources.sh [out]
set -eu

OUT="${1:-out}"
DIST="${DIST:-dist}"
SRC="$OUT/sources"
TAB="$(printf '\t')"

command -v jq >/dev/null 2>&1 || { echo "tools/sources.sh needs jq" >&2; exit 1; }

# Licences whose terms condition distributing a binary on providing source.
#
# Matched as substrings of the declared expression, which is why these are spellings
# rather than SPDX identifiers: "GPL-2.0-or-later", "GPL-2.0-only" and a bare
# "GPL-2.0" all have to hit, while "Apache-2.0 OFL-1.1" must not. LGPL and AGPL are
# covered by the GPL substring and named here so the intent is not an accident of
# spelling.
#
# MPL, EPL and CDDL are included for the same reason as GPL even though their
# copyleft is per-file: each conditions distributing a binary on making source
# available. Whether the copyleft is file-level or project-level changes what
# upstream must publish, not what this feed must serve.
is_copyleft() {
	case "$1" in
	*GPL*|*gpl*|*MPL*|*mpl*|*EPL*|*epl*|*CDDL*|*cddl*) return 0 ;;
	*) return 1 ;;
	esac
}

mkdir -p "$SRC"

# Stage whatever the fetches produced, before the check rather than after: a source
# archive that was fetched and not copied should fail as a missing file, not pass
# because the check looked in the directory it came from.
if [ -d "$DIST/sources" ]; then
	find "$DIST/sources" -maxdepth 1 -type f ! -name staged.txt -exec cp -a {} "$SRC/" \;
fi

# Everything the tree publishes, from the JSON index owfeed writes beside each binary
# one. A noarch package appears in every architecture's index and is wanted once.
packages="$(find "$OUT" -name index.json -exec \
	jq -r '.packages[]? | [.name, .version, (.license // "")] | @tsv' {} + 2>/dev/null \
	| sort -u)"

[ -n "$packages" ] || { echo "tools/sources.sh: no package found in any index.json under $OUT" >&2; exit 1; }

missing="$(mktemp)"
listed="$(mktemp)"
trap 'rm -f "$missing" "$listed"' EXIT

printf '%s\n' "$packages" | while IFS="$TAB" read -r name version licence; do
	[ -n "${name:-}" ] || continue
	src="$(find "$SRC" -maxdepth 1 -type f -name "${name}-${version}.*" ! -name '*.txt' | head -1)"

	if [ -n "$src" ]; then
		# The sha256 of what was actually served, and the URL it came from. The
		# archive itself is fetched unpinned -- see tools/fetch.sh for why -- so
		# recording what was handed out is what keeps it identifiable afterwards.
		sum="$(sha256sum "$src" | cut -d' ' -f1)"
		origin="$(awk -v n="$name" -v v="$version" '$1==n && $2==v {print $5; exit}' \
			"$DIST/sources/staged.txt" 2>/dev/null || true)"
		printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
			"$name" "$version" "${licence:-unstated}" "$(basename "$src")" \
			"$sum" "${origin:-unrecorded}" >> "$listed"
		continue
	fi

	is_copyleft "${licence:-}" || continue
	{
		echo "NO SOURCE $name $version: declares \`$licence\`, and this feed serves no source for it"
		echo "  the tag's own archive could not be fetched, so set SOURCE_URL in"
		echo "  packages/$name/upstream.sh to where the source actually lives -- see LEGAL.md"
	} >&2
	echo "$name $version" >> "$missing"
done

{
	echo "# Corresponding source for the packages this feed publishes, served from the"
	echo "# same origin as the binaries so that GPLv2 §3(a) is satisfied by the feed"
	echo "# itself rather than by a link to somewhere else. See LEGAL.md."
	echo "#"
	echo "# package${TAB}version${TAB}licence${TAB}file${TAB}sha256${TAB}origin"
	sort "$listed"
} > "$SRC/index.txt"

if [ -s "$missing" ]; then
	echo "refusing to publish: $(grep -c '' "$missing") copyleft package(s) without corresponding source" >&2
	exit 1
fi

echo "corresponding source served for $(grep -c '' "$listed") package(s); no copyleft package is missing one"
