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