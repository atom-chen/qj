local TaskHblqSuccLayer = class("TaskHblqSuccLayer", function()
    return cc.Layer:create()
end)

function TaskHblqSuccLayer:create(rtn_msg)
    local layer = TaskHblqSuccLayer.new()
    layer:createLayerMenu(rtn_msg)
    return layer
end

function TaskHblqSuccLayer:createLayerMenu(rtn_msg)
    local node = tolua.cast(cc.CSLoader:createNode("ui/task_hblq_succ.csb"), "ccui.Widget")
    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
        )

    local moneyLabel = ccui.Helper:seekWidgetByName(node, "money")
    local money      = rtn_msg.huodong_money * 0.01
    moneyLabel:setString(string.format("%.2f元", money))
end

return TaskHblqSuccLayer