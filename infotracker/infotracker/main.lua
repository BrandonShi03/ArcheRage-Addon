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
ADDON:ImportAPI(API_TYPE.ACHIEVEMENT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)
ADDON:ImportAPI(API_TYPE.LOCALE.id)
ADDON:ImportAPI(API_TYPE.STORE.id)
ADDON:ImportAPI(API_TYPE.PLAYER.id)
ADDON:ImportAPI(API_TYPE.EQUIPMENT.id)
ADDON:ImportAPI(API_TYPE.QUEST.id)
ADDON:ImportAPI(API_TYPE.MAP.id)
ADDON:ImportAPI(API_TYPE.BAG.id)

version = "1.3" --Oct25 2025 first patch  

local okButton = nil
local timeUpdator = nil
local scale = UIParent:GetUIScale() or 1.0
local equipmentNames = {}
local normalizedX = 0
local normalizedY = 0
local counter = 0
local count = 9
local titleY = 20 
local titleFontSize = 25 
local buttonX = 150
local buttonY = 35
local CSicon = {}
local CS = {}
local button = {}
local accptedQuest = {}
local mainPageButton = {}
local dailyIconList = {"Addon/test/icon/GR.dds","Addon/test/icon/CR.dds","ui/icon/icon_item_3864.dds","ui/icon/icon_item_3887.dds","Addon/test/icon/JMG.dds","Addon/test/icon/boss2.dds","Addon/test/icon/boss.dds","ui/icon/icon_item_4050.dds"}
local questState = "daily"
local vocation_today = 0
local gold_today = 0
local honor_today = 0
local exp_today = 0
local language = X2Locale:GetLocale()
local DAILY_PROGRESS = (language == "zh_cn") and "每日进度: %d/%d" or "Daily Progress: %d/%d"
local GUILD_PROGRESS = (language == "zh_cn") and "公会任务进度: %d/%d" or "Guild Progress: %d/%d"
local serverTimeTable = UIParent:GetServerTimeTable()
local month = serverTimeTable.month
local day = serverTimeTable.day
local date_Today = tostring(month) .. tostring(day)
local is_in_Net = false

