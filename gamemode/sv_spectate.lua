util.AddNetworkString("spectating_status")

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:CSpectate(mode, spectatee)
	mode = mode || OBS_MODE_IN_EYE
	self:Spectate(mode)
	if IsValid(spectatee) then
		self:SpectateEntity(spectatee)
		self.Spectatee = spectatee
	else
		self.Spectatee = nil
	end
	self.SpectateMode = mode
	self.Spectating = true
	net.Start("spectating_status")
	net.WriteInt(self.SpectateMode or -1, 8)
	net.WriteEntity(self.Spectatee or Entity(-1))
	net.Send(self)
end

function PlayerMeta:UnCSpectate(mode, spectatee) 
	self:UnSpectate()
	self.SpectateMode = nil
	self.Spectatee = nil
	self.Spectating = false
	net.Start("spectating_status")
	net.WriteInt(-1, 8)
	net.WriteEntity(Entity(-1))
	net.Send(self)
end

function PlayerMeta:IsCSpectating() 
	return self.Spectating
end

function PlayerMeta:GetCSpectatee() 
	return self.Spectatee
end

function PlayerMeta:GetCSpectateMode() 
	return self.SpectateMode
end

function GM:SpectateNext(ply, direction)
	direction = direction or 1

	local players = {}
	local index = 1
	for k, v in pairs(team.GetPlayers(2)) do
		if v:Alive() then
			table.insert(players, v)
			if v == ply:GetCSpectatee() then
				index = #players
			end
		end
	end
	if #players > 0 then
		index = index + direction
		if index > #players then
			index = 1
		end
		if index < 1 then
			index = #players
		end

		local ent = players[index]
		if IsValid(ent) then
			ply:CSpectate(OBS_MODE_IN_EYE, ent)
		else
			if IsValid(ply:GetRagdollEntity()) then
				if ply:GetCSpectating() != ply:GetRagdollEntity() then
					ply:CSpectate(OBS_MODE_CHASE, ply:GetRagdollEntity())
				end
			else
				ply:CSpectate(OBS_MODE_ROAMING)
			end
		end
	else
		ply:CSpectate(OBS_MODE_ROAMING)
	end
end

function GM:ChooseSpectatee(ply) 

	-- if ((!ply.SpectateTime || ply.SpectateTime < CurTime()) && ply:KeyPressed(IN_ATTACK))
	--  || !IsValid(ply:GetCSpectatee()) || (ply:GetCSpectatee():IsPlayer() && !ply:GetCSpectatee():Alive()) then

	-- 	// recalculate spectating
	-- 	local players = team.GetPlayers(2)
	-- 	for k,v in pairs(players) do
	-- 		if !(v:Alive()) then
	-- 			players[k] = nil
	-- 		end
	-- 	end

	-- 	local ent = table.Random(players)
	-- 	if IsValid(ent) then
	-- 		ply:CSpectate(OBS_MODE_IN_EYE, ent)
	-- 	elseif IsValid(ply:IsCSpectating()) then
	-- 		if ply:GetCSpectating() != ply:GetRagdollEntity() then
	-- 			ply:CSpectate(OBS_MODE_CHASE, ply:GetRagdollEntity())
	-- 		end
	-- 	elseif ply:IsCSpectating() then
	-- 		ply:CSpectate(OBS_MODE_ROAMING)
	-- 	end
	-- end

	if !ply.SpectateTime || ply.SpectateTime < CurTime() then

		local direction 
		if ply:KeyPressed(IN_ATTACK) then
			direction = 1
		elseif ply:KeyPressed(IN_ATTACK2) then
			direction = -1
		end

		if direction then
			self:SpectateNext(ply, direction)
		end
	end

	// if invalid or dead
	if !IsValid(ply:GetCSpectatee()) || ( ply:GetCSpectatee():IsPlayer() && !ply:GetCSpectatee():Alive() ) then
		self:SpectateNext(ply)
	end
end