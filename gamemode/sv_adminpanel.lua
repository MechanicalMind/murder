GM.AdminPanelAllowed = CreateConVar("mu_allow_admin_panel", 1, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED), "Should allow admins to use mu_admin_panel" )

util.AddNetworkString("mu_adminpanel_details")

net.Receive("mu_adminpanel_details", function (length, ply)
	if !ply:IsAdmin() then return end
	if !GAMEMODE.AdminPanelAllowed:GetBool() then return end

	local tab = {}
	tab.players = {}
	tab.weightMul = GAMEMODE.MurdererWeight:GetFloat()

	local total = 0
	for k, ply in pairs(team.GetPlayers(2)) do
		total = total + (ply.MurdererChance or 1) ^ tab.weightMul
	end

	for k, ply in pairs(team.GetPlayers(2)) do
		local t = {}
		t.player = ply:EntIndex() // can't send players via JSON
		t.murderer = ply:GetMurderer()
		t.murdererChance = ((ply.MurdererChance or 1) ^ tab.weightMul) / total
		t.murdererWeight = ply.MurdererChance or 1
		tab.players[ply:EntIndex()] = t
	end

	local json = util.TableToJSON(tab)
	net.Start("mu_adminpanel_details")
	net.WriteString(json)
	net.Send(ply)
end)