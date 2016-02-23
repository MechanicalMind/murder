SWEP.ViewModel = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

SWEP.PrintName = translate and translate.knife or "Knife"

SWEP.Weight	= 0

SWEP.Spawnable			= true
SWEP.AdminOnly			= true

SWEP.Primary.Delay			= 0.5
SWEP.Primary.Recoil			= 3
SWEP.Primary.Damage			= 120
SWEP.Primary.NumShots		= 1	
SWEP.Primary.Cone			= 0.04
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Force			= 900
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

function SWEP:GetTrace(left, up)
	local trace = {}
	trace.filter = self.Owner
	trace.start = self.Owner:GetShootPos()
	trace.mask = MASK_SHOT_HULL
	local ang = self.Owner:GetAimVector():Angle()
	if left then
		ang:RotateAroundAxis(ang:Up(), left)
	end
	if up then
		ang:RotateAroundAxis(ang:Right(), up)
	end
	local vec = ang:Forward()
	trace.endpos = trace.start + vec * 60
	local tr = util.TraceLine(trace)
	tr.TraceAimVector = vec
	tr.LeftUp = Vector(left or 0, up or 0, 0)
	return tr
end


function SWEP:PrimaryAttack()
	if self.ChargeStart then
		self.ChargeStart = nil
		if SERVER then
			net.Start("mu_knife_charge")
			net.WriteEntity(self)
			net.WriteUInt(0, 8)
			net.Send(self.Owner)
		end
		self.FistCanAttack = CurTime() + self.Primary.Delay
		return
	end
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

	if SERVER then
		if self.KnifeChargeConvar:GetBool() then
			self.ChargeStart = CurTime()
			net.Start("mu_knife_charge")
			net.WriteEntity(self)
			net.WriteUInt(1, 8)
			net.WriteDouble(self.ChargeStart)
			net.Send(self.Owner)
		else
			self:ThrowKnife(0.6)
		end
	end

end

function SWEP:GetCharge()
	local start = CurTime() - (self.ChargeStart or 0)
	return math.Clamp((math.sin(start * 2 - 1) + 1) / 2, 0, 1)
end

function SWEP:ThrowKnife(force)
	local ent = ents.Create("mu_knife")
	ent:SetOwner(self.Owner)
	ent:SetPos(self.Owner:GetShootPos())
	local knife_ang = Angle(-28,0,0) + self.Owner:EyeAngles()
	knife_ang:RotateAroundAxis(knife_ang:Right(), -90)
	ent:SetAngles(knife_ang)
	ent:Spawn()


	local phys = ent:GetPhysicsObject()
	phys:SetVelocity(self.Owner:GetAimVector() * (force * 1000 + 200))
	phys:AddAngleVelocity(Vector(0, 1500, 0))

	self:Remove()
end

function SWEP:Think()
	if self.FistCanAttack && self.FistCanAttack < CurTime() then
		self.FistCanAttack = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
		self.IdleTime = CurTime() + 0.1
	end	
	if self.FistHit && self.FistHit < CurTime() then
		self.FistHit = nil
		self:AttackTrace()
	end
	if SERVER && self.ChargeStart then
		if !IsValid(self.Owner) || !self.Owner:KeyDown(IN_ATTACK2) then
			if IsValid(self.Owner) then
				self:ThrowKnife(self:GetCharge())
				net.Start("mu_knife_charge")
				net.WriteEntity(self)
				net.WriteUInt(0, 8)
				net.Send(self.Owner)
			end
			self.ChargeStart = nil
		end
	end
end

function SWEP:AttackTrace()
	self.Owner:LagCompensation(true)
	local trace = {}
	trace.filter = self.Owner
	trace.start = self.Owner:GetShootPos()
	trace.mask = MASK_SHOT_HULL
	trace.endpos = trace.start + self.Owner:GetAimVector() * 60
	trace.mins = Vector(-10, -10, -10)
	trace.maxs = Vector(10, 10, 10)
	local tr = util.TraceHull(trace)
	tr.TraceAimVector = self.Owner:GetAimVector()

	// aim around
	if !IsValid(tr.Entity) then tr = self:GetTrace() end
	if !IsValid(tr.Entity) then tr = self:GetTrace(10,0) end
	if !IsValid(tr.Entity) then tr = self:GetTrace(-10,0) end
	if !IsValid(tr.Entity) then tr = self:GetTrace(0,10) end
	if !IsValid(tr.Entity) then tr = self:GetTrace(0,-10) end
	if tr.Hit then
		self.Owner:ViewPunch(Angle(0, 3, 0))
		if IsValid(tr.Entity) then
			// only play the sound for the murderer
			if CLIENT && LocalPlayer() == self.Owner then
				self:EmitSound("Weapon_Crowbar.Melee_Hit")
			end
			local dmg = DamageInfo()
			dmg:SetDamage(self.Primary.Damage)
			dmg:SetAttacker(self.Owner)
			dmg:SetInflictor(self.Weapon or self)
			dmg:SetDamageForce(self.Owner:GetAimVector() * self.Primary.Force)
			dmg:SetDamagePosition(tr.HitPos)
			dmg:SetDamageType(DMG_SLASH)
			tr.Entity:DispatchTraceAttack(dmg, tr)

			if tr.Entity != self && tr.Entity != self.Owner && (tr.Entity:IsPlayer() || tr.Entity:GetClass() == "prop_ragdoll") then
				local edata = EffectData()
				edata:SetStart(self.Owner:GetShootPos())
				edata:SetOrigin(tr.HitPos)
				edata:SetNormal(tr.Normal)
				edata:SetEntity(tr.Entity)
				util.Effect("BloodImpact", edata)
			end
		else
			self:EmitSound("Weapon_Crowbar.Melee_Hit")
		end
	else
		// only play the sound for the murderer
		if CLIENT && LocalPlayer() == self.Owner then
			self:EmitSound("Weapon_Crowbar.Single")
		end
	end
	self.Owner:LagCompensation(false)
end

function SWEP:Reload()
	if self.ChargeStart then
		self.ChargeStart = nil
		if SERVER then
			net.Start("mu_knife_charge")
			net.WriteEntity(self)
			net.WriteUInt(0, 8)
			net.Send(self.Owner)
		end
		self.FistCanAttack = CurTime() + self.Primary.Delay
		return
	end
end