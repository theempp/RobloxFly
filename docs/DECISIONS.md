# Build decisions

- The supplied specification is unchanged and is the design authority. This repository started empty except for that file.
- Rojo 7.7.0 produces a Studio-openable place; Luau 0.740 checks source and runs pure domain tests. Tools are local and ignored by Git. No mandatory plugin, paid dependency, or marketplace model.
- First route: fictional Riviera coast near Monaco. Original aircraft: Aster L6. Warm limestone, graphite steel, porcelain paint, walnut cabin and champagne trim. Direction must be reviewed in Studio before expanding the fleet/world.
- Aircraft are server-simulated guided-route kinematic vehicles. Control inputs are bounded intent, never client positions. The cabin remains usable under cruise autopilot. Approach and touchdown depend on speed, height, alignment and vertical speed.
- A single charter owns an isolated operational plot. Up to four players can participate; visitors cannot mutate the host's collection. No simultaneous fleet simulation.
- Production persistence fails closed if a profile cannot load or save. Studio uses explicit session-only data until API services and a published test universe are configured.
- Paid product IDs remain zero and purchase actions disabled. No fake receipt success or speculative monetization fulfillment.
- Studio was found running at authentication. No Studio playtest claim is permitted until an authenticated editor can run this build.
- User chose local builds while Studio remains signed out. Lune 0.10.5 now bakes the same production World module into an edit-mode preview and runs finite server integration tests with simulated transport. A Three.js inspector reviews exported geometry only; it is not a second game implementation.
- Foundation teams have zero salary to guarantee recovery from a zero-credit balance. Higher teams retain transparent salaries and cannot create debt. Training disabled security skills would sell an ineffective upgrade, so only implemented effects can be trained.
- The local reward failure test prevents the host closing results while a crewmate's save is pending. Live run resume and private-universe durability testing remain release gates.
