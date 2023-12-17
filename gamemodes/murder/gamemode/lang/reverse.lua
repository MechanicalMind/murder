pt.default = function (n)
	local a = Translator:Translate(Translator:GetEnglishTable(), {n})
	if type(a) != "string" then
		return tostring(n)
	end

	local sleft, mid, sright = a:match("^([%s]*)(.*)([%s]*)$")
	local first = true
	local words = ""
	for word in mid:gmatch("[^%s]+") do
		if word:find("[{}]") then

		else
			local cap = word:sub(1, 1):match("[A-Z]")
			word = word:lower():reverse()
			if cap then
				word = word:sub(1, 1):upper() .. word:sub(2)
			end
		end
		if first then
			words = words .. word
			first = false
		else
			words = words .. " " .. word
		end
	end
	return sleft .. words .. sright
end
