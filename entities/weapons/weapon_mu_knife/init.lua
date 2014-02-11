AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include("shared.lua")

util.AddNetworkString("mu_knife_charge")

function SWEP:Initialize()
	self:SetWeaponHoldType("melee")
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	if IsValid(self.Owner) then
		net.Start("mu_knife_charge")
		net.WriteEntity(self)
		net.WriteUInt(0, 8)
		net.Send(self.Owner)
	end
	self.ChargeStart = nil
	return true
end

