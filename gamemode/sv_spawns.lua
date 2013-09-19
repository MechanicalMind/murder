if !TeamSpawns then
	TeamSpawns = {}
	TeamSpawns['spawns'] = {}
end

function GM:LoadSpawns() 
	for listName, spawnList in pairs(TeamSpawns) do
		local jason = file.Read("murder/" .. game.GetMap() .. "/spawns/" .. listName .. ".txt", "DATA")
		if jason then
			local tbl = util.JSONToTable(jason)
			TeamSpawns[listName] = tbl
		end
	end
end

function GM:SaveSpawns()

	// ensure the folders are there
	if !file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local mapName = game.GetMap()
	if !file.Exists("murder/" .. mapName .. "/","DATA") then
		file.CreateDir("murder/" .. mapName)
	end

	if !file.Exists("murder/" .. mapName .. "/spawns/","DATA") then
		file.CreateDir("murder/" .. mapName .. "/spawns")
	end

	// JSON!
	for listName, spawnList in pairs(TeamSpawns) do
		local jason = util.TableToJSON(spawnList)
		file.Write("murder/" .. mapName .. "/spawns/" .. listName .. ".txt", jason)
	end
end

local function getPosPrintString(pos, plyPos) 
	return math.Round(pos.x) .. "," .. math.Round(pos.y) .. "," .. math.Round(pos.z) .. " " .. math.Round(pos:Distance(plyPos) / 12) .. "ft"
end

concommand.Add("th_spawn_add", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	table.insert(spawnList, ply:GetPos())

	ply:ChatPrint("Added " .. #spawnList .. ": " .. getPosPrintString(ply:GetPos(), ply:GetPos()) )

	GAMEMODE:SaveSpawns()
end)

concommand.Add("th_spawn_list", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	ply:ChatPrint("SpawnList " ..  args[1])
	for k, pos in pairs(spawnList) do
		ply:ChatPrint(k .. ": " .. getPosPrintString(pos,ply:GetPos()) )
	end
end)

concommand.Add("th_spawn_closest", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	if #spawnList <= 0 then
		ply:ChatPrint("List is empty")
		return
	end

	local closest
	for k, pos in pairs(spawnList) do
		if !closest || (spawnList[closest]:Distance(ply:GetPos()) > pos:Distance(ply:GetPos())) then
			closest = k
		end
	end

	ply:ChatPrint(closest .. ": " .. getPosPrintString(spawnList[closest],ply:GetPos()) )
end)

concommand.Add("th_spawn_remove", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 2 then
		ply:ChatPrint("Too few args (spawnList, key)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	local key = tonumber(args[2]) or 0
	if !spawnList[key] then
		ply:ChatPrint("Invalid key, position inexists")
		return
	end

	local pos = spawnList[key]
	table.remove(spawnList, key)
	ply:ChatPrint("Remove " .. key .. ": " .. getPosPrintString(pos, ply:GetPos()) )

	GAMEMODE:SaveSpawns()
end)