GM.FootstepMaxLifeTime = CreateClientConVar( "mu_footstep_maxlifetime", 30, true, true )

local FootSteps = {}
if FootStepsG then
	FootSteps = FootStepsG
end
FootStepsG = FootSteps

function GM:FootStepsInit()
	
end

local footMat = Material( "thieves/footprint" )
-- local CircleMat = Material( "Decals/burn02a" )
local maxDistance = 600 ^ 2
local function renderfoot(self)
	cam.Start3D(EyePos(), EyeAngles())
	render.SetMaterial( footMat )
	local pos = EyePos()
	local lifeTime = math.Clamp(self.FootstepMaxLifeTime:GetInt(), 0, 30)
	for k, footstep in pairs(FootSteps) do
		if footstep.curtime + lifeTime > CurTime() then
			if (footstep.pos - EyePos()):LengthSqr() < maxDistance then
				render.DrawQuadEasy( footstep.pos + footstep.normal * 0.01, footstep.normal, 10, 20, footstep.col, footstep.angle )  
			end
		else
			FootSteps[k] = nil
		end
	end
	cam.End3D()
end

function GM:DrawFootprints()


	local errored, retval = pcall(renderfoot, self)

	if ( !errored ) then
		ErrorNoHalt( retval )
	end

end

function GM:AddFootstep(ply, pos, ang) 
	ang.p = 0
	ang.r = 0
	local fpos = pos
	if ply.LastFoot then
		fpos = fpos + ang:Right() * 5
	else
		fpos = fpos + ang:Right() * -5
	end
	ply.LastFoot = !ply.LastFoot

	local trace = {}
	trace.start = fpos
	trace.endpos = trace.start + Vector(0,0,-10)
	trace.filter = ply
	local tr = util.TraceLine(trace)

	if tr.Hit then

		local tbl = {}
		tbl.pos = tr.HitPos
		tbl.plypos = fpos
		tbl.foot = foot
		tbl.curtime = CurTime()
		tbl.angle = ang.y
		tbl.normal = tr.HitNormal
		local col = ply:GetPlayerColor()
		tbl.col = Color(col.x * 255, col.y * 255, col.z * 255)
		table.insert(FootSteps, tbl)
	end
end

function GM:FootStepsFootstep(ply, pos, foot, sound, volume, filter)

	if ply != LocalPlayer() then return end

	if !self:CanSeeFootsteps() then return end

	self:AddFootstep(ply, pos, ply:GetAimVector():Angle())
end

function GM:CanSeeFootsteps()
	if self:GetAmMurderer() && LocalPlayer():Alive() then return true end
	return false
end

function GM:ClearFootsteps()
	table.Empty(FootSteps)
end

net.Receive("add_footstep", function ()
	local ply = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()

	if !IsValid(ply) then return end

	if ply == LocalPlayer() then return end

	if !GAMEMODE:CanSeeFootsteps() then return end

	GAMEMODE:AddFootstep(ply, pos, ang)
end)

net.Receive("clear_footsteps", function ()
	GAMEMODE:ClearFootsteps()

end)