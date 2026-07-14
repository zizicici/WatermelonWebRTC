#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/VERSION.env"

BUILD_ROOT="${WATERMELON_WEBRTC_BUILD_ROOT:-$HOME/Library/Caches/WatermelonWebRTC}"
DEPOT_TOOLS_DIR="$BUILD_ROOT/depot_tools"
CHECKOUT_ROOT="$BUILD_ROOT/checkout"
WEBRTC_SRC_DIR="$CHECKOUT_ROOT/src"
WEBRTC_OUTPUT_DIR="$WEBRTC_SRC_DIR/out_watermelon_ios"
ARTIFACTS_DIR="$ROOT_DIR/Artifacts"
XCFRAMEWORK_PATH="$ARTIFACTS_DIR/WebRTC.xcframework"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_ASSETS_DIR="$ROOT_DIR/release-assets"
ARCHIVE_NAME="WebRTC-$PACKAGE_VERSION.xcframework.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"
RELEASE_URL="https://github.com/zizicici/WatermelonWebRTC/releases/download/$PACKAGE_VERSION/$ARCHIVE_NAME"
PATCHES_DIR="$ROOT_DIR/patches"
WEBRTC_PATCH="$PATCHES_DIR/webrtc-data-channel-only.patch"
CHROMIUM_BUILD_PATCH="$PATCHES_DIR/chromium-ios-minsize.patch"
BUILD_PROFILE="watermelon-data-channel-only-minsize-v1"

export PATH="$DEPOT_TOOLS_DIR:$PATH"
export DEPOT_TOOLS_UPDATE=0

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

require_file() {
    [[ -f "$1" ]] || {
        echo "Missing required file: $1" >&2
        exit 1
    }
}

require_directory() {
    [[ -d "$1" ]] || {
        echo "Missing required directory: $1" >&2
        exit 1
    }
}

patch_set_sha256() {
    (
        cd "$ROOT_DIR"
        shasum -a 256 \
            patches/chromium-ios-minsize.patch \
            patches/webrtc-data-channel-only.patch
    ) | shasum -a 256 | awk '{print $1}'
}
