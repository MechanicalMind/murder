
local WRandom = {}
WRandom.__index = WRandom

function WeightedRandom()
	local tab = {}
	tab.items = {}
	setmetatable(tab, WRandom)
	return tab
end

function WRandom:Add(weight, item)
	local t = {}
	t.weight = weight
	t.item = item
	table.insert(self.items, t)
end

function WRandom:Roll()
	local total = 0
	for k, item in pairs(self.items) do
		total = total + item.weight
	end
	local c = math.random(total - 1)
	local cur = 0
	for k, item in pairs(self.items) do
		cur = cur + item.weight
		if c < cur then
			return item.item
		end
	end
end

-- local murds = WeightedRandom()
-- murds:Add(1 ^ 3, "jim")
-- murds:Add(3 ^ 3, "john")
-- murds:Add(6 ^ 3, "peter")

-- local tab = {}
-- for i = 0, 1000 do
-- 	local p = murds:Roll()
-- 	tab[p] = (tab[p] or 0) + 1
-- end
-- for k,v in pairs(tab) do
-- 	print(k, math.Round(v / 1000 * 10))
-- end
