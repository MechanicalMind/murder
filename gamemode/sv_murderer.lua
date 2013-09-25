local PlayerMeta = FindMetaTable("Player")


function PlayerMeta:SetMurderer(bool)
	self.Murderer = bool
	net.Start( "your_are_a_murderer" )
	net.WriteUInt(bool and 1 or 0, 8)
	net.Send( self )
end

function PlayerMeta:GetMurderer(bool)
	return self.Murderer
end

local NO_KNIFE_TIME = 30
function GM:MurdererThink()
	local players = team.GetPlayers(2)
	local murderer
	for k,ply in pairs(players) do
		if ply:GetMurderer() then
			murderer = ply
			break
		end
	end

	// regenerate knife if on ground
	if IsValid(murderer) && murderer:Alive() then
		if murderer:HasWeapon("weapon_mu_knife") then
			murderer.LastHadKnife = CurTime()
		else
			if murderer.LastHadKnife && murderer.LastHadKnife + NO_KNIFE_TIME < CurTime() then
				for k, ent in pairs(ents.FindByClass("weapon_mu_knife")) do
					ent:Remove()
				end
				for k, ent in pairs(ents.FindByClass("mu_knife")) do
					ent:Remove()
				end
				murderer:Give("weapon_mu_knife")
			end
		end
	end
end