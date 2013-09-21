AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_footsteps.lua")
AddCSLuaFile("cl_respawn.lua")
AddCSLuaFile("cl_murderer.lua")
AddCSLuaFile("cl_player.lua")

include("shared.lua")
include("sv_player.lua")
include("sv_parkour.lua")
include("sv_spawns.lua")
include("sv_stealth.lua")
include("sv_ragdoll.lua")
include("sv_respawn.lua")
include("sv_murderer.lua")
include("sv_rounds.lua")
include("sv_footsteps.lua")

resource.AddFile("materials/thieves/footprint.vmt")

util.AddNetworkString("your_are_a_murderer")

function GM:Initialize() 
	self:LoadSpawns()
	self.DeathRagdolls = {}
	self:StartNewRound()
end

function GM:InitPostEntity() 
	for k, ent in pairs(ents.GetAll()) do
		if ent:GetClass():find("door") then
			ent:Fire("unlock","",0)
		end
	end
end

function GM:Think()
	self:ParkourThink()
	self:RoundThink()
end

function GM:AllowPlayerPickup( ply, ent )
	return true
end

function GM:PlayerNoClip( ply )
	return ply:IsAdmin() || ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:PlayerSwitchFlashlight(ply, turningOn)
	return true
end

function GM:OnEndRound()

end

function GM:OnStartRound()
	
end

function GM:SendMessageAll(msg) 
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint(msg)
	end
end

