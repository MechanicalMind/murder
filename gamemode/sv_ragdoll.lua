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

local function clearupRagdolls(ragdolls, max)
	local count = 1
	for k, rag in pairs(ragdolls) do
		if IsValid(rag) then
			count = count + 1
		else
			rag[k] = nil
		end
	end

	if max >= 0 && count > max then
		while true do
			if count > max then
				if IsValid(ragdolls[1]) then
					ragdolls[1]:Remove()
				end
				table.remove(ragdolls, 1)
				count = count - 1
			else
				break
			end
		end
	end
end

function PlayerMeta:CreateRagdoll(attacker, dmginfo)
	local ent = self:GetNWEntity("DeathRagdoll")

	// remove old player ragdolls
	if !self.DeathRagdolls then self.DeathRagdolls = {} end
	local max = hook.Run("MaxDeathRagdollsPerPlayer", self)
	clearupRagdolls(self.DeathRagdolls, max or 1)

	// remove old server ragdolls
	if !GAMEMODE.DeathRagdolls then GAMEMODE.DeathRagdolls = {} end
	local max = hook.Run("MaxDeathRagdolls")
	clearupRagdolls(GAMEMODE.DeathRagdolls, max or 1)

	local data = duplicator.CopyEntTable(self)
	if !util.IsValidRagdoll(data.Model) then
		return
	end

	local ent = ents.Create( "prop_ragdoll" )
	data.ModelScale = 1 // doesn't work on ragdolls
	duplicator.DoGeneric(ent, data)
	
	self:SetNWEntity("DeathRagdoll", ent )
	ent:SetNWEntity("RagdollOwner", self)
	table.insert(self.DeathRagdolls,ent)
	table.insert(GAMEMODE.DeathRagdolls,ent)
	
	if ent.SetPlayerColor then
		ent:SetPlayerColor(self:GetPlayerColor())
	end
	ent.PlayerRagdoll = true
	hook.Run("PreDeathRagdollSpawn", self, ent)
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	hook.Run("OnDeathRagdollCreated", self, ent)
	ent:Fire("kill", "", 60 * 8)

	local vel = self:GetVelocity()
	for bone = 0, ent:GetPhysicsObjectCount() - 1 do
		local phys = ent:GetPhysicsObjectNum( bone )
		if IsValid(phys) then
			local pos, ang = self:GetBonePosition( ent:TranslatePhysBoneToBone( bone ) )
			phys:SetPos(pos)
			phys:SetAngles(ang)
			phys:AddVelocity(vel)
		end
	end
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