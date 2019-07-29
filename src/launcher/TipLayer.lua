
local TipLayer = class("TipLayer",function()
    return cc.Layer:create()
end)

function TipLayer:ctor(msg,callfunc)
    local node = tolua.cast(cc.CSLoader:createNode("launcher/tip_upd.csb"), "ccui.Widget")
    self:setName("TipLayer")
    self:addChild(node)
    local director = cc.Director:getInstance()
    local visible_size = director:getVisibleSize()
    node:setContentSize(cc.size(visible_size.width, visible_size.height))
    ccui.Helper:doLayout(node)
    local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text")
    local btnEnter = ccui.Helper:seekWidgetByName(node, "btEnter")
    local btCancel = ccui.Helper:seekWidgetByName(node, "btCancel")
    content:setString(msg)
    btnEnter:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            callfunc(true)
            self:removeFromParent(true)
        end
    end)
    btCancel:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            callfunc(false)
            self:removeFromParent(true)
        end
    end)

    local Panel = ccui.Helper:seekWidgetByName(node, "Panel")
    Panel:setPositionY(display.cy+50)
end

return TipLayer