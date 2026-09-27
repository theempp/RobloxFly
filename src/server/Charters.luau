local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Domain = require(Shared.Domain)
local FlightModel = require(Shared.FlightModel)
local Profiles = require(script.Parent.Profiles)
local World = require(script.Parent.World)
local Charters = {}
Charters.Sessions = {}
local plots, offers, membership, slots = {}, {}, {}, {}
local root = World.init()
local remote
local function send(player, kind, data) if player and player.Parent then remote:FireClient(player, kind, data) end end
local function tell(run, text, cue)
	for userId in run.Members do send(Players:GetPlayerByUserId(userId), "Notice", { Text = text, Cue = cue }) end
end
local function near(player, point, distance)
	local c = player.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and (r.CFrame.Position - point).Magnitude <= (distance or Config.Limits.InteractionDistance)
end
local function movePlayer(player, cf)
	local c = player and player.Character
	if c then c:PivotTo(cf); local r = c:FindFirstChild("HumanoidRootPart"); if r then r.AssemblyLinearVelocity = Vector3.zero end end
end
local function lockControls(player, locked)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = if locked then 0 else 18; humanoid.JumpPower = if locked then 0 else 50; humanoid.JumpHeight = if locked then 0 else 7.2; humanoid.AutoRotate = not locked end
end
local function profile(player) return Profiles.get(player.UserId) end

function Charters.offers(player)
	local list = offers[player.UserId]
	if not list or list[1].Expires <= os.time() then
		list = {}
		for i, client in Config.Clients do
			table.insert(list, { Id = HttpService:GenerateGUID(false), Client = i, Destination = "riviera", Jet = "aster_l6",
				Expires = os.time() + Config.OfferLifetime, Fee = client.Fee, Range = 680, Seats = client.Party })
		end
		offers[player.UserId] = list
	end
	return list
end

local function publicRun(run)
	if not run then return nil end
	local members = {}
	for id, info in run.Members do table.insert(members, { UserId = id, Name = info.Name, Role = info.Role, Paid = info.Paid }) end
	return { Id = run.Id, Owner = run.Owner, Stage = run.Stage, Offer = run.Offer, Client = run.Client,
		Prep = run.Prep, Members = members, Flight = run.Flight, Request = run.Request, Served = run.Metrics.Served,
		Arrival = run.Arrival, Result = run.Result, JetName = run.Jet.Name, Pilot = run.Pilot, Error = run.Error,
		Elapsed = math.floor(os.clock() - run.Started), Coop = run.Coop or 0, Seated = run.Seated }
end

function Charters.snapshot(player)
	local run = Charters.Sessions[membership[player.UserId]]
	local hosts = {}
	for id, session in Charters.Sessions do
		if session.Stage == "Preparation" and session.Owner ~= player.UserId then
			table.insert(hosts, { Id = id, Owner = session.Owner, Name = session.Members[session.Owner].Name })
		end
	end
	return { Profile = Profiles.public(player.UserId), Offers = Charters.offers(player), Run = publicRun(run), Hosts = hosts,
		ServerTime = os.time(), Plot = plots[player.UserId] and plots[player.UserId].Index }
end

local function push(player) send(player, "State", Charters.snapshot(player)) end
local function broadcast(run) for id in run.Members do local p = Players:GetPlayerByUserId(id); if p then push(p) end end end

function Charters.addPlayer(player)
	local index = 0; while slots[index] do index += 1 end; slots[index] = true
	local plot = World.hangar(root, player.UserId, index); plots[player.UserId] = plot
	local tail = Domain.tailNumber(player.UserId, 1)
	plot.Jet = World.jet(plot.Model, plot.Origin, tail)
	plot.Jet:SetAttribute("Owner", player.UserId)
	World.door(plot.Jet, true); World.upgrade(plot, profile(player))
	local function spawnCharacter(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.2)
		local run = Charters.Sessions[membership[player.UserId]]
		if run and (run.Stage == "Flight" or run.Stage == "Boarding") then
			movePlayer(player, run.Jet:GetPivot() * CFrame.new(0, 4, -6))
		else movePlayer(player, CFrame.new(plot.Origin + Vector3.new(-32, 4, 56))) end
	end
	player.CharacterAdded:Connect(spawnCharacter)
	if player.Character then task.spawn(spawnCharacter, player.Character) end
	player.RespawnLocation = plot.Spawn
	push(player)
