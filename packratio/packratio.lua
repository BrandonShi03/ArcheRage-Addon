ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)
ADDON:ImportObject(OBJECT_TYPE.BUTTON)
ADDON:ImportObject(OBJECT_TYPE.DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.NINE_PART_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.COLOR_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.WINDOW)
ADDON:ImportObject(OBJECT_TYPE.LABEL)
ADDON:ImportObject(OBJECT_TYPE.ICON_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.IMAGE_DRAWABLE)

ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)
ADDON:ImportAPI(API_TYPE.LOCALE.id)
ADDON:ImportAPI(API_TYPE.STORE.id)
ADDON:ImportAPI(API_TYPE.ABILITY.id)
--initial
local localizedName = {}
local Commerce = 0
local showButton = nil
local showOtherButton = false
local fromButton = nil
local toButton = nil
local continentButton = nil
local updateFrequency = 5000
local counter = 0
local scale = UIParent:GetUIScale() or 1.0
local width = UIParent:GetScreenWidth()
local height = UIParent:GetScreenHeight()
local extent = 50*scale   --图片大小 image width and height
local buttonX = 80*scale -- 按钮宽度 as its name
local buttonY =35*scale -- 按钮长度 as its name
local backward = 5*scale -- 按钮间距 lil space in between
--zone
local fromZoneGroup = 22
local toZoneGroup = 8
local westZone = {}
local eastZone = {}
local westOutlet = {5,8,20}
local eastOutlet = {4,12,17}
local packRatio = {}
--drawicon
local refreshtimer = CreateEmptyWindow("refreshtimer", "UIParent")
refreshtimer:Show(true)
refreshtimer:Enable(true)
local drawableNmyIcons = {} -- Table to store drawn icons, must be global
local drawableNmyLabels = {} -- Table to store drawn rate, must be global

local color = {}
    color.normal    = UIParent:GetFontColor("btn_df")
    color.highlight = UIParent:GetFontColor("btn_ov")
    color.pushed    = UIParent:GetFontColor("btn_on")
    color.disabled  = UIParent:GetFontColor("btn_dis")

local buttonskin = {
    drawableType = "ninePart",
    path = "ui/common/default.dds",
    coordsKey = "btn",
    autoResize = true,
    fontColor = color,
    fontInset = {
        left = 11,
        right = 11,
        top = 0,
        bottom = 0,
    },
}

local function GetPackPrice(toZoneGroup, packName)
    if toZoneGroup == 5 and SOLZREED_PRICE and SOLZREED_PRICE[packName] then
        return SOLZREED_PRICE[packName][1]
    elseif toZoneGroup == 8 and TWOCROWNS_PRICE and TWOCROWNS_PRICE[packName] then
        return TWOCROWNS_PRICE[packName][1]
    elseif toZoneGroup == 20 and CINDERSTONE_PRICE and CINDERSTONE_PRICE[packName] then
        return CINDERSTONE_PRICE[packName][1]
    elseif toZoneGroup == 4 and SOLIS_PRICE and SOLIS_PRICE[packName] then
        return SOLIS_PRICE[packName][1]
    elseif toZoneGroup == 12 and VILLANELLE_PRICE and VILLANELLE_PRICE[packName] then
        return VILLANELLE_PRICE[packName][1]
    elseif toZoneGroup == 17 and YNYSTERE_PRICE and YNYSTERE_PRICE[packName] then
        return YNYSTERE_PRICE[packName][1]
    elseif toZoneGroup == 33 and HEEDMAR_PRICE and HEEDMAR_PRICE[packName] then
        return HEEDMAR_PRICE[packName][1]
    end
    return nil
end

local function GetCommerceSkill()
    local allAbilityInfos = X2Ability:GetAllMyActabilityInfos()
    if allAbilityInfos then
        for _, info in pairs(allAbilityInfos) do
            if info then
                if info.name == "Commerce" or info.name == "经商" then
                    local points = info.point or 0
                    local modifyPoints = info.modifyPoint or 0
                    return points + modifyPoints
                end
            end
        end
    end
    return 0
end

