include("shared.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")
include("cl_footsteps.lua")
include("cl_respawn.lua")
include("cl_murderer.lua")
include("cl_player.lua")
include("cl_fixplayercolor.lua")
include("cl_ragdoll.lua")
include("cl_chattext.lua")
include("cl_voicepanels.lua")


function GM:Initialize() 
	self:FootStepsInit()
end


function GM:Think()

end


function GM:EntityRemoved(ent)

end

function GM:PostDrawViewModel( vm, ply, weapon )

	if ( weapon.UseHands || !weapon:IsScripted() ) then

		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then hands:DrawModel() end

	end

end

function GM:RenderScene( origin, angles, fov )
	-- self:FootStepsRenderScene(origin, angles, fov)
end

function GM:PostDrawTranslucentRenderables()
	self:DrawFootprints()
end

function GM:PreDrawHalos()

	local entL = ents.FindByClass( "weapon_mu_magnum" )
	for k,v in pairs(entL) do
		if IsValid(v.Owner) then
			entL[k] = nil
		end
	end
	halo.Add(entL, Color(0, 0, 255), 5, 5, 5, true, false)

	if self:GetAmMurderer() then
		local knives = ents.FindByClass( "weapon_mu_knife" )
		for k,v in pairs(knives) do
			if IsValid(v.Owner) then
				knives[k] = nil
			end
		end
		halo.Add(knives, Color(220, 0, 0), 5, 5, 5, true, false)
		halo.Add(ents.FindByClass( "mu_knife" ), Color(220, 0, 0), 5, 5, 5, true, false)
	end
end