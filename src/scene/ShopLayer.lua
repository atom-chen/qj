local ShopLayer = class("ShopLayer", function()
    return cc.Layer:create()
end)

function ShopLayer:create()
    local layer = ShopLayer.new()
    layer:createLayerMenu()
    return layer
end

function ShopLayer:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_ShopLayer.csb"), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local tab_1 = ccui.Helper:seekWidgetByName(node, "Tab_1")
    local tab_2 = ccui.Helper:seekWidgetByName(node, "Tab_2")
    tab_2:setVisible(false)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Panel_1"))
                commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Panel_2"), function()
                    self:removeFromParent(true)
                end)

            end
        end)
end

return ShopLayer