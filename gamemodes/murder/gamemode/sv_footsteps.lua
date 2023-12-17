util.AddNetworkString("add_footstep")
util.AddNetworkString("clear_footsteps")

function GM:FootstepsOnFootstep(ply, pos, foot, sound, volume, filter)
	net.Start("add_footstep")
	net.WriteEntity(ply)
	net.WriteVector(pos)
	net.WriteAngle(ply:GetAimVector():Angle())
	local tab = {}
	for k, ply in pairs(player.GetAll()) do
		if self:CanSeeFootsteps(ply) then
			table.insert(tab, ply)
		end
	end
	net.Send(tab)
end

function GM:CanSeeFootsteps(ply)
	if ply:GetMurderer() && ply:Alive() then return true end
	return false
end

function GM:ClearAllFootsteps()
	net.Start("clear_footsteps")
	net.Broadcast()
end