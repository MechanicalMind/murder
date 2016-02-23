if SERVER then
	AddCSLuaFile()
else
	function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
	end
end

SWEP.Base = "weapon_mers_base"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.ViewModelFlip = false

SWEP.HoldType = "revolver"
SWEP.SequenceDraw = "draw"
SWEP.SequenceIdle = "idle01"
SWEP.SequenceHolster = "holster"

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Sound = "Weapon_357.Single"
SWEP.Primary.Sequence = "fire"
-- SWEP.Primary.Delay = 0.
SWEP.Primary.Damage = 200
SWEP.Primary.Cone = 0
SWEP.Primary.DryFireSequence = "fireempty"
SWEP.Primary.DryFireSound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Recoil = 9
SWEP.Primary.InfiniteAmmo = true
SWEP.Primary.AutoReload = true


SWEP.ReloadSequence = "reload"
SWEP.ReloadSound = Sound("Weapon_357.Reload")

SWEP.PrintName = translate and translate.magnum or "Magnum"
function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	self.PrintName = translate and translate.magnum or "Magnum"
	self:SetClip1(self:GetMaxClip1())
end

function SWEP:DoPrimaryAttackEffect(stats)
	local bullet = {}	-- Set up the shot
	bullet.Num = self.Primary.NumShots or 1
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector(stats.cone or 0, stats.cone or 0, 0)
	bullet.Tracer = 1
	bullet.TracerName = "mu_magnum_shoot"
	bullet.Force = self.Primary.Force or ((self.Primary.Damage or 1) * 3)
	bullet.Damage = stats.damage or 1
	self.Owner:FireBullets(bullet)
	
	local eff = EffectData()
	eff:SetOrigin(self.Owner:GetShootPos())
	eff:SetNormal(self.Owner:GetAimVector())
	eff:SetEntity(self.Owner)
	eff:SetAttachment(1)
	-- util.Effect("mu_magnum_shoot",eff)
end
	