local parts = {"Alfa",
"Bravo",
"Charlie",
"Delta",
"Echo",
"Foxtrot",
"Golf",
"Hotel",
"India",
"Juliett",
"Kilo",
"Lima",
"Miko",
"November",
"Oscar",
"Papa",
"Quebec",
"Romeo",
"Sierra",
"Tango",
"Uniform",
"Victor",
"Whiskey",
"X-ray",
"Yankee",
"Zulu"
}

local PlayerMeta = FindMetaTable("Player")

function GM:GenerateName(words)
	local name
	for i = 1, words do
		local word = parts[math.random(#parts)]
		if !name then
			name = word
		else
			name = name .. " " .. word
		end
	end
	return name
end

function PlayerMeta:GenerateBystanderName()
	local name = GAMEMODE:GenerateName(1)
	self:SetNWString("bystanderName", name)
	self.BystanderName = name
end

function PlayerMeta:GetBystanderName()
	local name = self:GetNWString("bystanderName")
	if !name || name == "" then
		return "Bystander" 
	end
	return name
end

concommand.Add("mu_print_players", function (admin, com, args)
	if !admin:IsAdmin() then return end

	for k, ply in pairs(player.GetAll()) do
		local c = ChatText()
		c:Add(ply:Nick())
		local col = ply:GetPlayerColor()
		c:Add(" " .. ply:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		c:Add(" " .. ply:SteamID())
		c:Add(" " .. team.GetName(ply:Team()), team.GetColor(ply:Team()))
		c:Send(admin)
	end
end)