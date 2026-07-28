# luci-app-footstrap-updater — in-LuCI updater for the theme.
#
# Data only. tools/fetch.sh does the work.

KIND="apk"

# Upstream publishes both containers, so this package serves both release lines:
# 25.12 installs the .apk, 24.10 the .ipk. They are the same build.

REPO="VizzleTF/luci-app-footstrap-updater"
VERSION="1.2.0-r1"
ARTIFACT="luci-app-footstrap-updater-1.2.0-r1.apk"
SHA256="b43e2c449f7f225c93c8eeb901517558ae3c054fceb49083b8e7bb1c12bfeb5a"
ARTIFACT_IPK="luci-app-footstrap-updater_1.2.0-r1_all.ipk"
SHA256_IPK="858306f784850c27871e5830df3bc2259a97fc925ee8534775a1592981174b89"

SIG_KEY="keys/vizzletf-release.pub"
SIG_KEY_ID="18c63865e2bcf8d6"
AUTO_MERGE="yes"
