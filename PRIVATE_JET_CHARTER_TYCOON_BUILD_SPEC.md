# Private Jet Charter Tycoon — V1 Build Specification

## 1. Product decision

Build a Roblox multiplayer private jet charter game. The player's luxury hangar and jet collection are the long-term progression and social display. The repeatable game is accepting a client contract, preparing and flying a short charter, meeting client needs, managing arrival discretion, and earning a satisfaction rating and payout.

This document is the authoritative V1 design. The earlier idea notes are background only where they differ from this specification. Numerical values below are starting balance targets and should be data driven.

### Design pillars

1. A complete, rewarding solo flight; better coordination with friends.
2. Active flying and service, rather than idle cash generation.
3. Exceptional visual and sensory quality from the first playable build: believable aviation, cinematic luxury, expressive animation, and carefully mixed sound.
4. Crew teams, jets, and hangars worth collecting and displaying.
5. Clear purchases and a viable free progression path.

### Quality bar and production priority

The ambition is to create a standout, highly played Roblox game; no design document can guarantee a player count. Prioritize a small, visually memorable experience that players want to repeat and share. The **first playable build must already look and feel premium**. Do not defer all art, lighting, animation, effects, audio, and camera work until after every system exists. Build one complete, polished charter first, then extend its reusable quality standard to additional destinations, jets, and systems. Avoid spending time or credits on broad, low-quality scaffolding that will be discarded.

## 2. Player journey and core loop

1. Spawn in the player's customizable luxury hangar. See the active jet, assigned teams, phone, contracts, and nearby visitors.
2. The phone rings with three contract offers. Each shows client profile, destination, required seats and range, payout, expected flight time, difficulty, and expiry. Declined or expired offers refresh. Never force a purchase to receive a playable offer.
3. Accept a contract. Set catering and cabin preferences, select a suitable jet, assign owned pilot, cabin, and security teams, and invite or queue players for a 1–4 person crew.
4. Board. Players claim soft roles: Captain, First Officer, Cabin Host, and Ground/Security. Anyone may assist outside their role. Empty roles use assigned NPC teams. The owner can fly as Captain regardless of an assigned pilot team.
5. Taxi/take off, cruise, respond to live NPC client requests, descend, and land. Cruise autopilot lets a solo player leave the controls and handle cabin tasks; it disengages for approach and landing.
6. Complete an arrival discretion encounter: select car placement, manage baggage and umbrellas, and steer paparazzi away from the client.
7. Show an understandable score breakdown and rewards. Return to the hangar with currency, account/role XP, crew progress, and reputation.

Target one charter at about 8 minutes from boarding to result, with short loading and no realistic long-haul wait. Destinations at launch: Monaco, Dubai, an alpine ski town, and New York. Tokyo is reserved for Season One content after launch and is not required for the first playable release.

## 3. Flight and scoring

Flight controls must work on desktop, mobile, and gamepad. Use approachable, arcade-leaning physics with visible speed, altitude, route marker, and landing guidance. Players must be able to make meaningful takeoff and landing errors without one small mistake ending the run. Provide a safe recovery or go-around option.

Score the flight out of 100 with an on-screen breakdown: smoothness 25, timing 20, cabin service 25, arrival/discretion 20, safety 10. Server-authoritative events determine the score. Examples: excessive bank or abrupt acceleration reduce smoothness; missed requests reduce service; exposed client path reduces discretion. Define clear floors and caps so a single minor error cannot erase the whole payout. Payout = advertised base fee times a rating multiplier, with any co-op bonus shown before boarding. No idle income or dropper conveyor.

The client is a live NPC in the cabin with a limited, readable set of mid-flight requests and a mood indicator. Client archetypes vary in patience, service preferences, time sensitivity, and discretion needs. Use fictional names and identities; no real celebrity likenesses.

## 4. Crew roles, solo play, and rewards

| Role | Primary responsibility | Examples |
| --- | --- | --- |
| Captain | Flight controls | Takeoff, route, landing, go-around |
| First Officer | Assist the flight | Checklist, radio calls, navigation, landing assist |
| Cabin Host | Client experience | Catering, request timing, cabin mood |
| Ground/Security | Arrival discretion | Vehicle, bags, umbrellas, paparazzi route |

Roles are optional assignments, not hard locks. A solo player can finish all normal contracts with NPC teams and cruise autopilot. NPC performance is competent but does not automatically produce perfect ratings. A real crew can earn a modest 10% cooperative payout bonus; do not make multiplayer mandatory.

