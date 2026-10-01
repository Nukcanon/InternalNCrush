# Internal N Crush sound credits

## 1.2.6 female announcer replacement

The former Microsoft Zira/SAPI victory and bomb phrases described in the historical notes below have been replaced. Eleven English cues (Blue/Orange victory, bomb planted/dropped/defused, and each team's capture of A/B/C) are synthesized offline with **hexgrad Kokoro-82M v1.0**, stock female voice `af_heart`, speed 1.04. Model and voice source: https://huggingface.co/hexgrad/Kokoro-82M (Apache-2.0); inference conversion: https://github.com/thewh1teagle/kokoro-onnx . License text is retained at `assets/AUDIO_KOKORO_LICENSE.txt`.

`tools/build_announcer.py` documents resampling, level matching, peak limiting and silence padding. `tools/announcer/provenance.json` records phrases and WAV hashes. These are synthetic voices, not a human performance or an imitation of a particular game actor. Only the generated recordings ship; no neural model, inference library, network voice service or inference workload is included in either game build. The final mix uses a dedicated announcement player, a bounded sequential queue and +10 dB cue gain through the game's existing limiter.

Build sources, including `tools/audio_source.zip` (mono 44.1 kHz PCM) and the editing script, are available at https://github.com/Nukcanon/nukcanon/tree/internal-n-crush-v0.6.0/games/relaystrike. Development source files are not bundled with the playable ZIP. `tools/build_audio.py` documents the complete edits: trimming, pitch/resampling, filtering, layering, short early reflections, fades, and gain staging. No audio from Metal Slug, Call of Duty, Counter-Strike, or VALORANT is included.

- **Q009 — Q009's weapon sounds.** https://opengameart.org/content/q009s-weapon-sounds (pack uploaded by Calinou). License: Creative Commons Attribution-ShareAlike 3.0 Unported, https://creativecommons.org/licenses/by-sa/3.0/. Source files prefixed `q_` derive from this pack. All `assets/audio/gun_*.wav` are adaptations of Q009's sounds, mixed and edited for Internal N Crush, and are distributed under **CC BY-SA 3.0**. The original license text is retained in `assets/AUDIO_Q009_LICENSE.txt`. This license applies to those sound assets, independently of the MIT game code.
- **Kenney — Impact Sounds; Interface Sounds.** https://kenney.nl/assets/impact-sounds and https://kenney.nl/assets/interface-sounds. CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/. Concrete and grass footsteps, mechanical/metal/glass/soft impacts and short interface cues are used and edited. Original notice: `assets/AUDIO_KENNEY_LICENSE.txt`.
- **rubberduck — 25 CC0 bang / firework SFX.** https://opengameart.org/content/25-cc0-bang-firework-sfx. CC0 1.0. Recorded fireworks/bangs are used as low-frequency layers, explosions and deployment tails. Sources: `cannon_01`, `bang_03`, `shot_01`, `fw_02`.

Non-Q009-derived mixed audio is offered under CC0 1.0 unless a different license is explicitly identified below. The per-file license is also recorded in `assets/audio_manifest.json`. The authors do not endorse this game. No DRM or additional restrictions are applied to these assets.

0.7.0: `hurt` and `armor_hurt` use deterministic low-mid synthesis plus the credited CC0 impact/cloth sources. `kill_sting` is original deterministic synthesis (CC0-1.0). See tools/build_audio.py for reproducible recipes.

## 1.4.5 reload and wrench foley

- zer0_sol — Handgun Reload Sound Effect, `reload.wav`, https://opengameart.org/content/handgun-reload-sound-effect, CC0 1.0. Excerpts at 0.06–0.42 s (magazine catch and drop) and 0.54–0.92 s (fresh magazine seated), stereo folded to mono 44.1 kHz PCM and normalized: `tools/foley/mag_release_z.wav`, `mag_insert_z.wav` → `assets/audio/reload.wav` (magazine out) and `magazine.wav` (seated), with a faint lowpassed metal layer.
- BMacZero (Brian MacIntosh) — Gun Reload Sound Effects, `clipload1.wav`, https://opengameart.org/content/gun-reload-sound-effects, CC0 1.0. Kept as `tools/foley/clipload1_b.wav` (not yet mixed).
- rubberduck — 100 CC0 Metal and Wood SFX, https://opengameart.org/content/100-cc0-metal-and-wood-sfx, CC0 1.0. `misc_03`, `metal_slam_01`, `metal_hit_03`, `metal_sheet_06`, `metal_close_01` resampled from 48 kHz to mono 44.1 kHz PCM (`tools/foley/rd_*.wav`): the rocket sliding down its tube and seating (`rocket_insert.wav`), and the wrench clang on a turret (`wrench_repair.wav`).

## Bomb announcements (1.1.1)

Three short English announcements were synthesized locally using Windows SAPI / Microsoft Zira Desktop. The generated WAV recordings are stored in `tools/announcer` for reproducible builds; no voice engine or voice model is redistributed. They are not recordings from another game. Defusing uses the existing credited CC0 metal/tool samples.

## 1.2.2 combat foley

- EZduzziteh — Hurt Sound Effects, `hurt_01.mp3`, https://opengameart.org/content/hurt-sound-effects, CC0. Converted to mono 44.1 kHz PCM and normalized; male hurt and armored-hurt cues.
- AuraVoice / Nocturnal_Vanguard — Female Hurt Grunts & Groans, https://opengameart.org/content/female-hurt-grunts-groans, CC0. Short excerpt at 3.70–4.19 seconds, converted to mono PCM; female hurt cues.
- Mike Koenig — Loading Shotgun, https://soundbible.com/1403-Loading-Shotgun.html, Creative Commons Attribution 3.0 (https://creativecommons.org/licenses/by/3.0/). Excerpts at 2.58–3.43 and 8.24–9.29 seconds, mono conversion, normalization, pitch adjustment and metal latch layering for shell insertion / action rack. `shell_insert.wav` and `bolt.wav`, plus the corresponding source excerpts in `tools/foley`, remain CC BY 3.0.

Magazine, movement, melee and explosive cues use the previously credited CC0 recordings plus original noise envelopes. Gunfire mixes are unchanged.

## 1.2.3 foley and announcements

The old original melee noise envelope is reused for equip/deploy. A lower filtered
envelope supplies the new swing; throw, heavy metal bounce and clear UI taps use
the CC0 sources above. Flash/smoke use the exact grenade blast PCM and gain.
Blue/Orange team victory phrases are locally generated Microsoft Zira Desktop
SAPI speech, with the same provenance as the bomb announcements. No game audio
or voice engine is redistributed. Existing gun recipes and source ordering stay
unchanged; DUET is appended as a new weapon.

## 1.2.4 contact separation

Wrench repair uses high-passed Kenney plate/metal recordings for a bright ringing strike. Wrench wall/body impacts use the existing dry low-mid impact/cloth layers; knife body contact uses a shorter soft-impact mix, and knife wall contact retains the clear metal layer. All five mixes are CC0-1.0, reproduced by `tools/build_audio.py`. Contact feedback is local to the striking player.

## Combat audio refresh (work in progress)

Shotgun shell/rack recordings: zer0_sol, Shotgun Reload Sound effects, https://opengameart.org/content/shotgun-reload-sound-effects (CC0). Source archive retained at tools/foley/new_sources/shotgunsounds.zip. Converted to mono 44.1 kHz PCM, trimmed and filtered; no pitch-to-speech or TTS. Native per-weapon Q009 adaptations retain CC BY-SA 3.0. combat_audio_refresh.py records all transformations. New propulsion/vent/hinge textures are original CC0 procedural sound designs, not claimed to be field recordings.

## 1.4.2 hit marker, melee and slide

- **Kenney — RPG Audio; Impact Sounds.** https://kenney.nl/assets/rpg-audio and https://kenney.nl/assets/impact-sounds. CC0 1.0 (same notice as `assets/AUDIO_KENNEY_LICENSE.txt`). The source OGGs used are kept as mono 44.1 kHz PCM in `tools/foley/k_*.wav`: knife slices, chop, knife draw, cloth, metal pot/click, metal/tin/wood/soft/punch impacts and a concrete footstep.

`hit`, `confirm`, `knife_swing`, `wrench_swing`, `knife_flesh`, `knife_wall`, `wrench_flesh`, `wrench_repair`, `wrench_wall` and `slide` are rebuilt from those recordings plus generated air/friction noise (trimming, filtering, fades and layering in `tools/combat_audio_refresh.py`). The hit marker is now a short unpitched tap instead of a ringing tone. All ten mixes are CC0-1.0.

## Optional vocal gunfire

Generated with ElevenLabs Sound Effects (https://elevenlabs.io/), not TTS.
The user supplied and selected candidate 4 from the first session for the pistol,
and `American_woman_yelli_#3-1790581855008.mp3` for the other categories.
The louder `American_woman_shout_#1` take was rejected and is not shipped.
Edits: separate utterances, mono conversion, short edge fades, gain adjustment,
44.1 kHz resampling; no pitch or voice-identity alteration. ARC/LINK reuse the
machine-gun utterance. See `assets/vocal_audio_provenance.json` for hashes/cuts.
These are provider-licensed samples, not CC0. Free-plan generation is subject
to ElevenLabs attribution and noncommercial-use terms; this record does not
grant commercial rights. The optional setting is off by default.
