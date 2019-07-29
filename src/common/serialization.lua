--[[
Title: serialization functions in commonlib
Author(s): LiXizhi, Andy @ParaEngine
Date: 2006/11/25
Desc: serialization functions in commonlib
Use Lib:
-------------------------------------------------------
require "script/ide/commonlib.lua"
-- include commonlib to use this lib
require "script/ide/serialization.lua"
-------------------------------------------------------
]]

if(not commonlib) then commonlib = {}; end
local commonlib = commonlib;

local tostring      = tostring
local tonumber      = tonumber
local type          = type
local string_format = string.format;
local pairs         = pairs
local ipairs        = ipairs
local log           = log;

-- output input to log safely in a single echo line. Only used in debugging or testing
-- Internally it uses commonlib.dump which handles recursive tables.
-- @param p1: anything to echo, table, nil, value, function, etc.
-- @param handleRecursion: if true, table recursion is handled. it may cause stack overflow if set to nil with recursive table
function commonlib.echo(p1, handleRecursion)
    print("echo:")

    print(commonlib.serialize_compact2(p1))

    do return end

    if(handleRecursion) then
        commonlib.log.log_long(commonlib.dump(p1, nil, not handleRecursion))
    else
        -- commonlib.log.log_long(commonlib.serialize(p1));
        commonlib.log.log_long(commonlib.serialize_compact(p1)); -- this will print in a single line(good for log search)
    end
    print("\n")
end

function commonlib.enjson(o)
    return commonlib.serialize_compact2(o)
end
-- -- shortcut
-- echo = commonlib.echo;

--[[ serialize a table to the current file: function and user data are exported as nil value.
@param o: table to serialize
]]
function commonlib.serializeToFile(file, o)
    local obj_type = type(o)
    if obj_type == "number" then
        file:WriteString(tostring(o))
    elseif obj_type == "string" then
        file:WriteString(string_format("%q", o))
    elseif obj_type == "boolean" then
        if(o) then
            file:WriteString("true")
        else
            file:WriteString("false")
        end
    elseif obj_type == "table" then
        file:WriteString("{\r\n")

        local k, v
        for k, v in pairs(o) do
            file:WriteString("[")
            commonlib.serializeToFile(file, k)
            file:WriteString("]=")
            commonlib.serializeToFile(file, v)
            file:WriteString(",\r\n")
        end

        -- local i;
        -- for i,v in ipairs(o) do
        -- file:WriteString( string_format("  [%d] = ",i) )
        -- commonlib.serializeToFile(file, v)
        -- file:WriteString(",\r\n")
        -- end

        file:WriteString("}\r\n")
    elseif obj_type == "function" then
        file:WriteString("nil")
    elseif obj_type == "userdata" then
        file:WriteString("nil")
    else
        log("--cannot serialize a " .. obj_type.."\r\n")
    end
end

-- serialize to string.
-- e.g. print(commonlib.serialize(o))
-- @param o: the object to serialize
-- @param bBeautify: if true, it will generate with line breakings. if nil, it will use the C++ function to serialize.
function commonlib.serialize(o, bBeautify)
    if(not bBeautify) then
        return NPL.SerializeToSCode("", o);
    else
        local obj_type = type(o)
        if obj_type == "number" then
            return (tostring(o))
        elseif obj_type == "nil" then
            return ("nil")
        elseif obj_type == "string" then
            return (string_format("%q", o))
        elseif obj_type == "boolean" then
            if(o) then
                return "true"
            else
                return "false"
            end
        elseif obj_type == "function" then
            return (tostring(o))
        elseif obj_type == "userdata" then
            return ("nil")
        elseif obj_type == "table" then
            local str = "{\r\n"
            local k, v
            for k, v in pairs(o) do
                str = str..("[")..commonlib.serialize_compact3(k) .. "]="..commonlib.serialize(v, true) .. ",\r\n"
            end
            str = str.."}\r\n";
            return str
        else
            log("--cannot serialize a " .. obj_type.."\r\n")
        end
    end
end

-- this is the fatest serialization method using native API.
function commonlib.serialize_compact(o)
    return NPL.SerializeToSCode("", o);
end

-- same as commonlib.serialize, except that it is more compact by removing all \r\n and comments, etc.
function commonlib.serialize_compact3(o)
    local obj_type = type(o)
    if obj_type == "number" then
        return (tostring(o))
    elseif obj_type == "nil" then
        return ("nil")
    elseif obj_type == "string" then
        return (string_format("%q", o))
    elseif obj_type == "boolean" then
        if(o) then
            return "true"
        else
            return "false"
        end
    elseif obj_type == "table" then
        local str = "{"
        local k, v
        for k, v in pairs(o) do
            str = str..("[")..commonlib.serialize_compact(k) .. "]=" .. (commonlib.serialize_compact(v) or "nil") .. ","
        end
        str = str.."}";
        return str
    end
end

-- same as commonlib.serialize_compact, except that it is more compact by removing string key brackets, etc.
-- e.x. {nid=19612,action="user_login",} instead of {["nid"]=19612,["action"]="user_login",}
local function serialize_compact2(o)
    local obj_type = type(o)
    if obj_type == "number" then
        return (tostring(o))
    elseif obj_type == "string" then
        return (string_format("%q", o))
    elseif obj_type == "boolean" then
        if(o) then
            return "true"
        else
            return "false"
        end
    elseif obj_type == "table" then
        local str = "{"
        local k, v;
        local nIndex = 1;
        for k, v in pairs(o) do
            if(type(k) == "string") then
                str = str..k.."=" .. (serialize_compact2(v) or "nil") .. ",";
            elseif(nIndex == k) then
                str    = str..(serialize_compact2(v) or "nil") .. ",";
                nIndex = nIndex + 1;
            else
                str = str.."["..tostring(k) .. "]=" .. (serialize_compact2(v) or "nil") .. ",";
            end
        end
        str = str.."}";
        return str
    elseif obj_type == "nil" then
        return ("nil")
    end
end
commonlib.serialize_compact2 = serialize_compact2;

-- this function will return a table created from file.
-- function may return nil
-- e.g.
-- local t = commonlib.LoadTableFromFile("temp/t.txt")
-- if(t~=nil) then end
function commonlib.LoadTableFromFile(filename)
    -- commonlib.tmptable = nil;
    -- local file = ParaIO.open(filename, "r");
    -- if(file:IsValid()) then
    -- local body = file:GetText();
    -- if(type(body)=="string") then
    -- NPL.DoString("commonlib.tmptable = "..body);
    -- end
    -- file:close();
    -- end
    -- return commonlib.tmptable;

    commonlib.tmptable = nil;
    local file         = ParaIO.open(filename, "r");
    if(file:IsValid()) then
        local body = file:GetText();
        if(type(body) == "string") then
            commonlib.tmptable = NPL.LoadTableFromString(body)
            if(not commonlib.tmptable) then
                -- log("error: commonlib.LoadTableFromFile() returns empty table. call stack is\n");
                -- commonlib.log(commonlib.debugstack())
            end
        end
        file:close();
    end
    return commonlib.tmptable;
end

-- @param body: should be a string of "{ any thing here }". if table or other data type, it is returned as it is.
-- return the table.
function commonlib.LoadTableFromString(body)
    if(type(body) == "string") then
        commonlib.tmptable = NPL.LoadTableFromString(body)
        if(not commonlib.tmptable) then
            -- LOG.std(nil, "error", "serializer", "commonlib.LoadTableFromString() returns empty table. input %s. call stack is", tostring(body));
            -- commonlib.log(commonlib.debugstack())
        end
        return commonlib.tmptable;
    else
        return body;
    end
end

-- this function will return a table created from file.
-- @param bBeautified: true to enable indentation which is well organized and easy to read the table structure
-- function may return nil.e.g.
-- local t = {test=1};
-- commonlib.SaveTableToFile(t, "temp/t.txt");
function commonlib.SaveTableToFile(o, filename, bBeautified)
    local succeed;
    local file = ParaIO.open(filename, "w");
    if(file:IsValid()) then
        local str;
        if(bBeautified) then
            str = commonlib.serialize2(o, 1);
        else
            str = commonlib.serialize(o);
        end
        file:WriteString(str);
        succeed = true;
    end
    file:close();
    return succeed;
end

