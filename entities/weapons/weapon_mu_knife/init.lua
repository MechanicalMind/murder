AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include("shared.lua")

util.AddNetworkString("mu_knife_charge")

SWEP.KnifeChargeConvar = CreateConVar("mu_knife_charge", 1, bit.bor(FCVAR_NOTIFY), "Should we use a charge bar on alt attack?" )

function SWEP:Initialize()
	self:SetHoldType("melee")
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

