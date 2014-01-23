if SERVER then

	AddCSLuaFile( "shared.lua" )

	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
else

	SWEP.PrintName			= "Hands"
	SWEP.Slot				= 0
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

	SWEP.ViewModelFOV		= 60

	function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
		-- draw.DrawText("Hands","Default",x + w * 0.44,y + h * 0.20,Color(0,50,200,alpha),1)
	end

	function SWEP:DrawHUD()
	end

end

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

SWEP.HoldType = "normal"

SWEP.ViewModel	= "models/weapons/v_crowbar.mdl"
SWEP.WorldModel	= "models/weapons/w_crowbar.mdl"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"


function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	self.CurHoldType = self.HoldType
	self:DrawShadow(false)
end

function SWEP:Deploy()
	if SERVER then
		self:SetColor(255,255,255,0)
		if IsValid(self.Owner) then
			timer.Simple(0,function ()
				if IsValid(self) && IsValid(self.Owner) then
					self.Owner:DrawViewModel(false)
				end
			end)
		end
	end
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
	local nht = self.HoldType
	if self.CurHoldType != nht then
		self.CurHoldType = nht
		self:SetWeaponHoldType(nht)
		if SERVER then
			umsg.Start("rp_holdtype")
			umsg.Entity(self)
			umsg.String(nht)
			umsg.End()
		end
	end
end

function SWEP:PrimaryAttack()
end

function SWEP:DrawWorldModel()

end
