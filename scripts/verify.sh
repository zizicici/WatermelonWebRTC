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

nm -gU "$device_binary" | grep -q '_OBJC_CLASS_\$_RTCPeerConnection'
nm -gU "$device_binary" | grep -q '_OBJC_CLASS_\$_RTCDataChannel'
if nm -gU "$device_binary" | grep -q '_OBJC_CLASS_\$_LKRTC'; then
    echo "Unexpected LiveKit-prefixed symbols found" >&2
    exit 1
fi

license_count="$(find "$XCFRAMEWORK_PATH" -iname '*license*' -type f | wc -l | tr -d ' ')"
[[ "$license_count" -gt 0 ]] || {
    echo "Generated license bundle is missing" >&2
    exit 1
}

echo "Verified device and simulator slices, RTC symbols, and licenses"