--load translated string into table
local function getLocalizedNames()
    localizedName.zoneGroupName = {}  -- 动态初始化子表
    localizedName.continentName = {}  -- 动态初始化子表

    local ProductionZoneGroups = X2Store:GetProductionZoneGroups()
    for k, v in pairs(ProductionZoneGroups) do
        local id = v.id or "unknown_id"
        localizedName.zoneGroupName[id] = v.zoneGroupName or "unknown"
        localizedName.continentName[id] = v.continentName or "unknown"
    end

    local j = 1
    local k = 1
    for i = 1, 104 do  -- 遍历 continentName 的每个元素（数值循环）
        if localizedName.continentName[i] == localizedName.continentName[1] then
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("West, %s",tostring(i)))
            westZone[j] = i
            j = j+1
        elseif localizedName.continentName[i] == localizedName.continentName[4] then
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("East, %s",tostring(i)))
            eastZone[k] = i
            k = k+1
        end
    end
end

--language
local language = "zh_cn"
local PACKRATE = "查询货率"
local HIDE = "关闭货率"
local REQUESTNOTSEND = "未成功发送申请"
local DATAMISSING = "返回数据错误"
local TEXT = "输出文本"
local DISPLAYING = "正在显示从 %s"
local TO = " 到 %s"
local SPACKRATE = "的货率"
local RETURN = "未找到数据列表"
local ERROR = "错误"
local CHANGE = "检测到查询地区改变，正在查询 %s"
local LOADED = "成功加载货率插件,作者：奈奈呀\n点击按钮以开始查询货率"


language = X2Locale:GetLocale() or "en_us"

if language ~= "zh_cn" then
    buttonX = 120*scale
    PACKRATE = "Track"
    HIDE = "No Track"
    REQUESTNOTSEND = "Error: Request not sent."
    DATAMISSING = "Return Data is missing"
    TEXT = "Output"
    DISPLAYING = "Displaying %s"
    TO = "——> %s"
    SPACKRATE = ""
    RETURN = "Date list does not found"
    ERROR = "Error"
    CHANGE = "Change in locations detected, checking %s"
    LOADED = "loaded Pack ratio tracker made by Neveremore\nclick the button to start tracking packrate"
end

local freshnessMultipliers = {
    ["加工发酵"] = "1.03",
    ["无添加发酵"] = "1.15",
    ["基本发酵"] = "1.05",
    ["天然发酵"] = "1.30",   
    ["特供"] = "1.30",      
    ["新鲜"] = "1.15",          
    ["标准"] = "1.05"   
}


local function drawIcon(w, iconPath,id, xOffset, yOffset, ratio)
    local displayedRatio = 0
    -- If the icon already exists, don't redraw it, instead update it
    if showOtherButton == false then
        return
    end
    if drawableNmyIcons[id] ~= nil then
        if drawableNmyIcons[id].iconPath == iconPath then
            if not drawableNmyIcons[id]:IsVisible() then
                drawableNmyIcons[id]:SetVisible(true)
                drawableNmyLabels[id]:Show(true)
            end
            drawableNmyIcons[id]:AddAnchor("TOPLEFT", w, xOffset, buttonY+yOffset) 
            drawableNmyLabels[id]:AddAnchor("TOPLEFT", w, xOffset+(25*scale*width/1914), buttonY+yOffset+(50*scale*width/1914)) --LEFT+25 +20
            if ratio >= 125 then
                drawableNmyLabels[id].style:SetColor(0, 1, 0, 1.0)
            elseif ratio >= 115 then
                drawableNmyLabels[id].style:SetColor(1, 1, 0, 1.0)
            else
                drawableNmyLabels[id].style:SetColor(1, 0, 0, 1.0)
            end
            displayedRatio = string.format("%s%%",ratio)
            drawableNmyLabels[id]:SetText(displayedRatio)
            return
        else
            drawableNmyIcons[id]:ClearAllTextures()
            drawableNmyIcons[id]:AddTexture(iconPath)
            drawableNmyIcons[id]:AddAnchor("TOPLEFT", w, xOffset, buttonY+yOffset) 
            drawableNmyLabels[id]:AddAnchor("TOPLEFT", w, xOffset+(25*scale*width/1914), buttonY+yOffset+(50*scale*width/1914)) --LEFT+25 +20
            if ratio >= 125 then
                drawableNmyLabels[id].style:SetColor(0, 1, 0, 1.0)
            elseif ratio >= 115 then
                drawableNmyLabels[id].style:SetColor(1, 1, 0, 1.0)
            else
                drawableNmyLabels[id].style:SetColor(1, 0, 0, 1.0)
            end
            displayedRatio = string.format("%s%%",ratio)
            drawableNmyLabels[id]:SetText(displayedRatio)
            drawableNmyIcons[id].iconPath = iconPath
            return
        end
    end
    -- Create an icon using iconPath
    local drawableIcon = w:CreateIconDrawable("artwork")
    drawableIcon:SetExtent(extent,extent) -- Width, height
    drawableIcon:ClearAllTextures() -- Every other usage of AddTexture called this first 🤷
    drawableIcon:AddTexture(iconPath) -- path to dds texture to load
    drawableIcon:SetVisible(false)
    -- add ratio label
    lblRatio = w:CreateChildWidget("label", "lblRatio", 0, true)
    lblRatio:Show(false)
    lblRatio:EnablePick(false)
    if ratio >= 125 then
        lblRatio.style:SetColor(0, 1, 0, 1.0)
    elseif ratio >= 115 then
        lblRatio.style:SetColor(1, 1, 0, 1.0)
    else
        lblRatio.style:SetColor(1, 0, 0, 1.0)
    end
    --lblRatio.style:SetColor(1, 1, 1, 1.0)
    lblRatio.style:SetOutline(true)
    lblRatio.style:SetAlign(ALIGN_BOTTOM)
    displayedRatio = string.format("%s%%",ratio)
    lblRatio:SetText(displayedRatio)
    
    drawableNmyIcons[id] = drawableIcon
    drawableNmyIcons[id].iconPath = iconPath
    drawableNmyLabels[id] = lblRatio
