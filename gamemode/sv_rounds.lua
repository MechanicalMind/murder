
util.AddNetworkString("SetRound")
util.AddNetworkString("DeclareWinner")

GM.RoundStage = 0
GM.RoundCount = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.RoundCount = GAMEMODE.RoundCount
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:SetRound(round)
	self.RoundStage = round
	self.RoundTime = CurTime()

	self.RoundSettings = {}

	self.RoundSettings.ShowAdminsOnScoreboard = self.ShowAdminsOnScoreboard:GetBool()
	self.RoundSettings.AdminPanelAllowed = self.AdminPanelAllowed:GetBool()
	self.RoundSettings.ShowSpectateInfo = self.ShowSpectateInfo:GetBool()

	self:NetworkRound()
end

function GM:NetworkRound(ply)
	net.Start("SetRound")
	net.WriteUInt(self.RoundStage, 8)
	net.WriteDouble(self.RoundTime)

	if self.RoundSettings then
		net.WriteUInt(1, 8)
		net.WriteUInt(self.RoundSettings.ShowAdminsOnScoreboard and 1 or 0, 8)
		net.WriteUInt(self.RoundSettings.AdminPanelAllowed and 1 or 0, 8)
		net.WriteUInt(self.RoundSettings.ShowSpectateInfo and 1 or 0, 8)
	else
		net.WriteUInt(0, 8)
	end

	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

// 0 not enough players
// 1 playing
// 2 round ended, about to restart
// 4 waiting for map switch
function GM:RoundThink()
	local players = team.GetPlayers(2)
	if self.RoundStage == 0 then
		if #players > 1 && (!self.LastPlayerSpawn || self.LastPlayerSpawn + 1 < CurTime()) then 
			self:StartNewRound()
		end
	elseif self.RoundStage == 1 then
		if !self.RoundLastDeath || self.RoundLastDeath < CurTime() then
			self:RoundCheckForWin()
		end
		if self.RoundUnFreezePlayers && self.RoundUnFreezePlayers < CurTime() then
			self.RoundUnFreezePlayers = nil
			for k, ply in pairs(players) do
				if ply:Alive() then
					ply:Freeze(false)
					ply.Frozen = false
				end
			end
		end
		// after x minutes without a kill reveal the murderer
		local time = self.MurdererFogTime:GetFloat()
		time = math.max(0, time)

		if time > 0 && self.MurdererLastKill && self.MurdererLastKill + time < CurTime() then
			local murderer
			local players = team.GetPlayers(2)
			for k,v in pairs(players) do
				if v:GetMurderer() then
					murderer = v
				end
			end
			if murderer && !murderer:GetMurdererRevealed() then
				murderer:SetMurdererRevealed(true)
				self.MurdererLastKill = nil
			end
		end

	elseif self.RoundStage == 2 then
		if self.RoundTime + 5 < CurTime() then
			self:StartNewRound()
		end
	end
end

function GM:RoundCheckForWin()
	local murderer
	local players = team.GetPlayers(2)
	if #players <= 0 then 
		self:SetRound(0)
		return 
	end
	local survivors = {}
	for k,v in pairs(players) do
		if v:Alive() && !v:GetMurderer() then
			table.insert(survivors, v)
		end
		if v:GetMurderer() then
			murderer = v
		end
	end

	// check we have a murderer
	if !IsValid(murderer) then
		self:EndTheRound(3, murderer)
		return
	end

	// has the murderer killed everyone?
	if #survivors < 1 then
		self:EndTheRound(1, murderer)
		return
	end

	// is the murderer dead?
	if !murderer:Alive() then
		self:EndTheRound(2, murderer)
		return
	end

	// keep playing.
end


function GM:DoRoundDeaths(dead, attacker)
	if self.RoundStage == 1 then
		self.RoundLastDeath = CurTime() + 2
		
	end
end

