# Milestones and honest acceptance state

| Gate | Current evidence | Outstanding gate |
|---|---|---|
| 1 — Visual / interaction foundation | Original source geometry baked to a Studio place; offline browser review of actual exported parts; art tokens and camera/audio conventions; 1,180 scene parts, 563 aircraft parts, 10 point lights | Studio screenshots, collision/scale review, NPC/door/gear motion and sound upload/mix |
| 2 — Premium solo charter | Full state flow authored; 24 pure domain/flight tests and 17 server integration tests with simulated transport; model-controlled departure/cruise/landing | A real solo F5 run, moving cabin/avatar behavior, manual landing feel, streaming, UI usability, durable private-universe save/rejoin |
| 3 — Co-op and crews | Four-member cap, soft roles, shared charter, separate payouts, recruit/assign/train and salary logic tested offline | Studio 2–4 clients, owner/disconnect handling, all security skill effects, wider badges and NPC sophistication |
| 4 — Progression / world | One jet and destination; two visible hangar upgrades; globally distinct generated tail IDs | Midsize/large jets, Dubai/alpine/New York, collection storage, training rooms, configurable visit permissions, filtered custom tail IDs, qualifying weekly leaderboards and serialized prestige awards |
| 5 — Commerce / season | Transparent permanent recruitment and rotating daily spotlight; disabled purchase controls/IDs; fail-closed receipt callback | Full daily item rotation, five-week free/premium tracks, objectives, functional season jet, premium/full-pass products, receipt fulfillment and anti-abuse tests |
| 6 — Release | Keyboard/touch/gamepad bindings and quality/accessibility controls authored | Device input tests, sound completion, performance profiles, onboarding study, repeated new-player testing and all above gates |

No gate is called production-complete. The next step is to authenticate Studio, open the baked place and run the solo checklist in README. Expanding all destinations before that gate would duplicate unvalidated aircraft, flight and visual assumptions.

Balance observation: the deterministic flight model completes its route in about 147 seconds with ideal control. This is shorter than the specification's approximately eight-minute total charter target. Keep the first route forgiving, then tune route length, service pacing and arrival timing from real playtests; do not pad it with idle cruise.

Security skills other than Logistics are displayed but training is disabled until their encounter effects exist. Pilot skills refine control response/autopilot tracking; cabin skills affect NPC timing, patience and service credit. No unimplemented effect is sold through training.
