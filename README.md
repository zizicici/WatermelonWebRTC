# WatermelonWebRTC

Reproducible iOS binary distribution of the official Google WebRTC Objective-C SDK, tailored for Watermelon's Browser Link data channels.

This repository pins an exact commit from `webrtc.googlesource.com`, applies a reviewed data-channel-only patch set, builds `WebRTC.xcframework` with Google's own iOS build script, verifies the result, and packages it for Swift Package Manager. It does not rename upstream symbols or redistribute a third-party build.

The build keeps peer connections, SDP, ICE, DTLS, SCTP, and data channels. GN options and the patches in `patches/` remove Objective-C media implementations, audio/video factories, capture/rendering helpers, broad Objective-C archive loading, Opus, AV1, audio processing, protobuf event logging, PSNR helpers, and internal metrics. The remaining Objective-C media headers are not a supported API surface for this package.

This is a Watermelon-maintained custom binary, not an official Google release. The source code and the upstream build entry point come from Google WebRTC; the reduced build profile, patches, packaging, and release version belong to this repository.

## Where this build comes from

Release `144.7559.2-watermelon.1` has the following lineage:

1. Check out Google's WebRTC milestone 144 branch head `refs/branch-heads/7559` at commit `2e1433bcaaa9582126e2af48a3c5d712331931c4`.
2. Check out Chromium `depot_tools` at commit `953e42245133578f3af7abebe9f929f2cfc549cf` and use it to synchronize Google's pinned dependency graph.
3. Apply `patches/webrtc-data-channel-only.patch` to the WebRTC checkout and `patches/chromium-ios-minsize.patch` to its Chromium build checkout.
4. Invoke Google's `tools_webrtc/ios/build_ios_libs.py` for iOS device arm64 and simulator arm64/x86_64, with the Watermelon data-channel-only and minimum-size GN arguments from `scripts/build.sh`.
5. Verify the architectures, required peer-connection and data-channel symbols, absence of selected media classes, generated licenses, and the device-binary size limit.
6. Remove dSYMs from the runtime archive, create a deterministic zip, compute its SwiftPM checksum, and publish it as an immutable GitHub release asset.

The earlier `144.7559.1` release in this repository was a full WebRTC build from the same pinned Google commit. `144.7559.2-watermelon.1` is produced by rebuilding that source with the first Watermelon data-channel-only profile; it is not a newer upstream WebRTC revision and is not derived from another vendor's XCFramework.

The custom version is intentionally distinct from upstream numbering:

| Component | Meaning |
| --- | --- |
| `144` | Google WebRTC milestone |
| `7559` | Google WebRTC branch head |
| `2` | Binary package revision in this repository |
| `watermelon.1` | Watermelon custom build-profile revision |

The authoritative pins and current package version live in `VERSION.env`. Each release also includes `provenance.json`, which records the exact source commit, tool commit, patch-set hash, build profile, deployment target, archive name, and SwiftPM checksum.

## Optimization record

The measurements below come from the July 14, 2026 optimization run. App-level numbers were taken from signed Watermelon Release archives and repacked with the same IPA procedure. Exact byte counts are used because decimal MB and binary MiB obscure small differences. Runs later found to contain the wrong cached framework are excluded.

### App-level progression

| Stage | WebRTC configuration | IPA size | Change from previous stage | Increase over Watermelon 1.5.8 |
| --- | --- | ---: | ---: | ---: |
| Watermelon 1.5.8 | No WebRTC | 14,434,623 B | — | — |
| Watermelon 1.6.0 | Full `144.7559.1` SDK | 19,559,873 B | +5,125,250 B | +5,125,250 B |
| Safe trim | Public GN switches only | 17,523,607 B | -2,036,266 B | +3,088,984 B |
| Data-channel-only | No-media factory and Objective-C implementation pruning | 16,247,720 B | -1,275,887 B | +1,813,097 B |
| Minimum-size candidate | Data-channel-only plus `-Oz`, official build, and ThinLTO O0 | 15,916,445 B | -331,275 B | +1,481,822 B |

The final candidate reduced the Watermelon 1.6.0 IPA by 3,643,428 bytes, or 18.63%. The remaining 1,481,822-byte difference from 1.5.8 is only an approximate WebRTC feature cost because the two app versions also contain unrelated code changes.

Before compression, the signed app grew from 27,951,104 to 38,764,544 bytes when full WebRTC was introduced, an increase of 10,813,440 bytes. The 10,210,208-byte embedded WebRTC executable accounted for about 94.42% of that increase.

The framework contribution measured inside those IPAs was:

| Stage | WebRTC executable | Compressed WebRTC IPA entry |
| --- | ---: | ---: |
| Full SDK | 10,210,208 B | 4,870,808 B |
| Safe trim | 6,202,576 B | 2,836,891 B |
| Data-channel-only | 3,385,488 B | 1,519,350 B |
| Minimum-size candidate | approximately 2.74 MB signed; 2,718,756 B before signing | 1,184,595 B |

