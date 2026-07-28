#!/bin/sh
# Fetch one package's upstream artifacts, verify them, and stage them.
#
# One implementation for every package. A package contributes data — a version, its
# checksums, which architectures each artifact serves — and never a script, so the
# hourly update job rewrites values rather than code, and adding a package does not
# start with copying somebody else's shell.
#
# Usage: tools/fetch.sh packages/<name>
set -eu

DIR="${1:?usage: tools/fetch.sh packages/<name>}"
NAME="$(basename "$DIR")"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${DIST:-dist}"
STAGING="${STAGING:-staging}"

. "$ROOT/$DIR/upstream.sh"

# A package can be present and not published — see LEGAL.md for why one is.
if [ "${ENABLED:-yes}" != "yes" ]; then
	echo ">> $NAME: not enabled, skipping"
	exit 0
fi

# Most projects tag releases v<version>; some do not. Overriding the whole tag
# rather than the prefix means a project that tags "release-1.2" or "2026.07" is a
# one-line entry rather than a change here.
TAG="${TAG:-v${VERSION%-r*}}"
base="https://github.com/${REPO}/releases/download/${TAG}"

# get <url> <dest>
#
# --retry, because a release of ninety-odd assets meets a 502 from the CDN sooner or
# later and a whole publish failing on one is noise, not a finding. Retrying is safe
# here for the reason it usually is not: every byte fetched is checked against a hash
# or a signature afterwards, so a retry cannot smuggle anything past.
get() {
	curl -fsSL --proto '=https' --tlsv1.2 \
		--retry 5 --retry-delay 2 --retry-connrefused --retry-all-errors \
		-o "$2" "$1"
}

# download <url> <dest> <sha256>
download() {
	get "$1" "$2"
	got="$(sha256sum "$2" | cut -d' ' -f1)"
	[ "$got" = "$3" ] || { echo "$1: sha256 $got, pinned $3" >&2; rm -f "$2"; exit 1; }
}

# check_signature <file>
#
# A pin proves the bytes have not changed since someone looked at them. The author's
# signature says who produced them, and only that can justify an update merging
# itself. The key is pinned in this repository: whoever can replace an artifact can
# replace the signature beside it and the key it names.
# staged <package> <arch> <file>
#
# What this fetch actually put in the tree, so tools/check-tree.sh can compare the
# built feed against it rather than re-deriving each package's shape. A fetch that
# half-succeeds is otherwise invisible: `owfeed doctor` reads what is there and
# cannot see what is missing.
#
# Not a dotfile, and that is not cosmetic. This was `.staged` for one commit, and it
# never crossed the boundary between the job that fetches and the job that signs:
# actions/upload-artifact excludes hidden files by default, the same way
# actions/upload-pages-artifact does. A name without a leading dot works whether or
# not someone remembered the flag.
staged() {
	mkdir -p "$DIST"
	printf '%s %s %s\n' "$1" "$2" "$3" >> "$DIST/staged.txt"
}

# check_signature <local file> [remote asset name]
#
# The remote name is given separately because a package can arrive under one name and
# be stored under another: release assets are flat, so an apk built for many
# architectures carries one in its filename that the published package does not.
check_signature() {
	[ -n "${SIG_KEY:-}" ] || return 0
	remote="${2:-$(basename "$1")}"
	get "$base/$remote.sig" "$1.sig"
	owfeed verify-artifact --key "$ROOT/$SIG_KEY" --key-id "$SIG_KEY_ID" \
		--signature "$1.sig" "$1"
	# Evidence for this step, not something to publish: apk has no idea what to do
	# with a detached usign signature.
	rm -f "$1.sig"
}

case "${KIND:?upstream.sh must set KIND}" in
apk)
	# Upstream publishes a finished package. Its own CI built it; rebuilding here
	# would ship something the maintainer never tested. It goes where owfeed puts a
	# build of that architecture and is signed and indexed unchanged.
	dest="$DIST/noarch"
	mkdir -p "$dest"
	echo ">> $NAME $VERSION (25.12)"
	download "$base/$ARTIFACT" "$dest/$ARTIFACT" "$SHA256"
	check_signature "$dest/$ARTIFACT"
	staged "$NAME" noarch "$ARTIFACT"

	# The 24.10 container, when upstream builds one. opkg calls the
	# architecture-independent package "all" where apk calls it noarch, so it goes
	# in the directory named for what it says it is.
	if [ -n "${ARTIFACT_IPK:-}" ]; then
		dest="$DIST/all"
		mkdir -p "$dest"
		echo ">> $NAME $VERSION (24.10)"
		download "$base/$ARTIFACT_IPK" "$dest/$ARTIFACT_IPK" "$SHA256_IPK"
		check_signature "$dest/$ARTIFACT_IPK"
		staged "$NAME" all "$ARTIFACT_IPK"
	fi
	;;

