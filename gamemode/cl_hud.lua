
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
		local speed = math.floor(LocalPlayer():GetVelocity():Length2D())

		draw.DrawText("Speed:" .. speed, "MersRadial", ScrW() - 200, 20, color_white, 0)

		local tr = LocalPlayer():GetEyeTrace()

		local lc = render.GetLightColor(LocalPlayer():GetPos() + Vector(0,0,30))
		local lt = (lc.r + lc.g + lc.b) / 3
		draw.DrawText("Light:" .. tostring(lc), "MersRadial", ScrW() - 20, 80, color_white, 2)
		draw.DrawText("Average:" .. tostring(math.Round(lt * 100) / 100), "MersRadial", ScrW() - 20, 120, color_white, 2)
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