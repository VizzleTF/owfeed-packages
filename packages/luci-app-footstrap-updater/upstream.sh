# luci-app-footstrap-updater — in-LuCI updater for the theme.
#
# Data only. tools/fetch.sh does the work.

KIND="apk"

# Upstream publishes both containers, so this package serves both release lines:
# 25.12 installs the .apk, 24.10 the .ipk. They are the same build.

REPO="VizzleTF/luci-app-footstrap-updater"
VERSION="2.0.0-r1"
ARTIFACT="luci-app-footstrap-updater-2.0.0-r1.apk"
SHA256="1b2e0b7e14938a3b9ff39574cc6b47d28ba1dcd45f4861c202577242b7109d6c"
ARTIFACT_IPK="luci-app-footstrap-updater_2.0.0-r1_all.ipk"
SHA256_IPK="1aed26e6e06dc68c72d0341defa5407793c4bab93b83e9ce4006b9806d902d3a"

SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"
AUTO_MERGE="yes"
