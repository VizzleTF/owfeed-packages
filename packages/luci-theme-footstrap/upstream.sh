# Rewritten by tools/check-updates.sh. Data only — no logic here.
REPO="VizzleTF/luci-theme-footstrap"
VERSION="0.11.6-r1"
ARTIFACT="luci-theme-footstrap-0.11.6-r1.apk"
SHA256="e2e7bde2aec9dd44863573c5ddcb17162295e31b177d0e7d45e4d2b79b804259"

# The release is verified against this key before it is ingested, so the feed's
# signature means the author signed it. The key id is pinned as well: the id inside
# a signature only says which key to look for, never that the key is the right one.
SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"

# Provenance from someone other than this feed, so an update may merge itself once
# CI is green. See CONTRIBUTING.md.
AUTO_MERGE="yes"
