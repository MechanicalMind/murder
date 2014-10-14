include("shared.lua")

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModelFOV = 65

SWEP.Slot = 1
SWEP.SlotPos = 1

killicon.AddFont("weapon_mu_knife", "HL2MPTypeDeath", "5", Color(0, 0, 255, 255))

function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
	local name = translate and translate.knife or "Knife"
	surface.SetFont("MersText1")
	local tw, th = surface.GetTextSize(name:sub(2))
	
	surface.SetFont("MersHead1")
	local twf, thf = surface.GetTextSize(name:sub(1, 1))
	tw = tw + twf + 1
	
	draw.DrawText(name:sub(2), "MersText1", x + w * 0.5 - tw / 2 + twf + 1, y + h * 0.51, Color(255, 150, 0, alpha), 0)
	draw.DrawText(name:sub(1, 1), "MersHead1", x + w * 0.5 - tw / 2 , y + h * 0.49, Color(255, 50, 50, alpha), 0)
end

function SWEP:Initialize()
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:DrawViewModel()	
	return false
end

function SWEP:DrawWorldModel()	
	self:DrawModel()
end

function SWEP:DrawHUD()
	if self.ChargeStart then
		local sw, sh = ScrW(), ScrH()
		local charge = self:GetCharge()

		-- draw.DrawText("Charging" .. (math.Round(self:GetCharge() * 100) / 100),"MersHead1", sw * 0.5, sh * 0.5 + 30, color_white,1)

		local w, h = math.Round(ScrW() * 0.2), 40
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(sw / 2 - w / 2, sh / 2 - h / 2 + 120, w, h)

		surface.SetDrawColor(255, 0, 0, 150)
		surface.DrawRect(sw / 2 - w / 2, sh / 2 - h / 2 + 120, w * charge, h)
	end
end  

net.Receive("mu_knife_charge", function(len)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	
	local charging = net.ReadUInt(8) != 0
	if charging then
		ent.ChargeStart = net.ReadDouble()
	else
		ent.ChargeStart = nil
	end
end)