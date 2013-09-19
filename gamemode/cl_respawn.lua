
function GM:RenderDeathOverlay()
	local client = LocalPlayer()
	local sw, sh = ScrW(), ScrH()

	if GAMEMODE.SpectateTime > CurTime() then

		// render black screen
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-1,-1,sw + 2,sh + 2)

		render.SetColorModulation(1, 1, 1)

		// render body
		cam.Start3D( EyePos(), EyeAngles() )
		cam.IgnoreZ(true)
		local ent = client:GetRagdollEntity()
		if IsValid(ent) then
			ent:DrawModel()
		end
		cam.IgnoreZ(false)
		cam.End3D()
	end
end

GM.DeathEndTime = 0
GM.SpectateTime = 0
usermessage.Hook("rp_death",function (um)
	GAMEMODE.DeathEndTime = CurTime() + um:ReadLong()
	GAMEMODE.SpectateTime = CurTime() + um:ReadLong()
end)

function GM:RenderRespawnText()
	local client = LocalPlayer()
	local sw,sh = ScrW(),ScrH()
	
	local t = math.max(math.ceil(GAMEMODE.SpectateTime - CurTime()), 0)
	
	if t <= 0 then
	else
		draw.DrawText(tostring(t), "MersDeathBig",sw / 2,sh  * 0.25,color_white,1)
	end
end