-- Original, deterministic production geometry. No toolbox scripts or external models.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local P = require(ReplicatedStorage.Shared.Palette)
local World = {}

local function model(name, parent)
	local m = Instance.new("Model"); m.Name = name; m.Parent = parent; return m
end
local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color or P.Porcelain
	p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder elseif shape == "Ball" then p.Shape = Enum.PartType.Ball end
	p.Parent = parent; return p
end
local function sign(parent, name, text, size, cf, color, background)
	local p = part(parent, name, size, cf, background or P.Graphite)
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34; gui.LightInfluence = 0; gui.Parent = p
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium; label.TextColor3 = color or P.Champagne; label.Text = text; label.TextScaled = true; label.Parent = gui
	return p
end
local function lamp(parent, cf, size, color, range)
	local p = part(parent, "Luminaire", size, cf, color or P.White, Enum.Material.Neon)
	p.CanCollide = false
	if range == 0 then return p end
	local light = Instance.new("PointLight"); light.Color = color or P.White; light.Range = range or 18; light.Brightness = 0.7; light.Shadows = false; light.Parent = p
	return p
end
local function prompt(p, action, text)
	local a = Instance.new("ProximityPrompt"); a.Name = action; a.ActionText = text; a.ObjectText = "Aster Aviation"
	a.HoldDuration = 0.35; a.MaxActivationDistance = 12; a.RequiresLineOfSight = false; a.Parent = p
	p:SetAttribute("Action", action); return a
end
local function sofa(parent, cf, width)
	part(parent, "LoungeSeat", Vector3.new(width, 1.1, 3.4), cf, P.Porcelain, Enum.Material.Fabric)
	part(parent, "LoungeBack", Vector3.new(width, 2.5, 0.7), cf * CFrame.new(0, 1, 1.5), P.Porcelain, Enum.Material.Fabric)
	for _, x in { -width / 2, width / 2 } do part(parent, "LoungeArm", Vector3.new(0.5, 1.8, 3.4), cf * CFrame.new(x, 0.4, 0), P.Walnut, Enum.Material.Wood) end
end

function World.init()
	local preview = workspace:FindFirstChild("EditModePreview")
	if preview then preview:Destroy() end
	local root = Instance.new("Folder"); root.Name = "AsterWorld"; root.Parent = workspace
	local lighting = game:GetService("Lighting")
	for _, name in { "AsterAtmosphere", "AsterBloom", "AsterGrade" } do
		local old = lighting:FindFirstChild(name); if old then old:Destroy() end
	end
	lighting.Ambient = Color3.fromRGB(100, 108, 120); lighting.OutdoorAmbient = Color3.fromRGB(143, 150, 163)
	local atmosphere = Instance.new("Atmosphere"); atmosphere.Density = 0.25; atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(201, 216, 228); atmosphere.Decay = Color3.fromRGB(228, 187, 140); atmosphere.Glare = 0.15; atmosphere.Haze = 1.5; atmosphere.Name = "AsterAtmosphere"; atmosphere.Parent = lighting
	local bloom = Instance.new("BloomEffect"); bloom.Intensity = 0.12; bloom.Size = 20; bloom.Threshold = 1.8; bloom.Name = "AsterBloom"; bloom.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect"); grade.Contrast = 0.08; grade.Saturation = -0.08; grade.TintColor = Color3.fromRGB(255, 245, 232); grade.Name = "AsterGrade"; grade.Parent = lighting
	return root
end

