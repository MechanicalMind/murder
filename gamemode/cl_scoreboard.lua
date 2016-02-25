local menu

surface.CreateFont( "ScoreboardPlayer" , {
	font = "Default",
	size = 32,
	weight = 500,
})

surface.CreateFont( "ScoreboardJoinString" , {
	font = "Default",
	size = 12,
	weight = 600,
})

surface.CreateFont( "ScoreboardHostName" , {
	font = "Default",
	size = 40,
	weight = 400,
})

local muted = Material("icon32/muted.png")

local function addPlayerItem(self, mlist, ply, pteam)
	local but = vgui.Create("DButton")
	but.player = ply
	but.ctime = CurTime()
	but:SetTall(40)
	but:SetText("")
	function but:Paint(w, h)
		local showAdmins = GAMEMODE.RoundSettings.ShowAdminsOnScoreboard

		if IsValid(ply) && showAdmins && ply:IsAdmin() then
			surface.SetDrawColor(Color(150,50,50))
		else
			surface.SetDrawColor(team.GetColor(pteam))
		end
		
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255,255,255,10)
		surface.DrawRect(0, 0, w, h * 0.45 )

		surface.SetDrawColor(color_black)
		surface.DrawOutlinedRect(0, 0, w, h)

		if IsValid(ply) && ply:IsPlayer() then
			local s = 0

			if ply:IsMuted() then
				surface.SetMaterial(muted)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(s + 4, h / 2 - 16, 32, 32)
				s = s + 32
			end

			draw.DrawText(ply:Ping(), "ScoreboardPlayer", w - 9, 4, color_black, 2)
			draw.DrawText(ply:Ping(), "ScoreboardPlayer", w - 10, 3, color_white, 2)
			
			if ply:Alive() then
			draw.DrawText(ply:Nick().." ("..ply:GetBystanderName()..")", "ScoreboardPlayer", s + 11, 3, color_black, 0)
			draw.DrawText(ply:Nick().." ("..ply:GetBystanderName()..")", "ScoreboardPlayer", s + 10, 2, color_white, 0)
			else
			draw.DrawText(ply:Nick(), "ScoreboardPlayer", s + 11, 3, color_black, 0)
			draw.DrawText(ply:Nick(), "ScoreboardPlayer", s + 10, 2, color_white, 0)
			end
			
			ply:GetPlayerColor()

		end
	end
	function but:DoClick()
		GAMEMODE:DoScoreboardActionPopup(ply)
	end

	mlist:AddItem(but)
end

function GM:DoScoreboardActionPopup(ply)
	local actions = DermaMenu()

	if ply != LocalPlayer() then
		local t = translate.scoreboardActionMute
		if ply:IsMuted() then
			t = translate.scoreboardActionUnmute
		end
		local mute = actions:AddOption( t )
		mute:SetIcon("icon16/sound_mute.png")
		function mute:DoClick()
			if IsValid(ply) then
				ply:SetMuted(!ply:IsMuted())
			end
		end
		
	end
	
	local profile = actions:AddOption( translate.showProfile )
	profile:SetIcon( "icon16/group.png" )
	function profile:DoClick()
		ply:ShowProfile()
	end
	
	local profile = actions:AddOption( translate.copySteamID )
	profile:SetIcon( "icon16/user.png" )
	function profile:DoClick()
	    chat.AddText(Color( 90, 90, 90 ), "[", Color( 0, 100, 200 ), "Scoreboard", Color( 90, 90, 90 ), "] ", Color( 255, 255, 255 ),"SteamID copied!")
		SetClipboardText(ply:SteamID())
	end
	
	if IsValid(LocalPlayer()) && LocalPlayer():IsAdmin() then
		actions:AddSpacer()

		if ply:Team() == 2 then
			local spectate = actions:AddOption( Translator:QuickVar(translate.adminMoveToSpectate, "spectate", team.GetName(1)) )
			spectate:SetIcon( "icon16/status_busy.png" )
			function spectate:DoClick()
				RunConsoleCommand("mu_movetospectate", ply:EntIndex())
			end

			local force = actions:AddOption( translate.adminMurdererForce )
			force:SetIcon( "icon16/delete.png" )
			function force:DoClick()
				RunConsoleCommand("mu_forcenextmurderer", ply:EntIndex())
			end
			
		end
		
	end
	actions:Open()
end

