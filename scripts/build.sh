#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_directory "$WEBRTC_SRC_DIR"
require_file "$WEBRTC_SRC_DIR/tools_webrtc/ios/build_ios_libs.py"
require_command xcodebuild

WATERMELON_GN_ARGS=(
    rtc_data_channel_only=true
    ios_disable_objc_archive_autoload=true
    rtc_include_opus=false
    rtc_include_dav1d_in_internal_decoder_factory=false
    enable_libaom=false
    rtc_exclude_audio_processing_module=true
    rtc_ios_use_opengl_rendering=false
    rtc_enable_protobuf=false
    rtc_video_psnr=false
    rtc_disable_metrics=true
    is_official_build=true
    optimize_for_size=true
    optimize_for_minimum_size=true
    use_thin_lto=true
    thin_lto_enable_optimizations=false
)

actual_commit="$(git -C "$WEBRTC_SRC_DIR" rev-parse HEAD)"
[[ "$actual_commit" == "$WEBRTC_COMMIT" ]] || {
    echo "Refusing to build unpinned WebRTC commit: $actual_commit" >&2
    exit 1
}

"$ROOT_DIR/scripts/patches.sh" --apply

rm -rf "$WEBRTC_OUTPUT_DIR" "$XCFRAMEWORK_PATH"
mkdir -p "$ARTIFACTS_DIR"

(
    cd "$WEBRTC_SRC_DIR"
    tools_webrtc/ios/build_ios_libs.py \
        --build_config release \
        --arch device:arm64 simulator:arm64 simulator:x64 \
        --deployment-target "$IOS_DEPLOYMENT_TARGET" \
        --revision "$PACKAGE_REVISION" \
        --output-dir "$WEBRTC_OUTPUT_DIR" \
        --extra-gn-args "${WATERMELON_GN_ARGS[@]}"
)

require_directory "$WEBRTC_OUTPUT_DIR/WebRTC.xcframework"
ditto "$WEBRTC_OUTPUT_DIR/WebRTC.xcframework" "$XCFRAMEWORK_PATH"

echo "Built $XCFRAMEWORK_PATH"
