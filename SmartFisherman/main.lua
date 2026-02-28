ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)
ADDON:ImportObject(OBJECT_TYPE.BUTTON)
ADDON:ImportObject(OBJECT_TYPE.DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.NINE_PART_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.COLOR_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.WINDOW)
ADDON:ImportObject(OBJECT_TYPE.LABEL)
ADDON:ImportObject(OBJECT_TYPE.ICON_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.IMAGE_DRAWABLE)

ADDON:ImportAPI(API_TYPE.OPTION.id)
ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.LOCALE.id)
ADDON:ImportAPI(API_TYPE.HOTKEY.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)
if API_TYPE == nil then
    ADDON:ImportAPI(8)
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "NO API!")
    return
end
version = "1.0"

local fishUpdator = nil
local counter = 0
local autoSetKey = "R"
local savedKey = nil
local keyBind={
    ["5264"] = "4",
    ["5265"] = "3",
    ["5267"] = "5",
    ["5266"] = "6",
    ["5508"] = "7"
}

--window setting
local titleY = 20 
local titleFontSize = 25 

local active = {"R","T","Y","U"}
function resetKeyBind()
    X2Hotkey:BindingToOption()
    for i=1,4 do
        X2Hotkey:SetOptionBindingWithIndex("mode_action_bar_button",active[i], 1,i)
        X2Hotkey:SaveHotKey()
    end
end

local fisherWindow = nil
local function ToggleFisherWindow()
    if fisherWindow == nil then
        fisherWindow = CreateEmptyWindow("fisherWindow", "UIParent")
        fisherWindow:SetExtent(300, 300)
        fisherWindow:AddAnchor("CENTER", "UIParent", 0,0)
        fisherWindow:EnableDrag(true)
        
        local function OnShow()
            if fisherWindow.ShowProc ~= nil then
                fisherWindow:ShowProc()
            end
            SettingWindowSkin(fisherWindow)
            fisherWindow:SetStartAnimation(true, true)
        end
        fisherWindow:SetHandler("OnShow", OnShow)

        function fisherWindow:OnDragStart()
            self:StartMoving()
            self.moving = true
        end
        fisherWindow:SetHandler("OnDragStart", fisherWindow.OnDragStart)

        function fisherWindow:OnDragStop()
            self:StopMovingOrSizing()
            self.moving = false
        end
        fisherWindow:SetHandler("OnDragStop", fisherWindow.OnDragStop)

        someTitle = fisherWindow:CreateChildWidget("label", "someTitle", 0, false)
        someTitle:SetHeight(30)
        someTitle:SetText(titleText)
        someTitle.style:SetFontSize(titleFontSize)
        someTitle:AddAnchor("TOP", fisherWindow,0,titleY)
        someTitle.style:SetAlign(ALIGN_CENTER)
        someTitle.style:SetColorByKey("brown")

        pressKeyLabel = fisherWindow:CreateChildWidget("label", "pressKeyLabel", 0, false)
        pressKeyLabel:SetHeight(30)
        pressKeyLabel:SetText(titleText)
        pressKeyLabel.style:SetFontSize(titleFontSize)
        pressKeyLabel:AddAnchor("CENTER", fisherWindow,0,0)
        pressKeyLabel.style:SetAlign(ALIGN_CENTER)
        pressKeyLabel.style:SetColorByKey("brown")

        local closeButton = fisherWindow:CreateChildWidget("button", "closeButton", 0, true)
        --closeButton:SetStyle("text_default")
        closeButton:AddAnchor("TOPRIGHT", fisherWindow,-10,10)
        closeButton:Show(true)
        closeButton:SetText("X")
        closeButton:SetExtent(45,30)
        local color = UIParent:GetFontColor("brown")
        closeButton:SetTextColor(color[1], color[2], color[3], color[4])

        function closeButton:OnClick()
            fisherWindow:Show(false)
            resetKeyBind()--reset on quit
        end
        closeButton:SetHandler("OnClick", closeButton.OnClick)

        
        function fisherWindow:OnUpdate(dt)
            if counter >= 500 then --0.5sec per update
                counter = 0
                local UnitId = X2Unit:GetTargetUnitId()
                if UnitId == nil then -- no target
                    pressKeyLabel:SetText(NOTARGET)
                    pressKeyLabel.style:SetColorByKey("brown")
                    savedKey = nil
                else
                    local labelText = DETECTING
                    local labelColor = "brown"

                    local targetBuffCount = X2Unit:UnitBuffCount("target")
                    if targetBuffCount then
                        for i=1,targetBuffCount do
                            local buffToolTip = X2Unit:UnitBuffTooltip("target", i)
                            local buffInfo = X2Unit:UnitBuff("target", i)
                            local stringId = tostring(buffInfo["buff_id"])
                            if keyBind[stringId] then --detect fish skill
                                labelText = PRESS .. tostring(autoSetKey)
                                labelColor = "green"

                                if savedKey == nil then
                                    X2Hotkey:BindingToOption()--call before changing, might lower fps
                                    X2Hotkey:SetOptionBindingWithIndex("mode_action_bar_button",autoSetKey, 1,tonumber(keyBind[stringId]) or 1)
                                    X2Hotkey:SaveHotKey()--change
                                    savedKey = tonumber(keyBind[stringId])--update savedKey
                                else
                                    if savedKey ~= tonumber(keyBind[stringId]) then --diff skill
                                        labelText = WAIT--update text
                                        labelColor = "red"--update color

                                        X2Hotkey:BindingToOption()--call before changing, might lower fps
                                        X2Hotkey:SetOptionBindingWithIndex("mode_action_bar_button",autoSetKey, 1,tonumber(keyBind[stringId]) or 1)
                                        X2Hotkey:SaveHotKey()--change
                                        savedKey = tonumber(keyBind[stringId])--update savedKey
                                    end
                                end
                            end
                        end
                    end
                    pressKeyLabel:SetText(labelText)--update text
                    pressKeyLabel.style:SetColorByKey(labelColor)--update color
                end
            else
                counter = counter + dt
            end
        end
        fisherWindow:SetHandler("OnUpdate", fisherWindow.OnUpdate)

        fisherWindow:Enable(true)
        fisherWindow:Show(false)
    end
        fisherWindow:Show(not fisherWindow:IsVisible())
end

local function EnteredWorld()
    X2Chat:DispatchChatMessage(CMF_SYSTEM,string.format(ADDON_SUCCESS .. "%s",version or "未知"))
    X2Hotkey:BindingToOption()
end
UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, EnteredWorld)

X2:AddEscMenuButton(5,4321,"optimizer",RESET)
ADDON:RegisterContentTriggerFunc(4321, resetKeyBind)

X2:AddEscMenuButton(4,4320,"tgos",ADDON_NAME)
ADDON:RegisterContentTriggerFunc(4320, ToggleFisherWindow)