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
ADDON:ImportAPI(API_TYPE.PLAYER.id)
ADDON:ImportAPI(API_TYPE.SKILL.id)

local language = X2Locale:GetLocale()
local okButton = nil
local scale = UIParent:GetUIScale() or 1.0
local normalizedX = 0
local normalizedY = 0
local titleY = 20 
local titleFontSize = 25 
local buttonX = 150
local buttonY = 35
local buffIconExtent = 28*scale
local buffIconOffset = 1*scale
local playerName = X2Unit:UnitName("player")
local activecooldowns = {}
local debug = false
local maxDisplaySlots = 10
local lastUpdateTime = 0

version = "1.1"

local gradeText = {"poor","common","uncommon","rare","ancient","heroic","unique","artifact","wonder","epic","legendary","mythic","arche"}
--cooldown window
local cooldownWindow = CreateEmptyWindow("cooldownWindow","UIParent")
cooldownWindow:SetExtent(buffIconExtent,buffIconExtent)
cooldownWindow:AddAnchor("CENTER", "UIParent", 4*buffIconExtent, -3*buffIconExtent)
cooldownWindow:EnableDrag(false)
cooldownWindow:Show(true)

local background = cooldownWindow:CreateColorDrawable(0, 0, 0, 0, "background")
background:AddAnchor("TOPLEFT", cooldownWindow, 0, 0)
background:AddAnchor("BOTTOMRIGHT", cooldownWindow, 0, 0)


local function OnShow()
    if cooldownWindow.ShowProc ~= nil then
        cooldownWindow:ShowProc()
    end
    cooldownWindow:SetStartAnimation(true, true)
end
cooldownWindow:SetHandler("OnShow", OnShow)

-- 修改这部分，在创建图标的地方添加 gradeIcon
local item_icon = {}
local item_grade_icon = {}  -- 新增：存储品级图标
local item_cooldown_label = {}

for i=1 , maxDisplaySlots do --create icon and labels
    -- 主图标
    item_icon[i] = cooldownWindow:CreateIconDrawable("artwork")
    item_icon[i]:SetExtent(buffIconExtent, buffIconExtent)
    item_icon[i]:AddAnchor("TOPLEFT", cooldownWindow, (i-1)*(buffIconExtent-buffIconOffset), 0) 
    item_icon[i]:ClearAllTextures()
    item_icon[i]:SetVisible(false)

    -- 新增：品级图标（覆盖在主图标上）
    item_grade_icon[i] = cooldownWindow:CreateIconDrawable("artwork")
    item_grade_icon[i]:SetExtent(buffIconExtent, buffIconExtent)
    item_grade_icon[i]:AddAnchor("CENTER", item_icon[i], 0, 0)  -- 锚定到主图标中心
    item_grade_icon[i]:ClearAllTextures()
    item_grade_icon[i]:SetVisible(false)

    -- 冷却文字标签
    item_cooldown_label[i] = cooldownWindow:CreateChildWidget("label", "item_cooldown_label" .. i, 0, false)
    item_cooldown_label[i].style:SetFontSize(12)
    item_cooldown_label[i]:AddAnchor("BOTTOMLEFT", cooldownWindow, (buffIconExtent-buffIconOffset)/2 + (i-1)*(buffIconExtent-buffIconOffset), 0)
    item_cooldown_label[i].style:SetAlign(ALIGN_RIGHT)
    item_cooldown_label[i].style:SetColorByKey("white")
    item_cooldown_label[i]:SetText("")
    item_cooldown_label[i]:EnablePick(false)
    item_cooldown_label[i].style:SetOutline(true)
    item_cooldown_label[i].style:SetAlign(ALIGN_CENTER)
end

function getGradeIconPath(grade)
    if grade then
        local text = string.format("ui/icon/item_grade_%s%s.dds",tostring(grade),gradeText[grade+1])
        return text
    end
    return "ui/icon/item_grade_1common.dds"
end

local UpdateConfig = {}  -- 作为表，键是技能ID，值是配置

local function initUpdateConfig()
    UpdateConfig = {}  -- 清空
    for spellIdStr, v in pairs(config) do
        if v.update and v.update == true then
            UpdateConfig[spellIdStr] = v  -- 直接以ID为键存储
        end
    end
    
    if debug then
        local count = 0
        for _ in pairs(UpdateConfig) do count = count + 1 end
        if count > 0 then
            X2Chat:DispatchChatMessage(CMF_SYSTEM, 
                string.format("初始化API追踪配置，共 %d 个技能需要API更新", count))
        end
    end
end

-- 更新冷却显示
function updatecooldownDisplay()
    -- 将activecooldowns转换为数组并排序
    local sortedcooldowns = {}
    for spellId, data in pairs(activecooldowns) do
        table.insert(sortedcooldowns, {
            id = spellId,
            remaining = data.remaining,
            icon = data.icon,
            name = data.name or "未知",
            grade = data.grade or 1
        })
    end
    
    -- 按剩余时间排序（时间少的在前）
    table.sort(sortedcooldowns, function(a, b)
        return a.remaining < b.remaining
    end)
    
    -- 更新图标显示（最多显示10个）
    for i = 1, maxDisplaySlots do
        if sortedcooldowns[i] then
            local cooldown = sortedcooldowns[i]
            
            -- 设置图标
            item_icon[i]:ClearAllTextures()
            item_icon[i]:AddTexture("ui/icon/" .. cooldown.icon)
            item_icon[i]:Show(true)
            
            if cooldown.grade then
                -- 根据品级获取对应的品级图标
                local gradeIconPath = getGradeIconPath(cooldown.grade)
                item_grade_icon[i]:ClearAllTextures()
                item_grade_icon[i]:AddTexture(gradeIconPath)
                item_grade_icon[i]:Show(true)
            else
                item_grade_icon[i]:ClearAllTextures()
                item_grade_icon[i]:Show(false)
            end

            -- 设置冷却文本
            local remainTime = math.ceil(cooldown.remaining)
            local timeText = string.format("%d", remainTime)
            item_cooldown_label[i]:SetText(timeText)
            item_cooldown_label[i]:Show(true)
        else
            -- 清空未使用的槽位
            item_icon[i]:Show(false)
            item_grade_icon[i]:Show(false)
            item_cooldown_label[i]:SetText("")
        end
    end
