local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

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