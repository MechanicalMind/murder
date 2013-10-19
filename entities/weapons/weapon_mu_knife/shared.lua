
SWEP.ViewModel = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

SWEP.PrintName = "Knife"

SWEP.Weight	= 0

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.Primary.Delay			= 0.5
SWEP.Primary.Recoil			= 3
SWEP.Primary.Damage			= 120
SWEP.Primary.NumShots		= 1	
SWEP.Primary.Cone			= 0.04
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Force			= 10
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic   	= true
SWEP.Primary.Ammo         	= "none"

SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= false
SWEP.Secondary.Ammo         = "none"

function SWEP:GetTrace(ang)
	local trace = {}
	trace.filter = self.Owner
	trace.start = self.Owner:GetShootPos()
	trace.mask = MASK_SHOT
	local vec = self.Owner:GetAimVector()
	if ang then vec:Rotate(ang) end
	trace.endpos = trace.start + vec * 60
	//trace.mask = MASK_SHOT
	local tr = util.TraceLine(trace)
	tr.TraceAimVector = vec
	tr.TraceAngle = ang
	return tr
end


function SWEP:PrimaryAttack()	
	if self.FistCanAttack then return end
	if self.IdleTime && self.IdleTime > CurTime() then return end
	self.FistCanAttack = CurTime() + self.Primary.Delay
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self:SendWeaponAnim( ACT_VM_MISSCENTER )
	self.FistHit = CurTime() + 0.1
end

function SWEP:SecondaryAttack()
	if self.FistCanAttack then return end
	if self.IdleTime && self.IdleTime > CurTime() then return end
	self.FistCanAttack = CurTime() + self.Primary.Delay
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self:SendWeaponAnim( ACT_VM_HITCENTER )

	if SERVER then
		local ent = ents.Create("mu_knife")
		ent:SetOwner(self.Owner)
		ent:SetPos(self.Owner:GetShootPos())
		local knife_ang = Angle(-28,0,0) + self.Owner:EyeAngles()
		knife_ang:RotateAroundAxis(knife_ang:Right(), -90)
		ent:SetAngles(knife_ang)
		ent:Spawn()

		local phys = ent:GetPhysicsObject()
		phys:SetVelocity(self.Owner:GetAimVector() * 1000)
		phys:AddAngleVelocity(Vector(0, 1500, 0))

		self:Remove()
	end

end

function SWEP:Think()
	if self.FistCanAttack && self.FistCanAttack < CurTime() then
		self.FistCanAttack = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
		self.IdleTime = CurTime() + 0.1
	end	
	if self.FistHit && self.FistHit < CurTime() then
		self.Owner:LagCompensation(true)
		self.FistHit = nil
		local tr = self:GetTrace()

		// aim around
		if !tr.Hit then tr = self:GetTrace(Angle(0,20,0)) end
		if !tr.Hit then tr = self:GetTrace(Angle(0,-20,0)) end
		if !tr.Hit then tr = self:GetTrace(Angle(0,0,20)) end
		if !tr.Hit then tr = self:GetTrace(Angle(0,0,-20)) end
		if tr.Hit then
			self.Owner:ViewPunch(Angle(0, 3, 0))
			if IsValid(tr.Entity) then
				// only play the sound for the murderer
				if CLIENT && LocalPlayer() == self.Owner then
					self:EmitSound("Weapon_Crowbar.Melee_Hit")
				end
			else
				self:EmitSound("Weapon_Crowbar.Melee_Hit")
			end
			local bullet = {}	-- Set up the shot
			bullet.Num = 1
			bullet.Src = self.Owner:GetShootPos()
			bullet.Dir = tr.TraceAimVector
			bullet.Spread = Vector( 0, 0, 0 )
			bullet.Tracer = 0
			bullet.Force = self.Primary.Force
			bullet.Damage = self.Primary.Damage
			self.Owner:FireBullets( bullet )
		else
			// only play the sound for the murderer
			if CLIENT && LocalPlayer() == self.Owner then
				self:EmitSound("Weapon_Crowbar.Single")
			end
		end
		self.Owner:LagCompensation(false)
	end
end