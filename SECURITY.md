# Security policy

WatermelonWebRTC packages a pinned Google WebRTC source revision. Security updates are handled by reviewing upstream WebRTC and Chromium stable-branch changes, updating the pinned commit, rebuilding from source, and publishing a new immutable release.

Release assets are never replaced in place. Consumers must pin a semantic version and SwiftPM checksum.

Report suspected build, provenance, or binary-integrity issues privately to the repository owner.

