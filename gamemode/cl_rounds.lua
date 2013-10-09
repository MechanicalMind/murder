
GM.RoundStage = 0
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
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
			surface.PlaySound("ambient/creatures/town_child_scream1.wav")
		end)
	end
end)