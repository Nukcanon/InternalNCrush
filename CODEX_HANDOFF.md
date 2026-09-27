# Internal N Crush 1.2.3 recovery handoff

Resume only the fetched 1.2.2 baseline `fb6c32aafc1bb5a5467ae45346fa87fe51e05472` and branch `work/v1.2.3-stability-20260927`. Recovery base `da2424b`, first continuation checkpoint `b4efed1`. Do not restore old 1.1.x game or website files.

Native and Web use the same rules/network contract but separate baked graphics. Native preserves detailed anatomy/materials; Web staging uses CartoonModel and reduced assets. Never copy lightweight assets back to `game/`. Menu photographs are unchanged approved 1.2.2 build artifacts, not newly invented replacement images.

Read `WORK_V123.md`, `RELEASE_NOTES_V123.md` and `VALIDATION_V123.md` for acceptance and test evidence. Current runtime changes implement the recovered requirements; publication remains 1.2.2 while final release gates run. The 1.2.3 source version is a candidate, not proof of publication.

Local functional regressions, native rendering, browser repeated-play, ENet gameplay/rotation/reconnect and WebRTC loopback passed. Native and Web resource counts stay bounded during measured sessions. Godot 4.4.1 reports native texture warnings / Web allocator warning during fixture shutdown; these are recorded, not hidden. Low-end/mobile FPS, many-hour play and external WAN/NAT remain unverified. Do not promise crash-free or AAA visual quality.

Next: final candidate CI, packaged Windows execution, Web rendered repeat test, exact-source Windows/Web/NAS release and website installer. Fetch both remotes before publication, preserve concurrent changes, verify source SHA and archive/file hashes. Root publication status must be updated with actual successful run IDs and assets after release.

Female operators are SERA (role 1) and MINA (role 5). Chin/hair and thumbnails changed; compare `validation/v123/` native/Web captures. Character appearance remains stylized and is not a photorealistic copy of the supplied portrait.
