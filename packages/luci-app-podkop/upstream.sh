# luci-app-podkop — the LuCI application for podkop.
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
ARTIFACT="luci-app-podkop-0.7.21-r1.apk"
SHA256="aa370b9ba123b570a630bdf408fa2de291a1e0c0bb4cfaecb2350f4d15eebc12"

# The .ipk is named differently from the .apk in this project's releases —
# luci-app-podkop-v0.7.21-r1-all.ipk rather than podkop_0.7.21-r1_all.ipk — so it is written
# out rather than derived.
ARTIFACT_IPK="luci-app-podkop-v0.7.21-r1-all.ipk"
SHA256_IPK="280eac58d6ae43601d4aaa05342d2b47415384ef16f9664a09cf309816667f92"

# Upstream publishes no detached signatures, so the pins above are the whole of the
# evidence and an update waits for a person.
AUTO_MERGE="no"