// 1 Murderer wins
// 2 Murderer loses
// 3 Murderer rage quit
function GM:EndTheRound(reason, murderer)
	if self.RoundStage != 1 then return end

	local players = team.GetPlayers(2)
	for k, ply in pairs(players) do
		ply:SetTKer(false)
		ply:SetMurdererRevealed(false)
		ply:UnMurdererDisguise()
	end

	if reason == 3 then
		if murderer then
			local col = murderer:GetPlayerColor()
			local msgs = Translator:AdvVarTranslate(translate.murdererDisconnectKnown, {
				murderer = {text = murderer:Nick() .. ", " .. murderer:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
			})
			local ct = ChatText(msgs)
			ct:SendAll()
			-- ct:Add(", it was ")
			-- ct:Add(murderer:Nick() .. ", " .. murderer:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		else
			local ct = ChatText()
			ct:Add(translate.murdererDisconnect)
			ct:SendAll()
		end
	elseif reason == 2 then
		local col = murderer:GetPlayerColor()
		local msgs = Translator:AdvVarTranslate(translate.winBystandersMurdererWas, {
			murderer = {text = murderer:Nick() .. ", " .. murderer:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
		})
		local ct = ChatText()
		ct:Add(translate.winBystanders, Color(20, 120, 255))
		ct:AddParts(msgs)
		ct:SendAll()
	elseif reason == 1 then
		local col = murderer:GetPlayerColor()
		local msgs = Translator:AdvVarTranslate(translate.winMurdererMurdererWas, {
			murderer = {text = murderer:Nick() .. ", " .. murderer:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
		})
		local ct = ChatText()
		ct:Add(translate.winMurderer, Color(190, 20, 20))
		ct:AddParts(msgs)
		ct:SendAll()
	end

	net.Start("DeclareWinner")
	net.WriteUInt(reason, 8)
	if murderer then
		net.WriteEntity(murderer)
		net.WriteVector(murderer:GetPlayerColor())
		net.WriteString(murderer:GetBystanderName())
	else
		net.WriteEntity(Entity(0))
		net.WriteVector(Vector(1, 1, 1))
		net.WriteString("?")
	end

	for k, ply in pairs(team.GetPlayers(2)) do
		net.WriteUInt(1, 8)
		net.WriteEntity(ply)
		net.WriteUInt(ply.LootCollected, 32)
		net.WriteVector(ply:GetPlayerColor())
		net.WriteString(ply:GetBystanderName())
	end
	net.WriteUInt(0, 8)

	net.Broadcast()

	for k, ply in pairs(players) do
		if !ply.HasMoved && !ply.Frozen && self.AFKMoveToSpec:GetBool() then
			local oldTeam = ply:Team()
			ply:SetTeam(1)
			GAMEMODE:PlayerOnChangeTeam(ply, 1, oldTeam)

			local col = ply:GetPlayerColor()
			local msgs = Translator:AdvVarTranslate(translate.teamMovedAFK, {
				player = {text = ply:Nick(), color = Color(col.x * 255, col.y * 255, col.z * 255)},
				team = {text = team.GetName(1), color = team.GetColor(2)}
			})
			local ct = ChatText()
			ct:AddParts(msgs)
			ct:SendAll()
		end
		if ply:Alive() then
			ply:Freeze(false)
			ply.Frozen = false
		end
	end
	self.RoundUnFreezePlayers = nil

	self.MurdererLastKill = nil

	hook.Call("OnEndRound")
	hook.Run("OnEndRoundResult", reason)
	self.RoundCount = self.RoundCount + 1
	local limit = self.RoundLimit:GetInt()
	if limit > 0 then
		if self.RoundCount >= limit then
			self:ChangeMap()
			self:SetRound(4)
			return
		end
	end
	self:SetRound(2)
end

function GM:StartNewRound()
	local players = team.GetPlayers(2)
	if #players <= 1 then 
		local ct = ChatText()
		ct:Add(translate.minimumPlayers, Color(255, 150, 50))
		ct:SendAll()
		self:SetRound(0)
		return
	end

	local ct = ChatText()
	ct:Add(translate.roundStarted)
	ct:SendAll()

	self:SetRound(1)
	self.RoundUnFreezePlayers = CurTime() + 10

	local players = team.GetPlayers(2)
	for k,ply in pairs(players) do
		ply:UnSpectate()
	end
	game.CleanUpMap()
	self:InitPostEntityAndMapCleanup()
	self:ClearAllFootsteps()



	local oldMurderer
	for k,v in pairs(players) do
		if v:GetMurderer() then
			oldMurderer = v
		end
	end
	
	local murderer

	// get the weight multiplier
	local weightMul = self.MurdererWeight:GetFloat()

	// pick a random murderer, weighted
	local rand = WeightedRandom()
	for k, ply in pairs(players) do
		rand:Add(ply.MurdererChance ^ weightMul, ply)
		ply.MurdererChance = ply.MurdererChance + 1
	end
	murderer = rand:Roll()

	// allow admins to specify next murderer
	if self.ForceNextMurderer && IsValid(self.ForceNextMurderer) && self.ForceNextMurderer:Team() == 2 then
		murderer = self.ForceNextMurderer
		self.ForceNextMurderer = nil
	end

	if IsValid(murderer) then
		murderer:SetMurderer(true)
	end
	for k, ply in pairs(players) do
		if ply != murderer then
			ply:SetMurderer(false)
		end
		ply:StripWeapons()
		ply:KillSilent()
		ply:Spawn()
		ply:Freeze(true)
		local vec = Vector(0, 0, 0)
		vec.x = math.Rand(0, 1)
		vec.y = math.Rand(0, 1)
		vec.z = math.Rand(0, 1)
		ply:SetPlayerColor(vec)

		ply.LootCollected = 0
		ply.HasMoved = false
		ply.Frozen = true
		ply:SetTKer(false)
		ply:CalculateSpeed()
		ply:GenerateBystanderName()
	end
	local noobs = table.Copy(players)
	table.RemoveByValue(noobs, murderer)
	local magnum = table.Random(noobs)
	if IsValid(magnum) then
		magnum:Give("weapon_mu_magnum")
	end

	self.MurdererLastKill = CurTime()

	hook.Call("OnStartRound")
end

function GM:PlayerLeavePlay(ply)
	if ply:HasWeapon("weapon_mu_magnum") then
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	end

	if self.RoundStage == 1 then
		if ply:GetMurderer() then
			self:EndTheRound(3, ply)
		end
	end
end

concommand.Add("mu_forcenextmurderer", function (ply, com, args)
	if !ply:IsAdmin() then return end
	if #args < 1 then return end

	local ent = Entity(tonumber(args[1]) or -1)
	if !IsValid(ent) || !ent:IsPlayer() then 
		ply:ChatPrint("not a player")
		return 
	end

	GAMEMODE.ForceNextMurderer = ent
	local msgs = Translator:AdvVarTranslate(translate.adminMurdererSelect, {
		player = {text = ent:Nick(), color = team.GetColor(2)}
	})
	local ct = ChatText()
	ct:AddParts(msgs)
	ct:Send(ply)
end)

function GM:ChangeMap()
	if #self.MapList > 0 then
		if MapVote then
			// only match maps that we have specified
			local prefix = {}
			for k, map in pairs(self.MapList) do
				table.insert(prefix, map .. "%.bsp$")
			end
			MapVote.Start(nil, nil, nil, prefix)
			return
		end
		self:RotateMap()
	end
end

function GM:RotateMap()
	local map = game.GetMap()
	local index 
	for k, map2 in pairs(self.MapList) do
		if map == map2 then
			index = k
		end
	end
	if !index then index = 1 end
	index = index + 1
	if index > #self.MapList then
		index = 1
	end
	local nextMap = self.MapList[index]
	print("[Murder] Rotate changing map to " .. nextMap)
	local ct = ChatText()
	ct:Add(Translator:QuickVar(translate.mapChange, "map", nextMap))
	ct:SendAll()
	hook.Call("OnChangeMap", GAMEMODE)
	timer.Simple(5, function ()
		RunConsoleCommand("changelevel", nextMap)
	end)
end

GM.MapList = {}

local defaultMapList = {
	"clue",
	"cs_italy",
	"ttt_clue",
	"cs_office",
	"de_chateau",
	"de_tides",
	"de_prodigy",
	"mu_nightmare_church",
	"dm_lockdown",
	"housewithgardenv2",
	"de_forest"
}

function GM:SaveMapList()

	// ensure the folders are there
	if !file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local txt = ""
	for k, map in pairs(self.MapList) do
		txt = txt .. map .. "\r\n"
	end
	file.Write("murder/maplist.txt", txt)
end

function GM:LoadMapList() 
	local jason = file.ReadDataAndContent("murder/maplist.txt")
	if jason then
		local tbl = {}
		local i = 1
		for map in jason:gmatch("[^\r\n]+") do
			table.insert(tbl, map)
		end
		self.MapList = tbl
	else
		local tbl = {}
		for k, map in pairs(defaultMapList) do
			if file.Exists("maps/" .. map .. ".bsp", "GAME") then
				table.insert(tbl, map)
			end
		end
		self.MapList = tbl
		self:SaveMapList()
	end
end
