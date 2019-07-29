local function clearLoadedFiles()
    for k, v in pairs(package.loaded) do
        if string.sub(k, 1, 6) == "common" then
            package.loaded[k] = nil
        elseif string.sub(k, 1, 5) == "logic" then
            package.loaded[k] = nil
        elseif string.sub(k, 1, 7) == "modules" then
            package.loaded[k] = nil
        elseif string.sub(k, 1, 3) == "net" then
            package.loaded[k] = nil
        elseif string.sub(k, 1, 5) == "scene" then
            package.loaded[k] = nil
        end
    end
end
clearLoadedFiles()

require("common.serialization")
require("common.CocosEx")
require("common.logger.logger")
AudioManager = require("common.AudioManager"):create()
require("common.UtilityTools")
require("common.FuncEx")

require("common.NativeUtil")
require("common.ErrNo")
require("common.ErrStrToClient")
require("common.GameConfig")
require("common.GameGlobal")
require("common.ProfileManager")
require("common.SpeekMgr")
require("common.EventEnum")
require("common.EventBus")
NetCmd = require("common.NetCmd")

gt = gt or {}

-- export global variable
local __g = _G
GV        = {}
setmetatable(GV, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

-- disable create unexpected global variable
local function disable_global()
    setmetatable(__g, {
        __newindex = function(_, name, value)
            error(string.format("USE \" GV.%s = value \" INSTEAD OF SET GLOBAL VARIABLE", name), 2)
        end
    })
end

-- require("common.CocosFuncRedirect")

-- disable_global()

GV.IS_WINDOWS = "\\" == package.config:sub(1, 1)

local function genIdMap(gt)
    local idMap = {}
    for k, v in pairs(gt) do
        if type(v) == "number" then
            idMap[v] = k
        end
    end
    return idMap
end

-- 消息类型
gt.idMap = genIdMap(NetCmd)

local rawJsonEncode2 = json.encode2
json.encode2 = function(data)
    local cmdCode = nil
    local sendStr = ""
    if type(data) == "table" then
        for i, v in ipairs(data) do
            if v.cmd then
                logUp("send2-->>: ", data)
                cmdCode = v.cmd
                sendStr = rawJsonEncode2(data)
                break
            end
        end
    elseif type(data) == "string" then
        cmdCode = 0
        sendStr = data
    end
    if cmdCode then
        return sendStr, cmdCode
    else
        return sendStr
    end
end

local rawJsonEncode = json.encode
json.encode = function(data)
    local cmdCode = nil
    local sendStr = ""
    if type(data) == "table" then
        if data.cmd then
            logUp("send-->>: ", data)
            cmdCode = data.cmd
        end
        sendStr = rawJsonEncode(data)
    elseif type(data) == "string" then
        cmdCode = 0
        sendStr = data
    end
    if cmdCode then
        return sendStr, cmdCode
    else
        return sendStr
    end
end

local rawJsonDecode = json.decode
json.decode = function(data, isNetMsg)
    local jsonData = nil
    local pFunc = function()
        jsonData = rawJsonDecode(data)
    end

    local ok, errMsg = xpcall(pFunc, function(errorMessage)
        local str    = tostring(errorMessage) .. debug.traceback("", 6)
        local errStr = string.format("json.decode(data) fail errMsg = %s.\n json data = '%s'", tostring(str), tostring(data))
        gt.uploadErr(errStr)

        if buglyReportLuaException then
            -- report lua exception
            local errStr = string.format("json.decode(data) fail errMsg = %s.\n json data = %s", errorMessage, tostring(data))
            buglyReportLuaException(tostring(errStr), debug.traceback())
        end
    end)

    if ok then
        if jsonData and type(jsonData) == "table" and jsonData.cmd then
            if isNetMsg then
                logUp("rcv-->>: ", jsonData)
            end
        elseif not jsonData then
            local errStr = string.format("json.decode(data) fail, result is nil, json data = %s", tostring(data))
            gt.uploadErr(errStr)

            if buglyReportLuaException then
                -- report lua exception
                buglyReportLuaException(tostring(errStr), debug.traceback())
            end
        end
    else
        local errStr = string.format("json.decode(data) fail. json data = %s", tostring(data))
        gt.uploadErr(errStr)

        if buglyReportLuaException then
            -- report lua exception
            buglyReportLuaException(tostring(errStr), debug.traceback())
        end
    end

    return jsonData
end

local function uploadCount(key)
    local log_url = gt.getConf("log_url")
    local game    = "ylqj"
    local version = cc.UserDefault:getInstance():getStringForKey("UpdateVersion", "1.0.0")
    local url     = string.format("%s/count?key=%s&version=%s&game=%s", log_url, key, version, game)
    ymkj.UrlPool:instance():reqHttpGet("upload_key_count", url)
end
gt.uploadCount = uploadCount

local function setRoomID(roomID)
    gt.roomID = roomID
end
gt.setRoomID = setRoomID

local function getRoomID()
    return gt.roomID
end
gt.getRoomID = getRoomID

local function setClubID(clubID)
    gt.clubID = clubID
end
gt.setClubID = setClubID

local function getClubID()
    return gt.clubID
end
gt.getClubID = getClubID

local function getNetStauts()
    local signal       = tonumber(gt.signalStrength) or 3
    local networktType = tonumber(gt.networktType) or 1
    if networktType == -1 then
        return "nosignal"
    elseif networktType == 1 then
        if signal >= 0 and signal <= 3 then
            return string.format("wifi%d", signal)
        end
    elseif networktType >= 2 and networktType <= 4 then
        return string.format("%dg", networktType)
    end
    return "nosignal"
end
gt.getNetStauts = getNetStauts

local function uploadErr(errStr, noTraceback)
    if not noTraceback then
        local msg = debug.traceback(2)
        errStr    = errStr .. "\n" .. tostring(msg)

        ERROR(errStr)
    else
    end
    if g_os == "win" then return end
    local md5     = require("common.md5")
    local game    = package_name or "ylqj"
    local md      = md5.sumhexa(errStr)
    local version = cc.UserDefault:getInstance():getStringForKey("UpdateVersion", "1.0.0")
    -- UID
    local uid     = gt.getData("uid") or cc.UserDefault:getInstance():getStringForKey("uid", "")
    local date    = os.date("*t", os.time());
    --date = {year = 2017, month = 8, day = 22, yday = 234, wday = 3,
    --        hour = 10, min = 46, sec = 52, isdst = false}
    local time    = string.format("%s%s%s-%s:%s:%s",date.year,date.month,date.day,date.hour,date.min,date.sec)
    -- 房间号
    local roomID  = tostring(gt.getRoomID())
    -- 群主号
    local clubID  = tostring(gt.getClubID())
    -- 机型
    local osType  = tostring(g_os)
    -- 网络状态
    local netStaus = gt.getNetStauts()
    local extra = string.format("uid=%s|time=%s|roomID=%s|clubID=%s|osType=%s|netStaus=%s",uid,time,roomID,clubID,osType,netStaus)
    local log_url = gt.getConf("log_url")
    local url     = string.format("%s?game=%s&md=%s&version=%s&content=%s&extra=%s", log_url, game, md, version, gt.urlEncode(errStr), extra)
    ymkj.UrlPool:instance():reqHttpGet("upload_log", url)
end
gt.uploadErr = uploadErr

-- 输出程序运行异常堆栈
__G__TRACKBACK__ = function (errorMessage)
    logMsg("---------------- 调用堆栈开始 ----------------")
    local str = tostring(errorMessage) .. debug.traceback("", 2)
    logMsg("LUA ERROR: " .. str)
    logMsg("---------------- 调用堆栈结束 ----------------")
    gt.uploadErr(str, true)

    if buglyReportLuaException then
        -- report lua exception
        buglyReportLuaException(tostring(errorMessage), debug.traceback())
    end

    return str
end