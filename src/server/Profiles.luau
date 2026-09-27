--!strict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Domain = require(Shared.Domain)
local Profiles = {}
local store = if RunService:IsStudio() then nil else DataStoreService:GetDataStore(Config.DataStore)
local session = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local cache: {[number]: any} = {}
local busy: {[number]: boolean} = {}
local studio = RunService:IsStudio()
local LEASE = 180

local function retry(callback: () -> any): (boolean, any)
	local lastError
	for attempt = 1, 4 do
		local ok, value = pcall(callback)
		if ok then return true, value end
		lastError = value
		if attempt < 4 then task.wait(2 ^ (attempt - 1)) end
	end
	return false, lastError
end

function Profiles.get(userId: number): any return cache[userId] end
function Profiles.isStudio(): boolean return studio end

function Profiles.load(userId: number): (boolean, string?)
	if studio then cache[userId] = Domain.newProfile(Config); return true end
	local ok, value = retry(function()
		return store:UpdateAsync("p_" .. userId, function(old)
			local data = Domain.migrate(old, Config)
			if data.Lock and data.Lock.Session ~= session and data.Lock.Expires > os.time() then return nil end
			data.Lock = { Session = session, Expires = os.time() + LEASE }
			return data
		end)
	end)
	if not ok or not value then return false, "Your save is unavailable or open in another server. Please rejoin shortly." end
	cache[userId] = value
	return true
end

-- Serialize and commit each economic mutation before reporting success.
-- The transform must not yield or cause side effects: UpdateAsync may retry it.
function Profiles.transact(userId: number, transform: (any) -> (boolean, any)): (boolean, any)
	while busy[userId] do task.wait() end
	if not cache[userId] then return false, "Profile is not ready" end
	busy[userId] = true
	local output, accepted = nil, false
	local ok, value = retry(function()
		local function apply(old)
			if not old or (not studio and (not old.Lock or old.Lock.Session ~= session)) then return nil end
			local nextData = Domain.copy(old)
			accepted, output = transform(nextData)
			if not accepted then return nil end
			if not studio then nextData.Lock = { Session = session, Expires = os.time() + LEASE } end
			return nextData
		end
		if studio then return apply(cache[userId]) end
		return store:UpdateAsync("p_" .. userId, apply)
	end)
	if ok and value then cache[userId] = value end
	busy[userId] = nil
	if not ok then return false, "Save failed. Nothing has been confirmed. Try again." end
	if not value then return false, output or "Save session changed. Rejoin to protect progress." end
	return accepted, output
end

function Profiles.release(userId: number)
	while busy[userId] do task.wait() end
	busy[userId] = true
	if cache[userId] and not studio then
		retry(function()
			return store:UpdateAsync("p_" .. userId, function(old)
				if old and old.Lock and old.Lock.Session == session then old.Lock = nil; return old end
				return nil
			end)
		end)
	end
	cache[userId] = nil; busy[userId] = nil
end

function Profiles.public(userId: number): any
	local profile = cache[userId]
	if not profile then return nil end
	local result = Domain.copy(profile); result.Lock = nil; result.Receipts = nil; result.RewardJournal = nil
	result.SessionOnly = studio
	return result
end

task.spawn(function()
	while task.wait(50) do
		for userId in cache do
			if not studio then
				task.spawn(function()
					local ok = Profiles.transact(userId, function() return true, "lease" end)
					if not ok then
						local player = game:GetService("Players"):GetPlayerByUserId(userId)
						if player then player:Kick("Your save connection was interrupted. Rejoin to protect your progress.") end
					end
				end)
			end
		end
	end
end)
return Profiles
