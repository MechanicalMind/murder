
GM.RoundStage = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
end

// 0 not enough players
// 1 playing
// 2 end, about to restart
function GM:RoundThink()
	if self.RoundStage == 0 then
		
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
		

		if !dead:GetMurderer() then
			if IsValid(attacker) && attacker:IsPlayer() then
				if attacker:GetMurderer() then
					-- self:SendMessageAll("The murderer has struck again")
				else
					self:SendMessageAll("A bystander was killed by " .. attacker:Nick())
				end
			else
				-- self:SendMessageAll("An bystander died in mysterious circumstances")
			end
		else
			if attacker != dead && IsValid(attacker) && attacker:IsPlayer() then
				self:SendMessageAll(attacker:Nick() .. " killed the murderer")
			else
				self:SendMessageAll("The murderer died in mysterious circumstances")
			end
		end

		

	end
end

// 1 Murderer wins
// 2 Murderer loses
// 3 Murderer rage quit
function GM:EndTheRound(reason, murderer)
	if self.RoundStage != 1 then return end

	if reason == 3 then
		if murderer then
			self:SendMessageAll("Murderer rage quit, it was " .. murderer:Nick())
		else
			self:SendMessageAll("Murderer rage quit")
		end
	elseif reason == 2 then
		self:SendMessageAll("Bystanders win! The murderer was " .. murderer:Nick())
	elseif reason == 1 then
		if murderer:Alive() then
			self:SendMessageAll("The murderer wins! He was " .. murderer:Nick())
		else
			self:SendMessageAll("The murderer wins at the cost of his own life. He was " .. murderer:Nick())
		end
	end
	self:OnEndRound()
	self.RoundStage = 2
	self.RoundTime = CurTime()
end

function GM:StartNewRound()
	self:SendMessageAll("New round has started")
	self.RoundStage = 1
	self.RoundTime = CurTime()

	local players = team.GetPlayers(2)
	for k,ply in pairs(players) do
		ply:UnSpectate()
	end
	game.CleanUpMap()
	self:ClearAllFootsteps()
	local murderer = table.Random(players)
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