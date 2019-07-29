local ClubJointNumberPanel = class("ClubJointNumberPanel", function()
    return cc.Layer:create()
end)

function ClubJointNumberPanel:create(args)
    local layer = ClubJointNumberPanel.new()
    layer.clubs = args.clubs
    layer:createLayerMenu()
    return layer
end

function ClubJointNumberPanel:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_JoinroomLayer.csb"), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    local number     = 0
    local number_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "tRoomID"), "ccui.Text")
    number_lbl:setString("请输入亲友圈ID")

    local function beyondNumberLong()
        local clueName = number_lbl:getString()
        if(string.len(clueName) > 10) then
            number = 0
            number_lbl:setString("请输入亲友圈ID")
            commonlib.showLocalTip("无效亲友较圈号，请重新输入")
            return
        end
    end

    for i = 0, 9 do
        ccui.Helper:seekWidgetByName(node, string.format("%d", i)):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                number = number * 10 + i
                number_lbl:setString(number)

                beyondNumberLong()
            end
        end)
    end

    ccui.Helper:seekWidgetByName(node, "btReinput"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            number = 0
            number_lbl:setString("请输入亲友圈ID")
        end
    end)

    ccui.Helper:seekWidgetByName(node, "btOk"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            beyondNumberLong()

            local num = tonumber(number_lbl:getString())
            for i, v in ipairs(self.clubs or {}) do
                if v.club_id == num then
                    commonlib.showLocalTip('您已存在当前亲友圈[' .. num .. ']中，请重新输入')
                    return
                end
            end
            if num then
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_APPLY_JOIN,
                    club_id = num,
                }
                ymkj.SendData:send(json.encode(input_msg))
                self:removeFromParent(true)
            else
                commonlib.showLocalTip("请输入亲友圈ID")
            end
        end
    end)
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))

    ccui.Helper:seekWidgetByName(node, "btDel"):setVisible(false)
end

return ClubJointNumberPanel