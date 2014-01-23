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
local EntityMeta = FindMetaTable("Entity")

GM.BystanderWords = CreateClientConVar( "mu_bystandername_words", 1, FCVAR_ARCHIVE, "Number of words to generate for bystander name" )

// adds a name to the bystander parts generation table
function GM:AddBystanderNamePart(name)
	table.insert(parts, name)
end

// removes a name to the bystander parts generation table
function GM:RemoveBystanderNamePart(name)
	table.RemoveByValue(parts, name)
end

// returns the bystander parts generation table
function GM:GetBystanderNameParts()
	return parts
end

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

function EntityMeta:GenerateBystanderName()
	local words = math.max(1, GAMEMODE.BystanderWords:GetInt())
	local name = GAMEMODE:GenerateName(words)
	self:SetNWString("bystanderName", name)
	self.BystanderName = name
end

function EntityMeta:SetBystanderName(name)
	self:SetNWString("bystanderName", name)
	self.BystanderName = name
end

function EntityMeta:GetBystanderName()
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