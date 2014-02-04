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

function SWEP:CanPickup(ent)
	if ent:IsWeapon() || ent:IsPlayer() || ent:IsNPC() then
		return false
	end
	local class = ent:GetClass()
	if class == "prop_ragdoll" then return true end
	if class == "prop_physics" then return true end
	if class == "prop_physics_multiplayer" then return true end
	return false
end

function SWEP:SecondaryAttack()
	if SERVER then
		self:SetCarrying()
		local tr = self.Owner:GetEyeTraceNoCursor()

		if IsValid(tr.Entity) && self:CanPickup(tr.Entity) then
			self:SetCarrying(tr.Entity, tr.PhysicsBone)
			self:ApplyForce()
		end
	end
end

function SWEP:ApplyForce()
	local target = self.Owner:GetAimVector() * 30 + self.Owner:GetShootPos()
	local phys = self.CarryEnt:GetPhysicsObjectNum( self.CarryBone )
	if IsValid(phys) then
		local vec = target - phys:GetPos()
		local len = vec:Length()
		if len > 40 then
			self:SetCarrying()
			return
		end

		vec:Normalize()
		
		local tvec = vec * len * 15
		local avec = tvec - phys:GetVelocity()
		avec = avec:GetNormal() * math.min(45, avec:Length())
		avec = avec / phys:GetMass() * 16
		phys:AddVelocity( avec)

	end
end

function SWEP:GetCarrying()
	return self.CarryEnt
end

function SWEP:SetCarrying(ent, bone)
	if IsValid(ent) then
		self.CarryEnt = ent
		self.CarryBone = bone
	else
		self.CarryEnt = nil
		self.CarryBone = nil
	end
	self.Owner:CalculateSpeed()
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

	if IsValid(self.Owner) && self.Owner:KeyDown(IN_ATTACK2) then
		if IsValid(self.CarryEnt) then
			self:ApplyForce()
		end
	elseif self.CarryEnt != nil then
		self:SetCarrying()
	end
end

function SWEP:PrimaryAttack()
end

function SWEP:DrawWorldModel()

end
