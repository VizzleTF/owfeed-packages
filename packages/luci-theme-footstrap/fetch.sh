#!/bin/sh
# Take luci-theme-footstrap's released package as it is.
#
# Upstream's own CI builds this through the OpenWrt SDK, which compiles its CSS and
# its translation catalogues. Rebuilding it here would produce something the
# maintainer never tested, so the feed distributes exactly what they published and
# adds only its own signature.
set -eu

VERSION="0.11.6-r1"
REPO="VizzleTF/luci-theme-footstrap"
FILE="luci-theme-footstrap-${VERSION}.apk"
SHA256="e2e7bde2aec9dd44863573c5ddcb17162295e31b177d0e7d45e4d2b79b804259"

# A prebuilt package is architecture-independent, so it goes where owfeed puts a
# noarch build and is picked up by `owfeed sign` and `owfeed index` unchanged.
DEST="${1:-dist}/noarch"
mkdir -p "$DEST"

url="https://github.com/${REPO}/releases/download/v${VERSION%-r*}/${FILE}"
echo ">> $FILE"
curl -fsSL --proto '=https' --tlsv1.2 -o "$DEST/$FILE" "$url"

got="$(sha256sum "$DEST/$FILE" | cut -d' ' -f1)"
[ "$got" = "$SHA256" ] || { echo "$url: sha256 $got, pinned $SHA256" >&2; rm -f "$DEST/$FILE"; exit 1; }
