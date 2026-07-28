#!/bin/sh
# Stage podkop_updater from its upstream release.
#
# The binary is a static Go build, so one artifact serves every OpenWrt architecture
# that shares its GOARCH. No SDK is involved, and none is needed.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/upstream.sh"
STAGING="${1:-staging}/podkop-updater"

# GOARCH target -> the OpenWrt architectures it runs on.
# armv7 covers the Cortex-A cores OpenWrt builds for; the older ARMv5 targets
# (arm926ej-s, fa526, xscale) would need a separate GOARM=5 build and upstream
# does not publish one, so they are simply not covered.
targets() {
	cat <<'MAP'
amd64   x86_64
arm64   aarch64_cortex-a53 aarch64_cortex-a72 aarch64_cortex-a76 aarch64_generic
armv7   arm_cortex-a5_vfpv4 arm_cortex-a7 arm_cortex-a7_neon-vfpv4 arm_cortex-a7_vfpv4 arm_cortex-a8_vfpv3 arm_cortex-a9 arm_cortex-a9_neon arm_cortex-a9_vfpv3-d16 arm_cortex-a15_neon-vfpv4
mips    mips_24kc mips_mips32
mipsle  mipsel_24kc mipsel_24kc_24kf mipsel_74kc mipsel_mips32
MAP
}

# The pins live in upstream.sh so the update bot rewrites data, never logic.
sums() {
	echo "$ARTIFACTS" | awk 'NF { sub(/^podkop_updater-/, "", $1); print $1, $2 }'
}

mkdir -p "$(dirname "$STAGING")"
echo "${VERSION}" > "$(dirname "$STAGING")/podkop-updater.version"
rm -rf "$STAGING"

targets | while read -r goarch arches; do
	want="$(sums | awk -v t="$goarch" '$1 == t { print $2 }')"
	[ -n "$want" ] || { echo "no checksum pinned for $goarch" >&2; exit 1; }

	tmp="$(mktemp)"
	url="https://github.com/${REPO}/releases/download/v${VERSION%-r*}/podkop_updater-${goarch}"
	echo ">> $goarch"
	curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp" "$url"

	got="$(sha256sum "$tmp" | cut -d' ' -f1)"
	[ "$got" = "$want" ] || { echo "$url: sha256 $got, pinned $want" >&2; exit 1; }

	for arch in $arches; do
		mkdir -p "$STAGING/$arch/usr/bin"
		install -m 0755 "$tmp" "$STAGING/$arch/usr/bin/podkop_updater"
		cp -a "$HERE/files/." "$STAGING/$arch/"
	done
	rm -f "$tmp"
done
