
include('shared.lua')

function ENT:Initialize()
	self.Emitter = ParticleEmitter(self:GetPos())
	self.NextPart = CurTime()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	local pos = self:GetPos()
	local client = LocalPlayer()

	if self.NextPart < CurTime() then

		if client:GetPos():Distance(pos) > 1000 then return end

		self.Emitter:SetPos(pos)
		self.NextPart = CurTime() + math.Rand(0, 0.02)
		local vec = VectorRand() * 3
		local pos = self:LocalToWorld(vec)
		local particle = self.Emitter:Add( "particle/snow.vmt", pos)
		particle:SetVelocity(  Vector(0,0, 4) )
		particle:SetDieTime( 7 )
		particle:SetStartAlpha( 140 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 5 )
		particle:SetEndSize( 6 )
		particle:SetRoll( 0 )
		particle:SetRollDelta( 0 )
		particle:SetColor( 0, 0, 0 )
		//particle:SetGravity( Vector( 0, 0, 10 ) )
	end
end

function ENT:OnRemove()
	self.Emitter:Finish()
end