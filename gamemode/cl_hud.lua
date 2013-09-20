
surface.CreateFont( "MersText1" , {
	font = "Tahoma",
	size = 16,
	weight = 1000,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersHead1" , {
	font = "coolvetica",
	size = 24,
	weight = 500,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersRadial" , {
	font = "coolvetica",
	size = math.ceil(ScrW() / 34),
	weight = 500,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersRadialSmall" , {
	font = "coolvetica",
	size = math.ceil(ScrW() / 60),
	weight = 100,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersDeathBig" , {
	font = "coolvetica",
	size = math.ceil(ScrW() / 18),
	weight = 500,
	antialias = true,
	italic = false
})



function GM:HUDPaint()
	local client = LocalPlayer()
	if !client:Alive() then
		self:RenderRespawnText()
	else
		local t1 = "You are innocent"
		local t2 = "Try to stay alive and find the murderer"
		local c = Color(255,255,255)

		if self:GetAmMurderer() then
			t1 = "You are the murderer"
			t2 = "Kill everyone, stealthly"
			c = Color(255,90,90)
		end

		draw.DrawText(t1, "MersRadial", ScrW() - 20, 20, c, 2)
		draw.DrawText(t2, "MersRadialSmall", ScrW() - 20, 60, c, 2)


		-- local tr = LocalPlayer():GetEyeTrace()

		-- local lc = render.GetLightColor(LocalPlayer():GetPos() + Vector(0,0,30))
		-- local lt = (lc.r + lc.g + lc.b) / 3
		-- draw.DrawText("Light:" .. tostring(lc), "MersRadial", ScrW() - 20, 80, color_white, 2)
		-- draw.DrawText("Average:" .. tostring(math.Round(lt * 100) / 100), "MersRadial", ScrW() - 20, 120, color_white, 2)

	end
end

function GM:GUIMousePressed(code, vector)
end

function GM:RenderScreenspaceEffects()
	local client = LocalPlayer()
	if !client:Alive() then
		self:RenderDeathOverlay()
	end
end