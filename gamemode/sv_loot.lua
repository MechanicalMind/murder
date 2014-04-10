local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

if !LootItems then
	LootItems = {}
end

local LootModels = {}
LootModels["breenbust"] = "models/props_combine/breenbust.mdl"
LootModels["huladoll"] = "models/props_lab/huladoll.mdl"
LootModels["beer1"] = "models/props_junk/glassbottle01a.mdl"
LootModels["beer2"] = "models/props_junk/glassjug01.mdl"
LootModels["cactus"] = "models/props_lab/cactus.mdl"
LootModels["lamp"] = "models/props_lab/desklamp01.mdl"
LootModels["clipboard"] = "models/props_lab/clipboard.mdl"
LootModels["suitcase1"] = "models/props_c17/suitcase_passenger_physics.mdl"
LootModels["suitcase2"] = "models/props_c17/suitcase001a.mdl"
LootModels["battery"] = "models/items/car_battery01.mdl"
LootModels["turtle"] = "models/props/de_tides/vending_turtle.mdl"
LootModels["toothbrush"] = "models/props/cs_militia/toothbrushset01.mdl"
LootModels["circlesaw"] = "models/props/cs_militia/circularsaw01.mdl"
LootModels["axe"] = "models/props/cs_militia/axe.mdl"
LootModels["skull"] = "models/Gibs/HGIBS.mdl"
LootModels["baby"] = "models/props_c17/doll01.mdl"
LootModels["antlionhead"] = "models/Gibs/Antlion_gib_Large_2.mdl"
LootModels["briefcase"] = "models/props_c17/BriefCase001a.mdl"
LootModels["breenclock"] = "models/props_combine/breenclock.mdl"
LootModels["sawblade"] = "models/props_junk/sawblade001a.mdl"
LootModels["wrench"] = "models/props_c17/tools_wrench01a.mdl"
LootModels["consolebox"] = "models/props_c17/consolebox01a.mdl"
LootModels["cashregister"] = "models/props_c17/cashregister01a.mdl"
LootModels["bananabunch"] = "models/props/cs_italy/bananna_bunch.mdl"
LootModels["banana"] = "models/props/cs_italy/bananna.mdl"
LootModels["orange"] = "models/props/cs_italy/orange.mdl"
LootModels["familyphoto"] = "models/props_lab/frame002a.mdl"

local FruitModels = {
	"models/props/cs_italy/bananna_bunch.mdl",
	"models/props/cs_italy/orange.mdl",
	"models/props/cs_italy/bananna.mdl",
	"models/props_junk/watermelon01.mdl"
}

util.AddNetworkString("GrabLoot")
util.AddNetworkString("SetLoot")

function GM:LoadLootData() 
	local mapName = game.GetMap()
	local jason = file.ReadDataAndContent("murder/" .. mapName .. "/loot.txt")
	if jason then
		local tbl = util.JSONToTable(jason)
		LootItems = tbl
	end
end

function GM:CountLootItems()
	return #LootItems
end

function GM:SpawnLoot()
	for k, ent in pairs(ents.FindByClass("mu_loot")) do
		ent:Remove()
	end

	for k, data in pairs(LootItems) do
		self:SpawnLootItem(data)
	end
end

function GM:SpawnLootItem(data)
	for k, ent in pairs(ents.FindByClass("mu_loot")) do
		if ent.LootData == data then
			ent:Remove()
		end
	end

	local ent = ents.Create("mu_loot")
	ent:SetModel(data.model)
	ent:SetPos(data.pos)
	ent:SetAngles(data.angle)
	ent:Spawn()

	ent.LootData = data
	-- print(data.pos, data.model, ent)

	return ent
end

function GM:LootThink()
	if self:GetRound() == 1 then

		if !self.LastSpawnLoot || self.LastSpawnLoot < CurTime() then
			self.LastSpawnLoot = CurTime() + 12

			local data = table.Random(LootItems)
			if data then
				self:SpawnLootItem(data)
			end
		end
	end
end

function GM:SaveLootData()

	// ensure the folders are there
	if !file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local mapName = game.GetMap()
	if !file.Exists("murder/" .. mapName .. "/","DATA") then
		file.CreateDir("murder/" .. mapName)
	end

	// JSON!
	local jason = util.TableToJSON(LootItems)
	file.Write("murder/" .. mapName .. "/loot.txt", jason)
end

function GM:AddLootItem(ent)
	local data = {}
	data.model = ent:GetModel()
	data.material = ent:GetMaterial()
	data.pos = ent:GetPos()
	data.angle = ent:GetAngles()
	table.insert(LootItems, data)
end

