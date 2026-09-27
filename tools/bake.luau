-- Bake the SAME World module used by the server into an edit-mode preview.
-- Lune is a data model authoring tool, not a Roblox physics/render test.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local game = roblox.deserializePlace(fs.readFile("build/PrivateJetCharterTycoon.rbxlx"))
local workspace = game:GetService("Workspace")

-- Authoring-time implementations: transforms and immediate tween endpoints.
roblox.implementMethod("Model", "GetPivot", function(m)
	return if m.PrimaryPart then m.PrimaryPart.CFrame else roblox.CFrame.identity
end)
roblox.implementMethod("Model", "PivotTo", function(m, cf)
	local delta = cf * m:GetPivot():Inverse()
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame = delta * p.CFrame end end
end)
roblox.implementMethod("TweenService", "Create", function(_, object, _, props)
	return { Play = function()
		for key, value in props do object[key] = value end
		if object:IsA("Motor6D") then object.Part1.CFrame = object.Part0.CFrame * object.C0 * object.C1:Inverse() end
	end }
end)
local env = { game = game, workspace = workspace, task = require("@lune/task") }
for _, name in { "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Enum", "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence" } do env[name] = roblox[name] end
env.TweenInfo = { new = function(...) return { ... } end }
local cache = {}
env.require = function(module)
	if cache[module] then return cache[module] end
	local moduleEnv = table.clone(env); moduleEnv.script = module
	local result = luau.load(module.Source, { environment = moduleEnv, debugName = module.Name })()
	cache[module] = result; return result
end
local World = env.require(game:GetService("ServerScriptService").Server.World)
local Config = env.require(game:GetService("ReplicatedStorage").Shared.Config)
local root = World.init(); root.Name = "EditModePreview"
local plot = World.hangar(root, 0, 0)
local jet = World.jet(plot.Model, plot.Origin, "AS-000001")
World.door(jet, true)
World.npc(plot.Model, "Client", roblox.CFrame.new(-25, 3.2, 44), roblox.Color3.fromRGB(126, 107, 91))
World.destination(plot.Model, plot.Origin, Config.Flight)
local totalParts, jetParts, lights, prompts = 0, 0, 0, 0
local scene = {}
for _, p in root:GetDescendants() do
	if p:IsA("BasePart") then
		totalParts += 1
		assert(p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, "Zero-sized part")
		local r, g, b = p.Color.R, p.Color.G, p.Color.B
		table.insert(scene, { name = p.Name, size = { p.Size.X, p.Size.Y, p.Size.Z }, cf = { p.CFrame:GetComponents() }, color = { r, g, b }, transparency = p.Transparency,
			shape = if p:IsA("WedgePart") then "Wedge" elseif p:IsA("Part") then tostring(p.Shape) else "Block", material = tostring(p.Material) })
	elseif p:IsA("PointLight") then lights += 1
	elseif p:IsA("ProximityPrompt") then prompts += 1
	elseif p:IsA("TextLabel") then
		-- Lune's legacy Font alias does not coerce EnumItem to FontFace on serialization.
		p.FontFace = roblox.Font.new("rbxasset://fonts/families/GothamSSm.json", roblox.Enum.FontWeight.Medium)
	end
end
for _, p in jet:GetDescendants() do if p:IsA("BasePart") then jetParts += 1 end end
assert(jetParts < 650, "Aircraft part budget exceeded")
assert(totalParts < 2500, "Scene part budget exceeded")
assert(prompts >= 5, "Missing interaction stations")
local camera = roblox.Instance.new("Camera"); camera.Name = "Camera"; camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(-65, 27, -48), roblox.Vector3.new(0, 7, 13)); camera.Focus = roblox.CFrame.new(0, 7, 13); camera.Parent = workspace
fs.writeFile("build/PrivateJetCharterTycoon.rbxl", roblox.serializePlace(game))
fs.writeFile("build/scene.json", serde.encode("json", scene))
fs.writeFile("docs/GEOMETRY_REPORT.json", serde.encode("json", { TotalParts = totalParts, JetParts = jetParts, PointLights = lights, InteractionPrompts = prompts, Verification = "Offline authoring and serialization; not a Roblox render or physics test" }, true))
print(string.format("Baked %d scene parts, %d jet parts, %d lights, %d prompts into Studio edit preview.", totalParts, jetParts, lights, prompts))
