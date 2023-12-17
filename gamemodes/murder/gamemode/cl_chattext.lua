net.Receive("chattext_msg", function (len)
	local msgs = {}
	while true do
		local i = net.ReadUInt(8)
		if i == 0 then break end
		local str = net.ReadString()
		local col = net.ReadVector()
		table.insert(msgs, Color(col.x, col.y, col.z))
		table.insert(msgs, str)
	end

	chat.AddText(unpack(msgs))
end)

net.Receive("msg_clients", function (len)
	local lines = {}
	while net.ReadUInt(8) != 0 do
		local r = net.ReadUInt(8)
		local g = net.ReadUInt(8)
		local b = net.ReadUInt(8)
		local text = net.ReadString()
		table.insert(lines, {color = Color(r, g, b), text = text})
	end
	for k, line in pairs(lines) do
		MsgC(line.color, line.text)
	end
end)