end

function cooldownWindow:OnUpdate(dt)
    lastUpdateTime = lastUpdateTime + dt
    
    -- 每秒更新一次（避免频繁更新）
    if lastUpdateTime >= 1000 then
        lastUpdateTime = 0
        
        local needUpdate = false
        
        -- 遍历所有冷却中的技能
        for spellId, data in pairs(activecooldowns) do
            if data.remaining > 0 then
                data.remaining = data.remaining - 1
                needUpdate = true
                
                -- 检查是否冷却结束
                if data.remaining <= 0 then
                    if debug == true then
                        X2Chat:DispatchChatMessage(CMF_SYSTEM, 
                            string.format("测试：冷却结束: %s", data.name or "未知"))
                    end
                    activecooldowns[spellId] = nil  -- 移除冷却
                end
            end
        end
        
        for spellIdStr, info in pairs(UpdateConfig) do
            local spellId = tonumber(spellIdStr)
            if spellId then
                

                -- 使用X2Skill:GetCooldown检查冷却
                local currentCd, maxCd = X2Skill:GetCooldown(spellId, true)
                
                if currentCd and currentCd > 0 then
                    
                    -- 有冷却时间
                    local remainingSeconds = math.ceil(currentCd / 1000)  -- 毫秒转秒
                    -- 如果不在冷却表中，或冷却时间变化较大，则更新
                    local existingData = activecooldowns[spellIdStr]
                    if not existingData then
                        activecooldowns[spellIdStr] = {
                            remaining = remainingSeconds,   -- 剩余时间
                            total = info.cooldown or 0,      -- 总冷却时间
                            icon = info.icon, -- 图标
                            grade = info.grade or 1    
                        }
                        needUpdate = true
                        
                        if debug == true and not existingData then
                            X2Chat:DispatchChatMessage(CMF_SYSTEM, 
                                string.format("API检测到冷却: %s - %d秒", 
                                activecooldowns[spellIdStr].name, remainingSeconds))
                        end
                    end
                else
                    -- 没有冷却，如果之前在冷却表中则移除
                    if activecooldowns[spellIdStr] then
                        if debug == true then
                            X2Chat:DispatchChatMessage(CMF_SYSTEM, 
                                string.format("API技能冷却结束: %s", 
                                activecooldowns[spellIdStr].name))
                        end
                        activecooldowns[spellIdStr] = nil
                        needUpdate = true
                    end
                end
            end
        end

        -- 如果需要更新显示
        if needUpdate then
            updatecooldownDisplay()
        end
    end
end
cooldownWindow:SetHandler("OnUpdate", cooldownWindow.OnUpdate)

local function EnteredWorld()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, (language == "zh_cn") and string.format("成功加载技能冷却插件，作者:奈奈呀，版本%s",version or "未知") or string.format("Loaded Cooldown Tracker by Nevermore, Version %s",version or "N/A"))
    -- 初始化API追踪配置
    initUpdateConfig()
end
UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, EnteredWorld)

local function cooldownHandler(...)
    local _, eventType, casterName, _, spellId, spellName, _ = ...
    
    if casterName == playerName then
        if eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED" then
            local spellIdStr = tostring(spellId)
            
            if config[spellIdStr] then
                local info = config[spellIdStr]
                local needUpdate = config[spellIdStr].update
                if not needUpdate or needUpdate == false then
                    -- 添加到冷却表
                    activecooldowns[spellIdStr] = {
                        remaining = info.cooldown,  -- 剩余时间
                        total = info.cooldown,      -- 总冷却时间
                        icon = info.icon,          -- 图标
                        name = spellName,           -- 技能名
                        grade = info.grade or 1
                    }
                    
                    if debug == true then
                        X2Chat:DispatchChatMessage(CMF_SYSTEM, 
                            string.format("测试：开始冷却: %s - %s秒", spellName, info.cooldown))
                    end
                else
                    X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("测试：试图更新api冷却，已驳回"))
                end
                -- 更新显示
                updatecooldownDisplay()
            end
        end
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.COMBAT_MSG, cooldownHandler)

local function TestSimple(...)
    local args = { ... }
    local count = select("#", ...)
    local msg = string.format("参数(%d): ", count)
    if args[3] == playerName then --args[2] == "SPELL_CAST_SUCCESS" and 
        for i=1, count do
            msg = msg .. string.format("[%s] ", tostring(select(i, ...)))
        end
        if debug == true then
            X2Chat:DispatchChatMessage(CMF_SYSTEM, msg)
        end
    end
end
UIParent:SetEventHandler(UIEVENT_TYPE.COMBAT_MSG, TestSimple)