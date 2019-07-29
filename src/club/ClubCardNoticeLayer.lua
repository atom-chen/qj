require('club.ClubHallUI')

local cmd_list = {
    NetCmd.S2C_CLUB_EXCHANGE_CARD,
}

local ClubCardNoticeLayer = class("ClubCardNoticeLayer", function()
    return cc.Layer:create()
end)

function ClubCardNoticeLayer:create(args)
    local layer = ClubCardNoticeLayer.new(args)
    -- layer:createLayerMenu()
    return layer
end

function ClubCardNoticeLayer:ctor(args)
    self.isAllowCharge = args.isAllowCharge
    self.isBoss        = args.isBoss
    self:createLayerMenu()
    self:registerEventListener()

    self:enableNodeEvents()
end

function ClubCardNoticeLayer:onEnter()

end

function ClubCardNoticeLayer:onExit()
    self:unregisterEventListener()
end

function ClubCardNoticeLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            if rtn_msg.cmd == NetCmd.S2C_CLUB_EXCHANGE_CARD then
                commonlib.showLocalTip("兑换出错！")
            end
        else
            commonlib.showLocalTip(rtn_msg.msg)
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ClubCardNoticeLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubCardNoticeLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_faka_shuoming
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node, 100, 6666)

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

    local btnCommit = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btnCommit"), "ccui.Button")
    btnCommit:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    local btnduihuan = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btnduihuan"), "ccui.Button")
    btnduihuan:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:fangkaChange()
            end
        end
    )
    -- 关闭兑换亲友圈房卡功能
    if self.isAllowCharge == 1 and self.isBoss then
        btnCommit:setPositionX(296.99)
        btnduihuan:setVisible(true)
    else
        btnCommit:setPositionX(494.98)
        btnduihuan:setVisible(false)
    end

    -- local shuoming = ccui.Helper:seekWidgetByName(node,"shuoming")
    -- shuoming:setVisible(false)

    -- local shuomingContent = ccui.Helper:seekWidgetByName(node,"shuomingContent")

    -- local posX,posY = shuoming:getPosition()

    -- local ttfConfig = {}
    -- ttfConfig.fontFilePath="ui/zhunyuan.ttf"
    -- ttfConfig.fontSize=28
    -- ttfConfig.glyphs=cc.GLYPHCOLLECTION_CUSTOM

    -- local str = shuomingContent:getString()
    -- log(str)
    -- ttfConfig.customGlyphs=str

    -- local labelshuoming = cc.Label:createWithTTF(ttfConfig,str, cc.TEXT_ALIGNMENT_LEFT, shuoming:getContentSize().width)
    -- labelshuoming:setAnchorPoint(cc.p(0.5,0.5))
    -- labelshuoming:setColor(cc.c3b(107,29,29))

    -- if labelshuoming.setLineHeight then
    --     labelshuoming:setLineHeight(45)
    --     shuoming:getParent():addChild(labelshuoming)
    --     labelshuoming:setPosition(posX,posY)
    -- else
    --     shuoming:setVisible(true)
    -- end

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_top"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))

    self:enableNodeEvents()
end

function ClubCardNoticeLayer:onSelEvent(name)
    print("onSelEvent", name)
end

