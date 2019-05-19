if SERVER then
	AddCSLuaFile()


	util.AddNetworkString("mu_knife_charge")

	SWEP.KnifeChargeConvar = CreateConVar("mu_knife_charge", 1, bit.bor(FCVAR_NOTIFY), "Should we use a charge bar on alt attack?" )
else
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
end

SWEP.Base = "weapon_mers_base"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 65

SWEP.HoldType = "knife"
SWEP.SequenceDraw = "draw"
SWEP.SequenceIdle = "idle"

SWEP.Primary.Sequence = {"midslash1", "midslash2"}
SWEP.Primary.Delay = 0.5
SWEP.Primary.Recoil = 3
SWEP.Primary.Damage = 120
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.04
SWEP.Primary.ClipSize = -1
SWEP.Primary.Force = 900
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.PrintName = translate and translate.knife or "Knife"
function SWEP:Initialize()
	self.PrintName = translate and translate.knife or "Knife"
	self.BaseClass.Initialize(self)
end

function SWEP:SetupDataTables()
	self.BaseClass.SetupDataTables(self)
	self:NetworkVar("Float", 3, "FistHit")
end

function SWEP:Holster()
	if SERVER then
		if IsValid(self.Owner) then
			net.Start("mu_knife_charge")
			net.WriteEntity(self)
			net.WriteUInt(0, 8)
			net.Send(self.Owner)
		end

		self.ChargeStart = nil
	end
	return self.BaseClass.Holster(self)
end

function SWEP:GetFistRange()
	return 40
end

function SWEP:DoPrimaryAttackEffect()
	-- self.Owner:ViewPunch(Angle(3, 0, math.Rand(-3, 3)))
	self:SetFistHit(CurTime() + 0.1)
end

function SWEP:Think()
	self.BaseClass.Think(self)
	if self:GetFistHit() != 0 && self:GetFistHit() < RealTime() then
		self:SetFistHit(0)
		if IsFirstTimePredicted() then
			self:AttackTrace()
		end
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
	trace.endpos = trace.start + vec * self:GetFistRange()
	local tr = util.TraceLine(trace)
	tr.TraceAimVector = vec
	tr.LeftUp = Vector(left or 0, up or 0, 0)
	return tr
end

function SWEP:AttackTrace()
	if self.Owner:IsPlayer() then
		self.Owner:LagCompensation( true )
	end
	local trace = {}
	trace.filter = self.Owner
	trace.start = self.Owner:GetShootPos()
	trace.mask = MASK_SHOT_HULL
	trace.endpos = trace.start + self.Owner:GetAimVector() * self:GetFistRange()
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
		if IsValid(tr.Entity) then
			if CLIENT && LocalPlayer() == self.Owner then
				self:EmitSound("Weapon_Crowbar.Melee_Hit")
			end
			local dmg = DamageInfo()
			dmg:SetDamage(self.Primary.Damage or 1)
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
	if self.Owner:IsPlayer() then
		self.Owner:LagCompensation( false )
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

function SWEP:SecondaryAttack()
	if !self:IsIdle() then return end

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

function SWEP:Reload()
	if self.ChargeStart then
		self.ChargeStart = nil
		if SERVER then
			net.Start("mu_knife_charge")
			net.WriteEntity(self)
			net.WriteUInt(0, 8)
			net.Send(self.Owner)
		end
		return
	end
end