local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

function GM:PlayerInitialSpawn( ply )
	ply.LootCollected = 0
	ply.MurdererChance = 1

	timer.Simple(0, function ()
		if IsValid(ply) then
			ply:KillSilent()
		end
	end)
	
	ply.HasMoved = true
	ply:SetTeam(2)

	self:NetworkRound(ply)

end

function GM:PlayerSpawn( ply )

	-- If the player doesn't have a team
	-- then spawn him as a spectator
	if ply:Team() == 1 || ply:Team() == TEAM_UNASSIGNED then

		GAMEMODE:PlayerSpawnAsSpectator( ply )
		return
	
	end

	-- Stop observer mode
	ply.Spectating = nil
	ply:UnSpectate()

	player_manager.OnPlayerSpawn( ply )
	player_manager.RunClass( ply, "Spawn" )

	hook.Call( "PlayerLoadout", GAMEMODE, ply )
	hook.Call( "PlayerSetModel", GAMEMODE, ply )

	ply:CalculateSpeed()

	local oldhands = ply:GetHands()
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		-- Which hands should we use?
		local cl_playermodel = ply:GetInfo( "cl_playermodel" )
		local info = player_manager.TranslatePlayerHands( cl_playermodel )
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
 	end

 	local spawnPoint = self:PlayerSelectTeamSpawn(ply:Team(), ply)
 	if IsValid(spawnPoint) then
 		ply:SetPos(spawnPoint:GetPos())
 	end

 	local vec = Vector(0,0,0)
 	vec.x = math.Rand(0, 1)
 	vec.y = math.Rand(0, 1)
 	vec.z = math.Rand(0, 1)
 	ply:SetPlayerColor(vec)
end

function GM:PlayerLoadout(ply)

	ply:Give("weapon_rp_hands")
	-- ply:Give("weapon_fists")

	if ply:GetMurderer() then
		ply:Give("weapon_mu_knife")
	end


end

local playerModels = {}
local function addModel(model, sex)
	local t = {}
	t.model = model
	t.sex = sex
	table.insert(playerModels, t)
end

addModel("male03", "male")
addModel("male04", "male")
addModel("male05", "male")
addModel("male07", "male")
addModel("male06", "male")
addModel("male09", "male")
addModel("male01", "male")
addModel("male02", "male")
addModel("male08", "male")
addModel("female06", "female")
addModel("female01", "female")
addModel("female03", "female")
addModel("female05", "female")
addModel("female02", "female")
addModel("female04", "female")
addModel("refugee01", "male")
addModel("refugee02", "male")
addModel("refugee03", "male")
addModel("refugee04", "male")

function GM:PlayerSetModel( ply )

	local cl_playermodel = ply:GetInfo( "cl_playermodel" )

	local playerModel = table.Random(playerModels)
	cl_playermodel = playerModel.model

	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )
	util.PrecacheModel( modelname )
	ply:SetModel( modelname )
	ply.ModelSex = playerModel.sex

end

