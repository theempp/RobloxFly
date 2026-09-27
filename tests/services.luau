-- Offline integration harness: real server modules, Lune data model, controlled
-- task scheduler and DataStore transport. This does NOT simulate Roblox physics.
local fs = require("@lune/fs")
local rbx = require("@lune/roblox")
local luau = require("@lune/luau")
local actualGame = rbx.deserializePlace(fs.readFile("build/PrivateJetCharterTycoon.rbxlx"))
local Domain = require("../src/shared/Domain")
local now, guid, writes = 1000, 0, 0
local queued, delayed, records, playerMap = {}, {}, {}, {}
local failWrites = false
local heartbeat
local store = {}
function store:UpdateAsync(key, transform)
	if failWrites then error("Injected storage outage") end
	local nextValue = transform(Domain.copy(records[key]))
	if nextValue ~= nil then records[key] = Domain.copy(nextValue); writes += 1 end
	return Domain.copy(nextValue)
end
local scheduler = {
	wait = function(seconds) now += seconds or 1/30; return seconds or 1/30 end,
	spawn = function(fn, ...) table.insert(queued, { fn, { ... } }) end,
	delay = function(seconds, fn) table.insert(delayed, { At = now + seconds, Fn = fn }) end,
}
local function drain()
	while #queued > 0 do local item = table.remove(queued, 1); item[1](table.unpack(item[2])) end
end
local function advance(seconds)
	now += seconds
	for i = #delayed, 1, -1 do if delayed[i].At <= now then local fn = table.remove(delayed, i).Fn; fn() end end
	drain()
end
local services = {
	DataStoreService = { GetDataStore = function() return store end },
	RunService = { IsStudio = function() return false end, Heartbeat = { Connect = function(_, fn) heartbeat = fn end } },
	HttpService = { GenerateGUID = function() guid += 1; return "test-guid-" .. guid end },
	Players = { GetPlayerByUserId = function(_, id) return playerMap[id] end },
}
local game = { JobId = "test-session", GetService = function(_, name) return services[name] or actualGame:GetService(name) end }
rbx.implementMethod("Model", "GetPivot", function(m) return m.PrimaryPart and m.PrimaryPart.CFrame or rbx.CFrame.identity end)
rbx.implementMethod("Model", "PivotTo", function(m, cf)
	local delta = cf * m:GetPivot():Inverse()
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame = delta * p.CFrame end end
end)
rbx.implementMethod("TweenService", "Create", function(_, object, _, props)
	return { Play = function() for key, value in props do object[key] = value end end }
end)
local env = { game = game, workspace = actualGame:GetService("Workspace"), task = scheduler,
	os = { time = function() return math.floor(now) end, clock = function() return now end } }
for _, name in { "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Enum", "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence" } do env[name] = rbx[name] end
env.TweenInfo = { new = function(...) return { ... } end }
local modules = {}
env.require = function(module)
	if modules[module] then return modules[module] end
	local moduleEnv = table.clone(env); moduleEnv.script = module
	local result = luau.load(module.Source, { environment = moduleEnv, debugName = module.Name })()
	modules[module] = result; return result
end
local Profiles = env.require(actualGame:GetService("ServerScriptService").Server.Profiles)
-- The repeating lease-renewal loop is separately exercised through transact,
-- not executed as an infinite background coroutine in this finite harness.
table.clear(queued)
local Charters = env.require(actualGame:GetService("ServerScriptService").Server.Charters)
local Config = env.require(actualGame:GetService("ReplicatedStorage").Shared.Config)
local function player(id)
	local p = { UserId = id, DisplayName = "Tester " .. id, Parent = true, CharacterAdded = { Connect = function() end } }
	playerMap[id] = p
	assert(Profiles.load(id)); Charters.addPlayer(p)
	local c = rbx.Instance.new("Model"); c.Parent = env.workspace
	local root = rbx.Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = c; c.PrimaryPart = root; p.Character = c
	return p
end
local sent = {}
Charters.start({ FireClient = function(_, p, kind, value) table.insert(sent, { User = p.UserId, Kind = kind, Data = value }) end })
local a, b = player(11), player(22)
local passed = 0
local function test(name, fn) local ok, err = pcall(fn); if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end; passed += 1; print("PASS " .. name) end
local function move(p, pos) p.Character:PivotTo(rbx.CFrame.new(pos)) end
local function act(p, action, data) return Charters.action(p, action, data or {}) end
local run