end

function Charters.accept(player, offerId)
	if membership[player.UserId] then return false, "Finish or leave your current charter first" end
	local offer
	for _, o in Charters.offers(player) do if o.Id == offerId then offer = o end end
	if not offer or offer.Expires <= os.time() then return false, "Offer expired · refresh your phone" end
	local p = profile(player); local jet = Config.Jets[p.ActiveJet]
	if not p.Jets[p.ActiveJet] or jet.Seats < offer.Seats or jet.Range < offer.Range then return false, "Aircraft is not eligible" end
	local plot = plots[player.UserId]
	local run = { Id = HttpService:GenerateGUID(false), Owner = player.UserId, Pilot = player.UserId, Stage = "Preparation", Offer = Domain.copy(offer),
		Client = Config.Clients[offer.Client], Jet = plot.Jet, Plot = plot, Started = os.clock(),
		Members = { [player.UserId] = { Name = player.DisplayName, Role = "Captain" } }, Prep = {}, Arrival = {},
		Metrics = { Rough = 0, Elapsed = 0, Target = Config.Clients[offer.Client].Time, Prepared = 0, Served = 0, Missed = 0, Discretion = 4, GoArounds = 0, HardLanding = 0 },
		Input = {}, LastInput = 0, RequestIndex = 0, Request = nil }
	Charters.Sessions[run.Id] = run; membership[player.UserId] = run.Id; offers[player.UserId] = nil
	run.NPC = World.npc(plot.Model, "Client", CFrame.new(plot.Origin + Vector3.new(-25, 3.2, 44)), Color3.fromRGB(126, 107, 91))
	run.CrewNPC = World.npc(plot.Model, "CabinCrew", CFrame.new(plot.Origin + Vector3.new(-19, 3.2, 40)))
	push(player); tell(run, "Set catering and cabin mood at the cabin atelier. Your client is waiting.", "Phone")
	print("[PJCT] charter_started", run.Id)
	return true
end

local function finish(run)
	run.Stage = "Results"
	run.Metrics.Elapsed = os.clock() - run.Started
	run.Metrics.Rough = run.Flight.Rough; run.Metrics.GoArounds = run.Flight.GoArounds
	local result = Domain.score(run.Metrics, Config)
	result.BaseFee = run.Offer.Fee; result.Coop = run.Coop
	result.Payout = math.floor(result.BaseFee * result.Multiplier * (1 + result.Coop))
	result.XP = 50 + result.Score; result.CompletedAt = os.time()
	run.Result = result
	for id, member in run.Members do
		task.spawn(function()
			local ok, message = Profiles.transact(id, function(p)
				Domain.reward(p, run.Id, result, member.Role)
				return true, "Reward saved"
			end)
			member.Paid = ok
			if not ok then run.Error = message end
			local player = Players:GetPlayerByUserId(id); if player then push(player) end
		end)
	end
	tell(run, "Charter complete · your rating shows every contribution.", "Results")
	broadcast(run); print("[PJCT] charter_completed", run.Id, result.Score)
end

local function board(run)
	run.Stage = "Boarding"; run.Started = os.clock()
	local cf = run.Jet:GetPivot()
	World.door(run.Jet, true)
	World.animateNPC(run.NPC, { cf * CFrame.new(-10, -2.2, -10), cf * CFrame.new(-4, 3.2, -10), cf * CFrame.new(2.2, 3, 1.7) }, 1.6, function()
		run.NPC:SetAttribute("Seated", true)
		run.NPC:SetAttribute("Mood", "Comfortable")
			World.poseSeated(run.NPC)
	end)
	World.animateNPC(run.CrewNPC, { cf * CFrame.new(-9, -2.2, -10), cf * CFrame.new(0, 3.2, -8) }, 1.8)
	for id in run.Members do movePlayer(Players:GetPlayerByUserId(id), cf * CFrame.new(0, 4, -6)) end
	tell(run, "Welcome aboard. Your client is taking their seat.", "Door")
	broadcast(run)
	task.delay(5.5, function()
		if run.Stage ~= "Boarding" then return end
		run.Stage = "Ready"; World.door(run.Jet, false)
		tell(run, "Cabin secured. Start engines when ready.", "Door"); broadcast(run)
	end)