local function ToggleEventWindow()
    if showWindow == nil then
        showWindow = CreateEmptyWindow("showWindow", "UIParent")
        showWindow:SetExtent(300, 400) -- 800 475
        showWindow:AddAnchor("CENTER", "UIParent", 0,0)
        showWindow:EnableDrag(true)
        showWindow:SetCloseOnEscape(true)
       
        local function OnShow()
            if showWindow.ShowProc ~= nil then
                showWindow:ShowProc()
            end
            SettingWindowSkin(showWindow)
            showWindow:SetStartAnimation(true, true)
        end
        showWindow:SetHandler("OnShow", OnShow)

        function showWindow:OnDragStart()
            self:StartMoving()
            self.moving = true
        end
        showWindow:SetHandler("OnDragStart", showWindow.OnDragStart)

        function showWindow:OnDragStop()
            self:StopMovingOrSizing()
            self.moving = false
        end
        showWindow:SetHandler("OnDragStop", showWindow.OnDragStop)

        someTitle = showWindow:CreateChildWidget("label", "someTitle", 0, false)
        someTitle:SetHeight(30)
        someTitle:SetText(INFOADDON .. MAINPAGE)
        someTitle.style:SetFontSize(titleFontSize)
        someTitle:AddAnchor("TOP", showWindow,0,titleY)
        someTitle.style:SetAlign(ALIGN_CENTER)
        someTitle.style:SetColorByKey("brown")

        local uiScale = UIParent:GetUIScale() or 1.0
        for i=1 , 8 do
            CSicon[i] = showWindow:CreateIconDrawable("artwork")
            CSicon[i]:SetExtent(30,30)
            CSicon[i]:AddAnchor("TOPLEFT", showWindow, 5, 75+(i - 1) * 35) 
            CSicon[i]:ClearAllTextures()
            --CSicon[i]:AddTexture("ui/icon/icon_skill_buff606.dds") 
            CSicon[i]:SetVisible(false)

            CS[i] = showWindow:CreateChildWidget("label", "CS" .. i, 0, false)
            CS[i]:SetHeight(30)
            CS[i].style:SetFontSize(16)
            CS[i]:AddAnchor("TOPLEFT", showWindow, 50, 75+(i - 1) * 35)
            CS[i].style:SetAlign(ALIGN_LEFT)
            CS[i].style:SetColorByKey("brown")
            --CS[i]:SetText("SOFT")

            local buttonInit = showWindow:CreateChildWidget("button", "questButton"..i, 0, true)
            buttonInit:AddAnchor("TOPLEFT", showWindow, 50, 75+(i - 1) * 35)
            buttonInit.style:SetFontSize(16)
            buttonInit:SetText("")
            buttonInit:SetExtent(buttonX ,buttonY)
            buttonInit:Show(true)
            local color = UIParent:GetFontColor("brown")
            buttonInit:SetTextColor(color[1], color[2], color[3], color[4])
            function buttonInit:OnClick()
                --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("you clicked button %s",tostring(i) or "error"))
                local questList = {GR, CR, WH, AEGIS, JMG, VOIDATTK, WONDERLAND, HALCY}
                if questState == "vocation" then
                    questList = {BSB,NUI,RESIDENT,FISHPACK}
                    --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("BSB"))
                elseif questState == "daily" then
                    questList = {GR, CR, WH, AEGIS, JMG, VOIDATTK, WONDERLAND, HALCY}
                elseif questState == "weekly" then
                    questList = {HIRAMONE,WHM,EHM,IPY,GPW}
                elseif questState == "others" then
                    questList = {WABOSS,LUSCA,ABYSSAL,AKASCH,PRAIRIE,GARDENBOSS,YNYSWORD,CINDERSWORD}
                end
                if questList[i] then
                    X2Chat:DispatchChatMessage(CMF_SYSTEM, (language == "zh_cn") and "正在检测"  .. tostring(questList[i]) or "Checking for " .. tostring(questList[i]))
                    if questList[i] == WH then
                        local west = {8602,8603,8604,8605,8637,9000220}
                        local east = {8609,8612,8615,8638,8606,9000220}
                        local pirate = {8610,8613,8616,8639,8607,9000220}
                        local westComplete = 0
                        local eastComplete = 0
                        local pirateComplete = 0
                        local outputTable = {}
                        
                        for _,id in ipairs(west) do
                            westComplete = westComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(east) do
                            eastComplete = eastComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(pirate) do
                            pirateComplete = pirateComplete + checkQuestComplete(id)
                        end
                        
                        if westComplete == 0 and eastComplete == 0 and pirateComplete == 0 then
                            outputTable = west
                        else
                            if westComplete >= eastComplete and westComplete >= pirateComplete then
                                outputTable = west
                            elseif eastComplete >= westComplete and eastComplete >= pirateComplete then
                                outputTable = east
                            else
                                outputTable = pirate
                            end
                        end

                        for _,id in pairs(outputTable) do
                            if id and id ~= nil then
                                local title = X2Quest:GetQuestContextMainTitle(id)
                                local complete = X2Quest:IsCompleted(id)
                                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                            end
                        end
                    elseif questList[i] == AEGIS then
                        local west = {8626,8628,8632,8641,8618,8645,9000221}
                        local east = {8623,8627,8631,8644,8619,8645,9000221}
                        local pirate = {8624,8630,8634,8643,8621,8645,9000221}
                        local westComplete = 0
                        local eastComplete = 0
                        local pirateComplete = 0
                        local outputTable = {}
                        
                        for _,id in ipairs(west) do
                            westComplete = westComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(east) do
                            eastComplete = eastComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(pirate) do
                            pirateComplete = pirateComplete + checkQuestComplete(id)
                        end
                        
                        if westComplete == 0 and eastComplete == 0 and pirateComplete == 0 then
                            outputTable = west
                        else
                            if westComplete >= eastComplete and westComplete >= pirateComplete then
                                outputTable = west
                            elseif eastComplete >= westComplete and eastComplete >= pirateComplete then
                                outputTable = east
                            else
                                outputTable = pirate
                            end
                        end

                        for _,id in pairs(outputTable) do
                            if id and id ~= nil then
                                local title = X2Quest:GetQuestContextMainTitle(id)
                                local complete = X2Quest:IsCompleted(id)
                                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                            end
                        end
                    elseif questList[i] == GR then
                        local west = {5142,5143,5144,7648,7649,11192,10739}
                        local east = {5157,5143,5144,7648,7649,11192,10739}
                        local westComplete = 0
                        local eastComplete = 0
                        local outputTable = {}
                        
                        for _,id in ipairs(west) do
                            westComplete = westComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(east) do
                            eastComplete = eastComplete + checkQuestComplete(id)
                        end
                        
                        if westComplete == 0 and eastComplete == 0 then
                            outputTable = west
                        else
                            if westComplete >= eastComplete then
                                outputTable = west
                            else
                                outputTable = east
                            end
                        end

                        for _,id in pairs(outputTable) do
                            if id and id ~= nil then
                                local title = X2Quest:GetQuestContextMainTitle(id)
                                local complete = X2Quest:IsCompleted(id)
                                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                            end
                        end
                    elseif questList[i] == PRAIRIE then
                        local west = {11096,11132}
                        local east = {11116,11132}
                        local pirate = {11098,11131,11133}
                        local westComplete = 0
                        local eastComplete = 0
                        local pirateComplete = 0
                        local outputTable = {}
                        
                        for _,id in ipairs(west) do
                            westComplete = westComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(east) do
                            eastComplete = eastComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(pirate) do
                            pirateComplete = pirateComplete + checkQuestComplete(id)
                        end
                        
                        if westComplete == 0 and eastComplete == 0 and pirateComplete == 0 then
                            outputTable = west
                        else
                            if westComplete >= eastComplete and westComplete >= pirateComplete then
                                outputTable = west
                            elseif eastComplete >= westComplete and eastComplete >= pirateComplete then
                                outputTable = east
                            else
                                outputTable = pirate
                            end
                        end

                        for _,id in pairs(outputTable) do
                            if id and id ~= nil then
                                local title = X2Quest:GetQuestContextMainTitle(id)
                                local complete = X2Quest:IsCompleted(id)
                                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                            end
                        end
                        elseif questList[i] == ABYSSAL then
                        local west = {6971,6973}
                        local east = {6971,6974}
                        local pirate = {6971,6975}
                        local westComplete = 0
                        local eastComplete = 0
                        local pirateComplete = 0
                        local outputTable = {}
                        
                        for _,id in ipairs(west) do
                            westComplete = westComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(east) do
                            eastComplete = eastComplete + checkQuestComplete(id)
                        end
                        for _,id in ipairs(pirate) do
                            pirateComplete = pirateComplete + checkQuestComplete(id)
                        end
                        
                        if westComplete == 0 and eastComplete == 0 and pirateComplete == 0 then
                            outputTable = west
                        else
                            if westComplete >= eastComplete and westComplete >= pirateComplete then
                                outputTable = west
                            elseif eastComplete >= westComplete and eastComplete >= pirateComplete then
                                outputTable = east
                            else
                                outputTable = pirate
                            end
                        end

                        for _,id in pairs(outputTable) do
                            if id and id ~= nil then
                                local title = X2Quest:GetQuestContextMainTitle(id)
                                local complete = X2Quest:IsCompleted(id)
                                X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                            end
                        end
                    else
                        local data = eventDatas[questList[i]]
                        if data and data[1] and CS[i] then -- 注意这里访问 data[1]
                            --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("found data"))
                            local questIds = data[1].questId or {} -- 访问第一个元素的 questId
                            for _,id in pairs(questIds) do
                                if id and id ~= nil then
                                    local title = X2Quest:GetQuestContextMainTitle(id)
                                    local complete = X2Quest:IsCompleted(id)
                                    X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s——>%s",title,(complete == true) and "|cFF00FF00" .. COMPLETE .. "|r" or "|cFFFF9999" .. INCOMPLETE .. "|r"))
                                end
                            end
                        end
                    end
                end
            end
            buttonInit:SetHandler("OnClick", buttonInit.OnClick)
            button[i] = buttonInit
        end 
        
        -- 定义按钮配置表，每个按钮都有独立的函数
        local buttonConfigs = {
            {
                name = GNINFO,
                func = function()
                    for i=1,8 do
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    someTitle:SetText(GNINFO)
                    local mainPageString = {}
                    local Noblessing = checkBlessing()
                    if Noblessing == true then
                        table.insert(mainPageString,NOBLESSING)
                    end
                    local noCos,noUnde = checkCostumeAndUnderwear()
                    if noCos == true then
                        table.insert(mainPageString,COS_EXPIRED)
                    end
                    if noUnde == true then
                        table.insert(mainPageString,UND_EXPIRED)
                    end

                    local maxDaily = 0
                    local unlockedDaily = 0
                    local completeDaily = 0
                    for i=1,7 do
                        local info = X2Achievement:GetTodayAssignmentInfo(TADT_TODAY, i)
                        if info then
                            if info.status == 1 then
                                maxDaily = maxDaily +1
                            elseif info.status == 2 then
                                maxDaily = maxDaily + 1
                                unlockedDaily = unlockedDaily + 1
                            elseif info.status == 3 then
                                maxDaily = maxDaily + 1
                                completeDaily = completeDaily + 1
                            end
                        end
                    end

                    -- 只有当有日常任务且未全部完成时才显示
                    if maxDaily > 0 then
                        if completeDaily == maxDaily then
                            -- 所有日常任务都已完成，不显示任何信息
                        elseif unlockedDaily == 0 and completeDaily == 0 then
                            -- 没有解锁的任务且没有完成的任务
                            table.insert(mainPageString,NO_UNLOCK_DAILY)
                        elseif unlockedDaily == 0 and completeDaily > 0 then
                            -- 没有解锁的任务但有已完成的任务（说明今天已经做完了所有解锁的任务）
                            -- 不显示任何信息
                        elseif completeDaily > 0 then
                            -- 有已完成的任务，显示完成进度
                            table.insert(mainPageString, string.format(DAILY_PROGRESS, completeDaily, maxDaily))
                        elseif unlockedDaily ~= 0 and completeDaily == 0 then
                            --解锁了但是啥也没做
                            table.insert(mainPageString, string.format(DAILY_PROGRESS, 0, maxDaily))
                        else
                            table.insert(mainPageString,UNLOCKED_PART_DAILY)
                        end
                    else
                        table.insert(mainPageString,NO_DAILY)
                    end

                    -- 修改的公会任务检查逻辑
                    local maxGuild = 0
                    local unlockedGuild = 0
                    local completeGuild = 0
                    for i=1,7 do
                        local guildInfo = X2Achievement:GetTodayAssignmentInfo(TADT_EXPEDITION, i)
                        if guildInfo then
                            if guildInfo.status == 1 then
                                maxGuild = maxGuild +1
                            elseif guildInfo.status == 2 then
                                maxGuild = maxGuild + 1
                                unlockedGuild = unlockedGuild + 1
                            elseif guildInfo.status == 3 then
                                maxGuild = maxGuild + 1
                                completeGuild = completeGuild + 1
                            end
                        end
                    end

                    -- 只有当有公会任务且未全部完成时才显示
                    if maxGuild > 0 then
                        if completeGuild == maxGuild then
                            -- 所有公会任务都已完成，不显示任何信息
                        elseif unlockedGuild == 0 and completeGuild == 0 then
                            -- 没有解锁的任务且没有完成的任务
                            table.insert(mainPageString,NO_GUILD_QUEST)
                        elseif unlockedGuild == 0 and completeGuild > 0 then
                            -- 没有解锁的任务但有已完成的任务（说明今天已经做完了所有解锁的任务）
                            -- 不显示任何信息
                        elseif completeGuild > 0 then
                            -- 有已完成的任务，显示完成进度
                            table.insert(mainPageString, string.format(GUILD_PROGRESS, completeGuild, maxGuild))
                        elseif unlockedDaily ~= 0 and completeDaily == 0 then
                            --解锁了但是啥也没做
                            table.insert(mainPageString, string.format(GUILD_PROGRESS, 0, maxDaily))
                        else
                            table.insert(mainPageString,PART_GUILD)
                        end
                    else
                        local name = X2Unit:GetUnitId("player")
                        local guildName = X2Unit:GetUnitInfoById(tostring(name))
                        if guildName.expeditionName and guildName.expeditionName ~= nil then
                            table.insert(mainPageString,NO_GUILD_QUEST_UNLOCKED)
                        else
                            table.insert(mainPageString,NO_GUILD)
                        end
                    end

                    local count = X2Quest:GetActiveQuestListCount()
                    local haveWhale = false
                    local haveHalcy = false
                    local Complete = X2Quest:IsCompleted(9000220)
                    local HALCYComplete = X2Quest:IsCompleted(9320)
                    
                    for i = 1, count do
                        local type1 = X2Quest:GetActiveQuestType(i)
                        if type1 == 9000220 then
                            haveWhale = true
                        elseif type1 == 9320 then
                            haveHalcy = true
                        end
                    end
                    if haveWhale == false and Complete == false then
                        table.insert(mainPageString,NO_WH_QUEST)
                    end
                    if haveHalcy == false and HALCYComplete == false then
                        table.insert(mainPageString,NO_HALCY_QUEST)
                    end

                    for i,string in pairs(mainPageString)do
                        if CS[i] and string ~= nil then
                            CS[i]:SetText(string)
                            CS[i]:Show(true)
                        end
                    end
                end
            },
            {
                name = QUEST_INFO, 
                func = function()
                    someTitle:SetText(QUEST_INFO)
                    questState = "daily"
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:SetText("")
                            if CSicon[i] then
                                CSicon[i]:ClearAllTextures()
                                CSicon[i]:Show(false)
                            end
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    local dailyQuestList = {GR, CR, WH, AEGIS, JMG, VOIDATTK, WONDERLAND, HALCY}
                    local dailyIconList = {"Addon/infotracker/icon/GR.dds","Addon/infotracker/icon/CR.dds","ui/icon/icon_item_3864.dds","ui/icon/icon_item_3887.dds","Addon/infotracker/icon/JMG.dds","Addon/infotracker/icon/boss2.dds","Addon/infotracker/icon/boss.dds","ui/icon/icon_item_4050.dds"}
                    for i, eventName in ipairs(dailyQuestList) do
                        local data = eventDatas[eventName]
                        if data and data[1] and CS[i] then -- 注意这里访问 data[1]
                            button[i]:Show(true)
                            local questIds = data[1].questId or {} -- 访问第一个元素的 questId
                            local complete = 0
                            
                            if #questIds > 0 then
                                -- 计算完成的任务数量
                                for _, id in ipairs(questIds) do
                                    complete = complete + checkQuestComplete(id)
                                end
                                
                                local maxQuestNum = data[1].maxQuestNum or #questIds
                                button[i]:SetText(string.format("%s %s/%s", eventName, complete, maxQuestNum))
                            else
                                button[i]:SetText(string.format("%s %s", eventName, UNABLETOTRACK))
                            end
                        else
                            button[i]:Show(true)
                            button[i]:SetText(string.format("%s %s", eventName, NO_DATA))
                        end
                    end
                    for i,iconPath in pairs(dailyIconList) do
                        if iconPath then
                            CSicon[i]:AddTexture(iconPath)
                            CSicon[i]:Show(true)
                        end
                    end
                end
            },
            {
                name = CM_STATES,
                func = function()
                    someTitle:SetText(CM_STATES)
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:Show(true)
                        end
                        if CSicon[i] then
                            CSicon[i]:ClearAllTextures()
                            CSicon[i]:Show(false) 
                        end
                        if button[i] then
                            button[i]:Show(false)
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    local SOFT = {54,56,57,102,103}
                    local CRAFT = {2,22,26,27,78,11,14,16}
                    local BOAT = {3,4,5,6,9,13}
                    local CAR = {7,10,21,24}
                    local PACK = {8,15,18,23}
                    local SOFTstring = checkForDevelopment(SOFT,MINI_SOF)
                    local CRAFTstring = checkForDevelopment(CRAFT,GRAND_WORKBENCH)
                    local BOATstring = checkForDevelopment(BOAT,SHIP_MERCHANT)
                    local CARString = checkForDevelopment(CAR,CAR_MERCHANT)
                    local PACKString = checkForDevelopment(PACK,ADV_PACKCRAFTOR)
                    if SOFTstring and CS[1] then
                        CS[1]:SetText(SOFTstring)
                        CSicon[1]:AddTexture("ui/icon/icon_skill_buff606.dds")
                        CSicon[1]:Show(true)  
                    end
                    if CRAFTstring and CS[2] then
                        CS[2]:SetText(CRAFTstring)
                        CSicon[2]:AddTexture("ui/icon/icon_item_0529.dds")
                        CSicon[2]:Show(true)
                    end
                    if BOATstring and CS[3] then
                        CS[3]:SetText(BOATstring)
                        CSicon[3]:AddTexture("ui/icon/icon_item_2121.dds")
                        CSicon[3]:Show(true)
                    end
                    if CARString and CS[4] then
                        CS[4]:SetText(CARString)
                        CSicon[4]:AddTexture("ui/icon/icon_item_4693.dds")
                        CSicon[4]:Show(true)
                    end
                    if PACKString and CS[5] then
                        CS[5]:SetText(PACKString)
                        CSicon[5]:AddTexture("ui/icon/icon_item_1752.dds")
                        CSicon[5]:Show(true)
                    end
                    for i=6,8 do
                        if CS[i] then
                            CS[i]:SetText("")
                            CSicon[i]:ClearAllTextures()
                            CSicon[i]:Show(false) 
                        end
                    end
                end
            },
            {
                name = LIFE_DAILY,
                func = function()
                    someTitle:SetText(LIFE_DAILY)
                    questState = "vocation"
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:SetText("")
                            if CSicon[i] then
                                CSicon[i]:ClearAllTextures()
                                CSicon[i]:Show(false)
                            end
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    local vocationQuestList = {BSB,NUI,RESIDENT,FISHPACK}
                    local dailyIconList = {"ui/icon/icon_item_3493.dds","ui/icon/icon_skill_love06.dds","ui/icon/achievement/icon_achieve_0169.dds","ui/icon/arcustom/lucky_coin.dds"}
                    for i, eventName in ipairs(vocationQuestList) do
                        local data = eventDatas[eventName]
                        if data and data[1] and CS[i] then -- 注意这里访问 data[1]
                            button[i]:Show(true)
                            local questIds = data[1].questId or {} -- 访问第一个元素的 questId
                            local complete = 0
                            
                            if #questIds > 0 then
                                -- 计算完成的任务数量
                                for _, id in ipairs(questIds) do
                                    complete = complete + checkQuestComplete(id)
                                end
                                
                                local maxQuestNum = data[1].maxQuestNum or #questIds
                                button[i]:SetText(string.format("%s %s/%s", eventName, complete, maxQuestNum))
                            else
                                button[i]:SetText(string.format("%s %s", eventName, UNABLETOTRACK))
                            end
                        else
                            button[i]:Show(true)
                            button[i]:SetText(string.format("%s %s", eventName, "无数据"))
                        end
                    end
                    for i,iconPath in pairs(dailyIconList) do
                        if iconPath then
                            CSicon[i]:AddTexture(iconPath)
                            CSicon[i]:Show(true)
                        end
                    end
                end
            },
            {
                name = WEEKLY,
                func = function()
                    someTitle:SetText(WEEKLY)
                    questState = "weekly"
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:SetText("")
                            if CSicon[i] then
                                CSicon[i]:ClearAllTextures()
                                CSicon[i]:Show(false)
                            end
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    local weeklyQuestList = {HIRAMONE,WHM,EHM,IPY,GPW}
                    local dailyIconList = {"ui/icon/icon_item_4405.dds","ui/icon/icon_item_4443.dds","ui/icon/icon_item_4572.dds","ui/icon/icon_item_5136.dds","ui/icon/icon_item_5136.dds"}
                    for i, eventName in ipairs(weeklyQuestList) do
                        local data = eventDatas[eventName]
                        if data and data[1] and CS[i] then -- 注意这里访问 data[1]
                            button[i]:Show(true)
                            local questIds = data[1].questId or {} -- 访问第一个元素的 questId
                            local complete = 0
                            
                            if #questIds > 0 then
                                -- 计算完成的任务数量
                                for _, id in ipairs(questIds) do
                                    complete = complete + checkQuestComplete(id)
                                end
                                
                                local maxQuestNum = data[1].maxQuestNum or #questIds
                                button[i]:SetText(string.format("%s %s/%s", eventName, complete, maxQuestNum))
                            else
                                button[i]:SetText(string.format("%s %s", eventName, UNABLETOTRACK))
                            end
                        else
                            button[i]:Show(true)
                            button[i]:SetText(string.format("%s %s", eventName, "无数据"))
                        end
                    end
                    for i,iconPath in pairs(dailyIconList) do
                        if iconPath then
                            CSicon[i]:AddTexture(iconPath)
                            CSicon[i]:Show(true)
                        end
                    end
                end
            },
            {
                name = OTHERQUEST,
                func = function()
                    someTitle:SetText(OTHERQUEST)
                    questState = "others"
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:SetText("")
                            if CSicon[i] then
                                CSicon[i]:ClearAllTextures()
                                CSicon[i]:Show(false)
                            end
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    local otherQuestList = {WABOSS,LUSCA,ABYSSAL,AKASCH,PRAIRIE,GARDENBOSS,YNYSWORD,CINDERSWORD}
                    local dailyIconList = {"ui/icon/icon_item_4212.dds","ui/icon/icon_item_4212.dds","ui/icon/icon_item_4212.dds","ui/icon/icon_item_5136.dds","ui/icon/icon_item_5136.dds","ui/icon/icon_item_4828.dds","ui/icon/icon_item_3493.dds","ui/icon/icon_item_3493.dds"}
                    for i, eventName in ipairs(otherQuestList) do
                        local data = eventDatas[eventName]
                        if data and data[1] and CS[i] then -- 注意这里访问 data[1]
                            button[i]:Show(true)
                            local questIds = data[1].questId or {} -- 访问第一个元素的 questId
                            local complete = 0
                            
                            if #questIds > 0 then
                                -- 计算完成的任务数量
                                for _, id in ipairs(questIds) do
                                    complete = complete + checkQuestComplete(id)
                                end
                                
                                local maxQuestNum = data[1].maxQuestNum or #questIds
                                button[i]:SetText(string.format("%s %s/%s", eventName, complete, maxQuestNum))
                            else
                                button[i]:SetText(string.format("%s %s", eventName, UNABLETOTRACK))
                            end
                        else
                            button[i]:Show(true)
                            button[i]:SetText(string.format("%s %s", eventName, "无数据"))
                        end
                    end
                    for i,iconPath in pairs(dailyIconList) do
                        if iconPath then
                            CSicon[i]:AddTexture(iconPath)
                            CSicon[i]:Show(true)
                        end
                    end
                end
            },
            {
                name = NET_INCOME_TODY,
                func = function()
                    ResetStatsButton:Show(true)
                    someTitle:SetText(NET_INCOME_TODY)
                    is_in_Net = true
                    for i=1,8 do
                        if CS[i] then
                            CS[i]:Show(true)
                        end
                        if CSicon[i] then
                            CSicon[i]:ClearAllTextures()
                            CSicon[i]:Show(false) 
                        end
                        if button[i] then
                            button[i]:Show(false)
                        end
                        if mainPageButton[i] then
                            mainPageButton[i]:Show(false)
                        end
                    end
                    
                    if exp_today and CS[1] then
                        CS[1]:SetText(EXP .. tostring(exp_today)) 
                    end
                    if gold_today and CS[2] then
                        if tonumber(gold_today) >= 10000  then
                            local gold_today_in_gold = tonumber(gold_today) / 10000
                            CS[2]:SetText(GOLD .. tostring(gold_today_in_gold) .. GSTRING)
                        elseif tonumber(gold_today) > -10000 and tonumber(gold_today) < 10000 then
                            CS[2]:SetText(GOLD .. LESS_THAN_1G)
                        else
                            local gold_today_in_gold = tonumber(gold_today) / 10000
                            CS[2]:SetText(GOLD .. tostring(gold_today_in_gold .. GSTRING))
                        end
                    end
                    if vocation_today and CS[3] then
                        CS[3]:SetText(VOCATION .. tostring(vocation_today)) 
                    end
                    if honor_today and CS[4] then
                        CS[4]:SetText(HONOR .. tostring(honor_today)) 
                    end
                    for i =5,8 do
                        if CS[i] then
                            CS[i]:Show(false)
                        end
                    end
                end
            }
        }
        local timeUpdator = CreateEmptyWindow("timeUpdator", "UIParent")
        timeUpdator:Show(true)
        timeUpdator:AddAnchor("TOP", "UIParent", 0, -100)
        local ShowWidget = timeUpdator:CreateChildWidget("label", "ShowWidget", 10, true)
            ShowWidget:Show(true)
            ShowWidget:EnablePick(false)
            ShowWidget.style:SetColor(0, 0.7, 0.7, 1.0)
            ShowWidget.style:SetFontSize(26)
            ShowWidget.style:SetOutline(false)
            ShowWidget.style:SetAlign(ALIGN_CENTER)
            ShowWidget:AddAnchor("CENTER", timeUpdator,0, (UIParent:GetScreenHeight()/3)-100)
            ShowWidget:SetText("")
        local counter = 0
        warningCounter = 0
        function timeUpdator:OnUpdate(dt)
            if counter >= 1000 then
                counter = 0

                local serverTimeTable = UIParent:GetServerTimeTable()
                local month = serverTimeTable.month
                local day = serverTimeTable.day
                local playerName = X2Unit:UnitName("player")
                local today = tostring(month) .. tostring(day)
                if today == date_Today then
                    savePlayerData(month..day,playerName,gold_today,vocation_today,honor_today,exp_today)
                else
                    date_Today = today
                    -- 重置内存变量
                    gold_today = 0
                    vocation_today = 0
                    honor_today = 0
                    exp_today = 0
                    savePlayerData(today,playerName,0,0,0,0)
                end
                local showTable = {}
                if DisplayGuild == true then
                    local maxGuild = 0
                    local unlockedGuild = 0
                    local completeGuild = 0
                    for i=1,7 do
                        local guildInfo = X2Achievement:GetTodayAssignmentInfo(TADT_EXPEDITION, i)
                        if guildInfo then
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s",info))
                            if guildInfo.status == 1 then
                                maxGuild = maxGuild +1
                            elseif guildInfo.status == 2 then
                                maxGuild = maxGuild + 1
                                unlockedGuild = unlockedGuild + 1
                            elseif guildInfo.status == 3 then
                                maxGuild = maxGuild + 1
                                completeGuild = completeGuild + 1
                            end
                        end
                    end
                    if maxGuild ~= 0 then
                        if unlockedGuild == 0 and completeGuild == 0 then
                            table.insert(showTable,NO_GUILD_QUEST)
                        end
                    end
                end

                if DisplayDaily == true then
                    local maxDaily = 0
                    local unlockedDaily = 0
                    local completeDaily = 0
                    for i=1,7 do
                        local info = X2Achievement:GetTodayAssignmentInfo(TADT_TODAY, i)
                        if info then
                            if info.status == 1 then
                                maxDaily = maxDaily +1
                            elseif info.status == 2 then
                                maxDaily = maxDaily + 1
                                unlockedDaily = unlockedDaily + 1
                            elseif info.status == 3 then
                                maxDaily = maxDaily + 1
                                completeDaily = completeDaily + 1
                            end
                        end
                    end
                    if maxDaily ~= 0 then
                        if unlockedDaily == 0 and completeDaily == 0 then
                            table.insert(showTable,NO_UNLOCK_DAILY)
                        end
                    end
                end
                if DisplayCosUnd == true then
                    local noCos,noUnde = checkCostumeAndUnderwear()
                    if noCos == true then
                        table.insert(showTable,COS_EXPIRED)
                    end
                    if noUnde == true then
                        table.insert(showTable,UND_EXPIRED)
                    end
                end

                if DisplayStatus == true then
                    local Noblessing = checkBlessing()
                    if Noblessing == true then
                        table.insert(showTable,NOBLESSING)
                    end
                end

                local haveCert = false
                local haveQuest = false
                for i=0,150 do
                    local item = X2Bag:GetBagItemInfo(0, i)
                    if item and item.itemType == 46588 then
                        haveCert = true
                    end
                end
        
                local haveWhale = false
                local haveHalcy = false
                local WHgoingOn = false
                local haveFish = false
                local havePack = false
                local EndIn = 0
                local WHComplete = X2Quest:IsCompleted(9000220)
                local HALCYComplete = X2Quest:IsCompleted(9320)
                local fishComplete = X2Quest:IsCompleted(9000531)
                local packComplete = X2Quest:IsCompleted(9000226)
                local count = X2Quest:GetActiveQuestListCount()
                for i = 1, count do
                    local type1 = X2Quest:GetActiveQuestType(i)
                    if type1 == 9000220 then
                        haveWhale = true
                    elseif type1 == 9320 then
                        haveHalcy = true
                    elseif type1 == 9000226 then
                        havePack = true
                    elseif type1 == 9000531 then
                        haveFish = true
                    end
                end

                if DisplayFish == true and haveFish == false and fishComplete == false then
                    table.insert(showTable, NO_FISH_QUEST)
                end
                if DisplayPack == true and havePack == false and packComplete == false then
                    table.insert(showTable, NO_PACK_QUEST)
                end

                local zoneInfo = X2Map:GetZoneStateInfoByZoneId(103)
                if zoneInfo.conflictState == 5 then
                    EndIn = math.floor(zoneInfo.remainTime/60) +15
                    WHgoingOn = true
                elseif zoneInfo.conflictState == 6 and zoneInfo.remainTime >= 4500 then
                    EndIn = math.floor((zoneInfo.remainTime - 4500)/60)
                    WHgoingOn = true
                end

                if WHgoingOn == true and WHComplete == false and DisplayWH == true then
                    table.insert(showTable, WHBoss .. tostring(EndIn) .. ((language == "zh_cn") and "分" or " min"))
                    if haveWhale == false then
                        table.insert(showTable, NO_WH_QUEST)
                    end
                end

                if haveCert == true and haveHalcy == false and HALCYComplete == false and DisplayHalcy == true then
                    if warningCounter <= 2 then
                        warningCounter = warningCounter +1
                        X2Chat:DispatchChatMessage(CMF_SYSTEM, INFOADDON .. ":" .. NO_HALCY_QUEST)
                    end
                    table.insert(showTable, NO_HALCY_QUEST)
                end

                if showTable[1] and showTable[1] ~= nil then
                    ShowWidget:Show(true)
                    local string = ""
                    for _,Content in pairs(showTable) do
                        if Content ~= nil then
                            string = string .. Content .. " "
                        end
                    end
                    ShowWidget:SetText(string)
                else
                    ShowWidget:Show(false)
                    ShowWidget:SetText("")
                end

                if DisplayWidget == false then
                    ShowWidget:Show(false)
                    ShowWidget:SetText("")
                end

                if is_in_Net == true then
                    if exp_today and CS[1] then
                        CS[1]:SetText(EXP .. tostring(exp_today)) 
                    end
                    if gold_today and CS[2] then
                        if tonumber(gold_today) >= 10000  then
                            local gold_today_in_gold = tonumber(gold_today) / 10000
                            CS[2]:SetText(GOLD .. tostring(gold_today_in_gold) .. GSTRING)
                        elseif tonumber(gold_today) > -10000 and tonumber(gold_today) < 10000 then
                            CS[2]:SetText(GOLD .. LESS_THAN_1G)
                        else
                            local gold_today_in_gold = tonumber(gold_today) / 10000
                            CS[2]:SetText(GOLD .. tostring(gold_today_in_gold .. GSTRING))
                        end
                    end
                    if vocation_today and CS[3] then
                        CS[3]:SetText(VOCATION .. tostring(vocation_today)) 
                    end
                    if honor_today and CS[4] then
                        CS[4]:SetText(HONOR .. tostring(honor_today)) 
                    end
                    for i =5,8 do
                        if CS[i] then
                            CS[i]:Show(false)
                        end
                    end
                end
            else
                counter = counter + dt
            end
        end
        timeUpdator:SetHandler("OnUpdate", timeUpdator.OnUpdate)
        -- 创建按钮并分配函数
        local function CreateButtonsWithConfig()
            for i, config in ipairs(buttonConfigs) do
                local button = showWindow:CreateChildWidget("button", "configButton_" .. i, 0, true)
                button:SetText(config.name)
                button:SetExtent(buttonX * scale,buttonY*scale)
                button:AddAnchor("TOP", showWindow, 0, 75+(i - 1) * 35)
                button:Show(true)
                button.style:SetFontSize(16)
                --button.style:SetAlign(ALIGN_RIGHT)
                local color = UIParent:GetFontColor("brown")
                button:SetTextColor(color[1], color[2], color[3], color[4])
                -- 为每个按钮分配独立的函数
                function button:OnClick()
                    config.func()
                end
                button:SetHandler("OnClick", button.OnClick)
                mainPageButton[i] = button
            end
        end
        CreateButtonsWithConfig()
        local closeButton = showWindow:CreateChildWidget("button", "closeButton", 0, true)
        --closeButton:SetStyle("text_default")
        closeButton:AddAnchor("TOPRIGHT", showWindow,-10,10)
        closeButton:Show(true)
        closeButton:SetText("X")
        closeButton:SetExtent(45,30)
        local color = UIParent:GetFontColor("brown")
        closeButton:SetTextColor(color[1], color[2], color[3], color[4])

        function closeButton:OnClick()
            showWindow:Show(false)
            is_in_Net = false
        end
        closeButton:SetHandler("OnClick", closeButton.OnClick)

        local DailyQuestButton = showWindow:CreateChildWidget("button", "DailyQuestButton", 0, true)
        --DailyQuestButton:SetStyle("text_default")
        DailyQuestButton:AddAnchor("BOTTOMLEFT", showWindow,0,0)
        DailyQuestButton:Show(true)
        DailyQuestButton:SetText(MAINPAGE)
        DailyQuestButton:SetExtent(buttonX,buttonY)
        local color = UIParent:GetFontColor("brown")
        DailyQuestButton:SetTextColor(color[1], color[2], color[3], color[4])

        function DailyQuestButton:OnClick()
            for i=1,8 do
                if CS[i] then
                    CS[i]:Show(false)
                end
                if CSicon[i] then
                    CSicon[i]:Show(false)
                end
                if button[i] then
                    button[i]:Show(false)
                end
                if mainPageButton[i] then
                    mainPageButton[i]:Show(true)
                end
            end
            is_in_Net = false
            someTitle:SetText(INFOADDON .. MAINPAGE)
            ResetStatsButton:Show(false)
        end
        DailyQuestButton:SetHandler("OnClick", DailyQuestButton.OnClick)

        ResetStatsButton = showWindow:CreateChildWidget("button", "ResetStatsButton", 0, true)
        --DailyQuestButton:SetStyle("text_default")
        ResetStatsButton:AddAnchor("TOPLEFT", showWindow,0,0)
        ResetStatsButton:Show(false)
        ResetStatsButton:SetText(RESETSTATS)
        ResetStatsButton:SetExtent(buttonX-100,buttonY)
        local color = UIParent:GetFontColor("brown")
        ResetStatsButton:SetTextColor(color[1], color[2], color[3], color[4])

        function ResetStatsButton:OnClick()
            local serverTimeTable = UIParent:GetServerTimeTable()
            local month = serverTimeTable.month
            local day = serverTimeTable.day
            local playerName = X2Unit:UnitName("player")
            local today = tostring(month) .. tostring(day)
            gold_today = 0
            vocation_today = 0
            honor_today = 0
            exp_today = 0
            savePlayerData(today,playerName,0,0,0,0)
            if exp_today and CS[1] then
                CS[1]:SetText(EXP .. tostring(exp_today)) 
            end
            if gold_today and CS[2] then
                if tonumber(gold_today) >= 10000  then
                    local gold_today_in_gold = tonumber(gold_today) / 10000
                    CS[2]:SetText(GOLD .. tostring(gold_today_in_gold) .. GSTRING)
                elseif tonumber(gold_today) > -10000 and tonumber(gold_today) < 10000 then
                    CS[2]:SetText(GOLD .. LESS_THAN_1G)
                else
                    local gold_today_in_gold = tonumber(gold_today) / 10000
                    CS[2]:SetText(GOLD .. tostring(gold_today_in_gold .. GSTRING))
                end
            end
            if vocation_today and CS[3] then
                CS[3]:SetText(VOCATION .. tostring(vocation_today)) 
            end
            if honor_today and CS[4] then
                CS[4]:SetText(HONOR .. tostring(honor_today)) 
            end
            for i =5,8 do
                if CS[i] then
                    CS[i]:Show(false)
                end
            end
        end
        ResetStatsButton:SetHandler("OnClick", ResetStatsButton.OnClick)

        local SwitchWidgetButton = showWindow:CreateChildWidget("button", "SwitchWidgetButton", 0, true)
        --DailyQuestButton:SetStyle("text_default")
        SwitchWidgetButton:AddAnchor("BOTTOMRIGHT", showWindow,0,0)
        SwitchWidgetButton:Show(true)
        SwitchWidgetButton:SetText(CLOSEWIDGET)
        SwitchWidgetButton:SetExtent(buttonX,buttonY)
        local color = UIParent:GetFontColor("brown")
        SwitchWidgetButton:SetTextColor(color[1], color[2], color[3], color[4])

        function SwitchWidgetButton:OnClick()
            if DisplayWidget == false then
                DisplayWidget = true
                X2Chat:DispatchChatMessage(CMF_SYSTEM, OPENEDWIDGET)
            else
                DisplayWidget = false
                X2Chat:DispatchChatMessage(CMF_SYSTEM, CLOSEDWIDGET)
            end
        end
        SwitchWidgetButton:SetHandler("OnClick", SwitchWidgetButton.OnClick)

        showWindow:Enable(true)
        showWindow:Show(true)   
    end
    showWindow:Show(not showWindow:IsVisible())
