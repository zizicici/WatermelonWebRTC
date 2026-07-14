#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

mode="${1:---apply}"
[[ "$mode" == "--apply" || "$mode" == "--reverse" || "$mode" == "--check" ]] || {
    echo "Usage: $0 [--apply|--reverse|--check]" >&2
    exit 2
}

require_command git
require_file "$WEBRTC_PATCH"
require_file "$CHROMIUM_BUILD_PATCH"
require_directory "$WEBRTC_SRC_DIR"
require_directory "$WEBRTC_SRC_DIR/build"

patch_state() {
    local repository="$1"
    local patch="$2"

    if git -C "$repository" apply --reverse --check "$patch" >/dev/null 2>&1; then
        echo applied
        return
    fi

    if git -C "$repository" apply --check "$patch" >/dev/null 2>&1; then
        echo pristine
        return
    fi

    echo mismatch
}

webrtc_state="$(patch_state "$WEBRTC_SRC_DIR" "$WEBRTC_PATCH")"
chromium_state="$(patch_state "$WEBRTC_SRC_DIR/build" "$CHROMIUM_BUILD_PATCH")"

if [[ "$webrtc_state" == "mismatch" || "$chromium_state" == "mismatch" ]]; then
    echo "Patch set does not match the pinned checkout" >&2
    exit 1
fi

if [[ "$mode" == "--check" ]]; then
    [[ "$webrtc_state" == "applied" && "$chromium_state" == "applied" ]] || {
        echo "Patch set is not fully applied" >&2
        exit 1
    }
    echo "Patch set ready"
    exit 0
fi

if [[ "$mode" == "--apply" ]]; then
    [[ "$webrtc_state" == "applied" ]] || git -C "$WEBRTC_SRC_DIR" apply "$WEBRTC_PATCH"
    [[ "$chromium_state" == "applied" ]] || git -C "$WEBRTC_SRC_DIR/build" apply "$CHROMIUM_BUILD_PATCH"
    echo "Patch set applied"
    exit 0
fi

[[ "$webrtc_state" == "pristine" ]] || git -C "$WEBRTC_SRC_DIR" apply --reverse "$WEBRTC_PATCH"
[[ "$chromium_state" == "pristine" ]] || git -C "$WEBRTC_SRC_DIR/build" apply --reverse "$CHROMIUM_BUILD_PATCH"
echo "Patch set reverted"
