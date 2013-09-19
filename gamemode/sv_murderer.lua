local PlayerMeta = FindMetaTable("Player")


function PlayerMeta:SetMurderer(bool)
	self.Murderer = bool
	net.Start( "your_are_a_murderer" )
	net.WriteUInt(bool and 1 or 0, 8)
	net.Send( self )
end

function PlayerMeta:GetMurderer(bool)
	return self.Murderer
end