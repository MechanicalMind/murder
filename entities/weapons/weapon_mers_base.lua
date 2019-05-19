if ( SERVER ) then
	AddCSLuaFile()

	util.AddNetworkString("mers_base_holdtype")


	concommand.Add("mers_weapon_info", function (ply)
		local wep = ply:GetActiveWeapon()
		local vm = ply:GetViewModel()
		local ct = ChatText()
		for i = 0, vm:GetSequenceCount() - 1 do
			ct:Add(i .. "\t" .. vm:GetSequenceName(i) .. "\t" .. vm:SequenceDuration(i) .. "\n")
		end

		for k, v in pairs(wep.Primary) do
			ct:Add(tostring(k) .. "\t" .. tostring(v) .. "\n")
		end
		ct:Send(ply)
	end)
else
	net.Receive("mers_base_holdtype", function (len)
		local wep = net.ReadEntity()
		if IsValid(wep) && wep:IsWeapon() && wep.SetWeaponHoldType then
			wep:SetWeaponHoldType(net.ReadString())
		end
	end)
end
SWEP.Base = "weapon_base"
SWEP.Weight			= 5
SWEP.AutoSwitchTo	= false
SWEP.AutoSwitchFrom	= false
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= true
SWEP.UseHands = true

SWEP.Author			= "Mechanical Mind"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV = 50
SWEP.HolsterHoldTime = 0.3

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:Initialize()
	self:SetWeaponState("holster")
	self:CalculateHoldType()
	self.HolsterPercent = 1
	self.IronsightsPercent = 0
end

function SWEP:SetNetHoldType(name)
	self:SetWeaponHoldType(name)
	if SERVER then
		net.Start("mers_base_holdtype")
		net.WriteEntity(self)
		net.WriteString(name)
		net.Broadcast()
	end
end

function SWEP:CalculateHoldType()
	local holdtype = self.HoldType
	// crouching in passive holdtype looks wierd, use smg instead
	if holdtype == "passive" && IsValid(self.Owner) && self.Owner:Crouching() then
		holdtype = self.HoldType or "smg"
	end
	if self.OldHoldType != holdtype then
		self.OldHoldType = holdtype
		self:SetNetHoldType(holdtype)
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "WeaponState")
	self:NetworkVar("Float", 0, "ReloadEnd")
	self:NetworkVar("Float", 1, "NextIdle")
	self:NetworkVar("Float", 2, "DrawEnd")
end

function SWEP:IsIdle()
	if self:GetReloadEnd() > 0 && self:GetReloadEnd() >= CurTime() then return false end
	if self:GetNextPrimaryFire() > 0 && self:GetNextPrimaryFire() >= CurTime() then return false end
	if self:GetDrawEnd() > 0 && self:GetDrawEnd() >= CurTime() then return false end
	return true
end

function SWEP:PrimaryAttack()
	if !self:IsIdle() then return end
	if self:GetMaxClip1() > 0 && self:Clip1() <= 0 then
		self:Reload()
		return
	end
	local vm = self.Owner:GetViewModel()
	if self.Primary.Sequence then
		local sequence = self.Primary.Sequence
		if type(sequence) == "table" then
			if IsFirstTimePredicted() then
				self.LastSequence = ((self.LastSequence or -1) + 1) % #sequence
			end
			sequence = sequence[self.LastSequence + 1]
		end
		vm:SendViewModelMatchingSequence(vm:LookupSequence(sequence))
	end

	self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or vm:SequenceDuration()))
	self:SetNextIdle(CurTime() + vm:SequenceDuration())
	self:TakePrimaryAmmo(1)

	if self.Primary.Sound then
		self:EmitSound(self.Primary.Sound)
	end
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	local stats = {}
	stats.recoil = self.Primary.Recoil or 1
	stats.damage = self.Primary.Damage or 1
	stats.cone = self.Primary.Cone or 0.1
	if self.Primary.Recoil then
		stats.recoil = stats.recoil or 1
		if IsFirstTimePredicted() && CLIENT then
			local circle = Angle(0, math.Rand(0, 360), 0)
			local vec = circle:Forward() * math.Rand(stats.recoil * 0.8, stats.recoil) * 0.1
			vec.y = -math.abs(vec.y) - stats.recoil * 0.2
			if ViewPosition then ViewPosition:Recoil(vec) end
		end
	end
	hook.Run("CalculateWeaponPrimaryFireStats", self, self.Owner, stats)
	self:DoPrimaryAttackEffect(stats)
end