end

local function CreateButton()
    if okButton ~= nil then
        return
    end

    okButton = UIParent:CreateWidget("button", "exampleButton", "UIParent", "")
    okButton:SetText(INFOADDON)

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
    --ApplyButtonSkin(okButton, buttonskin)
    --okButton:SetExtent(35,25)
    okButton:SetStyle("text_default")
    okButton:AddAnchor("CENTER", "UIParent", 0, 0)
    okButton:Show(true)
    --okButton.style:SetAlign(ALIGN_LEFT)

    okButton:EnableDrag(true)

    function okButton:OnDragStart()
        self:StartMoving()
        self.moving = true
    end
    okButton:SetHandler("OnDragStart", okButton.OnDragStart)
    function okButton:OnDragStop()
        self:StopMovingOrSizing()
        self.moving = false
        local offsetX, offsetY = self:GetOffset()
        local uiScale = UIParent:GetUIScale() or 1.0
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("%s",tostring(uiScale) or "error"))
        local normalizedX,normalizedY
        normalizedX = offsetX / uiScale
        normalizedY = offsetY / uiScale
        SaveWindowPosition(normalizedX, normalizedY)
    end
    okButton:SetHandler("OnDragStop", okButton.OnDragStop)
    local savedWindowX, savedWindowY = LoadSavedPosition()
    if savedWindowX ~= nil and savedWindowY ~= nil then
        local uiScale = UIParent:GetUIScale() or 1.0
        okButton:AddAnchor("TOPLEFT", "UIParent", savedWindowX*uiScale,savedWindowY*uiScale)
    end

    
    function okButton:OnClick()
        for i=1,8 do
            if CS[i] then
                CS[i]:Show(false)
            end
            if CSicon[i] then
                CSicon[i]:Show(false)
            end
            if button[i] then
                button[i]:Show(false)
            end
            if mainPageButton[i] then
                mainPageButton[i]:Show(true)
            end
        end

        ToggleEventWindow()
        someTitle:SetText(INFOADDON .. MAINPAGE)
        if ResetStatsButton then ResetStatsButton:Show(false) end
    end
    okButton:SetHandler("OnClick", okButton.OnClick)
