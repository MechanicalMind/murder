
util.AddNetworkString("flashlight_charge")


function GM:FlashlightThink()
	if self.FlashlightBattery:GetFloat() > 0 then
		local decay = FrameTime() / self.FlashlightBattery:GetFloat()
		for k, ply in pairs(player.GetAll()) do
			if ply:Alive() then
				if ply:FlashlightIsOn() then
					ply:SetFlashlightCharge(math.Clamp(ply:GetFlashlightCharge() - decay, 0, 1))
				else
					ply:SetFlashlightCharge(math.Clamp(ply:GetFlashlightCharge() + decay / 2, 0, 1))
				end
			end
		end
	end
end

function GM:PlayerSwitchFlashlight(ply, turningOn)
	if turningOn then
		if ply.FlashlightPenalty && ply.FlashlightPenalty > CurTime() then
			return false
		end
	end
	return true
end

local PlayerMeta = FindMetaTable("Player")
function PlayerMeta:GetFlashlightCharge()
	return self.FlashlightCharge or 1
end

function PlayerMeta:SetFlashlightCharge(charge)
	self.FlashlightCharge = charge
	if charge <= 0 then
		self.FlashlightPenalty = CurTime() + 1.5
		if self:FlashlightIsOn() then
			self:Flashlight(false)
		end
	end
	net.Start("flashlight_charge")
	net.WriteFloat(self.FlashlightCharge)
	net.Send(self)
end