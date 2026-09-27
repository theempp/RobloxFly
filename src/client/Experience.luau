local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.AudioCatalog)
local D = require(script.Parent.Design)
local Experience = {}
local player = Players.LocalPlayer
local settings = { Quality = "High", ReducedMotion = false, Volume = 0.55 }
local run, jet, skip, shot, shotStart, shotDuration, cameraCF
local sounds, oldLights = {}, {}
local lastStage, lastPhase

local function setQuality(object)
	if object:IsA("PointLight") then
		if oldLights[object] == nil then oldLights[object] = object.Enabled end
		object.Enabled = settings.Quality ~= "Low" and oldLights[object]
	elseif object:IsA("BasePart") and (object.Name == "FuselagePanel" or object.Name == "SteelColumn") then
		object.CastShadow = settings.Quality ~= "Low"
	end
end
function Experience.cancel()
	shot = nil
	if skip then skip.Visible = false end
end
function Experience.cinematic(kind, duration)
	if settings.ReducedMotion or not jet then return end
	shot = kind; shotStart = os.clock(); shotDuration = duration; skip.Visible = true
end
local function findJet(owner)
	local world = workspace:FindFirstChild("AsterWorld"); local plot = world and world:FindFirstChild("Hangar_" .. owner)
	return plot and plot:FindFirstChild("AsterL6")
end

function Experience.cue(name)
	if not name or not Catalog[name] then return end
	local sound = sounds[name]
	if sound and sound.SoundId ~= "" then sound:Play() end
end

function Experience.init(gui)
	skip = D.button(gui, "Skip cinematic", Experience.cancel)
	skip.AnchorPoint = Vector2.new(0.5, 1); skip.Position = UDim2.new(0.5, 0, 1, -18); skip.Size = UDim2.fromOffset(176, 48); skip.Visible = false; skip.ZIndex = 30
	for name, info in Catalog do
		local sound = Instance.new("Sound"); sound.Name = "Aster" .. name; sound.SoundId = info.Id
		sound.Looped = info.Loop or false; sound.Volume = info.Volume * settings.Volume
		sound.RollOffMinDistance = 12; sound.RollOffMaxDistance = 140; sound.Parent = SoundService; sounds[name] = sound
	end
	workspace.DescendantAdded:Connect(setQuality)
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if not jet or not jet.Parent then jet = findJet(if run then run.Owner else player.UserId); return end
		local pivot = jet:GetPivot()
		local seated = run and run.Stage == "Flight" and run.Seated and run.Seated[player.UserId]
		if shot and os.clock() - shotStart >= shotDuration then Experience.cancel() end
		if shot or seated then
			camera.CameraType = Enum.CameraType.Scriptable
			local desired
			if shot then
				local alpha = math.clamp((os.clock() - shotStart) / shotDuration, 0, 1)
				local offset = if shot == "Boarding" then Vector3.new(-25, 10, -20) elseif shot == "Arrival" then Vector3.new(-36, 12, 22) else Vector3.new(-43 + alpha * 10, 21, -70 + alpha * 10)
				desired = CFrame.lookAt(pivot.Position + offset, pivot.Position + Vector3.new(0, 3, 0))
			else desired = CFrame.lookAt(pivot.Position + Vector3.new(0, 24, 68), pivot.Position + Vector3.new(0, 3, -26)) end
			cameraCF = if cameraCF then cameraCF:Lerp(desired, math.min(1, dt * 6)) else desired
			camera.CFrame = cameraCF; camera.FieldOfView = 65
		else
			if camera.CameraType == Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Custom
				local character = player.Character; camera.CameraSubject = character and character:FindFirstChildOfClass("Humanoid")
			end
			cameraCF = nil
		end
	end)
end

function Experience.update(newRun, newSettings)
	if newSettings then
		local changed = settings.Quality ~= newSettings.Quality
		settings = newSettings
		if changed then for _, object in workspace:GetDescendants() do setQuality(object) end end
		if settings.ReducedMotion then Experience.cancel() end
	end
	run = newRun
	jet = findJet(if run then run.Owner else player.UserId)
	local stage = if run then run.Stage else "Hangar"
	if stage ~= lastStage then
		if stage == "Hangar" then Experience.cinematic("Reveal", 3)
		elseif stage == "Boarding" then Experience.cinematic("Boarding", 2)
		elseif stage == "Arrival" then Experience.cinematic("Arrival", 2)
		elseif stage == "Results" then Experience.cinematic("Arrival", 2) end
		lastStage = stage
	end
	local f = run and run.Flight
	if f and f.Phase ~= lastPhase then
		if f.Phase == "Climb" or f.Phase == "Approach" then Experience.cinematic("Flight", 1.4) end
		lastPhase = f.Phase
	end
	for name, sound in sounds do
		local info = Catalog[name]
		sound.Volume = info.Volume * settings.Volume
		if name == "Turbine" and jet then
			sound.Parent = jet.PrimaryPart; sound.PlaybackSpeed = if f then 0.7 + f.Throttle * 0.6 else 0.7
			sound.Volume *= if stage == "Flight" then 1 else 0
		elseif name == "Wind" then sound.Volume *= if stage == "Flight" then 1 else 0
		elseif name == "Hangar" then sound.Volume *= if stage == "Hangar" or stage == "Preparation" then 1 else 0 end
		if info.Loop and sound.SoundId ~= "" and not sound.IsPlaying then sound:Play() end
	end
	if jet then
		for _, fx in jet:GetDescendants() do
			if fx:IsA("ParticleEmitter") then fx.Rate = if stage == "Flight" and settings.Quality == "High" then 8 else 0 end
			if fx.Name == "CabinCove" and fx:IsA("BasePart") and run then fx.Color = if run.Prep.Mood == "Cool" then D.P.Lagoon else D.P.Champagne end
		end
	end
end
return Experience
