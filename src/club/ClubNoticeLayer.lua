require('club.ClubHallUI')

local ClubNoticeLayer = class("ClubNoticeLayer", function()
    return cc.Layer:create()
end)

function ClubNoticeLayer:create()
    local layer = ClubNoticeLayer.new()
    layer:createLayerMenu()
    return layer
end

function ClubNoticeLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_notice
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local Panel_top = ccui.Helper:seekWidgetByName(node, "Panel_top")

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btExit"), "ccui.Button")
    btExit:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_top"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

function ClubNoticeLayer:onSelEvent(name)
    print("onSelEvent", name)
end

return ClubNoticeLayer