end

local Anchor = CreateEmptyWindow("Anchor", "UIParent")
      Anchor:Show(true)
      Anchor:AddAnchor("LEFT", "UIParent", 0,0)
      Anchor:SetExtent(8*extent, extent+buttonY)
      Anchor:EnableDrag(true)
local background = Anchor:CreateColorDrawable(0, 0, 0, 0.05, "background")
background:AddAnchor("TOPLEFT", Anchor, 0, 0)
background:AddAnchor("BOTTOMRIGHT", Anchor, 0, 0)

local function CreateShowButton()
    if showButton ~= nil then
        return
    end

    showButton = Anchor:CreateChildWidget("button", "showButton", 0, true)
    --ApplyButtonSkin(showButton, buttonskin)
    showButton:SetStyle("text_default")
    showButton:AddAnchor("TOPLEFT",Anchor,0,0)
    showButton:Show(true)
    showButton:EnableDrag(true)
    showButton:SetText(PACKRATE)
    showButton:SetExtent(buttonX,buttonY)

    function showButton:OnClick()
        if showOtherButton == false then
            showButton:SetText(HIDE)
            showButton:SetExtent(buttonX,buttonY)
            showOtherButton = true
            continentButton:Show(true)
            fromButton:Show(true)
            toButton:Show(true)
            textButton:Show(true)
            for i = 1 , 10 do
                if drawableNmyIcons[i] ~= nil then
                    drawableNmyIcons[i]:SetVisible(true)
                    drawableNmyLabels[i]:Show(true)
                end
            end
            
        else
            showButton:SetText(PACKRATE)
            showButton:SetExtent(buttonX,buttonY)
            showOtherButton = false
            continentButton:Show(false)
            fromButton:Show(false)
            toButton:Show(false)
            textButton:Show(false)
            for i = 1 , 10 do
                if drawableNmyIcons[i] ~= nil then
                    drawableNmyIcons[i]:SetVisible(false)
                    drawableNmyLabels[i]:Show(false)
                end
            end
        end
    end
    showButton:SetHandler("OnClick", showButton.OnClick)
end