end

function Charters.action(player, action, data)
	local run = Charters.Sessions[membership[player.UserId]]
	local p = profile(player)
	if action == "Accept" then return Charters.accept(player, data.Id) end
	if action == "Join" then
		if run then return false, "Leave your current charter first" end
		local host = Charters.Sessions[data.Id]
		if not host or host.Stage ~= "Preparation" then return false, "This charter is no longer boarding a crew" end
		local count = 0; for _ in host.Members do count += 1 end
		if count >= Config.Limits.MaxCrew then return false, "Crew is full" end
		host.Members[player.UserId] = { Name = player.DisplayName, Role = Config.Roles[count + 1] }
		membership[player.UserId] = host.Id; movePlayer(player, CFrame.new(host.Plot.Origin + Vector3.new(-30, 4, 45)))
		broadcast(host); return true, "Joined the crew · roles are flexible"
	end
	if action == "Recruit" or action == "Assign" or action == "Upgrade" or action == "Train" or action == "Theme" or action == "Badge" then
		if run and run.Stage ~= "Preparation" then return false, "Manage your operation between flights" end
		local ok, message = Profiles.transact(player.UserId, function(pr)
			if action == "Train" then return Domain.train(pr, data.Id, data.Skill, Config) end
			if action == "Theme" then
				if data.Id ~= "Porcelain" and data.Id ~= "Graphite" then return false, "Unknown finish" end
				pr.Hangar.Theme = data.Id; return true, "Hangar finish changed"
			end
			if action == "Badge" then
				local team = pr.Teams[data.Id]; local info = Config.Teams[data.Id]
				if not team or info.Category ~= "Cabin" or team.Runs < 5 or team.Badges.cabin_calm then return false, "Requires 5 completed charters with this cabin team" end
				if pr.Credits < Config.Economy.BadgeCost then return false, "Needs 900 credits" end
				pr.Credits -= Config.Economy.BadgeCost; team.Badges.cabin_calm = true; return true, "Unhurried equipped · +5 seconds of request patience"
			end
			return Domain.purchase(pr, action, data.Id, Config)
		end)
		World.upgrade(plots[player.UserId], profile(player)); push(player); return ok, message
	end
	if action == "Settings" then
		local ok, msg = Profiles.transact(player.UserId, function(pr)
			if data.Id == "Quality" and (data.Value == "High" or data.Value == "Low") then pr.Settings.Quality = data.Value
			elseif data.Id == "Motion" and type(data.Value) == "boolean" then pr.Settings.ReducedMotion = data.Value
			elseif data.Id == "Volume" and type(data.Value) == "number" then pr.Settings.Volume = math.clamp(data.Value, 0, 1)
			else return false, "Invalid setting" end
			return true, "Preference saved"
		end)
		push(player); return ok, msg
	end
	if not run then return false, "Accept a charter first" end
	if action == "Role" and run.Stage == "Preparation" then
		if not table.find(Config.Roles, data.Id) then return false, "Unknown role" end
		run.Members[player.UserId].Role = data.Id; broadcast(run); return true, "Role selected · anyone may assist"
	elseif action == "Prep" and run.Stage == "Preparation" then
		if not near(player, run.Plot.Model.CateringStation.CFrame.Position) then return false, "Walk to the cabin atelier counter" end
		if not table.find({ "Tea", "Coffee", "Water", "Warm", "Quiet", "Cool" }, data.Id) then return false, "Choose a cabin preference" end
		if table.find({ "Tea", "Coffee", "Water" }, data.Id) then run.Prep.Catering = data.Id else run.Prep.Mood = data.Id end
		broadcast(run); return true, "Cabin preference set"
	elseif action == "Board" and run.Stage == "Preparation" then
		if player.UserId ~= run.Owner then return false, "The host starts boarding" end
		if not run.Prep.Catering or not run.Prep.Mood then return false, "Choose catering and mood at the atelier" end
		if not near(player, run.Jet.CabinDoor.CFrame.Position, 22) then return false, "Walk to the aircraft boarding stair" end
		local ok, salary = Profiles.transact(run.Owner, function(pr)
			local paid, cost = Domain.salary(pr, math.floor(os.time() / Config.Economy.DaySeconds), Config)
			return paid, if paid then cost else "Assigned salaries exceed your balance. Assign starter teams or earn credits before departure."
		end)
		if not ok then return false, salary end
		run.Metrics.Prepared = (if run.Prep.Catering == run.Client.Preference then 1 else 0) + (if run.Prep.Mood == run.Client.Mood then 1 else 0)
		local count = 0; for _ in run.Members do count += 1 end
		run.Coop = if count > 1 then Config.Economy.CoopBonus else 0
		board(run); return true, "Assigned team salary charged: " .. salary
	elseif action == "Start" and run.Stage == "Ready" then
		if player.UserId ~= run.Owner then return false, "The host starts the flight" end
		run.Stage = "Flight"; run.Flight = FlightModel.new(Config.Flight); run.FlightStarted = os.clock()
		run.Tuning = Domain.crewTuning(profile(player)); run.Flight.Crew = run.Tuning.Pilot
		run.Destination = World.destination(run.Plot.Model, run.Plot.Origin, Config.Flight)
		run.Seated = {}; for id in run.Members do run.Seated[id] = true end
		World.weldNPC(run.NPC, run.Jet); World.weldNPC(run.CrewNPC, run.Jet)
		tell(run, "Runway clear. Increase throttle, reach 72 knots, then hold climb.", "Turbine"); broadcast(run); return true
	elseif action == "Cockpit" and run.Stage == "Flight" then
		if run.Pilot ~= player.UserId and not run.Flight.Autopilot and Players:GetPlayerByUserId(run.Pilot) then return false, "Captain has control. Use cruise autopilot for handover." end
		run.Pilot = player.UserId; run.Seated[player.UserId] = true
		movePlayer(player, run.Jet:GetPivot() * CFrame.new(-2, 4, -13)); return true, "Flight controls engaged"
	elseif action == "Autopilot" and run.Stage == "Flight" then
		if player.UserId ~= run.Pilot or run.Flight.Phase ~= "Cruise" then return false, "Autopilot is available to the pilot during cruise" end
		run.Flight.Autopilot = not run.Flight.Autopilot
		return true, if run.Flight.Autopilot then "Cruise autopilot active · cabin is available" else "Manual control"
	elseif action == "Cabin" and run.Stage == "Flight" then
		if run.Pilot == player.UserId and not run.Flight.Autopilot then return false, "Engage cruise autopilot before leaving flight controls" end
		run.Seated[player.UserId] = false; movePlayer(player, run.Jet:GetPivot() * CFrame.new(0, 4, -6)); return true, "Cabin mode · use the galley to serve"
	elseif action == "Gear" and run.Stage == "Flight" then
		if player.UserId ~= run.Pilot or run.Flight.Phase == "Taxi" then return false, "Gear control is available after takeoff" end
		run.Flight.Gear = not run.Flight.Gear; World.gear(run.Jet, run.Flight.Gear); tell(run, if run.Flight.Gear then "Gear down" else "Gear up", "Gear"); return true
	elseif action == "GoAround" and run.Stage == "Flight" then
		if player.UserId ~= run.Pilot then return false, "Only the pilot can request a go-around" end
		FlightModel.goAround(run.Flight, Config.Flight); World.gear(run.Jet, true); return true, "Safe go-around · align with the runway"
	elseif action == "Service" and run.Stage == "Flight" then
		if not run.Request then return false, "Your client is comfortable" end
		if not near(player, run.Jet.Galley.CFrame.Position, 12) then return false, "Walk to the cabin galley" end
		if run.Seated[player.UserId] then return false, "Switch to cabin mode to serve" end
		run.Metrics.Served += 1; run.Request = nil; run.NPC:SetAttribute("Mood", "Delighted")
		World.service(run)
		tell(run, "Thank you. That was just what I needed.", "Service"); return true
	elseif action == "Arrival" and run.Stage == "Arrival" then
		if not table.find({ "Covered", "Open", "Baggage", "Umbrella", "Decoy" }, data.Id) then return false, "Unknown arrival action" end
		if not near(player, run.Jet:GetPivot().Position, 65) then return false, "Stay with your client at the aircraft" end
		if data.Id == "Covered" or data.Id == "Open" then run.Arrival.Car = data.Id else run.Arrival[data.Id] = true end
		World.arrivalAction(run, data.Id)
		broadcast(run); return true, "Arrival detail arranged"
	elseif action == "Finish" and run.Stage == "Arrival" then
		if not run.Arrival.Car or not run.Arrival.Baggage then return false, "Arrange a car and transfer the baggage first" end
		run.Metrics.Discretion = 4 + (if run.Arrival.Car == "Covered" then 8 else 0) + (if run.Arrival.Umbrella then 4 else 0) + (if run.Arrival.Decoy then 4 else 0)
		run.Stage = "Handover"; broadcast(run)
		World.escort(run, function() if run.Stage == "Handover" then finish(run) end end)
		return true, "Your client is being escorted to the car"
	elseif action == "RetrySave" and run.Stage == "Results" then
		local member = run.Members[player.UserId]
		if member.Paid then return true, "Reward already saved" end
		local ok, msg = Profiles.transact(player.UserId, function(pr) Domain.reward(pr, run.Id, run.Result, member.Role); return true, "Reward saved" end)
		member.Paid = ok; push(player); return ok, msg
	elseif action == "Return" and run.Stage == "Results" then
		if not run.Members[player.UserId].Paid then return false, "Save pending. Retry reward save before returning." end
		if player.UserId == run.Owner then
			for _, member in run.Members do if not member.Paid then return false, "A crewmate's reward is still saving. Keep the charter open." end end
		end
		Charters.leave(player); return true, "Welcome back to your hangar"
	elseif action == "Leave" and run.Stage == "Preparation" then Charters.leave(player); return true end
	return false, "That action is unavailable in this phase"