end

local function EnteredWorld()
    CreateButton()
    checkCostumeAndUnderwear()
    checkBlessing()
    ToggleEventWindow()
    local playerName = X2Unit:UnitName("player")
    gold_today,vocation_today,honor_today,exp_today = loadPlayerData(playerName)
    X2Chat:DispatchChatMessage(CMF_SYSTEM, (language == "zh_cn") and string.format("成功加载信息插件，作者:奈奈呀，版本%s",version or "未知") or string.format("Loaded Info Tracker by Nevermore, Version %s",version or "N/A"))
    if ShowButton == false then
        okButton:AddAnchor("TOPLEFT", "UIParent", -100, -100)
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, EnteredWorld)


local function Leftloading()
    local zoneId = X2Unit:GetCurrentZoneGroup()
    if zoneId == 103 then
        local Complete = X2Quest:IsCompleted(9000220)
        local count = X2Quest:GetActiveQuestListCount()
        local haveWhale = false
        for i = 1, count do
            local type1 = X2Quest:GetActiveQuestType(i)
            if type1 == 9000220 then
                haveWhale = true
            end
        end
        if haveWhale == false and Complete == false then
            X2Chat:DispatchChatMessage(CMF_SYSTEM, INFOADDON .. ":" .. NO_WH_QUEST )
        end
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.LEFT_LOADING, Leftloading)