function World.hangar(root, userId, index)
	local m = model("Hangar_" .. userId, root)
	local origin = Vector3.new(index * 3500, 0, 0)
	local function at(x, y, z) return CFrame.new(origin + Vector3.new(x, y, z)) end
	part(m, "Apron", Vector3.new(380, 1, 420), at(0, -0.5, -85), P.Limestone, Enum.Material.Concrete)
	local coast = part(m, "CoastalRoute", Vector3.new(2800, 2, 17000), at(0, -12, -8000), P.Lagoon, Enum.Material.Glass)
	coast.CanCollide = false; coast.Reflectance = 0.2
	part(m, "Floor", Vector3.new(150, 0.4, 132), at(0, 0.05, 24), P.Limestone, Enum.Material.Marble).Reflectance = 0.12
	part(m, "BackWall", Vector3.new(150, 42, 2), at(0, 21, 89), P.Porcelain, Enum.Material.Concrete)
	for _, x in { -75, 75 } do
		part(m, "SideWall", Vector3.new(2, 42, 132), at(x, 21, 24), P.Porcelain, Enum.Material.Concrete)
		for z = -36, 84, 24 do
			part(m, "SteelColumn", Vector3.new(1.4, 42, 2), at(x * 0.98, 21, z), P.Graphite, Enum.Material.Metal)
		end
	end
	for z = -36, 84, 24 do
		part(m, "RoofTruss", Vector3.new(150, 1.8, 1.5), at(0, 41, z), P.Graphite, Enum.Material.Metal)
		for x = -60, 60, 30 do part(m, "TrussBrace", Vector3.new(32, 0.7, 0.7), at(x, 38, z) * CFrame.Angles(0, 0, math.rad(12)), P.Graphite, Enum.Material.Metal) end
		lamp(m, at(0, 39.5, z), Vector3.new(92, 0.2, 0.5), P.White, 48)
	end
	part(m, "Roof", Vector3.new(152, 1, 134), at(0, 43, 24), P.Graphite, Enum.Material.Metal)
	for _, x in { -66, 66 } do
		part(m, "DoorCassette", Vector3.new(18, 39, 2.5), at(x, 19.5, -43), P.Graphite, Enum.Material.Metal)
		for dx = -7, 7, 2 do part(m, "DoorFlute", Vector3.new(0.4, 38, 0.3), at(x + dx, 19.5, -44.5), P.Limestone, Enum.Material.Metal) end
	end
	sign(m, "Brand", "A S T E R   /   A V I A T I O N", Vector3.new(76, 5, 0.3), at(0, 29, 87.8))
	sign(m, "HangarId", "01   /   PRIVATE CHARTER", Vector3.new(31, 2, 0.3), at(-48, 17, 87.6), P.Graphite, P.Porcelain)
	for x = -60, 60, 12 do part(m, "FloorJoint", Vector3.new(0.05, 0.02, 125), at(x, 0.28, 24), P.Graphite) end
	for z = -32, 84, 12 do part(m, "FloorJoint", Vector3.new(144, 0.02, 0.05), at(0, 0.29, z), P.Graphite) end
	part(m, "TaxiLine", Vector3.new(0.35, 0.04, 210), at(0, 0.31, -10), P.Champagne)
	for _, x in { -35, 35 } do part(m, "BayOutline", Vector3.new(0.22, 0.04, 75), at(x, 0.32, 17), P.Champagne) end
	part(m, "BayOutline", Vector3.new(70, 0.04, 0.22), at(0, 0.32, 55), P.Champagne)
	-- Glass concierge lounge, with clear entry and an aircraft sightline.
	part(m, "LoungePlatform", Vector3.new(31, 0.6, 34), at(53, 0.5, 64), P.Walnut, Enum.Material.WoodPlanks)
	local glass = part(m, "LoungeGlass", Vector3.new(0.25, 14, 25), at(37, 7, 70), P.Glass, Enum.Material.Glass); glass.Transparency = 0.65
	sofa(m, at(55, 2, 78), 13)
	sofa(m, at(65, 2, 65) * CFrame.Angles(0, math.pi / 2, 0), 9)
	part(m, "LoungeTable", Vector3.new(8, 0.5, 4), at(54, 2.2, 69), P.Limestone, Enum.Material.Marble)
	part(m, "TableBase", Vector3.new(3, 2, 2), at(54, 1, 69), P.Graphite, Enum.Material.Metal)
	for _, x in { 42, 68 } do
		part(m, "Planter", Vector3.new(3, 3, 3), at(x, 1.5, 82), P.Graphite)
		part(m, "Topiary", Vector3.new(4, 7, 4), at(x, 6, 82), Color3.fromRGB(66, 93, 76), Enum.Material.Grass, "Ball")
	end
	local dispatch = sign(m, "Dispatch", "CONCIERGE\nCHARTER OFFERS", Vector3.new(9, 4, 1), at(-43, 5, 65))
	prompt(dispatch, "Phone", "View charter offers")
	local prep = part(m, "CateringStation", Vector3.new(10, 3, 5), at(-48, 1.5, 44), P.Graphite, Enum.Material.Metal)
	part(m, "StoneCounter", Vector3.new(11, 0.4, 6), at(-48, 3.2, 44), P.Porcelain, Enum.Material.Marble)
	sign(m, "PrepSign", "CABIN ATELIER", Vector3.new(11, 1.5, 0.2), at(-48, 5, 46.5))
	prompt(prep, "Prep", "Prepare cabin")
	for i = 1, 3 do
		local bag = part(m, "Baggage", Vector3.new(1.6, 2.6, 1), at(-34 + i * 2, 1.3, 38), if i == 1 then P.Walnut else P.Graphite)
		part(m, "BagHandle", Vector3.new(0.7, 0.15, 0.3), bag.CFrame * CFrame.new(0, 1.45, 0), P.Champagne, Enum.Material.Metal)
	end
	local spawn = Instance.new("SpawnLocation"); spawn.Name = "Spawn"; spawn.Size = Vector3.new(6, 1, 6); spawn.CFrame = at(-34, 0.8, 64)
	spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = false; spawn.Duration = 0; spawn.Parent = m
	local runway = model("DepartureRunway", m)
	part(runway, "Asphalt", Vector3.new(88, 0.4, 2100), at(0, -0.1, -1220), Color3.fromRGB(56, 62, 67), Enum.Material.Asphalt)
	for z = -240, -2200, -80 do
		part(runway, "Centerline", Vector3.new(1.5, 0.05, 28), at(0, 0.15, z), P.Porcelain)
		for _, x in { -43, 43 } do lamp(runway, at(x, 0.4, z), Vector3.new(0.5, 0.3, 0.5), P.White, 0) end
	end
	return { Model = m, Origin = origin, Spawn = spawn, Index = index }
