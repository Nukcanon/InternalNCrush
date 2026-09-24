# Official Godot WebRTC extension

Unmodified binary dependency: godotengine/webrtc-native 1.2.1-stable. Source: https://github.com/godotengine/webrtc-native/tree/1.2.1-stable

Download: https://github.com/godotengine/webrtc-native/releases/download/1.2.1-stable/godot-extension-webrtc_native.zip

Archive SHA-256: `f37d03da03da3ff0d092542a04586644f889135cb7a1c3566ad57513203a553b`.

`game/tools/prepare_webrtc.py` downloads and verifies the archive before extracting Windows/Linux x86-64 release/debug libraries. It does not run at game startup. `.gdextension` is restricted to those targets; browsers use their native WebRTC implementation. All seven upstream `LICENSE.*` notices are preserved and included in the Windows ZIP. libdatachannel is MPL-2.0, with corresponding source available through the linked upstream release and its pinned submodules. No library source modifications are made.
