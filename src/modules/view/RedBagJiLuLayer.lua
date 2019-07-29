local GrayLayer = require("modules.view.GrayLayer")
local RedBagJiLuLayer = class("RedBagJiLuLayer",GrayLayer)

function RedBagJiLuLayer:ctor()
    self:setName("RedBagJiLuLayer")
    GrayLayer.ctor(self)
end

function RedBagJiLuLayer:onEnter()
    GrayLayer.onEnter(self)

	self.root = tolua.cast(cc.CSLoader:createNode("ui/ui_receiveTip.csb"),"ccui.Widget")
    self:addChild(self.root)

    self.bg = ccui.Helper:seekWidgetByName(self.root, "lqjl_bg")
    self.bg:setContentSize(g_visible_size)
    ccui.Helper:doLayout(self.bg)
    self.bg:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:hideView()
        end
    end)
    self.listview = ccui.Helper:seekWidgetByName(self.root, "ListView_lqjl")

    self:showView()
end

function RedBagJiLuLayer:showView()
    local data = RedBagController:getModel():getHBMy()
    local jilu_item = ccui.Helper:seekWidgetByName(self.listview, "receiveItem")
    local isHasData = false
    if data and next(data)~=nil then -- 已领取
        for _,jilu_data in pairs(data) do
            -- 创建记录列表item
            if jilu_data.status == 1 then
                isHasData = true
                local item = jilu_item
                if _>1 then
                    item = jilu_item:clone()
                    self.listview:pushBackCustomItem(item)
                end
                -- 设置记录列表item信息
                ccui.Helper:seekWidgetByName(item, "time"):setString(jilu_data.time)
                ccui.Helper:seekWidgetByName(item, "money"):setString(""..jilu_data.money*0.01)
            end
        end
        local lqjl_tip = self.listview:getChildByName("lqjl_tip")
        if lqjl_tip then
            lqjl_tip:removeSelf()
        end
    end
    if not isHasData then
        local lqjl_Panel = ccui.Helper:seekWidgetByName(self.root, "lqjl_Panel")
        lqjl_Panel:removeAllChildren()
        local size = lqjl_Panel:getContentSize()
        local lqjl_tip = display.newSprite("ui/qj_redbag/lq_tip.png")
        lqjl_Panel:addChild(lqjl_tip)
        lqjl_tip:setName("lqjl_tip")
        lqjl_tip:setPosition(cc.p(size.width/2, size.height/2))
    end
end

function RedBagJiLuLayer:hideView()
    self:removeSelf()
end

return RedBagJiLuLayer