end

function World.jet(parent, origin, tailNumber)
	local m = model("AsterL6", parent)
	local function at(x, y, z) return CFrame.new(x, y, z) end
	local root = part(m, "Hull", Vector3.new(7.6, 0.7, 40), at(0, 0, 0), P.Graphite)
	m.PrimaryPart = root
	-- Hollow elliptical shell with real port door opening. Nose points toward -Z.
	for segment = 0, 7 do
		local z = -14 + segment * 4
		for i = 0, 15 do
			local a = i * math.pi * 2 / 16
			local x, y = math.cos(a) * 4.35, math.sin(a) * 4.0 + 3.2
			local doorHole = segment == 1 and i >= 6 and i <= 9
			if not doorHole then
				local shell = part(m, "FuselagePanel", Vector3.new(1.85, 0.24, 4.06), at(x, y, z) * CFrame.Angles(0, 0, a + math.pi / 2), P.Porcelain, Enum.Material.Metal)
				shell.Reflectance = 0.08
			end
		end
	end
	-- Continuous hollow lofts: no detached ellipsoid nose or solid cockpit obstruction.
	local function triangle(name, a, b, c, color, material, transparent)
		local ab, ac, bc = b - a, c - a, c - b
		if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then c, a = a, c
		elseif ac:Dot(ac) > bc:Dot(bc) then a, b = b, a end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local back = bc.Unit
		local up = bc:Cross(right).Unit
		local height = math.abs(ab:Dot(up))
		for _, row in { { (a + b) / 2, right, back, math.abs(ab:Dot(back)) }, { (a + c) / 2, -right, -back, math.abs(ac:Dot(back)) } } do
			local tile = part(m, name, Vector3.new(0.08, height, math.max(0.01, row[4])), CFrame.fromMatrix(row[1], row[2], up, row[3]), color, material, "Wedge")
			tile.Reflectance = 0.06; tile.Transparency = transparent and 0.15 or 0
		end
	end
	local function loft(name, rings)
		for k = 1, #rings - 1 do
			local a, b = rings[k], rings[k + 1]
			for i = 0, 15 do
				local theta = i * math.pi / 8
				local nextTheta = theta + math.pi / 8
				local function vertex(ring, angle) return Vector3.new(math.cos(angle) * ring[2], ring[4] + math.sin(angle) * ring[3], ring[1]) end
				local a1, a2, b1, b2 = vertex(a, theta), vertex(a, nextTheta), vertex(b, theta), vertex(b, nextTheta)
				local glazing = name == "Nose" and k == 1 and i >= 1 and i <= 6
				local tileName = if glazing then "CanopyGlass" else name
				local color, material = if glazing then P.Glass else P.Porcelain, if glazing then Enum.Material.Glass else Enum.Material.Metal
				triangle(tileName, a1, a2, b1, color, material, glazing)
				triangle(tileName, a2, b2, b1, color, material, glazing)
			end
		end
	end
	loft("Nose", { { -16, 4.35, 4, 3.2 }, { -19, 3.9, 3.35, 3.05 }, { -24, 2.35, 1.65, 2.5 }, { -29, 0.12, 0.12, 2.1 } })
	loft("TailCone", { { 16, 4.35, 4, 3.2 }, { 22, 2.5, 2.5, 3.9 }, { 28, 0.15, 0.25, 4.5 } })
	part(m, "Carpet", Vector3.new(7.7, 0.2, 33), at(0, 0.5, 1), P.Walnut, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		part(m, "LowerStripe", Vector3.new(0.11, 0.23, 32), at(side * 4.37, 2, 0), P.Champagne, Enum.Material.Metal)
		for z = -3, 13, 5.4 do
			local bezel = part(m, "WindowBezel", Vector3.new(0.19, 2.1, 2.7), at(side * 4.4, 4.2, z), P.Graphite, Enum.Material.Metal, "Ball")
			bezel.CanCollide = false
			local glass = part(m, "CabinWindow", Vector3.new(0.22, 1.65, 2.2), at(side * 4.5, 4.2, z), P.Glass, Enum.Material.Glass, "Ball")
			glass.Transparency = 0.28; glass.CanCollide = false
		end
		-- Swept wings with wedge planform and narrow tips.
		part(m, "WingRoot", Vector3.new(12, 0.5, 11), at(side * 8.8, 0.1, 6), P.Porcelain, Enum.Material.Metal)
		part(m, "SweptWing", Vector3.new(0.38, 17, 7.4), at(side * 21, 0.7, 10) * CFrame.Angles(0, 0, -side * math.pi / 2), P.Porcelain, Enum.Material.Metal, "Wedge")
		part(m, "Winglet", Vector3.new(0.35, 4.2, 3.4), at(side * 29, 2.6, 12) * CFrame.Angles(0, 0, math.rad(-side * 12)), P.Graphite, Enum.Material.Metal)
		local flap = part(m, "Flap", Vector3.new(12, 0.18, 1.4), at(side * 18, 0.35, 14), P.Limestone, Enum.Material.Metal)
		flap:SetAttribute("Side", side)
		lamp(m, at(side * 29.1, 2.4, 11), Vector3.new(0.25, 0.25, 0.5), if side < 0 then P.Red else P.Green, 6)
		-- Twin rear-mounted turbofans, dark intake and spinner.
		part(m, "EnginePylon", Vector3.new(3.8, 0.5, 4), at(side * 5, 3.2, 17), P.Graphite, Enum.Material.Metal)
		part(m, "Nacelle", Vector3.new(8.7, 3.5, 3.5), at(side * 6.6, 3.5, 17) * CFrame.Angles(0, math.pi / 2, 0), P.Porcelain, Enum.Material.Metal, "Cylinder")
		part(m, "Intake", Vector3.new(0.2, 2.95, 2.95), at(side * 6.6, 3.5, 12.6) * CFrame.Angles(0, math.pi / 2, 0), P.Graphite, Enum.Material.Metal, "Cylinder")
		part(m, "Spinner", Vector3.new(0.5, 0.8, 0.8), at(side * 6.6, 3.5, 12.4) * CFrame.Angles(0, math.pi / 2, 0), P.Limestone, Enum.Material.Metal, "Cylinder")
		local exhaust = part(m, "Exhaust", Vector3.new(0.3, 2.5, 2.5), at(side * 6.6, 3.5, 21.5) * CFrame.Angles(0, math.pi / 2, 0), P.Graphite, Enum.Material.Metal, "Cylinder")
		local attachment = Instance.new("Attachment"); attachment.Orientation = Vector3.new(0, 90, 0); attachment.Parent = exhaust
		local fx = Instance.new("ParticleEmitter"); fx.Name = "EngineMist"; fx.Texture = "rbxasset://textures/particles/smoke_main.dds"
		fx.Color = ColorSequence.new(P.Porcelain); fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1) })
		fx.Size = NumberSequence.new(1.2); fx.Lifetime = NumberRange.new(0.25, 0.5); fx.Speed = NumberRange.new(5, 8); fx.Rate = 0; fx.Parent = attachment
	end
	part(m, "VerticalStabilizer", Vector3.new(0.7, 11, 6.4), at(0, 9, 22) * CFrame.Angles(math.rad(-15), 0, 0), P.Graphite, Enum.Material.Metal, "Wedge")
	part(m, "HorizontalStabilizer", Vector3.new(21, 0.35, 5), at(0, 13.5, 23), P.Porcelain, Enum.Material.Metal)
	-- Flight deck sits forward of the door, inside a glazed canopy.
	for _, side in { -1, 1 } do
		local windshield = part(m, "Windshield", Vector3.new(3.5, 2.7, 0.3), at(side * 1.8, 5.5, -17) * CFrame.Angles(math.rad(-28), math.rad(side * 17), 0), P.Glass, Enum.Material.Glass)
		windshield.Transparency = 0.2
		part(m, "FlightDeckSeat", Vector3.new(2.5, 0.7, 2.5), at(side * 2.1, 1.3, -13.5), P.Graphite, Enum.Material.Fabric)
		part(m, "FlightDeckBack", Vector3.new(2.5, 2.9, 0.5), at(side * 2.1, 2.7, -12.5), P.Graphite, Enum.Material.Fabric)
		sign(m, "Instrument", "ASTER\nSPD  ALT\nFLIGHT SYSTEM", Vector3.new(2.5, 1.3, 0.15), at(side * 2, 2.9, -16), P.Lagoon)
	end
	local captain = part(m, "Captain", Vector3.new(2, 0.3, 2), at(-2, 1.7, -13.8), P.Graphite)
	prompt(captain, "Cockpit", "Take flight controls")
	part(m, "Console", Vector3.new(1, 1.7, 4), at(0, 1.4, -14), P.Graphite, Enum.Material.Metal)
	for i = 1, 4 do part(m, "ThrottleLever", Vector3.new(0.12, 0.65, 0.15), at(-0.38 + i * 0.15, 2.3, -13.5), P.Limestone, Enum.Material.Metal) end
	-- Six individually upholstered seats with armrests, pedestal and stitched inset.
	for row = 1, 3 do
		for _, side in { -1, 1 } do
			local cf = at(side * 2.25, 1.2, -4 + row * 5.7)
			part(m, "SeatPedestal", Vector3.new(1.6, 0.7, 1.8), cf, P.Graphite, Enum.Material.Metal)
			part(m, "SeatCushion", Vector3.new(2.45, 0.7, 2.7), cf * CFrame.new(0, 0.6, 0), P.Porcelain, Enum.Material.Fabric)
			part(m, "SeatBack", Vector3.new(2.45, 3.3, 0.6), cf * CFrame.new(0, 2.1, 1.2) * CFrame.Angles(math.rad(-8), 0, 0), P.Porcelain, Enum.Material.Fabric)
			part(m, "SeatHeadrest", Vector3.new(1.6, 0.8, 0.35), cf * CFrame.new(0, 3.25, 0.7), P.Limestone, Enum.Material.Fabric)
			for _, arm in { -1, 1 } do part(m, "SeatArm", Vector3.new(0.2, 0.3, 2.4), cf * CFrame.new(arm * 1.23, 1.2, 0), P.Walnut, Enum.Material.Wood) end
			part(m, "Belt", Vector3.new(2.3, 0.05, 0.17), cf * CFrame.new(0, 0.98, 0), P.Graphite, Enum.Material.Fabric)
		end
	end
	for _, side in { -1, 1 } do
		part(m, "CabinCove", Vector3.new(0.2, 0.14, 26), at(side * 2.8, 6.25, 3), P.Champagne, Enum.Material.Neon)
		lamp(m, at(side * 2.8, 5.8, 4), Vector3.new(0.2, 0.15, 0.7), P.White, 14)
		part(m, "ClubTable", Vector3.new(1.9, 0.18, 2), at(side * 3, 2.3, 4.3), P.Walnut, Enum.Material.Wood)
	end
	local galley = part(m, "Galley", Vector3.new(2.3, 2.6, 3), at(2.7, 1.9, -8), P.Walnut, Enum.Material.Wood)
	part(m, "GalleyTop", Vector3.new(2.5, 0.18, 3.2), at(2.7, 3.3, -8), P.Limestone, Enum.Material.Marble)
	prompt(galley, "Service", "Serve client request")
	local tray = part(m, "CateringTray", Vector3.new(1.5, 0.12, 1.1), at(2.7, 3.47, -8), P.Champagne, Enum.Material.Metal)
	part(m, "Cup", Vector3.new(0.55, 0.65, 0.55), tray.CFrame * CFrame.new(0, 0.4, 0), P.Porcelain, Enum.Material.SmoothPlastic, "Cylinder")
	local door = part(m, "CabinDoor", Vector3.new(0.22, 5.8, 3.85), at(-4.45, 2.1, -10), P.Porcelain, Enum.Material.Metal)
	prompt(door, "Board", "Board aircraft")
	local stairs = model("Stairs", m)
	for i = 1, 5 do part(stairs, "Step", Vector3.new(1.2, 0.3, 3.8), at(-4.7 - i * 0.95, 0.3 - i * 0.85, -10), P.Graphite, Enum.Material.Metal) end
	for _, z in { -12, -8 } do part(stairs, "Rail", Vector3.new(6.3, 0.13, 0.13), at(-7.3, 1.1, z) * CFrame.Angles(0, 0, math.rad(39)), P.Champagne, Enum.Material.Metal) end
	local gear = model("LandingGear", m)
	for _, pos in { Vector3.new(0, -2.4, -18), Vector3.new(-4.8, -2.4, 5.5), Vector3.new(4.8, -2.4, 5.5) } do
		part(gear, "Strut", Vector3.new(0.3, 3.7, 0.3), CFrame.new(pos), P.Limestone, Enum.Material.Metal)
		part(gear, "Wheel", Vector3.new(1.3, 1.9, 1.9), CFrame.new(pos + Vector3.new(0, -1.5, 0)), P.Graphite, Enum.Material.SmoothPlastic, "Cylinder")
	end
	sign(m, "TailNumber", tailNumber, Vector3.new(0.1, 1, 6), at(-4.5, 3.8, 15) * CFrame.Angles(0, math.pi / 2, 0), P.Graphite, P.Porcelain)
	m:PivotTo(CFrame.new(origin + Vector3.new(0, 5.4, 12)))
	-- One anchored root with a welded assembly avoids replicating hundreds of part transforms each tick.
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			local joint = Instance.new("Motor6D"); joint.Name = "AssemblyJoint"; joint.Part0 = root; joint.Part1 = p
			joint.C0 = root.CFrame:ToObjectSpace(p.CFrame); joint:SetAttribute("Rest", joint.C0); joint.Parent = p
			p.Anchored = false; p.Massless = true
		end
	end
	return m
