
function GM:SetAmMurderer(bool)
	self.Murderer = bool
end

function GM:GetAmMurderer(bool)
	return self.Murderer
end

net.Receive( "your_are_a_murderer", function( length, client )
	local am = net.ReadUInt(8) != 0
	GAMEMODE:SetAmMurderer(am)
end)
