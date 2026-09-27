local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Concierge = require(script.Parent.Concierge)
local FlightController = require(script.Parent.FlightController)
local Experience = require(script.Parent.Experience)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local event = remotes:WaitForChild("Concierge")
local function send(action, data) event:FireServer(action, data or {}) end
local gui = Concierge.init(send)
Experience.init(gui)
FlightController.init(gui, send, remotes:WaitForChild("FlightInput"), Experience.cancel)
Concierge.visibilityChanged(FlightController.setObscured)
local settings
event.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		if not data.Profile then return end
		settings = data.Profile.Settings
		Concierge.state(data); FlightController.update(data.Run); Experience.update(data.Run, settings)
	elseif kind == "Flight" then
		Concierge.flight(data); FlightController.update(data); Experience.update(data, settings)
	elseif kind == "Notice" then Concierge.notice(data); Experience.cue(data.Cue) end
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if player ~= Players.LocalPlayer then return end
	local action = prompt.Parent:GetAttribute("Action")
	if action == "Phone" or action == "Prep" then Concierge.show("Charters"); send("Sync")
	elseif action == "Service" or action == "Board" or action == "Cockpit" then send(action) end
end)
GuiService.AutoSelectGuiEnabled = true
task.spawn(function() for _ = 1, 4 do send("Sync"); task.wait(2) end end)
print("[PJCT] client ready")