local function giveMagnum(ply)
	// if they already have the gun, drop the first and give them a new one
	if ply:HasWeapon("weapon_mu_magnum") then
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	end
	if ply:GetTKer() then
		// if they are penalised, drop the gun on the floor
		ply.TempGiveMagnum = true // temporarily allow them to pickup the gun
		ply:Give("weapon_mu_magnum")
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	else
		ply:Give("weapon_mu_magnum")
		ply:SelectWeapon("weapon_mu_magnum")
	end
end

function GM:PlayerPickupLoot(ply, ent)
	ply.LootCollected = ply.LootCollected + 1

	if !ply:GetMurderer() then
		if ply.LootCollected == 5 then
			giveMagnum(ply)
		end
		if ply.LootCollected % 15 == 0 then
			giveMagnum(ply)
		end
	end

	ply:EmitSound("ambient/levels/canals/windchime2.wav", 100, math.random(40,160))
	ent:Remove()

	net.Start("GrabLoot")
	net.WriteUInt(ply.LootCollected, 32)
	net.Send(ply)
end

function PlayerMeta:GetLootCollected()
	return self.LootCollected
end

function PlayerMeta:SetLootCollected(loot)
	self.LootCollected = loot
	net.Start("SetLoot")
	net.WriteUInt(self.LootCollected, 32)
	net.Send(self)
end

local function getLootPrintString(data, plyPos) 
	local str = math.Round(data.pos.x) .. "," .. math.Round(data.pos.y) .. "," .. math.Round(data.pos.z) .. " " .. math.Round(data.pos:Distance(plyPos) / 12) .. "ft"
	str = str .. " " .. data.model
	return str
end

concommand.Add("mu_loot_add", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (model)")
		return
	end

	local mdl = args[1]

	local name = args[1]:lower()
	if name == "rand" || name == "random" then
		mdl = table.Random(LootModels)
	elseif name == "fruit" then
		mdl = table.Random(FruitModels)
	elseif !name:find("%.mdl$") then
		if !LootModels[name] then
			ply:ChatPrint("Invalid model alias " .. name)
			return
		end

		mdl = LootModels[name]
	end


	local data = {}
	data.model = mdl
	data.pos = ply:GetEyeTrace().HitPos
	data.angle = ply:GetAngles() * 1
	data.angle.p = 0
	table.insert(LootItems, data)

	ply:ChatPrint("Added " .. #LootItems .. ": " .. getLootPrintString(data, ply:GetPos()) )

	GAMEMODE:SaveLootData()

	local ent = GAMEMODE:SpawnLootItem(data)
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local pos = ent:GetPos()
	pos.z = pos.z - mins.z
	ent:SetPos(pos)

	data.pos = pos
	GAMEMODE:SaveLootData()
end)

concommand.Add("mu_loot_list", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")
		return
	end


	ply:ChatPrint("Loot items ")
	for k, pos in pairs(LootItems) do
		ply:ChatPrint(k .. ": " .. getLootPrintString(pos, ply:GetPos()) )
	end
end)

concommand.Add("mu_loot_closest", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")
		return
	end

	if #LootItems <= 0 then
		ply:ChatPrint("Loot list is empty")
		return
	end

	local closest
	for k, data in pairs(LootItems) do
		if !closest || (LootItems[closest].pos:Distance(ply:GetPos()) > data.pos:Distance(ply:GetPos())) then
			closest = k
		end
	end

	ply:ChatPrint(closest .. ": " .. getLootPrintString(LootItems[closest], ply:GetPos()) )
end)

concommand.Add("mu_loot_remove", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (key)")
		return
	end

	local key = tonumber(args[1]) or 0
	if !LootItems[key] then
		ply:ChatPrint("Invalid key, position inexists")
		return
	end

	local data = LootItems[key]
	table.remove(LootItems, key)
	ply:ChatPrint("Remove " .. key .. ": " .. getLootPrintString(data, ply:GetPos()) )

	GAMEMODE:SaveLootData()
end)

concommand.Add("mu_loot_adjustpos", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")
		return
	end

	local key
	local ent = ply:GetEyeTrace().Entity
	if IsValid(ent) && ent:GetClass() == "mu_loot" && ent.LootData then
		for k,v in pairs(LootItems) do
			if v == ent.LootData then
				key = k
			end
		end
	end
	if !key then
		ply:ChatPrint("Not a loot item")
		return
	end

	ent.LootData.pos = ent:GetPos()
	ent.LootData.angle = ent:GetAngles()

	ply:ChatPrint("Adjusted " .. key .. ": " .. getLootPrintString(ent.LootData, ply:GetPos()) )

	GAMEMODE:SaveLootData()
end)

concommand.Add("mu_loot_respawn", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	GAMEMODE:SpawnLoot()
end)

concommand.Add("mu_loot_models_list", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	ply:ChatPrint("Loot models")
	for alias, model in pairs(LootModels) do
		ply:ChatPrint(alias .. ": " .. model )
	end
end)