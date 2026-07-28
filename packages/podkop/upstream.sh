# podkop — domain routing over VLESS / Shadowsocks.
#
# NOT ENABLED. See LEGAL.md: this is a third-party package under GPL-2.0-or-later
# with its own trademark policy, and neither the source-availability obligation nor
# the author's consent has been settled. The entry exists so the checks can be run
# against it, not so it can be published.

# Not fetched by CI: tools/fetch.sh is run over the packages listed in
# owfeed.yml, and this one is deliberately absent from it.
ENABLED="no"

KIND="apk"

REPO="itdoginfo/podkop"
VERSION="0.7.21-r1"

# This project tags without the customary v prefix.
TAG="0.7.21"
ARTIFACT="podkop-0.7.21-r1.apk"
SHA256="55870987143ff985272f151e36185e5616d2645aec6faae64e0f5a0f121c1e3b"

# The .ipk is named differently from the .apk in this project's releases —
# podkop-v0.7.21-r1-all.ipk rather than podkop_0.7.21-r1_all.ipk — so it is written
# out rather than derived.
ARTIFACT_IPK="podkop-v0.7.21-r1-all.ipk"
SHA256_IPK="e67956585f018b460fe3af62029577946a0da6faaac92669dfc0361efe09a0ef"

# Upstream publishes no detached signatures, so the pins above are the whole of the
# evidence and an update waits for a person.
AUTO_MERGE="no"
