#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

"$ROOT_DIR/scripts/verify.sh"
require_command swift
require_command ditto

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_PATH" "$ARCHIVE_PATH"

checksum="$(swift package compute-checksum "$ARCHIVE_PATH")"
sed \
    -e "s|__BINARY_URL__|$RELEASE_URL|g" \
    -e "s|__BINARY_CHECKSUM__|$checksum|g" \
    "$ROOT_DIR/Package.swift.template" > "$ROOT_DIR/Package.swift"

cat > "$DIST_DIR/provenance.json" <<EOF
{
  "packageVersion": "$PACKAGE_VERSION",
  "webrtcMilestone": $WEBRTC_MILESTONE,
  "webrtcBranch": "$WEBRTC_BRANCH",
  "webrtcCommit": "$WEBRTC_COMMIT",
  "depotToolsCommit": "$DEPOT_TOOLS_COMMIT",
  "iosDeploymentTarget": "$IOS_DEPLOYMENT_TARGET",
  "archive": "$ARCHIVE_NAME",
  "swiftPackageChecksum": "$checksum"
}
EOF

echo "Packaged $ARCHIVE_PATH"
echo "SwiftPM checksum: $checksum"

