-- Some hack to print command stuff only if -noprint is not present
local canPrint = true
local function xprint(str)
    if canPrint then print(str) end
end

-- Deals with both -noprint and player admin checks
local function doCommandChecks(ply, args)
    if args[#args] == "-noprint" then   
        canPrint = false
        table.remove(args, #args)
    else                                
        canPrint = true 
    end

    return ply == NULL or ply:IsAdmin()
end

-- Command for saving files
concommand.Add("mwcc_save_chars", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_save_chars: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    local r, filename = SaveCharsFile(args[1])
    if r == 0 then
        xprint("mwcc_save_chars: Successfully saved configs to "..filename.."!")
    elseif r == 2 then
        xprint("mwcc_save_chars: Invalid character \":\" found in filename "..filename.."!")
    end

    return r
end)

-- Command for loading character files
concommand.Add("mwcc_load_chars", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_load_chars: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    if !args[1] then
        xprint("mwcc_load_chars: No file passed!")
        return 3    -- means "failed to load file"
    end

    local r, filename, errors = LoadCharsFile(args[1])
    if r == 0 then
        xprint("mwcc_load_chars: Loaded "..filename.." successfully!")
    elseif r == 2 then
        xprint("mwcc_load_chars: Could not find file "..filename.."!")
    elseif r == 3 then
        for i, e in ipairs(errors) do
            xprint("mwcc_load_chars: "..e)
        end
        xprint("mwcc_load_chars: Failed to load file "..filename.."!")
    end
end)

-- Command for printing characters
concommand.Add("mwcc_print_chars", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_print_chars: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    -- Set tables
    local printTable = {{"INDEX", "NAME", "NAME COLOR", "PLAYERMODEL", "PM COLOR", "SEX"}}
    local columnWidths = {0, 0, 0, 0, 0, 0}
    local function upd()
        for i,v in ipairs(columnWidths) do
            columnWidths[i] = math.max(v, string.len(printTable[#printTable][i]))
        end
    end
    upd()

    -- Add content to print table and update column widths
    local characters = GetCustomChars()
    for i, c in ipairs(characters) do
        local name      = c.name
        local pm        = c.pm.model
        local sex       = c.sex

        local nameColor
        if isvector(c.nameColor) then nameColor = string.sub(c.nameColor.x, 1, 4).." "..string.sub(c.nameColor.y, 1, 4).." "..string.sub(c.nameColor.z, 1, 4)
        else nameColor = c.nameColor end
        
        local pmColor
        if isvector(c.pm.color) then pmColor = string.sub(c.pm.color.x, 1, 4).." "..string.sub(c.pm.color.y, 1, 4).." "..string.sub(c.pm.color.z, 1, 4)
        else pmColor = c.pm.color end

        table.insert(printTable, {i, name, nameColor, pm, pmColor, sex})
        upd()
    end

    -- Print content from table
    for i,v in ipairs(printTable) do
        local output = ""
        for j,w in ipairs(v) do
            output = output..w..string.rep(" ", columnWidths[j] - string.len(w))
            if j != #v then output = output.." | " end
        end
        print(output)
    end

    return 0    -- means success
end)

-- Some helper functions for the mwcc_char_- commands
local function findCharacterByName(n)
    local characters = GetCustomChars()
    for i,v in pairs(characters) do
        if string.lower(v.name) == string.lower(n) then
            return i, v
        end
    end
end

local function findCharacterByIndex(i)
    local characters = GetCustomChars()
    i = tonumber(i)
    return i, characters[i]
end

local function findCharacterFromArgs(args)
    local index, char

    if args[1] then
        if args[1] == "-byname" then
            index, char = findCharacterByName(args[2])
        elseif args[1] == "-byindex" then
            index, char = findCharacterByIndex(args[2])

        -- None of these tags found. If arg is a number, assume it's the index
        elseif tonumber(args[1]) then
            index, char = findCharacterByIndex(args[1])
        
        -- Not a number either, so it must be the name
        else
            index, char = findCharacterByName(args[1])
        end
    else
        return 2    -- means "could not find identifier"
    end

    -- Char not found
    if char == nil then
        return 3    -- means "not found"
    end

    return 0, index, char
end

-- lmk if there's a better way to do this because this just feels criminal for some reason lol
local function getModelBodygroups(name)
    -- Use ragdoll to load model
    local modelPath = player_manager.TranslatePlayerModel(name)
    local ent = ents.Create("prop_ragdoll")
    ent:SetModel(modelPath)

    -- Table to be returned, let's also add model skin
    local r = {}
    if ent:SkinCount() > 1 then
        r.Skin = 0
    end

    -- Add model bodygroups
    local bgs = ent:GetBodyGroups()
    for _, bg in ipairs(bgs) do
        if ent:GetBodygroupCount(bg.id) <= 1 then continue end
        r[bg.name] = 0
    end

    -- Remove entity and return table
    ent:Remove()
    return r
end

-- Command for printing specific character info
concommand.Add("mwcc_char_info", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_char_info: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    -- Get char from identifier
    local r, index, char = findCharacterFromArgs(args)
    if r == 2 then 
        xprint("mwcc_char_info: Must include either the name or the index of the character!")
        return r
    elseif r == 3 then
        xprint("mwcc_char_info: Could not find specified character!")
        return r
    end

    -- Print info
    print("INDEX: "..index)
    print("NAME: "..char.name)

    if isvector(char.nameColor) then
        print("NAME COLOR: "..string.sub(char.nameColor.x, 1, 4).." "..string.sub(char.nameColor.y, 1, 4).." "..string.sub(char.nameColor.z, 1, 4))
    else
        print("NAME COLOR: "..char.nameColor)
    end

    print("PLAYERMODEL: "..char.pm.model)

    if isvector(char.pm.color) then
       print("PM COLOR: "..string.sub(char.pm.color.x, 1, 4).." "..string.sub(char.pm.color.y, 1, 4).." "..string.sub(char.pm.color.z, 1, 4))
    else
        print("PM COLOR: "..char.pm.color)
    end

    print("SEX: "..char.sex)
    print("BODYGROUPS ("..table.Count(char.pm.bodygroups).."):")
    for k,v in pairs(char.pm.bodygroups) do
        print("- "..k..": "..v)
    end

    return 0    -- means "success"
end)

-- Command for editing character info
concommand.Add("mwcc_char_edit", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_char_edit: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    -- Get char from identifier
    local r, index, char = findCharacterFromArgs(args)
    if r == 2 then 
        xprint("mwcc_char_edit: Must include either the name or the index of the character!")
        return r
    elseif r == 3 then
        xprint("mwcc_char_edit: Could not find specified character!")
        return r
    end

    -- Set loop start position
    local start
    if args[1] == "-byname" or args[1] == "-byindex" then
        start = 3
    else
        start = 2
    end

    -- Make a copy of the character to overwrite the original with
    char = table.Copy(char)

    -- Quick func for throwing an error for invalid command
    local function throwInvalid()
        xprint("mwcc_char_edit: Invalid command format!")
        return 4    -- means "invalid format"
    end

    -- Check if there's actually anything after the identifier
    if !args[start] then
        return throwInvalid()
    end

    -- Loop through the rest of command looking for varnames and its values to change to
    local i = start
    while i <= #args do
        local varname = args[i]
        if varname == "-name" then
            char.name = args[i+1]
            i = i+1
        elseif varname == "-namecolor" then
            local r = args[i+1]
            if r == "random" then
                char.nameColor = r
                i = i+1
            else
                r = tonumber(r)
                local g = tonumber(args[i+2])
                local b = tonumber(args[i+3])

                if !r or !g or !b then
                    return throwInvalid()
                end

                r = math.Clamp(r, 0, 1)
                g = math.Clamp(g, 0, 1)
                b = math.Clamp(b, 0, 1)

                char.nameColor = Vector(r, g, b)
                i = i+3
            end
        elseif varname == "-sex" then
            char.sex = args[i+1]
            i = i+1
        elseif varname == "-pm" then
            if char.pm.model != args[i+1] then
                char.pm.model = args[i+1]
                char.pm.bodygroups = getModelBodygroups(char.pm.model)
            end
            i = i+1
        elseif varname == "-pm-color" then
            local r = args[i+1]
            if r == "random" then
                char.pm.color = r
                i = i+1
            else
                r = tonumber(r)
                local g = tonumber(args[i+2])
                local b = tonumber(args[i+3])

                if !r or !g or !b then
                    return throwInvalid()
                end

                r = math.Clamp(r, 0, 1)
                g = math.Clamp(g, 0, 1)
                b = math.Clamp(b, 0, 1)

                char.pm.color = Vector(r, g, b)
                i = i+3
            end
        elseif varname == "-pm-body" then
            for j = i+1, #args, 2 do
                local bgName = string.lower(args[j])
                local bgValue = tonumber(args[j+1])

                local bgNameFirstChar = string.sub(bgName, 1, 1)

                if bgNameFirstChar == "-" then
                    i = j-1
                    break
                elseif tonumber(bgNameFirstChar) or !bgValue then
                    return throwInvalid()
                end

                -- Look for the correct-cased bgName in case there's any difference in letter case
                for bgk, bgv in pairs(char.pm.bodygroups) do
                    if string.lower(bgk) == bgName then
                        bgName = bgk
                        break
                    end
                end

                -- Set bodygroup
                char.pm.bodygroups[bgName] = bgValue

                -- Finished reading whole command
                if j+1 == #args  then
                    i = j+1
                    break
                end
            end
        else
            -- Expected any of these varnames, got none of them. Invalid format
            return throwInvalid()
        end

        i = i+1
    end

    SetCustomChar(index, char)
    xprint("mwcc_char_edit: Changed character info for "..char.name.." successfully!")
end)

-- Command for adding characters
concommand.Add("mwcc_char_add", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_char_add: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    -- Create character w/ default settings and save it to characters
    local char = {
        pm = {
            model = "male01",
            color = Vector(.5, .5, .5),
            bodygroups = {}
        },
        name = "Charlie",
        nameColor = Vector(.5, .5, .5),
        sex = "male"
    }
    AddCustomChar(char)

    -- No more args, wrap up
    if #args == 0 then
        xprint("mwcc_add_char: Added default character successfully!")
        return 0    -- means "success" (tbh i dont know if this'll make a difference in the end, i dont think so)
    end

    -- Run mwcc_char_edit on that character with the rest of the args
    xprint("mwcc_add_char: Added default character, now using \"mwcc_char_edit\" to apply settings.")

    local cmd = "mwcc_char_edit -byindex "..#GetCustomChars().." "
    for _, arg in ipairs(args) do
        if string.find(arg, " ") then arg = "\""..arg.."\"" end
        cmd = cmd..arg.." "
    end
    if !canPrint then cmd = cmd.."-noprint" end

    ply:ConCommand(cmd)
    return 0
end)

-- Command for deleting characters
concommand.Add("mwcc_char_delete", function(ply, cmd, args)
    -- Do command checks
    if !doCommandChecks(ply, args) then
        xprint("mwcc_char_delete: Only admins can run this command!")
        return 1    -- means "no permission"
    end

    -- Get char from identifier
    local r, index, char = findCharacterFromArgs(args)
    if r == 2 then 
        xprint("mwcc_char_delete: Must include either the name or the index of the character!")
        return r
    elseif r == 3 then
        xprint("mwcc_char_delete: Could not find specified character!")
        return r
    end

    -- Delete character
    DeleteCustomChar(index)
    xprint("mwcc_char_delete: Character "..char.name.." deleted successfully!")
end)
