local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootStepsFootstep(ply, pos, foot, sound, volume, filter)

end

-- The client doesn't have access to the server's getters,
-- so you have to define them here as well.
-- That's why you have these getters in both the server and the client.
function EntityMeta:GetPlayerColor()
	return self:GetNWVector("playerColor") or Vector()
end

-- Used only on client for playermodel at the corner
function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
end

function EntityMeta:GetNameColor()
	return self:GetNWVector("nameColor") or Vector()
end

function EntityMeta:GetBystanderName()
	local name = self:GetNWString("bystanderName")
	if !name || name == "" then
		return "Bystander" 
	end
	return name
end