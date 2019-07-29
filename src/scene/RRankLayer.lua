local RRankLayer = class("RRankLayer", function()
    return cc.Layer:create()
end)

function RRankLayer.create()
    local layer = RRankLayer.new()
    return layer
end

function RRankLayer:ctor()
    self:createLayerMenu()
end

function RRankLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        rtn_msg       = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            if rtn_msg.shuoming and not ios_checking and not g_author_game then
                self.shuoming = rtn_msg.shuoming
                self:refreshLayer()
            end

            if self.ani_finish then
                self:initRankList(rtn_msg.data)
            else
                self.data = rtn_msg.data
            end
        else
            commonlib.showLocalTip(rtn_msg.msg)
        end
    end

    local listenerRsp = cc.EventListenerCustom:create(S2C_RANK, rspCallback)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
end

function RRankLayer:refreshLayer()
    if self.cur then
        if type(self.shuoming) == "string" then
            local tip = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "Text_2"), "ccui.Text")
            if string.len(self.shuoming) < 24 then
                tip:setString(rankTextConfig)
            else
                local tab = string.split(self.shuoming, "|||||")
                if tab[1] then
                    rankTextConfig = tab[1]
                end
                if tab[self.cur] then
                    tip:setString(tab[self.cur])
                else
                    tip:setString(rankTextConfig)
                end
            end
        end
    end
end

function RRankLayer:unregisterEventListener()
    cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(S2C_RANK)
end

function RRankLayer:reqRankData()
    local net_msg = {
        {cmd = NetCmd.C2S_RANK},
    }
    ymkj.SendData:send(json.encode2(net_msg))
end

function RRankLayer:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/paihang.csb"), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Widget")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:unregisterEventListener()

                if self.listView then
                    self.listView:setVisible(false)
                    self.listView  = nil
                    self.mode_item = nil
                    self.node      = nil

                    commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "BG"):getVirtualRenderer(), nil, 0)

                    commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Image_1"))

                    commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "btn-exit"))

                    commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "paihangkuang"))

                    commonlib.moveTo(ccui.Helper:seekWidgetByName(node, "shuominkuang"), true, function()
                        self:removeFromParent(true)
                    end, true)
                end
            end
        end
    )

    if g_author_game then
        rankTextConfig = "一.积   分\n" ..
        "所有玩过的局数输赢积分加减计算\n" ..
        "二.输赢次数\n" ..
        "（例:积分达到最高分.赢场不是最高,我们将和第二三四名核算.积分和赢场最高为准.）"
    end

    local tip = tolua.cast(ccui.Helper:seekWidgetByName(node, "Text_2"), "ccui.Text")
    tip:setString(rankTextConfig)

    local taskBtn = ccui.Helper:seekWidgetByName(node, "gaikuang")
    local infoBtn = ccui.Helper:seekWidgetByName(node, "jiangli")
    local ruleBtn = ccui.Helper:seekWidgetByName(node, "guize")
    local hight   = ccui.Helper:seekWidgetByName(node, "tupian")

    taskBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            taskBtn:setColor(cc.c3b(77, 49, 0))
            infoBtn:setColor(cc.c3b(255, 255, 245))
            ruleBtn:setColor(cc.c3b(255, 255, 245))

            taskBtn:setTouchEnabled(false)
            infoBtn:setTouchEnabled(true)
            ruleBtn:setTouchEnabled(true)

            hight:runAction(cc.MoveTo:create(0.1, cc.p(44, 20)))

            self.cur = 1
            self:refreshLayer()
        end
    end)

    taskBtn:setColor(cc.c3b(77, 49, 0))
    infoBtn:setColor(cc.c3b(255, 255, 245))
    ruleBtn:setColor(cc.c3b(255, 255, 245))

    taskBtn:setTouchEnabled(false)
    infoBtn:setTouchEnabled(true)
    ruleBtn:setTouchEnabled(true)

    self.cur = 1

    infoBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            infoBtn:setColor(cc.c3b(77, 49, 0))
            taskBtn:setColor(cc.c3b(255, 255, 245))
            ruleBtn:setColor(cc.c3b(255, 255, 245))

            taskBtn:setTouchEnabled(true)
            infoBtn:setTouchEnabled(false)
            ruleBtn:setTouchEnabled(true)

            hight:runAction(cc.MoveTo:create(0.1, cc.p(125, 20)))

            self.cur = 2
            self:refreshLayer()
        end
    end)

    ruleBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            ruleBtn:setColor(cc.c3b(77, 49, 0))
            infoBtn:setColor(cc.c3b(255, 255, 245))
            taskBtn:setColor(cc.c3b(255, 255, 245))

            taskBtn:setTouchEnabled(true)
            infoBtn:setTouchEnabled(true)
            ruleBtn:setTouchEnabled(false)

            hight:runAction(cc.MoveTo:create(0.1, cc.p(207, 20)))

            self.cur = 3
            self:refreshLayer()
        end
    end)

    self.node     = node
    self.listView = tolua.cast(ccui.Helper:seekWidgetByName(node, "ListView_1"), "ccui.ListView")

    ccui.Helper:seekWidgetByName(node, "BG"):setVisible(false)
    ccui.Helper:seekWidgetByName(node, "Image_1"):setVisible(false)
    ccui.Helper:seekWidgetByName(node, "btn-exit"):setVisible(false)

    local scrollView1 = ccui.Helper:seekWidgetByName(node, "ScrollView_1")
    self.listView:setClippingEnabled(false)
    scrollView1:setClippingEnabled(false)

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "paihangkuang"), function()
        self.listView:setClippingEnabled(true)

        ccui.Helper:seekWidgetByName(node, "BG"):setVisible(true)
        ccui.Helper:seekWidgetByName(node, "Image_1"):setVisible(true)
        ccui.Helper:seekWidgetByName(node, "btn-exit"):setVisible(true)

        commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "BG"), function()
            if self.data then self:initRankList(self.data) end
            self.ani_finish = true
        end)

        commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Image_1"))

        commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "btn-exit"))

    end)

    commonlib.moveTo(ccui.Helper:seekWidgetByName(node, "shuominkuang"), true, function()
        scrollView1:setClippingEnabled(true)
    end)

    -- self.listView:setContentSize(cc.size(self.listView:getContentSize().width+6, self.listView:getContentSize().height))
    self.mode_item = tolua.cast(ccui.Helper:seekWidgetByName(node, "NOlist"), "ccui.Widget")
    self.mode_item:setContentSize(cc.size(self.listView:getContentSize().width, self.mode_item:getContentSize().height))
    -- self.listView:setPositionX(self.listView:getPositionX()-4)
    ccui.Helper:doLayout(self.mode_item)

    self.mode_item:setVisible(false)

    self:registerEventListener()

    for i = 1, 3 do
        local item = ccui.Helper:seekWidgetByName(self.node, "NO"..i)
        item:setVisible(false)
    end
    self.mode_item:setVisible(false)

    self:reqRankData()
