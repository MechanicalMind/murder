util.AddNetworkString("chattext_msg")

local meta = {}
meta.__index = meta

function meta:Add(string, color)
	local t = {}
	t.string = string
	t.color = color or color_white
	table.insert(self.msgs, t)
	return self
end

function meta:SendAll()
	self:NetConstructMsg()
	net.Broadcast()
	return self
end

function meta:Send(ply)
	self:NetConstructMsg()
	net.Send(ply)
	return self
end

function meta:NetConstructMsg()
	net.Start("chattext_msg")
	for k, msg in pairs(self.msgs) do
		net.WriteUInt(1,8)
		net.WriteString(msg.string)
		net.WriteVector(Vector(msg.color.r, msg.color.g, msg.color.b))
	end
	net.WriteUInt(0,8)
end

function ChatText()
	local t = {}
	t.msgs = {}
	setmetatable(t, meta)
	return t
end

-- local t = ChatText()
-- t:Add("pants down", Color(255,0,0))
-- t:Add(" pants up")
-- t:SendAll()
