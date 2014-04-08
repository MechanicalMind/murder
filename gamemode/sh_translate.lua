// translate

Translator = {}
Translator.languages = {}

local rootFolder = (GM or GAMEMODE).Folder:sub(11) .. "/gamemode/"

function Translator:LoadLanguage(name, overridePath)
	local tempG = {}
	tempG.pt = {}

	local f = CompileFile(overridePath or (rootFolder .. "lang/" .. name .. ".lua"))
	if !f then
		return
	end
	setfenv(f, tempG)
	local b, err = pcall(f)

	if b then
		Translator.languages[name] = tempG.pt
	else
		MsgC(Color(255, 50, 50), "Loading translation failed " .. name .. "\nError: " .. err .. "\n")
	end
end

function Translator:GetLanguage()
	return "polish"
end

local def = {}
function Translator:GetLanguageTable()
	local lang = self:GetLanguage()
	if self.languages[lang] then
		return self.languages[lang]
	end
	if self.languages["english"] then
		return self.languages["english"]
	end
	return def
end

local files, dirs = file.Find(rootFolder .. "lang/*", "LUA")
for k, v in pairs(files) do
	AddCSLuaFile(rootFolder .. "lang/" .. v)
	local name = v:sub(1, -5)
	Translator:LoadLanguage(name)
end


// translation convience funcitons
function Translator:VarTranslate(name, reptable)
	local s = translate[name]
	for k, v in pairs(reptable) do
		s = s:gsub("{" .. k .. "}", v)
	end
	return s
end

function Translator:QuickVar(name, k, v)
	local s = translate[name]
	s = s:gsub("{" .. k .. "}", v)
	return s
end

// the actual translator
local tmeta = {}
local function trans(self, name)
	local t = Translator:GetLanguageTable()
	local a = rawget(t, name)
	if a != nil then
		if type(a) == "function" then
			return a(name)
		end
		return tostring(a)
	end
	local a = rawget(t, "default")
	if a != nil then
		if type(a) == "function" then
			return a(name)
		end
		return tostring(a)
	end
	return "<no-trans>"
end
tmeta.__index = trans
tmeta.__call = trans
tmeta.__newindex = function (self, key, value)
	
end
translate = {}
setmetatable(translate, tmeta)
