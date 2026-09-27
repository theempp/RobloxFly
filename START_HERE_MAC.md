# Open RobloxFly on your MacBook

This folder contains the Roblox Studio game, its complete source, the design specification, original audio, and build/test records. You do not need Windows, Rojo, Node.js, or a Studio plugin just to open and play the supplied place.

1. Download this repository using **Code → Download ZIP**, or [download the main-branch ZIP](https://github.com/theempp/RobloxFly/archive/refs/heads/main.zip).
2. Unzip it on your Mac. Move the extracted folder to your **Desktop** and name it **RobloxFly**.
3. Open Roblox Studio, which should already be signed in on your MacBook.
4. Choose **File → Open from File…** and select **Desktop/RobloxFly/build/PrivateJetCharterTycoon.rbxl**. You can also try double-clicking that file in Finder.
5. The hangar and aircraft are included in the edit-mode preview. Press Studio's **Play** button. On a Mac, the F5 shortcut may require **Fn + F5** depending on your keyboard settings.
6. Follow the solo charter walkthrough in **README.md → Open and play**. Keep Studio's **Output** panel visible for errors.

## Folder guide

| Location | What it contains |
|---|---|
| `build/PrivateJetCharterTycoon.rbxl` | Open this game in Studio; includes the edit-mode scene and game scripts |
| `build/PrivateJetCharterTycoon.rbxlx` | Source-only XML place; runtime builders create the world when played |
| `README.md` | Detailed gameplay controls, setup, persistence and audio instructions |
| `PRIVATE_JET_CHARTER_TYCOON_BUILD_SPEC.md` | The authoritative full game specification |
| `docs/ART_DIRECTION.md` | Visual identity, materials, cameras and performance targets |
| `docs/MILESTONES.md` | Implemented scope and remaining production gates |
| `docs/TEST_REPORT.md` | What local tests cover and the Studio playtest checklist |
| `docs/DECISIONS.md` | Consequential implementation decisions |
| `docs/ASSETS.md` | Original asset provenance and missing/configurable media |
| `docs/BUILD_MANIFEST.json` | SHA-256 fingerprints of the supplied game files |
| `src/shared`, `src/server`, `src/client` | Editable Luau configuration, gameplay services and interface code |
| `assets/audio` | Nine original WAV layers for uploading under your Roblox experience |
| `tests` | Offline domain, flight and service integration tests |
| `tools` | Reproducible build, original audio synthesis and geometry review scripts |

## Before publishing

This is the **first charter candidate, not a finished release**. Forty-one local tests pass, but Roblox Studio gameplay has not yet been tested. Confirm that the jet, boarding, moving cabin, controls and arrival work on your Mac before publishing.

Studio progress is **session-only by design**. Audio IDs are empty until you upload the WAVs and configure `src/shared/AudioCatalog.luau`. Robux purchases are disabled. The larger fleet, remaining destinations, leaderboards and season pass are still future milestones. Full details are in `docs/MILESTONES.md`.

## Continuing development on macOS

The Luau source and place files are cross-platform. The existing `tools/check.ps1` wrapper and `tools/bootstrap.mjs` binary downloads target Windows. To rebuild on macOS, install the macOS builds of **Rojo 7.7.0**, **Luau 0.740** and **Lune 0.10.5** from their official releases, then run from this folder:

```sh
luau tests/domain.luau
rojo build default.project.json -o build/PrivateJetCharterTycoon.rbxlx
lune run tests/services.luau
lune run tools/bake.luau
```

For live sync, install the official Rojo plugin in Studio and run `rojo serve default.project.json`. Source is authoritative; edits made only to the generated place do not automatically update the repository.
