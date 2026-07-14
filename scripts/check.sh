#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for script in "$ROOT_DIR"/scripts/*.sh; do
    bash -n "$script"
done

source "$ROOT_DIR/VERSION.env"
source "$ROOT_DIR/scripts/common.sh"
[[ "$WEBRTC_COMMIT" =~ ^[0-9a-f]{40}$ ]]
[[ "$DEPOT_TOOLS_COMMIT" =~ ^[0-9a-f]{40}$ ]]
[[ "$PACKAGE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+-watermelon\.[0-9]+$ ]]
require_file "$WEBRTC_PATCH"
require_file "$CHROMIUM_BUILD_PATCH"
git apply --stat "$WEBRTC_PATCH" >/dev/null
git apply --stat "$CHROMIUM_BUILD_PATCH" >/dev/null
grep -q 'rtc_data_channel_only=true' "$ROOT_DIR/scripts/build.sh"
grep -q 'optimize_for_minimum_size=true' "$ROOT_DIR/scripts/build.sh"

echo "Repository checks passed"
