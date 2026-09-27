local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local D = require(script.Parent.Design)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local P = D.P
local Controller = {}
local player = Players.LocalPlayer
local run, hud, instruments, guidance, requestLabel, controlPad, actionPad
local input = { Bank = 0, Pitch = 0, Throttle = 0 }
local held = {}; local analog = Vector2.zero; local triggers = 0
local send, remote, cancelCamera
local obscured = false
local function active()
	return run and run.Stage == "Flight" and run.Pilot == player.UserId and run.Seated and run.Seated[player.UserId]
end
function Controller.hasControl() return active() end
function Controller.run() return run end
function Controller.setObscured(value)
	obscured = value
	if hud then hud.Visible = not obscured and run ~= nil and run.Stage == "Flight" end
end

function Controller.init(gui, callback, inputRemote, cancel)
	send, remote, cancelCamera = callback, inputRemote, cancel
	hud = D.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, gui)
	instruments = D.text(hud, "", 16, P.Porcelain, 106, Enum.Font.RobotoMono)
	instruments.Position = UDim2.fromOffset(18, 70); instruments.Size = UDim2.fromOffset(310, 106)
	instruments.BackgroundColor3 = P.Graphite; instruments.BackgroundTransparency = 0.08; D.corner(instruments); D.padding(instruments, 12)
	guidance = D.text(hud, "", 13, P.Champagne, 68)
	guidance.Position = UDim2.fromOffset(18, 182); guidance.Size = UDim2.fromOffset(310, 68); guidance.BackgroundColor3 = P.Graphite; guidance.BackgroundTransparency = 0.08; D.corner(guidance); D.padding(guidance, 12)
	requestLabel = D.text(hud, "", 14, P.Porcelain, 68)
	requestLabel.Position = UDim2.new(0.5, -160, 0, 70); requestLabel.Size = UDim2.fromOffset(320, 68); requestLabel.BackgroundColor3 = P.Graphite; requestLabel.BackgroundTransparency = 0.05; D.corner(requestLabel); D.padding(requestLabel, 12)
	actionPad = D.make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -18), Size = UDim2.fromOffset(164, 244), CanvasSize = UDim2.fromOffset(0, 298), ScrollBarThickness = 2 }, hud)
	D.stack(actionPad, 5)
	for _, entry in { { "Autopilot", "P · Autopilot" }, { "Gear", "G · Gear" }, { "Cabin", "C · Cabin" }, { "Cockpit", "F · Controls" }, { "Service", "Serve request" }, { "GoAround", "Go around" } } do
		D.button(actionPad, entry[2], function() callback(entry[1], {}); cancel() end)
	end
	controlPad = D.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 140, 1, -18), Size = UDim2.fromOffset(198, 166) }, hud)
	for i, entry in { { "Up", "↑", Enum.KeyCode.Up }, { "Down", "↓", Enum.KeyCode.Down }, { "Left", "←", Enum.KeyCode.Left }, { "Right", "→", Enum.KeyCode.Right }, { "ThrottleUp", "+", Enum.KeyCode.E }, { "ThrottleDown", "−", Enum.KeyCode.Q } } do
		local b = D.button(controlPad, entry[2], function() end)
		b.Size = UDim2.fromOffset(60, 48); b.Position = UDim2.fromOffset(((i - 1) % 3) * 66, math.floor((i - 1) / 3) * 54)
		b.InputBegan:Connect(function(event) if event.UserInputType == Enum.UserInputType.Touch or event.UserInputType == Enum.UserInputType.MouseButton1 then held[entry[1]] = true; cancel() end end)
		b.InputEnded:Connect(function(event) if event.UserInputType == Enum.UserInputType.Touch or event.UserInputType == Enum.UserInputType.MouseButton1 then held[entry[1]] = nil end end)
		ContextActionService:BindAction("Aster" .. entry[1], function(_, state)
			if not active() or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			held[entry[1]] = state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change
			if held[entry[1]] then cancel() end
			return Enum.ContextActionResult.Sink
		end, false, entry[3])
	end
	for _, entry in { { "Autopilot", Enum.KeyCode.P }, { "Gear", Enum.KeyCode.G }, { "Cabin", Enum.KeyCode.C }, { "Cockpit", Enum.KeyCode.F } } do
		ContextActionService:BindAction("Aster" .. entry[1], function(_, state)
			if not run or run.Stage ~= "Flight" or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			if state == Enum.UserInputState.Begin then callback(entry[1], {}); cancel() end
			return Enum.ContextActionResult.Sink
		end, false, entry[2])
	end
	ContextActionService:BindAction("AsterStick", function(_, state, event)
		if not active() then analog = Vector2.zero; return Enum.ContextActionResult.Pass end
		analog = if state == Enum.UserInputState.End then Vector2.zero else Vector2.new(event.Position.X, event.Position.Y)
		if analog.Magnitude > 0.1 then cancel() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Thumbstick1)
	ContextActionService:BindAction("AsterTriggers", function(_, state, event)
		if not active() then triggers = 0; return Enum.ContextActionResult.Pass end
		triggers = if state == Enum.UserInputState.End then 0 elseif event.KeyCode == Enum.KeyCode.ButtonR2 then event.Position.Z else -event.Position.Z
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
	UserInputService.WindowFocusReleased:Connect(function() table.clear(held); analog = Vector2.zero; triggers = 0 end)
	local timer = 0
	RunService.Heartbeat:Connect(function(dt)
		timer += dt
		if timer < 0.1 then return end; timer = 0
		if active() then
			input.Bank = math.clamp((if held.Right then 1 else 0) - (if held.Left then 1 else 0) + analog.X, -1, 1)
			input.Pitch = math.clamp((if held.Up then 1 else 0) - (if held.Down then 1 else 0) + analog.Y, -1, 1)
			input.Throttle = math.clamp((if held.ThrottleUp then 1 else 0) - (if held.ThrottleDown then 1 else 0) + triggers, -1, 1)
			remote:FireServer(input)
		end
	end)
	local function resize()
		local width = workspace.CurrentCamera.ViewportSize.X
		local small = width < 700
		instruments.Size = UDim2.fromOffset(if small then 230 else 310, 106)
		guidance.Size = UDim2.fromOffset(if small then 230 else 310, 68)
		requestLabel.Position = if small then UDim2.fromOffset(18, 258) else UDim2.new(0.5, -160, 0, 70)
		requestLabel.Size = UDim2.fromOffset(if small then 230 else 320, 68)
		controlPad.Position = UDim2.new(0, if small then 16 else 140, 1, if small then -76 else -18)
		actionPad.Size = UDim2.fromOffset(if small then 138 else 164, if small then 160 else 244)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
end

function Controller.update(newRun)
	run = newRun
	hud.Visible = not obscured and run ~= nil and run.Stage == "Flight"
	if not hud.Visible then table.clear(held); return end
	local f = run.Flight
	if not f then return end
	controlPad.Visible = active()
	instruments.Text = string.format("%s  /  %s\n%03d KTS     %04d FT\nTHR %d%%   GEAR %s\nROUTE %d%%", string.upper(f.Phase), if f.Autopilot then "AUTO" else "MANUAL", f.Speed, math.max(0, f.Altitude - 5.4), f.Throttle * 100, if f.Gear then "DOWN" else "UP", math.clamp(f.Z / Config.Flight.RunwayEnd * 100, 0, 100))
	if f.Phase == "Taxi" then guidance.Text = "E / +: increase throttle\nAt 72 knots, hold ↑ to rotate."
	elseif f.Phase == "Climb" then guidance.Text = "Climb to 260 ft · G to retract gear\nLevel off with neutral pitch."
	elseif f.Phase == "Cruise" then guidance.Text = "P: cruise autopilot · C: cabin\nServe requests at the galley."
	else
		local distance = math.max(0, Config.Flight.RunwayStart + 300 - f.Z)
		local targetAlt = math.clamp(distance * 0.072 + 5.4, 5.4, 260)
		guidance.Text = string.format("APPROACH · target %.0f ft\n%s %.0f · 45–88 KTS · gear DOWN\n↓ descend · neutral pitch to flare", targetAlt, if f.X > 0 then "← LEFT" else "RIGHT →", math.abs(f.X))
	end
	requestLabel.Visible = run.Request ~= nil
	if run.Request then requestLabel.Text = "CLIENT REQUEST\n" .. run.Request.Text .. "\n" .. math.max(0, run.Request.Expires - os.time()) .. " seconds" end
end
return Controller