end

function World.npc(parent, name, cf, uniform)
	local m = model(name, parent)
	local skin = Color3.fromRGB(190, 142, 108)
	local root = part(m, "HumanoidRootPart", Vector3.new(2, 2, 1), cf, uniform or P.Graphite); root.Transparency = 1; root.CanCollide = false; m.PrimaryPart = root
	part(m, "Torso", Vector3.new(1.65, 2, 0.85), cf, uniform or P.Graphite)
	part(m, "Shirt", Vector3.new(0.45, 1.2, 0.05), cf * CFrame.new(0, 0.3, -0.45), P.Porcelain)
	part(m, "Head", Vector3.new(1.25, 1.25, 1.15), cf * CFrame.new(0, 1.7, 0), skin, Enum.Material.SmoothPlastic, "Ball")
	part(m, "Hair", Vector3.new(1.3, 0.5, 1.2), cf * CFrame.new(0, 2.22, 0.07), P.Walnut, Enum.Material.SmoothPlastic, "Ball")
	for _, s in { -1, 1 } do
		part(m, if s < 0 then "LeftArm" else "RightArm", Vector3.new(0.5, 1.8, 0.6), cf * CFrame.new(s * 1.1, -0.05, 0), uniform or P.Graphite)
		part(m, "Hand", Vector3.new(0.48, 0.4, 0.55), cf * CFrame.new(s * 1.1, -1.1, 0), skin)
		part(m, if s < 0 then "LeftLeg" else "RightLeg", Vector3.new(0.62, 1.9, 0.7), cf * CFrame.new(s * 0.47, -1.9, 0), P.Graphite)
		part(m, "Shoe", Vector3.new(0.68, 0.35, 1.1), cf * CFrame.new(s * 0.47, -2.8, -0.12), P.Graphite)
		part(m, "Eye", Vector3.new(0.09, 0.12, 0.06), cf * CFrame.new(s * 0.24, 1.8, -0.56), P.Graphite)
	end
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = false end end
	m:SetAttribute("Mood", "Ready")
	return m
