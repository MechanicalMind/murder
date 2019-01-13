
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

local baseSize = ScrH() / 23
surface.CreateFont( "MersRadial" , {
	font = "coolvetica",
	size = math.ceil(baseSize),
	weight = 500,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersRadialBig" , {
	font = "coolvetica",
	size = math.ceil(baseSize * 1.41),
	weight = 500,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersRadialSmall" , {
	font = "coolvetica",
	size = math.ceil(baseSize * .56),
	weight = 100,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersDeathBig" , {
	font = "coolvetica",
	size = math.ceil(baseSize * .188),
	weight = 500,
	antialias = true,
	italic = false
})

local function drawTextShadow(t,f,x,y,c,px,py)
	color_black.a = c.a
	draw.SimpleText(t,f,x + 1,y + 1,color_black,px,py)
	draw.SimpleText(t,f,x,y,c,px,py)
	color_black.a = 255
end


local healthCol = Color(120,255,20)
function GM:HUDPaint()
	local round = self:GetRound()
	local client = LocalPlayer()

	if round == 0 then
		drawTextShadow(translate.minimumPlayers, "MersRadial", ScrW() / 2, ScrH() - 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	elseif round == 5 then
		if self.StartNewRoundTime then
			local seconds = math.ceil(self.StartNewRoundTime - CurTime())
			if seconds <= 0 then 
				seconds = 0
			end
			drawTextShadow(Translator:QuickVar(translate.roundStartsInTime, "seconds", tostring(seconds)), "MersRadial", ScrW() / 2, ScrH() - 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		else

			drawTextShadow(translate.waitingToStart, "MersRadial", ScrW() / 2, ScrH() - 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end

	if client:Team() == 2 then
		if !client:Alive() then
			self:RenderRespawnText()
		else

			if round == 1 then
				if self.RoundStart && self.RoundStart + 10 > CurTime() then
					self:DrawStartRoundInformation()
				else
					self:DrawGameHUD(LocalPlayer())
				end
			elseif round == 2 then
				// display who won
				self:DrawGameHUD(LocalPlayer())
			else // round = 0

			end

			-- local tr = LocalPlayer():GetEyeTrace()

			-- local lc = render.GetLightColor(LocalPlayer():GetPos() + Vector(0,0,30))
			-- local lt = (lc.r + lc.g + lc.b) / 3
			-- draw.DrawText("Light:" .. tostring(lc), "MersRadial", ScrW() - 20, 80, color_white, 2)
			-- draw.DrawText("Average:" .. tostring(math.Round(lt * 100) / 100), "MersRadial", ScrW() - 20, 120, color_white, 2)
		end
	else
		self:RenderSpectate()
	end

	if self.Debug:GetBool() then
		local h = draw.GetFontHeight("MersRadial")
		local y = 0

		draw.DrawText("Footsteps: " .. table.Count(FootStepsG), "MersRadial", ScrW() - 20, 20 + y, color_white, 2)
		y = y + h
	end

	self:DrawRadialMenu()
	self:DrawSpawnsVisualise()
end

function GM:DrawStartRoundInformation()
	local client = LocalPlayer()
	local t1 = translate.startHelpBystanderTitle
	local t2 = nil
	local c = Color(20,120,255)
	local desc = translate.table.startHelpBystander

	if self:GetAmMurderer() then
		t1 = translate.startHelpMurdererTitle
		desc = translate.table.startHelpMurderer
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
		t1 = translate.startHelpGunTitle
		t2 = translate.startHelpGunSubtitle
		desc = translate.table.startHelpGun
	end

	drawTextShadow(t1, "MersRadial", ScrW() / 2, ScrH()  * 0.25, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	if t2 then
		local h = draw.GetFontHeight("MersRadial")
		drawTextShadow(t2, "MersRadialSmall", ScrW() / 2, ScrH() * 0.25 + h * 0.7, Color(120, 70, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if desc then
		local fontHeight = draw.GetFontHeight("MersRadialSmall")
		for k,v in pairs(desc) do
			drawTextShadow(v, "MersRadialSmall", ScrW() / 2, ScrH() * 0.75 + (k - 1) * fontHeight, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

local tex = surface.GetTextureID("SGM/playercircle")
local gradR = surface.GetTextureID("gui/gradient")

local function colorDif(col1, col2)
	local x = col1.x - col2.x
	local y = col1.y - col2.y
	local z = col1.z - col2.z
	x = x > 0 and x or -x
	y = y > 0 and y or -y
	z = z > 0 and z or -z
	return x + y + z
end

function GM:DrawGameHUD(ply)
	if !IsValid(ply) then return end
	local health = ply:Health()
	if !IsValid(ply) then return end

	local shouldDraw = hook.Run("HUDShouldDraw", "MurderMurdererFog")
	if shouldDraw != false then
		if LocalPlayer() == ply && ply:GetNWBool("MurdererFog") && self:GetAmMurderer() then
			surface.SetDrawColor(10,10,10,50)
			surface.DrawRect(-1, -1, ScrW() + 2, ScrH() + 2)
		
			drawTextShadow(translate.murdererFog, "MersRadial", ScrW() * 0.5, ScrH() - 80, Color(90,20,20), 1, TEXT_ALIGN_CENTER)
			drawTextShadow(translate.murdererFogSub, "MersRadialSmall", ScrW() * 0.5, ScrH() - 50, Color(130,130,130), 1, TEXT_ALIGN_CENTER)
		end
	end

	-- surface.SetFont("MersRadial")
	-- local w,h = surface.GetTextSize("Health")

	-- drawTextShadow("Health", "MersRadial", 20, ScrH() - 10, healthCol, 0, TEXT_ALIGN_BOTTOM)
	-- drawTextShadow(health, "MersRadialBig", 20 + w + 10, ScrH() - 10 + 3, healthCol, 0, TEXT_ALIGN_BOTTOM)

	local tr = ply:GetEyeTraceNoCursor()
	
	local shouldDraw = hook.Run("HUDShouldDraw", "MurderTraitorButton")
	if shouldDraw != false then
		if self:GetAmMurderer() then
			// find closest button to cursor with usable range
			local dis, dot, but
			for k, lbut in pairs(ents.FindByClass("ttt_traitor_button")) do
				local vec = lbut:GetPos() - ply:GetShootPos()
				local ldis, ldot = vec:Length(), vec:GetNormal():Dot(ply:GetAimVector())
				if (ldis < lbut:GetUsableRange() && ldot > 0.95) && (!but || ldot > dot) then
					dis = ldis
					dot = ldot
					but = lbut
				end
			end
			
			// draw the friggen button with excessive text
			if but then
				local sp = but:GetPos():ToScreen()
				if sp.visible then
					local sz = 16
					local col = Color(190, 20, 20)
					if but:GetNextUseTime() > CurTime() then
						col = Color(150, 150, 150)
					end
					local ft, fh = draw.GetFontHeight("MersText1"), draw.GetFontHeight("MersHead1")
					drawTextShadow(but:GetDescription(), "MersHead1", sp.x, sp.y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

					local text
					if but:GetNextUseTime() > CurTime() then
						text = Translator:VarTranslate(translate.ttt_tbut_waittime, {timesec = math.ceil(but:GetNextUseTime() - CurTime()) .. "s"})
					elseif but:GetDelay() < 0 then
						text = translate.ttt_tbut_single
					elseif but:GetDelay() == 0 then
						text = translate.ttt_tbut_reuse
					else
						text = Translator:VarTranslate(translate.ttt_tbut_retime, {num = but:GetDelay()})
					end
					drawTextShadow(text, "MersText1", sp.x, sp.y + fh, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					
					local key = input.LookupBinding("use")
					if key && but:GetNextUseTime() <= CurTime() then
						text = Translator:VarTranslate(translate.ttt_tbut_help, {key = key:upper()})
						drawTextShadow(text, "MersText1", sp.x, sp.y + ft + fh, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end
			end
		end
	end

	local shouldDraw = hook.Run("HUDShouldDraw", "MurderPlayerNames")
	if shouldDraw != false then
		// draw names
		if IsValid(tr.Entity) && (tr.Entity:IsPlayer() || tr.Entity:GetClass() == "prop_ragdoll") && tr.HitPos:Distance(tr.StartPos) < 500 then
			self.LastLooked = tr.Entity
			self.LookedFade = CurTime()
		end
		if IsValid(self.LastLooked) && self.LookedFade + 2 > CurTime() then
			local name = self.LastLooked:GetBystanderName() or "error"
			local col = self.LastLooked:GetPlayerColor() or Vector()
			col = Color(col.x * 255, col.y * 255, col.z * 255)
			col.a = (1 - (CurTime() - self.LookedFade) / 2) * 255
			drawTextShadow(name, "MersRadial", ScrW() / 2, ScrH() / 2 + 80, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local shouldDraw = hook.Run("HUDShouldDraw", "MurderDisguise")
	if shouldDraw != false then
		if self:GetAmMurderer() && self.LootCollected && self.LootCollected >= 1 then
			if IsValid(tr.Entity) && tr.Entity:GetClass() == "prop_ragdoll" && tr.HitPos:Distance(tr.StartPos) < 80 then
				if tr.Entity:GetBystanderName() != ply:GetBystanderName() || colorDif(tr.Entity:GetPlayerColor(), ply:GetPlayerColor()) > 0.1 then 
					local h = draw.GetFontHeight("MersRadial")
					drawTextShadow(translate.pressEToDisguiseFor1Loot, "MersRadialSmall", ScrW() / 2, ScrH() / 2 + 80 + h * 0.7, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		end
	end
	
	local shouldDraw = hook.Run("HUDShouldDraw", "MurderHealthBall")
	if shouldDraw != false then
		// setup size
		local size = ScrW() * 0.08

		// draw black circle
		surface.SetTexture(tex)
		surface.SetDrawColor(color_black)
		surface.DrawTexturedRect( size * 0.1, ScrH() - size * 1.1, size, size)

		// draw health circle
		surface.SetTexture(tex)
		local col = ply:GetPlayerColor()
		col = Color(col.x * 255, col.y * 255, col.z * 255)
		surface.SetDrawColor(col)
		local hsize = math.Clamp(health, 0, 100) / 100 * size
		surface.DrawTexturedRect( size * 0.1 + (size - hsize) / 2, ScrH() - size * 1.1 + (size - hsize) / 2, hsize, hsize)

		if LocalPlayer() == ply then
			drawTextShadow(self.LootCollected or "error", "MersRadialBig", size * 0.6, ScrH() - size * 0.6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		surface.SetFont("MersRadialSmall")
		local w,h = surface.GetTextSize(ply:GetBystanderName())
		local x = math.max(size * 0.6 + w / -2, size * 0.1)
		drawTextShadow(ply:GetBystanderName(), "MersRadialSmall", x, ScrH() - size * 1.1, col, 0, TEXT_ALIGN_BOTTOM)
	end

	local shouldDraw = hook.Run("HUDShouldDraw", "MurderFlashlightCharge")
	if shouldDraw != false then
		if LocalPlayer() == ply && (ply:FlashlightIsOn() || self:GetFlashlightCharge() < 1) then
			local size = ScrW() * 0.08
			local x = size * 1.2

			local w = ScrW() * 0.08
			local h = ScrH() * 0.03

			local bord = math.Round(ScrW() * 0.08 * 0.03)
			if ply:FlashlightIsOn() then
				surface.SetDrawColor(0, 0, 0, 240)
			else
				surface.SetDrawColor(5, 5, 5, 180)
			end
			surface.DrawRect(x, ScrH() - h - size * 0.2, w, h)

			local charge = self:GetFlashlightCharge()

			if ply:FlashlightIsOn() then
				surface.SetDrawColor(50, 180, 220, 240)
			else
				surface.SetDrawColor(50, 180, 220, 180)
			end
			surface.DrawRect(x + bord, ScrH() - h - size * 0.2 + bord, (w - bord * 2) * charge, h - bord * 2)

			surface.SetTexture(gradR)
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawTexturedRect(x + bord, ScrH() - h - size * 0.2 + bord, (w - bord * 2) * charge, h - bord * 2)
		end
	end
	
	local shouldDraw = hook.Run("HUDShouldDraw", "MurderPlayerType")
	if shouldDraw != false then
		local name = translate.bystander
		local color = Color(20,120,255)

		if LocalPlayer() == ply && self:GetAmMurderer() then
			name = translate.murderer
			color = Color(190, 20, 20)
		end

		drawTextShadow(name, "MersRadial", ScrW() - 20, ScrH() - 10, color, 2, TEXT_ALIGN_BOTTOM)
	end
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

function GM:PostDrawHUD()
	if self:GetRound() == 1 then
		local dest = 0
		if self.TKerPenalty then
			-- dest = (math.sin(CurTime()) + 1) * 30 / 2 + 230
			dest = 254
		end
		self.ScreenDarkness = math.Clamp(math.Approach(self.ScreenDarkness or 0, dest, FrameTime() * 120), 0, 255)

		if self.ScreenDarkness > 0 then
			local sw, sh = ScrW(), ScrH()
			surface.SetDrawColor(0,0,0, self.ScreenDarkness)
			surface.DrawRect(-1, -1, sw + 2, sh + 2)
		end
	else
		self.ScreenDarkness = 0
	end
end

function GM:HUDShouldDraw( name )
	// hide health and armor
	if name == "CHudHealth" || name == "CHudBattery" then
		return false
	end

	// allow weapon hiding
	local ply = LocalPlayer()
	if IsValid(ply) then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) && wep.HUDShouldDraw then
			return wep.HUDShouldDraw(wep, name)
		end
	end

	return true
end

function GM:GUIMousePressed(code, vector)
	return self:RadialMousePressed(code,vector)
end
