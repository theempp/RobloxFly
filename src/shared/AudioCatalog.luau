-- Original WAVs live in assets/audio. Upload to the experience owner, then set IDs.
-- An empty ID deliberately stays silent; essential audio has captions.
return {
	Hangar = { Id = "", Loop = true, Volume = 0.18, Caption = "Hangar ventilation" },
	Turbine = { Id = "", Loop = true, Volume = 0.45, Caption = "Turbines spooling" },
	Wind = { Id = "", Loop = true, Volume = 0.14, Caption = "Cabin air" },
	Phone = { Id = "", Volume = 0.35, Caption = "New charter offers" },
	Door = { Id = "", Volume = 0.30, Caption = "Cabin door secured" },
	Service = { Id = "", Volume = 0.30, Caption = "Client service requested" },
	Touchdown = { Id = "", Volume = 0.45, Caption = "Main gear touchdown" },
	Results = { Id = "", Volume = 0.35, Caption = "Charter complete" },
	Gear = { Id = "", Volume = 0.30, Caption = "Landing gear moving" },
}
