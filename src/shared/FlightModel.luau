--!strict
-- Guided-route arcade flight. All integration occurs on the server.
local Flight = {}
function Flight.new(config: any): any
	return { Z = 0, X = 0, Altitude = config.GearHeight, Speed = 0, VerticalSpeed = 0,
		Bank = 0, Pitch = 0, Throttle = 0, Autopilot = false, Gear = true, Phase = "Taxi", Rough = 0, GoArounds = 0 }
end

function Flight.goAround(f: any, config: any)
	f.Z = config.ApproachStart - 800; f.Altitude = 210; f.X = 0; f.Speed = 95
	f.VerticalSpeed = 0; f.Pitch = 0; f.Bank = 0; f.Throttle = 0.8
	f.Gear = true; f.Autopilot = false; f.Phase = "Approach"; f.GoArounds += 1
end

function Flight.step(f: any, input: any, dt: number, c: any): string?
	dt = math.clamp(dt, 0, 0.1)
	local bank = math.clamp(input.Bank or 0, -1, 1)
	local pitch = math.clamp(input.Pitch or 0, -1, 1)
	f.Throttle = math.clamp(f.Throttle + (input.Throttle or 0) * dt * 0.35, 0, 1)
	local targetSpeed = f.Throttle * 145
	if f.Autopilot and f.Phase == "Cruise" then
		targetSpeed = c.CruiseSpeed; f.Throttle = c.CruiseSpeed / 145
		pitch = math.clamp((c.CruiseAltitude - f.Altitude) / (80 - ((f.Crew and f.Crew.Cruise or 60) - 60)), -0.5, 0.5)
		bank = math.clamp(-f.X / (120 - ((f.Crew and f.Crew.Navigation or 60) - 60) * 2), -0.4, 0.4)
	end
	local oldSpeed = f.Speed
	f.Speed += math.clamp(targetSpeed - f.Speed, -16 * dt, 12 * dt)
	local safety = ((f.Crew and f.Crew.Safety or 60) - 60) * 0.003
	local response = 2 + ((f.Crew and (if f.Phase == "Approach" then f.Crew.Landing else f.Crew.Takeoff) or 60) - 60) * 0.01
	f.Bank += (bank * 30 * (1 - safety) - f.Bank) * math.min(1, dt * 2)
	f.Pitch += (pitch * 16 - f.Pitch) * math.min(1, dt * response)
	f.X = math.clamp(f.X + math.sin(math.rad(f.Bank)) * f.Speed * dt * 0.5, -c.MaxLateral, c.MaxLateral)
	local airborne = f.Phase ~= "Taxi" or f.Altitude > c.GearHeight + 0.001 or (f.Speed >= c.RotateSpeed and pitch > 0.1)
	if airborne then
		local stallSink = math.max(0, 58 - f.Speed) * 0.7
		local desiredVS = math.sin(math.rad(f.Pitch)) * f.Speed - stallSink
		f.VerticalSpeed += (desiredVS - f.VerticalSpeed) * math.min(1, dt * 1.5)
	else f.VerticalSpeed = 0 end
	f.Altitude = math.clamp(f.Altitude + f.VerticalSpeed * dt, c.GearHeight, c.MaxAltitude)
	f.Z += f.Speed * dt
	if math.abs(f.Bank) > 24 or math.abs(f.Speed - oldSpeed) / math.max(dt, 0.001) > 14 then f.Rough += dt end
	if f.Phase == "Taxi" and f.Altitude > 18 then f.Phase = "Climb"; return "Takeoff" end
	if f.Phase == "Taxi" and (f.Z > 1800 or math.abs(f.X) > c.RunwayHalfWidth) then Flight.goAround(f, c); return "Recovery" end
	if f.Phase == "Climb" and f.Altitude >= 180 then f.Phase = "Cruise"; return "Cruise" end
	if f.Z >= c.ApproachStart and f.Phase ~= "Approach" then
		f.Phase = "Approach"; f.Autopilot = false; return "Approach"
	end
	if f.Altitude <= c.GearHeight + 0.01 and f.Phase ~= "Taxi" then
		if f.Z >= c.RunwayStart and f.Z <= c.RunwayEnd and math.abs(f.X) <= c.RunwayHalfWidth
			and f.Speed >= c.LandingSpeedMin and f.Speed <= c.LandingSpeedMax and f.Gear and math.abs(f.Bank) < 12 then
			f.Phase = "Landed"; return "Landed"
		end
		Flight.goAround(f, c); return "Recovery"
	end
	if f.Z > c.RunwayEnd then Flight.goAround(f, c); return "Recovery" end
	return nil
end

return Flight