end

function World.animateNPC(npc, points, duration, done)
	task.spawn(function()
		local limbs = {}
		for _, name in { "LeftArm", "RightArm", "LeftLeg", "RightLeg" } do
			local limb = npc:FindFirstChild(name)
			if limb then limbs[name] = npc:GetPivot():ToObjectSpace(limb.CFrame) end
		end
		for _, goal in points do
			if not npc.Parent then return end
			local start = npc:GetPivot(); local elapsed = 0
			while elapsed < duration and npc.Parent do
				elapsed += task.wait(); local alpha = math.min(elapsed / duration, 1)
				local bob = math.sin(alpha * math.pi * 10) * 0.08
				npc:PivotTo(start:Lerp(goal, alpha) * CFrame.new(0, bob, 0))
				for name, rest in limbs do
					local swing = math.sin(alpha * math.pi * 10) * 0.32 * (if string.find(name, "Left") then 1 else -1)
					npc[name].CFrame = npc:GetPivot() * rest * CFrame.Angles(swing, 0, 0)
				end
			end
			for name, rest in limbs do npc[name].CFrame = npc:GetPivot() * rest end
		end
		if done and npc.Parent then done() end
	end)
end

function World.poseSeated(npc)
	local cf = npc:GetPivot()
	for _, side in { -1, 1 } do
		local leg = npc:FindFirstChild(if side < 0 then "LeftLeg" else "RightLeg")
		if leg then leg.CFrame = cf * CFrame.new(side * 0.47, -1.35, -0.6) * CFrame.Angles(-math.pi / 2, 0, 0) end
	end