-- serialize to string
-- serialization will be well organized and easy to read the table structure
-- e.g. print(commonlib.serialize(o, 1))
function commonlib.serialize2(o, lvl)
    local obj_type = type(o)
    if obj_type == "number" then
        return (tostring(o))
    elseif obj_type == "string" then
        return (string_format("%q", o))
    elseif obj_type == "boolean" then
        if(o) then
            return "true"
        else
            return "false"
        end
    elseif obj_type == "table" then

        local forwardStr = "";
        for i = 0, lvl do
            forwardStr = forwardStr.."  ";
        end
        local str = "{\r\n";
        local k, v
        for k, v in pairs(o) do
            nextlvl = lvl + 1;
            str     = str..forwardStr..("  [")..commonlib.serialize2(k, nextlvl) .. "] = "..commonlib.serialize2(v, nextlvl) .. ",\r\n"
        end
        str = str..forwardStr.."}";
        return str
    elseif obj_type == "nil" then
        return ("nil")
    elseif obj_type == "function" then
        return (tostring(o))
    elseif obj_type == "userdata" then
        return ("nil")
    else
        log("-- cannot serialize a " .. obj_type.."\r\n")
    end
end

-- dump text or lines. it will automatically create directory for you.
-- @param filename: which file to write to. it will replace whatever in the file.
-- @param o: it can be text string or table array containing text lines, which are concartinated. It does NOT add line endings.
-- commonlib.SaveTableToFile({"hello ", "world!"}, "temp/t.txt");
function commonlib.WriteTextToFile(o, filename)
    local succeed;
    ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
    if(file:IsValid()) then
        if(type(o) == "string") then
            file:WriteString(o);
        elseif(type(o) == "table") then
            local _, line
            for _, line in ipairs(o) do
                if(type(line) == "string") then
                    file:WriteString(line);
                end
            end
        end
        succeed = true;
    end
    file:close();
    return succeed;
end
---------------------------------------
-- DataDumper.lua code is from: http://lua-users.org/wiki/DataDumper
-- added by LXZ on 2008.5.1
---------------------------------------

--[[
Copyright (c) 2007 Olivetti-Engineering SA

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
]]