local function CreateTextButton()
    if textButton ~= nil then
        return
    end
    textButton = Anchor:CreateChildWidget("button", "textButton", 0, true)
    textButton:SetText(TEXT)
    --ApplyButtonSkin(textButton, buttonskin)
    textButton:SetStyle("text_default")
    textButton:AddAnchor("TOPLEFT", Anchor, 1*(buttonX-backward),0)
    textButton:Show(false)
    textButton:SetExtent(buttonX,buttonY)
    function textButton:OnClick()
        X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format(DISPLAYING .. TO .. SPACKRATE,localizedName.zoneGroupName[fromZoneGroup],localizedName.zoneGroupName[toZoneGroup]))
        local displayCommerce = GetCommerceSkill()
        if displayCommerce ~= 0 then
            X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("价格推算基于你的经商熟练度%.1f万,实际以交易所价格为准",displayCommerce/10000))
        end
        for k,v in pairs(packRatio) do
            local message = string.format("%s->%s%%",v.itemInfo.name or "unknown",v.ratio or "unknown")
            if v.itemInfo.name and v.ratio then
                local basePrice = GetPackPrice(toZoneGroup,v.itemInfo.name)
                Commerce = GetCommerceSkill()
                if basePrice then
                    local price = basePrice * v.ratio * (1+(Commerce/10000*0.05))
                    if string.find(v.itemInfo.name, "加工发酵") then
                        price = price *1.03
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "无添加发酵") then
                        price = price *1.15
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "基本发酵") then
                        price = price *1.05
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "天然发酵") then
                        price = price *1.30
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "特供") then
                        price = price *1.15
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "标准") then
                        price = price *1.05
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    elseif string.find(v.itemInfo.name, "新鲜") then
                    price = price *1.15
                    --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("成功"))
                    end
                    local finalPrice = math.floor(price/10000)
                    message = string.format("%s->%s%%,约%s金",v.itemInfo.name or "unknown",v.ratio or "unknown",finalPrice or "错误")
                end
            end
            X2Chat:DispatchChatMessage(CMF_SYSTEM, message)
        end
    end
    textButton:SetHandler("OnClick", textButton.OnClick)
end

local function CreateContinentButton()
    if continentButton ~= nil then
        return
    end
    continentButton = Anchor:CreateChildWidget("button", "continentButton", 0, true)
    continentButton:SetText(localizedName.continentName[fromZoneGroup])
    --ApplyButtonSkin(continentButton, buttonskin)
    continentButton:SetStyle("text_default")
    continentButton:Show(false)
    continentButton:AddAnchor("TOPLEFT", Anchor, 2*(buttonX-backward),0)
    continentButton:SetExtent(buttonX,buttonY)
    function continentButton:OnClick()
        if localizedName.continentName[fromZoneGroup] == localizedName.continentName[1] then
            fromZoneGroup = eastZone[1]
            toZoneGroup = eastOutlet[2]
        elseif localizedName.continentName[fromZoneGroup] == localizedName.continentName[4] then
            fromZoneGroup = westZone[1]
            toZoneGroup = westOutlet[1]
        end
        continentButton:SetText(localizedName.continentName[fromZoneGroup])
        fromButton:SetText(localizedName.zoneGroupName[fromZoneGroup])
        toButton:SetText(localizedName.zoneGroupName[toZoneGroup])
    end
    continentButton:SetHandler("OnClick", continentButton.OnClick)
end

local function CreateFromButton()
    if fromButton ~= nil then
        return
    end

    fromButton = Anchor:CreateChildWidget("button", "fromButton", 0, true)
    fromButton:SetText(localizedName.zoneGroupName[fromZoneGroup])
    --ApplyButtonSkin(fromButton, buttonskin)
    fromButton:SetStyle("text_default")
    fromButton:AddAnchor("TOPLEFT", Anchor, 3*(buttonX-backward),0)
    fromButton:Show(false)
    fromButton:SetExtent(buttonX,buttonY)
    local z = 1
    local x = 1
    function fromButton:OnClick()
        westOutlet = {5,8,20}
        eastOutlet = {4,12,17}
        if localizedName.continentName[fromZoneGroup] == localizedName.continentName[1] then
            if z >= #westZone then
                z = 1
            else
                z = z+1
            end
            fromZoneGroup = westZone[z]
            if fromZoneGroup == westOutlet[1] then
                toZoneGroup = westOutlet[2]
            elseif fromZoneGroup == westOutlet[2] then
                toZoneGroup = westOutlet[3]
            elseif fromZoneGroup == westOutlet[3] then
                toZoneGroup = westOutlet[1]
            end
        elseif localizedName.continentName[fromZoneGroup] == localizedName.continentName[4] then
            if x >= #eastZone then
                x = 1
            else
                x = x+1
            end
            fromZoneGroup = eastZone[x]
            if fromZoneGroup == eastOutlet[1] then
                toZoneGroup = eastOutlet[2]
            elseif fromZoneGroup == eastOutlet[2] then
                toZoneGroup = eastOutlet[3]
            elseif fromZoneGroup == eastOutlet[3] then
                toZoneGroup = eastOutlet[1]
            end
        end
        fromButton:SetText(localizedName.zoneGroupName[fromZoneGroup])
        toButton:SetText(localizedName.zoneGroupName[toZoneGroup])
    end
    fromButton:SetHandler("OnClick", fromButton.OnClick)
