# Rewritten by tools/check-updates.sh. Data only — no logic here.
REPO="VizzleTF/podkop_autoupdater"
VERSION="0.3.4-r1"

# One artifact per GOARCH. ARTIFACTS is "<name> <sha256>" per line; the GOARCH-to-
# OpenWrt-architecture mapping lives in fetch.sh, because it is a property of the
# toolchain rather than of the release.
ARTIFACTS="
podkop_updater-amd64  2d64d66c9fe9ae337a7f7559307256d62f23124c5556ff22e928aa6d8e2f82a8
podkop_updater-arm64  ba045eaa5369c0cc06060cf863d94ef56c157a83afdf0bc1e806f1f2f8b017b1
podkop_updater-armv7  c745f835fef439c6cad00ad85c25dea484e4ac53747253fe2e79ba4c8500b13f
podkop_updater-mips   e3b9f23105dabf33d4f3f4874a2f08c101f3081fd1922427b82e7193b1f2e743
podkop_updater-mipsle 6cb925ec66ff6ff7b39aff5b09d3d60a95e6c0e2ffd8245364590fc444febbff
"

# Upstream publishes a .sha256 beside each binary and nothing else. A checksum
# served by the same host from the same release is not provenance, so an update
# here is reviewed by a person before it is signed with this feed's key.
AUTO_MERGE="no"
