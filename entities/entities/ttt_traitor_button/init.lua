AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.TraitorButton = true
ENT.RemoveOnPress = false

function ENT:Initialize()
	self:SetModel("models/weapons/w_bugbait.mdl")

	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)

	self:SetDelay(self.RawDelay or 1)

	if self:GetDelay() < 0 || self.RemoveOnPress then
		self:SetDelay(-1)
		self.RemoveOnPress = true
	end

	if self:GetUsableRange() < 1 then
		self:SetUsableRange(1024)
	end

	self:SetNextUseTime(0)
	self:SetLocked(self:HasSpawnFlags(2048))

	self:SetDescription(self.RawDescription or "?")

	self.RawDelay = nil
	self.RawDescription = nil
end

function ENT:KeyValue(key, value)
	if key == "OnPressed" then
		self:StoreOutput(key, value)
	elseif key == "wait" then
		self.RawDelay = tonumber(value)
	elseif key == "description" then
		self.RawDescription = tostring(value)

		if self.RawDescription == "" then
			self.RawDescription = nil
		end
	elseif key == "RemoveOnPress" then
		self.RemoveOnPress = tobool(value)
	else
		// this is a terrible idea, but I don't know if it does something important in TTT
		self:SetNetworkKeyValue(key, value)
	end
end


function ENT:AcceptInput(name, activator)
	if name == "Toggle" then
		self:SetLocked(not self:GetLocked())
		return true
	elseif name == "Hide" or name == "Lock" then
		self:SetLocked(true)
		return true
	elseif name == "Unhide" or name == "Unlock" then
		self:SetLocked(false)
		return true
	end
end

util.AddNetworkString("TTT_ConfirmUseTButton")

function ENT:TraitorButtonPressed(ply)
	if self:GetNextUseTime() > CurTime() then
		return
	end
	self:TriggerOutput("OnPressed", ply)

	if self.RemoveOnPress then
		self:SetLocked(true)
		self:Remove()
	else
		self:SetNextUseTime(CurTime() + self:GetDelay())
	end

	net.Start("TTT_ConfirmUseTButton")
	net.Send(ply)
	return true
end