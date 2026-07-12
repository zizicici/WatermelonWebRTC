#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

"$ROOT_DIR/scripts/verify.sh"
require_command swift
require_command ditto
require_command plutil
require_command zip

rm -rf "$DIST_DIR" "$RELEASE_ASSETS_DIR"
mkdir -p "$DIST_DIR/runtime" "$RELEASE_ASSETS_DIR"
runtime_xcframework="$DIST_DIR/runtime/WebRTC.xcframework"
ditto "$XCFRAMEWORK_PATH" "$runtime_xcframework"
for library_index in 0 1; do
    plutil -remove "AvailableLibraries.$library_index.DebugSymbolsPath" "$runtime_xcframework/Info.plist"
done
find "$runtime_xcframework" -type d -name dSYMs -prune -exec rm -rf {} +
find "$runtime_xcframework" -exec touch -h -t 202001010000 {} +
(
    cd "$DIST_DIR/runtime"
    find WebRTC.xcframework -print | LC_ALL=C sort | COPYFILE_DISABLE=1 zip -q -X "$ARCHIVE_PATH" -@
)
rm -rf "$DIST_DIR/runtime"

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

ditto "$ARCHIVE_PATH" "$RELEASE_ASSETS_DIR/$ARCHIVE_NAME"
ditto "$DIST_DIR/provenance.json" "$RELEASE_ASSETS_DIR/provenance.json"

echo "Packaged $ARCHIVE_PATH"
echo "SwiftPM checksum: $checksum"
