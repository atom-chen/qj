--------------------------------------------------------------------------------
-- @Author: iwifigame@126.com
-- @Date: 2018-01-24
-- @Last Modified by: iwifigame@126.com
-- @Last Modified time: 2018-01-24
-- @Desc: 封装inspect
-- 在原始inspect上包装一层，方法名与inspect相同
-- 在封装内统一设置元素处理方法、设置换行符、缩进等
--------------------------------------------------------------------------------
local inspectRaw = require("common.logger.inspect")

function inspect(value)
    return inspectRaw(value, {
        -- 对value中的第一个元素做处理
        process = function(item, path)
            -- 过滤函数
            if type(item) == "function" then
                return nil
            end

            -- 过滤元表
            if path[#path] == inspectRaw.METATABLE then
                return nil
            end

            -- 过滤类class
            if path[#path] == "class" then
                return nil
            end

            -- 将m_msgId转成消息名字
            if path[#path] == 'cmd' then
                return item .. ":" .. (gt.idMap[item] or item)
            end

            return item
        end,
        newline = " ", -- 换行符设置，默认就是\n
        indent  = "" -- 缩进设置
    })
end