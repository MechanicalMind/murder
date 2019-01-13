include("sh_translate.lua")
include("shared.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")
include("cl_footsteps.lua")
include("cl_respawn.lua")
include("cl_murderer.lua")
include("cl_player.lua")
include("cl_fixplayercolor.lua")
include("cl_ragdoll.lua")
include("cl_chattext.lua")
include("cl_voicepanels.lua")
include("cl_rounds.lua")
include("cl_endroundboard.lua")
include("cl_qmenu.lua")
include("cl_spectate.lua")
include("cl_adminpanel.lua")
include("cl_flashlight.lua")
include("cl_halos.lua")
include("cl_spawns.lua")

GM.Debug = CreateClientConVar( "mu_debug", 0, true, true )
GM.HaloRender = CreateClientConVar( "mu_halo_render", 1, true, true ) // should we render halos
GM.HaloRenderLoot = CreateClientConVar( "mu_halo_loot", 1, true, true ) // shouuld we render loot halos
GM.HaloRenderKnife = CreateClientConVar( "mu_halo_knife", 1, true, true ) // shouuld we render murderer's knife halos

function GM:Initialize() 
	self:FootStepsInit()
end

GM.FogEmitters = {}
if GAMEMODE then GM.FogEmitters = GAMEMODE.FogEmitters end
function GM:Think()
	for k, ply in pairs(player.GetAll()) do
		if ply:Alive() && ply:GetNWBool("MurdererFog") then
			if !ply.FogEmitter then
				ply.FogEmitter = ParticleEmitter(ply:GetPos())
				self.FogEmitters[ply] = ply.FogEmitter
			end
			if !ply.FogNextPart then ply.FogNextPart = CurTime() end

			local pos = ply:GetPos() + Vector(0,0,30)
			local client = LocalPlayer()

			if ply.FogNextPart < CurTime() then

				if client:GetPos():Distance(pos) > 1000 then return end

				ply.FogEmitter:SetPos(pos)
				ply.FogNextPart = CurTime() + math.Rand(0.01, 0.03)
				local vec = Vector(math.Rand(-8, 8), math.Rand(-8, 8), math.Rand(10, 55))
				local pos = ply:LocalToWorld(vec)
				local particle = ply.FogEmitter:Add( "particle/snow.vmt", pos)
				particle:SetVelocity(  Vector(0,0, 4) + VectorRand() * 3 )
				particle:SetDieTime( 5 )
				particle:SetStartAlpha( 180 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 6 )
				particle:SetEndSize( 7 )   
				particle:SetRoll( 0 )
				particle:SetRollDelta( 0 )
				particle:SetColor( 0, 0, 0 )
				//particle:SetGravity( Vector( 0, 0, 10 ) )
			end
		else
			if ply.FogEmitter then
				ply.FogEmitter:Finish()
				ply.FogEmitter = nil
				self.FogEmitters[ply] = nil
			end
		end
	end

	// clean up old fog emitters
	for ply, emitter in pairs(self.FogEmitters) do
		if !IsValid(ply) || !ply:IsPlayer() then
			emitter:Finish()
			self.FogEmitters[ply] = nil
		end
	end
end


function GM:EntityRemoved(ent)

end

function GM:PostDrawViewModel( vm, ply, weapon )

	if ( weapon.UseHands || !weapon:IsScripted() ) then

		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then hands:DrawModel() end

	end

end

function GM:RenderScene( origin, angles, fov )
	-- self:FootStepsRenderScene(origin, angles, fov)
end

function GM:PostDrawTranslucentRenderables()
	self:DrawFootprints()
end

function GM:PreDrawMurderHalos(Add)
	local client = LocalPlayer()

	if IsValid(client) && client:Alive() && self.HaloRender:GetBool() then
		local halos = {}
		if self.HaloRenderLoot:GetBool() then
			for k, v in pairs(ents.FindByClass("weapon_mu_magnum")) do
				if !IsValid(v.Owner) then
					table.insert(halos, {ent = v, color = 3})
				end
			end
			for k, v in pairs(ents.FindByClass("mu_loot")) do
				table.insert(halos, {ent = v, color = 1})
			end
		end

		if self:GetAmMurderer() && self.HaloRenderKnife:GetBool() then
			for k, v in pairs(ents.FindByClass("weapon_mu_knife")) do
				if !IsValid(v.Owner) then
					table.insert(halos, {ent = v, color = 2})
				end
			end
			for k, v in pairs(ents.FindByClass("mu_knife")) do
				table.insert(halos, {ent = v, color = 2})
			end
		end
		if #halos > 0 then
			Add(halos, {Color(0, 220, 0), Color(220, 0, 0), Color(0, 0, 255)}, 5, 5, 5, true, false)
		end
	end
end

net.Receive("mu_tker", function (len)
	GAMEMODE.TKerPenalty = net.ReadUInt(8) != 0
end)