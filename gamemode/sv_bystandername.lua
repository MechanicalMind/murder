

GM.BystanderNameParts = {}
local function addPart(name, sex)
	local tab = {}
	tab.name = name
	tab.sex = sex
	table.insert(GM.BystanderNameParts, tab)
end

/* Don't add to this list, add names to data/murder/bystander_name_parts.txt */
addPart("Alfa")
addPart("Bravo")
addPart("Charlie")
addPart("Delta")
addPart("Echo")
addPart("Foxtrot")
addPart("Golf")
addPart("Hotel")
addPart("India")
addPart("Juliett")
addPart("Kilo")
addPart("Lima")
addPart("Miko")
addPart("November")
addPart("Oscar")
addPart("Papa")
addPart("Quebec")
addPart("Romeo")
addPart("Sierra")
addPart("Tango")
addPart("Uniform")
addPart("Victor")
addPart("Whiskey")
addPart("X-ray")
addPart("Yankee")
addPart("Zulu")

local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

GM.BystanderWords = CreateClientConVar( "mu_bystandername_words", 1, FCVAR_ARCHIVE, "Number of words to generate for bystander name" )

// adds a name to the bystander parts generation table
function GM:AddBystanderNamePart(name, sex)
	name = tostring(name)
	if !name then error("arg 1 must be a string") end
	if sex != "male" && sex != "female" then sex = nil end
	local tab = {}
	tab.name = name
	tab.sex = sex
	table.insert(self.BystanderNameParts, tab)
end

// removes a name to the bystander parts generation table
function GM:RemoveBystanderNamePart(name, sex)
	for k, v in pairs(self.BystanderNameParts) do
		if v.name == name && v.sex == sex then
			table.remove(self.BystanderNameParts, k)
			break
		end
	end
end

// returns the bystander parts generation table
function GM:GetBystanderNameParts()
	return self.BystanderNameParts
end

function GM:GenerateName(words, sex)
	if #self.BystanderNameParts <= 0 then
		return "error"
	end
	local name
	for i = 1, words do
		local tab = {}
		for k, v in pairs(self.BystanderNameParts) do
			if v.sex == sex || v.sex == nil then
				table.insert(tab, v.name)
			end
		end
		local word = tab[math.random(#tab)]
		if !name then
			name = word
		else
			name = name .. " " .. word
		end
	end
	return name
end

function GM:LoadBystanderNames()
	local text = file.ReadDataAndContent("murder/bystander_name_parts.txt")
	if text then
		local tbl = {}
		local i = 1
		for line in text:gmatch("[^\r\n]+") do
			local name, sex = line:match("([^,]+)/([^,]+)")
			if !name then name = line end
			if sex == "m" then sex = "male" end
			if sex == "f" then sex = "female" end
			if sex != "male" && sex != "female" then sex = nil end
			local tab = {}
			tab.name = name
			tab.sex = sex
			table.insert(tbl, tab)
		end
		self.BystanderNameParts = tbl
	end
end

function EntityMeta:GenerateBystanderName()
	local words = math.max(1, GAMEMODE.BystanderWords:GetInt())
	local name = GAMEMODE:GenerateName(words, self.ModelSex or "male")
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