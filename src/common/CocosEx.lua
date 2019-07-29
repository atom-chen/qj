--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-09-06
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2018-09-06
-- @Desc:
--------------------------------------------------------------------------------
director        = cc.Director:getInstance()
eventDispatcher = director:getEventDispatcher()
openGLView      = director:getOpenGLView()

local Node  = cc.Node
local Scene = cc.Scene
local Layer = cc.Layer
local Menu  = cc.Menu

-- 为node扩展一个判断点击区域的方法
function Node:hitTestEx(point)
    local nsp = self:getParent():convertToNodeSpace(point)
    local bb  = self:getBoundingBox()
    if (cc.rectContainsPoint(bb, nsp)) then
        return true
    end
    return false
end

-- 为node注册一个点击事件,注意设置node大小区域
function Node:addOnClick(fun)
    self:addOnTouch(function(touch, event)
        local point = touch:getLocation()
        return self:hitTestEx(point)
    end,
    nil,
    function(touch, event)
        local point = touch:getLocation()
        if self:hitTestEx(point) then
            fun(touch, event)
        end
    end)
end

-- 为node注册触摸事件
function Node:addOnTouch(funBegin, funMoved, funEnded, swallow)
    local listenner = cc.EventListenerTouchOneByOne:create()
    listenner:setSwallowTouches(swallow or false)
    listenner:registerScriptHandler(function(touch, event)
        return funBegin(touch, event)
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    if funMoved then
        listenner:registerScriptHandler(function(touch, event)
            funMoved(touch, event)
        end, cc.Handler.EVENT_TOUCH_MOVED)
    end
    if funEnded then
        listenner:registerScriptHandler(function(touch, event)
            funEnded(touch, event)
        end, cc.Handler.EVENT_TOUCH_ENDED)
    end
    eventDispatcher:addEventListenerWithSceneGraphPriority(listenner, self)
end

function Node:removeAllRegistedObject()
    gt.clearLayerStack() -- 移除层堆栈
    gt.removeEventListenersForTarget(self) -- 移除所有的事件监听器
    scheduler.unscheduleAllForTarget(self) -- 移除所有的循环任务
end

-- 添加精灵
function Node:addSprite(source, point, zOrder)
    point        = point or {}
    local sprite = display.newSprite(source, point.x, point.y)
    if zOrder then
        sprite:setLocalZOrder(zOrder)
    end
    self:addChild(sprite)
    return sprite
end

-- 添加cs(cocos studio)结点
function Node:addCSNode(name, zOrder)
    local csNode = cc.CSLoader:createNode(name)

    if not csNode then
        return nil
    end

    csNode:setAnchorPoint(cc.p(0.5, 0.5))
    csNode:setPosition(VCenter)
    if zOrder then
        csNode:setLocalZOrder(zOrder)
    end

    self:addChild(csNode)

    return csNode
end

-- 添加带动画的cs结点
function Node:addCSAniNode(name, zOrder)
    local csNode   = self:addCSNode(name, zOrder)
    local timeLine = cc.CSLoader:createTimeline(name)
    csNode:runAction(timeLine)

    return csNode, timeLine
end

-- 用指定的节点替换cs节点
-- @param name 要被替换的cs节点名字
-- @param target 用来替换的节点
-- @param isHide 替换后，原来的cs节点是否隐藏，默认为隐藏
-- @param isRemove 替换后，原来的cs节点是否删除，默认为删除
function Node:replaceCSNode(name, target, isHide, isRemove)
    local tmp      = self:seekNode(name)
    local position = cc.p(tmp:getPosition())
    target:setPosition(position)
    tmp:getParent():addChild(target)
    isHide = isHide or true
    if isHide then
        tmp:setVisible(false)
    else
        tmp:setVisible(true)
    end
    isRemove = isRemove or true
    if isRemove then
        tmp:removeFromParent()
    end
end

-- 根据指定名字查找cs结点
function Node:seekNode(name)
    if not name then
        return nil
    end

    if self:getName() == name then
        return self
    end

    local children = self:getChildren()
    if not children or #children == 0 then
        return nil
    end
    for i, parentNode in ipairs(children) do
        local childNode = parentNode:seekNode(name)
        if childNode then
            return childNode
        end
    end

    return nil
end

-- 打印cs结构树
function Node:printNode(prefix)
    local prefix = prefix or ""

    printInfo(prefix .. self:getName())

    local children = self:getChildren()
    if not children or #children == 0 then
        return
    end
    for i, parentNode in ipairs(children) do
        parentNode:printNode(prefix .. "--|")
    end
end

-- 给cs按钮控件添加事件监听器
function Node:addBtListener(btName, listener, isScale)
    local bt = self:seekNode(btName)
    if not bt then
        return nil
    end

    if not listener then
        return nil
    end

    bt:addClickEventListener(function(sender)
        listener(sender)
    end)

    isScale = isScale or false
    if isScale then
        bt:setPressedActionEnabled(true)
        bt:setZoomScale(-0.1)
    end

    return bt
end

-- 为场景添加键盘事件监听器
function Scene:addKeyListener(callback)
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(callback, cc.Handler.EVENT_KEYBOARD_RELEASED)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

-- 给layer添加全部填充背景
function Layer:addBackground(sprite)
    local background = nil

    if type(sprite) == "string" then
        background = display.newSprite(sprite)
    elseif type(sprite) == "userdata" then
        background = sprite
    end

    if not background then
        return nil
    end

    local frameVisibleRect = VisibleRect.getVisibleMaxRect().size
    local backgroundSize   = background:getTextureRect()
    local scaleX           = frameVisibleRect.width / backgroundSize.width
    local scaleY           = frameVisibleRect.height / backgroundSize.height
    local scale            = 0
    if scaleX > scaleY then
        scale = scaleX
    else
        scale = scaleY
    end
    background:setScale(scale);
    background:setPosition(VCenter)

    self:addChild(background)

    return background
end

-- 创建菜单项
function Layer:createMenuItem(normal, selected, text)
    local normalSprite = display.newSprite(normal)
    local selectedSprite
    local textSprite
    if selected then
        selectedSprite = display.newSprite(selected)
    end
    if text then
        textSprite = display.newSprite(text)
    end
    local menuItem = cc.MenuItemSprite:create(normalSprite, selectedSprite)
    if textSprite then
        local size = menuItem:getContentSize()
        textSprite:setPosition(cc.p(size.width / 2, size.height / 2))
        menuItem:addChild(textSprite)
    end
    return menuItem
end

-- 添加菜单项
function Menu:addMenuItem(menuItem, x, y, callback)
    menuItem:setPosition(cc.p(x, y))
    menuItem:registerScriptTapHandler(callback)
    self:addChild(menuItem)
end