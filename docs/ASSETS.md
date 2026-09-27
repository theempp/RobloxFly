# Asset provenance and configuration

| Asset | Origin | Runtime status |
|---|---|---|
| Hangar, Aster L6, cabin furniture, ground props, original NPCs, Riviera scene | Original procedural Luau geometry in `World.luau` | Included; needs Studio visual/physics approval |
| Concierge interface, typography layout, signage | Original code; Roblox built-in fonts | Included; device verification pending |
| Walk cycle, seated pose, door/gear, service tray, baggage and escort | Original procedural transforms and motors | Included; motion review pending |
| Hangar, turbine, wind, phone, door, gear, service, touchdown, results WAVs | Original deterministic synthesis in `tools/audio.mjs`; no third-party samples | Files included; Roblox upload/permissions and final mix required |
| Exhaust smoke texture | Roblox built-in `rbxasset://textures/particles/smoke_main.dds` | Referenced locally by the Roblox engine |
| Materials and reflections | Roblox built-in materials and Lighting | High/low controls authored; no device profile yet |
| Three.js 0.180.0 | MIT, [upstream](https://github.com/mrdoob/three.js/tree/r180), downloaded with license by bootstrap | Local asset inspector only; never shipped as Roblox runtime code |

No real jet branding, real celebrity likenesses, marketplace model scripts, commissioned assets, generated image costs, paid assets, or externally uploaded files were used.

Known sensory gaps: no custom imported avatar animation clips, voice/radio recordings, lounge music, weather variation, animated aircraft control surfaces, touchdown smoke or runway spray yet. Paparazzi have props and movement but their timed flash effect is still pending. Cockpit screens are static instruments; the live HUD supplies authoritative telemetry. Window glazing and cabin lighting need engine review, and the model has a deliberately stylized faceted silhouette.
