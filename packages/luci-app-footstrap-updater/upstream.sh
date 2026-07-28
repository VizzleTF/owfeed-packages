# Rewritten by tools/check-updates.sh. Data only — no logic here.
REPO="VizzleTF/luci-app-footstrap-updater"
VERSION="1.1.0-r1"
ARTIFACT="luci-app-footstrap-updater-1.1.0-r1.apk"
SHA256="1ef557f04a5c14c84f8e46b2947252762c84155f5f6c7fd5f54852a7cebfb50e"

# The release is verified against this key before it is ingested, so the feed's
# signature means the author signed it. The key id is pinned as well: the id inside
# a signature only says which key to look for, never that the key is the right one.
SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"

# Provenance from someone other than this feed, so an update may merge itself once
# CI is green. See CONTRIBUTING.md.
AUTO_MERGE="yes"
