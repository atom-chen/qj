require('club.ClubHallUI')

local ClubTipLayer = class("ClubTipLayer", function()
    return cc.Layer:create()
end)

function ClubTipLayer:create(args)
    local layer   = ClubTipLayer.new()
    layer.msg     = args.msg
    layer.copyStr = args.copyStr
    layer.okFunc = args.okFunc or function()end
    layer.cancelFunc = args.cancelFunc
    layer:createLayerMenu()
    return layer
end

function ClubTipLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_dialog
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local text = ccui.Helper:seekWidgetByName(node, "wenben")
    text:setString(self.msg)

    local btOk = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-ok"), "ccui.Button")
    btOk:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.okFunc()
            self:removeFromParent(true)
        end
    end)

    if self.cancelFunc then
        local btCancel = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-cancel"), "ccui.Button")
        btCancel:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.cancelFunc()
                self:removeFromParent(true)
            end
        end)

        btOk:setPositionX(btOk:getPositionX() + 200)
        btCancel:setPositionX(btCancel:getPositionX() - 200)
    end

    local btCopy = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-copy"), "ccui.Button")
    if self.copyStr then
        btCopy:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                ymkj.copyClipboard(self.copyStr)
                commonlib.showLocalTip("复制成功")
            end
        end)
    else
        btCopy:setVisible(false)
    end

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

return ClubTipLayer