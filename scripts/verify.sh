#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_directory "$XCFRAMEWORK_PATH"
require_file "$XCFRAMEWORK_PATH/Info.plist"
require_command lipo
require_command nm
require_command plutil

info_json="$(plutil -convert json -o - "$XCFRAMEWORK_PATH/Info.plist")"
grep -q 'ios-arm64' <<<"$info_json"
grep -q 'ios-arm64_x86_64-simulator' <<<"$info_json"

device_binary="$XCFRAMEWORK_PATH/ios-arm64/WebRTC.framework/WebRTC"
simulator_binary="$XCFRAMEWORK_PATH/ios-arm64_x86_64-simulator/WebRTC.framework/WebRTC"
require_file "$device_binary"
require_file "$simulator_binary"

[[ "$(lipo -archs "$device_binary")" == "arm64" ]]
simulator_archs="$(lipo -archs "$simulator_binary")"
grep -qw arm64 <<<"$simulator_archs"
grep -qw x86_64 <<<"$simulator_archs"

device_symbols="$(nm -gU "$device_binary")"
grep -q '_OBJC_CLASS_\$_RTCPeerConnection' <<<"$device_symbols"
grep -q '_OBJC_CLASS_\$_RTCDataChannel' <<<"$device_symbols"
if grep -q '_OBJC_CLASS_\$_LKRTC' <<<"$device_symbols"; then
    echo "Unexpected LiveKit-prefixed symbols found" >&2
    exit 1
fi
for removed_class in RTCAudioSource RTCVideoSource RTCCameraPreviewView RTCMediaStream; do
    if grep -q "_OBJC_CLASS_\\\$_$removed_class" <<<"$device_symbols"; then
        echo "Unexpected media class found: $removed_class" >&2
        exit 1
    fi
done

device_size="$(stat -f '%z' "$device_binary")"
[[ "$device_size" -le 3000000 ]] || {
    echo "Device WebRTC binary exceeds 3,000,000-byte budget: $device_size" >&2
    exit 1
}

license_count="$(find "$XCFRAMEWORK_PATH" -iname '*license*' -type f | wc -l | tr -d ' ')"
[[ "$license_count" -gt 0 ]] || {
    echo "Generated license bundle is missing" >&2
    exit 1
}

echo "Verified slices, data-channel-only symbols, size budget, and licenses"
