require("common.logger.inspect_utils")

local FOREGROUND_BLUE      = 0x0001 -- text color contains blue.
local FOREGROUND_GREEN     = 0x0002 -- text color contains green.
local FOREGROUND_RED       = 0x0004 -- text color contains red.
local FOREGROUND_INTENSITY = 0x0008 -- text color is intensified.

local BACKGROUND_BLUE      = 0x0010 -- background color contains blue.
local BACKGROUND_GREEN     = 0x0020 -- background color contains green.
local BACKGROUND_RED       = 0x0040 -- background color contains red.
local BACKGROUND_INTENSITY = 0x0080 -- background color is intensified.

local Color_Debug = {
    ["LOG"]    = FOREGROUND_GREEN,
    ["TRACE"]  = FOREGROUND_GREEN,
    ["DEBUGS"] = FOREGROUND_GREEN,
    ["INFO"]   = FOREGROUND_RED + FOREGROUND_BLUE,
    ["WARN"]   = FOREGROUND_RED + FOREGROUND_GREEN,
    ["ERROR"]  = FOREGROUND_RED,
    ["FATAL"]  = FOREGROUND_RED,
}

DEBUG_LEVEL = DEBUG_LEVEL or 2

local logger = {_version = "1.0.0"}

logger.outfile = "log.txt"

function logger.setLogFile(file)
    logger.outfile = file
end

function logger.clearLog()
    local fp = io.open(logger.outfile, "w+")
    fp:close()
end

local _tostring = tostring
local function tostring(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if type(x) == "table" then
            x = inspect(x)
        elseif type(x) == "userdata" then
            local peer = tolua.getpeer(x)
            if peer and peer.class then
                x = "[USERDATA] [" .. peer.class.__cname .. "] " .. inspect(peer)
            else
                x = "[USERDATA] peer is nil"
            end
        end
        t[#t + 1] = _tostring(x)
    end
    return table.concat(t, " ")
end

-- 添加行信息输出
local function getLogFun(str)
    return function (...)
        if type(DEBUG_LEVEL) ~= "number" or DEBUG_LEVEL < 2 then
            return
        end

        -- 1. Output to console
        local debugInfo      = debug.getinfo(2, "Sl")
        local lineinfo       = debugInfo.short_src .. ":" .. debugInfo.currentline
        local lineAndMsgInfo = lineinfo .. ": " .. tostring(...)

        if SetConsoleTextAttribute then
            local old = SetConsoleTextAttribute(Color_Debug[str])

            print(string.format("[%s] [%s] %s",
                str:upper(), os.date("%H:%M:%S"), lineAndMsgInfo))

            SetConsoleTextAttribute(old)
        else
            print(string.format("[%s] [%s] %s",
                str:upper(), os.date("%H:%M:%S"), lineAndMsgInfo))
        end

        -- 2. Output to log file
        if logger.outfile and DEBUG_RECORD then
            local fp  = io.open(logger.outfile, "a")
            local str = string.format("[%s] [%s] %s\n",
                str:upper(), os.date(), lineAndMsgInfo)
            fp:write(str)
            fp:close()
        end
    end
end

function logMsg(...)
    if type(DEBUG_LEVEL) ~= "number" or DEBUG_LEVEL < 2 then
        return
    end

    local msg = tostring(...)

    -- 1. Output to console
    if SetConsoleTextAttribute then
        local old = SetConsoleTextAttribute(Color_Debug["ERROR"])

        print(string.format("[%s] %s", os.date("%H:%M:%S"), msg))

        SetConsoleTextAttribute(old)
    else
        print(string.format("[%s] %s", os.date("%H:%M:%S"), msg))
    end

    -- 2. Output to log file
    if logger.outfile and DEBUG_RECORD then
        local fp  = io.open(logger.outfile, "a")
        local str = string.format("[%s] %s\n", os.date(), msg)
        fp:write(str)
        fp:close()
    end
end

-- 输出调用logUP的方法的调用者信息
function logUp(...)
    if type(DEBUG_LEVEL) ~= "number" or DEBUG_LEVEL < 2 then
        return
    end

    -- 1. Output to console
    local debugInfo      = debug.getinfo(3, "Sl")
    local lineAndMsgInfo = nil
    if debugInfo then
        local lineinfo = debugInfo.short_src .. ":" .. debugInfo.currentline
        lineAndMsgInfo = lineinfo .. ": " .. tostring(...)
    else
        lineAndMsgInfo = "NO UP CALLER!!!" .. tostring(...)
    end

    if SetConsoleTextAttribute then
        local old = SetConsoleTextAttribute(Color_Debug['LOG'])

        print(string.format("[LOG UP] [%s] %s",
            os.date("%H:%M:%S"), lineAndMsgInfo))

        SetConsoleTextAttribute(old)
    else
        print(string.format("[LOG UP] [%s] %s",
            os.date("%H:%M:%S"), lineAndMsgInfo))
    end

    -- 2. Output to log file
    if logger.outfile and DEBUG_RECORD then
        local fp  = io.open(logger.outfile, "a")
        local str = string.format("[LOG UP] [%s] %s\n",
            os.date(), lineAndMsgInfo)
        fp:write(str)
        fp:close()
    end
end

function logBuff(buff)
    if type(DEBUG_LEVEL) ~= "number" or DEBUG_LEVEL < 2 then
        return
    end

    local len  = string.len(buff)
    local info = "buff length: " .. len .. ", buff contents:\n"
    -- 32, 126
    for i = 0, len - 1 do
        local bytes = string.byte(buff, i + 1)
        local chars = string.char(bytes)
        if bytes < 32 or bytes > 126 then
            chars = " "
        end
        info = info .. string.format("%3d-%3d(%s)\t", i, bytes, chars)
        if (i + 1) % 7 == 0 then
            info = info .. "\n"
        end
    end

    logUp(info)
end

-- 生成 log, TRACE,... FATAL等全局方法
log    = getLogFun("LOG")
TRACE  = getLogFun("TRACE")
DEBUGS = getLogFun("DEBUGS")
INFO   = getLogFun("INFO")
WARN   = getLogFun("WARN")
ERROR  = getLogFun("ERROR")
FATAL  = getLogFun("FATAL")

return logger