local function PlayerMoneyOutput(returnValue)
    if returnValue then
        gold_today = gold_today + returnValue
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("bag %s",tostring(gold_today)))
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.PLAYER_MONEY, PlayerMoneyOutput)

local function PlayerBankMoneyOutput(returnValue)
    if returnValue then
        gold_today = gold_today + returnValue
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("bank %s",tostring(gold_today)))
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.PLAYER_BANK_MONEY, PlayerBankMoneyOutput)

local function PlayerVocation(returnValue)
    if returnValue then
        vocation_today = vocation_today + returnValue
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("vocation %s",tostring(vocation_today)))
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.PLAYER_LIVING_POINT, PlayerVocation)

local function PlayerHonor(returnValue)
    if returnValue then
        honor_today = honor_today + returnValue
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("honor %s",tostring(honor_today)))
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.PLAYER_HONOR_POINT, PlayerHonor)

local function PlayerExp(nonsense,exp)
    if exp then
        exp_today = exp_today + tonumber(exp)
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("exp %s",tostring(exp_today)))
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.EXP_CHANGED, PlayerExp)
X2:AddEscMenuButton(4,1234,"tgos",(language == "zh_cn") and "信息插件" or "Info Addon")
ADDON:RegisterContentTriggerFunc(1234, ToggleEventWindow)
