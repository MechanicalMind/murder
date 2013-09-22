local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

PlayerMeta.GetRagdollEntityOld = PlayerMeta.GetRagdollEntity
function PlayerMeta:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		return ent
	end
	return self:GetRagdollEntityOld()
end

PlayerMeta.GetRagdollOwnerOld = PlayerMeta.GetRagdollOwner
function EntityMeta:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then
		return ent
	end
	return self:GetRagdollOwnerOld()
end