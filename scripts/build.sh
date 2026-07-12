#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_directory "$WEBRTC_SRC_DIR"
require_file "$WEBRTC_SRC_DIR/tools_webrtc/ios/build_ios_libs.py"
require_command xcodebuild

actual_commit="$(git -C "$WEBRTC_SRC_DIR" rev-parse HEAD)"
[[ "$actual_commit" == "$WEBRTC_COMMIT" ]] || {
    echo "Refusing to build unpinned WebRTC commit: $actual_commit" >&2
    exit 1
}

rm -rf "$WEBRTC_OUTPUT_DIR" "$XCFRAMEWORK_PATH"
mkdir -p "$ARTIFACTS_DIR"

(
    cd "$WEBRTC_SRC_DIR"
    tools_webrtc/ios/build_ios_libs.py \
        --build_config release \
        --arch device:arm64 simulator:arm64 simulator:x64 \
        --deployment-target "$IOS_DEPLOYMENT_TARGET" \
        --revision "$PACKAGE_REVISION" \
        --output-dir "$WEBRTC_OUTPUT_DIR"
)

require_directory "$WEBRTC_OUTPUT_DIR/WebRTC.xcframework"
ditto "$WEBRTC_OUTPUT_DIR/WebRTC.xcframework" "$XCFRAMEWORK_PATH"

echo "Built $XCFRAMEWORK_PATH"