function ClubCardNoticeLayer:fangkaChange()
    local shuoming_node = self:getChildByTag(6666)
    if shuoming_node then
        shuoming_node:removeFromParent(true)
    end
    local profile = ProfileManager.GetProfile()
    if not profile then return end
    local csb         = ClubHallUI.getInstance().csb_club_charge
    local fangka_node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(fangka_node, 200)

    fangka_node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(fangka_node)

    local btExit    = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "btExit"), "ccui.Button")
    local btadd     = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "btn-add"), "ccui.Button")
    local btminus   = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "btn-minus"), "ccui.Button")
    local btDuihuan = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "btDuihuan"), "ccui.Button")
    local tprice    = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "t-price"), "ccui.Text")
    -- local tshuoming = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node,"shuoming"),"ccui.Text")
    local tclickfk = tolua.cast(ccui.Helper:seekWidgetByName(fangka_node, "t-clickfk"), "ccui.TextField")

    -- tshuoming:setVisible(false)
    btExit:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )
    ------------ 打开界面获取兑换房卡的默认值
    local cardnum = 50
    -- math.floor(profile.card/50)*50
    -- if cardnum == 0 then
    --     cardnum = 50
    -- elseif cardnum > 10000 then
    --     cardnum = 10000
    -- end
    tclickfk:setString(cardnum)
    local fangkanumber = tonumber(tclickfk:getString())
    tprice:setString(string.format("%d 元", fangkanumber / 5))
    ----------------- 输入框房卡位置--------
    local function fkposition()

        if fangkanumber < 100 then
            tclickfk:setPositionX(118)
        elseif fangkanumber >= 100 and fangkanumber < 1000 then
            tclickfk:setPositionX(110)
        elseif fangkanumber >= 1000 and fangkanumber < 10000 then
            tclickfk:setPositionX(105)
        elseif fangkanumber >= 10000 then
            tclickfk:setPositionX(94)
        end
    end

    fkposition()

    btadd:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                fangkanumber = tonumber(tclickfk:getString())
                if fangkanumber == nil then
                    fangkanumber = 50
                    tclickfk:setString(fangkanumber)
                end
                if fangkanumber < 10000 then
                    tclickfk:setString(fangkanumber + 50)
                    fangkanumber = tonumber(tclickfk:getString())
                    if fangkanumber >= 10000 then
                        fangkanumber = 10000
                        tclickfk:setString(fangkanumber)
                    end
                    tprice:setString(string.format("%d 元", fangkanumber / 5))
                end

                fkposition()
            end
        end
    )

    btminus:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                fangkanumber = tonumber(tclickfk:getString())
                if fangkanumber == nil then
                    fangkanumber = 50
                    tclickfk:setString(fangkanumber)
                end
                if fangkanumber > 50 then
                    tclickfk:setString(fangkanumber - 50)
                    fangkanumber = tonumber(tclickfk:getString())
                    if fangkanumber < 50 then
                        fangkanumber = 50
                        tclickfk:setString(fangkanumber)
                    end
                    tprice:setString(string.format("%d 元", fangkanumber / 5))
                end
                fkposition()
            end
        end
    )

    ---- 输入框输入数值判定
    ---- 当输入数字之外的值时 tonumber转换的值为nil，因此兑换数变为最低值50
    tclickfk:addEventListener(
        function(sender, eventType)
            if eventType == ccui.TextFiledEventType.detach_with_ime then
                fangkanumber = tonumber(tclickfk:getString())
                if fangkanumber == nil then
                    fangkanumber = 50
                else
                    if fangkanumber < 50 then
                        fangkanumber = 50
                    elseif fangkanumber >= 50 and fangkanumber <= 10000 then
                        fangkanumber = math.floor(fangkanumber / 50) * 50
                    elseif fangkanumber > 10000 then
                        fangkanumber = 10000
                    end
                end
                tclickfk:setString(fangkanumber)
                tprice:setString(string.format("%d 元", fangkanumber / 5))

                fkposition()
            elseif eventType == ccui.TextFiledEventType.insert_text then
                fangkanumber = tonumber(tclickfk:getString())
                if fangkanumber == nil then
                    fangkanumber = 50
                else
                    if fangkanumber >= 10000 then
                        fangkanumber = 10000
                    elseif fangkanumber <= 0 then
                        fangkanumber = 50
                    end
                end
                tclickfk:setString(fangkanumber)
                tprice:setString(string.format("%d 元", fangkanumber / 5))
            elseif eventType == ccui.TextFiledEventType.delete_backward then
                fangkanumber = tonumber(tclickfk:getString())
                if fangkanumber == nil then
                    fangkanumber = 0
                else
                    if fangkanumber < 0 then
                        fangkanumber = 50
                    end
                end
                tclickfk:setString(fangkanumber)
                tprice:setString(string.format("%d 元", fangkanumber / 5))
            end
        end
    )

    btDuihuan:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local cardnumber = tonumber(fangkanumber)
                local id         = profile.uid
                local url        = string.format("%s?uid=%d&card=%d", gt.getConf("wx_charge_url"), id, cardnumber)
                gt.openUrl(url)
                self:removeFromParent(true)
            end
        end
    )
end

return ClubCardNoticeLayer