All participating players receive the full personal currency and XP award. The jet owner gets jet and hangar ownership progress. Give separate role XP and cosmetic milestones, plus an account level. Rewards are granted once per completed run using server-side run IDs. Disconnect handling should preserve earned progress without duplicate payouts.

## 5. Recruitable teams and development

Players recruit persistent **teams**, not individual workers. Launch categories: Pilot Team, Cabin Team, Security Team. Each team has a name, rarity/grade, starting overall rating, role-specific skill ratings, salary, visual identity, and badge slots. Players may own multiple teams per category and swap assigned teams before a charter.

- Pilot skill categories: takeoff, cruise handling, navigation, landing, and safety.
- Cabin skill categories: service speed, client reading, catering, and composure.
- Security skill categories: discretion, crowd control, logistics, and response.
- Overall is a transparent weighted summary of category ratings, not a separate hidden power value.
- Recruiting a team is a one-time purchase with **earned or purchased in-game credits**. Only currently assigned teams draw a salary, charged once per in-game day. Bench teams cost nothing. Show salary before assignment and prevent a negative balance from silently accruing.
- Players manually allocate earned training tokens and spend credits to raise a selected skill, within tier caps. A badge unlocks after explicit mastery milestones, then can be purchased with credits if the player chooses. Badges grant narrow, clearly described benefits; equip limits prevent stacking every benefit.
- Skills and badges stay with that team when it is benched or reassigned. Recruited teams do not expire. V1 has no fixed-term contracts.
- A daily recruitment board shows direct, guaranteed offers with displayed skills and prices. The roster and store must remain usable even if a player never spends Robux.

## 6. Jets and destinations

Launch with three main classes: light, midsize, and large cabin. All jets expose passenger capacity, fuel capacity, range, handling, and cabin comfort. Higher classes open contracts with more passengers, longer routes, and greater payouts. Upgrades can improve the jet within bounded class limits; they do not erase the reason to collect a higher class.

Start with one light jet. Unlock standard jets through account reputation and credits. The five-week Season One pass offers a distinct, functional jet at a high tier. It is above the starter in capacity, fuel, and range, but is not the best endgame jet and does not guarantee a high rating. Buying the complete season pass grants that jet immediately as part of unlocking all tiers. It remains owned after the season. Serialized jets awarded for leaderboard performance remain a separate prestige reward and cannot be bought through the pass.

V1 can use short, separate destination scenes and a guided route rather than a single geographically realistic world. Each destination needs a recognizable skyline or terrain, runway, arrival area, and time-of-day or weather variation. Use fictional airport and client branding where needed.

## 7. Hangar and social layer

The hangar starts as a clean, customizable base. Use two independent upgrade tracks:

**Operations:** additional jet bays and storage, crew training facilities, recruitment board quality/refresh, and service line quality for catering and supplies. Capacity upgrades should support collection without requiring simultaneous multi-flight simulation in V1.

**Showpiece:** flooring, wall finishes, lighting, lounge, signage, jet display positions, trophies, and seasonal decor. These change appearance and social prestige; they do not secretly raise charter scores.

Friends can visit a player's hangar, walk around jets, inspect visible tail numbers and trophies, and join a charter queue. Owners control guest permissions. Tail numbers must be unique within the game's namespace, filtered for Roblox text rules, and safely fall back to a generated number. A visitor cannot alter another player's inventory or hangar.

## 8. Economy, store, and season

**Credits** are earned from charters and may also be purchased with Robux through repeatable purchases. They buy jets, teams, upgrades, badges, and cosmetics. **Training tokens** are earned through play and used for manual crew skill allocation. Do not sell training tokens directly in V1. **Reputation** comes from completed charters and quality milestones, not purchases.

The daily rotating store offers guaranteed, fully visible teams, cosmetics, upgrades, and badges. Show the exact item, stats, price, and refresh time before purchase. Avoid paid random boxes, paid spins, and undisclosed odds. Players can still obtain essential progression through standard shops and earned credits when an item is out of rotation.

Season One lasts **five weeks**. It has free and premium tracks, with pass XP from charter completion and varied crew-role objectives. Rewards include credits, liveries, uniforms, hangar pieces, badges, and a high-tier functional jet. Sell a premium-track unlock and a separate complete-pass purchase that immediately claims every tier, including the jet. Show all rewards and both prices clearly. The season jet persists. Do not sell leaderboard placement or serialized leaderboard jets.