function SWEP:DoPrimaryAttackEffect(stats)
	local bullet = {}
	bullet.Num = self.Primary.NumShots or 1
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector(stats.cone or 0, stats.cone or 0, 0)
	bullet.Tracer = self.Primary.Tracer or 1
	bullet.Force = self.Primary.Force or ((self.Primary.Damage or 1) * 3)
	bullet.Damage = stats.damage or 1
	self.Owner:FireBullets(bullet)
end

function SWEP:SecondaryAttack()
end

local function lerp(from, to, step)
	if from < to then
		return math.min(from + step, to)
	end
	return math.max(from - step, to)
end

function SWEP:Think()
	self:CalculateHoldType()
	if self:GetReloadEnd() > 0 && self:GetReloadEnd() < CurTime() then
		self:SetReloadEnd(0)

		if self.Primary.InfiniteAmmo then
			self:SetClip1(self:GetMaxClip1())
		else
			local spare = self.Owner:GetAmmoCount(self:GetPrimaryAmmoType())
			local addAmmo = math.min(self:GetMaxClip1() - self:Clip1(), spare)
			self:SetClip1(self:Clip1() + addAmmo)
			self.Owner:SetAmmo(spare - addAmmo, self:GetPrimaryAmmoType())
		end
	end
	if self:GetNextIdle() > 0 && self:GetNextIdle() < CurTime() then
		self:SetNextIdle(0)

		local sequence = self.SequenceIdle
		local vm = self.Owner:GetViewModel()
		vm:SendViewModelMatchingSequence(vm:LookupSequence(sequence))
		if self.Primary.AutoReload then
			if self:GetMaxClip1() > 0 && self:Clip1() <= 0 then
				self:Reload()
			end
		end
	end

	if IsValid(self.Owner) then
		if !self.Owner:KeyDown(IN_RELOAD) then
			self.ReloadHoldStart = nil
		end
		self.UsingIronsights = false
		if self.Owner:KeyDown(IN_ATTACK2) && self:GetWeaponState() != "holster" then
			self.UsingIronsights = true
		end
	end

	self.IronsightsPercent = lerp(self.IronsightsPercent, self.UsingIronsights and 1 or 0, FrameTime() * 2.5)
end

function SWEP:Reload()
	if self:IsIdle() then
		if self:GetWeaponState() == "normal" && self:GetMaxClip1() > 0 && self:Clip1() < self:GetMaxClip1() then
			local spare = self.Owner:GetAmmoCount(self:GetPrimaryAmmoType())
			if spare > 0 || self.Primary.InfiniteAmmo then
				local vm = self.Owner:GetViewModel()
				vm:SendViewModelMatchingSequence(vm:LookupSequence(self.ReloadSequence))
				if self.ReloadSound then
					self:EmitSound(self.ReloadSound)
				end
				self.Owner:SetAnimation(PLAYER_RELOAD)
				self:SetReloadEnd(CurTime() + vm:SequenceDuration())
				self:SetNextIdle(CurTime() + vm:SequenceDuration())
			end
		end
	end
end

function SWEP:Deploy()
	self:SetWeaponState("normal")
	self:CalculateHoldType()
	local time = 1
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		if self.SequenceDraw then
			vm:SendViewModelMatchingSequence(vm:LookupSequence(self.SequenceDraw))
			time = vm:SequenceDuration()
		elseif self.SequenceDrawTime then
			time = self.SequenceDrawTime
		end
	end
	self:SetDrawEnd(CurTime() + 0)
	self:SetNextIdle(CurTime() + time)
	return true
end

function SWEP:Holster(newWep)
	return true
end

local function ease(t)
	if t<.5 then return 2*t*t else return -1+(4-2*t)*t end
end

local function addangle(ang,ang2)
	ang:RotateAroundAxis(ang:Up(),ang2.y) -- yaw
	ang:RotateAroundAxis(ang:Forward(),ang2.r) -- roll
	ang:RotateAroundAxis(ang:Right(),ang2.p) -- pitch
end

function SWEP:CalcViewModelView(vm, opos, oang, pos, ang)

	// iron sights
	local addpos, addang = Vector(0, 0, 0), Angle(0, 0, 0)
	if self.Ironsights then
		addpos = self.Ironsights.Pos or addpos
		addang = self.Ironsights.Angle or addang
	end
	local pos2 = addpos * ease(self.IronsightsPercent)
	addangle(ang, addang * ease(self.IronsightsPercent))
	pos2:Rotate(ang)
	return pos + pos2, ang
end

function SWEP:OnRemove()
end