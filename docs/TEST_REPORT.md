# Local verification — 2026-09-27

The `tools/check.ps1` pipeline compiles every Luau source file, type-checks the four pure shared rule modules, runs the tests below, builds with Rojo, executes the production World module in Lune, checks geometry budgets and serializes a Studio-openable place.

**24 domain/flight tests** cover profile isolation/migration, invalid saves, tail namespace uniqueness, reward deduplication and bounds, real catalog prices, token training and limits, effective crew tuning, salary/day behavior and free recovery crews, score floors/caps, malformed remote payloads, flight input bounds, rotation speed, runway overruns, autopilot disengagement, gear-up recovery and a full simulated departure/cruise/approach/landing.

**17 server integration tests** execute the real Profiles, Charters, World and shared modules with a deterministic clock, Lune data-model instances, simulated player connections, immediate tween endpoints and an in-memory replacement for DataStore transport. They cover exclusive save leases, injected storage failure, forged/expired offers, duplicate acceptance, join/role flow, preparation distance, host-only boarding, departure restrictions, autopilot/cabin access, single-use manual service, landing-to-arrival transition, required car/baggage, handover, failed reward commit/retry, host return protection, full co-op awards, recruit/assign/train, release and reload.

These tests do **not** prove Roblox replication, character physics, UI rendering, audio permissions, real DataStore availability, human flight feel or multiplayer device performance. No live Roblox server, published experience or purchase was used.

The production geometry bake includes an edit-mode preview that is removed and regenerated on Play. Counts: 1,180 scene BaseParts, 563 jet BaseParts, 10 PointLights and five proximity prompts. Limits: fewer than 2,500 scene parts and 650 aircraft parts. These are authored scene budgets, not measured draw calls or frame rates. The aircraft budget increased from the initial 500-part target to close tapered surfaces with original wedge geometry without requiring an external mesh upload.

The offline Three.js inspector displayed the same exported geometry. Review caught and corrected a blocked reveal camera, detached nose shape, tapered-panel gaps and excess zero-range lights. It does not render Roblox SurfaceGui text or match the engine's materials/lighting.

## Studio playtest checklist — NOT RUN

1. Open `.rbxl`, confirm edit preview, Play, check Output and player spawn.
2. Accept → physical prep → board: confirm cabin clearances, moving door/stair and NPC seating.
3. Fly departure, engage autopilot, leave controls and walk to the galley while the aircraft moves; serve a request; return to controls. Check stability and control capture.
4. Fly an acceptable landing, intentionally attempt gear-up/off-center/too-fast landings, and verify each recovery remains playable.
5. Check streamed approach/runway visibility and arrival taxi reposition. Arrange car/baggage/umbrella/decoy, watch escort, inspect every score row and reward.
6. Return, recruit/assign/train, upgrade a finish/facility, repeat. Confirm each purchase only charges once and animations/UI remain responsive.
7. Test Start Server with 2–4 players: concurrent accept/join, duplicate buttons, host-only actions, roles, full payouts, guest return, respawn and owner disconnect. A departing owner currently cancels an unfinished charter; live run resume is not implemented.
8. Phone and tablet portrait/landscape: no HUD covering the open phone, no clipped touch controls, no stuck input after focus loss. Test a physical gamepad and GUI selection.
9. Upload audio; check permissions, spatial falloff, mixes, captions, mute and reduced motion. Verify skip during every cinematic and immediate cancel on flight input.
10. Private test universe: complete/rejoin to confirm durable progress; verify denial during profile lease contention; inject controlled transport failures only in test tooling.
11. Profile actual hardware: mobile frame time target 33 ms; capture memory, draw calls, physics and network stats. Compare quality modes, four crews and destination streaming. Reduce collision/mesh complexity if required.

## Blocking condition

Roblox Studio is installed and was running, but its editor was behind the login screen. The user explicitly chose local builds for now. No authentication was automated. Engine and release gates remain pending.
