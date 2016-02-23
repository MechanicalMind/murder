
EFFECT.Mat = Material( "effects/tracer_middle" )

--[[---------------------------------------------------------
   Init( data table )
-----------------------------------------------------------]]

local smoke = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016",
}

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()
	
	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self.EndPos = data:GetOrigin()
	
	self.Time = 0.05
	self.LifeTime = RealTime() + self.Time

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )
	
	-- sound.Play( "weapons/explode"..math.random(3,5).. ".wav", pos, 90, 130 )
		
	local emitter = ParticleEmitter((self.StartPos + self.EndPos) / 2) 

	for i = 0, 30 do
	
		local rel = VectorRand() * 52
		local particle = emitter:Add(table.Random(smoke), self.StartPos + VectorRand() * 1)
		particle:SetVelocity(VectorRand() * math.Rand(20, 30) + (self.EndPos - self.StartPos):GetNormal() * math.Rand(0, 650))
		particle:SetDieTime(10)
		particle:SetStartAlpha(50)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(10, 15))
		particle:SetEndSize(math.Rand(70, 90))  
		particle:SetRoll(0)
		particle:SetRollDelta(0)
		particle:SetAirResistance(105)
		local g = math.random(200, 255)
		particle:SetColor(g, g, g)
	end
	
		
	-- 	local particle = emitter:Add( "particles/smokey",pos)
	-- 	particle:SetVelocity( VectorRand() * 60 )
	-- 	particle:SetDieTime( 2.6)
	-- 	particle:SetStartAlpha( 150 )
	-- 	particle:SetEndAlpha( 0 )
	-- 	particle:SetStartSize( 10 )
	-- 	particle:SetEndSize( 70 )   
	-- 	particle:SetRoll( 0 )
	-- 	particle:SetRollDelta( 0 )
	-- 	particle:SetColor( math.random(150,160),150,150 )
	-- end
		
	emitter:Finish()

end

--[[---------------------------------------------------------
   THINK
-----------------------------------------------------------]]
function EFFECT:Think( )	
	return self.LifeTime >= RealTime()
end

--[[---------------------------------------------------------
   Draw the effect
-----------------------------------------------------------]]
function EFFECT:Render()
	local per = (self.LifeTime - RealTime()) / self.Time
	DebugInfo(0, tostring(per))
	
	render.SetMaterial( self.Mat )
	local texcoord = math.Rand( 0, 1 )
	
	local bstartpos = (self.StartPos - self.EndPos) * per + self.EndPos
	local bendpos = bstartpos + (self.StartPos - self.EndPos):GetNormal() * 160
	
	render.DrawBeam(bstartpos, bendpos, 8, 0, 1, Color( 255, 255, 255, 255))

end
