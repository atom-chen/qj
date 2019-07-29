local device = require("cocos.framework.device")

local util = {}

function util:clearLoadedFiles()
    local fold_list = {"club","common","launcher","logic","modules","net","scene"}
    for i,v in ipairs(fold_list) do
        for k, m in pairs(package.loaded) do
            if string.sub(k, 1, #v) == v then
                package.loaded[k] = nil
            end
        end
    end
    cc.SpriteFrameCache:getInstance():removeSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeAllTextures()
end

-- 添加自定义事件监听器
function util:addCustomEventListener(event, callback)
    local closure = function(customEvent)
        local msg = customEvent:getUserData()
        callback(msg)
    end
    local listener = cc.EventListenerCustom:create(event, closure)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
end

function util:showTip(msg,callfunc)
    local TipLayer = require("launcher.TipLayer")
    local runScene = cc.Director:getInstance():getRunningScene()
    local layer = runScene:getChildByName("TipLayer")
    if layer then
        layer:removeSelf()
    end
    layer = TipLayer:create(msg,callfunc)
    runScene:addChild(layer,99999)
end

function util:uploadErr(errStr, noTraceback)
    if not noTraceback then
        local msg = debug.traceback(2)
        errStr    = errStr .. "\n" .. tostring(msg)
    end
    if device.platform == "windows" then return end
    local md5       = require("launcher.md5")
    local game      = package_name or "ylqj"
    local md        = md5.sumhexa(errStr)
    local version   = cc.UserDefault:getInstance():getStringForKey("UpdateVersion", "1.0.0")
    local uid       = cc.UserDefault:getInstance():getStringForKey("uid", "")
    local date      = os.date("*t", os.time())
    --date = {year = 2017, month = 8, day = 22, yday = 234, wday = 3,
    --        hour = 10, min = 46, sec = 52, isdst = false}
    local time      = string.format("%s%s%s-%s:%s:%s",date.year,date.month,date.day,date.hour,date.min,date.sec)
    local ip        = g_client_ip or ""
    local lonlat    = cc.UserDefault:getInstance():getStringForKey("lonlat","0;0")
    local extra     = string.format("uid=%s|time=%s|ip=%s|os=%s|lonlat=%s",uid,time,ip,device.platform,lonlat)
    local cfg       = require("launcher.cfg")
    local log_url   = cfg:getConf("log_url")
    local url       = string.format("%s?game=%s&md=%s&version=%s&content=%s&extra=%s", log_url, game, md, version, string.urlencode(errStr),extra)
    ymkj.UrlPool:instance():reqHttpGet("upload_log", url)
    print("uploadErr",url)
end

-- 输出程序运行异常堆栈
__G__TRACKBACK__ = function (errorMessage)
    print("---------------- 调用堆栈开始 ----------------")
    local str = tostring(errorMessage) .. debug.traceback("", 2)
    print("LUA ERROR: " .. str)
    print("---------------- 调用堆栈结束 ----------------")
    util:uploadErr(str, true)
    return str
end

return util