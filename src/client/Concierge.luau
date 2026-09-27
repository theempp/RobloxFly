local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Domain = require(Shared.Domain)
local D = require(script.Parent.Design)
local P = D.P
local Concierge = {}
local player = Players.LocalPlayer
local gui, phone, content, status, account, tabs, closeButton, viewTitle, hint, toast
local page, snapshot, send = "Charters", nil, nil
local expiryLabels = {}
local function credits(n) return string.format("%s CR", tostring(math.floor(n or 0))) end
local function action(name, data) send(name, data or {}) end
local function text(parent, value, size, color, height, font) return D.text(parent, value, size or 14, color, height, font) end

local function cardTitle(parent, eyebrow, title, sub)
	text(parent, eyebrow, 11, P.Champagne, 18, Enum.Font.RobotoMono)
	text(parent, title, 24, P.Porcelain, 32, Enum.Font.GothamBold)
	if sub then text(parent, sub, 13, P.Lagoon, 30) end
end

local function charterPage()
	local run = snapshot.Run
	if run then
		local c = D.card(content)
		cardTitle(c, string.upper(run.Stage) .. "  /  ASTER L6", run.Client.Name, run.Client.Title)
		text(c, "ASTER BASE  ─────────  RVA\nMonaco · Riviera", 17, P.Porcelain, 48)
		text(c, credits(run.Offer.Fee) .. " base  ·  " .. run.Client.Party .. " guests\nCo-op: +10% with a crew · each player receives a full award", 13, P.Lagoon, 46)
		D.rule(c)
		if run.Stage == "Preparation" then
			text(c, "CLIENT BRIEF", 11, P.Champagne)
			text(c, run.Client.Preference .. " catering  /  " .. run.Client.Mood .. " cabin\nCovered car · discretion matters", 15, P.Porcelain, 46)
			text(c, "Walk to the cabin atelier, then choose preferences below. Board at the port-side stair.", 14, P.Porcelain, 52)
			for _, group in { { "Tea", "Coffee", "Water" }, { "Warm", "Quiet", "Cool" } } do
				for _, option in group do
					local selected = run.Prep.Catering == option or run.Prep.Mood == option
					D.button(c, (if selected then "✓  " else "") .. option, function() action("Prep", { Id = option }) end, selected)
				end
			end
			local salary = 0
			for _, id in snapshot.Profile.Assigned do salary += Config.Teams[id].Salary end
			text(c, "Assigned salary: " .. credits(salary) .. " / game day (20 min). Charged once before boarding. Benched teams cost nothing.", 12, P.Lagoon, 54)
			D.button(c, "Board at aircraft", function() action("Board") end, true)
			D.button(c, "Leave charter", function() action("Leave") end)
		elseif run.Stage == "Boarding" then
			text(c, "Your client is boarding. The crew is securing the cabin.", 16, P.Porcelain, 60)
		elseif run.Stage == "Ready" then
			text(c, "Runway departure\nE / Q throttle · ↑ / ↓ pitch · ← / → bank\nGamepad: stick + triggers\nTouch flight controls appear after engine start.", 14, P.Porcelain, 110)
			D.button(c, "Start engines · take runway", function() action("Start"); phone.Visible = false end, true)
		elseif run.Stage == "Flight" then
			text(c, "Fly the departure, then engage cruise autopilot to serve your client. Autopilot disengages for approach.", 16, P.Porcelain, 84)
			D.button(c, "Return to flight", function() phone.Visible = false end, true)
		elseif run.Stage == "Arrival" then
			text(c, "A quiet arrival", 20, P.Porcelain, 30)
			text(c, "Arrange the car and baggage, then protect your client's path from photographers.", 14, P.Lagoon, 56)
			for _, opt in { { "Covered", "Covered car · sheltered path" }, { "Open", "Open apron car · exposed path" }, { "Baggage", "Transfer baggage" }, { "Umbrella", "Escort with umbrella" }, { "Decoy", "Direct photographers to decoy" } } do
				local selected = run.Arrival.Car == opt[1] or run.Arrival[opt[1]]
				D.button(c, (if selected then "✓  " else "") .. opt[2], function() action("Arrival", { Id = opt[1] }) end, selected)
			end
			D.button(c, "Complete the handover", function() action("Finish") end, true)
		elseif run.Stage == "Handover" then
			text(c, "Your client is being escorted to the car. The concierge is preparing your result.", 16, P.Porcelain, 80)
		elseif run.Stage == "Results" then
			Concierge.results(c, run)
		end
		return
	end
	text(content, "YOUR NEXT DEPARTURE", 11, P.Champagne, 20, Enum.Font.RobotoMono)
	text(content, "A remarkable journey\nstarts with a call.", 25, P.Porcelain, 68, Enum.Font.GothamBold)
	for _, offer in snapshot.Offers do
		local client = Config.Clients[offer.Client]; local c = D.card(content)
		cardTitle(c, "RIVIERA  /  PRIVATE CHARTER", client.Name, client.Title)
		text(c, "AST  ━━━━━━━━━━━━━  RVA", 18, P.Champagne, 30, Enum.Font.RobotoMono)
		text(c, client.Party .. " guests   /   680 nm   /   ~8 min charter", 13, P.Porcelain, 28)
		text(c, credits(offer.Fee), 26, P.Porcelain, 34, Enum.Font.GothamBold)
		text(c, "Base fee × your rating · +10% with friends", 12, P.Lagoon)
		local label = text(c, "", 12, P.Champagne)
		table.insert(expiryLabels, { Label = label, Expires = offer.Expires })
		D.button(c, "Accept charter", function() action("Accept", { Id = offer.Id }) end, true)
	end
	D.button(content, "Refresh offers", function() action("Sync") end)
