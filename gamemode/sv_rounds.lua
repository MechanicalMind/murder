
GM.RoundStage = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
end

function GM:RoundThink()
	if self.RoundStage == 2 then
		if self.RoundTime + 5 < CurTime() then
			self:StartNewRound()
		end
	end
end


function GM:DoRoundDeaths(dead, attacker)
	if self.RoundStage == 1 then
		local murderer
		local players = team.GetPlayers(2)
		if #players == 0 then return end
		for k,v in pairs(players) do
			if !v:Alive() || dead == v then
				players[k] = nil
			end
			if v:GetMurderer() then
				murderer = v
				players[k] = nil
			end
		end
		local c = table.Count(players)

		if !dead:GetMurderer() then
			if attacker:GetMurderer() then
				self:SendMessageAll("The murderer struck again! (" .. c .. " left)")
			else
				self:SendMessageAll("An innocent was killed by " .. attacker:Nick())
			end
		end

		if !murderer then
			self:EndTheRound(3, murderer)
			return
		end
		if !murderer:Alive() || murderer == dead then
			self:EndTheRound(2, murderer)
			return
		end

		if c <= 0 then 
			self:EndTheRound(1, murderer)
			return
		end

		
	end
end

// 1 Murderer wins
// 2 Murderer loses
// 3 Murderer rage quit
function GM:EndTheRound(reason, murderer)
	if self.RoundStage != 1 then return end

	if reason == 3 then
		self:SendMessageAll("Murderer rage quit, it was " .. murderer:Nick())
	elseif reason == 2 then
		self:SendMessageAll("Murderer died, it was " .. murderer:Nick())
	elseif reason == 1 then
		self:SendMessageAll("Murderer killed everyone, it was " .. murderer:Nick())
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
	murderer:SetMurderer(true)
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