function GM:DoPlayerDeath( ply, attacker, dmginfo )

	for k, weapon in pairs(ply:GetWeapons()) do
		if weapon:GetClass() == "weapon_mu_magnum" then
			ply:DropWeapon(weapon)
		end
	end

	ply:CreateRagdoll()

	local ent = ply:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		ply:SpectateEntity( ent )
		ply:Spectate( OBS_MODE_CHASE )
		ply.Spectating = ent
	end

	ply:AddDeaths( 1 )

	if ( attacker:IsValid() && attacker:IsPlayer() ) then

		if ( attacker == ply ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end

	end

end

local plyMeta = FindMetaTable("Player")

function plyMeta:CalculateSpeed()
	// set the defaults
	local walk,run,canrun = 250,310,false
	local jumppower = 200

	if self:GetMurderer() then
		canrun = true
	end

	if self.LastTKTime then
		walk = walk * 0.7
		run = run * 0.7
		jumppower = jumppower * 0.5
	end

	// handcuffs
	-- if self:GetHandcuffed() then
	-- 	walk = walk * 0.3
	-- 	jumppower = 150
	-- 	canrun = false
	-- end
	-- if self:GetTasered() then
	-- 	walk = 40
	-- 	jumppower = 100
	-- 	canrun = false
	-- end

	// set out new speeds
	if canrun then
		self:SetRunSpeed(run)
	else
		self:SetRunSpeed(walk)
	end
	self.CanRun = canrun
	self:SetWalkSpeed(walk)
	self:SetJumpPower(jumppower)
end

local function isValid() return true end
local function getPos(self) return self.pos end

local function generateSpawnEntities(spawnList)
	local tbl = {}

	for k, pos in pairs(spawnList) do
		local t = {}
		t.IsValid = isValid
		t.GetPos = getPos
		t.pos = pos
		table.insert(tbl, t)
	end

	return tbl
end

function GM:PlayerSelectTeamSpawn( TeamID, pl )

	local SpawnPoints = team.GetSpawnPoints( TeamID )

	SpawnPoints = generateSpawnEntities(TeamSpawns["spawns"])

	if ( !SpawnPoints || table.Count( SpawnPoints ) == 0 ) then return end
	
	local ChosenSpawnPoint = nil
	
	for i=0, 6 do
	
		local ChosenSpawnPoint = table.Random( SpawnPoints )
		if ( GAMEMODE:IsSpawnpointSuitable( pl, ChosenSpawnPoint, i==6 ) ) then
			return ChosenSpawnPoint
		end
	
	end
	
	return ChosenSpawnPoint

end


function GM:PlayerDeathSound()
	// don't play sound
	return true
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	// Don't scale it depending on hitgroup
end

function GM:PlayerDeath(ply, Inflictor, attacker )

	self:DoRoundDeaths(ply, attacker)

	if !ply:GetMurderer() then
		if IsValid(attacker) && attacker:IsPlayer() then
			if attacker:GetMurderer() then
				-- self:SendMessageAll("The murderer has struck again")
			elseif attacker != ply then
				if self.ShowBystanderTKs:GetBool() then
					local ct = ChatText()
					local col = attacker:GetPlayerColor()
					ct:Add(attacker:Nick() .. ", " .. attacker:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
					ct:Add(" killed an innocent bystander")
					ct:SendAll()
				end
				attacker.LastTKTime = CurTime()
				attacker:CalculateSpeed()
				timer.Simple(0, function () 
					if IsValid(attacker) && attacker:HasWeapon("weapon_mu_magnum") then
						local wep = attacker:GetWeapon("weapon_mu_magnum")
						wep.LastTK = attacker
						wep.LastTKTime = CurTime()
						attacker:DropWeapon(wep)
					end
				end)
			end
		else
			-- self:SendMessageAll("An bystander died in mysterious circumstances")
		end
	else
		if attacker != ply && IsValid(attacker) && attacker:IsPlayer() then
			local ct = ChatText()
			local col = attacker:GetPlayerColor()
			ct:Add(attacker:Nick() .. ", " .. attacker:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
			ct:Add(" killed the murderer")
			ct:SendAll()
		else
			local ct = ChatText()
			ct:Add("The murderer died in mysterious circumstances")
			ct:SendAll()
		end
	end

	ply.NextSpawnTime = CurTime() + 5
	ply.DeathTime = CurTime()
	ply.SpectateTime = CurTime() + 4

	umsg.Start("rp_death", ply)
	umsg.Long(5)
	umsg.Long(4)
	umsg.End()
	
	if ( Inflictor && Inflictor == attacker && (Inflictor:IsPlayer() || Inflictor:IsNPC()) ) then
	
		Inflictor = Inflictor:GetActiveWeapon()
		if ( !Inflictor || Inflictor == NULL ) then Inflictor = attacker end
	
	end

	self:RagdollSetDeathDetails(ply, Inflictor, attacker)
end

function GM:PlayerDeathThink( ply )
	if self:CanRespawn(ply) then
		ply:Spawn()

	else

		if ((!ply.SpectateTime || ply.SpectateTime < CurTime()) && ply:KeyPressed(IN_ATTACK))
		 || !IsValid(ply.Spectating) || (ply.Spectating:IsPlayer() && !ply.Spectating:Alive()) then

			// recalculate spectating
			local players = team.GetPlayers(2)
			for k,v in pairs(players) do
				if !(v:Alive()) then
					players[k] = nil
				end
			end

			local ent = table.Random(players)
			if IsValid(ent) then
				ply:SpectateEntity( ent )
				ply:Spectate( OBS_MODE_IN_EYE )
				ply.Spectating = ent
			elseif IsValid(ply.Spectating) then
				if ply.Spectating != ply:GetRagdollEntity() then
					ply:SpectateEntity( ply:GetRagdollEntity() )
					ply:Spectate( OBS_MODE_CHASE )
					ply.Spectating = ply:GetRagdollEntity()
				end
			elseif ply.Spectating then
				ply.Spectating = nil
				ply:Spectate( OBS_MODE_ROAMING )
			end
		end

	end
	
end

function EntityMeta:GetPlayerColor()
	return self.playerColor or Vector()
end

function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
	self:SetNWVector("playerColor", vec)
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootstepsOnFootstep(ply, pos, foot, sound, volume, filter)
end

function GM:PlayerCanPickupWeapon( ply, ent )

	// can't pickup a weapon twice
	if ply:HasWeapon(ent:GetClass()) then
		return false
	end

	if ent:GetClass() == "weapon_mu_magnum" then
		// murderer can't have the gun
		if ply:GetMurderer() then
			return false
		end

		// penalty for killing a bystander
		if ent.LastTK == ply && ent.LastTKTime + 20 > CurTime() then
			return false
		end
	end

	if ent:GetClass() == "weapon_mu_knife" then
		// bystanders can't have the knife
		if !ply:GetMurderer() then
			return false
		end
	end

	return true
end

function GM:PlayerCanHearPlayersVoice( listener, talker ) 
	return self:PlayerCanHearChatVoice(listener, talker) 
end

function GM:PlayerCanHearChatVoice(listener, talker) 
	if self.RoundStage != 1 then
		return true
	end
	if !listener:Alive() || listener:Team() != 2 then
		return true
	end
	if talker:Team() != 2 then
		return false
	end
	if !talker:Alive() then
		return false
	end
	return true
end

function GM:PlayerDisconnected(ply)
	self:PlayerLeavePlay(ply)
end

function GM:PlayerOnChangeTeam(ply, newTeam, oldTeam) 
	if oldTeam == 2 then
		self:PlayerLeavePlay(ply)	
	end
	ply:SetMurderer(false)
	if newteam == 1 then
		
	end
	ply.HasMoved = true
	ply:KillSilent()
end

concommand.Add("mu_jointeam", function (ply, com, args)
	if ply.LastChangeTeam && ply.LastChangeTeam + 10 > CurTime() then return end
	ply.LastChangeTeam = CurTime()

	local curTeam = ply:Team()
	local newTeam = tonumber(args[1] or "") or 0
	if newTeam >= 1 && newTeam <= 2 && newTeam != curTeam then
		ply:SetTeam(newTeam)
		GAMEMODE:PlayerOnChangeTeam(ply, newTeam, curTeam)
		local ct = ChatText()
		ct:Add(ply:Nick() .. " changed team to ")
		ct:Add(team.GetName(newTeam), team.GetColor(newTeam))
		ct:SendAll()
	end
end)

concommand.Add("mu_movetospectate", function (ply, com, args)
	if !ply:IsAdmin() then return end
	if #args < 1 then return end

	local ent = Entity(tonumber(args[1]) or -1)
	if !IsValid(ent) || !ent:IsPlayer() then return end
	
	local curTeam = ent:Team()
	if 1 != curTeam then
		ent:SetTeam(1)
		GAMEMODE:PlayerOnChangeTeam(ent, 1, curTeam)
		local ct = ChatText()
		ct:Add(ent:Nick() .. " was moved to ")
		ct:Add(team.GetName(1), team.GetColor(1))
		ct:SendAll()
	end
end)

function GM:PlayerCanSeePlayersChat( text, teamOnly, listener, speaker )
	return self:PlayerCanHearChatVoice(listener, speaker) 
end

function GM:PlayerSay( ply, text, team)
	if ply:Team() == 2 && ply:Alive() && self:GetRound() != 0 then
		local ct = ChatText()
		local col = ply:GetPlayerColor()
		ct:Add(ply:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
		ct:Add(": " .. text, color_white)
		ct:SendAll()
		return false
	end
	return true
end

function GM:PlayerShouldTaunt( ply, actid )
	return false
end

function GM:KeyPress( ply, key )
	if key == IN_USE then
		local tr = ply:GetEyeTraceNoCursor()

		// press e on windows to break them
		if IsValid(tr.Entity) && (tr.Entity:GetClass() == "func_breakable" || tr.Entity:GetClass() == "func_breakable_surf") && tr.HitPos:Distance(tr.StartPos) < 50 then
	 		local dmg = DamageInfo()
	 		dmg:SetAttacker(game.GetWorld())
	 		dmg:SetInflictor(game.GetWorld())
	 		dmg:SetDamage(10)
	 		dmg:SetDamageType(DMG_BULLET)
	 		dmg:SetDamageForce(ply:GetAimVector() * 500)
	 		dmg:SetDamagePosition(tr.HitPos)
	 		tr.Entity:TakeDamageInfo(dmg)
		end
	end
end