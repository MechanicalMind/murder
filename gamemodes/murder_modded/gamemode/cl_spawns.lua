GM.Spawns = {}

local color_black, color_green = Color(0, 0, 0), Color(0, 150, 0)
function GM:DrawSpawnsVisualise()
	if !self.SpawnsVisualise then return end

	for k, v in pairs(self.Spawns) do
		local pos = v.Pos:ToScreen()
		if pos.visible then
			local size = 8
			draw.RoundedBox(size / 2, pos.x - size / 2, pos.y - size / 2, size, size, color_black) 	
			local size = 6
			draw.RoundedBox(size / 2, pos.x - size / 2, pos.y - size / 2, size, size, color_green) 	
		end
	end
end

local function unnetworkList()
	local exists = {}
	while true do
		local i = net.ReadUInt(32)
		if i == 0 then break end
		local pos = net.ReadVector()
		exists[i] = true
		if !GAMEMODE.Spawns[i] then
			GAMEMODE.Spawns[i] = {}
		end
		GAMEMODE.Spawns[i].Pos = pos
		if !IsValid(GAMEMODE.Spawns[i].Ent) then
			GAMEMODE.Spawns[i].Ent = ClientsideModel("models/editor/playerstart.mdl")
			GAMEMODE.Spawns[i].Ent:SetAngles(Angle(0, math.random(0, 360), 0))
		end
		GAMEMODE.Spawns[i].Ent:SetPos(pos)
	end

	for k, v in pairs(GAMEMODE.Spawns) do
		if !exists[k] then
			if IsValid(v.Ent) then
				v.Ent:Remove()
			end
			GAMEMODE.Spawns[k] = nil
		end
	end
end

net.Receive("Spawns_View", function (len)
	local r = net.ReadUInt(8)
	if r == 0 then
		GAMEMODE.SpawnsVisualise = nil
		for k, v in pairs(GAMEMODE.Spawns) do
			if IsValid(v.Ent) then
				v.Ent:Remove()
			end
			GAMEMODE.Spawns[k] = nil
		end
		return
	end
	GAMEMODE.SpawnsVisualise = net.ReadString()
	unnetworkList()
end)

net.Receive("Spawns_ViewChange", function (len)
	unnetworkList()
end)

