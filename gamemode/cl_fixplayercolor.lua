-- Proxy Example:
--
--	Proxies
--	{
--		PlayerColor
--		{
--			resultVar	$color2
--		}
--	}

matproxy.Add(
{
	name	=	"PlayerColor",

	init	=	function( self, mat, values )

		// Store the name of the variable we want to set
		self.ResultTo = values.resultvar

	end,

	bind	=	function( self, mat, ent )

		if ( !IsValid( ent ) ) then return end

		// retarded garry shit
		-- if ( ent:IsRagdoll() ) then
		-- 	ent = ent:GetRagdollOwner()
		-- 	if ( !IsValid( ent ) ) then return end
		-- end

		if ( ent.GetPlayerColor ) then
			local col = ent:GetPlayerColor()
			if ( isvector( col ) ) then
				mat:SetVector( self.ResultTo, col )
			end
		else
			mat:SetVector( self.ResultTo, Vector( 62.0/255.0, 88.0/255.0, 106.0/255.0 ) )
		end

	end
})