end

function World.service(run)
	local tray = run.Jet.CateringTray
	local motor = tray:FindFirstChild("AssemblyJoint")
	if motor then
		local rest = motor:GetAttribute("Rest")
		local cup = run.Jet.Cup:FindFirstChild("AssemblyJoint")
		local cupRest = cup and cup:GetAttribute("Rest")
		TweenService:Create(motor, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { C0 = CFrame.new(3, 2.5, 4.3) }):Play()
		if cup then TweenService:Create(cup, TweenInfo.new(1.2), { C0 = CFrame.new(3, 2.5, 4.3) * rest:Inverse() * cupRest }):Play() end
		task.delay(3, function()
			if motor.Parent then TweenService:Create(motor, TweenInfo.new(1.2), { C0 = rest }):Play() end
			if cup and cup.Parent then TweenService:Create(cup, TweenInfo.new(1.2), { C0 = cupRest }):Play() end
		end)
	end
end

function World.arrivalAction(run, action)
	local cf = run.Jet:GetPivot()
	local destination = run.Destination
	if action == "Baggage" and not destination:FindFirstChild("TransferredBaggage") then
		local bag = part(destination, "TransferredBaggage", Vector3.new(1.6, 2.6, 1), cf * CFrame.new(-10, -3, -10), P.Walnut)
		TweenService:Create(bag, TweenInfo.new(2), { CFrame = destination.ArrivalCar.Body.CFrame * CFrame.new(-4, -0.5, 3) }):Play()
	elseif action == "Umbrella" and not destination:FindFirstChild("Umbrella") then
		part(destination, "Umbrella", Vector3.new(8, 0.4, 8), cf * CFrame.new(-12, 5, -10), P.Graphite, Enum.Material.SmoothPlastic, "Ball")
		part(destination, "UmbrellaStem", Vector3.new(0.15, 7, 0.15), cf * CFrame.new(-12, 1.5, -10), P.Champagne, Enum.Material.Metal)
	elseif action == "Decoy" then
		for _, npc in destination:GetChildren() do
			if npc.Name == "Photographer" then World.animateNPC(npc, { npc:GetPivot() * CFrame.new(0, 0, 30) }, 2) end
		end
	end
