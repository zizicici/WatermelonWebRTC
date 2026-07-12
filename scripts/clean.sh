#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

rm -rf "$WEBRTC_OUTPUT_DIR" "$ARTIFACTS_DIR" "$DIST_DIR"
echo "Removed build outputs; source checkout and depot_tools were preserved"

