include("shared.lua")

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModelFOV = 65

SWEP.Slot = 1
SWEP.SlotPos = 1

killicon.AddFont( "weapon_pk_fists", "HL2MPTypeDeath", "5", Color( 0, 0, 255, 255 ) )

function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
	draw.DrawText("nife","MersText1",x + w * 0.5,y + h * 0.51,Color(255,150,0,alpha),1)
	draw.DrawText("K","MersHead1",x + w * 0.405,y + h * 0.49,Color(255,50,50,alpha),1)
end

function SWEP:Initialize()
	self:SetWeaponHoldType("melee")
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
	return false
end


function SWEP:DrawHUD()
end  