manifest)
	# Upstream publishes finished packages and a signed inventory of them.
	#
	# The strongest shape there is, and the one that needs the least maintained by
	# hand here: the manifest carries every package's size and sha256, and its
	# signature is what makes those trustworthy. So this repository pins the version
	# and the key, and nothing else -- the checksum table that KIND="apk" needs is
	# the manifest, verified rather than transcribed.
	[ -n "${SIG_KEY:-}" ] || { echo "$NAME: KIND=manifest requires SIG_KEY" >&2; exit 1; }

	work="$(mktemp -d)"
	get "$base/manifest.txt"     "$work/manifest.txt"
	get "$base/manifest.txt.sig" "$work/manifest.txt.sig"

	# VERIFY BEFORE READING. Every value below steers a download, so parsing first
	# would mean acting on text nobody has vouched for.
	owfeed verify-artifact --key "$ROOT/$SIG_KEY" --key-id "$SIG_KEY_ID" \
		--signature "$work/manifest.txt.sig" "$work/manifest.txt"

	# A signature proves who wrote something, never what it is about. One key often
	# signs several repositories, so without these two checks a manifest lifted from
	# another of this author's releases would verify perfectly as this one.
	got_repo="$(awk '$1=="repo"{print $2; exit}' "$work/manifest.txt")"
	got_tag="$(awk '$1=="tag"{print $2; exit}' "$work/manifest.txt")"
	[ "$got_repo" = "$REPO" ] || { echo "$NAME: manifest is for $got_repo, not $REPO" >&2; exit 1; }
	[ "$got_tag" = "$TAG" ] || { echo "$NAME: manifest is for $got_tag, not $TAG" >&2; exit 1; }

	# pkg <name> <format> <file> <size> <sha256> <arch>
	awk '$1=="pkg"{print $3, $4, $5, $6, $7}' "$work/manifest.txt" | while read -r fmt file size sum arch; do
		# opkg calls the architecture-independent package "all" where apk calls it
		# noarch, so each goes in the directory named for what it says it is.
		dest="$DIST/$arch"
		mkdir -p "$dest"

		# The asset name is not the name this gets published under. An apk's
		# filename carries no architecture -- in a feed the architecture is the
		# directory -- but release assets are flat, so `owfeed release` appended the
		# architecture where names collided. Taking it back off restores the name
		# the index derives, and is exactly the inverse of what put it there.
		out="$file"
		case "$fmt" in
		apk) out="$(printf '%s' "$file" | sed "s/_${arch}\.apk$/.apk/")" ;;
		esac

		echo ">> $NAME $VERSION $arch ($fmt)"
		download "$base/$file" "$dest/$out" "$sum"

		got_size="$(wc -c < "$dest/$out" | tr -d ' ')"
		[ "$got_size" = "$size" ] || { echo "$file: $got_size bytes, manifest says $size" >&2; exit 1; }

		# The manifest's signature already covers this file's hash, so a detached
		# signature beside it adds nothing here -- it exists for consumers that know
		# nothing about manifests. Checked when present, not required: an upstream
		# that publishes a manifest has no reason to also publish ninety signatures
		# nobody reads.
		if [ -n "${SIG_PER_PACKAGE:-yes}" ] && [ "${SIG_PER_PACKAGE:-yes}" = "yes" ]; then
			check_signature "$dest/$out" "$file"
		fi
		staged "$NAME" "$arch" "$out"
	done
	rm -rf "$work"
	;;

binaries)
	# Upstream publishes raw artifacts. Each one serves the architectures listed
	# beside it — a static binary needs the right target and no OpenWrt SDK, and one
	# build usually covers several OpenWrt architectures that share it.
	mkdir -p "$STAGING"
	echo "$VERSION" > "$STAGING/$NAME.version"
	rm -rf "${STAGING:?}/$NAME"

	echo "$ARTIFACTS" | while read -r artifact sha arches; do
		[ -n "$artifact" ] || continue
		echo ">> $NAME $VERSION $artifact"
		tmp="$(mktemp)"
		download "$base/$artifact" "$tmp" "$sha"
		check_signature "$tmp"

		for arch in $arches; do
			mkdir -p "$STAGING/$NAME/$arch$(dirname "${BINARY_DEST:?upstream.sh must set BINARY_DEST}")"
			install -m 0755 "$tmp" "$STAGING/$NAME/$arch$BINARY_DEST"
			# Anything the feed itself adds — an init script, a default config.
			[ -d "$ROOT/$DIR/files" ] && cp -a "$ROOT/$DIR/files/." "$STAGING/$NAME/$arch/"
		done
		rm -f "$tmp"
	done
	;;

*)
	echo "$NAME: KIND=$KIND is not a shape this feed knows" >&2
	exit 1
	;;
esac