### What changed at each stage

1. **Full SDK baseline.** The unmodified Objective-C framework exported audio, video, camera, codec, rendering, RTP, PeerConnection, and DataChannel implementations even though Browser Link only used PeerConnection and DataChannel. It accounted for 4,870,808 of the 5,125,250 compressed bytes added to the IPA.
2. **Safe GN-only trim.** The first retained build disabled Opus, AV1, the audio processing module, OpenGL rendering, protobuf event logging, PSNR helpers, and internal metrics. It kept the upstream Objective-C build graph and public implementation surface. The signed WebRTC executable fell by 4,007,632 bytes and the IPA fell by 2,036,266 bytes. VP8, VP9, H264, and many media implementations remained because the upstream `framework_objc` target still pulled them in.
3. **No-media factory.** The next experiment made the Objective-C factory use WebRTC's supported modular factory without a media engine. Removing only the framework's top-level codec dependencies saved about another 0.28 MB after compression, showing that the monolithic Objective-C base target still retained most media code.
4. **Objective-C and link-graph pruning.** The WebRTC patch then removed media-only Objective-C implementations and dependencies, disabled broad Objective-C archive autoloading, and replaced `-all_load` / global `-ObjC` behavior with explicit loading of the required base, constraints, and helper archives. Intermediate device binaries moved from about 6.15 MB to 3.46 MB, then to about 3.31 MB after unused stats, metrics, tracing, RTP wrappers, and media track implementations were removed. A runtime probe exposed a missing `NSString` conversion category; the small helper archive containing it was explicitly restored before testing continued.
5. **End-to-end validation.** Two PeerConnections in one simulator process exchanged offer/answer and ICE candidates, opened an SCTP DataChannel, and transferred a binary message. The resulting framework also compiled, linked, signed, and passed deep signature validation inside a fresh Watermelon Release archive.
6. **Minimum-size compiler pass.** The first aggressive build had not enabled the official size profile. Adding `is_official_build`, size optimization, and ThinLTO reduced the unsigned device binary from 3,341,052 to 2,867,948 bytes. Adding the Chromium `-Oz` option and removing unused camera/device helpers reduced it again to 2,718,756 bytes. The final fresh Watermelon archive was 15,916,445 bytes.
7. **Reproducible packaging.** The repository build produced device arm64 and simulator arm64/x86_64 slices. Packaging removed dSYMs from the runtime download, fixed timestamps, sorted ZIP entries, generated `provenance.json`, and computed the SwiftPM checksum. A post-release repack from `Artifacts/WebRTC.xcframework` was byte-for-byte identical to the committed and remotely published archive.

### Published-release comparison

Both releases below were downloaded again and measured with the same commands during the post-release audit:

| Measurement | Full `144.7559.1` | `144.7559.2-watermelon.1` | Reduction |
| --- | ---: | ---: | ---: |
| Runtime XCFramework ZIP | 16,091,168 B | 3,885,575 B | 12,205,593 B / 75.85% |
| Expanded regular files | 34,977,013 B | 8,901,166 B | 26,075,847 B / 74.55% |
| Device arm64 executable | 10,112,868 B | 2,718,756 B | 7,394,112 B / 73.12% |
| Simulator arm64/x86_64 executable | 24,364,560 B | 5,696,432 B | 18,668,128 B / 76.62% |
| Exported `RTC*` Objective-C classes | 71 | 14 | 57 / 80.28% |
| Exported media/RTP/codec classes in the audit pattern | 39 | 0 | 39 / 100% |
| Public headers | 93 | 93 | 0 |

The final runtime ZIP checksum is `ed55a50ce98c2f59f726a6d1e54bea075e7ecdabee8b7bc93910969ec603fa14`. The downloaded GitHub asset, committed release asset, local `dist` archive, and independently repacked archive all matched byte for byte. The recorded patch-set SHA-256 also recomputed to `300c65fd18cc5a5502ce0aad1a03667662c53aa051574d27b5ac6dfb38fdc0d6`.

dSYMs are retained in the local build artifact but are not runtime content. The final XCFramework plus dSYMs contains 187,059,810 bytes of regular files, of which 178,158,530 bytes are dSYM files. Repacking the same artifact with dSYMs produced a 48,001,236-byte ZIP; the published runtime ZIP is 3,885,575 bytes, a packaging-only reduction of 44,115,661 bytes or 91.91%. This dSYM exclusion was already used by the full release, so it is not counted as a data-channel optimization.

### Invalid, superseded, and rejected attempts

