# Rewritten by tools/check-updates.sh. Data only — no logic here.
REPO="VizzleTF/luci-theme-footstrap"
VERSION="0.11.6-r1"
ARTIFACT="luci-theme-footstrap-0.11.6-r1.apk"
SHA256="e2e7bde2aec9dd44863573c5ddcb17162295e31b177d0e7d45e4d2b79b804259"

# Upstream signs its releases with usign and publishes <artifact>.sig. That is
# provenance from someone other than this feed, so an update may merge itself once
# CI is green. See CONTRIBUTING.md.
AUTO_MERGE="yes"
