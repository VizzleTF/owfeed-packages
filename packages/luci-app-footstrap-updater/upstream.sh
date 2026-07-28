# luci-app-footstrap-updater — in-LuCI updater for the theme.
#
# Data only. tools/fetch.sh does the work.

KIND="apk"

# Upstream publishes both containers, so this package serves both release lines:
# 25.12 installs the .apk, 24.10 the .ipk. They are the same build.

REPO="VizzleTF/luci-app-footstrap-updater"
VERSION="1.1.0-r1"
ARTIFACT="luci-app-footstrap-updater-1.1.0-r1.apk"
SHA256="1ef557f04a5c14c84f8e46b2947252762c84155f5f6c7fd5f54852a7cebfb50e"
ARTIFACT_IPK="luci-app-footstrap-updater_1.1.0-r1_all.ipk"
SHA256_IPK="60901c9fd4654a9eae3686dcde36ee154775861a5fe8c3414cdc6ddb2cfcf6ba"

SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"
AUTO_MERGE="yes"
