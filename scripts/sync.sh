#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_command git
require_command xcodebuild

mkdir -p "$BUILD_ROOT"

if [[ ! -d "$DEPOT_TOOLS_DIR/.git" ]]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
fi

git -C "$DEPOT_TOOLS_DIR" fetch origin main
git -C "$DEPOT_TOOLS_DIR" checkout --detach "$DEPOT_TOOLS_COMMIT"

if [[ ! -d "$WEBRTC_SRC_DIR/.git" ]]; then
    mkdir -p "$CHECKOUT_ROOT"
    (
        cd "$CHECKOUT_ROOT"
        fetch --nohooks --no-caffeinate webrtc_ios
    )
fi

git -C "$WEBRTC_SRC_DIR" fetch origin "$WEBRTC_REF"
git -C "$WEBRTC_SRC_DIR" checkout --detach "$WEBRTC_COMMIT"
(
    cd "$CHECKOUT_ROOT"
    gclient sync --delete_unversioned_trees --with_branch_heads --with_tags --revision "src@$WEBRTC_COMMIT"
)

actual_commit="$(git -C "$WEBRTC_SRC_DIR" rev-parse HEAD)"
[[ "$actual_commit" == "$WEBRTC_COMMIT" ]] || {
    echo "WebRTC checkout mismatch: $actual_commit" >&2
    exit 1
}

echo "Synced Google WebRTC $WEBRTC_COMMIT"