| Attempt | Observed result | Decision |
| --- | --- | --- |
| Pass `--clean` to Google's iOS build script | The option cleaned the output and exited; it did not clean and then build | Reran the build without `--clean`; no size result was recorded for the clean-only run |
| First Watermelon archive with the safe framework | Xcode's binary-artifact cache silently selected the original WebRTC framework | Invalidated that IPA number, corrected the SwiftPM artifact path, and rebuilt with isolated/fresh build data |
| Remove only top-level media factories | Saved only about 0.28 MB compressed | Superseded by pruning the monolithic Objective-C dependency graph |
| Disable Objective-C archive autoloading without explicit helpers | The app linked, but the runtime probe missed the `NSString` conversion category | Added the required helper archive explicitly; the broken variant was discarded |
| ThinLTO link optimization O2 | Device binary grew from 2,718,756 to 2,784,244 bytes and compressed output grew by about 89 KB | Reverted to ThinLTO link optimization O0 |
| Disable automatic stack-variable initialization | Saved only about 32 KB before compression and 18 KB after compression | Rejected because the security-hardening loss was not worth the size gain |
| Link individual Objective-C root classes instead of required archives | Saved 168 bytes | Rejected as overfitted to the current Swift call sites |
| Enable the arm64 machine outliner | Not executed because upstream disables it for iOS correctness concerns | Rejected without publishing an unsafe experiment |
| Version the custom build as `144.7559.2` | Could be mistaken for an official/upstream release | Changed before commit to `144.7559.2-watermelon.1`; no plain `144.7559.2` tag or release was created |

### Current scope and audit limitations

- This package is intentionally not a general-purpose WebRTC SDK. Its 93 public headers are currently identical to the full build, but most media implementations are absent. Header visibility does not mean an API is supported.
- The final device binary exports only certificate, configuration, constraints, ICE, SDP, PeerConnection, DataChannel, buffer, crypto-options, and dispatcher classes. No audited audio/video/camera/codec/RTP Objective-C class is exported.
- The Mach-O still contains load commands for several Apple media-related system frameworks, although the final binary has no matching undefined audio/video symbols. Removing those unused load commands may save a very small amount but was not part of this release.
- GitHub Actions checks repository scripts and publishes committed release inputs; it does not rebuild the roughly 60 GB upstream checkout. The binary trust boundary therefore includes the controlled local macOS build described above.
- The current release workflow verifies tag/version and asset existence, but does not itself recompute and cross-check every checksum field. The current release was independently cross-checked, but this is a hardening opportunity for future releases.
- `verify.sh` enforces required DataChannel symbols, a selected media-class denylist, architectures, licenses, and a 3,000,000-byte device limit. A complete exported-class allowlist and stricter upstream-checkout cleanliness checks would make future regression detection stronger.
- The synchronized source tree is build input, not package content. During this run it occupied 41.45 GiB and 608,734 filesystem entries after alternate outputs were cleaned. It was archived outside the Git repository after the verified build and must be restored or synchronized again before rebuilding.

## Trust model

- Source: `https://webrtc.googlesource.com/src`
- Build tooling: `https://chromium.googlesource.com/chromium/tools/depot_tools.git`
- Both source and tooling are pinned by full commit hashes in `VERSION.env`.
- Patch files are versioned and their aggregate SHA-256 is included in release provenance.
- Builds run locally on a controlled macOS machine.
- Release archives include the license generated by Google's build script and a provenance record.
- SwiftPM verifies the release archive with its SHA-256 checksum.

## Build

Requirements:

- macOS with Xcode and Command Line Tools
- At least 60 GB free disk space
- Git and network access to Google's source hosts

Source and tool checkouts are stored outside the repository in `~/Library/Caches/WatermelonWebRTC` by default. Override this with `WATERMELON_WEBRTC_BUILD_ROOT`.

```sh
./scripts/sync.sh
./scripts/build.sh
./scripts/verify.sh
./scripts/package.sh
```

`sync.sh` temporarily removes this repository's known patches, synchronizes the pinned upstream checkout, and reapplies them. It refuses to continue if the patch set no longer matches upstream instead of silently producing a different binary.

The build produces:

- `Artifacts/WebRTC.xcframework`
- `dist/WebRTC-<version>.xcframework.zip`
- `dist/provenance.json`
- a generated `Package.swift` containing the release URL and checksum

The local XCFramework retains dSYMs. The SwiftPM runtime archive excludes them to keep dependency downloads small. Verification also rejects media-class regressions and a device WebRTC executable larger than 3,000,000 bytes.

## Updating

Updates are deliberate. Revert the current patch set, change the pinned commits in `VERSION.env`, rebase and review both patches, rebuild from an empty output directory, run verification, and publish a new immutable GitHub release. Never replace an existing release asset or move an existing tag.

## License

The scripts and package metadata in this repository use the BSD 3-Clause license. Google WebRTC retains its own license and patent grant; the official build embeds the generated third-party license bundle in the XCFramework.
