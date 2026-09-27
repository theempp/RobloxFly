--!strict
local Protocol = {}
function Protocol.validPayload(data: any): boolean
	if type(data) ~= "table" then return false end
	local count = 0
	for key, value in data do
		count += 1
		if count > 6 or type(key) ~= "string" or #key > 24 then return false end
		if type(value) == "string" then if #value > 96 then return false end
		elseif type(value) == "number" then if value ~= value or math.abs(value) > 1000000 then return false end
		elseif type(value) ~= "boolean" then return false end
	end
	return true
end
function Protocol.validInput(data: any): boolean
	if not Protocol.validPayload(data) then return false end
	for _, key in { "Bank", "Pitch", "Throttle" } do
		if type(data[key]) ~= "number" or data[key] ~= data[key] or math.abs(data[key]) > 1 then return false end
	end
	return true
end
return Protocol
