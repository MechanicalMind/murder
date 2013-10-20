
util.AddNetworkString("SetRound")
util.AddNetworkString("DeclareWinner")

GM.RoundStage = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:SetRound(round)
	self.RoundStage = round
	net.Start("SetRound")
	net.WriteUInt(round, 8)
	net.Broadcast()
	self.RoundTime = CurTime()
end

function GM:NetworkRound(ply)
	net.Start("SetRound")
	net.WriteUInt(self.RoundStage, 8)
	net.Send(ply)
end

// 0 not enough players
// 1 playing
// 2 round ended, about to restart
function GM:RoundThink()
	local players = team.GetPlayers(2)
	if self.RoundStage == 0 then
		if #players > 1 then 
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
		if !ply.HasMoved && !ply.Frozen then
			local oldTeam = ply:Team()
			ply:SetTeam(1)
			GAMEMODE:PlayerOnChangeTeam(ply, 1, oldTeam)
			local ct = ChatText()
			ct:Add(ply:Nick() .. " was moved to ")
			ct:Add(team.GetName(1), team.GetColor(1))
			ct:Add(" for being AFK", color_white)
			ct:SendAll()
		end
		if ply:Alive() then
			ply:Freeze(false)
			ply.Frozen = false
		end
		ply.LastTKTime = nil
	end
	self.RoundUnFreezePlayers = nil

	if reason == 3 then
		local ct = ChatText()
		ct:Add("The murderer rage quit")
		if murderer then
			ct:Add(", it was ")
			local col = murderer:GetPlayerColor()
			ct:Add(murderer:Nick() .. ", " .. murderer:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		end
		ct:SendAll()
	elseif reason == 2 then
		local ct = ChatText()
		ct:Add("Bystanders win! ", Color(20, 120, 255))
		ct:Add("The murderer was ")
		local col = murderer:GetPlayerColor()
		ct:Add(murderer:Nick() .. ", " .. murderer:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		ct:SendAll()
	elseif reason == 1 then
		local ct = ChatText()
		ct:Add("The murderer wins! ", Color(190, 20, 20))
		ct:Add("He was ")
		local col = murderer:GetPlayerColor()
		ct:Add(murderer:Nick() .. ", " .. murderer:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		ct:SendAll()
	end

	net.Start("DeclareWinner")
	net.WriteUInt(reason, 8)
	net.WriteEntity(murderer)

	for k, ply in pairs(team.GetPlayers(2)) do
		net.WriteUInt(1, 8)
		net.WriteEntity(ply)
		net.WriteUInt(ply.LootCollected, 32)
	end
	net.WriteUInt(0, 8)

	net.Broadcast()

	self:OnEndRound()
	self:SetRound(2)
end

function GM:StartNewRound()
	local players = team.GetPlayers(2)
	if #players <= 1 then 
		local ct = ChatText()
		ct:Add("Not enough players to start round", Color(255, 150, 50))
		ct:SendAll()
		self:SetRound(0)
		return
	end

	local ct = ChatText()
	ct:Add("A new round has started")
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

	// don't pick same murderer as last round
	local moMurderer = table.Copy(players)
	table.RemoveByValue(moMurderer, oldMurderer)
	local murderer = table.Random(moMurderer)

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

		ply.LootCollected = 0
		ply.HasMoved = false
		ply.Frozen = true
		ply.LastTKTime = nil
		ply:CalculateSpeed()
		ply:GenerateBystanderName()
	end
	local noobs = table.Copy(players)
	table.RemoveByValue(noobs, murderer)
	local magnum = table.Random(noobs)
	if IsValid(magnum) then
		magnum:Give("weapon_mu_magnum")
	end

	self:OnStartRound()
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