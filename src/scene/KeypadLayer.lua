local KeypadLayer = class("KeypadLayer", function()
    return cc.Layer:create()
end)

function KeypadLayer:create(outLabel, FindBtn)
    local layer = KeypadLayer.new()
    layer:createLayerMenu(outLabel, FindBtn)
    return layer
end

function KeypadLayer:createLayerMenu(outLabel, FindBtn)
    local wordLimit = 10
    local node      = tolua.cast(cc.CSLoader:createNode("ui/keypad.csb"), "ccui.Widget")
    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                outLabel:setString("")
                if FindBtn then
                    FindBtn:setColor(cc.c3b(255, 255, 255))
                end
                self:removeFromParent(true)
            end
        end
        )

    local str = outLabel:getString()
    print("init str", str)
    local lab = ccui.Helper:seekWidgetByName(node, "lab")
    lab:setString(str)

    for i = 0, 9 do
        ccui.Helper:seekWidgetByName(node, string.format("%d", i)):addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    if #str < wordLimit then
                        str = str .. i
                        lab:setString(str)
                        outLabel:setString(str)
                    else
                        commonlib.showLocalTip("长度超过了限制")
                    end
                end
            end
        )
    end

    ccui.Helper:seekWidgetByName(node, "btn-cxsr"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            str = ""
            lab:setString(str)
            outLabel:setString(str)
        end
    end)

    ccui.Helper:seekWidgetByName(node, "btn-shanchu"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if #str > 0 then
                str = string.sub(str, 1, #str - 1)
            end
            lab:setString(str)
            outLabel:setString(str)
        end
    end)

    ccui.Helper:seekWidgetByName(node, "Button_1"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if FindBtn and #str > 0 then
                FindBtn:setColor(cc.c3b(255, 0, 0))
                FindBtn:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(1, 0.7), cc.ScaleTo:create(1, 1))))
            end
            self:removeFromParent(true)
        end
    end)
end

return KeypadLayer