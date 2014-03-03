local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

local dtypes = {}
dtypes[DMG_GENERIC]=""
dtypes[DMG_CRUSH]="Blunt Force"
dtypes[DMG_BULLET]="Bullet"
dtypes[DMG_SLASH]="Laceration"
dtypes[DMG_BURN]="Fire"
dtypes[DMG_VEHICLE]="Blunt Force"
dtypes[DMG_FALL]="Fall force"
dtypes[DMG_BLAST]="Explosion"
dtypes[DMG_CLUB]="Blunt Force"
dtypes[DMG_SHOCK]="Shock"
dtypes[DMG_SONIC]="Sonic"
dtypes[DMG_ENERGYBEAM]="Enery"
dtypes[DMG_DROWN]="Hydration"
dtypes[DMG_PARALYZE]="Paralyzation"
dtypes[DMG_NERVEGAS]="Nervegas"
dtypes[DMG_POISON]="Poison"
dtypes[DMG_RADIATION]="Radiation"
dtypes[DMG_DROWNRECOVER]=""
dtypes[DMG_ACID]="Acid"
dtypes[DMG_PLASMA]="Plasma"
dtypes[DMG_AIRBOAT]="Energy"
dtypes[DMG_DISSOLVE]="Energy"
dtypes[DMG_BLAST_SURFACE]=""
dtypes[DMG_DIRECT]="Fire"
dtypes[DMG_BUCKSHOT]="Bullet"


local DeathRagdollsPerPlayer = 3
local DeathRagdollsPerServer = 22

if !PlayerMeta.CreateRagdollOld then
	PlayerMeta.CreateRagdollOld = PlayerMeta.CreateRagdoll
end
function PlayerMeta:CreateRagdoll(attacker, dmginfo)
	local ent = self:GetNWEntity("DeathRagdoll")

	// remove old player ragdolls
	if !self.DeathRagdolls then self.DeathRagdolls = {} end
	local countPlayerRagdolls = 1
	for k,rag in pairs(self.DeathRagdolls) do
		if IsValid(rag) then
			countPlayerRagdolls = countPlayerRagdolls + 1
		else
			self.DeathRagdolls[k] = nil
		end
	end
	if DeathRagdollsPerPlayer >= 0 && countPlayerRagdolls > DeathRagdollsPerPlayer then
		for i = 0,countPlayerRagdolls do
			if countPlayerRagdolls > DeathRagdollsPerPlayer then
				self.DeathRagdolls[1]:Remove()
				table.remove(self.DeathRagdolls,1)
				countPlayerRagdolls = countPlayerRagdolls - 1
			else
				break
			end
		end
	end

	// remove old server ragdolls
	local c2 = 1
	for k,rag in pairs(GAMEMODE.DeathRagdolls) do
		if IsValid(rag) then
			c2 = c2 + 1
		else
			GAMEMODE.DeathRagdolls[k] = nil
		end
	end
	if DeathRagdollsPerServer >= 0 && c2 > DeathRagdollsPerServer then
		for i = 0,c2 do
			if c2 > DeathRagdollsPerServer then
				GAMEMODE.DeathRagdolls[1]:Remove()
				table.remove(GAMEMODE.DeathRagdolls,1)
				c2 = c2 - 1
			else
				break
			end
		end
	end

	local Data = duplicator.CopyEntTable( self )

	local ent = ents.Create( "prop_ragdoll" )
		duplicator.DoGeneric( ent, Data )
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ent:Fire("kill","",60 * 8)
	if ent.SetPlayerColor then
		ent:SetPlayerColor(self:GetPlayerColor())
	end
	ent:SetNWEntity("RagdollOwner", self)
	
	ent.Corpse = {}
	ent.Corpse.Name = self:Nick()
	ent.Corpse.CauseDeath = ""
	if dmginfo then
		local t = dmginfo:GetDamageType()
		// do bitmasks
	end
	ent.Corpse.Attacker = ""
	if IsValid(attacker) && attacker:IsPlayer() then
		if attacker == self then
			if ent.Corpse.CauseDeath == "" then
				ent.Corpse.CauseDeath = "Suicide"
			end
		else
			ent.Corpse.Attacker = attacker:Nick()
		end
		local wep = dmginfo:GetInflictor()
		-- inflicter doesn't work, do on GM:PlayerDeath
	end

	// set velocities
	local Vel = self:GetVelocity()

	local iNumPhysObjects = ent:GetPhysicsObjectCount()
	for Bone = 0, iNumPhysObjects-1 do

		local PhysObj = ent:GetPhysicsObjectNum( Bone )
		if IsValid(PhysObj) then

			local Pos, Ang = self:GetBonePosition( ent:TranslatePhysBoneToBone( Bone ) )
			PhysObj:SetPos( Pos )
			PhysObj:SetAngles( Ang )
			PhysObj:AddVelocity( Vel )

		end

	end

	// finish up
	self:SetNWEntity("DeathRagdoll", ent )
	table.insert(self.DeathRagdolls,ent)
	table.insert(GAMEMODE.DeathRagdolls,ent)
end

if !PlayerMeta.GetRagdollEntityOld then
	PlayerMeta.GetRagdollEntityOld = PlayerMeta.GetRagdollEntity
end
function PlayerMeta:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		return ent
	end
	return self:GetRagdollEntityOld()
end

if !PlayerMeta.GetRagdollOwnerOld then
	PlayerMeta.GetRagdollOwnerOld = PlayerMeta.GetRagdollOwner
end
function EntityMeta:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then
		return ent
	end
	return self:GetRagdollOwnerOld()
end

function GM:RagdollSetDeathDetails(victim, inflictor, attacker) 
	local rag = victim:GetRagdollEntity()
	if rag then
		if IsValid(inflictor) && inflictor:IsWeapon() then
			if inflictor.PrintName then
				rag.Corpse.inflictor = inflictor.PrintName
			else
				rag.Corpse.inflictor = inflictor:GetClass()
			end
		end
	end
end