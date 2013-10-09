
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
	local round = self:GetRound()
	local client = LocalPlayer()

	if round == 0 then
		drawTextShadow("Not enough players to start round", "MersRadial", ScrW() / 2, ScrH() - 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	if !client:Alive() then
		self:RenderRespawnText()
	else

		if round == 1 then
			if self:GetRound() == 1 && self.RoundStart && self.RoundStart + 10 > CurTime() then
				self:DrawStartRoundInformation()
			else
				self:DrawGameHUD()
			end
		elseif round == 2 then
			// display who won
			self:DrawGameHUD()
		else // round = 0

		end

		-- local tr = LocalPlayer():GetEyeTrace()

		-- local lc = render.GetLightColor(LocalPlayer():GetPos() + Vector(0,0,30))
		-- local lt = (lc.r + lc.g + lc.b) / 3
		-- draw.DrawText("Light:" .. tostring(lc), "MersRadial", ScrW() - 20, 80, color_white, 2)
		-- draw.DrawText("Average:" .. tostring(math.Round(lt * 100) / 100), "MersRadial", ScrW() - 20, 120, color_white, 2)
	end
end

function GM:DrawStartRoundInformation()
	local client = LocalPlayer()
	local t1 = "You are a bystander"
	local t2 = nil
	local c = Color(20,120,255)
	local desc = {
		"There is a murderer on the loose",
		"Don't get killed"
	}

	if self:GetAmMurderer() then
		t1 = "You are the murderer"
		desc = {
			"Kill everyone",
			"Don't get caught"
		}
		c = Color(190, 20, 20)
	end

	local hasMagnum = false
	for k, wep in pairs(client:GetWeapons()) do
		if wep:GetClass() == "weapon_mu_magnum" then
			hasMagnum = true
			break
		end
	end
	if hasMagnum then
		t1 = "You are a bystander"
		t2 = "with a secret weapon"
		desc = {
			"There is a murderer on the loose",
			"Find and kill him"
		}
	end

	drawTextShadow(t1, "MersRadial", ScrW() / 2, ScrH()  * 0.25, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	if t2 then
		local h = draw.GetFontHeight("MersRadial")
		drawTextShadow(t2, "MersRadialSmall", ScrW() / 2, ScrH() * 0.25 + h * 0.7, Color(190, 20, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local fontHeight = draw.GetFontHeight("MersRadialSmall")
	for k,v in pairs(desc) do
		drawTextShadow(v, "MersRadialSmall", ScrW() / 2, ScrH() * 0.75 + (k - 1) * fontHeight, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function GM:DrawGameHUD()
	local client = LocalPlayer()
	local health = client:Health()

	surface.SetFont("MersRadial")
	local w,h = surface.GetTextSize("Health")

	drawTextShadow("Health", "MersRadial", 20, ScrH() - 10, healthCol, 0, TEXT_ALIGN_TOP)
	drawTextShadow(health, "MersRadialBig", 20 + w + 10, ScrH() - 10 + 3, healthCol, 0, TEXT_ALIGN_TOP)

	local name = "Bystander"
	local color = Color(20,120,255)

	if self:GetAmMurderer() then
		name = "Murderer"
		color = Color(190, 20, 20)
	end

	drawTextShadow(name, "MersRadial", ScrW() - 20, ScrH() - 10, color, 2, TEXT_ALIGN_TOP)
end

function GM:GUIMousePressed(code, vector)
end

function GM:RenderScreenspaceEffects()
	local client = LocalPlayer()
	if !client:Alive() then
		self:RenderDeathOverlay()
	end

	if self:GetRound() == 1 && self.RoundStart && self.RoundStart + 10 > CurTime() then
		local sw, sh = ScrW(), ScrH()
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-1,-1,sw + 2,sh + 2)
	end
end

function GM:HUDShouldDraw( name )
	// hide health and armor
	if name == "CHudHealth" || name == "CHudBattery" then
		return false
	end
	if self:GetRound() == 1 && self.RoundStart && self.RoundStart + 10 > CurTime() then
		if name == "CHudChat" then
			return false
		end
	end
	return true
end