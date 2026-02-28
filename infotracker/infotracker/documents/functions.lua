ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)
function formatTime(s)
    local min = math.floor(s/60)
    if min > 0 then
        return string.format("%d分",min)
    else
        return string.format("小于1分")
    end
end

function processTable(t, parentKey)
    for k, v in pairs(t) do
        -- 构建当前键的完整路径（例如 "parent.child"）
        local currentKey = parentKey and (parentKey .. "." .. tostring(k)) or tostring(k)
        
        if type(v) == "table" then
            -- 如果是嵌套 Table，递归处理
            processTable(v, currentKey)
        else
            -- 将值转换为字符串，处理布尔值和 nil
            local valueStr
            if v == nil then
                valueStr = "unknown"
            else
                valueStr = tostring(v)  -- 显式转换布尔值/数字为字符串
            end

            -- 发送格式化消息
            local message = string.format("%s => %s", currentKey, valueStr)
            X2Chat:DispatchChatMessage(CMF_SYSTEM, message)
        end
    end
end

function checkForDevelopment(zoneTable,tableName)
    if type(zoneTable) == "table" then
        local outputString = ""
        for _,zoneId in pairs(zoneTable) do
            local info = X2Map:GetZoneStateInfoByZoneId(zoneId)
            if info.zoneName and info.localDevelopmentStep then
                if info.localDevelopmentStep == 3 then
                    --outputString = string.format(outputString .. info.zoneName .. " ")
                    return tableName .. ":" .. info.zoneName
                end
            end
        end

        if outputString == "" or outputString == nil then
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format(tableName .. ":" .. "暂未有三阶段"))
            return tableName .. ":" .. NOSTAGETHREE
        else
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format(tableName .. ":" .. outputString))
            return tableName .. ":" .. outputString
        end
    end
end

function checkCostumeAndUnderwear()
    -- 检查时装
    local costume = false
    local under = false
    local costumeInfo = X2Equipment:GetEquippedItemTooltipInfo(ES_COSPLAY, false)
    if costumeInfo and costumeInfo.evolvingInfo and costumeInfo.evolvingInfo.remainTime then
        local remainTime = costumeInfo.evolvingInfo.remainTime
        if remainTime.year == 0 and remainTime.month == 0 and remainTime.day == 0 and
           remainTime.hour == 0 and remainTime.minute == 0 and remainTime.second == 0 then
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, "信息插件：你的时装已过期")
            costume = true
        end
    end

    -- 检查内衣
    local underwearInfo = X2Equipment:GetEquippedItemTooltipInfo(ES_UNDERPANTS, false)
    if underwearInfo and underwearInfo.evolvingInfo and underwearInfo.evolvingInfo.remainTime then
        local remainTime = underwearInfo.evolvingInfo.remainTime
        if remainTime.year == 0 and remainTime.month == 0 and remainTime.day == 0 and
           remainTime.hour == 0 and remainTime.minute == 0 and remainTime.second == 0 then
            --X2Chat:DispatchChatMessage(CMF_SYSTEM, "信息插件：你的内衣已过期")
            under = true
        end
    end
    return costume,under
end

function checkBlessing()
    local blessingId = {30766,30767,30768,30771,30773,9002338,9002340,9002342,9002337,9002339,902341,30760,30764,30765,30770,30772}
    local buffCount = X2Unit:UnitBuffCount("player")
    local haveBlessing = false   
    for i = 1, buffCount do
        local buffInfo = X2Unit:UnitBuff("player", i)
        local buffId = buffInfo["buff_id"]
        for j=1,#blessingId do
            if buffId == blessingId[j] then
                haveBlessing = true
            end
        end
    end
    if haveBlessing == false then
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, "信息插件：你未获得国王雕像Buff")
        return true
    end
    return false
end

function checkQuestComplete(id)
    if id and id ~= nil then
        local complete = X2Quest:IsCompleted(id)
        if complete == true then
            return 1
        else
            return 0
        end
    end
end

local filePath = "TimeBut.txt"
function SaveWindowPosition(x, y)
    if not x or not y then
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("错误的位置"))
        return
    end
    local file = io.open(filePath, "w")
    if not file then
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("无法打开文件%s",filePath))
        return
    end
    
    file:write(string.format("%d,%d", x, y))
    file:close()
end
function LoadSavedPosition()
    local file = io.open(filePath, "r")
    if not file then
        return nil,nil
    end
    if file then
        local line = file:read("*line")
        file:close()
        if not line then
            return nil,nil
        end
        local x,y = line:match("(%d+),(%d+)")
        if x and y then
            return tonumber(x),tonumber(y)
        else
            return nil,nil
        end
    end
end


function savePlayerData(date,name,gold,vocation,honor,exp)
    --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("calledSave"))
    local filepath = string.format("%s.txt",name)
    local file = io.open(filepath, "w")
    file:write(string.format('["%s"] = "date"\n', tostring(date) or "0"))
    file:write(string.format('["%s"] = "gold"\n', tostring(gold) or "0"))
    file:write(string.format('["%s"] = "vocation"\n', tostring(vocation) or "0"))
    file:write(string.format('["%s"] = "honor"\n', tostring(honor) or "0"))
    file:write(string.format('["%s"] = "exp"\n', tostring(exp) or "0"))
    file:close()
end

function loadPlayerData(name)
    --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("calledLoad"))
    local serverTimeTable = UIParent:GetServerTimeTable()
    local month = serverTimeTable.month
    local day = serverTimeTable.day
    local filePath = string.format("%s.txt",name)
    local file = io.open(filePath, "r")
    local rGold,rVocation,rHonor,rExp = 0,0,0,0
    local currentDate = tostring(month) .. tostring(day)
    
    if file then
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("load find file"))
        for line in file:lines() do
            -- 修改正则表达式以匹配可能包含负号的数字
            local value, name = line:match('%["([%-%d]+)"%]%s*=%s*"(.-)"')
            if value and name then
                if name == "date" then
                    if value == currentDate then
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("match the date! %s",tostring(value)))
                    else
                        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("New Day! Data wiped %s",tostring(value)))
                        local playerName = X2Unit:UnitName("player")
                        savePlayerData(currentDate,playerName,0,0,0,0)
                        return 0,0,0,0
                    end
                elseif name == "gold" then
                    rGold = tonumber(value) or 0
                elseif name == "vocation" then
                    rVocation = tonumber(value) or 0
                elseif name == "honor" then
                    rHonor = tonumber(value) or 0
                elseif name == "exp" then
                    rExp = tonumber(value) or 0
                end
            end
        end
        file:close()
        return rGold,rVocation,rHonor,rExp
    else
        --X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("no file!"))
        local playerName = X2Unit:UnitName("player")
        savePlayerData(currentDate,playerName,0,0,0,0)
        return 0,0,0,0
    end
end