-- Run with tools/luau/luau.exe tests/domain.luau
local Config = require("../src/shared/Config")
local Domain = require("../src/shared/Domain")
local Flight = require("../src/shared/FlightModel")
local Protocol = require("../src/shared/Protocol")
local passed = 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
	passed += 1; print("PASS " .. name)
end
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end

test("remote payload rejects tables, oversized strings and nonfinite numbers", function()
	assert(not Protocol.validPayload({ Id = {} }))
	assert(not Protocol.validPayload({ Id = string.rep("a", 97) }))
	assert(not Protocol.validPayload({ Value = 0/0 }))
	assert(not Protocol.validPayload({ Value = math.huge }))
	assert(Protocol.validPayload({ Id = "cabin_silk", Value = false }))
end)
test("flight input accepts bounded intent only", function()
	assert(not Protocol.validInput({ Bank = 2, Pitch = 0, Throttle = 0 }))
	assert(not Protocol.validInput({ Bank = 0, Pitch = 0/0, Throttle = 0 }))
	assert(not Protocol.validInput({ Bank = 0, Pitch = 0 }))
	assert(Protocol.validInput({ Bank = -1, Pitch = 1, Throttle = 0.5 }))
end)

test("new profiles are independent", function()
	local a, b = Domain.newProfile(Config), Domain.newProfile(Config)
	a.Teams.cabin_starter.Skills.Speed = 99
	equal(b.Teams.cabin_starter.Skills.Speed, 60)
end)
test("generated tail numbers retain the entire owner namespace", function()
	assert(Domain.tailNumber(1234567, 1) ~= Domain.tailNumber(234567, 1))
	assert(Domain.tailNumber(-1, 1) ~= Domain.tailNumber(1, 1))
	assert(Domain.tailNumber(1, 1) ~= Domain.tailNumber(1, 2))
end)
test("future schema fails closed", function() assert(not pcall(Domain.migrate, { Version = 999 }, Config)) end)
test("corrupt credits fail closed", function() assert(not pcall(Domain.migrate, { Version = 1, Credits = -1 }, Config)) end)
test("old profile gains missing fields", function() equal(Domain.migrate({ Credits = 321 }, Config).Credits, 321) end)
test("duplicate reward cannot mint twice", function()
	local p = Domain.newProfile(Config)
	local result = { Payout = 1500, XP = 120, Score = 90, CompletedAt = 1 }
	assert(Domain.reward(p, "run-a", result, "Captain"))
	assert(not Domain.reward(p, "run-a", result, "Captain"))
	equal(p.Credits, Config.StartingCredits + 1500); equal(p.Tokens, 1); equal(p.Runs, 1)
end)
test("reward journal and score sample are bounded", function()
	local p = Domain.newProfile(Config)
	for i = 1, 100 do Domain.reward(p, "run-" .. i, { Payout = 1, XP = 1, Score = i, CompletedAt = i }, "Captain") end
	local count = 0; for _ in p.RewardJournal do count += 1 end
	equal(count, 64); equal(#p.BestScores, 10); equal(p.BestScores[1], 100)
end)
test("recruitment charges server catalog price once", function()
	local p = Domain.newProfile(Config)
	assert(Domain.purchase(p, "Recruit", "cabin_silk", Config)); equal(p.Credits, 200)
	assert(not Domain.purchase(p, "Recruit", "cabin_silk", Config)); equal(p.Credits, 200)
end)
test("unknown and unaffordable purchases reject", function()
	local p = Domain.newProfile(Config)
	assert(not Domain.purchase(p, "Recruit", "FAKE", Config))
	assert(not Domain.purchase(p, "Recruit", "pilot_horizon", Config)); equal(p.Credits, 2400)
end)
test("manual training requires currency and earned tokens", function()
	local p = Domain.newProfile(Config)
	assert(not Domain.train(p, "cabin_starter", "Speed", Config))
	p.Tokens = 1; assert(Domain.train(p, "cabin_starter", "Speed", Config))
	equal(p.Teams.cabin_starter.Skills.Speed, 62); equal(p.Tokens, 0); equal(p.Credits, 2100)
end)
test("training cap and invalid skill reject", function()
	local p = Domain.newProfile(Config); p.Tokens = 3; p.Teams.cabin_starter.Skills.Speed = 85
	assert(not Domain.train(p, "cabin_starter", "Speed", Config))
	assert(not Domain.train(p, "cabin_starter", "Arbitrary", Config)); equal(p.Tokens, 3)
end)
test("cabin training changes real assistance timing", function()
	local p = Domain.newProfile(Config); p.Tokens = 1
	local before = Domain.crewTuning(p).ServiceDelay
	assert(Domain.train(p, "cabin_starter", "Speed", Config))
	assert(Domain.crewTuning(p).ServiceDelay < before)
end)
test("salary charges only assigned teams once per day", function()
	local p = Domain.newProfile(Config); p.Credits = 10000
	assert(Domain.purchase(p, "Recruit", "cabin_silk", Config))
	local before = p.Credits
	assert(Domain.purchase(p, "Assign", "cabin_silk", Config))
	local ok, cost = Domain.salary(p, 10, Config); assert(ok); equal(cost, 60)
	equal(p.Credits, before - 60); assert(Domain.salary(p, 10, Config)); equal(p.Credits, before - 60)
end)
test("salary never creates negative debt", function()
	local p = Domain.newProfile(Config); p.Credits = 3000
	assert(Domain.purchase(p, "Recruit", "cabin_silk", Config)); assert(Domain.purchase(p, "Assign", "cabin_silk", Config)); p.Credits = 1
	assert(not Domain.salary(p, 1, Config)); equal(p.Credits, 1); equal(p.SalaryDay, -1)
end)
test("foundation teams preserve a free recovery path", function()
	local p = Domain.newProfile(Config); p.Credits = 0
	assert(Domain.salary(p, 1, Config)); equal(p.Credits, 0)
end)
test("scores have explicit floors and bounded payout", function()
	local s = Domain.score({ Rough = 9999, Elapsed = 9999, Target = 1, Prepared = 0, Served = 0, Missed = 100, Discretion = 0, GoArounds = 100, HardLanding = 100 }, Config)
	equal(s.Score, 27); assert(s.Multiplier >= 0.55)
	local best = Domain.score({ Rough = 0, Elapsed = 100, Target = 400, Prepared = 2, Served = 3, Missed = 0, Discretion = 20, GoArounds = 0, HardLanding = 0 }, Config)
	equal(best.Score, 100); equal(best.Multiplier, 1.3)
end)
test("flight never rotates below safe speed", function()
	local f = Flight.new(Config.Flight)
	for _ = 1, 90 do Flight.step(f, { Pitch = 1 }, 1/30, Config.Flight) end
	equal(f.Phase, "Taxi"); equal(f.Altitude, Config.Flight.GearHeight)
end)
test("runway overrun recovers without ending charter", function()
	local f = Flight.new(Config.Flight); f.Z = 1799; f.Speed = 100; f.Throttle = 0.8
	equal(Flight.step(f, {}, 0.1, Config.Flight), "Recovery"); equal(f.GoArounds, 1)
end)
test("approach forcibly disengages autopilot", function()
	local f = Flight.new(Config.Flight); f.Phase = "Cruise"; f.Altitude = 260; f.Speed = 100; f.Z = Config.Flight.ApproachStart; f.Autopilot = true
	equal(Flight.step(f, {}, 1/30, Config.Flight), "Approach"); equal(f.Autopilot, false)
end)
test("gear up touchdown requires go around", function()
	local f = Flight.new(Config.Flight); f.Phase = "Approach"; f.Z = 14100; f.Speed = 70; f.Throttle = 0.5; f.Gear = false
	equal(Flight.step(f, {}, 1/30, Config.Flight), "Recovery")
end)
test("aligned controlled touchdown is accepted", function()
	local f = Flight.new(Config.Flight); f.Phase = "Approach"; f.Z = 14100; f.Speed = 70; f.Throttle = 0.5
	equal(Flight.step(f, {}, 1/30, Config.Flight), "Landed")
end)
test("full flight can take off cruise approach and land", function()
	local f = Flight.new(Config.Flight); local elapsed = 0; local events = {}
	for _ = 1, 18000 do
		local input = { Bank = math.clamp(-f.X / 100, -1, 1), Pitch = 0, Throttle = 0 }
		if f.Phase == "Taxi" or f.Phase == "Climb" then
			input.Throttle = if f.Throttle < 0.8 then 1 else 0
			input.Pitch = if f.Speed >= 72 then 0.6 else 0
		elseif f.Phase == "Cruise" then f.Autopilot = true; f.Gear = false
		elseif f.Phase == "Approach" then
			f.Gear = true
			local throttleTarget = 70/145
			input.Throttle = math.clamp((throttleTarget - f.Throttle) * 10, -1, 1)
			local desiredAltitude = math.max(5.4, (14200 - f.Z) * 0.072 + 5.4)
			input.Pitch = math.clamp((desiredAltitude - f.Altitude) / 60 - 0.23, -0.6, 0.6)
		end
		local before = { Z = f.Z, Altitude = f.Altitude, Phase = f.Phase, Gear = f.Gear }
		local event = Flight.step(f, input, 1/30, Config.Flight); elapsed += 1/30
		if event == "Recovery" then print("  recovery prior", before.Z, before.Altitude, before.Phase, before.Gear, f.Speed) end
		if event then events[event] = true; print(string.format("  %s at %.1fs, route %.0f, altitude %.1f, speed %.1f", event, elapsed, f.Z, f.Altitude, f.Speed)) end
		if event == "Landed" then break end
	end
	assert(events.Takeoff and events.Cruise and events.Approach, "missing flight phases")
	equal(f.Phase, "Landed"); equal(f.GoArounds, 0)
	print(string.format("  Simulated manual departure + autopilot + guided landing: %.1fs", elapsed))
end)
print(string.format("%d domain/flight tests passed", passed))
