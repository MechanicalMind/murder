if SERVER then
	AddCSLuaFile()
else
	function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
		-- draw.DrawText("Hands","Default",x + w * 0.44,y + h * 0.20,Color(0,50,200,alpha),1)
	end
end

SWEP.Base = "weapon_mers_base"
SWEP.Slot = 0
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.ViewModel	= "models/weapons/c_arms.mdl"
SWEP.WorldModel	= ""
SWEP.ViewModelFlip = false

SWEP.HoldType = "normal"
SWEP.SequenceDraw = "fists_draw"
SWEP.SequenceIdle = "fists_idle_01"

SWEP.PrintName = translate and translate.hands or "Hands"
function SWEP:Initialize()
	self.PrintName = translate and translate.hands or "Hands"
	self.BaseClass.Initialize(self)
end

function SWEP:DoPrimaryAttackEffect()
end

local function addangle(ang,ang2)
	ang:RotateAroundAxis(ang:Up(),ang2.y) -- yaw
	ang:RotateAroundAxis(ang:Forward(),ang2.r) -- roll
	ang:RotateAroundAxis(ang:Right(),ang2.p) -- pitch
end

function SWEP:CalcViewModelView(vm, opos, oang, pos, ang)

	// iron sights
	local pos2 = Vector(-35, 0, 0)
	addangle(ang, Angle(-90, 0, 0))
	pos2:Rotate(ang)
	return pos + pos2, ang
end


local pickupWhiteList = {
	prop_ragdoll = true,
	prop_physics = true,
	prop_physics_multiplayer = true
}

if SERVER then
	function SWEP:CanPickup(ent)
		if ent:IsWeapon() || ent:IsPlayer() || ent:IsNPC() then return false end

		local class = ent:GetClass()
		if pickupWhiteList[class] then return true end

		return false
	end
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
	local phys = self.CarryEnt:GetPhysicsObjectNum(self.CarryBone)

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

		phys:AddVelocity(avec)
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
	self.BaseClass.Think(self)
	if IsValid(self.Owner) && self.Owner:KeyDown(IN_ATTACK2) then
		if IsValid(self.CarryEnt) then
			self:ApplyForce()
		end
	elseif self.CarryEnt then
		self:SetCarrying()
	end
end

function SWEP:PrimaryAttack()
	if SERVER then
		if IsValid(self.Owner) then
			// Disabled until https://github.com/Facepunch/garrysmod-issues/issues/2668 is fixed
			-- if self.Owner:HasWeapon("weapon_mu_knife") then
			-- 	self.Owner:SelectWeapon("weapon_mu_knife")
			-- elseif self.Owner:HasWeapon("weapon_mu_magnum") then
			-- 	self.Owner:SelectWeapon("weapon_mu_magnum")
			-- end
		end
	end
end