local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

PLAYER.GetRagdollEntityOld = PLAYER.GetRagdollEntityOld or PLAYER.GetRagdollEntity

function PLAYER:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")

	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollEntityOld()
end

ENTITY.GetRagdollOwnerOld = ENTITY.GetRagdollOwnerOld or ENTITY.GetRagdollOwner

function ENTITY:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")

	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollOwnerOld()
end