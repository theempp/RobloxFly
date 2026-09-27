--!strict
-- Pure domain code, exercised by tests/domain.luau without a Roblox process.
local Domain = {}

function Domain.tailNumber(userId: number, jetIndex: number): string
	local digits, value, encoded = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", math.abs(userId), ""
	repeat local n = value % 36; encoded = string.sub(digits, n + 1, n + 1) .. encoded; value = math.floor(value / 36) until value == 0
	return "AS-" .. (if userId < 0 then "S" else "U") .. encoded .. "-" .. jetIndex
end

function Domain.copy(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in value do result[key] = Domain.copy(item) end
	return result
end

function Domain.newProfile(config: any): any
	local teams = {}
	for id, team in config.Teams do
		if team.Price == 0 then teams[id] = { Skills = Domain.copy(team.Skills), Runs = 0, Badges = {} } end
	end
	return { Version = config.Schema, Credits = config.StartingCredits, XP = 0, Reputation = 0, Tokens = 0,
		Runs = 0, RoleXP = {}, Jets = { aster_l6 = true }, ActiveJet = "aster_l6", Teams = teams,
		Assigned = { Pilot = "pilot_starter", Cabin = "cabin_starter", Security = "security_starter" },
		Hangar = { Theme = "Porcelain", Showpiece = 0, Operations = 0 },
		Settings = { Quality = "High", ReducedMotion = false, Volume = 0.55 },
		SalaryDay = -1, RewardJournal = {}, BestScores = {}, Receipts = {}, SeasonXP = 0 }
end

function Domain.migrate(data: any, config: any): any
	if type(data) ~= "table" then return Domain.newProfile(config) end
	if type(data.Version) == "number" and data.Version > config.Schema then error("Newer save version") end
	local default = Domain.newProfile(config)
	for key, value in default do if data[key] == nil then data[key] = value end end
	assert(type(data.Credits) == "number" and data.Credits == data.Credits and data.Credits >= 0, "Invalid saved credits")
	data.Version = config.Schema
	return data
end

function Domain.overall(skills: any): number
	local sum, count = 0, 0
	for _, value in skills do sum += value; count += 1 end
	return math.floor(sum / math.max(1, count) + 0.5)
end

function Domain.crewTuning(profile: any): any
	local cabin = profile.Teams[profile.Assigned.Cabin]
	local pilot = profile.Teams[profile.Assigned.Pilot]
	local security = profile.Teams[profile.Assigned.Security]
	return {
		Pilot = Domain.copy(pilot.Skills),
		ServiceDelay = math.clamp(26 - (cabin.Skills.Speed - 60) * 0.25, 18, 28),
		Patience = (cabin.Skills.Reading - 60) * 0.15 + (cabin.Skills.Composure - 60) * 0.1,
		AutoServiceCredit = math.clamp(0.55 + (cabin.Skills.Catering - 60) * 0.006, 0.5, 0.72),
		ArrivalAssistDelay = math.clamp(28 - (security.Skills.Logistics - 60) * 0.3, 20, 30),
	}
end

function Domain.score(metrics: any, config: any): any
	local weights = config.Scoring
	local breakdown = {
		{ Name = "Smoothness", Value = math.clamp(weights.Smoothness - math.floor(metrics.Rough * 0.3), 8, 25), Max = 25, Cause = "Abrupt controls and steep bank" },
		{ Name = "Timing", Value = math.clamp(20 - math.floor(math.max(0, metrics.Elapsed - metrics.Target) / 15), 6, 20), Max = 20, Cause = "Time against the client schedule" },
		{ Name = "Cabin service", Value = math.clamp(8 + metrics.Prepared * 3 + metrics.Served * 5 - metrics.Missed * 3, 5, 25), Max = 25, Cause = "Cabin preferences and live requests" },
		{ Name = "Discretion", Value = math.clamp(metrics.Discretion, 4, 20), Max = 20, Cause = "Car, baggage and protected client path" },
		{ Name = "Safety", Value = math.clamp(10 - metrics.GoArounds - metrics.HardLanding * 3, 4, 10), Max = 10, Cause = "Landing, gear and safe recovery" },
	}
	local score = 0
	for _, row in breakdown do row.Value = math.floor(row.Value + 0.5); score += row.Value end
	local multiplier = math.floor((0.55 + score / 100 * 0.75) * 100) / 100
	return { Score = score, Breakdown = breakdown, Multiplier = multiplier,
		Label = if score >= 90 then "Exceptional" elseif score >= 75 then "Distinguished" elseif score >= 60 then "Promising" else "Flight completed" }
end

function Domain.reward(profile: any, runId: string, result: any, role: string): boolean
	if profile.RewardJournal[runId] then return false end
	profile.RewardJournal[runId] = result.CompletedAt
	profile.Credits += result.Payout
	profile.XP += result.XP
	profile.RoleXP[role] = (profile.RoleXP[role] or 0) + result.XP
	profile.Reputation += math.floor(result.Score / 10)
	profile.Tokens += 1
	profile.Runs += 1
	profile.SeasonXP += result.XP
	for _, teamId in profile.Assigned do profile.Teams[teamId].Runs += 1 end
	table.insert(profile.BestScores, result.Score)
	table.sort(profile.BestScores, function(a: number, b: number) return a > b end)
	while #profile.BestScores > 10 do table.remove(profile.BestScores) end
	-- Runs cannot be replayed by clients. Bound the persisted dedup journal.
	local entries: {any} = {}
	for id, stamp in profile.RewardJournal do table.insert(entries, { id, stamp }) end
	table.sort(entries, function(a: any, b: any) return a[2] > b[2] end)
	for i = 65, #entries do profile.RewardJournal[entries[i][1]] = nil end
	return true
end

function Domain.purchase(profile: any, action: string, id: string, config: any): (boolean, string)
	if action == "Recruit" then
		local team = config.Teams[id]
		if not team or team.Price == 0 or profile.Teams[id] then return false, "Team unavailable or already owned" end
		if profile.Credits < team.Price then return false, "More credits needed" end
		profile.Credits -= team.Price
		profile.Teams[id] = { Skills = Domain.copy(team.Skills), Runs = 0, Badges = {} }
		return true, "Team recruited permanently"
	elseif action == "Assign" then
		local team = config.Teams[id]
		if not team or not profile.Teams[id] then return false, "Recruit this team first" end
		profile.Assigned[team.Category] = id
		return true, "Assigned · salary shown in roster"
	elseif action == "Upgrade" then
		if id ~= "Showpiece" and id ~= "Operations" then return false, "Unknown upgrade" end
		if profile.Hangar[id] >= 1 then return false, "Upgrade already owned" end
		local cost = if id == "Showpiece" then config.Economy.HangarCost else config.Economy.ServiceCost
		if profile.Credits < cost then return false, "More credits needed" end
		profile.Credits -= cost; profile.Hangar[id] = 1
		return true, if id == "Showpiece" then "Lounge and floor finish installed" else "Service facility installed · request grace +4 seconds"
	end
	return false, "Unknown purchase"
end

function Domain.train(profile: any, id: string, skill: string, config: any): (boolean, string)
	local team = profile.Teams[id]
	if not team or type(team.Skills[skill]) ~= "number" then return false, "Choose an owned team skill" end
	if config.Teams[id].Category == "Security" and skill ~= "Logistics" then return false, "This skill's encounter is not enabled yet" end
	if team.Skills[skill] >= config.Economy.SkillCap then return false, "Tier skill cap reached" end
	if profile.Tokens < 1 or profile.Credits < config.Economy.TrainingCost then return false, "Needs 1 training token and 300 credits" end
	profile.Tokens -= 1; profile.Credits -= config.Economy.TrainingCost
	team.Skills[skill] = math.min(config.Economy.SkillCap, team.Skills[skill] + config.Economy.SkillStep)
	return true, skill .. " improved"
end

function Domain.salary(profile: any, day: number, config: any): (boolean, number)
	if profile.SalaryDay == day then return true, 0 end
	local cost = 0
	for _, id in profile.Assigned do cost += config.Teams[id].Salary end
	if profile.Credits < cost then return false, cost end
	profile.Credits -= cost; profile.SalaryDay = day
	return true, cost
end

return Domain
