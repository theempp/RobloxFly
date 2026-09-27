local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Profiles = require(script.Parent.Profiles)
local Charters = require(script.Parent.Charters)

local folder = Instance.new("Folder"); folder.Name = "Remotes"; folder.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent"); event.Name = "Concierge"; event.Parent = folder
local input = Instance.new("RemoteEvent"); input.Name = "FlightInput"; input.Parent = folder
local buckets, locks, syncAt = {}, {}, {}

local function rate(player, cost)
	local t = os.clock(); local b = buckets[player.UserId] or { Time = t, Tokens = Config.Limits.RemoteBurst }
	b.Tokens = math.min(Config.Limits.RemoteBurst, b.Tokens + (t - b.Time) * Config.Limits.RemoteRate); b.Time = t
	buckets[player.UserId] = b
	if b.Tokens < cost then return false end
	b.Tokens -= cost; return true
end
Charters.start(event)
event.OnServerEvent:Connect(function(player, action, data)
	if type(action) ~= "string" or #action > 24 or not rate(player, 2) or not Profiles.get(player.UserId) then return end
	if action == "Sync" then
		if os.clock() - (syncAt[player.UserId] or -10) < 1 then return end
		syncAt[player.UserId] = os.clock(); event:FireClient(player, "State", Charters.snapshot(player)); return
	end
	if not Protocol.validPayload(data) or locks[player.UserId] then return end
	locks[player.UserId] = true
	local success, ok, message = pcall(Charters.action, player, action, data)
	locks[player.UserId] = nil
	if not success then warn("[PJCT] action_error", action, ok); message = "That action could not finish. Please try again."; ok = false end
	if message then event:FireClient(player, "Notice", { Text = message, Error = not ok }) end
end)

input.OnServerEvent:Connect(function(player, data)
	if not rate(player, 0.25) or not Protocol.validInput(data) then return end
	Charters.input(player, { Bank = data.Bank, Pitch = data.Pitch, Throttle = data.Throttle })
end)

local function add(player)
	local ok, message = Profiles.load(player.UserId)
	if not player.Parent then Profiles.release(player.UserId); return end
	if not ok then player:Kick(message); return end
	Charters.addPlayer(player)
end
Players.PlayerAdded:Connect(add)
for _, player in Players:GetPlayers() do task.spawn(add, player) end
Players.PlayerRemoving:Connect(function(player)
	Charters.removePlayer(player); buckets[player.UserId] = nil; locks[player.UserId] = nil; syncAt[player.UserId] = nil
end)
game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do pending += 1; task.spawn(function() Profiles.release(player.UserId); pending -= 1 end) end
	local start = os.clock(); while pending > 0 and os.clock() - start < 25 do task.wait(0.1) end
end)

-- Product IDs are unconfigured. Never acknowledge an unknown receipt as granted.
MarketplaceService.ProcessReceipt = function(_receipt)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
print("[PJCT] server ready · " .. (if Profiles.isStudio() then "Studio session-only saves" else "durable profile store"))
