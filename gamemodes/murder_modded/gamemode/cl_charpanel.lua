local CSEntMeta = FindMetaTable("CSEnt")

local c_black = Color(0, 0, 0, 255) -- because

-- I hope nothing wrong happens with this
function CSEntMeta:GetPlayerColor()
    return self.playerColor or Vector()
end

local charFile = ""
local files = {}
local characters = {}

local panel

local function setCurrentChar(i)
    panel.charIndex = i

    if i == 0 then
        panel.charModel:Hide()
        panel.charProperties:GetParent():Hide()
        return
    end

    panel.charModel:Show()
    panel.charProperties:GetParent():Show()

    -- Model
    local char = characters[i]
    if !char then
        if #characters < 1 then
            setCurrentChar(0)
        else
            setCurrentChar(1)
        end
        return
    end

    panel.charModel:SetModel(player_manager.TranslatePlayerModel(char.pm.model))
    
    -- Name
    panel.charProperties.name:SetValue(char.name)

    -- Name color
    if char.nameColor == "random" then
        panel.charProperties.nameColorRandom:SetChecked(true)
        panel.charProperties.nameColor:SetEnabled(false)
        panel.charProperties.nameColor.color = Color(0, 0, 0, 255)
    else
        panel.charProperties.nameColorRandom:SetChecked(false)
        panel.charProperties.nameColor:SetEnabled(true)
        panel.charProperties.nameColor.color = 
            Color(char.nameColor.x*255, char.nameColor.y*255, char.nameColor.z*255)
    end

    -- Sex
    if char.sex == "male" then
        panel.charProperties.sexMale:SetToggle(true)
        panel.charProperties.sexFemale:SetToggle(false)
    elseif char.sex == "female" then
        panel.charProperties.sexMale:SetToggle(false)
        panel.charProperties.sexFemale:SetToggle(true)
    end

    -- Playermodel
    panel.charProperties.playermodel:SetText(char.pm.model)

    -- PM color
    if char.pm.color == "random" then
        panel.charProperties.pmColorRandom:SetChecked(true)
        panel.charProperties.pmColor:SetEnabled(false)
        panel.charProperties.pmColor.color = Color(0, 0, 0, 255)

        panel.charModel:GetEntity().playerColor = Vector()
    else
        panel.charProperties.pmColorRandom:SetChecked(false)
        panel.charProperties.pmColor:SetEnabled(true)
        panel.charProperties.pmColor.color = 
            Color(char.pm.color.x*255, char.pm.color.y*255, char.pm.color.z*255)

        panel.charModel:GetEntity().playerColor = char.pm.color
    end

    -- Bodygroups
    for _, v in pairs(panel.charProperties.bodygroups) do
        v:Remove()
    end
    panel.charProperties.bodygroups = {}

    -- TODO when chars are updated, bodygroup sliders order may end up changing. gotta fix that
    for bgName, bgValue in pairs(char.pm.bodygroups) do
        local inputBG = panel.charProperties:NumSlider(bgName:gsub("^%l", string.upper), nil, 0, 4, 0)
        inputBG:Dock(FILL)
        inputBG:SetValue(0)

        if bgName == "Skin" then
            inputBG:SetMax(panel.charModel:GetEntity():SkinCount() - 1)
            inputBG:SetValue(bgValue)
            inputBG.OnValueChanged = function(self, v)
                panel.charModel:GetEntity():SetSkin(v)
            end
            panel.charModel:GetEntity():SetSkin(bgValue)
        else
            local bgId = panel.charModel:GetEntity():FindBodygroupByName(bgName)
            inputBG:SetMax(panel.charModel:GetEntity():GetBodygroupCount(bgId) - 1)
            inputBG:SetValue(bgValue)
            inputBG.OnValueChanged = function(self, v)
                panel.charModel:GetEntity():SetBodygroup(bgId, v)
            end
            panel.charModel:GetEntity():SetBodygroup(bgId, bgValue)
        end

        inputBG.dragging = false
        inputBG.MouseReleased = function(self)
            RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex,
                "-pm-body", bgName, self:GetValue(), "-noprint")
        end
        inputBG.Think = function(self)
            if self:IsEditing() and !self.dragging then
                self.dragging = true
            elseif !self:IsEditing() and self.dragging then
                self.dragging = false
                self:MouseReleased(self)
            end
        end

        panel.charProperties.bodygroups[bgName] = inputBG
    end

    -- Delete button
    panel.charProperties.delete:Remove()

    local btnDelete = panel.charProperties:Button("Delete character")
    btnDelete.DoClick = function()
        RunConsoleCommand("mwcc_char_delete", "-byindex", panel.charIndex, "-noprint")
    end
    panel.charProperties.delete = btnDelete
