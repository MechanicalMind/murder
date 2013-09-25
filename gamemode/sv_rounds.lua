
GM.RoundStage = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
end

// 0 not enough players
// 1 playing
// 2 end, about to restart
function GM:RoundThink()
	if self.RoundStage == 0 then
		local players = team.GetPlayers(2)
		if #players > 1 then 
			self:StartNewRound()
		end
	elseif self.RoundStage == 1 then
		if !self.RoundLastDeath || self.RoundLastDeath < CurTime() then
			self:RoundCheckForWin()
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
		self.RoundStage = 0
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

	if reason == 3 then
		local ct = ChatText()
		ct:Add("Murderer rage quit")
		if murderer then
			ct:Add(", it was ")
			local col = murderer:GetPlayerColor()
			ct:Add(murderer:Nick(), Color(col.x * 255, col.y * 255, col.z * 255))
		end
		ct:SendAll()
	elseif reason == 2 then
		local ct = ChatText()
		ct:Add("Bystanders win! ", Color(50, 255, 0))
		ct:Add("The murderer was ")
		local col = murderer:GetPlayerColor()
		ct:Add(murderer:Nick(), Color(col.x * 255, col.y * 255, col.z * 255))
		ct:SendAll()
	elseif reason == 1 then
		local ct = ChatText()
		ct:Add("The murderer wins! ", Color(255, 50, 0))
		ct:Add("He was ")
		local col = murderer:GetPlayerColor()
		ct:Add(murderer:Nick(), Color(col.x * 255, col.y * 255, col.z * 255))
		ct:SendAll()
	end
	self:OnEndRound()
	self.RoundStage = 2
	self.RoundTime = CurTime()
end

function GM:StartNewRound()
	local players = team.GetPlayers(2)
	if #players <= 1 then 
		local ct = ChatText()
		ct:Add("Not enough players to start round", Color(255, 150, 50))
		ct:SendAll()
		self.RoundStage = 0
		return
	end

	local ct = ChatText()
	ct:Add("New round has started")
	ct:SendAll()

	self.RoundStage = 1
	self.RoundTime = CurTime()

	local players = team.GetPlayers(2)
	for k,ply in pairs(players) do
		ply:UnSpectate()
	end
	game.CleanUpMap()
	self:ClearAllFootsteps()

	local oldMurderer
	for k,v in pairs(players) do
		if v:GetMurderer() then
			oldMurderer = v
		end
	end

	local murderer = table.Random(players)
	if murderer == oldMurderer then
		murderer = table.Random(players)
		print(oldMurderer, murderer, "REMADE CHANCES")
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