end

local function CreateToButton()
    if toButton ~= nil then
        return
    end

    toButton = Anchor:CreateChildWidget("button", "toButton", 0, true)
    toButton:SetText(localizedName.zoneGroupName[toZoneGroup])
    --ApplyButtonSkin(toButton, buttonskin)
    toButton:SetStyle("text_default")
    toButton:AddAnchor("TOPLEFT", Anchor, 4*(buttonX-backward),0)
    toButton:Show(false)
    toButton:SetExtent(buttonX,buttonY)
    local v = 1
    local b = 1
    function toButton:OnClick()
        westOutlet = {5,8,20}
        eastOutlet = {4,12,17}
        if localizedName.continentName[fromZoneGroup] == localizedName.continentName[1] then
            if fromZoneGroup == westOutlet[1] then
                westOutlet = {8,20}
            elseif fromZoneGroup == westOutlet[2] then
                westOutlet = {5,20}
            elseif fromZoneGroup == westOutlet[3] then
                westOutlet = {5,8}
            end
            
            if v >= #westOutlet then
                v = 1
            else
                v = v+1
            end
            toZoneGroup = westOutlet[v]

        elseif localizedName.continentName[fromZoneGroup] == localizedName.continentName[4] then
            if fromZoneGroup == eastOutlet[1] then
                eastOutlet = {12,17}
            elseif fromZoneGroup == eastOutlet[2] then
                eastOutlet = {4,17}
            elseif fromZoneGroup == eastOutlet[3] then
                eastOutlet = {4,12}
            end
            
            if b >= #eastOutlet then
                b = 1
            else
                b = b+1
            end
            toZoneGroup = eastOutlet[b]
        end
        toButton:SetText(localizedName.zoneGroupName[toZoneGroup])
    end
    toButton:SetHandler("OnClick", toButton.OnClick)
end

---thanks to Noir's timeuntil code
local x = 0
local y = width/2
local filePath = "packRatioPositionSetting.txt"
local function SaveWindowPosition(x, y)
    local file = io.open(filePath, "w")
    file:write(string.format("%d,%d", x, y))
    file:close()
end
local function LoadSavedPosition()
    local file = io.open(filePath, "r")
    if not file then
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("no file"))
        return width/2,height/2
    end
    local line = file:read("*line") 
    file:close()
    if not line or line == "" then
        return width/2,height/2
    end
    local x,y= line:match("(%d+),(%d+)")
    if x and y then
        return x,y
    else
        return width/2,height/2
    end
end
function Anchor:OnDragStart()
    self:StartMoving()
    self.moving = true
end
Anchor:SetHandler("OnDragStart", Anchor.OnDragStart)
function Anchor:OnDragStop()
    self:StopMovingOrSizing()
    self.moving = false
    local offsetX, offsetY = self:GetOffset()
    local normalizedX = offsetX / scale
    local normalizedY = offsetY / scale
    SaveWindowPosition(normalizedX, normalizedY)
end
Anchor:SetHandler("OnDragStop", Anchor.OnDragStop)
local savedWindowX, savedWindowY= LoadSavedPosition()
Anchor:AddAnchor("TOPLEFT", "UIParent", tonumber(savedWindowX), tonumber(savedWindowY))


local checkedFrom = 0
local checkedTo = 0
function checkPackRatio(fromZoneGroup,toZoneGroup)
    local success = X2Store:GetSpecialtyRatioBetween(fromZoneGroup, toZoneGroup)
    if not success then
        X2Chat:DispatchChatMessage(CMF_SYSTEM, REQUESTNOTSEND)
    end
    checkedFrom = fromZoneGroup
    checkedTo = toZoneGroup
    counter = 0
end

