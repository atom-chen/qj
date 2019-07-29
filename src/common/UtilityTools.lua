--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Email: liyongjin2009@gmail.com
-- @Date:   2017-03-25
-- @Last Modified by:   liyongjin
-- @Last Modified time: 2017-03-29
-- @Desc: 框架工具类
--------------------------------------------------------------------------------
cc.exports.gt = gt or {}

local tab = {
    fontNormal = "res/ui/zhunyuan.ttf",

    scheduler      = cc.Director:getInstance():getScheduler(),
    targetPlatform = cc.Application:getInstance():getTargetPlatform(),

    -- 触摸屏蔽层不透明度
    MASK_LAYER_OPACITY = 175,
}

for k, v in pairs(tab) do
    gt[k] = v
end

-- 添加自定义事件监听器
local function addCustomEventListener(event, callback)
    local closure = function(customEvent)
        local msg = customEvent:getUserData()
        callback(msg)
    end
    local listener = cc.EventListenerCustom:create(event, closure)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
end
gt.addCustomEventListener = addCustomEventListener

-- 添加网络消息监听器
local function addNetMsgListener(event, callback)
    local closure = function(customEvent)
        local eventStr = customEvent:getUserData()
        local msg      = json.decode(eventStr, true)
        if msg then
            callback(msg)
        else
            local errStr = string.format("json.decode(eventStr) nil event = %s eventStr = %s", tostring(event), tostring(eventStr))
            gt.uploadErr(errStr)
        end
    end
    local listener = cc.EventListenerCustom:create(event, closure)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
end
gt.addNetMsgListener = addNetMsgListener

-- 创建触摸屏蔽层
-- @param number opacity 不透明度，0完全透明，255全黑不透明
local function createMaskLayer(opacity)
    if not opacity then
        -- 用默认透明度
        opacity = gt.MASK_LAYER_OPACITY
    end

    local maskLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, opacity), VWinSize.width, VWinSize.height)
    maskLayer:addOnTouch(function()
        return true
    end, nil, nil, true)

    return maskLayer
end
gt.createMaskLayer = createMaskLayer

-- 得到本地保存值
local function getLocal(type, key, default)
    if type == "boolean" then
        if default == nil then
            default = false
        end
        return cc.UserDefault:getInstance():getBoolForKey(key, default)
    elseif type == "int" then
        return cc.UserDefault:getInstance():getIntegerForKey(key, default or 0)
    elseif type == "float" then
        return cc.UserDefault:getInstance():getFloatForKey(key, default or 0)
    elseif type == "string" then
        return cc.UserDefault:getInstance():getStringForKey(key, default or "")
    end
end
gt.getLocal = getLocal

local function getLocalBool(key, default)
    if default == nil then
        default = false
    end
    return cc.UserDefault:getInstance():getBoolForKey(key, default)
end
gt.getLocalBool = getLocalBool

local function getLocalInt(key, default)
    return cc.UserDefault:getInstance():getIntegerForKey(key, default or 0)
end
gt.getLocalInt = getLocalInt

local function getLocalFloat(key, default)
    return cc.UserDefault:getInstance():getFloatForKey(key, default or 0.0)
end
gt.getLocalFloat = getLocalFloat

local function getLocalString(key, default)
    return cc.UserDefault:getInstance():getStringForKey(key, default or "")
end
gt.getLocalString = getLocalString

-- 设置本地保存值
local function setLocal(type, key, value, isFlush)
    local result = nil
    if type == "bool" then
        result = cc.UserDefault:getInstance():setBoolForKey(key, value)
    elseif type == "int" then
        result = cc.UserDefault:getInstance():setIntegerForKey(key, value)
    elseif type == "float" then
        result = cc.UserDefault:getInstance():setFloatForKey(key, value)
    elseif type == "string" then
        result = cc.UserDefault:getInstance():setStringForKey(key, value)
    end

    if isFlush then
        cc.UserDefault:getInstance():flush()
    end

    return result
end
gt.setLocal = setLocal

local function setLocalBool(key, value, isFlush)
    local result = cc.UserDefault:getInstance():setBoolForKey(key, value)
    if isFlush then
        cc.UserDefault:getInstance():flush()
    end
end
gt.setLocalBool = setLocalBool

local function setLocalInt(key, value, isFlush)
    local result = cc.UserDefault:getInstance():setIntegerForKey(key, value)
    if isFlush then
        cc.UserDefault:getInstance():flush()
    end
end
gt.setLocalInt = setLocalInt

local function setLocalFloat(key, value, isFlush)
    local result = cc.UserDefault:getInstance():setFloatForKey(key, value)
    if isFlush then
        cc.UserDefault:getInstance():flush()
    end
end
gt.setLocalFloat = setLocalFloat

local function setLocalString(key, value, isFlush)
    local result = cc.UserDefault:getInstance():setStringForKey(key, value)
    if isFlush then
        cc.UserDefault:getInstance():flush()
    end
end
gt.setLocalString = setLocalString

-- 刷新输出本地保存值
local function flushLocal()
    cc.UserDefault:getInstance():flush()
end
gt.flushLocal = flushLocal

-- 得到今天0点0时0分的时间值
local function getCurrentDayZero()
    local currentDay = os.date("*t", os.time())
    currentDay.hour  = 0
    currentDay.min   = 0
    currentDay.sec   = 0
    return os.time(currentDay)
end
gt.getCurrentDayZero = getCurrentDayZero

-- 浮动文本
gt.golbalZOrder = 10000
local function floatText(content)
    if not content or content == "" then
        return
    end

    local offsetY  = 20
    local rootNode = cc.Node:create()
    rootNode:setCascadeOpacityEnabled(true)
    rootNode:setPosition(cc.p(VCenter.x, VCenter.y - offsetY))

    local bg        = ccui.Scale9Sprite:create("ui/qj_tips/ts_0000_tst-fs8.png")
    local capInsets = cc.size(130, 6)
    bg:setScale9Enabled(true)
    bg:setCapInsets(cc.rect(capInsets.width, capInsets.height, bg:getContentSize().width - capInsets.width * 2, bg:getContentSize().height - capInsets.height * 2))
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setGlobalZOrder(gt.golbalZOrder)
    gt.golbalZOrder = gt.golbalZOrder + 1
    rootNode:addChild(bg)

    local ttfConfig        = {}
    ttfConfig.fontFilePath = gt.fontNormal
    ttfConfig.fontSize     = 38
    local ttfLabel         = cc.Label:createWithTTF(ttfConfig, content)
    ttfLabel:setGlobalZOrder(gt.golbalZOrder)
    gt.golbalZOrder = gt.golbalZOrder + 1
    ttfLabel:setTextColor(cc.c3b(255, 255, 255))
    ttfLabel:enableOutline(cc.c4b(93, 60, 0, 255), 2)
    ttfLabel:setAnchorPoint(cc.p(0.5, 0.5))
    rootNode:addChild(ttfLabel)

    bg:setContentSize(cc.size(ttfLabel:getContentSize().width + capInsets.width * 2, ttfLabel:getContentSize().height + capInsets.height * 2))

    rootNode:setOpacity(0)
    local action = cc.Sequence:create(
        cc.FadeIn:create(0.5),
        cc.DelayTime:create(1),
        cc.FadeOut:create(1),
        cc.CallFunc:create(function()
            rootNode:removeFromParent(true)
        end)
    )
    director:getRunningScene():addChild(rootNode)
    rootNode:runAction(action)
end
gt.floatText = floatText