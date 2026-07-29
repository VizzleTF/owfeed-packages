# luci-app-footstrap-updater — in-LuCI updater for the theme.
#
# Data only. tools/fetch.sh does the work.

KIND="apk"

# Upstream publishes both containers, so this package serves both release lines:
# 25.12 installs the .apk, 24.10 the .ipk. They are the same build.

REPO="VizzleTF/luci-app-footstrap-updater"
VERSION="1.2.1-r1"
ARTIFACT="luci-app-footstrap-updater-1.2.1-r1.apk"
SHA256="0ca4c58515f3668cf6a38068377091a6362fd6a8b962bbf1a166bb32b3254e0f"
ARTIFACT_IPK="luci-app-footstrap-updater_1.2.1-r1_all.ipk"
SHA256_IPK="710bea5672fb5f89306210126ddc2fe0af9e1247867f207875a73f4426d2935e"

SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"
AUTO_MERGE="yes"