end

function Charters.leave(player)
	lockControls(player, false)
	local run = Charters.Sessions[membership[player.UserId]]
	membership[player.UserId] = nil
	if run then
		run.Members[player.UserId] = nil
		if player.UserId == run.Owner or not next(run.Members) then
			run.Stage = "Closed"
			for id in run.Members do
				membership[id] = nil; local guest = Players:GetPlayerByUserId(id)
				if guest and plots[id] then lockControls(guest, false); movePlayer(guest, plots[id].Spawn.CFrame + Vector3.new(0, 4, 0)); push(guest) end
			end
			if run.NPC then run.NPC:Destroy() end; if run.CrewNPC then run.CrewNPC:Destroy() end
			if run.Destination then run.Destination:Destroy() end
			run.Jet:PivotTo(CFrame.new(run.Plot.Origin + Vector3.new(0, 5.4, 12)))
			World.door(run.Jet, true); World.gear(run.Jet, true)
			Charters.Sessions[run.Id] = nil
		else broadcast(run) end
	end
	if plots[player.UserId] then movePlayer(player, plots[player.UserId].Spawn.CFrame + Vector3.new(0, 4, 0)) end
	push(player)
end

function Charters.removePlayer(player)
	Charters.leave(player)
	local plot = plots[player.UserId]
	if plot then slots[plot.Index] = nil; plot.Model:Destroy(); plots[player.UserId] = nil end
	Profiles.release(player.UserId)
