# Private Jet Charter Tycoon

A source-controlled Roblox vertical-slice candidate based on `PRIVATE_JET_CHARTER_TYCOON_BUILD_SPEC.md`. The first route is fictional Riviera / Monaco, with an original Aster L6 light jet and customizable Aster hangar.

**On a MacBook? Start with [START_HERE_MAC.md](START_HERE_MAC.md).** Ready-to-open `.rbxl` and `.rbxlx` files are included in `build/`; no build tools are needed to open them in Studio.

**Status: local build and offline tests pass; Roblox Studio playtesting is blocked by its login screen.** The user chose to continue locally. This is not a finished V1 or a claim of premium production quality. Do not publish it as a release until the Studio gates below pass.

## Open and play

1. Sign in to Roblox Studio manually.
2. Open **`build/PrivateJetCharterTycoon.rbxl`** with File → Open from File. It includes an edit-mode hangar, aircraft, NPC and Riviera scene. The `.rbxlx` sibling is the smaller source-only Rojo build.
3. Press **Play (F5)**. The preview is replaced by the same production builders, with your own plot. The phone should open. Open Output and watch for `[PJCT] server ready` and `[PJCT] client ready`; report any red errors.
4. Accept an offer. Close the phone and walk to the **Cabin Atelier** counter on the left side of the hangar. Use its proximity prompt, then choose the requested catering and mood.
5. Walk to the port aircraft stair. Use **Board**. After the NPC boards and the cabin secures, use **Start engines** on the phone.
6. **E / Q** increases/decreases throttle. At **72 knots**, hold **↑** to rotate; **↓** descends, **← / →** banks. Reach cruise above 180 ft, then use **P** for autopilot and **C** for cabin mode. Walk to the galley to serve. **F** returns to controls; **G** toggles gear.
7. Autopilot disengages on approach. Follow the altitude guide, align near center, extend gear, and land at **45–88 knots** with less than 12° bank. A bad landing or overrun sends you around safely. The flight model uses a compressed guided route, not a real flight simulator.
8. At arrival, open the phone: arrange the car, baggage, umbrella and photographer decoy. Complete the handover, inspect the score and payout, then return to the hangar.
9. Recruit and assign a team, manually train one supported skill, or buy a hangar upgrade. Complete a second charter. **Studio data is intentionally session-only** and is labelled that way in the UI.

Touch has six large held flight controls plus action buttons. Gamepad uses the left stick and R2/L2, with selectable UI actions. Both input paths are authored but **unverified on devices**.

## Rebuild / sync

Node.js and Git are installed here. Local tools are already downloaded into ignored `tools/` directories: Rojo 7.7.0, Luau 0.740 and Lune 0.10.5. No global installation or Studio plugin is needed to open the build.

From the repository in PowerShell:

```powershell
# Only on a new checkout:
node tools/bootstrap.mjs
Expand-Archive tools/rojo.zip tools/rojo -Force
Expand-Archive tools/luau.zip tools/luau -Force
Expand-Archive tools/lune.zip tools/lune -Force
New-Item -ItemType Directory -Force build | Out-Null

# Compile, type-check pure modules, test rules/services, build and bake:
./tools/check.ps1

# Optional live sync after installing the official Rojo Studio plugin:
./tools/rojo/rojo.exe serve default.project.json
```

Connect the Rojo plugin to localhost port 34872. Source is authoritative; do not overwrite it with edits to the generated preview. World geometry lives in `src/server/World.luau` and is reusable across runtime and the offline bake.

For a local geometry inspector, run `node tools/preview.mjs`, then open `http://127.0.0.1:8765`. It loads the actual exported parts, with orbit, exterior, cabin cutaway and Riviera views. **It is not Roblox rendering**: materials, surface text, lighting and physics differ. It exists to catch proportions, geometry and composition errors while Studio is unavailable.

## What is implemented in source

- Original procedural hangar, lounge, aircraft shell/cockpit/cabin, motors for door and gear, six seats, boarding stair, signage, service stations and coastal destination.
- Phone offers with expiry, server aircraft eligibility and preparation distance checks, scripted client boarding, server flight integration, cruise autopilot, physical cabin service and safe landing recovery.
- Arrival decisions with baggage transfer, umbrella prop, moving photographers and client escort; explicit score categories, payout multiplier, crew bonus and results.
- Up to four crew members, flexible role selection, full individual awards, permanent team recruitment/assignment, salaries, tokens, supported manual skills, cabin badge and two hangar upgrades.
- Shared Roblox UI design, touch/keyboard/gamepad paths, captions, short skippable camera beats, quality/motion/volume preferences, original audio layers and controlled exhaust.
- Server-owned inventory and economy, bounded/rate-limited remotes, per-user action locks, versioned profiles, session leases, transactional mutations, durable reward IDs and fail-closed receipt handling.

## Audio setup

Nine original, synthesized WAVs are in `assets/audio`. Regenerate with `node tools/audio.mjs`. Upload them through Roblox Asset Manager under the experience's owner, grant the experience access, and set the returned `rbxassetid://…` IDs in `src/shared/AudioCatalog.luau`. IDs are empty, so these custom sounds are **silent until configured**. Captions still communicate essential cues. Listen and mix them in Studio before accepting the audio gate; these are authored first-pass sound assets, not recordings of real aircraft.

## Persistence and commerce configuration

Production servers use `PJCT_Profile_v1` through `UpdateAsync`. Studio intentionally bypasses live data stores, even when API access is enabled. To verify durable data, publish to a private **test experience**, join through the Roblox client, complete a charter, leave, and rejoin. Never point development failure tests at real player data.

Profile mutations must commit before the UI confirms them. Reward-save failure leaves results open with **Retry reward save**. A host cannot return while a crewmate's result is unsaved. Session leases expire after 180 seconds and renew every 50 seconds. Unavailable or future-schema saves are never replaced with defaults. Successful rewards survive reconnects; progress before completing a charter is not resumable yet. An outage combined with server termination before any reward commit remains a release risk.

Robux IDs are **0**, paid controls are disabled, and `ProcessReceipt` returns `NotProcessedYet`. Premium/full-pass fulfillment is intentionally not implemented. Enabling purchases requires an audited durable receipt flow, real product configuration and sandbox purchase tests. No paid success is simulated.

## Required acceptance gates

See [TEST_REPORT.md](docs/TEST_REPORT.md) for evidence and [MILESTONES.md](docs/MILESTONES.md) for remaining scope. Immediate next work is a Studio solo playtest, specifically model welding, avatar movement in the cabin, mobile UI, geometry collisions, streamed destination arrival and saving in a private test universe. The broader fleet, three remaining launch destinations, social visit permissions, leaderboards and five-week pass follow the first slice's engine acceptance.

Sources for the pinned build workflow: [Rojo releases](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0), [Luau releases](https://github.com/luau-lang/luau/releases/tag/0.740), [Lune Roblox authoring API](https://lune-org.github.io/docs/api-reference/roblox/). Asset provenance is in [ASSETS.md](docs/ASSETS.md).