Weekly leaderboards rank charter satisfaction, with a minimum qualifying run count and anti-abuse limits. Design the metric to reward sustained quality rather than one lucky run; use an average of each player's best qualifying runs with a minimum run count. At season end, award serialized cosmetic/prestige jets to top eligible players. Publish exact ranking and tie rules in game.

Use placeholder Robux product IDs and disabled purchase buttons until real Roblox products are configured. Never simulate a successful paid purchase in production. All purchases and rewards require server-side validation and durable receipt handling.

## 9. Visual and audio direction

Blend **realistic luxury aviation** with **stylized cinematic luxury**. Jets should have believable proportions and readable aviation features; the world can simplify scale and detail for performance and legibility. Use broad forms, polished materials, warm interior lighting, controlled reflections, and dramatic but clear destination lighting. Avoid generic neon tycoon machinery.

The hangar default is neutral and customizable. Suggested base palette: warm white, graphite, brushed metal, and subtle champagne accents; offer brighter and darker player-selected themes. UI should feel like a premium aviation concierge app: clear contract cards, crisp typography, restrained gold accents, large touch targets, and strong contrast. Distinguish role interactions at a glance. Provide a cinematic arrival and result moment without slowing repeat play; allow skips.

Use original or properly licensed assets. Establish a fallback with simple blockout models, procedural signage, placeholder audio, and built-in materials so the game remains playable without external art. Avoid copying a real brand's marks or 2K's exact badge art/UI.

### 9.1 Art direction and environmental detail

The visual target is an ultra-modern luxury aviation fantasy rendered within Roblox's practical limits. Aim for convincing materials, proportions, composition, and atmosphere rather than photorealistic claims. The first hangar should feel like a real high-end aviation space: monumental doors, structural steel, polished concrete or stone, accurate scale cues, floor guidance markings, maintenance details, glass lounge, discreet signage, and a featured aircraft. Give players clear sightlines to their jet. Let upgrades visibly transform the space rather than only changing a menu value.

Jets need distinct exterior silhouettes, moving control surfaces where practical, landing gear states, wing and cabin lighting, readable doors and boarding points, convincing cockpit instrumentation, and a detailed but performant passenger cabin. Each class should visibly express its range and capacity. Keep interactable surfaces obvious without floating clutter. Destination scenes need strong art direction: Monaco's waterfront luxury, Dubai's monumental modern skyline, an alpine town's cold mountains and warm chalet arrival, and New York's dense urban approach. These are stylized fictionalized scenes, not promises of exact real-world airport replicas.

Use a coherent material library, physically plausible light sources, restrained post-processing, weather and time-of-day variants, and deliberate color grading. Maintain visual clarity for runway markings, route cues, clients, and interaction targets. Implement scalable quality settings so lower-end mobile devices retain readable silhouettes and stable play even when high-end effects are reduced.

### 9.2 Animation and character performance

Animate the entire charter ritual: contract phone interaction, crew boarding, door and stairs operation, baggage handling, catering placement, client greeting and seating, safety preparation, takeoff and landing gear, cabin request responses, and discreet arrival escort. Use short, responsive animations that preserve control. The client should show mood through posture, facial expression where feasible, and reaction timing. Crew should look purposeful rather than standing idle. Blend transitions and avoid repeated robotic loops. Provide a clear fallback when a custom animation asset is unavailable.

### 9.3 VFX and camera language

Use subtle, layered effects: ramp heat haze where feasible, engine startup exhaust, taxi and landing lights, wheel touchdown smoke, light runway spray in wet weather, cabin lighting transitions, window atmosphere, camera shake calibrated to turbulence, phone and rating highlights, and restrained paparazzi flashes. Effects must support gameplay and never hide landing guidance or accessibility cues.

Create short, skippable cinematic beats for the phone offer, hangar reveal, client boarding, engine startup, takeoff, destination approach, arrival, and results. Use purposeful camera paths, depth, framing, and transitions. The player's inputs must remain responsive; a cutscene cannot trap a player or delay repeat flights. First-time moments may be longer; repeat moments should be shortened or skipped by preference.

### 9.4 Sound and music

Build a layered soundscape: hangar room tone and distant equipment, footsteps by surface, phone vibration and ringtone, jet doors and switches, turbine spool and thrust, wind and cabin air, landing gear, runway contact, seatbelt and service cues, radio/checklist calls, restrained crowd and paparazzi sounds, and results feedback. Use spatial audio and distance falloff where appropriate, with separate mixes for cockpit, cabin, hangar, and exterior. Music should shift between luxury lounge, flight tension, and arrival payoff without masking speech or critical cues. Include volume controls, captions for essential cues, and a consistent sonic identity. Use original or licensed audio only.

