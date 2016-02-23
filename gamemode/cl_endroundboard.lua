
local menu
function GM:DisplayEndRoundBoard(data)
	if IsValid(menu) then
		menu:Remove()
	end

	menu = vgui.Create("DFrame")
	menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	menu:Center()
	menu:SetTitle("")
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)

	function menu:Paint()
		surface.SetDrawColor(Color(40,40,40,255))
		surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
	end

	local winnerPnl = vgui.Create("DPanel", menu)
	winnerPnl:DockPadding(24,24,24,24)
	winnerPnl:Dock(TOP)
	function winnerPnl:PerformLayout()
		self:SizeToChildren(false, true)
	end
	function winnerPnl:Paint(w, h) 
		surface.SetDrawColor(Color(50,50,50,255))
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	local winner = vgui.Create("DLabel", winnerPnl)
	winner:Dock(TOP)
	winner:SetFont("MersRadialBig")
	winner:SetAutoStretchVertical(true)

	if data.reason == 3 then
		winner:SetText(translate.endroundMurdererQuit)
		winner:SetTextColor(Color(255, 255, 255))
	elseif data.reason == 2 then
		winner:SetText(translate.endroundBystandersWin)
		winner:SetTextColor(Color(20, 120, 255))
	elseif data.reason == 1 then
		winner:SetText(translate.endroundMurdererWins)
		winner:SetTextColor(Color(190, 20, 20))
	end

	local murdererPnl = vgui.Create("DPanel", winnerPnl)
	murdererPnl:Dock(TOP)
	murdererPnl:SetTall(draw.GetFontHeight("MersRadialSmall"))
	function murdererPnl:Paint()
	end

	if data.murdererName then
		local col = data.murdererColor
		local msgs = Translator:AdvVarTranslate(translate.endroundMurdererWas, {
			murderer = {text = data.murdererName, color = Color(col.x * 255, col.y * 255, col.z * 255)}
		})

		for k, msg in pairs(msgs) do
			local was = vgui.Create("DLabel", murdererPnl)
			was:Dock(LEFT)
			was:SetText(msg.text)
			was:SetFont("MersRadialSmall")
			was:SetTextColor(msg.color or color_white)
			was:SetAutoStretchVertical(true)
			was:SizeToContentsX()
		end
	end

	local lootPnl = vgui.Create("DPanel", menu)
	lootPnl:Dock(FILL)
	lootPnl:DockPadding(24,24,24,24)
	function lootPnl:Paint(w, h) 
		surface.SetDrawColor(Color(50,50,50,255))
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	local desc = vgui.Create("DLabel", lootPnl)
	desc:Dock(TOP)
	desc:SetFont("MersRadial")
	desc:SetAutoStretchVertical(true)
	desc:SetText(translate.endroundLootCollected)
	desc:SetTextColor(color_white)
	
	local lootList = vgui.Create("DPanelList", lootPnl)
	lootList:Dock(FILL)

	table.sort(data.collectedLoot, function (a, b)
		return a.count > b.count
	end)

	for k, v in pairs(data.collectedLoot) do
		if !v.playerName then continue end
		local pnl = vgui.Create("DPanel")
		pnl:SetTall(draw.GetFontHeight("MersRadialSmall"))
		function pnl:Paint(w, h)
		end
		function pnl:PerformLayout()
			if self.NamePnl then
				self.NamePnl:SetWidth(self:GetWide() * 0.5)
			end
			if self.BNamePnl then
				self.BNamePnl:SetWidth(self:GetWide() * 0.3)
			end
			self:SizeToChildren(false, true)
		end

		local name = vgui.Create("DButton", pnl)
		pnl.NamePnl = name
		name:Dock(LEFT)
		name:SetAutoStretchVertical(true)
		name:SetText(v.playerName)
		name:SetFont("MersRadialSmall")
		local col = v.playerColor
		name:SetTextColor(Color(col.x * 255, col.y * 255, col.z * 255))
		name:SetContentAlignment(4)
		function name:Paint() end
		function name:DoClick()
			if IsValid(v.player) then
				GAMEMODE:DoScoreboardActionPopup(v.player)
			end
		end

		local bname = vgui.Create("DButton", pnl)
		pnl.BNamePnl = bname
		bname:Dock(LEFT)
		bname:SetAutoStretchVertical(true)
		bname:SetText(v.playerBystanderName)
		bname:SetFont("MersRadialSmall")
		local col = v.playerColor
		bname:SetTextColor(Color(col.x * 255, col.y * 255, col.z * 255))
		bname:SetContentAlignment(4)
		function bname:Paint() end
		bname.DoClick = name.DoClick


		local count = vgui.Create("DLabel", pnl)
		pnl.CountPnl = count
		count:Dock(FILL)
		count:SetAutoStretchVertical(true)
		count:SetText(tostring(v.count))
		count:SetFont("MersRadialSmall")
		local col = v.playerColor
		count:SetTextColor(Color(col.x * 255, col.y * 255, col.z * 255))
		count.DoClick = count.DoClick

		lootList:AddItem(pnl)
	end

end

net.Receive("reopen_round_board", function ()
	if IsValid(menu) then
		menu:SetVisible(true)
	end
end)