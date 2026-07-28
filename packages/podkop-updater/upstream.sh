# podkop-updater — watches podkop releases, drives update and rollback from Telegram.
#
# Data only. tools/fetch.sh does the work.

# Upstream publishes static Go binaries rather than packages, so owfeed builds them.
# See the packages: entry in owfeed.yml.
KIND="binaries"

REPO="VizzleTF/podkop_autoupdater"
VERSION="0.3.4-r1"

# Where the binary installs. The payload is a piece of the root filesystem.
BINARY_DEST="/usr/bin/podkop_updater"

# <artifact> <sha256> <the OpenWrt architectures it runs on>
#
# A static binary needs the right target and no SDK, so one build serves every
# architecture that shares its GOARCH. The ARMv5 targets (arm926ej-s, fa526,
# xscale) would need a GOARM=5 build and upstream publishes none, so they are not
# covered rather than covered badly.
ARTIFACTS="
podkop_updater-amd64  2d64d66c9fe9ae337a7f7559307256d62f23124c5556ff22e928aa6d8e2f82a8  x86_64
podkop_updater-arm64  ba045eaa5369c0cc06060cf863d94ef56c157a83afdf0bc1e806f1f2f8b017b1  aarch64_cortex-a53 aarch64_cortex-a72 aarch64_cortex-a76 aarch64_generic
podkop_updater-armv7  c745f835fef439c6cad00ad85c25dea484e4ac53747253fe2e79ba4c8500b13f  arm_cortex-a5_vfpv4 arm_cortex-a7 arm_cortex-a7_neon-vfpv4 arm_cortex-a7_vfpv4 arm_cortex-a8_vfpv3 arm_cortex-a9 arm_cortex-a9_neon arm_cortex-a9_vfpv3-d16 arm_cortex-a15_neon-vfpv4
podkop_updater-mips   e3b9f23105dabf33d4f3f4874a2f08c101f3081fd1922427b82e7193b1f2e743  mips_24kc mips_mips32
podkop_updater-mipsle 6cb925ec66ff6ff7b39aff5b09d3d60a95e6c0e2ffd8245364590fc444febbff  mipsel_24kc mipsel_24kc_24kf mipsel_74kc mipsel_mips32
"

# Upstream publishes a .sha256 beside each binary and no signature. A checksum
# served by the same host as the artifact is not provenance, so updates here wait
# for a person.
AUTO_MERGE="no"

# Pending: upstream now builds and signs its own packages.
#
# VizzleTF/podkop_autoupdater has moved onto owfeed and its next release will carry
# apk and ipk packages plus a usign-signed manifest, under key 37ddece4c0eef357 --
# already pinned at keys/podkop-updater.pub. When that release exists this entry
# stops being KIND="binaries" and starts carrying what upstream published, and
# AUTO_MERGE can become "yes": the provenance will come from somewhere other than
# this feed.
#
# Until then this stays as it is. Switching first would mean fetching assets that
# are not there yet.
