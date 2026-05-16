-- Network strings
util.AddNetworkString("sv_send_chars")
util.AddNetworkString("cl_get_chars")

-- Stores all our custom characters' data
local charFile = ""
local characters = {}

-- More network stuff
local function updateClient()
    local players = {}
    for _, ply in pairs(player.GetAll()) do
        if ply:IsAdmin() then
            table.insert(players, ply)
        end
    end

    local filesAndChars = {
        files = file.Find("mwcc/charconfigs/*.json", "DATA"),
        characters = GetCustomChars()
    }

    net.Start("sv_send_chars")
    net.WriteString(charFile)
    net.WriteString(util.TableToJSON(filesAndChars))
    net.Send(players)
end

net.Receive("cl_get_chars",  function(len, ply)
    print("server received!")
    if !ply:IsAdmin() then return end

    local filesAndChars = {
        files = file.Find("mwcc/charconfigs/*.json", "DATA"),
        characters = GetCustomChars()
    }

    net.Start("sv_send_chars")
    net.WriteString(charFile)
    net.WriteString(util.TableToJSON(filesAndChars))
    net.Send(ply)
end)

-- Getter, setter, adder, remover, urmommer etc.
function GetCustomChars()
    return characters
end

function SetCustomChar(index, char)
    characters[index] = char
    updateClient()
end

function AddCustomChar(char)
    table.insert(characters, char)
    updateClient()
end

function DeleteCustomChar(index)
    table.remove(characters, index)
    updateClient()
end

-- Save file
function SaveCharsFile(f)
    -- Make sure save directory exists
    if !file.IsDir("mwcc", "DATA") then             file.CreateDir("mwcc") end
    if !file.IsDir("mwcc/charconfigs", "DATA") then file.CreateDir("mwcc/charconfigs") end

    local json = util.TableToJSON(characters)
    local filename = "mwcc/charconfigs/"..f..".json"

    if string.find(filename, ":") then
        return 2, filename    -- means invalid character found
    end

    file.Write(filename, json)
    charFile = f
    updateClient()
    return 0, filename    -- means success
end

-- Load file
function LoadCharsFile(f)
    -- Check if file exists
    local filename = "mwcc/charconfigs/"..f..".json"
    if !file.Exists(filename, "DATA") then 
        return 2, filename    -- means "file not found"
    end

    -- Read file content
    local json = file.Read(filename, "DATA")
    local jsonTable = util.JSONToTable(json)

    -- Check if content structure is valid
    local errors = {}
    if !istable(jsonTable) then
        table.insert(errors, "Content inside file is not a table!")
    else
        for k, v in pairs(jsonTable) do
            -- This must be an array, only numerical keys
            if isstring(k) then
                table.insert(errors, "Table must contain only numerical indexes, found index \""..k.."\"")
                continue
            end

            -- Only tables inside this table
            if !istable(v) then
                table.insert(errors, "Value at index "..k.." is not a table!")
                continue
            end

            -- Name must be a string
            if !isstring(v.name) then
                table.insert(errors, "at index "..k..", \"name\" is not a string!")
            end

            -- Sex must be either "male" or "female"
            if v.sex != "male" and v.sex != "female" then
                table.insert(errors, "at index "..k..", \"sex\" must be either \"male\" or \"female\"!")
            end

            -- Name color must be a vector
            if !isvector(v.nameColor) and v.nameColor != "random" then
                table.insert(errors, "at index "..k..", \"nameColor\" is neither a vector nor \"random\"!")
            end

            -- PM must be a table
            if !istable(v.pm) then
                table.insert(errors, "at index "..k..", \"pm\" is not a table!")
            else
                -- pm.model must be a string
                if !isstring(v.pm.model) then
                    table.insert(errors, "at index "..k..", \"pm.model\" is not a string!")
                end

                -- pm.color must be either a vector or "random"
                if !isvector(v.pm.color) and v.pm.color != "random" then
                    table.insert(errors, "at index "..k..", \"pm.color\" is neither a vector nor \"random\"!")
                end

                -- pm.bodygroups must be a table
                if !istable(v.pm.bodygroups) then
                    table.insert(errors, "at index "..k..", \"pm.bodygroups\" is not a table!")
                else
                    -- all keys inside pm.bodygroups must be numbers
                    for k2, v2 in pairs(v.pm.bodygroups) do
                        if !isnumber(v.pm.bodygroups[k2]) then
                            table.insert(errors, "at index "..k..", \"pm.bodygroups["..k2.."]\" is not a number!")
                        end
                    end
                end
            end
        end
    end

    if #errors > 0 then
        return 3, filename, errors    -- means "failed to load file"
    end

    -- Set characters table
    characters = jsonTable
    charFile = f
    updateClient()
    return 0, filename    -- means "success"
end

-- Load default file on start
hook.Add("Initialize", "InitializeChars", function()
    -- If default file does not exist, load it from data_static and save it
    if !file.Exists("mwcc/charconfigs/default.json", "DATA") then
        -- "what if somethings wrong with the file!!!"
        -- well if it doesnt it means the user messed with the files and fucked it up, thats not my problem
        print("Default char file not found, creating new one...")
        local content = file.Read("data_static/mwcc/default_chars.json", "GAME")
        characters = util.JSONToTable(content)
        SaveCharsFile("default")
    end

    -- If there's a file named after the current map, load that instead
    if file.Exists("mwcc/charconfigs/"..game.GetMap()..".json", "DATA") then
       LoadCharsFile(game.GetMap()) 
    else
       LoadCharsFile("default")        
    end
end)

gameevent.Listen("player_activate")
hook.Add("player_activate", "SendWelcomeChat", function()
    if player.GetCount() == 1 then
        PrintMessage(HUD_PRINTTALK, "Hello and welcome to Murder with Custom Characters! Type \"mwcc_char_panel\" in the console to get started!")
    end
end)

-- Set all players' characters from the table
function SetPlayerCharacters()
    -- Shuffle so if there are not enough custom chars for everyone in the server, 
    -- at least everyone gets to play as one eventually
    local players = player:GetAll()
    local chars = table.Copy(characters)
    table.Shuffle(players)
    table.Shuffle(chars)
    
    for k, ply in ipairs(players) do
        -- Keep default model for this player
        if k > #characters then break end

        local char = chars[k]

        -- Model
        local modelPath = player_manager.TranslatePlayerModel(char.pm.model)
        util.PrecacheModel(modelPath)
        ply:SetModel(modelPath)

        -- Model color
        local modelColor = char.pm.color
        if modelColor == "random" then 
            modelColor = Vector(math.Rand(0,1), math.Rand(0,1), math.Rand(0,1)) 
        end
        ply:SetPlayerColor(modelColor)

        -- Model bodygroups
        local skin = char.pm.bodygroups.Skin
        if skin == nil then skin = 0 end
        ply:SetSkin(skin)

        for i = 0, ply:GetNumBodyGroups()-1 do
            ply:SetBodygroup(i, 0)
        end

        for bname, bvalue in pairs(char.pm.bodygroups) do
            if bname == "Skin" then continue end
            ply:SetBodygroup(ply:FindBodygroupByName(bname), bvalue)
        end

        -- Model hands
        ply:SetupHands()

        -- Name
        ply:SetBystanderName(char.name)

        -- Name color
        local nameColor = char.nameColor
        if nameColor == "random" then
            nameColor = Vector(math.Rand(0,1), math.Rand(0,1), math.Rand(0,1))
        end
        ply:SetNameColor(nameColor)

        -- Sex
        ply.ModelSex = char.sex
    end
end
