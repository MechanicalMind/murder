
GM.RoundStage = 0
GM.LootCollected = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.LootCollected = GAMEMODE.LootCollected
end

function GM:GetRound()
	return self.RoundStage or 0
end

net.Receive("SetRound", function (length)
	local r = net.ReadUInt(8)
	GAMEMODE.RoundStage = r
	GAMEMODE.RoundStart = CurTime()

	if r == 1 then
		timer.Simple(0.2, function ()
			local pitch = math.random(70, 140)
			if IsValid(LocalPlayer()) then
				LocalPlayer():EmitSound("ambient/creatures/town_child_scream1.wav", 100, pitch)
			end
		end)
		GAMEMODE.LootCollected = 0
	end
end)

net.Receive("DeclareWinner" , function (length)
	local data = {}
	data.reason = net.ReadUInt(8)
	data.murderer = net.ReadEntity()
	data.murdererColor = net.ReadVector()
	data.murdererName = net.ReadString()
	if IsValid(data.murderer) then
	end

	data.collectedLoot = {}
	while true do
		local cont = net.ReadUInt(8)
		if cont == 0 then break end

		local t = {}
		t.player = net.ReadEntity()
		if IsValid(t.player) then
			t.playerName = t.player:Nick()
		end
		t.count = net.ReadUInt(32)
		t.playerColor = net.ReadVector()
		t.playerBystanderName = net.ReadString()
		table.insert(data.collectedLoot, t)
	end

	GAMEMODE:DisplayEndRoundBoard(data)

	local pitch = math.random(80, 120)
	if IsValid(LocalPlayer()) then
		LocalPlayer():EmitSound("ambient/alarms/warningbell1.wav", 100, pitch)
	end
end)

net.Receive("GrabLoot", function (length)
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)

net.Receive("SetLoot", function (length)
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)