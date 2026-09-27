# Aster Aviation / first charter

The signature is a champagne taxi line extending from a monumental hangar through the concourse and into the phone's route diagram. Broad architectural light frames the aircraft; no neon machinery.

| Token | Value | Use |
|---|---|---|
| Porcelain | #EEECE5 | fuselage, primary type |
| Graphite | #17232A | structural steel, interface |
| Champagne | #CEB784 | wayfinding, focus, trim |
| Limestone | #ABA69A | hangar floor |
| Lagoon | #66B5C4 | horizon, route cues |
| Walnut | #614739 | cabinetry |

Display: Gotham Bold, limited to aircraft and destination names. Body: Gotham Medium. Instruments: Roboto Mono. Phone contracts use a route line with airport identifiers, expiry and advertised fee. Large 48-pixel actions; status uses words and symbols as well as color. HUD clears the center sightline.

Aircraft length 58 studs, span 60; approximately 1 stud = 0.28 m, with wider cabin clearances for Roblox avatars. Six seats, club tables, overhead light coves, port door and stair, twin aft nacelles, swept wing, T tail, cockpit glazing and instruments. All visual assets are original procedural parts; not photorealistic or licensed aircraft replicas.

Quality tiers reduce local lights, particles and shadows. Initial budgets (targets, not measured device results): <2,500 scene parts per operational plot; <650 aircraft parts plus bounded NPC rigs; 30 server simulation steps/s; <=10 input packets/s/player; <=4 HUD snapshots/s/player; <=48 live particles/aircraft; 33 ms mobile frame target. The aircraft allowance increased to close the original tapered surfaces without an external mesh upload. Profile on real devices before setting launch limits.

Camera beats: reveal 3 seconds, boarding 2, takeoff 1.4, approach 1.4, arrival 2, results 2. Skip always visible, any flight input cancels, reduced motion disables them. Never let a cinematic control the server flight state.

Audio is authored locally as original synthesized WAV layers. Roblox cannot play local WAV paths: upload under the experience owner and put approved IDs in AudioCatalog. Caption cues remain functional with unconfigured IDs. Custom motion uses code-driven rig transforms; animation assets are a documented future replacement, not a dependency.
