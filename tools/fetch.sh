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

# download <url> <dest> <sha256>
download() {
	curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"
	got="$(sha256sum "$2" | cut -d' ' -f1)"
	[ "$got" = "$3" ] || { echo "$1: sha256 $got, pinned $3" >&2; rm -f "$2"; exit 1; }
}

# check_signature <file>
#
# A pin proves the bytes have not changed since someone looked at them. The author's
# signature says who produced them, and only that can justify an update merging
# itself. The key is pinned in this repository: whoever can replace an artifact can
# replace the signature beside it and the key it names.
check_signature() {
	[ -n "${SIG_KEY:-}" ] || return 0
	curl -fsSL --proto '=https' --tlsv1.2 -o "$1.sig" "$base/$(basename "$1").sig"
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

	# The 24.10 container, when upstream builds one. opkg calls the
	# architecture-independent package "all" where apk calls it noarch, so it goes
	# in the directory named for what it says it is.
	if [ -n "${ARTIFACT_IPK:-}" ]; then
		dest="$DIST/all"
		mkdir -p "$dest"
		echo ">> $NAME $VERSION (24.10)"
		download "$base/$ARTIFACT_IPK" "$dest/$ARTIFACT_IPK" "$SHA256_IPK"
		check_signature "$dest/$ARTIFACT_IPK"
	fi
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
