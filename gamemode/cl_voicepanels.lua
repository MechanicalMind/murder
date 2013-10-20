local PANEL = {}
local PlayerVoicePanels = {}

function PANEL:Init()

	self.LabelName = vgui.Create( "DLabel", self )
	self.LabelName:SetFont( "GModNotify" )
	self.LabelName:Dock( FILL )
	self.LabelName:DockMargin( 8, 0, 0, 0 )
	self.LabelName:SetTextColor( Color( 255, 255, 255, 255 ) )

	self.Avatar = vgui.Create( "AvatarImage", self )
	self.Avatar:Dock( LEFT );
	self.Avatar:SetSize( 32, 32 )

	self.ColorBlock = vgui.Create("DPanel", self)
	self.ColorBlock:Dock(LEFT)
	self.ColorBlock:SetSize(32,32)
	function self.ColorBlock:Paint(w, h)
		if IsValid(self.Player) && self.Player:IsPlayer() then
			local col = self.Player:GetPlayerColor()
			surface.SetDrawColor(Color(col.x * 255, col.y * 255, col.z * 255))
			surface.DrawRect(0, 0, w, h)
		end
	end

	self.Color = color_transparent

	self:SetSize( 250, 32 + 8 )
	self:DockPadding( 4, 4, 4, 4 )
	self:DockMargin( 2, 2, 2, 2 )
	self:Dock( BOTTOM )

end

function PANEL:Setup( ply )

	self.ply = ply

	self:CheckBystanderState()	

	self.Avatar:SetPlayer( ply )
	self.ColorBlock.Player = ply
	
	self:InvalidateLayout()

end

function PANEL:CheckBystanderState(state)
	if IsValid(self.ply) then
		local newBystanderState = false
		local client = LocalPlayer()
		if !IsValid(client) then
			newBystanderState = true
		else
			if client:Team() == 2 && client:Alive() then
				newBystanderState = true
			else
				if self.ply:Team() == 2 && self.ply:Alive() then
					newBystanderState = true
				end
			end
		end

		if self.Bystander != newBystanderState then
			self:SetBystanderState(newBystanderState)
		end
		if newBystanderState then
			local col = self.ply:GetPlayerColor()
			if col != self.PrevColor then
				local color = Color(col.x * 255, col.y * 255, col.z * 255)
				self.Color = color
				self.LabelName:SetTextColor(color)
			end
			self.PrevColor = col
		end
	end
end

function PANEL:SetBystanderState(state)
	local col = self.ply:GetPlayerColor()
	local color = Color(col.x * 255, col.y * 255, col.z * 255)
	self.Color = color

	self.Bystander = state
	if state then
		self.LabelName:SetText(self.ply:GetBystanderName())
		self.LabelName:SetTextColor(color)
		self.ColorBlock:SetVisible(true)
		self.Avatar:SetVisible(false)
	else	
		self.LabelName:SetTextColor(color_white)
		self.LabelName:SetText( self.ply:Nick() )
		self.ColorBlock:SetVisible(false)
		self.Avatar:SetVisible(true)
	end
end

function PANEL:Paint( w, h )

	if ( !IsValid( self.ply ) ) then return end
	draw.RoundedBox( 4, 0, 0, w, h, Color( 0, self.ply:VoiceVolume() * 255, 0, 240 ) )

end

function PANEL:Think( )
	self:CheckBystanderState()

	if ( self.fadeAnim ) then
		self.fadeAnim:Run()
	end

end

function PANEL:FadeOut( anim, delta, data )
	
	if ( anim.Finished ) then
	
		if ( IsValid( PlayerVoicePanels[ self.ply ] ) ) then
			PlayerVoicePanels[ self.ply ]:Remove()
			PlayerVoicePanels[ self.ply ] = nil
			return
		end
		
	return end
			
	self:SetAlpha( 255 - (255 * delta) )

end

derma.DefineControl( "VoiceNotifyMurder", "", PANEL, "DPanel" )



function GM:PlayerStartVoice( ply )

	if ( !IsValid( g_VoicePanelList ) ) then return end
	
	-- There'd be an exta one if voice_loopback is on, so remove it.
	GAMEMODE:PlayerEndVoice( ply )


	if ( IsValid( PlayerVoicePanels[ ply ] ) ) then

		if ( PlayerVoicePanels[ ply ].fadeAnim ) then
			PlayerVoicePanels[ ply ].fadeAnim:Stop()
			PlayerVoicePanels[ ply ].fadeAnim = nil
		end

		PlayerVoicePanels[ ply ]:SetAlpha( 255 )

		return;

	end

	if ( !IsValid( ply ) ) then return end

	local pnl = g_VoicePanelList:Add( "VoiceNotifyMurder" )
	pnl:Setup( ply )
	
	PlayerVoicePanels[ ply ] = pnl
	
end


local function VoiceClean()

	for k, v in pairs( PlayerVoicePanels ) do
	
		if ( !IsValid( k ) ) then
			GAMEMODE:PlayerEndVoice( k )
		end
	
	end

end

timer.Create( "VoiceClean", 10, 0, VoiceClean )


function GM:PlayerEndVoice( ply )
	
	if ( IsValid( PlayerVoicePanels[ ply ] ) ) then

		if ( PlayerVoicePanels[ ply ].fadeAnim ) then return end

		PlayerVoicePanels[ ply ].fadeAnim = Derma_Anim( "FadeOut", PlayerVoicePanels[ ply ], PlayerVoicePanels[ ply ].FadeOut )
		PlayerVoicePanels[ ply ].fadeAnim:Start( 2 )

	end
	
end


local function CreateVoiceVGUI()

	g_VoicePanelList = vgui.Create( "DPanel" )

	g_VoicePanelList:ParentToHUD()
	g_VoicePanelList:SetPos( ScrW() - 300, 100 )
	g_VoicePanelList:SetSize( 250, ScrH() - 200 )
	g_VoicePanelList:SetDrawBackground( false )

end

hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )