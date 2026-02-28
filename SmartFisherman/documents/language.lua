ADDON:ImportAPI(API_TYPE.LOCALE.id)
local language = X2Locale:GetLocale() or "en_us"

titleText = "Fish!"
NOTARGET = "No Target"
DETECTING = "Detecting"
PRESS = "Press "
WAIT = "Please Wait..."
ADDON_SUCCESS = "Loaded smartfisherman by Nevermore,Version "
RESET = "Reset Key"
ADDON_NAME = "Fish Addon"

if language == "zh_cn" then
    titleText = "鱼来！"
    NOTARGET = "当前无目标"
    DETECTING = "识别中"
    PRESS = "按"
    WAIT = "请等待..."
    ADDON_SUCCESS = "成功加载钓鱼插件，作者:奈奈呀，版本"
    RESET = "重置键位"
    ADDON_NAME = "钓鱼插件"
end