local UserDefault                        = cc.UserDefault:getInstance()
local RedirectUserDefaultSetStringForKey = UserDefault.setStringForKey
function UserDefault.setStringForKey(self, key, value)
    if not key or #key == 0 or not value then
        local msg = string.format('UserDefault:setStringForKey [k] = [%s],[v] = [%s]', tostring(key), tostring(value))
        logMsg('------调用cc.UserDefault:getInstance():setStringForKey出错------')
        logUp(msg)
        logMsg('------调用cc.UserDefault:getInstance():setStringForKey出错------')
        if g_os == "win" then
            error('写入 UserDefault 失败', 1)
        end
        gt.uploadErr(msg)
        return
    end
    RedirectUserDefaultSetStringForKey(self, key, value)
end

local RedirectUserDefaultSetBoolForKey = UserDefault.setBoolForKey
function UserDefault.setBoolForKey(self, key, value)
    if not key or #key == 0 or not value then
        local msg = string.format('UserDefault:setStringForKey [k] = [%s],[v] = [%s]', tostring(key), tostring(value))
        logMsg('------调用cc.UserDefault:getInstance():setBoolForKey------')
        logUp(msg)
        logMsg('------调用cc.UserDefault:getInstance():setBoolForKey------')
        gt.uploadErr(msg)
        if g_os == "win" then
            error('写入 UserDefault 失败', 1)
        end
        return
    end
    RedirectUserDefaultSetBoolForKey(self, key, value)
end

local RedirectUserDefaultSetIntegerForKey = UserDefault.setIntegerForKey
function UserDefault.setIntegerForKey(self, key, value)
    if not key or #key == 0 or not value then
        local msg = string.format('UserDefault:setStringForKey [k] = [%s],[v] = [%s]', tostring(key), tostring(value))
        logMsg('------调用cc.UserDefault:getInstance():setIntegerForKey------')
        logUp(msg)
        logMsg('------调用cc.UserDefault:getInstance():setIntegerForKey------')
        gt.uploadErr(msg)
        if g_os == "win" then
            error('写入 UserDefault 失败', 1)
        end
        return
    end
    RedirectUserDefaultSetIntegerForKey(self, key, value)
end

local RedirectUserDefaultSetFloatForKey = UserDefault.setFloatForKey
function UserDefault.setFloatForKey(self, key, value)
    if not key or #key == 0 or not value then
        local msg = string.format('UserDefault:setStringForKey [k] = [%s],[v] = [%s]', tostring(key), tostring(value))
        logMsg('------调用cc.UserDefault:getInstance():setFloatForKey------')
        logMsg('写入失败')
        logUp(msg)
        logMsg('------调用cc.UserDefault:getInstance():setFloatForKey------')
        gt.uploadErr(msg)
        if g_os == "win" then
            error('写入 UserDefault 失败', 1)
        end
        return
    end
    RedirectUserDefaultSetFloatForKey(self, key, value)
end