end

function World.escort(run, done)
	for _, item in run.NPC:GetDescendants() do
		if item:IsA("BasePart") then item.Anchored = true end
		if item:IsA("WeldConstraint") then item:Destroy() end
	end
	local cf = run.Jet:GetPivot()
	for _, side in { -1, 1 } do
		run.NPC[if side < 0 then "LeftLeg" else "RightLeg"].CFrame = run.NPC:GetPivot() * CFrame.new(side * 0.47, -1.9, 0)
	end
	World.animateNPC(run.NPC, { cf * CFrame.new(-10, -2.2, -10), run.Destination.ArrivalCar.Body.CFrame * CFrame.new(5, 1.2, 0) }, 2, done)
end

function World.door(jet, open)
	local door = jet:FindFirstChild("CabinDoor")
	if door then
		door.CanCollide = not open
		local motor = door:FindFirstChild("AssemblyJoint")
		if motor then
			local rest = motor:GetAttribute("Rest")
			TweenService:Create(motor, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { C0 = if open then rest * CFrame.new(-2.8, -2.6, 0) * CFrame.Angles(0, 0, math.rad(-80)) else rest }):Play()
		end
	end
	for _, p in jet.Stairs:GetChildren() do p.Transparency = if open then 0 else 1; p.CanCollide = open end
	jet:SetAttribute("DoorOpen", open)
end

function World.gear(jet, extended)
	for _, p in jet.LandingGear:GetChildren() do
		local joint = p:FindFirstChild("AssemblyJoint")
		if joint then TweenService:Create(joint, TweenInfo.new(0.7), { C0 = joint:GetAttribute("Rest") * CFrame.new(0, if extended then 0 else 4, 0) }):Play() end
		p:SetAttribute("Extended", extended)
		if extended then p.Transparency = 0 else task.delay(0.7, function() if p.Parent and not p:GetAttribute("Extended") then p.Transparency = 1 end end) end
	end
end

function World.weldNPC(npc, jet)
	for _, p in npc:GetDescendants() do
		if p:IsA("BasePart") then
			local joint = Instance.new("WeldConstraint"); joint.Part0 = jet.PrimaryPart; joint.Part1 = p; joint.Parent = p
			p.Anchored = false; p.Massless = true
		end
	end
end

