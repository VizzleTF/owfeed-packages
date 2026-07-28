#!/bin/sh
# Stage podkop_updater from its upstream release.
#
# The binary is a static Go build, so one artifact serves every OpenWrt architecture
# that shares its GOARCH. No SDK is involved, and none is needed.
set -eu

VERSION="0.3.4"
REPO="VizzleTF/podkop_autoupdater"
HERE="$(cd "$(dirname "$0")" && pwd)"
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

# sha256 of each published artifact, recorded from the release. Upstream publishes a
# .sha256 beside each binary, but a checksum served by the same host from the same
# release is not a verification of it — pinning here is what makes it one.
sums() {
	cat <<'SUMS'
amd64   2d64d66c9fe9ae337a7f7559307256d62f23124c5556ff22e928aa6d8e2f82a8
arm64   ba045eaa5369c0cc06060cf863d94ef56c157a83afdf0bc1e806f1f2f8b017b1
armv7   c745f835fef439c6cad00ad85c25dea484e4ac53747253fe2e79ba4c8500b13f
mips    e3b9f23105dabf33d4f3f4874a2f08c101f3081fd1922427b82e7193b1f2e743
mipsle  6cb925ec66ff6ff7b39aff5b09d3d60a95e6c0e2ffd8245364590fc444febbff
SUMS
}

mkdir -p "$(dirname "$STAGING")"
echo "${VERSION}-r1" > "$(dirname "$STAGING")/podkop-updater.version"
rm -rf "$STAGING"

targets | while read -r goarch arches; do
	want="$(sums | awk -v t="$goarch" '$1 == t { print $2 }')"
	[ -n "$want" ] || { echo "no checksum pinned for $goarch" >&2; exit 1; }

	tmp="$(mktemp)"
	url="https://github.com/${REPO}/releases/download/v${VERSION}/podkop_updater-${goarch}"
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