### 9.5 UI, onboarding, and delight

The phone, contract cards, roster, store, jet comparison, season pass, and results should share one modern design system. Motion should clarify state changes: offer arrival, team assignment, skill increase, badge unlock, route progress, satisfaction change, and payout. Show real numbers and causes, especially for salaries, aircraft eligibility, and ratings. The first session should teach one action at a time through contextual prompts and a forgiving introductory contract. Celebrate a first successful landing and first crew upgrade with polished, brief feedback. Support touch, mouse, keyboard, and gamepad without tiny controls or excessive screen coverage.

## 10. Technical implementation for a fresh Roblox project

Use Roblox Studio and Luau. If this repository is empty, create a source-controlled Roblox project structure that can be opened or synced into Studio, with a README explaining exact setup and playtest steps. Choose a tooling workflow available locally; do not claim Studio testing if Studio is unavailable.

Suggested separation:

- Shared typed configuration: jets, destinations, client archetypes, teams, badges, upgrades, economy, season, and scoring weights.
- Server services: player data, contracts, matchmaking/crew, flight state, scoring, rewards, recruitment, store, season, leaderboards, and purchases.
- Client controllers/UI: phone offers, hangar, crew assignment, flight HUD, cabin requests, arrival tasks, results, store, and season pass.
- World content: hangar, aircraft prototypes, four destination scenes, NPC client, and interactable stations.

Server owns currency, inventory, purchases, contract offers, flight transitions, score, and rewards. Validate all remote calls, cooldowns, prices, ownership, seat requirements, and role actions. Persist player data with schema versioning, retry handling, and safe defaults. Use stable item IDs. Instrument charter starts, completions, abandonments, ratings, purchases, and session length without storing unnecessary personal data.

Keep V1 performant for common Roblox mobile devices. Reuse assets, stream or load destination scenes as needed, cap visual effects, and test touch controls. Set measurable budgets for client memory, part/triangle count, draw calls, particles, network events, and frame time after profiling the target hardware. Provide accessibility basics: remappable or clear controls, readable text, non-color-only status, and subtitles for critical audio cues.

### Production and credit efficiency

Use the available tools and existing assets before generating or purchasing replacements. Inspect the workspace and installed Roblox tooling once, then commit to a workflow. Build a single reusable aircraft interaction system, role action system, UI design system, and destination template rather than duplicating code. Generate or commission only the assets that have a clear role in the current playable milestone. Batch related asset requests and reviews; reuse materials, sound layers, and animation rigs. Keep a short decision log so later work does not revisit settled questions. Prefer a focused prototype and visible playtest evidence over large speculative documents. Do not run repeated broad tests without a specific unresolved risk. Preserve all work in source control and report the next actionable step at each milestone.

## 11. Build sequence and acceptance gates

1. **Visual and interaction foundation:** establish the art bible, UI design system, lighting/material palette, camera language, audio layers, animation approach, performance targets, and one detailed hangar plus one detailed light jet. Confirm these choices with in-engine screenshots or video when available. These are production assets and systems, not a disposable blockout.
2. **Premium playable vertical slice:** one destination, phone offers, prep, boarding, flight, live client request, landing, arrival event, results, and saved rewards. Include the key animations, sound cues, environmental effects, and short skippable cutscenes. Solo must work end to end.
3. **Co-op and crews:** 1–4 player queue, soft roles, NPC teams, recruitment, salaries, manual skills, badges, and role XP.
4. **Progression and world:** three jet classes, four launch destinations, hangar upgrade tracks, visits, and leaderboards. Carry the first slice's visual standard forward.
5. **Commerce and season:** daily store, purchasable credits, five-week free/premium pass, full-pass purchase, high-tier jet, purchase receipts, and published reward rules.
6. **Release polish:** onboarding, mobile/gamepad pass, visual and audio consistency, performance, accessibility, bug fixes, and a complete new-player playtest.

Do not call a system complete merely because its UI exists. For each gate, demonstrate the end-to-end path in Studio when available and report what was actually tested. A first release must let a new solo player finish a charter, see an explainable score, earn and save credits, recruit and assign a team, upgrade something meaningful, and return for another offer. A paying player may progress faster, but flight control and client decisions must still determine ratings.

## 12. Remaining production variables

The implementation team may tune starting prices, exact flight distances, skill growth costs, pass price, roster size, and art assets after playtesting. Keep these in configuration rather than hardcoding them across scripts. Do not reopen the core decisions above without a concrete conflict discovered during implementation.