local function SendRatioToChat(RatioTable)
    if not RatioTable or type(RatioTable) ~= "table" then
        X2Chat:DispatchChatMessage(CMF_SYSTEM, DATAMISSING)
        return 
    end
    packRatio = RatioTable
    end
UIParent:SetEventHandler(UIEVENT_TYPE.SPECIALTY_RATIO_BETWEEN_INFO, SendRatioToChat)


function refreshtimer:OnUpdate(dt) --check if colddown is enough
    local packCounter = 0
    if counter > updateFrequency then
        if showOtherButton == true then
            if checkedFrom ~= fromZoneGroup or checkedTo ~= toZoneGroup then
                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format(CHANGE .. TO .. SPACKRATE,localizedName.zoneGroupName[fromZoneGroup],localizedName.zoneGroupName[toZoneGroup]))
            end
            checkPackRatio(fromZoneGroup,toZoneGroup)
        end
    else
        counter = counter + dt
    end

    for k,v in pairs(packRatio) do
        drawIcon(Anchor,v.itemInfo.icon,k,extent*packCounter, 0, v.ratio)
        packCounter = packCounter +1
    end

    if packCounter ~= nil then
        if packCounter == 0 or showOtherButton == false then
            Anchor:SetExtent(buttonX+20,buttonY+20)
        else
            Anchor:SetExtent(packCounter*extent+1, extent+buttonY)
        end
    end

    for id = 7, 10 do
        if drawableNmyIcons[id] ~= nil then
            if id > packCounter then
                drawableNmyIcons[id]:SetVisible(false)
                drawableNmyLabels[id]:Show(false)
            end
        end
    end
end

local function EnteredWorld()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, LOADED)
    getLocalizedNames()
    CreateShowButton()
    CreateTextButton()
    CreateContinentButton()
    CreateFromButton()
    CreateToButton()
    Commerce = GetCommerceSkill() 
    checkPackRatio(fromZoneGroup,toZoneGroup)
end
UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, EnteredWorld)

refreshtimer:SetHandler("OnUpdate", refreshtimer.OnUpdate)

-- Chat event listener for commands
local chatAggroEventListenerEvents = {
    CHAT_MESSAGE = function(channel, relation, name, message, info)
        local copyOrignalName = name
        local isOtherWorldMessage = false
        local worldName = info and info.worldName or nil
        local nameWithWorldName
        if worldName == nil or worldName == "" then
            nameWithWorldName = name
        else
            nameWithWorldName = string.format("%s@%s", name, worldName)
            isOtherWorldMessage = true
        end

        name = string.format("|k%s,%d;", name, relation)
        if copyOrignalName == X2Unit:UnitName("player") then
            if string.sub(message, 1, 1) == "/" then
                local firstWord = string.match(message, "/[^%s]+")
                local secondWord = string.match(message, "/[^%s]+%s+([^%s]+)")
                local thirdWord = string.match(message, "/[^%s]+%s+[^%s]+%s+([^%s]+)")

                if firstWord == "/地区" or firstWord == "/Location" then
                    if secondWord and thirdWord then
                        local secondId,thirdId
                        for i=1,#localizedName.zoneGroupName do
                            if string.find(localizedName.zoneGroupName[i],secondWord) then
                                secondId = i
                            elseif string.find(localizedName.zoneGroupName[i],thirdWord) then
                                thirdId = i
                            end
                        end
                        if localizedName.continentName[secondId] == localizedName.continentName[thirdId] and secondId ~= thirdId then
                            fromZoneGroup = secondId
                            toZoneGroup = thirdId
                            fromButton:SetText(localizedName.zoneGroupName[fromZoneGroup])
                            toButton:SetText(localizedName.zoneGroupName[toZoneGroup])
                            continentButton:SetText(localizedName.continentName[fromZoneGroup])
                        end
                    end
                end
            end
        end
    end
}

local chatEventListenerAggro = CreateEmptyWindow("chatEventListenerAggro", "UIParent")
chatEventListenerAggro:Show(false)
chatEventListenerAggro:SetHandler("OnEvent", function(this, event, ...)
  chatAggroEventListenerEvents[event](...)
end)

-- Register chat events
local RegistUIEvent = function(window, eventTable)
  for key, _ in pairs(eventTable) do
    window:RegisterEvent(key)
  end
end
RegistUIEvent(chatEventListenerAggro, chatAggroEventListenerEvents)