function World.upgrade(plot, profile)
	plot.Model.Floor.Color = if profile.Hangar.Theme == "Graphite" then P.Graphite else P.Limestone
	plot.Model.Floor.Reflectance = if profile.Hangar.Showpiece > 0 then 0.25 else 0.1
	if profile.Hangar.Showpiece > 0 and not plot.Model:FindFirstChild("Sculpture") then
		part(plot.Model, "Sculpture", Vector3.new(1.5, 8, 1.5), CFrame.new(plot.Origin + Vector3.new(49, 5, 58)) * CFrame.Angles(0.2, 0, 0.4), P.Champagne, Enum.Material.Metal)
	end
	if profile.Hangar.Operations > 0 and not plot.Model:FindFirstChild("ServiceFacility") then
		sign(plot.Model, "ServiceFacility", "SERVICE ATELIER\nPRIORITY PREPARATION", Vector3.new(14, 4, 1), CFrame.new(plot.Origin + Vector3.new(-53, 6, 73)))
	end
end

function World.destination(parent, origin, config)
	local m = model("Riviera", parent)
	local z = -config.RunwayStart - 220
	local function at(x, y, dz) return CFrame.new(origin + Vector3.new(x, y, z + dz)) end
	part(m, "Sea", Vector3.new(2200, 3, 2600), at(250, -9, 0), P.Lagoon, Enum.Material.Glass).Reflectance = 0.25
	part(m, "Island", Vector3.new(220, 8, 1900), at(0, -4, -560), P.Limestone, Enum.Material.Rock)
	part(m, "Runway", Vector3.new(88, 0.3, 1700), at(0, 0, -640), Color3.fromRGB(54, 62, 67), Enum.Material.Asphalt)
	for dz = 80, -1480, -80 do
		part(m, "Centerline", Vector3.new(1.8, 0.06, 28), at(0, 0.2, dz), P.Porcelain)
		for _, x in { -43, 43 } do lamp(m, at(x, 0.5, dz), Vector3.new(0.6, 0.3, 0.6), P.White, 0) end
	end
	for x = -30, 30, 10 do part(m, "Threshold", Vector3.new(5, 0.07, 55), at(x, 0.25, 55), P.Porcelain) end
	for i = 1, 22 do
		local x = 180 + (i % 5) * 62; local dz = 200 - math.floor(i / 5) * 150
		local height = 20 + (i * 17) % 65
		part(m, "Waterfront", Vector3.new(40, height, 48), at(x, height / 2 - 2, dz), if i % 3 == 0 then P.Limestone else P.Porcelain, Enum.Material.Concrete)
		for floor = 8, height - 3, 9 do
			part(m, "Terrace", Vector3.new(43, 1, 52), at(x, floor, dz), P.Porcelain)
			part(m, "Glazing", Vector3.new(40.1, 4, 48.1), at(x, floor + 3, dz), P.Glass, Enum.Material.Glass)
		end
	end
	for i = 1, 9 do
		part(m, "CoastalMountain", Vector3.new(500, 200 + i * 20, 500), at(600 + i * 150, 20, -i * 200), Color3.fromRGB(124, 144, 125), Enum.Material.Rock, "Ball")
	end
	part(m, "ArrivalApron", Vector3.new(160, 0.5, 180), at(-115, -0.1, -1050), P.Limestone, Enum.Material.Concrete)
	part(m, "ArrivalCanopy", Vector3.new(44, 0.5, 36), at(-154, 13, -1050), P.Porcelain, Enum.Material.Metal)
	for _, dx in { -173, -135 } do part(m, "CanopyPier", Vector3.new(0.8, 13, 0.8), at(dx, 6.5, -1050), P.Champagne, Enum.Material.Metal) end
	sign(m, "ArrivalBrand", "R I V I E R A\nPRIVATE TERMINAL", Vector3.new(30, 4, 0.3), at(-151, 8, -1066))
	local car = model("ArrivalCar", m)
	part(car, "Body", Vector3.new(6, 2.3, 13), at(-151, 2, -1048), P.Graphite, Enum.Material.Metal)
	part(car, "Cabin", Vector3.new(5.6, 2, 7), at(-151, 4, -1048), P.Glass, Enum.Material.Glass)
	for _, dx in { -154, -148 } do for _, dz in { -1044, -1052 } do part(car, "Wheel", Vector3.new(0.8, 2.6, 2.6), at(dx, 1.3, dz), P.Graphite, Enum.Material.SmoothPlastic, "Cylinder") end end
	for i = 1, 3 do
		local npc = World.npc(m, "Photographer", at(-178 - i * 3, 3.2, -1020))
		local camera = part(npc, "PressCamera", Vector3.new(1.1, 0.65, 0.7), npc:GetPivot() * CFrame.new(0, 0.7, -1), P.Graphite)
		lamp(npc, camera.CFrame * CFrame.new(0, 0.3, -0.4), Vector3.new(0.3, 0.2, 0.1), P.White, 0)
	end
	return m
end

return World
