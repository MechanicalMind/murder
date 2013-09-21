
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

surface.CreateFont( "MersRadialBig" , {
	font = "coolvetica",
	size = math.ceil(ScrW() / 24),
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

local function drawTextShadow(t,f,x,y,c,px,py)
	draw.SimpleText(t,f,x + 1,y + 1,color_black,px,py)
	draw.SimpleText(t,f,x,y,c,px,py)
end


local healthCol = Color(120,255,20)
function GM:HUDPaint()
	local client = LocalPlayer()
	if !client:Alive() then
		self:RenderRespawnText()
	else
		local t1 = "Bystander"
		local t2 = "Try to stay alive and find the murderer"
		local c = Color(20,120,255)

		if self:GetAmMurderer() then
			t1 = "Murderer"
			t2 = "Kill everyone, without being seen"
			c = Color(230,50,50)
		end

		drawTextShadow(t1, "MersRadial", ScrW() - 20, ScrH() - 10, c, 2, TEXT_ALIGN_TOP)

		drawTextShadow(t2, "MersRadialSmall", ScrW() - 20, 20, color_white, 2)

		local health = client:Health()

		surface.SetFont("MersRadial")
		local w,h = surface.GetTextSize("Health")

		drawTextShadow("Health", "MersRadial", 20, ScrH() - 10, healthCol, 0, TEXT_ALIGN_TOP)
		drawTextShadow(health, "MersRadialBig", 20 + w + 10, ScrH() - 10 + 3, healthCol, 0, TEXT_ALIGN_TOP)


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

function GM:HUDShouldDraw( name )
	// hide health and armor
    if name == "CHudHealth" || name == "CHudBattery" then
        return false
    end
    return true
end