#!/bin/sh
# Take luci-app-footstrap-updater's released package as it is.
#
# Upstream's own CI builds it through the OpenWrt SDK. The feed distributes exactly
# what they published and adds only its own signature.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
. "$HERE/upstream.sh"

# A prebuilt package is architecture-independent, so it goes where owfeed puts a
# noarch build and is picked up by `owfeed sign` and `owfeed index` unchanged.
DEST="${1:-dist}/noarch"
mkdir -p "$DEST"

url="https://github.com/${REPO}/releases/download/v${VERSION%-r*}/${ARTIFACT}"
echo ">> $ARTIFACT"
curl -fsSL --proto '=https' --tlsv1.2 -o "$DEST/$ARTIFACT" "$url"

got="$(sha256sum "$DEST/$ARTIFACT" | cut -d' ' -f1)"
[ "$got" = "$SHA256" ] || { echo "$url: sha256 $got, pinned $SHA256" >&2; rm -f "$DEST/$ARTIFACT"; exit 1; }

# The author's signature, checked before this enters the feed. Without it the
# feed's key would be attesting to a successful download and nothing more.
if [ -n "${SIG_KEY:-}" ]; then
	curl -fsSL --proto '=https' --tlsv1.2 -o "$DEST/$ARTIFACT.sig" \
		"https://github.com/${REPO}/releases/download/v${VERSION%-r*}/${ARTIFACT}.sig"
	owfeed verify-artifact \
		--key "$ROOT/$SIG_KEY" \
		--key-id "$SIG_KEY_ID" \
		--signature "$DEST/$ARTIFACT.sig" \
		"$DEST/$ARTIFACT"
	# The signature is evidence for this step, not something to publish: it is over
	# the file, and apk has no idea what to do with it.
	rm -f "$DEST/$ARTIFACT.sig"
fi