end

function Charters.input(player, input)
	local run = Charters.Sessions[membership[player.UserId]]
	if not run or run.Stage ~= "Flight" or run.Pilot ~= player.UserId or not run.Seated[player.UserId] then return end
	if os.clock() - run.LastInput < 0.075 then return end
	run.LastInput = os.clock(); run.Input = input
end

local function tickFlight(run, dt)
	local f = run.Flight
	if os.clock() - run.LastInput > 0.6 then run.Input = {} end
	local event = FlightModel.step(f, run.Input, dt, Config.Flight)
	if event then
		if event == "Cruise" then tell(run, "Cruise established. Engage autopilot to visit your client.", "Service")
		elseif event == "Approach" then
			for id in run.Members do run.Seated[id] = true end
			tell(run, "Approach. Autopilot disengaged. Gear down, speed 45–88, align with the centerline.", "Gear")
		elseif event == "Recovery" then tell(run, "Safe go-around. Reduce bank and follow the landing guide.", "Gear"); World.gear(run.Jet, true)
		elseif event == "Takeoff" then tell(run, "Positive climb. Raise gear and climb to 260 feet.", "Gear")
		elseif event == "Landed" then
			run.Metrics.HardLanding = if math.abs(f.VerticalSpeed) > 9 then 1 else 0
			f.Z = Config.Flight.RunwayStart + 1050; f.X = -105; f.Altitude = Config.Flight.GearHeight; f.Pitch = 0; f.Bank = 0
			run.Stage = "Arrival"; run.ArrivalStarted = os.clock(); run.Input = {}; World.door(run.Jet, true)
			tell(run, "Welcome to Riviera. Arrange a covered car and protect your client's arrival.", "Touchdown")
			broadcast(run)
		end
	end
	local elapsed = os.clock() - run.FlightStarted
	if run.Stage == "Flight" and f.Phase == "Cruise" and run.RequestIndex < 3 and elapsed > 35 + run.RequestIndex * 28 and not run.Request then
		run.RequestIndex += 1
		local pr = Profiles.get(run.Owner); local team = pr.Teams[pr.Assigned.Cabin]
		local grace = (if team.Badges.cabin_calm then 5 else 0) + pr.Hangar.Operations * 4 + run.Tuning.Patience
		run.Request = { Text = ({ "A fresh " .. string.lower(run.Client.Preference) .. ", please.", "Could you adjust the reading light?", "A light snack before arrival, please." })[run.RequestIndex],
			Expires = os.time() + run.Client.Patience + grace, Started = os.clock() }
		run.NPC:SetAttribute("Mood", "Waiting"); tell(run, run.Request.Text, "Service")
	end
	if run.Request then
		if os.time() >= run.Request.Expires then run.Metrics.Missed += 1; run.Request = nil; tell(run, "The client request expired.", "Service")
		elseif os.clock() - run.Request.Started > run.Tuning.ServiceDelay then
			-- NPC team is competent: a partial contribution, never a perfect automatic score.
			run.Metrics.Served += run.Tuning.AutoServiceCredit; run.Request = nil; World.service(run); tell(run, "Your cabin team handled the request. Manual service earns full credit.", "Service")
		end
	end