test("save load acquires an exclusive lease", function()
	assert(records.p_11.Lock.Session ~= nil)
	records.p_33 = Domain.newProfile(Config); records.p_33.Lock = { Session = "foreign", Expires = now + 99 }
	assert(not Profiles.load(33))
end)
test("save outage leaves confirmed balance unchanged", function()
	local before = Profiles.get(11).Credits
	failWrites = true
	assert(not Profiles.transact(11, function(p) p.Credits -= 100; return true end))
	failWrites = false
	assert(Profiles.get(11).Credits == before and records.p_11.Credits == before)
end)
test("forged offer and premature reward reject", function()
	assert(not act(a, "Accept", { Id = "forged" })); assert(not act(a, "Finish")); assert(not act(a, "RetrySave"))
end)
test("offer expiry rejects stale accept", function()
	local id = Charters.offers(a)[1].Id; advance(Config.OfferLifetime + 1)
	assert(not act(a, "Accept", { Id = id }))
end)
test("accept creates one authoritative session", function()
	local id = Charters.offers(a)[1].Id; assert(act(a, "Accept", { Id = id }))
	assert(not act(a, "Accept", { Id = id }))
	local state = Charters.snapshot(a); run = Charters.Sessions[state.Run.Id]
	assert(run.Stage == "Preparation")
end)
test("co-op joins with a flexible role", function()
	assert(act(b, "Join", { Id = run.Id })); assert(act(b, "Role", { Id = "Cabin Host" }))
	assert(run.Members[22].Role == "Cabin Host")
end)
test("preparation rejects remote distance and invalid preferences", function()
	move(a, rbx.Vector3.new(1000, 1000, 1000)); assert(not act(a, "Prep", { Id = "Tea" }))
	move(a, run.Plot.Model.CateringStation.CFrame.Position); assert(not act(a, "Prep", { Id = "free-currency" }))
	assert(act(a, "Prep", { Id = run.Client.Preference })); assert(act(a, "Prep", { Id = run.Client.Mood }))
end)
test("only owner can board and salary commits once", function()
	move(a, run.Jet.CabinDoor.CFrame.Position); move(b, run.Jet.CabinDoor.CFrame.Position)
	assert(not act(b, "Board")); assert(act(a, "Board")); assert(not act(a, "Board"))
	drain(); advance(6)
	assert(run.Stage == "Ready"); assert(run.Coop == 0.1); assert(run.Metrics.Prepared == 2)
	assert(records.p_11.Credits == Config.StartingCredits)
end)
test("departure cannot be skipped and client boards", function()
	assert(run.NPC:GetAttribute("Seated")); assert(not act(a, "Finish")); assert(act(a, "Start"))
	assert(run.Stage == "Flight"); assert(not act(b, "Start"))
end)
test("pilot cannot leave manual departure; cruise unlocks cabin", function()
	assert(not act(a, "Cabin")); assert(not act(a, "Autopilot"))
	run.Flight.Phase = "Cruise"; run.Flight.Altitude = 260
	assert(act(a, "Autopilot")); assert(act(a, "Cabin"))
	assert(not run.Seated[11])
end)
test("live request rewards physical manual service once", function()
	run.Request = { Text = "Tea", Expires = now + 30, Started = now }
	move(a, run.Jet.Galley.CFrame.Position)
	assert(act(a, "Service")); assert(not act(a, "Service")); assert(run.Metrics.Served == 1)
end)
test("valid server touchdown opens arrival, not rewards", function()
	assert(act(a, "Cockpit"))
	run.Flight.Phase = "Approach"; run.Flight.Autopilot = false; run.Flight.Z = Config.Flight.RunwayStart + 200
	run.Flight.Altitude = Config.Flight.GearHeight; run.Flight.Speed = 70; run.Flight.Throttle = 70/145; run.Flight.Gear = true
	heartbeat(0.1)
	assert(run.Stage == "Arrival"); assert(Profiles.get(11).Runs == 0)
end)
test("arrival requires baggage and car; no duplicate completion", function()
	move(a, run.Jet:GetPivot().Position); assert(not act(a, "Finish"))
	for _, choice in { "Covered", "Baggage", "Umbrella", "Decoy" } do assert(act(a, "Arrival", { Id = choice })) end
	failWrites = true
	assert(act(a, "Finish")); assert(not act(a, "Finish")); drain()
	assert(run.Stage == "Results"); assert(Profiles.get(11).Runs == 0 and Profiles.get(22).Runs == 0)
	assert(not run.Members[11].Paid and not run.Members[22].Paid)
	assert(not act(a, "Return"))
end)
test("failed reward commit can retry without double credit", function()
	failWrites = false
	assert(act(a, "RetrySave")); assert(not act(a, "Return"))
	assert(act(b, "RetrySave")); assert(run.Members[11].Paid and run.Members[22].Paid)
	assert(Profiles.get(11).Runs == 1 and Profiles.get(22).Runs == 1)
end)
test("full co-op payouts are durable and replay safe", function()
	local expected = run.Result.Payout
	assert(records.p_11.Credits == Config.StartingCredits + expected)
	assert(records.p_22.Credits == Config.StartingCredits + expected)
	local before = records.p_11.Credits
	assert(act(a, "RetrySave")); assert(records.p_11.Credits == before)
end)
test("return restores hangar and allows meaningful progression", function()
	assert(act(a, "Return")); assert(Charters.snapshot(a).Run == nil)
	assert(act(a, "Recruit", { Id = "cabin_silk" })); assert(act(a, "Assign", { Id = "cabin_silk" }))
	assert(act(a, "Train", { Id = "cabin_silk", Skill = "Reading" }))
	assert(Profiles.get(11).Teams.cabin_silk.Skills.Reading == 82)
end)
test("release preserves progress and relinquishes lease", function()
	Profiles.release(11); assert(records.p_11.Lock == nil)
	assert(Profiles.load(11)); assert(Profiles.get(11).Runs == 1 and Profiles.get(11).Teams.cabin_silk)
end)
print(string.format("%d offline server integration tests passed; %d data-store commits", passed, writes))

