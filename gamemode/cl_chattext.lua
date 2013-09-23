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