end

function Charters.start(eventRemote)
	remote = eventRemote
	local accumulator, snapshot, movement = 0, 0, 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += math.min(dt, 0.1); snapshot += dt; movement += dt
		while accumulator >= Config.Flight.Step do
			for _, run in Charters.Sessions do if run.Stage == "Flight" then tickFlight(run, Config.Flight.Step) end end
			accumulator -= Config.Flight.Step
		end
		if movement >= 0.1 then
			movement = 0
			for _, run in Charters.Sessions do
				if run.Flight and (run.Stage == "Flight" or run.Stage == "Arrival") then
					local f = run.Flight; local old = run.Jet:GetPivot()
					local target = CFrame.new(run.Plot.Origin + Vector3.new(f.X, f.Altitude, -220 - f.Z)) * CFrame.Angles(math.rad(f.Pitch), 0, math.rad(-f.Bank))
					run.Jet.PrimaryPart.CFrame = target
					local delta = target * old:Inverse()
					for id in run.Members do
						local p = Players:GetPlayerByUserId(id); local c = p and p.Character
						if c then
							lockControls(p, run.Seated and run.Seated[id] and run.Stage == "Flight")
							if run.Seated and run.Seated[id] and run.Stage == "Flight" then
								movePlayer(p, target * CFrame.new(if id == run.Pilot then -2 else 0, 4, if id == run.Pilot then -13 else -6))
							elseif (c:GetPivot().Position - old.Position).Magnitude < 48 then movePlayer(p, delta * c:GetPivot())
							else movePlayer(p, target * CFrame.new(0, 4, -6)) end
						end
					end
				end
			end
		end
		if snapshot >= 1 / Config.Flight.SnapshotHz then
			snapshot = 0
			for _, run in Charters.Sessions do
				if run.Stage == "Flight" then
					for id in run.Members do send(Players:GetPlayerByUserId(id), "Flight", publicRun(run)) end
				elseif run.Stage == "Arrival" and not run.Arrival.Baggage and os.clock() - run.ArrivalStarted > run.Tuning.ArrivalAssistDelay then
					run.Arrival.Baggage = true; World.arrivalAction(run, "Baggage"); tell(run, "Your security team has transferred the baggage.", "Service"); broadcast(run)
				end
			end
		end
	end)
end
return Charters

