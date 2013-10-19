if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
else
	killicon.AddFont( "weapon_mu_magnum", "HL2MPTypeDeath", "1", Color( 255, 0, 0 ) )
end
SWEP.Base = "weapon_base"

SWEP.PrintName		= "Magnum"
SWEP.Slot			= 2
SWEP.SlotPos		= 1
SWEP.DrawAmmo		= true
SWEP.DrawCrosshair	= true
SWEP.ViewModelFlip	= false
SWEP.ViewModelFOV	= 50
SWEP.ViewModel		= "models/weapons/v_357.mdl"
SWEP.WorldModel		= "models/weapons/w_357.mdl"
SWEP.HoldType		= "pistol"
SWEP.PKOneOnly = true

SWEP.Weight			= 5
SWEP.AutoSwitchTo	= false
SWEP.AutoSwitchFrom	= false
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= true

SWEP.Author			= "Mechanical Mind"
SWEP.Contact		= ""
SWEP.Purpose		= "The icecream"
SWEP.Instructions	= "Magnum"

SWEP.Primary.Sound				= "Weapon_357.Single"
SWEP.Primary.Damage				= 120
SWEP.Primary.NumShots			= 1
SWEP.Primary.Recoil				= 5
SWEP.Primary.Cone				= 1
SWEP.Primary.Delay				= 3
SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Tracer				= 1
SWEP.Primary.Force				= 420
SWEP.Primary.TakeAmmoPerBullet	= false
SWEP.Primary.Automatic			= false
SWEP.Primary.Ammo				= "none"
SWEP.Primary.ReloadTime = 3.7
SWEP.ReloadFinishedSound		= Sound("Weapon_Crossbow.BoltElectrify")
SWEP.ReloadSound = Sound("Weapon_357.Reload")

SWEP.Secondary.Sound				= ""
SWEP.Secondary.Damage				= 10
SWEP.Secondary.NumShots				= 1
SWEP.Secondary.Recoil				= 1
SWEP.Secondary.Cone					= 0
SWEP.Secondary.Delay				= 0.25
SWEP.Secondary.ClipSize				= -1
SWEP.Secondary.DefaultClip			= -1
SWEP.Secondary.Tracer				= -1
SWEP.Secondary.Force				= 5
SWEP.Secondary.TakeAmmoPerBullet	= false
SWEP.Secondary.Automatic			= false
SWEP.Secondary.Ammo					= "none"

if SERVER then
	util.AddNetworkString("pkshotguncanattack")
end

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
	self.CanAttack = true
end

function SWEP:BulletCallback(att, tr, dmg)
	return {effects = true,damage = true}
end

function SWEP:PrimaryAttack()
	if !self.CanAttack then return false end
	local bullet = {}	-- Set up the shot
		bullet.Num = self.Primary.NumShots
		bullet.Src = self.Owner:GetShootPos()
		bullet.Dir = self.Owner:GetAimVector()
		bullet.Spread = Vector( self.Primary.Cone / 90, self.Primary.Cone / 90, 0 )
		bullet.Tracer = self.Primary.Tracer
		bullet.Force = self.Primary.Force
		bullet.Damage = self.Primary.Damage
		-- function bullet.Callback(att,tr,dmg)
		-- 	self:BulletCallback(att, tr, dmg)
		-- end
	self.Owner:FireBullets( bullet )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self:EmitSound(Sound(self.Primary.Sound))
	self.Owner:ViewPunch(Angle( -self.Primary.Recoil, 0, 0 ))

	self.NextLower = CurTime() + 0.4
	self.CanAttack = false

	// hacky fix for client, don't send immediately
	timer.Simple(0, function () if IsValid(self) then self:NetCanAttack() end end)

end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
	if self.NextAttack && self.NextAttack < CurTime() then
		self.NextAttack = nil
		self.CanAttack = true
		self:NetCanAttack()
		//self:SendWeaponAnim( ACT_VM_IDLE)
		//self.Owner:ChatPrint("Cake")
	end
	if self.NextLower && self.NextLower < CurTime() then
		self.NextLower = nil
		self.NextUpper = CurTime() + self.Primary.ReloadTime
		self:SendWeaponAnim(ACT_VM_RELOAD)
		-- self:EmitSound(self.ReloadSound)
		local i = math.random(1,3)
		if i == 2 then i = 4 end
		self:EmitSound("weapons/357/357_reload" .. i .. ".wav")
		self.Owner:SetAnimation( PLAYER_RELOAD )
	end
	if self.NextUpper && self.NextUpper < CurTime() then
		self.NextUpper = nil
		self.NextAttack = CurTime() + 0.1
		-- self:SendWeaponAnim(ACT_VM_IDLE)
		-- self:EmitSound(self.ReloadFinishedSound)
	end
end

function SWEP:Reload()

end

if CLIENT then
	net.Receive("pkshotguncanattack", function (len)
		local ent = net.ReadEntity()
		local canattack = net.ReadUInt(8)
		if IsValid(ent) then
			ent.CanAttack = canattack != 0
		end
	end)
end

function SWEP:NetCanAttack()
	if SERVER then
		if IsValid(self.Owner) && self.Owner:IsPlayer() then
			net.Start("pkshotguncanattack")
			net.WriteEntity(self)
			net.WriteUInt(self.CanAttack and 1 or 0,8)
			net.Send(self.Owner)
		end
	end
end

function SWEP:Deploy()
	if !self.CanAttack then
		self.NextAttack = nil
		self.NextLower = nil
		self.NextUpper = CurTime() + self.Primary.ReloadTime
		self:EmitSound(self.ReloadSound)
		self:SendWeaponAnim(ACT_VM_RELOAD)
		self:NetCanAttack()
	end
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
end

function SWEP:OnRestore()
end

function SWEP:Precache()
end

function SWEP:OwnerChanged()
end
