

local function getFootstepSound()
	// random number from 1-6 or 8
	local i = math.random(1, 7)
	if i == 7 then i = 8 end
	return "npc/footsteps/hardboot_generic" .. i .. ".wav"
end

local function getFilter(ply)
	local tbl = {ply}
	table.Add(tbl, ents.FindByClass("th_loot"))
	return tbl
end

local LedgeGrabMaxHeight = 98

local WallClimbUpForce = 51
local WallRunUpForce = 37
local WallRunForwardForce = 19

local SoundLevel = 40

function GM:ParkourThink()
 	for k, ply in pairs(player.GetAll()) do
 		if !ply.LedgeGrab then ply.LedgeGrab = {} end
 		if !ply.WallClimb then ply.WallClimb = {} end
 		if !ply.Breathe then ply.Breathe = {} end

 		if ply:Alive() then
 			if ply.LedgeGrab.Grabbing then
 				if CurTime() - ply.LedgeGrab.StageTime > 2 then
 					ply.LedgeGrab.Grabbing = false
 					ply.LedgeGrab.Stage = -1
 				end
	 			if ply.LedgeGrab.Stage == 0 then
	 				local dest = ply.LedgeGrab.BodyHit * 1
	 				dest.z = ply.LedgeGrab.Down.z + 10
	 				local aim = (dest - ply:GetPos())
	 				local len2d = aim:Length2D()
	 				local len = aim:Length()
	 				aim:Normalize()

	 				local vel = aim * math.min(80, len)
	 				if len2d < 4 then
	 					ply:SetMoveType(MOVETYPE_NONE)
	 				end
	 				ply:SetLocalVelocity(vel)

	 				if ply.LedgeGrab.StageTime + 0.3 < CurTime() then
						ply.LedgeGrab.Stage = 1
						ply.LedgeGrab.StageTime = CurTime()
				 		ply:SetMoveType(MOVETYPE_WALK)
				 		ply:EmitSound("npc/zombie/foot_slide3.wav", SoundLevel)
				 		ply.LedgeGrab.Foot = CurTime()
				 		ply:EmitSound(getFootstepSound(), SoundLevel)
	 				end

	 			elseif ply.LedgeGrab.Stage == 1 then
	 				local dest = ply.LedgeGrab.BodyHit * 1
	 				dest.z = ply.LedgeGrab.Down.z + 5
	 				local aim = (dest - ply:GetPos())
	 				local len = aim:Length()
	 				local lenz = math.abs(aim.z)
	 				aim:Normalize()

	 				ply:SetLocalVelocity(aim * 250)

				 	if ply.LedgeGrab.Foot + 0.2 < CurTime() then
				 		ply:EmitSound(getFootstepSound(), SoundLevel)
				 		ply.LedgeGrab.Foot = CurTime()
				 	end

	 				if ply:GetPos().z >= ply.LedgeGrab.Down.z + 2 then
	 					ply.LedgeGrab.Grabbing = false
	 					ply.LedgeGrab.Cooldown = CurTime()
	 					local vel = ply.LedgeGrab.Normal * -80
	 					ply:SetLocalVelocity(vel)
	 				end
	 			end
	 		else
	 			if !ply:OnGround() && !ply:Crouching() && ply:WaterLevel() == 0 then
		 			if ply:CanParkour("LedgeGrab") && ply:KeyDown(IN_JUMP) then
		 				// body trace must hit
		 				// head ray trace must miss

		 				// up trace
		 				local trace3 = {}
		 				trace3.start = ply:GetPos()
		 				trace3.endpos = trace3.start + Vector(0,0,LedgeGrabMaxHeight)
		 				trace3.filter = getFilter(ply)
		 				local trUp = util.TraceEntity(trace3, ply)
		 				local ceiling = trace3.endpos
		 				if trUp.Hit then
		 					ceiling = trUp.HitPos - Vector(0,0,2)
		 				end

		 				local dir = ply:GetAimVector()
		 				dir.z = 0
		 				dir:Normalize()

		 				// body trace
		 				local trace = {}
		 				trace.start = trace3.start
		 				trace.endpos = trace.start + dir * 10
		 				trace.filter = getFilter(ply)
		 				local trBody = util.TraceEntity(trace, ply)
		 				local dot = trBody.HitNormal:Dot(dir)

			 			ply.WallClimb.Time = ply.WallClimb.Time or 0

			 			/****************
			 			**** wall climb
			 			****************/

		 				if trBody.Hit && dot < -0.7 then

		 					if dot < -0.90 then
				 				// head trace
				 				local trace2 = {}
				 				trace2.start = ceiling
				 				trace2.endpos = trace2.start + trBody.HitNormal * -10
				 				trace2.filter = getFilter(ply)
				 				local trHead = util.TraceEntity(trace2, ply)

				 				if !trHead.Hit && (!ply.LedgeGrab.Cooldown || ply.LedgeGrab.Cooldown + 1 < CurTime()) then
				 					local trace4 = {}
				 					trace4.start = trace2.endpos
				 					trace4.endpos = trace2.endpos - Vector(0,0,LedgeGrabMaxHeight)
				 					trace4.filter = getFilter(ply)
				 					local trDown = util.TraceEntity(trace4, ply)
				 					local height = trDown.HitPos.z - trace3.start.z

				 					if height > 52 then
					 					ply.LedgeGrab.Grabbing = true
					 					ply.LedgeGrab.Up = trace3.endpos
					 					ply.LedgeGrab.Down = trDown.HitPos
					 					ply.LedgeGrab.Normal = trBody.HitNormal
					 					ply.LedgeGrab.BodyHit = trBody.HitPos
					 					ply.LedgeGrab.Dir = dir
					 					ply.LedgeGrab.Stage = 0
					 					ply.LedgeGrab.StageTime = CurTime()
										ply.LedgeGrab.StartTime = CurTime()
					 					ply:EmitSound("npc/footsteps/softshoe_generic6.wav", SoundLevel)
					 					ply:EmitSound("npc/headcrab_poison/ph_wallhit2.wav", SoundLevel)
					 					-- PrintTable(ply.LedgeGrab)
					 					-- ply:SetMoveType(MOVETYPE_NONE)
					 				end
				 				end
				 			end

			 				if !ply.LedgeGrab.Grabbing then
			 					local z = ply:GetVelocity().z
			 					if z > -80 then
			 						if ply.WallClimb.Time + 0.2 < CurTime() then
			 							ply.WallClimb.Time = CurTime()
				 						ply:EmitSound(getFootstepSound(), SoundLevel)
				 						ply:SetVelocity(Vector(0,0, WallClimbUpForce))

			 						end
			 					end
			 				end
			 			end

			 			/****************
			 			**** wall run
			 			****************/
			 			if !ply.LedgeGrab.Grabbing then
		 					local z = ply:GetVelocity().z
		 					local speed = ply:GetVelocity():Length()
		 					if z > -120 && speed > 100 then
		 						if ply.WallClimb.Time + 0.2 < CurTime() then
									// body trace right
									local trace = {}
									trace.start = ply:GetPos()
									trace.endpos = trace.start + ply:GetRight() * 10
									trace.filter = getFilter(ply)
									local trBody = util.TraceEntity(trace, ply)
									local dot = trBody.HitNormal:Dot(ply:GetRight())

									if trBody.Hit && dot < -0.7 then
										ply.WallClimb.Time = CurTime()
				 						ply:EmitSound("npc/footsteps/hardboot_generic" .. math.random(1,8) .. ".wav", SoundLevel)

					 					// move the player forward (parallel to wall) and up
				 						local vel = Vector(0,0,WallRunUpForce)
				 						local vec = trBody.HitNormal * 1
				 						vec:Rotate(Angle(0,-93,0))
				 						vel = vel + vec * WallRunForwardForce
				 						ply:SetVelocity(vel)
				 					else
				 						// body trace left
										trace.endpos = trace.start + ply:GetRight() * -10
										local trBody = util.TraceEntity(trace, ply)
										local dot = trBody.HitNormal:Dot(ply:GetRight())
										if trBody.Hit && dot > 0.7 then
											ply.WallClimb.Time = CurTime()
					 						ply:EmitSound("npc/footsteps/hardboot_generic" .. math.random(1,8) .. ".wav", SoundLevel)

					 						// move the player forward (parallel to wall) and up
					 						local vel = Vector(0,0,WallRunUpForce) 
					 						local vec = trBody.HitNormal * 1
					 						vec:Rotate(Angle(0,93,0))
					 						vel = vel + vec * WallRunForwardForce
					 						ply:SetVelocity(vel)
					 					end
				 					end

		 						end
		 					end
		 				end
		 			end
		 		end
	 		end
			local running = ply:GetVelocity():LengthSqr() > 1
			local onground = ply:OnGround()
			local hp = ply:Health()

			// recharge health
			if onground && !running && hp >= 70 && hp < 100 then
				if !ply.Breathe.sound then
					ply.Breathe.sound = CreateSound( ply, "player/breathe1.wav" )
				end
				-- DebugInfo(2, "Breathing " .. CurTime())
				if ply.Breathe.sound then
					if !ply.Breathe.sound:IsPlaying() then
						ply.Breathe.sound:Play()
					end
				end

				if (ply.LastHealthRevive or 0) < CurTime() then
					if !ply.HitLastCharge || ply.HitLastCharge < CurTime() then
						ply.HealthSpeedBuildup = ply.HealthSpeedBuildup or 0
						if ply.HealthSpeedBuildup < 14 then
							ply.HealthSpeedBuildup = ply.HealthSpeedBuildup + 1
						end

						local canrevive = true
						if canrevive then
							ply:SetHealth( math.Clamp( hp + 1, 0, 100 ) )
							ply.LastHealthRevive = CurTime() + 1.4 //- (ply.HealthSpeedBuildup / 14)
						end
					end
				end
			else
				ply.LastHealthRevive = CurTime() + 1
				ply.HealthSpeedBuildup = 0
				if ply.Breathe.sound then
					if ply.Breathe.sound:IsPlaying() then
						ply.Breathe.sound:Stop()
					end
				end
			end

			// don't increase velocity when jumping off ground
			if ply:KeyPressed(IN_JUMP) && ply.PrevOnGround then
				ply.LastJump = CurTime()

				local curVel = ply:GetVelocity()
				local newVel = ply.PrevSpeed * 1
				newVel.z = curVel.z
				ply:SetLocalVelocity(newVel)
			end
			ply.PrevSpeed = ply:GetVelocity()
			ply.PrevOnGround = ply:OnGround()
		end
	end
end

// minimum velocity to trigger function is 530
function GM:GetFallDamage( ply, vel )
	local minvel = vel - 600
	local dmg = math.ceil(minvel / 278 * 50)
	-- local dmg = math.Round(vel * (100 / (1024 - 530)))
	return dmg
end