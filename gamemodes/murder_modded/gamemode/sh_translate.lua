// translate

Translator = {}
Translator.languages = {}
Translator.language = "english"

local rootFolder = (GM or GAMEMODE).Folder:sub(11) .. "/gamemode/"

function Translator:LoadLanguage(name, overridePath)
	local tempG = {}
	tempG.pt = {}
	local meta = {}
	meta.__index = _G
	setmetatable(tempG, meta)

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
	return self.language or "english"
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

function Translator:GetEnglishTable()
	if self.languages["english"] then
		return self.languages["english"]
	end
	return def
end

function Translator:ChangeLanguage(lang)
	self.language = lang
	print("Changed language to " .. self:GetLanguage())
	hook.Run("TranslatorOnLanguageChanged", self:GetLanguage())
	GAMEMODE:SetupTeams()


	if SERVER then
		self:NetworkLanguage()
	end
end

local files, dirs = file.Find(rootFolder .. "lang/*", "LUA")
for k, v in pairs(files) do
	AddCSLuaFile(rootFolder .. "lang/" .. v)
	local name = v:sub(1, -5)
	Translator:LoadLanguage(name)
end

if SERVER then
	util.AddNetworkString("translator_language")

	hook.Add("Think", "Translator", function ()
		local lang = GAMEMODE.Language:GetString()

		if lang == "" then lang = "english" end

		if lang != Translator.language then
			Translator:ChangeLanguage(lang)
		end
	end)

	function Translator:NetworkLanguage(ply)
		net.Start("translator_language")
		net.WriteString(self:GetLanguage())
		if ply != nil then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end

	hook.Add("PlayerInitialSpawn", "Translator", function (ply)
		Translator:NetworkLanguage(ply)
	end)
else
	net.Receive("translator_language", function (len)
		local lang = net.ReadString()
		Translator:ChangeLanguage(lang)
	end)
end

function Translator:Translate(languageTable, names)
	for k, name in pairs(names) do
		local a = rawget(languageTable, name)
		if a != nil then
			if type(a) == "function" then
				local ret = a(name)
				if ret != nil then
					return ret
				end
			end
			return a
		end
	end
	local a = rawget(languageTable, "default")
	if a != nil then
		if type(a) == "function" then
			local ret = a(names[1])
			if ret != nil then
				return ret
			end
		end
		return a
	end
end


// translation convience funcitons

// replaces a phrases {variables} with replacements in reptable
function Translator:VarTranslate(s, reptable)
	for k, v in pairs(reptable) do
		s = s:gsub("{" .. k .. "}", v)
	end
	return s
end

function Translator:QuickVar(s, k, v)
	s = s:gsub("{" .. k .. "}", v)
	return s
end

// replaces {variables} with replacements but outputed in a table to allow additional formatting like colors
// used for ChatText(msgs)
function Translator:AdvVarTranslate(phrase, replacements)
	local out = {}
	local s = phrase
	for i = 1, 100 do
		local a, b, c = s:match("([^{]*){([^}]+)}(.*)")
		if a then
			if #a > 0 then
				table.insert(out, {text = a})
			end
			if type(replacements) == "function" then
				local rep = replacements(b)
				table.insert(out, rep or {text = "{" .. b .. "}"})
			else
				local rep = replacements[b] or "{" .. b .. "}"
				local col
				if type(rep) == "function" then
					table.insert(out, rep(b))
				elseif type(rep) == "table" then
					table.insert(out, rep)
				else
					table.insert(out, {text = rep})
				end
			end
			s = c
		end
	end
	if #s > 0 then
		table.insert(out, {text = s})
	end
	return out
end

// the actual translator
local tmeta = {}
local function get(args)
	local a = Translator:Translate(Translator:GetLanguageTable(), args)
	if a != nil then
		return a
	end

	// default to english if we don't have the translation
	local a = Translator:Translate(Translator:GetEnglishTable(), args)
	if a != nil then
		return a
	end
end
local function trans(self, ...)
	local args = {...}
	local a = get(args)
	if a != nil then
		return tostring(a)
	end
	local first = args[1]
	if first then
		return "<" .. tostring(first) .. ">"
	end
	return "<no-trans>"
end
tmeta.__index = trans
tmeta.__call = trans
tmeta.__newindex = function (self, key, value)
	
end

local tablemeta = {}
local function transtable(self, ...)
	local args = {...}
	local a = get(args)
	if type(a) == "table" then
		return a
	end
end
tablemeta.__index = transtable
tablemeta.__call = transtable
tablemeta.__newindex = function (self, key, value)
	
end

translate = {}
translate.table = {}
setmetatable(translate, tmeta)
setmetatable(translate.table, tablemeta)