local dumplua_closure = [[
local closures = {}
local function closure(t)
  closures[#closures+1] = t
  t[1] = assert(loadstring(t[1]))
  return t[1]
end

for _,t in pairs(closures) do
  for i = 2,#t do
    debug.setupvalue(t[1], i-1, t[i])
  end
end
]]

local lua_reserved_keywords = {
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
    'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while'}

local function keys(t)
    local res     = {}
    local oktypes = {stringstring = true, numbernumber = true}
    local function cmpfct(a, b)
        if oktypes[type(a)..type(b)] then
            return a < b
        else
            return type(a) < type(b)
        end
    end
    for k in pairs(t) do
        res[#res + 1] = k
    end
    table.sort(res, cmpfct)
    return res
end

-- local c_functions = {}
-- for _,lib in pairs{'_G', 'string', 'table', 'math',
-- 'io', 'os', 'coroutine', 'package', 'debug'} do
-- local t = _G[lib] or {}
-- lib = lib .. "."
-- if lib == "_G." then lib = "" end
-- for k,v in pairs(t) do
-- if type(v) == 'function' and not pcall(string.dump, v) then
-- c_functions[v] = lib..k
-- end
-- end
-- end

--[[ LiXizhi 2008.5.15: I modified to disable function and userdata dumping.
DataDumper consists of a single Lua function, which could easily be put in a separate module or integrated into a bigger one.
The function has four parameters, but only the first one is mandatory. It always returns a string value, which is valid Lua code.
Simply executing this chunk will import back to a variable the complete structure of the original variable.
For simple structures, there is only one Lua instruction like a table constructor, but some more complex features will output a script with more instructions.

All the following language features are supported:

Simple Lua types: nil, boolean, number, string
Tables are dumped recursively
Table metatables are also dumped recursively
Simple Lua functions (no upvalue) are dumped with loadstring
Lua closures with upvalues are also supported, using the debug library!
Known C functions are output using their original name
Complex tables structures with internal references are supported
@param value can be of any supported type
@param varname: optional variable name. Depending on its form, the output will look like:
    nil: "return value"
    identifier: "varname = value"
    other: "varname".."value"
@param fastmode is a boolean value:
    true: optimizes for speed. Metatables, closures, C functions and references are not supported. Returns a code chunk without any space or new line!
    false: supports all advanced features and favors readable code with good indentation.
@param indent: the number of additional indentation level. Default is 0.
]]
function commonlib.dump(value, varname, fastmode, ident)
    local defined, dumplua = {}
    -- Local variables for speed optimization
    local string_format, type, string_dump, string_rep =
    string.format, type, string.dump, string.rep
    local tostring, pairs, table_concat =
    tostring, pairs, table.concat
    local keycache, strvalcache, out, closure_cnt = {}, {}, {}, 0
    setmetatable(strvalcache, {__index = function(t, value)
        local res = string_format('%q', value)
        t[value]  = res
        return res
    end})
    local fcts = {
        string = function(value) return strvalcache[value] end,
        number = function(value) return value end,
        boolean = function(value) return tostring(value) end,
        ['nil'] = function(value) return 'nil' end,
        ['function'] = function(value)
            -- return string_format("loadstring(%q)", string_dump(value))
            return "function"
        end,
        userdata = function() return "userdata" end,
        thread = function() return "threads" end,
    }
    local function test_defined(value, path)
        if defined[value] then
            if path:match("^getmetatable.*%)$") then
                out[#out + 1] = string_format("s%s, %s)\n", path:sub(2, -2), defined[value])
            else
                out[#out + 1] = path .. " = " .. defined[value] .. "\n"
            end
            return true
        end
        defined[value] = path
    end
    local function make_key(t, key)
        local s
        if type(key) == 'string' and key:match('^[_%a][_%w]*$') then
            s = key .. "="
        else
            s = "[" .. dumplua(key, 0) .. "]="
        end
        t[key] = s
        return s
    end
    for _, k in ipairs(lua_reserved_keywords) do
        keycache[k] = '["'..k..'"] = '
    end
    if fastmode then
        fcts.table = function (value)
            -- Table value
            local numidx  = 1
            out[#out + 1] = "{"
            for key, val in pairs(value) do
                if key == numidx then
                    numidx = numidx + 1
                else
                    out[#out + 1] = keycache[key]
                end
                local str     = dumplua(val)
                out[#out + 1] = str..","
            end
            out[#out + 1] = "}"
            return ""
        end
    else
        fcts.table = function (value, ident, path)
            if test_defined(value, path) then return "nil" end
            -- Table value
            local sep, str, numidx, totallen = " ", {}, 1, 0
            local meta, metastr = (debug or getfenv()).getmetatable(value)
            if meta then
                ident    = ident + 1
                metastr  = dumplua(meta, ident, "getmetatable("..path..")")
                totallen = totallen + #metastr + 16
            end
            for _, key in pairs(keys(value)) do
                local val     = value[key]
                local s       = ""
                local subpath = path
                if key == numidx then
                    subpath = subpath .. "[" .. numidx .. "]"
                    numidx  = numidx + 1
                else
                    s = keycache[key]
                    if not s:match "^%[" then subpath = subpath .. "." end
                    subpath = subpath .. s:gsub("%s*=%s*$", "")
                end
                s             = s .. dumplua(val, ident + 1, subpath)
                str[#str + 1] = s
                totallen      = totallen + #s + 2
            end
            if totallen > 80 then
                sep = "\n" .. string_rep("  ", ident + 1)
            end
            str = "{"..sep..table_concat(str, ","..sep) .. " "..sep:sub(1, -3) .. "}"
            if meta then
                sep = sep:sub(1, -3)
                return "setmetatable("..sep..str..","..sep..metastr..sep:sub(1, -3) .. ")"
            end
            return str
        end
        -- fcts['function'] = function (value, ident, path)
        -- if test_defined(value, path) then return "nil" end
        -- if c_functions[value] then
        -- return c_functions[value]
        -- elseif debug == nil or debug.getupvalue(value, 1) == nil then
        ---- return string_format("loadstring(%q)", string_dump(value))
        -- return "up_value";
        -- end
        -- closure_cnt = closure_cnt + 1
        -- local res = {string.dump(value)}
        -- for i = 1,math.huge do
        -- local name, v = debug.getupvalue(value,i)
        -- if name == nil then break end
        -- res[i+1] = v
        -- end
        -- return "closure " .. dumplua(res, ident, "closures["..closure_cnt.."]")
        -- end
    end
    function dumplua(value, ident, path)
        return fcts[type(value)](value, ident, path)
    end
    if varname == nil then
        varname = "return "
    elseif varname:match("^[%a_][%w_]*$") then
        varname = varname .. " = "
    end
    if fastmode then
        setmetatable(keycache, {__index = make_key})
        out[1] = varname
        table.insert(out, dumplua(value, 0))
        return table.concat(out)
    else
        setmetatable(keycache, {__index = make_key})
        local items = {}
        for i = 1, 10 do items[i] = '' end
        items[3] = dumplua(value, ident or 0, "t")
        if closure_cnt > 0 then
            items[1], items[6] = dumplua_closure:match("(.*\n)\n(.*)")
            out[#out + 1] = ""
        end
        if #out > 0 then
            items[2], items[4] = "local t = ", "\n"
            items[5] = table.concat(out)
            items[7] = varname .. "t"
        else
            items[2] = varname
        end
        return table.concat(items)
    end
end

-- Used to escape "'s by toCSV
local function escapeCSV(s)
    if string.find(s, '[,"]') then
        s = '"' .. string.gsub(s, '"', '""') .. '"'
    end
    return s
end

-- Convert from CSV string to table
function commonlib.fromCSV(s)
    s                = s .. ','        -- ending comma
    local t          = {}        -- table to collect fields
    local fieldstart = 1
    repeat
        -- next field is quoted? (start with `"'?)
        if string.find(s, '^"', fieldstart) then
            local a, c
            local i = fieldstart
            repeat
                -- find closing quote
                a, i, c = string.find(s, '"("?)', i + 1)
            until c ~= '"' -- quote not followed by quote?
            if not i then error('unmatched "') end
            local f = string.sub(s, fieldstart + 1, i - 1)
            table.insert(t, (string.gsub(f, '""', '"')))
            fieldstart = string.find(s, ',', i) + 1
        else -- unquoted; find next comma
            local nexti = string.find(s, ',', fieldstart)
            table.insert(t, string.sub(s, fieldstart, nexti - 1))
            fieldstart = nexti + 1
        end
    until fieldstart > string.len(s)
    return t
end

-- Convert from table to CSV string
function commonlib.toCSV(tt)
    local s = ""
    for _, p in pairs(tt) do
        s = s .. "," .. escapeCSV(p)
    end
    return string.sub(s, 2) -- remove first comma
end

function commonlib.MillToTimeStr(totalMillseconds, timefmt)
    if(not totalMillseconds or type(totalMillseconds) ~= "number")then return end
    totalMillseconds = math.max(totalMillseconds, 0);
    local hours, minutes, seconds;
    local t          = 3600 * 1000;
    hours            = math.floor(totalMillseconds / t);
    totalMillseconds = totalMillseconds - hours * t;

    t                = 60 * 1000;
    minutes          = math.floor(totalMillseconds / t);
    totalMillseconds = totalMillseconds - minutes * t;

    t = 1000;

    t       = t / 1000
    seconds = totalMillseconds / t;
    hours   = math.max(hours, 0);
    minutes = math.max(minutes, 0);
    seconds = math.max(seconds, 0);
    if(timefmt)then
        if(timefmt == "m-s")then
            local s = string.format("%.2d:%.2d", minutes, seconds);
            return s, hours, minutes, seconds;
        end
        if(timefmt == "h-m")then
            local s = string.format("%.2d:%.2d", hours, minutes);
            return s, hours, minutes, seconds;
        end
        if(timefmt == "h-m-s")then
            local s = string.format("%.2d:%.2d:%.2d", hours, minutes, seconds);
            return s, hours, minutes, seconds;
        end
    end
    seconds = string.format("%.3f", seconds);
    return hours..":"..minutes..":"..seconds, hours, minutes, seconds;
end

-- 显示提示性语句
function commonlib.showLocalTip(str, pos, angle)
    local width = 680
    -- if not angle then
    --     width = 680
    -- end
    local tips = ccui.Scale9Sprite:create("ui/qj_tips/ts_0000_tst-fs8.png")
    -- tips:setPreferredSize(cc.size(width,50))
    tips:setCapInsets(cc.rect(20, 20, 10, 10))
    tips:setPosition(pos or cc.p(g_visible_size.width / 2, g_visible_size.height / 2))
    cc.Director:getInstance():getRunningScene():addChild(tips, 99999)

    local title = cc.LabelTTF:create(str, "STHeitiSC-Medium", 24)
    title:setHorizontalAlignment(1)
    -- title:setColor(ccc3(255,255,255))
    title:setPosition(cc.p(width / 2 + 80, 27))
    tips:addChild(title)

    title:runAction(cc.FadeOut:create(2))

    -- if not angle then
    --     tips:setRotation(-90)
    -- end
    tips:runAction(cc.Sequence:create(cc.MoveTo:create(1, cc.p(g_visible_size.width / 2, g_visible_size.height / 2 + 100)),
        cc.FadeOut:create(2), cc.CallFunc:create(function()
            tips:removeFromParent(true)
        end)))

end

function commonlib.getChipImg(chip_level)
    local list = {"game/chips-pink-red-small.png", "game/chips-green-small.png", "game/chips-blue-small.png",
        "game/chips-yellow-small.png", "game/chips-blue-green-small.png", "game/chips-brown-small.png", "game/chips-red-small.png",
        "game/chips-orange-small.png", "game/chips-purple-small.png", "game/chips-black-small.png"}
    if list[chip_level] then
        return list[chip_level]
    else
        return "game/chips-black-small.png"
    end
end

function commonlib.fadeIn(panel, callfunc, speed)

    panel:setOpacity(0)

panel:runAction(cc.Sequence:create(cc.FadeIn:create(0.25 * (speed or 1)), cc.CallFunc:create(function() if callfunc then callfunc() end end)))
end

function commonlib.fadeTo(panel, callfunc, is_remove)

    panel:setOpacity(0)

    local time = 0.2
    if is_remove then
        time = 0.15
    end
panel:runAction(cc.Sequence:create(cc.FadeTo:create(time, 180), cc.CallFunc:create(function() if callfunc then callfunc() end end)))
end

function commonlib.moveTo(panel, is_left, callfunc, is_remove)

    local pos = cc.p(panel:getPosition())

    local time = 0.2
    if is_remove then
        time = 0.2
        if is_left then
            pos.x = pos.x - g_visible_size.width
        else
            pos.x = pos.x + g_visible_size.width
        end
    else
        if is_left then
            panel:setPositionX(pos.x - g_visible_size.width / 3)
        else
            panel:setPositionX(pos.x + g_visible_size.width / 3)
        end
    end

panel:runAction(cc.Sequence:create(cc.MoveTo:create(time, pos), cc.CallFunc:create(function() if callfunc then callfunc() end end)))
end

function commonlib.fadeOut(panel, callfunc, time)

panel:runAction(cc.Sequence:create(cc.FadeOut:create(time or 0.175), cc.CallFunc:create(function() if callfunc then callfunc() end end)))
end

function commonlib.scaleIn(panel, callfunc, speed)
    panel:setOpacity(0)

    panel:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function()

        panel:setOpacity(255)
        local scale = panel:getScale()
        panel:setScale(1)

        panel:runAction(cc.Sequence:create(cc.ScaleTo:create(0.01 * (speed or 1), 1 * scale), cc.ScaleTo:create(0.075 * (speed or 1), 1.05 * scale),
        cc.ScaleTo:create(0.075 * (speed or 1), 1.0 * scale), cc.CallFunc:create(function() if callfunc then callfunc() end end)))

    end)))
end

function commonlib.scaleOut(panel, callfunc)

    local scale = panel:getScale()

    panel:runAction(cc.Sequence:create(cc.ScaleTo:create(0.075, 0.8 * scale), cc.ScaleTo:create(0.05, 0.5 * scale),
    cc.ScaleTo:create(0.05, 0.1 * scale), cc.CallFunc:create(function() if callfunc then callfunc() end end)))
end

function commonlib.getBezier(start_pos, end_pos)

    local add_x = end_pos.x - start_pos.x
    local add_y = end_pos.y - start_pos.y
    local off_y = math.random(20, 80)
    if math.random(1, 10000) <= 5000 then
        off_y = -off_y
    end
    local aa     = math.random(0, 2)
    local bb     = math.random(0, 2)
    local bezier = {}
    bezier[1]    = cc.p(start_pos.x + add_x * (0.2 + aa * 0.1), start_pos.y + add_y * 0.5 + off_y)
    bezier[2]    = cc.p(start_pos.x + add_x * (0.7 + bb * 0.1), start_pos.y + add_y * 0.5 + off_y)
    bezier[3]    = end_pos

    return bezier
end

function commonlib.loadLoading(callfunc, game_type)

    local scene = cc.Scene:create()
    local layer = tolua.cast(cc.CSLoader:createNode("ui/Guodu.csb"), "ccui.Widget")
    scene:addChild(layer)

    layer:setContentSize(cc.size(g_visible_size.height, g_visible_size.width))

    ccui.Helper:doLayout(layer)

    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(scene)
    else
        cc.Director:getInstance():runWithScene(scene)
    end

    local _count       = 0
    local LoadingBar_1 = tolua.cast(ccui.Helper:seekWidgetByName(layer, "LoadingBar_1"), "ccui.LoadingBar")
    LoadingBar_1:setPercent(0)
    LoadingBar_1:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.001), cc.CallFunc:create(function()
        _count = _count + 3
        LoadingBar_1:setPercent(_count)
        if _count > 100 then
            LoadingBar_1:stopAllActions()
            cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
            cc.Director:getInstance():getTextureCache():removeUnusedTextures()
            if callfunc then callfunc() end
        end
    end))))

    local tipConfig = loadTipConfg[game_type or "hall"] or loadTipConfg["hall"]
    local tipLabel  = tolua.cast(ccui.Helper:seekWidgetByName(layer, "lab-shuoming"), "ccui.Text")
    tipLabel:setString(tipConfig[math.random(1, #tipConfig)])
    tipLabel:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
        tipLabel:setString(tipConfig[math.random(1, #tipConfig)])
    end))))
end

function commonlib.worldPos(node, landscape)
    local pos = cc.p(node:getParent():convertToWorldSpace(cc.p(node:getPosition())))
    return pos
end

function commonlib.broadMsg(node, pos, portrait, offset)
    local msgLayer = ccui.Layout:create()
    msgLayer:setClippingEnabled(true)
    local w_width = 506
    if portrait then
        w_width = g_visible_size.height - 60
    elseif not pos then
        w_width = 630 -- g_visible_size.width
    end
    msgLayer:setContentSize(cc.size(w_width, 24))

    local sysMsg = cc.LabelTTF:create("", "STHeitiSC-Medium", 20)
    sysMsg:setAnchorPoint(0.0, 0.5)
    sysMsg:setPosition(cc.p(0, 12))
    sysMsg:setColor(cc.c3b(255, 255, 0))
    msgLayer:addChild(sysMsg)

    if not pos then
        local bg = cc.Sprite:create("game/zjh/zjh_fj_ico_xxk.png")
        bg:setAnchorPoint(0, 0)
        if portrait == false then
            bg:setPosition(cc.p(0, g_visible_size.height - 43))
        elseif portrait == nil then
            bg:setPosition(cc.p(43, 0))
            bg:setRotation(-90)
        else
            bg:setPosition(cc.p(0, g_visible_size.width - 43 - (offset or 0)))
        end
        msgLayer:setPosition(cc.p(60, 10))
        bg:addChild(msgLayer)
        node:addChild(bg, 9999)
        msgLayer = bg
    else
        msgLayer:setPosition(pos)
        node:addChild(msgLayer, 9999)
    end

    local speed = 39
    local function updateMsg()
        local str, pos
        str = node:Get_one_broadmsg() or ""
        pos = w_width
        if str == "" then
            msgLayer:setVisible(false)
            sysMsg:runAction(cc.Sequence:create(cc.DelayTime:create(1),
                cc.CallFunc:create(updateMsg)))
        else
            msgLayer:setVisible(true)
            sysMsg:setString(str)
            sysMsg:setPositionX(pos)
            local msgWidth = pos + sysMsg:getContentSize().width
            sysMsg:runAction(cc.Sequence:create(cc.MoveBy:create(msgWidth / speed, cc.p(-msgWidth, 0)),
                cc.CallFunc:create(updateMsg)))
        end
    end
    updateMsg()

end

function commonlib.showTextField(text_field, callfunc, is_zh)

    local open = nil
    if not g_is_ios then
        if callfunc then
            text_field:addEventListener(function(__, touchtype)
                if touchtype == 0 and not open then
                    open = true
                elseif touchtype == 1 and open then
                    open = nil
                    if callfunc then
                        callfunc()
                    end
                end
            end)
        end
        return
    end

    local input_dlg = nil
    text_field:addEventListener(function(__, touchtype)

        if touchtype == 0 and not open then

            text_field:setDetachWithIME(true)
            text_field:setTouchEnabled(false)

            open = true

        elseif touchtype == 1 and open then

            open = nil
            if not input_dlg then
                input_dlg       = tolua.cast(cc.CSLoader:createNode("srk/shurukuang.csb"), "ccui.Widget")
                input_dlg.panel = tolua.cast(input_dlg:getChildByName("Panel_1"), "ccui.Widget")
                input_dlg.panel:setContentSize(cc.size(g_visible_size.width, input_dlg.panel:getContentSize().height))
                ccui.Helper:doLayout(input_dlg.panel)
                input_dlg:setPosition(cc.p(0, g_visible_size.height - input_dlg.panel:getContentSize().height - 10))
                cc.Director:getInstance():getRunningScene():addChild(input_dlg, 100000)

                local input = tolua.cast(input_dlg.panel:getChildByName("TextField_1"), "ccui.TextField")
                input:attachWithIME()
                input:setTouchEnabled(false)
                input:addEventListener(function(__, touchtype)
                    if touchtype == 0 and not open then
                        open = true
                    elseif touchtype == 1 and open then
                        open = nil
                        if input_dlg then
                            if is_zh and string.find(input:getString(), "[^%d|%a]") then
                                commonlib.showLocalTip("只能输入字母或数字")
                            else
                                text_field:setString(input:getString())
                            end
                            text_field:setTouchEnabled(true)

                            cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("HideKeyboard")
                            input_dlg:removeFromParent(true)
                            input_dlg = nil
                        end
                    end
                end)

                tolua.cast(input_dlg.panel:getChildByName("Image_1"), "ccui.ImageView"):loadTexture("srk/shurukuang.jpg")

                tolua.cast(input_dlg.panel:getChildByName("btn-fasong"), "ccui.Button"):loadTextureNormal("srk/btn1.png")
                tolua.cast(input_dlg.panel:getChildByName("btn-fasong"), "ccui.Button"):loadTexturePressed(nil)

                input_dlg.panel:getChildByName("btn-fasong"):addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        open = nil
                        if input_dlg then
                            local vaild = true
                            if is_zh and string.find(input:getString(), "[^%d|%a]") then
                                commonlib.showLocalTip("只能输入字母或数字")
                                vaild = false
                            else
                                text_field:setString(input:getString())
                            end
                            text_field:setTouchEnabled(true)

                            input:didNotSelectSelf()

                            cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("HideKeyboard")
                            input_dlg:removeFromParent(true)
                            input_dlg = nil

                            if callfunc and vaild then
                                callfunc()
                            end
                        end
                    end
                end)

                cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(cc.EventListenerCustom:create("HideKeyboard", function()
                    if open then
                        open = nil
                        if input_dlg then
                            cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("HideKeyboard")

                            if is_zh and string.find(input:getString(), "[^%d|%a]") then
                                commonlib.showLocalTip("只能输入字母或数字")
                            else
                                text_field:setString(input:getString())
                            end
                            text_field:setTouchEnabled(true)

                            input:didNotSelectSelf()

                            input_dlg:removeFromParent(true)
                            input_dlg = nil
                        end
                    end
                end), 1)
            end
        end
    end)
end

function commonlib.closeRoomTipDlg()
    local runningScene = cc.Director:getInstance():getRunningScene()
    if not runningScene then
        return
    end
    local node = runningScene:getChildByName('RoomTipDlg')
    if node then
        node:removeFromParent()
    end
end

function commonlib.showRoomTipDlg(msg, callfunc)
    commonlib.showTipDlg(msg, callfunc, nil, nil, 'RoomTipDlg')
end

function commonlib.showTipDlg(msg, callfunc, no_cancel, lackPermisstion, name, noCancleBtn)
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_Tips
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999)
    if name then
        node:setName(name)
    end

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    exit:setVisible(false)
    local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text") -- :setString(msg)
    if not content then
        content = ccui.Text:create()
        content:setFontSize(36)
        content:setColor(cc.c3b(255, 255, 255))
        content:setPosition(cc.p(g_visible_size.width * 0.5, g_visible_size.height * 0.5))
        node:addChild(content)
    else
        content:setString(msg or "您的账号已在别处登陆！！！")
    end

    local btnEnter = ccui.Helper:seekWidgetByName(node, "btEnter")
    local btCancel = ccui.Helper:seekWidgetByName(node, "btCancel")

    if lackPermisstion then
        local imgEnter = tolua.cast(ccui.Helper:seekWidgetByName(node, "imgEnter"), "ccui.ImageView")
        imgEnter:loadTexture("ui/qj_button/gotoset.png")
        imgEnter:setScaleX(167 / 122)
        imgEnter:setScaleY(59 / 54)
    end

    btnEnter:addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                if callfunc then
                    callfunc(true)
                end
                node:removeFromParent(true)
            end
        end
    )
    exit:addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                if callfunc then
                    callfunc(true)
                end
                node:removeFromParent(true)
            end
        end
    )

    if noCancleBtn then
        btCancel:setVisible(false)
        btnEnter:setPositionX(btnEnter:getParent():getContentSize().width / 2)
        return
    end

    if no_cancel then
        btCancel:setVisible(false)
        btnEnter:setVisible(false)
        exit:setVisible(true)
    else
        btCancel:addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                    if callfunc then
                        callfunc(false)
                    end
                    node:removeFromParent(true)
                end
            end
        )
    end

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"), function()
        content:setString(msg or "您的账号已在别处登陆！！！")
    end)
end

function commonlib.showExitTip(msg, callfunc)
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_Tips
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 4532)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    exit:setVisible(false)
    local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text") -- :setString(msg)
    if not content then
        content = ccui.Text:create()
        content:setFontSize(36)
        content:setColor(cc.c3b(255, 255, 255))
        content:setPosition(cc.p(g_visible_size.width * 0.5, g_visible_size.height * 0.5))
        node:addChild(content)
    else
        content:setString(msg or "您的账号已在别处登陆！！！")
    end

    ccui.Helper:seekWidgetByName(node, "btEnter"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                if callfunc then
                    callfunc(true)
                end
                node:removeFromParent(true)
            end
        end
    )

    ccui.Helper:seekWidgetByName(node, "btCancel"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                if callfunc then
                    callfunc(false)
                end
                node:removeFromParent(true)
            end
        end
    )

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"), function()
        content:setString(msg or "您的账号已在别处登陆！！！")
    end)
end

function commonlib.showPushQinLiaoTip(msg)
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_Tips_push_qinliao
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 4532)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    exit:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
            node:removeFromParent(true)
        end
    end)
    local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "code"), "ccui.Text") -- :setString(msg)
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"), function()
        content:setString(msg or "")
    end)
end

function commonlib.showJieBangQinLiaoTip()
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_Tips_jiebang_qinliao
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 4532)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    exit:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
            node:removeFromParent(true)
        end
    end)
end

function commonlib.avoidJoinTip(msg, msg2)
    local layer = cc.Director:getInstance():getRunningScene():getChildByTag(8777)
    if layer then
        return
    end
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_avoidJoinTips
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 8777)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local tContent = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text")
    local content1 = tolua.cast(ccui.Helper:seekWidgetByName(node, "Content1"), "ccui.Text")
    local content2 = tolua.cast(ccui.Helper:seekWidgetByName(node, "Content2"), "ccui.Text")
    local content3 = tolua.cast(ccui.Helper:seekWidgetByName(node, "Content3"), "ccui.Text")
    local content4 = tolua.cast(ccui.Helper:seekWidgetByName(node, "Content4"), "ccui.Text")
    local btEnter  = ccui.Helper:seekWidgetByName(node, "btEnter")
    local btGps    = ccui.Helper:seekWidgetByName(node, "btGps")
    local btok     = ccui.Helper:seekWidgetByName(node, "btok")

    if msg then
        btGps:setVisible(false)
        btok:setVisible(false)
        btEnter:setVisible(true)
        btEnter:setPositionX(640)
        content1:setPositionY(350.6)
        content2:setPositionY(297.2)

        content3:setVisible(false)
        content4:setVisible(false)
        content1:setString("与此房间内的一名玩家" .. msg .. "，不能进入此房间")
        content2:setString("解决方案：请选择亲友圈中其他未开始房间进入游戏")
    elseif msg2 then
        btEnter:setVisible(false)
        btGps:setVisible(false)
        btok:setVisible(true)
        content1:setPositionY(350.6)
        content2:setPositionY(297.2)
        tContent:setString("亲爱的管理员大大:")
        content1:setString("开启或者关闭"..msg2.."时:")
        content2:setString("需亲友圈的桌子成功开启一局游戏后，功能在下局才会生效哦！")
        content2:setColor(cc.c3b(255, 23, 3))
        content3:setVisible(false)
        content4:setVisible(false)
    else
        btGps:setVisible(true)
        btEnter:setVisible(true)
        btok:setVisible(false)
        btEnter:setPositionX(448)
        content1:setPositionY(376.6)
        content2:setPositionY(344.2)
        content3:setVisible(true)
        content4:setVisible(true)
    end

    ccui.Helper:seekWidgetByName(node, "btEnter"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    ccui.Helper:seekWidgetByName(node, "btGps"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                local NativeUtil = require("common.NativeUtil")
                NativeUtil:locationSet()
                node:removeFromParent(true)
            end
        end
    )

    ccui.Helper:seekWidgetByName(node, "btok"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))
end

function commonlib.goldStr(num, unit)
    return num
    -- local num = tonumber(num)
    -- if num <= 100000 then
    -- return string.format("%d", num)
    -- elseif num <= 10000000 then
    --     return string.format("%0.2fk", num/1000)
    -- else
    --     return string.format("%dw", num/10000)
    -- end
end

function commonlib.wxHead(head)
    if (not head or head == "" or string.len(head) < 24) then
        head = "http://thirdwx.qlogo.cn/mmopen/vi_32/Iy3rGQO05UlcA1o6yWLVCEicxBj1Uq0yy7ubMuDQ1BHvtiaHoCWSg8ZXsZKsf4wbmHnfEicSsgAiamxrp3nsDPIGzA/132"
    end
    local head_url = head
    if string.sub(head, -2, -1) == "/0" then
        head_url = string.sub(head, 1, -2) .. "132"
    end
    return head_url
end

function commonlib.closeJiesan(parent)
    if parent.js_node then
        parent.js_node:removeFromParent(true)
        parent.js_node = nil
    end
end

function commonlib.showJiesan(parent, rtn_msg, count)

    if rtn_msg.errno and rtn_msg.errno ~= 0 then
        if parent.js_node then
            parent.js_node:removeFromParent(true)
            parent.js_node = nil
        end
        if rtn_msg.errno == 1004 then
            commonlib.showLocalTip("距离上次申请未超过60秒，稍后再试")
        elseif rtn_msg.errno == 1005 then
            commonlib.showLocalTip("当前没有人申请解散")
        else
            commonlib.showLocalTip(rtn_msg.errno)
        end
        return
    end

    if rtn_msg.cmd == NetCmd.S2C_APPLY_JIESAN_AGREE then
        if parent.js_node then
            for __, v in ipairs(parent.js_node.all_items or {}) do
                if v.uid == rtn_msg.uid then
                    if rtn_msg.typ == 1 then
                        v:setString('玩家['..v.id..']同意')
                    elseif rtn_msg.typ == 0 then
                        v:setString('玩家['..v.id..']拒绝')
                    else
                        v:setString('玩家['..v.id..']等待选择')
                    end
                end
            end
            if rtn_msg.self then
                ccui.Helper:seekWidgetByName(parent.js_node, "btn-tongyijiesan"):setVisible(false)
                ccui.Helper:seekWidgetByName(parent.js_node, "btn-tongyijiesan"):setTouchEnabled(false)

                ccui.Helper:seekWidgetByName(parent.js_node, "btn-butongyi"):setVisible(false)
                ccui.Helper:seekWidgetByName(parent.js_node, "btn-butongyi"):setTouchEnabled(false)
            end
            if rtn_msg.typ == 0 then
                parent.js_node.js_count = 0
            else
                parent.js_node.js_count = parent.js_node.js_count - 1
            end
        end
    else
        if parent.js_node then
            parent.js_node:removeFromParent(true)
            parent.js_node = nil
        end

        local csb  = DTUI.getInstance().csb_jiesanroom
        local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
        parent:addChild(node, 999999)

        parent.js_node = node

        parent.js_node.js_count = count - 1

        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(node)

        parent.js_node.all_items = {}
        parent.js_node.itemsID   = {}
        for i = 1, 6 do
            local item = ccui.Helper:seekWidgetByName(node, "Player"..i)
            if rtn_msg.jiesan_list and #rtn_msg.jiesan_list < 5 then
                local pos = 413.06 - (i - 1) * 57.6
                item:setPositionY(pos)
            else
                local pos = 437.06 - (i - 1) * 43.26
                item:setPositionY(pos)
            end
            if rtn_msg.jiesan_list and rtn_msg.jiesan_list[i] then
                local info = rtn_msg.jiesan_list[i]
                if pcall(commonlib.GetMaxLenString, info.name, 14) then
                    info.name = commonlib.GetMaxLenString(info.name, 14)
                else
                    info.name = info.name
                end
                if info.typ == 1 then
                    item:setString('玩家['..info.name..']同意')
                else
                    item:setString('玩家['..info.name..']等待选择')
                end
                item.uid = info.uid
                item.id  = info.name
            else
                item:setVisible(false)
            end
            parent.js_node.all_items[i] = item
            -- parent.js_node.itemsID[i] = info.name
        end
        if pcall(commonlib.GetMaxLenString, rtn_msg.nickname, 14) then
            ccui.Helper:seekWidgetByName(node, "Remain"):setString('玩家['..commonlib.GetMaxLenString(rtn_msg.nickname, 14) .. ']申请解散')
        else
            ccui.Helper:seekWidgetByName(node, "Remain"):setString('玩家['..rtn_msg.nickname..']申请解散')
        end

        local djs      = ccui.Helper:seekWidgetByName(node, "RemainTime")
        djs.time       = rtn_msg.time
        local now_time = os.time() + rtn_msg.time
        djs:setString('在'..math.floor(djs.time / 60) .. "分" .. (djs.time % 60) .. '秒之后自动同意')
        djs:runAction(cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            djs.time = math.max(now_time - os.time(), 0)
            djs:setString('在'..math.floor(djs.time / 60) .. "分" .. (djs.time % 60) .. '秒之后自动同意')
            if djs.time <= 0 or parent.js_node.js_count <= 0 then
                commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Panel_1"))
                commonlib.scaleOut(ccui.Helper:seekWidgetByName(node, "Panel_5"), function()
                    parent.js_node = nil
                    node:removeFromParent(true)
                end)
            end
        end)), djs.time))

        ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):setTouchEnabled(true)
        ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                    print("confirm")
                    local input_msg = {
                        cmd = NetCmd.C2S_APPLY_JIESAN_AGREE,
                        typ = 1,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                    ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):setTouchEnabled(false)
                end
            end
        )

        ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setTouchEnabled(true)
        ccui.Helper:seekWidgetByName(node, "btn-butongyi"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                    print("cancel")
                    local input_msg = {
                        cmd = NetCmd.C2S_APPLY_JIESAN_AGREE,
                        typ = 0,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                    ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setTouchEnabled(false)
                end
            end
        )

        commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
        commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))

        if rtn_msg.self then
            ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):setTouchEnabled(false)

            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setTouchEnabled(false)

        end
    end
end

function commonlib.interQuickStart(parent)
    local quickstart = parent:getChildByName('quickstart')
    if quickstart then
        commonlib.showTipDlg('房间已有玩家离开或进来新玩家！')
    end
    commonlib.closeQuickStart(parent)
end

function commonlib.closeQuickStart(parent)
    local quickstart = parent:getChildByName('quickstart')
    if quickstart then
        local ImgTextBg = ccui.Helper:seekWidgetByName(quickstart, "img-textbg")
        ImgTextBg:stopAllActions()
        quickstart:removeFromParent(true)
    end
    quickstart = nil
end

function commonlib.showQuickStart(parent, rtn_msg, count, str)

    dump(rtn_msg)
    local function removeQuickStart()
        commonlib.closeQuickStart(parent)
        quickstart = nil
    end
    if rtn_msg.errno and rtn_msg.errno ~= 0 then
        removeQuickStart()
        if rtn_msg.errno == 1004 then
            commonlib.showLocalTip("距离上次申请未超过60秒，稍后再试")
        elseif rtn_msg.errno == 1005 then
            commonlib.showLocalTip("当前没有人申请快速开始游戏")
        else
            commonlib.showLocalTip(rtn_msg.errno)
        end
        return
    end
    -- 加入同意
    if rtn_msg.cmd == NetCmd.S2C_APPLY_START_AGREE then
        local quickstart = parent:getChildByName('quickstart')
        if not quickstart then
            return
        end
        for __, v in ipairs(quickstart.all_items or {}) do
            if v.uid == rtn_msg.uid then

                local peoplestate = v:getChildByName('peoplestate')
                if rtn_msg.typ == 1 then
                    peoplestate:loadTexture('ui/qj_commom/agree-fs8.png')
                elseif rtn_msg.typ == 0 then
                    peoplestate:loadTexture('ui/qj_club/dt_clubOther_app_reject.png')
                else
                    peoplestate:loadTexture('ui/qj_commom/await-fs8.png')
                end
            end
        end
        if rtn_msg.self then
            ccui.Helper:seekWidgetByName(quickstart, "btn-agree"):setVisible(false)
            ccui.Helper:seekWidgetByName(quickstart, "btn-agree"):setTouchEnabled(false)

            ccui.Helper:seekWidgetByName(quickstart, "btn-disagree"):setVisible(false)
            ccui.Helper:seekWidgetByName(quickstart, "btn-disagree"):setTouchEnabled(false)
        end
        if rtn_msg.typ == 0 then
            quickstart.quick_start_count = 0
            commonlib.showTipDlg('玩家【' .. tostring(rtn_msg.nickname or '') .. '】 不同意立即开局!')
        else
            quickstart.quick_start_count = quickstart.quick_start_count - 1
        end
    elseif NetCmd.S2C_APPLY_START == rtn_msg.cmd then

        removeQuickStart()

        require('scene.DTUI')
        local csb  = DTUI.getInstance().csb_quickstart
        local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
        parent:addChild(node, 999999)
        node:setName('quickstart')
        quickstart = node

        quickstart.quick_start_count = count - 1

        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(node)

        ccui.Helper:seekWidgetByName(node, "t-wanfa"):setString('玩法:'..str)

        local ImgTextBg = ccui.Helper:seekWidgetByName(node, "img-textbg")
        local posX, posY = ImgTextBg:getPosition()
        local size = node:getContentSize()
        local startPosX, startPosY = size.width / 2, size.height / 2

        ImgTextBg:setPosition(startPosX, startPosY)
        ImgTextBg:runAction(cc.MoveTo:create(0.5, cc.p(posX, posY)))

        quickstart.all_items = {}
        quickstart.itemsID   = {}
        for i = 1, 4 do
            local item = ccui.Helper:seekWidgetByName(node, "player"..i)
            if item then
                if rtn_msg.start_list and rtn_msg.start_list[i] then
                    local info = rtn_msg.start_list[i]
                    if pcall(commonlib.GetMaxLenString, info.name, 14) then
                        info.name = commonlib.GetMaxLenString(info.name, 14)
                    else
                        info.name = info.name
                    end
                    local name = item:getChildByName('name')
                    name:setString('玩家【' .. info.name .. '】')

                    local peoplestate = item:getChildByName('peoplestate')

                    if info.typ == 1 then
                        peoplestate:loadTexture('ui/qj_commom/agree-fs8.png')
                    else
                        peoplestate:loadTexture('ui/qj_commom/await-fs8.png')
                    end
                    item.uid = info.uid
                    item.id  = info.name

                    local owner_uid = gt.getData('uid')
                    if info.typ ~= 2 and info.uid == owner_uid then
                        ccui.Helper:seekWidgetByName(quickstart, "btn-agree"):setVisible(false)
                        ccui.Helper:seekWidgetByName(quickstart, "btn-agree"):setTouchEnabled(false)

                        ccui.Helper:seekWidgetByName(quickstart, "btn-disagree"):setVisible(false)
                        ccui.Helper:seekWidgetByName(quickstart, "btn-disagree"):setTouchEnabled(false)
                    end
                else
                    item:setVisible(false)
                end
                quickstart.all_items[i] = item
            end
        end
        if pcall(commonlib.GetMaxLenString, rtn_msg.nickname, 14) then
            ccui.Helper:seekWidgetByName(node, "t-applicant"):setString('玩家['..commonlib.GetMaxLenString(rtn_msg.nickname, 14) .. ']申请立即开局，等待其他玩家选择')
        else
            ccui.Helper:seekWidgetByName(node, "t-applicant"):setString('玩家['..rtn_msg.nickname..']申请立即开局')
        end

        local djs = ccui.Helper:seekWidgetByName(node, "t-daojishi")
        djs.time  = rtn_msg.time
        djs:setString('注，超过60秒未作出选择，则默认拒绝，剩余')

        local text_last_time = ccui.Helper:seekWidgetByName(node, "t-time")
        local function setLastTime(min, seconds)
            if min > 0 then
                local time      = string.format('%d分%d秒', min, seconds)
                local last_time = string.format("%d分%d秒", min, seconds)
                time            = ''
                -- local str = string.format('注，超过%s未作出选择，则默认拒绝，剩余 %s ',time,last_time)

                -- djs:setString(str)

                text_last_time:setString(last_time)
            else
                local time      = string.format('%d秒', seconds)
                local last_time = string.format("%d秒", seconds)
                -- local str = string.format('注，超过%s未作出选择，则默认拒绝，剩余 %s ',time,last_time)

                -- djs:setString(str)

                text_last_time:setString(last_time)
            end
            -- text_last_time:setPositionX(djs:getPositionX() + djs:getContentSize().width * (1 - djs:getAnchorPoint().x))
        end

        local min     = math.floor(djs.time / 60)
        local seconds = math.floor(djs.time % 60)
        setLastTime(min, seconds)

        djs:runAction(cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            djs.time = math.max(djs.time - 1, 0)

            local min     = math.floor(djs.time / 60)
            local seconds = math.floor(djs.time % 60)
            setLastTime(min, seconds)

            if djs.time <= 0 or quickstart.quick_start_count <= 0 then
                commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Panel_1"))
                commonlib.scaleOut(ccui.Helper:seekWidgetByName(node, "Panel_2"), function()
                    node:removeFromParent(true)
                end)
            end
        end)), djs.time))
        local agree    = ccui.Helper:seekWidgetByName(node, "btn-agree")
        local disagree = ccui.Helper:seekWidgetByName(node, "btn-disagree")

        agree:setTouchEnabled(true)
        disagree:setTouchEnabled(true)

        agree:addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()

                    print("confirm")
                    local input_msg = {
                        cmd = NetCmd.C2S_APPLY_START_AGREE,
                        typ = 1,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                    agree:setTouchEnabled(false)
                    disagree:setTouchEnabled(false)
                    agree:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
                        agree:setTouchEnabled(true)
                        disagree:setTouchEnabled(true)
                    end)))
                end
            end
        )

        disagree:addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                    print("cancel")
                    local input_msg = {
                        cmd = NetCmd.C2S_APPLY_START_AGREE,
                        typ = 0,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                    agree:setTouchEnabled(false)
                    disagree:setTouchEnabled(false)
                    disagree:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
                        agree:setTouchEnabled(true)
                        disagree:setTouchEnabled(true)
                    end)))
                end
            end
        )

        commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
        commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))

        if rtn_msg.self then
            ccui.Helper:seekWidgetByName(node, "btn-agree"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "btn-agree"):setTouchEnabled(false)

            ccui.Helper:seekWidgetByName(node, "btn-disagree"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "btn-disagree"):setTouchEnabled(false)

        end
    end
end

function commonlib.stenHead(head_node, scale)

    local  model = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_headReady.png")

    scale      = scale or 0.95
    local size = model:getContentSize()

    local headNode = cc.ClippingNode:create()
    headNode:setInverted(false)
    headNode:setAlphaThreshold(0)
    headNode:setContentSize(cc.size(size))
    headNode:setPosition(cc.p(size.width * 0.5 * scale, size.height * 0.5 * scale))

    headNode:setStencil(model)

    local img_head = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_headReady.png")
    headNode:addChild(img_head)

    headNode:setScale(scale)

    head_node:addChild(headNode)

    return img_head
end

function commonlib.sendJiesan(is_game_start, is_room_owner, is_tips)
    if not is_game_start then
        if is_room_owner then
            local input_msg = {
                cmd = NetCmd.C2S_JIESAN,
            }
            ymkj.SendData:send(json.encode(input_msg))
        else
            commonlib.showTipDlg("您确定离开房间吗？", function(is_ok)
                if is_ok then
                    local input_msg = {
                        cmd = NetCmd.C2S_LEAVE_ROOM,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                end
            end)
        end
    else
        commonlib.showTipDlg("您确定申请解散房间吗？", function(is_ok)
            if is_ok then
                local input_msg = {
                    cmd = NetCmd.C2S_APPLY_JIESAN,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)
    end
end

-- 申请快速开始游戏
function commonlib.sendQuckStart(is_game_start, is_room_owner, is_tips)
    -- 游戏未开始
    if not is_game_start then
        local input_msg = {
            cmd = NetCmd.C2S_APPLY_START,
        }
        ymkj.SendData:send(json.encode(input_msg))
        -- if is_room_owner then
        --     -- 房主
        --     -- local input_msg = {
        --     --     cmd =NetCmd.C2S_JIESAN,
        --     -- }
        --     -- ymkj.SendData:send(json.encode(input_msg))
        -- else
        --     -- 其它成员
        --     -- commonlib.showTipDlg("您确定快速开始游戏吗？", function(is_ok)
        --     --     if is_ok then
        --     --         local input_msg = {
        --     --             cmd =NetCmd.C2S_LEAVE_ROOM,
        --     --         }
        --     --         ymkj.SendData:send(json.encode(input_msg))
        --     --     end
        --     -- end)
        -- end
    end
end

function commonlib.showSysTime(label, time)
    local time = time or os.time()
    label:setString(os.date("%m-%d %H:%M:%S", time))
    label:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        time = time + 1
        label:setString(os.date("%m-%d %H:%M:%S", time))
    end))))
end

local loading_node = nil
function commonlib.showLoading(is_hide, callfunc)
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene then
        loading_node = runningScene:getChildByName('loading_node')
        if loading_node then
            loading_node:removeFromParent(true)
            loading_node = nil
        end
    else
        loading_node = nil
    end
    if not is_hide then

        loading_node = tolua.cast(cc.CSLoader:createNode("ui/loading.csb"), "ccui.Widget")
        cc.Director:getInstance():getRunningScene():addChild(loading_node, 999999)

        loading_node:setName('loading_node')

        loading_node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(loading_node)

        local active = cc.CSLoader:createTimeline("ui/loading.csb")
        loading_node:runAction(active)

        active:gotoFrameAndPlay(0, true)

        loading_node:runAction(cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
            if loading_node then
                loading_node:removeFromParent(true)
                loading_node = nil
            end
            if callfunc then
                callfunc()
            else
                commonlib.showLocalTip("网络超时，请在稳定的网络环境中游戏。")
            end
        end)))
    end
end

function commonlib.showSeZiLoading(is_hide, callfunc)
    logUp('过渡动画')
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene then
        local club_se_zi_node = runningScene:getChildByName('club_se_zi_node')
        if club_se_zi_node then
            club_se_zi_node:removeFromParent(true)
            club_se_zi_node = nil
        end
    else
        club_se_zi_node = nil
    end

    if not is_hide then
        logUp('过渡动画 显示')
        local club_se_zi_node = gt.createMaskLayer()
        club_se_zi_node:setLocalZOrder(999999)
        club_se_zi_node:setName('club_se_zi_node')
        cc.Director:getInstance():getRunningScene():addChild(club_se_zi_node)
        club_se_zi_node:setTouchEnabled(true)

        local _name      = 'jiazai'
        local spineFile  = 'ui/qj_club/jiazai/jiazai'
        local animation1 = 'animation'

        if _name == 'jiazai' then
            spineFile = 'ui/qj_club/jiazai/jiazai'
            time      = 0.5
        end
        if not spineFile then return end
        skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
        skeletonNode:setScale(1)
        skeletonNode:setAnimation(0, animation1, true)

        local windowSize = cc.Director:getInstance():getWinSize()
        skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
        club_se_zi_node:addChild(skeletonNode, 100)

        local function removeSkeletonNode()
            skeletonNode:removeFromParent()
            club_se_zi_node:removeFromParent()
        end
        local action = cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(removeSkeletonNode))
        club_se_zi_node:runAction(action)

        -- skeletonNode:registerSpineEventHandler(function (event)
        --     -- if event.loopCount == 1 then
        --         local function removeSkeletonNode()
        --             skeletonNode:removeFromParent()
        --             club_se_zi_node:removeFromParent()
        --         end
        --         local action = cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(removeSkeletonNode))
        --         club_se_zi_node:runAction(action)
        --     -- end

        -- end, 2)

    end

    -- local runningScene = cc.Director:getInstance():getRunningScene()
    -- if runningScene then
    --     loading_node = runningScene:getChildByName('loading_node')
    --     if loading_node then
    --         loading_node:removeFromParent(true)
    --         loading_node = nil
    --     end
    -- else
    --     loading_node = nil
    -- end
    -- if not is_hide then

    --     loading_node = tolua.cast(cc.CSLoader:createNode("ui/loading.csb"), "ccui.Widget")
    --     cc.Director:getInstance():getRunningScene():addChild(loading_node, 999999)

    --     loading_node:setName('loading_node')

    --     loading_node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    --     ccui.Helper:doLayout(loading_node)

    --     local active = cc.CSLoader:createTimeline("ui/loading.csb")
    --     loading_node:runAction(active)

    --     active:gotoFrameAndPlay(0, true)

    --     loading_node:runAction(cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
    --         if loading_node then
    --             loading_node:removeFromParent(true)
    --             loading_node = nil
    --         end
    --         if callfunc then
    --             callfunc()
    --         else
    --             commonlib.showLocalTip("网络超时，请在稳定的网络环境中游戏。")
    --         end
    --     end)))
    -- end
end

function commonlib.distanceLatLon(lon1, lat1, lon2, lat2)
    if not lon1 or not lat1 or not lon2 or not lat2 then
        return 5000
    end

    if lon1 == 0 and lat1 == 0 then
        return 5000
    end

    if lon2 == 0 and lat2 == 0 then
        return 5000
    end

    local er = 6378137

    local radlat1 = math.pi * lat1 / 180.0
    local radlat2 = math.pi * lat2 / 180.0

    local radlong1 = math.pi * lon1 / 180.0
    local radlong2 = math.pi * lon2 / 180.0

    if(radlat1 < 0) then radlat1 = math.pi / 2 + math.abs(radlat1) end
    if(radlat1 > 0) then radlat1 = math.pi / 2 - math.abs(radlat1) end
    if(radlong1 < 0) then radlong1 = math.pi * 2 - math.abs(radlong1) end
    if(radlat2 < 0) then radlat2 = math.pi / 2 + math.abs(radlat2) end
    if(radlat2 > 0) then radlat2 = math.pi / 2 - math.abs(radlat2) end
    if(radlong2 < 0) then radlong2 = math.pi * 2 - math.abs(radlong2) end

    local x1 = er * math.cos(radlong1) * math.sin(radlat1);
    local y1 = er * math.sin(radlong1) * math.sin(radlat1);
    local z1 = er * math.cos(radlat1);
    local x2 = er * math.cos(radlong2) * math.sin(radlat2);
    local y2 = er * math.sin(radlong2) * math.sin(radlat2);
    local z2 = er * math.cos(radlat2);
    local d  = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2))

    local theta = math.acos((er * er + er * er - d * d) / (2 * er * er))
    local dist  = theta * er

    return dist
end

function commonlib.openWeb(url)
    if g_os == "ios" then
        local old_node = cc.Director:getInstance():getRunningScene():getChildByTag(189189)
        if old_node then
            old_node:removeFromParent(true)
        end
        ymkj.closeWeb()

        local node = tolua.cast(cc.CSLoader:createNode("ui/zfzx.csb"), "ccui.Widget")
        cc.Director:getInstance():getRunningScene():addChild(node, 999999, 189189)

        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(node)

        ccui.Helper:seekWidgetByName(node, "btn-exit"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                    node:removeFromParent(true)
                    ymkj.closeWeb()
                end
            end
        )
    end

    print(url)
    ymkj.openWeb(url, 0)
end

-- 截取中英混合的UTF8字符串，endIndex可缺省
function commonlib.subStr(str, startIndex, endIndex)
    local totalIndex = commonlib.subStrGetTotalIndex(str)
    if startIndex < 0 then
        startIndex = totalIndex + startIndex + 1;
    end

    if endIndex ~= nil then
        if endIndex < 0 then
            endIndex = totalIndex + endIndex + 1;
        else
            endIndex = math.min(totalIndex, endIndex)
        end
    end

    if endIndex == nil then
        return string.sub(str, commonlib.subStrGetTrueIndex(str, startIndex));
    else
        return string.sub(str, commonlib.subStrGetTrueIndex(str, startIndex), commonlib.subStrGetTrueIndex(str, endIndex + 1) - 1);
    end
end

-- 获取中英混合UTF8字符串的真实字符数量
function commonlib.subStrGetTotalIndex(str)
    local curIndex  = 0;
    local i         = 1;
    local lastCount = 1;
    repeat
        lastCount = commonlib.subStrGetByteCount(str, i)
        i         = i + lastCount;
        curIndex  = curIndex + 1;
    until(lastCount == 0);
    return curIndex - 1;
end

function commonlib.subStrGetTrueIndex(str, index)
    local curIndex  = 0;
    local i         = 1;
    local lastCount = 1;
    repeat
        lastCount = commonlib.subStrGetByteCount(str, i)
        i         = i + lastCount;
        curIndex  = curIndex + 1;
    until(curIndex >= index);
    return i - lastCount;
end

-- 返回当前字符实际占用的字符数
function commonlib.subStrGetByteCount(str, index)
    local curByte   = string.byte(str, index)
    local byteCount = 1;
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte >= 192 and curByte <= 223 then
        byteCount = 2
    elseif curByte >= 224 and curByte <= 239 then
        byteCount = 3
    elseif curByte >= 240 and curByte <= 247 then
        byteCount = 4
    end
    return byteCount;
end

local emo_list = {
    [1]  = {prefix = "ziya_0", num = 5},
    [2]  = {prefix = "bang_0", num = 8},
    [3]  = {prefix = "touxiao_0", num = 9},
    [4]  = {prefix = "kelian_0", num = 3},
    [5]  = {prefix = "daku_0", num = 3},
    [6]  = {prefix = "chat_face_", num = 4},
    [7]  = {prefix = "chat_fac_", num = 2},
    [8]  = {prefix = "qinqin_", num = 8},
    [9]  = {prefix = "kanren_0", num = 2},
    [10] = {prefix = "song_0", num = 8},
    [11] = {prefix = "shaoxiang", num = 8},
    [12] = {prefix = "xishou", num = 8},
}

function commonlib.bqani(index, delay_time)
    local frames = {}
    for i = 1, emo_list[index].num do
        local texture       = cc.Director:getInstance():getTextureCache():addImage("ui/club/emo/expression_"..index.."/"..emo_list[index].prefix..i..".png")
        local texSize       = texture:getContentSize()
        frames[#frames + 1] = cc.SpriteFrame:createWithTexture(texture, cc.rect(0, 0, texSize.width, texSize.height))
    end
    local animation = cc.Animation:createWithSpriteFrames(frames, delay_time or 0.2)
    return animation
end

local emojConf = {
    [1]  = "yeyeye",             -- 666
    [2]  = "bixue",              -- 吐
    [3]  = "bingdong",           -- 晕星星
    [4]  = "fanu",               -- 怒火
    [5]  = "fankun",             -- 哈欠
    [6]  = "guzhang",            -- 加油
    [7]  = "guilian",            -- 呵呵
    [8]  = "jiong",              -- 哭
    [9]  = "ku",                 -- 白旗
    [10] = "liuhan",            -- 汗
    [11] = "shihua",            -- 我伙呆
    [12] = "tiaopi",            -- 含情
    [13] = "toukui",            -- 得意
    [14] = "weiqu",             -- 可怜
    [15] = "xianmu",            -- 色
    [16] = "shangxiang",        -- 烧香

    [17] = "saizi_yue",
    [18] = "saizi_dou",
    [19] = "saizi_hun",
    [20] = "saizi_liang",
    [21] = "saizinv",
    [22] = "saizi_qian",
    [23] = "saizi_shui",
    [24] = "saizi_xiao",
    [25] = "saizi_xin",
    [26] = "saizi_xiu",
    [27] = "saizi_yun",
    [28] = "saizi_ding",
}

function commonlib.playbq(bq_index, pos, is_club, sex)
    if not emojConf[bq_index] then return end
    local fileJson = "ui/chat/biaoqingALL0/biaoqingALL0.ExportJson"
    local aniName  = "biaoqingALL0"
    if bq_index > 16 then
        local jsonFile     = "ui/chat/biaoqiDH/biaoqiDH.json"
        local atlasFile    = "ui/chat/biaoqiDH/biaoqiDH.atlas"
        local skeletonNode = sp.SkeletonAnimation:create(jsonFile, atlasFile, 1)
        skeletonNode:registerSpineEventHandler(function (event)
            print(string.format("[spine] %d complete: %d",
                event.trackIndex,
            event.loopCount))
            skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.RemoveSelf:create()))
        end, 2)

        skeletonNode:setAnchorPoint(0.5, 0)
        skeletonNode:setAnimation(0, emojConf[bq_index], true)
        skeletonNode:setPosition(pos)
        return skeletonNode
    end
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
    local armature = ccs.Armature:create(aniName)
    local function animationEvent(armatureBack, movementType, movementID)
        print("movementType", movementType)
        if movementType == 2 then
            -- armature:removeSelf()
        end
    end
    armature:setAnchorPoint(0.5, 0.5)
    armature:getAnimation():setMovementEventCallFunc(animationEvent)
    armature:getAnimation():play(emojConf[bq_index])
    armature:setPosition(pos)
    armature:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.RemoveSelf:create()))
    return armature
end

function commonlib.split(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^'..reps..']+', function (w)
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

function commonlib.appendTable(src, appendDes)
    local newTable = src or {}
    for _, v in ipairs(appendDes or {}) do
        newTable[#newTable + 1] = v
    end
    return newTable
end

function commonlib.insertSort(arr, func)
    local starttime = os.clock()
    local i         = nil
    local j         = nil
    local temp      = nil
    for i = 2, #arr do
        for j = 1, i - 1 do
            if func(arr[i], arr[j]) then
                temp   = arr[i]
                arr[i] = arr[j]
                arr[j] = temp
            end
        end
    end
    local endtime = os.clock()
    print(string.format("排序成员 cost time  : %.4f", endtime - starttime))
end