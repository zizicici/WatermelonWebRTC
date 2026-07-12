#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for script in "$ROOT_DIR"/scripts/*.sh; do
    bash -n "$script"
done

source "$ROOT_DIR/VERSION.env"
[[ "$WEBRTC_COMMIT" =~ ^[0-9a-f]{40}$ ]]
[[ "$DEPOT_TOOLS_COMMIT" =~ ^[0-9a-f]{40}$ ]]
[[ "$PACKAGE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

echo "Repository checks passed"

