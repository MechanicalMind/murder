util.AddNetworkString("Spawns_View")
util.AddNetworkString("Spawns_ViewChange")


if !TeamSpawns then
	TeamSpawns = {}
	TeamSpawns['spawns'] = {}
end

local function networkList(spawns)
	for k, v in pairs(spawns) do
		net.WriteUInt(k, 32)
		net.WriteVector(v)
	end
	net.WriteUInt(0, 32)
end

local function networkChange(listName)
	local spawns = TeamSpawns[listName]
	if !spawns then return end
	for k, ply in pairs(player.GetAll()) do
		if ply.SpawnsVisualise == listName then
			net.Start("Spawns_ViewChange")
			networkList(spawns)
			net.Send(ply)
		end
	end
end

function GM:LoadSpawns() 
	for listName, spawnList in pairs(TeamSpawns) do
		local jason = file.ReadDataAndContent("murder/" .. game.GetMap() .. "/spawns/" .. listName .. ".txt")
		if jason then
			local tbl = util.JSONToTable(jason)
			TeamSpawns[listName] = tbl
			networkChange(listName)
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

concommand.Add("mu_spawn_counts", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	for k, v in pairs(TeamSpawns) do
		ply:ChatPrint("Spawns: " .. k .. " count " .. table.Count(v))
	end
end)

concommand.Add("mu_spawn_add", function (ply, com, args, full)
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
	networkChange(args[1])
end)

concommand.Add("mu_spawn_list", function (ply, com, args, full)
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

concommand.Add("mu_spawn_closest", function (ply, com, args, full)
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
	if !closest then
		ply:ChatPrint("No closest spawn")
		return
	end

	ply:ChatPrint(closest .. ": " .. getPosPrintString(spawnList[closest],ply:GetPos()) )
end)

concommand.Add("mu_spawn_remove", function (ply, com, args, full)
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
	if args[2] == "closest" then
		local closest
		for k, pos in pairs(spawnList) do
			if !closest || (spawnList[closest]:Distance(ply:GetPos()) > pos:Distance(ply:GetPos())) then
				closest = k
			end
		end
		if !closest then
			ply:ChatPrint("No closest spawn")
			return
		end
		key = closest
	end

	if !spawnList[key] then
		ply:ChatPrint("Invalid key, position inexists")
		return
	end

	local pos = spawnList[key]
	table.remove(spawnList, key)
	ply:ChatPrint("Remove " .. key .. ": " .. getPosPrintString(pos, ply:GetPos()) )

	GAMEMODE:SaveSpawns()
	networkChange(args[1])
end)

concommand.Add("mu_spawn_visualise", function (ply, com, args, full)
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

	if ply.SpawnsVisualise && ply.SpawnsVisualise == args[1] then
		net.Start("Spawns_View")
		net.WriteUInt(0, 8)
		net.Send(ply)
		ply:ChatPrint("Stopped visualising spawns: " .. args[1])
		ply.SpawnsVisualise = nil
		return
	end

	ply.SpawnsVisualise = args[1]

	net.Start("Spawns_View")
	net.WriteUInt(1, 8)
	net.WriteString(ply.SpawnsVisualise)
	networkList(spawnList)
	net.Send(ply)
	ply:ChatPrint("Visualising spawns: " .. args[1])
end)