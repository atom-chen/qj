local BaseLayer = require("modules.view.BaseLayer")
local RedBagActionLayer = class("RedBagActionLayer",BaseLayer)

-- MainScene层级关系
local ZOrder = {
    BG     = 1,
    DIALOG = 2,
    TIP    = 3,
    GRID   = 100,
}

-- 字体设置
local ttfConfig = {}
ttfConfig.fontFilePath="ui/zhunyuan.ttf"
ttfConfig.fontSize=28
ttfConfig.glyphs=cc.GLYPHCOLLECTION_CUSTOM

function RedBagActionLayer:ctor()
    self:setName("RedBagActionLayer")
    BaseLayer.ctor(self)
end

function RedBagActionLayer:onEnter()
    BaseLayer.onEnter(self)

    -- 添加红包引导动画层
    local actionName = ""
    local pass = nil
    local node_RedBagAction = tolua.cast(cc.CSLoader:createNode("ui/DT_RedBagActionLayer.csb"),"ccui.Widget")
    self:addChild(node_RedBagAction)
    -- 点击背景继续动画
    local panel_RedBagAction = tolua.cast(node_RedBagAction:getChildByName("Panel_hongbao"),"ccui.Widget")
    panel_RedBagAction:setContentSize(g_visible_size)
    ccui.Helper:doLayout(panel_RedBagAction)
    local Armature_RedBagAction = panel_RedBagAction:getChildByName("Armature_hongbao")
    panel_RedBagAction:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if pass and actionName == "caisheng_1" then
                pass = false
                actionName = "caisheng_2"
                Armature_RedBagAction:getAnimation():play("caisheng_2")
            elseif pass and actionName == "caisheng_3" then
                cc.UserDefault:getInstance():setStringForKey("action_RedBag","true")
                self:removeSelf()
            end
        end
    end)
    -- 点击红包按钮继续动画
    local btn_hongbaobtn = panel_RedBagAction:getChildByName("btn_hongbao")
    btn_hongbaobtn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if eventType == ccui.TouchEventType.ended then
                local RedBagLayer = require("modules.view.RedBagLayer")
                local layer = RedBagLayer:create()
                self:getParent():addChild(layer,ZOrder.DIALOG)

                actionName = "hongbao"
                local pos = Armature_RedBagAction:getPositionX()
                Armature_RedBagAction:setPositionX(pos-50)
                Armature_RedBagAction:getAnimation():play("hongbao")

                btn_hongbaobtn:removeSelf()
            end
        end
    end)
    -- 动画完成的回调
    Armature_RedBagAction:getAnimation():setMovementEventCallFunc(function(armatureBack,movementType,movementID)
        -- 不要问我movementType是什么，我也不知道，去看打印
        -- 动画运行结束会给movementType传一个值
        if movementType == 1 and actionName == "caisheng_1" then
            Armature_RedBagAction:getAnimation():stop()
            pass = true
        elseif movementType == 2 and actionName == "caisheng_2" then
            Armature_RedBagAction:getAnimation():stop()
            btn_hongbaobtn:setVisible(true)
            actionName = "jiantou"
            Armature_RedBagAction:getAnimation():play("jiantou")
            local pos = Armature_RedBagAction:getPositionX()
            Armature_RedBagAction:setPositionX(pos+50)
        elseif movementType == 2 and actionName == "hongbao" then
            Armature_RedBagAction:getAnimation():stop()
            actionName = "qian"
            Armature_RedBagAction:getAnimation():play("qian")
        elseif movementType == 2 and actionName == "qian" then
            Armature_RedBagAction:getAnimation():stop()
            actionName = "caisheng_3"
            Armature_RedBagAction:getAnimation():play("caisheng_3")
            local posX = Armature_RedBagAction:getPositionX()
            local posY = Armature_RedBagAction:getPositionY()
            local str = "恭喜你获得“财神到”\n红包一个祝您好运！"
            local label = cc.Label:createWithTTF(ttfConfig,str, cc.TEXT_ALIGNMENT_LEFT)
            panel_RedBagAction:addChild(label)
            label:setColor(cc.c3b(208,59,40))
            label:setAnchorPoint(cc.p(0,0.5))
            label:setPosition(posX+200,posY+210)
            label:setVisible(false)
            label:runAction(cc.RepeatForever:create(cc.Sequence:create(
                cc.DelayTime:create(0.5),
                cc.CallFunc:create(function()
                    label:setVisible(true)
                end))))
        elseif movementType == 1 and actionName == "caisheng_3" then
            Armature_RedBagAction:getAnimation():stop()
            pass = true
        end
    end)
    -- 开始播放动画
    pass = false
    actionName = "caisheng_1"
    Armature_RedBagAction:getAnimation():play("caisheng_1")
end

function RedBagActionLayer:onExit()
    BaseLayer.onExit(self)
end

return RedBagActionLayer