end

local function updateChars()
    if !IsValid(panel) then return end

    -- Update files
    panel.file.name:SetValue(charFile)

    panel.file.nameDrop:Clear()
    for _, f in ipairs(files) do
        panel.file.nameDrop:AddChoice(string.sub(f, 1, string.len(f)-5))
    end

    -- Update characters
    panel.charPick:Clear()

    for i, char in ipairs(characters) do
        local btn = panel.charPick:Add("SpawnIcon")
        btn:SetModel(player_manager.TranslatePlayerModel(char.pm.model))
        btn:SetTooltip(char.name)
        btn:SetTooltipDelay(0)
        btn:Dock(TOP)
        btn.DoClick = function()
            setCurrentChar(i)
        end
    end

    local btnAdd = panel.charPick:Add("DButton")
    btnAdd:Dock(TOP)
    btnAdd:SetSize(64, 64)
    btnAdd:SetText("NEW")
    btnAdd.justClicked = false
    btnAdd.DoClick = function()
        panel.charPick.justAddedChar = true
        RunConsoleCommand("mwcc_char_add", "-noprint")
    end

    if panel.charPick.justAddedChar then
        panel.charPick.justAddedChar = false
        setCurrentChar(#characters)
    else
        setCurrentChar(panel.charIndex)
    end
end

net.Receive("sv_send_chars", function()
    charFile = net.ReadString()

    local filesAndChars = util.JSONToTable(net.ReadString())
    files = filesAndChars.files
    characters = filesAndChars.characters
    updateChars()
end)

local function fileMessage(txt)
    panel.file.msg:SetText(txt)
    panel.file.msg:SetColor(Color(0, 0, 0, 255))
end

local function fileError(txt)
    panel.file.msg:SetText(txt)
    panel.file.msg:SetColor(Color(255, 0, 0, 255))
end

local function fileHide()
    panel.file.msg:SetText("")
end

concommand.Add("mwcc_char_panel", function(ply)
    if IsValid(panel) then
        
    else
        -- Send character request
        net.Start("cl_get_chars")
        net.SendToServer()

        -- Main panel
        panel = vgui.Create("DFrame")
        panel:MakePopup()
        panel:SetSize(600, 400)
        panel:Center()
        panel:SetTitle("Character Config")

        panel.charIndex = 1

        -- File select panel
        local filePanel = panel:Add("DPanel")
        filePanel:Dock(TOP)
        filePanel:SetBackgroundColor(Color(0, 0, 0, 0))

        local fileText = filePanel:Add("DLabel")
        fileText:Dock(LEFT)
        fileText:SetText("File:")
        fileText:SizeToContentsX()
        fileText:DockMargin(0, 0, 10, 0)

        local fileNameDrop = filePanel:Add("DComboBox")
        fileNameDrop:Dock(LEFT)
        fileNameDrop:SetWide(200)
        fileNameDrop.OnSelect = function(self, index, value)
            panel.file.name:SetValue(value)
        end

        filePanel.nameDrop = fileNameDrop

        local fileName = fileNameDrop:Add("DTextEntry")
        local w, h = fileNameDrop:GetSize()
        fileName:SetSize(w-20, h+1)
        fileName.OnGetFocus = function()
            panel.file.nameDrop:CloseMenu()
        end
        
        filePanel.name = fileName

        local fileSave = filePanel:Add("DButton")
        fileSave:Dock(LEFT)
        fileSave:SetText("Save")
        fileSave.DoClick = function()
            local name = fileName:GetText()
            if string.len(name) == 0 then 
                fileError("Can't save an unnamed file!")
                return
            end
            fileHide()
            RunConsoleCommand("mwcc_save_chars", fileName:GetText(), "-noprint")
        end

        local fileLoad = filePanel:Add("DButton")
        fileLoad:Dock(LEFT)
        fileLoad:SetText("Load")
        fileLoad.DoClick = function()
            RunConsoleCommand("mwcc_load_chars", fileName:GetText(), "-noprint")
        end

        local fileMsg = filePanel:Add("DLabel")
        fileMsg:Dock(FILL)
        fileMsg:DockMargin(10, 0, 0, 0)
        fileMsg:SetText("")

        filePanel.msg = fileMsg

        panel.file = filePanel

        -- Character selector on the left
        local charPick = panel:Add("DScrollPanel")
        charPick:Dock(LEFT)
        charPick:SetMinimumSize(charPick:GetWide() + charPick:GetVBar():GetWide(), charPick:GetTall())
        charPick:SetBackgroundColor(Color(255, 0, 0, 255))
        charPick.justAddedChar = false

        for i = 1, 10 do
            local btn = charPick:Add("SpawnIcon")
            btn:Dock(TOP)
        end

        panel.charPick = charPick

        -- Character model preview in the middle
        local charModel = panel:Add("DModelPanel")
        charModel:Dock(FILL)
        charModel:SetModel(player_manager.TranslatePlayerModel("male01"))
        charModel:SetAnimated(true)
        charModel.PaintOver = function()
            local x, y = charModel:GetSize()
            x = x/2
            y = y/2 + 30

            local a = panel.charProperties.nameColor.color.a
            panel.charProperties.nameColor.color.a = 255

            draw.SimpleText(panel.charProperties.name:GetText(), "MersRadial", 
                x+1, y+1, c_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(panel.charProperties.name:GetText(), "MersRadial", 
                x, y, panel.charProperties.nameColor.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            panel.charProperties.nameColor.color.a = a
        end

        charModel.pressed = false
        charModel.pressX = 0
        charModel.pressY = 0
        charModel.DragMousePress = function(self)
            self.pressX, self.pressY = input.GetCursorPos()
            self.pressed = true
        end
        charModel.DragMouseRelease = function(self)
            self.pressed = false
        end
        charModel.LayoutEntity = function(self, ent)
            if self.pressed then
                local mx, my = input.GetCursorPos()
                local angles = ent:GetAngles() - Angle(0, self.pressX - mx, 0)
                ent:SetAngles(angles)
                self.pressX, self.pressY = mx, my
            end
        end
        
        panel.charModel = charModel

        -- Character settings on the right
        local charScrollWrapper = panel:Add("DScrollPanel")
        charScrollWrapper:Dock(RIGHT)
        charScrollWrapper:SetWide(250)

        local charProperties = charScrollWrapper:Add("DForm")
        charProperties:Dock(FILL)
        charProperties:SetLabel("Character settings")

        panel.charProperties = charProperties

        --  Name
        local inputName = charProperties:TextEntry("Name:")
        inputName.OnLoseFocus = function()
            RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-name", inputName:GetText(), "-noprint")
        end

        charProperties.name = inputName
        
        -- Name color
        local inputNCLeft = vgui.Create("DLabel")
        inputNCLeft:SetText("Name color:")

        local inputNCRight = vgui.Create("DPanel")
        inputNCRight:Dock(FILL)
        inputNCRight:SetBackgroundColor(Color(0, 0, 0, 0))

        local inputNCRandom = inputNCRight:Add("DCheckBoxLabel")
        local inputNCButton = inputNCRight:Add("DButton")

        inputNCRandom:Dock(LEFT)
        inputNCRandom:SetText("Random")
        inputNCRandom.OnChange = function()
            inputNCButton:SetEnabled(!inputNCRandom:GetChecked())

            if inputNCRandom:GetChecked() then
                RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-namecolor", "random", "-noprint")
            else
                RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-namecolor", 
                    inputNCButton.color.r/255, inputNCButton.color.g/255, inputNCButton.color.b/255, "-noprint")
            end
        end
        
        inputNCButton:SetWide(25)
        inputNCButton:Dock(RIGHT)
        inputNCButton:SetText("")
        inputNCButton.color = Color(0, 0, 0, 255)
        inputNCButton.PaintOver = function()
            if !inputNCButton:IsEnabled() then  inputNCButton.color.a = 127 
            else                                inputNCButton.color.a = 255 end
            draw.RoundedBox(0, 3, 3, inputNCButton:GetWide()-6, inputNCButton:GetTall()-6, inputNCButton.color)
        end

        inputNCButton.DoClick = function()
            local colorWindow = vgui.Create("DPanel")
            colorWindow:SetSize(250, 200)
            colorWindow:MakePopup()

            local mx, my = input.GetCursorPos()
            mx = math.Clamp(mx, 0, ScrW() - colorWindow:GetWide())
            my = math.Clamp(my, 0, ScrH() - colorWindow:GetTall())
            colorWindow:SetPos(mx, my)

            local color = colorWindow:Add("DColorMixer")
            color:Dock(FILL)
            color:SetAlphaBar(false)
            color:SetPalette(false)
            color:SetColor(inputNCButton.color)
            color.ValueChanged = function(color)
                color.ValueChanged = function(color)
                    local c = color:GetColor()
                    panel.charProperties.nameColor.color = c
                end
            end

            colorWindow.OnFocusChanged = function(focus)
                -- According to the wiki, focus was supposed to be a boolean, but it's just the
                -- panel that contains this function. Most definitely a bug.
                -- The solution below is full quirk. Don't count on it too much.
                if focus:HasFocus() then
                    colorWindow:Remove()

                    inputNCButton.color = color:GetColor()
                    RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-namecolor", 
                        inputNCButton.color.r/255, inputNCButton.color.g/255, inputNCButton.color.b/255, "-noprint")
                end
            end
        end

        charProperties:AddItem(inputNCLeft, inputNCRight)

        charProperties.nameColorRandom = inputNCRandom
        charProperties.nameColor = inputNCButton

        -- Sex
        local inputSexLeft = vgui.Create("DLabel")
        inputSexLeft:SetText("Sex:")

        local inputSexRight = vgui.Create("DPanel")
        inputSexRight:Dock(FILL)
        inputSexRight:SetBackgroundColor(Color(0, 0, 0, 0))

        local inputSexMale = inputSexRight:Add("DButton")
        local inputSexFemale = inputSexRight:Add("DButton")

        inputSexMale:Dock(LEFT)
        inputSexMale:SetWide(25)
        inputSexMale:SetText("M")
        inputSexMale:SetIsToggle(true)
        inputSexMale:SetToggle(true)
        inputSexMale.DoClick = function()
            inputSexMale:SetToggle(true)
            inputSexFemale:SetToggle(false)
            RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-sex", "male", "-noprint")
        end

        inputSexFemale:Dock(RIGHT)
        inputSexFemale:SetWide(25)
        inputSexFemale:SetText("F")
        inputSexFemale:SetIsToggle(true)
        inputSexFemale.DoClick = function()
            inputSexMale:SetToggle(false)
            inputSexFemale:SetToggle(true)
            RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-sex", "female", "-noprint")
        end

        charProperties:AddItem(inputSexLeft, inputSexRight)

        charProperties.sexMale = inputSexMale
        charProperties.sexFemale = inputSexFemale

        -- Playermodel
        local inputPMLeft = vgui.Create("DLabel")
        inputPMLeft:SetText("Playermodel")

        local inputPMRight = vgui.Create("DButton")
        inputPMRight:Dock(FILL)
        inputPMRight:SetText("male01")
        inputPMRight.DoClick = function()
            local pmMenuWindow = vgui.Create("DPanel")
            pmMenuWindow:SetSize(528, 384)
            pmMenuWindow:MakePopup()

            local mx, my = input.GetCursorPos()
            mx = math.Clamp(mx, 0, ScrW() - pmMenuWindow:GetWide())
            my = math.Clamp(my, 0, ScrH() - pmMenuWindow:GetTall())
            pmMenuWindow:SetPos(mx, my)

            pmMenuWindow.OnFocusChanged = function(focus)
                -- Again don't count on this
                if focus:HasFocus() then
                    pmMenuWindow:Remove()
                end
            end

            local pmMenu = pmMenuWindow:Add("DScrollPanel")
            pmMenu:Dock(FILL)

            local pmMenuLayout = pmMenu:Add("DIconLayout")
            pmMenuLayout:Dock(FILL)
            pmMenuLayout:SetSpaceX(0)
            pmMenuLayout:SetSpaceY(0)

            local pmList = player_manager.AllValidModels()
            for name, model in SortedPairs(pmList) do
                local btn = pmMenuLayout:Add("SpawnIcon")
                btn:SetSize(64, 64)
                btn:SetModel(model)
                btn.DoClick = function()
                    RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-pm", name, "-noprint")
                    pmMenuWindow:Remove()
                end
            end
        end
        
        charProperties:AddItem(inputPMLeft, inputPMRight)

        charProperties.playermodel = inputPMRight

        -- PM Color
        local inputPMColorLeft = vgui.Create("DLabel")
        inputPMColorLeft:SetText("PM color:")

        local inputPMColorRight = vgui.Create("DPanel")
        inputPMColorRight:Dock(FILL)
        inputPMColorRight:SetBackgroundColor(Color(0, 0, 0, 0))

        local inputPMColorRandom = inputPMColorRight:Add("DCheckBoxLabel")
        local inputPMColorButton = inputPMColorRight:Add("DButton")

        inputPMColorRandom:SetText("Random")
        inputPMColorRandom:Dock(LEFT)
        inputPMColorRandom.OnChange = function()
            inputPMColorButton:SetEnabled(!inputPMColorRandom:GetChecked())

            if inputPMColorRandom:GetChecked() then
                RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-pm-color", "random", "-noprint")
            else
                RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-pm-color", 
                    inputPMColorButton.color.r/255, inputPMColorButton.color.g/255, inputPMColorButton.color.b/255, "-noprint")
            end
        end
        
        inputPMColorButton:SetWide(25)
        inputPMColorButton:Dock(RIGHT)
        inputPMColorButton:SetText("")
        inputPMColorButton.color = Color(0, 0, 0, 255)
        inputPMColorButton.PaintOver = function()
            if !inputPMColorButton:IsEnabled() then inputPMColorButton.color.a = 127 end
            draw.RoundedBox(0, 3, 3, inputNCButton:GetWide()-6, inputNCButton:GetTall()-6, inputPMColorButton.color)
        end
        inputPMColorButton.DoClick = function()
            local colorWindow = vgui.Create("DPanel")
            colorWindow:SetSize(250, 200)
            colorWindow:MakePopup()

            local mx, my = input.GetCursorPos()
            mx = math.Clamp(mx, 0, ScrW() - colorWindow:GetWide())
            my = math.Clamp(my, 0, ScrH() - colorWindow:GetTall())
            colorWindow:SetPos(mx, my)

            local color = colorWindow:Add("DColorMixer")
            color:Dock(FILL)
            color:SetAlphaBar(false)
            color:SetPalette(false)
            color:SetColor(inputPMColorButton.color)
            color.ValueChanged = function(color)
                local c = color:GetColor()
                panel.charModel:GetEntity().playerColor = Vector(c.r/255, c.g/255, c.b/255)
            end

            colorWindow.OnFocusChanged = function(focus)
                -- Quirky ass if statement
                if focus:HasFocus() then
                    colorWindow:Remove()

                    inputPMColorButton.color = color:GetColor()
                    RunConsoleCommand("mwcc_char_edit", "-byindex", panel.charIndex, "-pm-color",
                        inputPMColorButton.color.r/255, inputPMColorButton.color.g/255, inputPMColorButton.color.b/255, "-noprint")
                end
            end
        end

        charProperties:AddItem(inputPMColorLeft, inputPMColorRight)

        charProperties.pmColorRandom = inputPMColorRandom
        charProperties.pmColor = inputPMColorButton

        -- PM bodygroups
        charProperties:Help("Bodygroups:")

        charProperties.bodygroups = {}

        for i = 1, 10 do
            local inputBG = charProperties:NumSlider("Bodygroup "..i, nil, 0, 4, 0)
            inputBG:Dock(FILL)
            inputBG:SetValue(0)
            charProperties.bodygroups["Bodygroup "..i] = inputBG
        end

        -- Delete button
        local btnDelete = charProperties:Button("Delete character")
        btnDelete.DoClick = function()
            RunConsoleCommand("mwcc_char_delete", "-byindex", panel.charIndex, "-noprint")
        end

        charProperties.delete = btnDelete
    end
end)
