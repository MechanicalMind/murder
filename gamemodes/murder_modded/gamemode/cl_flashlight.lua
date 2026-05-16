
function GM:GetFlashlightCharge()
	return self.FlashlightCharge or 1
end

net.Receive("flashlight_charge", function (len)
	GAMEMODE.FlashlightCharge = net.ReadFloat()
end)