end

function Concierge.results(c, run)
	local result = run.Result
	if not result then return end
	text(c, result.Label, 26, P.Champagne, 38, Enum.Font.GothamBold)
	text(c, tostring(result.Score) .. " / 100", 40, P.Porcelain, 54, Enum.Font.RobotoMono)
	for _, row in result.Breakdown do
		text(c, row.Name .. "    " .. row.Value .. " / " .. row.Max, 15, P.Porcelain)
		local rail = D.make("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = P.Graphite, BorderSizePixel = 0 }, c)
		D.make("Frame", { Size = UDim2.fromScale(row.Value / row.Max, 1), BackgroundColor3 = P.Champagne, BorderSizePixel = 0 }, rail)
		text(c, row.Cause, 11, P.Lagoon, 26)
	end
	D.rule(c)
	text(c, credits(result.Payout), 30, P.Champagne, 44, Enum.Font.GothamBold)
	text(c, credits(result.BaseFee) .. " × " .. result.Multiplier .. " rating × " .. (1 + result.Coop) .. " crew\n+" .. result.XP .. " XP  ·  +1 training token", 13, P.Porcelain, 46)
	local paid = false; for _, m in run.Members do if m.UserId == player.UserId then paid = m.Paid end end
	text(c, if paid then (if snapshot.Profile.SessionOnly then "Saved for this Studio session" else "Progress saved") else "Reward save pending · stay in this session", 13, if paid then P.Green else P.Red, 34)
	D.button(c, if paid then "Return to your hangar" else "Retry reward save", function() action(if paid then "Return" else "RetrySave") end, true)
end

local function crewPage()
	text(content, "PEOPLE MAKE THE JOURNEY", 11, P.Champagne, 20, Enum.Font.RobotoMono)
	text(content, "Your crew", 28, nil, 42, Enum.Font.GothamBold)
	local pr = snapshot.Profile
	if snapshot.Run then
		local c = D.card(content); text(c, "Flight roles · anyone can assist", 18)
		for _, member in snapshot.Run.Members do text(c, member.Name .. " · " .. member.Role, 14) end
		if snapshot.Run.Stage == "Preparation" then
			for _, role in Config.Roles do D.button(c, role, function() action("Role", { Id = role }) end) end
		end
	end
	local ids = {}; for id in pr.Teams do table.insert(ids, id) end; table.sort(ids)
	for _, id in ids do
		local info, owned = Config.Teams[id], pr.Teams[id]; local c = D.card(content)
		cardTitle(c, string.upper(info.Category) .. "  /  " .. info.Grade, info.Name)
		text(c, Domain.overall(owned.Skills) .. " overall · " .. credits(info.Salary) .. " per game day", 15, P.Champagne, 34)
		text(c, "Skills have equal weight. Training costs 300 CR + 1 token for +2, capped at 85.", 12, P.Lagoon, 46)
		text(c, if info.Category == "Cabin" then "Speed: NPC service timing. Reading and composure: client patience. Catering: NPC service quality."
			elseif info.Category == "Pilot" then "Takeoff and landing: pitch response. Safety: bank damping. Cruise and navigation: autopilot tracking."
			else "Logistics: automatic baggage timing. Other security skills are reserved for expanded encounters.", 12, P.Lagoon, 64)
		local skills = {}; for skill in owned.Skills do table.insert(skills, skill) end; table.sort(skills)
		for _, skill in skills do
			local implemented = info.Category ~= "Security" or skill == "Logistics"
			D.button(c, skill .. "  " .. owned.Skills[skill] .. (if implemented then "   /   Train +2" else "  ·  expansion pending"), function() action("Train", { Id = id, Skill = skill }) end, false, implemented)
		end
		local assigned = pr.Assigned[info.Category] == id
		D.button(c, if assigned then "✓ Assigned" else "Assign · " .. credits(info.Salary) .. "/day", function() action("Assign", { Id = id }) end, assigned)
		if info.Category == "Cabin" then
			text(c, "Unhurried badge · " .. owned.Runs .. "/5 charters\n+5 seconds client patience · 900 CR · one badge slot", 12, P.Lagoon, 48)
			D.button(c, if owned.Badges.cabin_calm then "✓ Unhurried equipped" else "Unlock Unhurried", function() action("Badge", { Id = id }) end, false, not owned.Badges.cabin_calm)
		end
	end
	local c = D.card(content); text(c, "Join an open charter", 20)
	if #snapshot.Hosts == 0 then text(c, "No crews waiting in this server. Friends can join your charter before boarding.", 14, P.Lagoon, 62) end
	for _, host in snapshot.Hosts do D.button(c, "Join " .. host.Name, function() action("Join", { Id = host.Id }); page = "Charters" end) end
end

local function hangarPage()
	local pr = snapshot.Profile
	local c = D.card(content); cardTitle(c, "YOUR AIRCRAFT", "Aster L6", "Light jet · six passenger seats")
	text(c, "2,100 nm range  /  1,300 fuel\n88 handling  /  72 comfort", 16, P.Porcelain, 54)
	text(c, "Your starter is eligible for every available Riviera charter.", 13, P.Lagoon, 44)
	local show = D.card(content); cardTitle(show, "SHOWPIECE", "A space of your own")
	text(show, "Finishes and display pieces change appearance. Charter scores come from your service and flying.", 14, P.Lagoon, 58)
	for _, theme in { "Porcelain", "Graphite" } do D.button(show, theme .. " finish · free", function() action("Theme", { Id = theme }) end, pr.Hangar.Theme == theme) end
	D.button(show, if pr.Hangar.Showpiece > 0 then "✓ Gallery finish installed" else "Gallery finish + sculpture · 1,400 CR", function() action("Upgrade", { Id = "Showpiece" }) end, false, pr.Hangar.Showpiece == 0)
	local ops = D.card(content); cardTitle(ops, "OPERATIONS", "Service atelier")
	text(ops, "Cabin preparation facility. Clients allow 4 extra seconds for each request.", 14, P.Lagoon, 52)
	D.button(ops, if pr.Hangar.Operations > 0 then "✓ Atelier installed" else "Install atelier · 1,800 CR", function() action("Upgrade", { Id = "Operations" }) end, true, pr.Hangar.Operations == 0)
end

local function storePage()
	text(content, "RECRUITMENT  /  GUARANTEED OFFERS", 11, P.Champagne, 24, Enum.Font.RobotoMono)
	text(content, "Build your reputation.", 24, nil, 42, Enum.Font.GothamBold)
	text(content, "Permanent teams. Visible prices. No random rewards. Standard recruitment remains available every day.", 14, P.Lagoon, 62)
	local ids = { "cabin_silk", "pilot_horizon", "security_velvet" }
	local featured = ids[(math.floor(os.time() / 86400) % #ids) + 1]
	for _, id in ids do
		local info = Config.Teams[id]; local c = D.card(content)
		cardTitle(c, (if id == featured then "TODAY'S SPOTLIGHT  /  " else "") .. string.upper(info.Category), info.Name)
		text(c, info.Grade .. " · " .. Domain.overall(info.Skills) .. " overall\nSalary " .. credits(info.Salary) .. " / 20-minute game day", 14, P.Champagne, 52)
		local statLines = {}; for skill, value in info.Skills do table.insert(statLines, skill .. " " .. value) end; table.sort(statLines)
		text(c, table.concat(statLines, "  ·  "), 12, P.Porcelain, 54)
		D.button(c, if snapshot.Profile.Teams[id] then "✓ Owned permanently" else "Recruit · " .. credits(info.Price), function() action("Recruit", { Id = id }) end, true, not snapshot.Profile.Teams[id])
	end
	local c = D.card(content); text(c, "Credit purchases", 20); text(c, "Unavailable in this development build. Earn credits by flying charters.", 14, P.Lagoon, 56)
	D.button(c, "Robux purchases unavailable", function() end, false, false)
end

local function settingsPage()
	local c = D.card(content); cardTitle(c, "MAKE YOURSELF COMFORTABLE", "Preferences")
	local prefs = snapshot.Profile.Settings
	D.button(c, "Quality: " .. prefs.Quality .. " · toggle", function() action("Settings", { Id = "Quality", Value = if prefs.Quality == "High" then "Low" else "High" }) end)
	D.button(c, "Reduced motion: " .. (if prefs.ReducedMotion then "On" else "Off"), function() action("Settings", { Id = "Motion", Value = not prefs.ReducedMotion }) end)
	D.button(c, "Sound: " .. (if prefs.Volume == 0 then "Muted" else "55%") .. " · toggle", function() action("Settings", { Id = "Volume", Value = if prefs.Volume > 0 then 0 else 0.55 }) end)
	text(c, "Critical cues always have captions. Low quality reduces decorative lights, shadows and particles. Cinematics always have a skip control.", 14, P.Lagoon, 90)
	D.rule(c)
	text(c, "Flight controls\nE / Q: throttle\n↑ / ↓: climb / descend\n← / →: bank\nP: cruise autopilot   G: gear\nC: cabin   F: flight controls\nGamepad: left stick, R2 / L2\nTouch: use the flight pad", 14, P.Porcelain, 190)
end

function Concierge.render()
	if not snapshot or not snapshot.Profile then return end
	D.clear(content); expiryLabels = {}
	account.Text = credits(snapshot.Profile.Credits) .. "   /   " .. snapshot.Profile.Tokens .. " TOKENS"
	viewTitle.Text = string.upper(page)
	status.Text = if snapshot.Profile.SessionOnly then "STUDIO · SESSION DATA" else "PRIVATE JET CHARTER TYCOON"
	if page == "Charters" then charterPage()
	elseif page == "Crew" then crewPage()
	elseif page == "Hangar" then hangarPage()
	elseif page == "Store" then storePage()
	elseif page == "Settings" then settingsPage() end
end

function Concierge.init(callback)
	send = callback
	gui = D.make("ScreenGui", { Name = "AsterConcierge", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
	local top = D.make("Frame", { BackgroundColor3 = P.Graphite, BackgroundTransparency = 0.06, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 54) }, gui)
	local brand = text(top, "A S T E R", 19, P.Champagne, 28, Enum.Font.GothamBold); brand.Position = UDim2.fromOffset(20, 3); brand.Size = UDim2.fromOffset(160, 28)
	status = text(top, "PRIVATE JET CHARTER TYCOON", 9, P.Lagoon, 16, Enum.Font.RobotoMono); status.Position = UDim2.fromOffset(20, 32); status.Size = UDim2.fromOffset(235, 16)
	account = text(top, "CONNECTING", 11, P.Porcelain, 54, Enum.Font.RobotoMono); account.Size = UDim2.new(0.5, -20, 1, 0); account.Position = UDim2.fromScale(0.5, 0); account.TextXAlignment = Enum.TextXAlignment.Right
	phone = D.make("Frame", { Name = "ConciergePhone", BackgroundColor3 = P.Graphite, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 66), Size = UDim2.fromOffset(414, 600) }, gui)
	D.corner(phone, 18); D.make("UIStroke", { Color = P.Champagne, Transparency = 0.55, Thickness = 1 }, phone)
	viewTitle = text(phone, "CHARTERS", 12, P.Champagne, 50, Enum.Font.RobotoMono); viewTitle.Position = UDim2.fromOffset(20, 0); viewTitle.Size = UDim2.new(1, -80, 0, 50)
	closeButton = D.button(phone, "×", function() phone.Visible = false end); closeButton.Size = UDim2.fromOffset(48, 42); closeButton.Position = UDim2.new(1, -56, 0, 5)
	content = D.make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -28, 1, -124), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = P.Champagne }, phone)
	D.stack(content, 14)
	tabs = D.make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -58), Size = UDim2.new(1, -24, 0, 52), CanvasSize = UDim2.fromOffset(430, 0), ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X }, phone)
	for i, name in { "Charters", "Crew", "Hangar", "Store", "Settings" } do
		local b = D.button(tabs, name, function() page = name; content.CanvasPosition = Vector2.zero; Concierge.render() end)
		b.Position = UDim2.fromOffset((i - 1) * 86, 0); b.Size = UDim2.fromOffset(82, 48); b.TextSize = 12
	end
	local opener = D.button(gui, "PHONE", function() phone.Visible = not phone.Visible; if phone.Visible then action("Sync") end end, true)
	opener.AnchorPoint = Vector2.new(0, 1); opener.Position = UDim2.new(0, 18, 1, -18); opener.Size = UDim2.fromOffset(108, 48)
	hint = text(gui, "Loading your hangar…", 14, P.Porcelain, 64); hint.Position = UDim2.new(0, 18, 1, -140); hint.Size = UDim2.fromOffset(330, 64)
	hint.BackgroundColor3 = P.Graphite; hint.BackgroundTransparency = 0.12; D.corner(hint, 10); D.padding(hint, 10)
	toast = text(gui, "", 14, P.Porcelain, 60); toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 64); toast.Size = UDim2.new(0.65, 0, 0, 60)
	toast.BackgroundColor3 = P.Graphite; toast.BackgroundTransparency = 0.03; toast.Visible = false; toast.ZIndex = 20; D.corner(toast); D.padding(toast, 10)
	local function resize()
		local size = workspace.CurrentCamera.ViewportSize
		phone.Size = UDim2.fromOffset(math.min(414, size.X - 24), math.max(240, size.Y - 150))
		hint.Visible = size.X > 750 or not phone.Visible
		hint.Size = UDim2.fromOffset(math.min(330, size.X - 36), 64)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); phone:GetPropertyChangedSignal("Visible"):Connect(resize); resize()
	task.spawn(function() while gui.Parent do
		for _, entry in expiryLabels do if entry.Label.Parent then entry.Label.Text = "Offer expires in " .. math.max(0, entry.Expires - os.time()) .. "s" end end
		task.wait(1)
	end end)
	return gui
