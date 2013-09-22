local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootStepsFootstep(ply, pos, foot, sound, volume, filter)

	// quiet thieves footsteps
	if ply:Team() == 3 then
		return true
	end
end

function EntityMeta:GetPlayerColor()
	return self:GetNWVector("playerColor") or Vector()
end