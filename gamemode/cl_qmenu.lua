local ments

local radialOpen = false
local prevSelected, prevSelectedVertex

function GM:OpenRadialMenu(elements)
	radialOpen = true
	gui.EnableScreenClicker(true)
	ments = elements or {}
	prevSelected = nil
end

function GM:CloseRadialMenu()
	radialOpen = false
	gui.EnableScreenClicker(false)
end

local function getSelected()
	local mx, my = gui.MousePos()
	local sw,sh = ScrW(), ScrH()
	local total = #ments
	local w = math.min(sw * 0.45, sh * 0.45)
	local h = w
	local sx, sy = sw / 2, sh / 2
	local x2,y2 = mx - sx, my - sy
	local ang = 0
	local dis = math.sqrt(x2 ^ 2 + y2 ^ 2)
	if dis / w <= 1 then
		if y2 <= 0 && x2 <= 0 then
			ang = math.acos(x2 / dis)
		elseif x2 > 0 && y2 <= 0 then
			ang = -math.asin(y2 / dis)
		elseif x2 <= 0 && y2 > 0 then
			ang = math.asin(y2 / dis) + math.pi
		else
			ang = math.pi * 2 - math.acos(x2 / dis)
		end
		return math.floor((1 - (ang - math.pi / 2 - math.pi / total) / (math.pi * 2) % 1) * total) + 1
	end
end

function GM:RadialMousePressed(code, vec)
	if radialOpen then
		local selected = getSelected()
		if selected && selected > 0 && code == MOUSE_LEFT then
			if selected && ments[selected] then
				RunConsoleCommand("mu_taunt", ments[selected].Code)
			end
		end
		self:CloseRadialMenu()
	end
end

local elements
local function addElement(name, code, subtitle)
	local t = {}
	t.Name = name
	t.Code = code
	t.Subtitle = subtitle
	table.insert(elements, t)
end

concommand.Add("+menu", function (client, com, args, full)
	if client:Alive() && client:Team() == 2 then
		elements = {}
		addElement("Help", "help", "Yell for help")
		addElement("Apologise", "apologise")
		addElement("Scream", "scream", "Like a little girl")
		addElement("Morose", "morose", "Feel the sadness")
		GAMEMODE:OpenRadialMenu(elements)
	end
end)

concommand.Add("-menu", function (client, com, args, full)
	GAMEMODE:RadialMousePressed(MOUSE_LEFT)
end)

local tex = surface.GetTextureID("VGUI/white.vmt")

local function drawShadow(n,f,x,y,color,pos)
	draw.DrawText(n,f,x + 1,y + 1,color_black,pos)
	draw.DrawText(n,f,x,y,color,pos)
end

local circleVertex

local fontHeight = draw.GetFontHeight("MersRadial")
function GM:DrawRadialMenu()
	if radialOpen then
		local sw,sh = ScrW(), ScrH()
		local total = #ments
		local w = math.min(sw * 0.45, sh * 0.45)
		local h = w
		local sx, sy = sw / 2, sh / 2

		local selected = getSelected() or -1


		if !circleVertex then
			circleVertex = {}
			local max = 50
			for i = 0, max do
				local vx, vy = math.cos((math.pi * 2) * i / max), math.sin((math.pi * 2) * i / max)

				table.insert(circleVertex, {x = sx + w* 1 * vx, y= sy + h* 1 * vy})
			end
		end

		surface.SetTexture(tex)
		surface.SetDrawColor(55,50,55,180)
		surface.DrawPoly(circleVertex)

		local add = math.pi * 1.5 + math.pi / total
		local add2 = math.pi * 1.5 - math.pi / total

		for k,ment in pairs(ments) do
			-- if k > 1 then break end
			local x,y = math.cos((k - 1) / total * math.pi * 2 + math.pi * 1.5), math.sin((k - 1) / total * math.pi * 2 + math.pi * 1.5)

			local lx, ly = math.cos((k - 1) / total * math.pi * 2 + add), math.sin((k - 1) / total * math.pi * 2 + add)

			-- surface.SetDrawColor(225,50,55,120)
			-- surface.DrawLine(sx + lx * w * 0.4, sy + ly * h * 0.4, sx + w * lx, sy + h * ly)

			if selected == k then
				local vertexes = prevSelectedVertex

				if prevSelected != selected then
					prevSelected = selected
					vertexes = {}
					prevSelectedVertex = vertexes
					local lx2, ly2 = math.cos((k - 1) / total * math.pi * 2 + add2), math.sin((k - 1) / total * math.pi * 2 + add2)

					table.insert(vertexes, {x = sx, y = sy})

					-- table.insert(vertexes, {x = sx + w* 0.4 * lx2, y= sy + h* 0.4 * ly2})
					table.insert(vertexes, {x = sx + w* 1 * lx2, y= sy + h* 1 * ly2})

					-- table.insert(vertexes, {x = sx + w* 1 * x, y= sy + h* 1 * y})
					local max = math.floor(50 / total)
					for i = 0, max do
						local addv = (add - add2) * i / max + add2
						local vx, vy = math.cos((k - 1) / total * math.pi * 2 + addv), math.sin((k - 1) / total * math.pi * 2 + addv)

						table.insert(vertexes, {x = sx + w* 1 * vx, y= sy + h* 1 * vy})
					end

					table.insert(vertexes, {x = sx + w* 1 * lx, y= sy + h* 1 * ly})
					-- table.insert(vertexes, {x = sx + w* 0.4 * lx, y= sy + h* 0.4 * ly})

				end

				surface.SetTexture(tex)
				surface.SetDrawColor(25,150,25,180)
				surface.DrawPoly(vertexes)

				-- surface.SetDrawColor(255,0,255,255)
				-- local x,y = vertexes[#vertexes].x,vertexes[#vertexes].y
				-- surface.DrawLine(sx,sy,x,y)

				-- surface.SetDrawColor(50,150,255,255)
				-- for i = 1, #vertexes do
				-- 	local x,y = vertexes[i].x,vertexes[i].y
				-- 	local t = i + 1
				-- 	if i >= #vertexes then t = 1 end
				-- 	local x2,y2 = vertexes[t].x,vertexes[t].y
				-- 	surface.DrawLine(x,y,x2,y2)
				-- end
			end

			drawShadow(ment.Name,"MersRadial",sx + w * 0.6 * x, sy + h * 0.6 * y - fontHeight / 3,color_white,1)
			if ment.Subtitle then
				drawShadow(ment.Subtitle,"MersRadialSmall",sx + w * 0.6 * x, sy + h * 0.6 * y + fontHeight / 2,color_white,1)
			end

			-- surface.SetDrawColor(255,0,255,255)
			-- surface.DrawLine(sx, sy, sx + w* 0.7 * x, sy + h* 0.7 * y)
		end
	end
end

