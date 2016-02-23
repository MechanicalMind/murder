
local mat_Copy		= Material( "pp/copy" )
local mat_Add		= Material( "pp/add" )
local mat_Sub		= Material( "pp/sub" )
local rt_Store		= render.GetScreenEffectTexture( 0 )
local rt_Blur		= render.GetScreenEffectTexture( 1 )

local List = {}

local function Add( ents, colors, blurx, blury, passes, add, ignorez )

	if ( add == nil ) then add = true end
	if ( ignorez == nil ) then ignorez = false end

	local t =
	{
		Ents = ents,
		Colors = colors,
		Hidden = when_hidden,
		BlurX = blurx or 2,
		BlurY = blury or 2,
		DrawPasses = passes or 1,
		Additive = add,
		IgnoreZ = ignorez
	}

	table.insert( List, t )

end
local function Render( entry )
	render.SuppressEngineLighting(true)
	local rt_Scene = render.GetRenderTarget()


	-- Store a copy of the original scene
	render.CopyRenderTargetToTexture( rt_Store )


	-- Clear our scene so that additive/subtractive rendering with it will work later
	if ( entry.Additive ) then
		render.Clear( 0, 0, 0, 255, false, true )
	else
		render.Clear( 255, 255, 255, 255, false, true )
	end


	-- Render colored props to the scene and set their pixels high
	cam.Start3D()
	render.SetStencilEnable( true )
	cam.IgnoreZ( entry.IgnoreZ )

	render.SetStencilWriteMask( 255 )
	render.SetStencilTestMask( 255 )
	render.SetStencilReferenceValue( 1 )

	render.SetStencilCompareFunction( STENCIL_ALWAYS )
	render.SetStencilPassOperation( STENCIL_REPLACE )
	render.SetStencilFailOperation( STENCIL_KEEP )
	render.SetStencilZFailOperation( STENCIL_KEEP )

	for k, v in pairs( entry.Ents ) do
		if IsValid( v.ent ) then
			render.SetStencilReferenceValue(2 ^ (v.color - 1))
			v.ent:DrawModel()
		end
	end
	cam.IgnoreZ( false )
	cam.End3D()

	render.SetStencilCompareFunction( STENCIL_EQUAL )
	render.SetStencilPassOperation( STENCIL_KEEP )

	for k,v in pairs(entry.Colors) do
		render.SetStencilReferenceValue(2 ^ (k - 1))
		cam.Start2D()
		surface.SetDrawColor( v)
		surface.DrawRect( 0, 0, ScrW(), ScrH() )
		cam.End2D()
	end

	render.SetStencilEnable( false )


	-- Store a blurred version of the colored props in an RT
	render.CopyRenderTargetToTexture( rt_Blur )
	render.BlurRenderTarget( rt_Blur, entry.BlurX, entry.BlurY, 1 )


	-- Restore the original scene
	render.SetRenderTarget( rt_Scene )
	mat_Copy:SetTexture( "$basetexture", rt_Store )
	render.SetMaterial( mat_Copy )
	render.DrawScreenQuad()


	-- Draw back our blured colored props additively/subtractively
	render.SetStencilReferenceValue( 0 )
	render.SetStencilTestMask( 255 )
	render.SetStencilEnable( true )

		render.SetStencilCompareFunction( STENCIL_EQUAL )

			if ( entry.Additive ) then

				mat_Add:SetTexture( "$basetexture", rt_Blur )
				render.SetMaterial( mat_Add )

			else

				mat_Sub:SetTexture( "$basetexture", rt_Blur )
				render.SetMaterial( mat_Sub )

			end

			for i = 0, entry.DrawPasses do

				render.DrawScreenQuad()

			end

	render.SetStencilEnable( false )


	-- Return original values
	render.SetStencilTestMask( 0 )
	render.SetStencilWriteMask( 0 )
	render.SetStencilReferenceValue( 0 )
	render.SuppressEngineLighting(false)
end

hook.Add( "PostDrawEffects", "RenderMurderHalos", function()

	hook.Run( "PreDrawMurderHalos", Add)

	if ( #List == 0 ) then return end
	
	local a = SysTime()
	for k, v in ipairs( List ) do
		Render( v )
	end

	List = {}

end )

-- hook.Add( "PreDrawMurderHalos", "abc", function (Add)
-- 	local t = {}
-- 	for k,v in pairs(ents.GetAll()) do
-- 		local entry = {}
-- 		entry.ent = v
-- 		entry.color = v:EntIndex() % 3
-- 		table.insert(t, entry)
-- 	end
-- 	Add(t, {Color(220, 0, 0), Color(0,220,0), Color(0,0,255)}, 5, 5, 5, true, false)
-- end)