end

function Concierge.state(data)
	local previous = snapshot and snapshot.Run
	snapshot = data
	if data.Run and (not previous or previous.Stage ~= data.Run.Stage) then
		if data.Run.Stage ~= "Flight" then phone.Visible = true; page = "Charters" end
	end
	if not data.Run then hint.Text = "Open your phone to choose a charter." else
		local run = data.Run
		hint.Text = ({ Preparation = "Prepare preferences at the atelier, then walk to the aircraft stair.", Boarding = "Your client is boarding. Welcome aboard.", Ready = "Cabin secured. Start engines from your phone.", Flight = "Fly the route · P autopilot · G gear · C cabin", Arrival = "Open your phone to arrange a discreet arrival.", Results = "Your charter rating and saved reward are on your phone." })[run.Stage] or ""
	end
	Concierge.render()
end
function Concierge.flight(run) if snapshot then snapshot.Run = run end end
function Concierge.show(name) page = name or "Charters"; phone.Visible = true; Concierge.render() end
function Concierge.visible() return phone.Visible end
function Concierge.visibilityChanged(callback)
	phone:GetPropertyChangedSignal("Visible"):Connect(function() callback(phone.Visible) end)
	callback(phone.Visible)
end
function Concierge.notice(message)
	toast.Text = message.Text; toast.TextColor3 = if message.Error then P.Red else P.Porcelain; toast.Visible = true
	local stamp = os.clock(); toast:SetAttribute("Stamp", stamp)
	task.delay(4, function() if toast:GetAttribute("Stamp") == stamp then toast.Visible = false end end)
end
return Concierge