local function doPlayerItems(self, mlist, pteam)

	for k, ply in pairs(team.GetPlayers(pteam)) do
		local found = false

		for t,v in pairs(mlist:GetCanvas():GetChildren()) do
			if v.player == ply then
				found = true
				v.ctime = CurTime()
			end
		end

		if !found then
			addPlayerItem(self, mlist, ply, pteam)
		end
	end
	local del = false

	for t,v in pairs(mlist:GetCanvas():GetChildren()) do
		if v.ctime != CurTime() then
			v:Remove()
			del = true
		end
	end
	// make sure the rest of the elements are moved up
	if del then
		timer.Simple(0, function() mlist:GetCanvas():InvalidateLayout() end)
	end
end

local function makeTeamList(parent, pteam)
	local mlist
	local chaos
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8,8,8,8)
	function pnl:Paint(w, h) 
		surface.SetDrawColor(Color(50,50,50,255))
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	function pnl:Think()
		if !self.RefreshWait || self.RefreshWait < CurTime() then
			self.RefreshWait = CurTime() + 0.1
			doPlayerItems(self, mlist, pteam)

			// update chaos/control
			if pteam == 2 then
				-- chaos:SetText("Control: " .. GAMEMODE:GetControl())
			else
				-- chaos:SetText("Chaos: " .. GAMEMODE:GetChaos())
			end
		end
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0,0,0,4)
	-- headp:DockPadding(4,0,4,0)
	headp:Dock(TOP)
	function headp:Paint() end

	local but = vgui.Create("DButton", headp)
	but:Dock(RIGHT)
	but:SetText(translate.scoreboardJoinTeam)
	but:SetTextColor(color_white)
	but:SetFont("ScoreboardJoinString")
	function but:DoClick()
		RunConsoleCommand("mu_jointeam", pteam)
	end
	function but:Paint(w, h)
		surface.SetDrawColor(team.GetColor(pteam))
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255,255,255,10)
		surface.DrawRect(0, 0, w, h * 0.45 )

		surface.SetDrawColor(color_black)
		surface.DrawOutlinedRect(0, 0, w, h)

		if self:IsDown() then
			surface.SetDrawColor(50,50,50,120)
			surface.DrawRect(1, 1, w - 2, h - 2)
		elseif self:IsHovered() then
			surface.SetDrawColor(255,255,255,30)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
	end

	local head = vgui.Create("DLabel", headp)
	head:SetText(team.GetName(pteam))
	head:SetFont("Trebuchet24")
	head:SetTextColor(team.GetColor(pteam))
	head:Dock(FILL)


	mlist = vgui.Create("DScrollPanel", pnl)
	mlist:Dock(FILL)

	// child positioning
	local canvas = mlist:GetCanvas()
	function canvas:OnChildAdded( child )
		child:Dock( TOP )
		child:DockMargin( 0,0,0,4 )
	end

	return pnl
end


function GM:ScoreboardShow()
	if IsValid(menu) then
		menu:SetVisible(true)
	else
		menu = vgui.Create("DFrame")
		menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
		menu:Center()
		menu:MakePopup()
		menu:SetKeyboardInputEnabled(false)
		menu:SetDeleteOnClose(false)
		menu:SetDraggable(false)
		menu:ShowCloseButton(false)
		menu:SetTitle("")
		menu:DockPadding(4,4,4,4)
		function menu:PerformLayout()
			menu.Cops:SetWidth(self:GetWide() * 0.5)
		end

		function menu:Paint()
			surface.SetDrawColor(Color(0,50,100,200))
			surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
		end

		menu.Credits = vgui.Create("DPanel", menu)
		menu.Credits:Dock(TOP)
		menu.Credits:DockPadding(8,-1,8,0)
		function menu.Credits:Paint() end

		local name = Label(GetHostName(), menu.Credits)
		name:Dock(LEFT)
		name:SetFont("ScoreboardHostName")
		name:SetTextColor(Color(0,0,0))
		function name:PerformLayout()
			surface.SetFont(self:GetFont())
			local w,h = surface.GetTextSize(self:GetText())
			self:SetSize(w,h)
		end

		local lab = Label("", menu.Credits)
		lab:Dock(RIGHT)
		lab:SetFont("MersText1")
		lab.PerformLayout = name.PerformLayout
		lab:SetTextColor(Color(0,0,0))

		function menu.Credits:PerformLayout()
			surface.SetFont(name:GetFont())
			local w,h = surface.GetTextSize(name:GetText())
			self:SetTall(h)
		end

		menu.Cops = makeTeamList(menu, 2)
		menu.Cops:Dock(LEFT)
		menu.Robbers = makeTeamList(menu, 1)
		menu.Robbers:Dock(FILL)
	end
end
function GM:ScoreboardHide()
	if IsValid(menu) then
		menu:Close()
	end
end

function GM:HUDDrawScoreBoard()
end