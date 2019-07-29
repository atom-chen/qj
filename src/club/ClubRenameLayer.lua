require('club.ClubHallUI')

local ClubRenameLayer = class("ClubRenameLayer", function()
    return cc.Layer:create()
end)

function ClubRenameLayer:create(args)
    local layer = ClubRenameLayer.new()
    layer.data  = args.data
    layer:createLayerMenu()
    return layer
end

function ClubRenameLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_rename_club
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:removeFromParent(true)
        end
    end)

    local imgInvaild = ccui.Helper:seekWidgetByName(node, "imgInvaild")
    imgInvaild:setVisible(false)
    local tQyqName = ccui.Helper:seekWidgetByName(node, "tQyqName")

    local btXG = tolua.cast(ccui.Helper:seekWidgetByName(node, "btXG"), "ccui.Button")
    btXG:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local ShieldWord = require("common.ShieldWord")
            local str        = tQyqName:getString()
            str              = string.trim(str)
            local oldlen = string.len(str)
            str = gt.filter_spec_chars(str)
            local newlen = string.len(str)
            if str == "" then
                if newlen ~= oldlen then
                    commonlib.showLocalTip("名称不能有特殊字符")
                    return
                else
                    commonlib.showLocalTip("名称不能为空")
                end
                -- tQyqName:setString("")
            elseif string.find(str, " ") or ShieldWord:CheckShieldWord(str) then
                tQyqName:setString("")
                imgInvaild:setVisible(true)
            else
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_MODIFY,
                    name    = str,
                    club_id = self.data.club_info.club_id,
                }
                ymkj.SendData:send(json.encode(input_msg))
                self:removeFromParent(true)
            end
        end
    end)

    local imgReNameMoney = ccui.Helper:seekWidgetByName(node, "imgReNameMoney")
    local tReNameMoney   = ccui.Helper:seekWidgetByName(node, "tReNameMoney")
    if self.data.club_info.isChangedName then
        tReNameMoney:setString('本次修改名称需要30 房卡')
        imgReNameMoney:setVisible(true)
    else
        tReNameMoney:setString('可免费修改一次名字')
        imgReNameMoney:setVisible(false)
    end

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

return ClubRenameLayer