end

function RRankLayer:initRankList(rank_list, is_first)

    if not is_first then

        if not rank_list or #rank_list == 0 then
            for i = 1, 3 do
                local item = ccui.Helper:seekWidgetByName(self.node, "NO"..i)
                item:setVisible(false)
            end
            self.mode_item:setVisible(false)
            return
        end
        for i = 1, 3 do
            local item = ccui.Helper:seekWidgetByName(self.node, "NO"..i)
            local v    = rank_list[i]
            if v then
                item:setVisible(true)
                tolua.cast(ccui.Helper:seekWidgetByName(item, "name"), "ccui.Text"):setString(v.name)
                local str = ""
                if v.score then
                    str = str .. "分:"..v.score
                end
                if v.win_ju and v.win_ju ~= 0 then
                    str = str .. " 赢:"..v.win_ju.."局"
                end
                tolua.cast(ccui.Helper:seekWidgetByName(item, "fenshu"), "ccui.Text"):setString(str)
                tolua.cast(ccui.Helper:seekWidgetByName(item, "ID"), "ccui.Text"):setString(v.uid)
                tolua.cast(ccui.Helper:seekWidgetByName(item, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(v.head), g_wxhead_addr)
            end
        end

        if #rank_list < 4 then
            return
        end

        self.mode_item:setVisible(true)
        for i = 4, #rank_list do
            local item = self.mode_item:clone()
            local v    = rank_list[i]
            self.listView:pushBackCustomItem(item)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "name"), "ccui.Text"):setString(v.name)
            local str = ""
            if v.score then
                str = str .. "分:"..v.score
            end
            if v.win_ju and v.win_ju ~= 0 then
                str = str .. " 赢:"..v.win_ju.."局"
            end
            tolua.cast(ccui.Helper:seekWidgetByName(item, "fenshu"), "ccui.Text"):setString(str)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "ID"), "ccui.Text"):setString(v.uid)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(v.head), g_wxhead_addr)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "AtlasLabel_1"), "ccui.TextAtlas"):setString(i)
            if i == 7 then
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function()
                    self:initRankList(rank_list, true)
                end)))
                break
            end

        end
        self.mode_item:setVisible(false)

    else

        if #rank_list < 8 then
            return
        end

        self.mode_item:setVisible(true)
        for i = 8, #rank_list do
            local item = self.mode_item:clone()
            local v    = rank_list[i]
            self.listView:pushBackCustomItem(item)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "name"), "ccui.Text"):setString(v.name)
            local str = ""
            if v.score then
                str = str .. "分:"..v.score
            end
            if v.win_ju and v.win_ju ~= 0 then
                str = str .. " 赢:"..v.win_ju.."局"
            end
            tolua.cast(ccui.Helper:seekWidgetByName(item, "fenshu"), "ccui.Text"):setString(str)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "ID"), "ccui.Text"):setString(v.uid)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(v.head), g_wxhead_addr)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "AtlasLabel_1"), "ccui.TextAtlas"):setString(i)
        end
        self.mode_item:setVisible(false)

    end
end

return RRankLayer