--!strict
-- Starting balance values. No product IDs or purchased training tokens.
return {
	Schema = 1,
	DataStore = "PJCT_Profile_v1",
	StartingCredits = 2400,
	OfferLifetime = 150,
	Flight = { Step = 1 / 30, InputHz = 10, SnapshotHz = 4, RouteLength = 15000,
		RotateSpeed = 72, CruiseSpeed = 112, LandingSpeedMin = 45, LandingSpeedMax = 88,
		CruiseAltitude = 260, ApproachStart = 11200, RunwayStart = 13900, RunwayEnd = 15400,
		RunwayHalfWidth = 42, GearHeight = 5.4, MaxAltitude = 520, MaxLateral = 420 },
	Scoring = { Smoothness = 25, Timing = 20, Service = 25, Discretion = 20, Safety = 10 },
	Economy = { CoopBonus = 0.10, DaySeconds = 1200, TrainingCost = 300, SkillStep = 2,
		SkillCap = 85, BadgeCost = 900, HangarCost = 1400, ServiceCost = 1800 },
	Roles = { "Captain", "First Officer", "Cabin Host", "Ground / Security" },
	Jets = {
		aster_l6 = { Name = "Aster L6", Class = "Light", Seats = 6, Range = 2100, Fuel = 1300, Handling = 88, Comfort = 72, Price = 0, Reputation = 0 },
	},
	Destinations = {
		riviera = { Name = "Monaco · Riviera", Code = "RVA", Range = 680, FlightSeconds = 240, Weather = "Coastal haze", Latitude = "43°44′ N" },
	},
	Clients = {
		{ Name = "Elara Voss", Title = "Design director", Party = 3, Fee = 1500, Patience = 50, Preference = "Tea", Mood = "Warm", Privacy = "Covered", Time = 420 },
		{ Name = "Milo Laurent", Title = "Film composer", Party = 2, Fee = 1720, Patience = 42, Preference = "Coffee", Mood = "Quiet", Privacy = "Covered", Time = 400 },
		{ Name = "Sana Vale", Title = "Ocean foundation chair", Party = 4, Fee = 1880, Patience = 38, Preference = "Water", Mood = "Cool", Privacy = "Covered", Time = 380 },
	},
	Teams = {
		pilot_starter = { Name = "Meridian Flight", Category = "Pilot", Grade = "Foundation", Price = 0, Salary = 0, Skills = { Takeoff = 62, Cruise = 66, Navigation = 64, Landing = 60, Safety = 68 } },
		cabin_starter = { Name = "Linen Service", Category = "Cabin", Grade = "Foundation", Price = 0, Salary = 0, Skills = { Speed = 60, Reading = 64, Catering = 62, Composure = 66 } },
		security_starter = { Name = "Quietline", Category = "Security", Grade = "Foundation", Price = 0, Salary = 0, Skills = { Discretion = 62, Crowd = 60, Logistics = 66, Response = 64 } },
		cabin_silk = { Name = "Silk Collective", Category = "Cabin", Grade = "Elite", Price = 2200, Salary = 60, Skills = { Speed = 76, Reading = 80, Catering = 78, Composure = 74 } },
		pilot_horizon = { Name = "Horizon Flight", Category = "Pilot", Grade = "Elite", Price = 2800, Salary = 75, Skills = { Takeoff = 78, Cruise = 76, Navigation = 80, Landing = 76, Safety = 82 } },
		security_velvet = { Name = "Velvet Detail", Category = "Security", Grade = "Elite", Price = 2100, Salary = 55, Skills = { Discretion = 80, Crowd = 76, Logistics = 78, Response = 74 } },
	},
	Badges = {
		cabin_calm = { Name = "Unhurried", TeamCategory = "Cabin", Runs = 5, Benefit = "Client requests allow 5 extra seconds.", Seconds = 5 },
	},
	Season = { Name = "Above the ordinary", Weeks = 5, Enabled = false, PremiumProductId = 0, CompleteProductId = 0 },
	Products = { Credits = { Id = 0, Amount = 10000 } },
	Limits = { MaxCrew = 4, RemoteBurst = 20, RemoteRate = 12, InteractionDistance = 18 },
}
