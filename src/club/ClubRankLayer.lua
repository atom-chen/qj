require('club.ClubHallUI')

local cmd_list = {
    NetCmd.S2C_CLUB_RANK,
    NetCmd.S2C_CLUB_RANK_DETAIL,
}

local ClubRankLayer = class("ClubRankLayer", function()
    return cc.Layer:create()
end)

function ClubRankLayer:create(args)
    local layer = ClubRankLayer.new(args)
    -- layer:createLayerMenu()
    return layer
end

function ClubRankLayer:ctor(args)
    self.isBoss  = args.isBoss
    self.isAdmin = args.isAdmin
    self.club_id = args.club_id
    self.data    = args.data
    self:createLayerMenu()
    self:registerEventListener()

    self:onRankToday()

    self:enableNodeEvents()
end

function ClubRankLayer:convertRank(rtn_msg)
    if rtn_msg and 0 == #rtn_msg then
        return rtn_msg
    end
    if rtn_msg[1].uid then
        return rtn_msg
    end

    for i, v in ipairs(rtn_msg) do
        rtn_msg[i].uid               = v[1]
        rtn_msg[i].name              = v[2]
        rtn_msg[i].head              = v[3]
        rtn_msg[i].room_id           = v[4]
        rtn_msg[i].qipai_type        = v[5]
        rtn_msg[i].total_ju          = v[6]
        rtn_msg[i].total_ju2         = v[7]
        rtn_msg[i].create_uid        = v[8]
        rtn_msg[i].create_time       = v[9]
        rtn_msg[i].qunzhu            = v[10]
        rtn_msg[i].club_index        = v[11]
        rtn_msg[i].score             = v[12]
        rtn_msg[i].total_score       = v[13]
        rtn_msg[i].big_winner_count  = v[14]
        rtn_msg[i].is_big_winner     = v[15]
        rtn_msg[i].big_winner_count2 = v[16]
    end
    return rtn_msg
end

function ClubRankLayer:convertUserRank(rtn_msg)
    if rtn_msg and 0 == #rtn_msg then
        return rtn_msg
    end
    rtn_msg.uid               = rtn_msg[1]
    rtn_msg.name              = rtn_msg[2]
    rtn_msg.head              = rtn_msg[3]
    rtn_msg.room_id           = rtn_msg[4]
    rtn_msg.qipai_type        = rtn_msg[5]
    rtn_msg.total_ju          = rtn_msg[6]
    rtn_msg.total_ju2         = rtn_msg[7]
    rtn_msg.create_uid        = rtn_msg[8]
    rtn_msg.create_time       = rtn_msg[9]
    rtn_msg.qunzhu            = rtn_msg[10]
    rtn_msg.club_index        = rtn_msg[11]
    rtn_msg.score             = rtn_msg[12]
    rtn_msg.total_score       = rtn_msg[13]
    rtn_msg.big_winner_count  = rtn_msg[14]
    rtn_msg.is_big_winner     = rtn_msg[15]
    rtn_msg.big_winner_count2 = rtn_msg[16]
    return rtn_msg
end

function ClubRankLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_CLUB_RANK then
            if rtn_msg.type ~= 100 then
                rtn_msg.list = self:convertRank(rtn_msg.list)
            end
            if rtn_msg.userScore and #rtn_msg.userScore > 0 then
                rtn_msg.userScore = self:convertUserRank(rtn_msg.userScore)
            end
            if rtn_msg.type == 1 then
                self.today_list      = rtn_msg.list
                self.today_userScore = rtn_msg.userScore or {}
                self:refreshToday()
            elseif rtn_msg.type == 2 then
                self.yesterday_list      = rtn_msg.list
                self.yesterday_userScore = rtn_msg.userScore or {}
                self:refreshYesterday()
            elseif rtn_msg.type == 100 then
                local ClubRankUserLayer = require("club.ClubRankUserLayer")
                self:addChild(ClubRankUserLayer:create({
                    list = rtn_msg.list,
                    data = self.data,
                }))
            end
        elseif rtn_msg.cmd == NetCmd.S2C_CLUB_RANK_DETAIL then
            local ClubRankPersonLayer = require("club.ClubRankPersonLayer")
            self:addChild(ClubRankPersonLayer:create({
                list = rtn_msg.list,
                data = self.data,
            }))
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ClubRankLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubRankLayer:exitLayer()
    -- self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubRankLayer:onExitTransitionStart()
    -- print('退出前 ClubRankLayer:exitTransitionStart')
    self:unregisterEventListener()

    self:unregisterEvent()
end

function ClubRankLayer:onEnterTransitionFinish()
    -- print('进入后 ClubRankLayer:enterTransitionFinish')
    self:registerEvent()
end

function ClubRankLayer:onReconnect()
    log('重连')
    if self.RankYesterdayPanel:isVisible() then
        self:onRankYesterday()
    elseif self.RankTodayPanel:isVisible() then
        self:onRankToday()
    end
end

function ClubRankLayer:registerEvent()
    local events = {
        {
            eType = EventEnum.onReconnect,
            func  = handler(self, self.onReconnect),
        },
    }
    for i, v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function ClubRankLayer:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function ClubRankLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_rank
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:exitLayer()
        end
    end)

    -- 昨天排行榜
    self.RankYesterdayPanel = ccui.Helper:seekWidgetByName(node, "RankYesterdayPanel")
    -- 灰色
    ccui.Helper:seekWidgetByName(self.RankYesterdayPanel, "item"):setVisible(false)
    -- 蓝色
    ccui.Helper:seekWidgetByName(self.RankYesterdayPanel, "item1"):setVisible(false)
    -- 自己的
    self.RankYesterdayPanel:getChildByName("itemowner"):setVisible(false)
    -- 成局数
    self.RankYesterdayPanel:getChildByName("itemcount"):setVisible(false)

    -- 今天排行榜
    self.RankTodayPanel = ccui.Helper:seekWidgetByName(node, "RankTodayPanel")
    -- 灰色
    ccui.Helper:seekWidgetByName(self.RankTodayPanel, "item"):setVisible(false)
    -- 蓝色
    ccui.Helper:seekWidgetByName(self.RankTodayPanel, "item1"):setVisible(false)
    -- 自己的
    self.RankTodayPanel:getChildByName("itemowner"):setVisible(false)
    -- 成局数
    self.RankTodayPanel:getChildByName("itemcount"):setVisible(false)

    self.btYesterday = ccui.Helper:seekWidgetByName(node, "btYesterday")
    self.btToday     = ccui.Helper:seekWidgetByName(node, "btToday")

    local lnCurTime = os.time()
    self.btYesterday:getChildByName("tYDay"):setString(os.date("昨天%m-%d", lnCurTime - 86400))
    self.btToday:getChildByName("tTDay"):setString(os.date("今天%m-%d", lnCurTime))

    self.btYesterday:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:onRankYesterday()
        end
    end)

    self.btToday:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:onRankToday()
        end
    end)

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))

    self:enableNodeEvents()
end

function ClubRankLayer:onRankToday()
    self.RankYesterdayPanel:setVisible(false)
    self.RankTodayPanel:setVisible(true)
    self.btToday:setTouchEnabled(false)
    self.btYesterday:setTouchEnabled(true)
    self.btToday:getChildByName("tTDay"):setColor(cc.c3b(224, 229, 254))
    self.btYesterday:getChildByName("tYDay"):setColor(cc.c3b(124, 125, 159))
    self.btToday:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btToday:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btYesterday:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_1.png")
    self.btYesterday:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_2.png")

    if not self.today_list then
        local input_msg = {
            cmd     = NetCmd.C2S_CLUB_RANK,
            club_id = self.club_id,
            type    = 1,
            isGM    = self.isBoss or self.isAdmin
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
end

function ClubRankLayer:onRankYesterday()
    self.RankYesterdayPanel:setVisible(true)
    self.RankTodayPanel:setVisible(false)
    self.btToday:setTouchEnabled(true)
    self.btYesterday:setTouchEnabled(false)
    self.btToday:getChildByName("tTDay"):setColor(cc.c3b(124, 125, 159))
    self.btYesterday:getChildByName("tYDay"):setColor(cc.c3b(224, 229, 254))
    self.btToday:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btToday:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btYesterday:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    self.btYesterday:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_1.png")
    if not self.yesterday_list then
        local input_msg = {
            cmd     = NetCmd.C2S_CLUB_RANK,
            club_id = self.club_id,
            type    = 2,
            isGM    = self.isBoss or self.isAdmin,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
end

function ClubRankLayer:sortRank(list)
    local function listSort(a, b)
        if a.total_score > b.total_score then
            return true
        elseif a.total_score == b.total_score then
            if a.total_ju2 < b.total_ju2 then
                return true
            elseif a.total_ju2 == b.total_ju2 then
                if a.big_winner_count2 > b.big_winner_count2 then
                    return true
                elseif a.big_winner_count2 == b.big_winner_count2 then
                    if a.uid < b.uid then
                        return true
                    end
                end
            end
        end
        return false
    end
    commonlib.insertSort(list, listSort)
    return list
end

function ClubRankLayer:refreshRank(lnType, scoreViewPanel)
    local bSetOwnerData = false
    local owneruid      = gt.getData('uid')

    local list = self.list

    self:sortRank(list)

    local PlayerList = scoreViewPanel:getChildByName("RankList")
    local LayerCont  = PlayerList:getChildByName('LayerCont')

    local baseItem = ccui.Helper:seekWidgetByName(scoreViewPanel, "item")
    baseItem:setVisible(false)

    local CScrollViewLoad = require('club.CScrollViewLoad')
    if not CScrollViewLoad then
        gt.uploadErr('not CScrollViewLoad old res')
        return
    end
    local minCell = math.max(5, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)

    local function setRankItem(item, i, v)
        if i >= 1 and i <= 3 then
            item:getChildByName("ImgNO"):loadTexture("ui/qj_contest/qj_contest_rank_" .. i .. ".png")
            item:getChildByName("tNo"):setVisible(false)
        else
            item:getChildByName("ImgNO"):setVisible(false)
            item:getChildByName("tNo"):setString(tostring(i))
            item:getChildByName("tNo"):setVisible(true)
            item:getChildByName("tNo"):setFontSize(40)
        end

        local head_url = commonlib.wxHead(v.head)
        item:getChildByName("touxiang"):downloadImg(head_url)
        if pcall(commonlib.GetMaxLenString, v.name, 12) then
            item:getChildByName("name"):setString(commonlib.GetMaxLenString(v.name, 12) or "")
        else
            item:getChildByName("name"):setString(v.name or "")
        end
        item:getChildByName("id"):setString(v.uid or "")
        if (self.isBoss or self.isAdmin) or self.ownerItem == item then
            item:getChildByName("btXQ"):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    print("详情")
                    local input_msg = {
                        cmd     = NetCmd.C2S_CLUB_RANK_DETAIL,
                        club_id = self.club_id,
                        uid     = v.uid,
                        type    = lnType,
                        isGM    = self.isBoss or self.isAdmin
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                end
            end)
            item:getChildByName("btXQ"):setVisible(true)
        else
            item:getChildByName("btXQ"):setVisible(false)
        end
        item:getChildByName("score"):setString(v.total_score or "")
        item:getChildByName("count"):setString(v.total_ju2 or "")
        item:getChildByName("god"):setString(v.big_winner_count2 or "")
    end

    if self.list and #self.list > 0 then
        local function setItem(i, v)
            if i <= 3 or (self.isBoss or self.isAdmin) then
                local item = nil
                if i % 2 ~= 0 then
                    item = CScrollViewLoad.newCellorGetCellByName(LayerCont, self.baseGrayItem, 'RankItem' .. i, self.rankCellPos[i])
                else
                    item = CScrollViewLoad.newCellorGetCellByName(LayerCont, self.baseBlueItem, 'RankItem' .. i, self.rankCellPos[i])
                end
                item:setVisible(true)
                setRankItem(item, i, v)
            end
        end

        self.rankMaxNum = CScrollViewLoad.resetList(self.rankMaxNum, list, LayerCont, 'RankItem')

        -- print(self.rankMaxNum)

        local function setCellPos()
            self.rankCellPos = CScrollViewLoad.setCellItemPos(self.rankMaxNum,
                self.rankCellPos,
                baseItem:getContentSize().width / 2,
                LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
                baseItem:getContentSize().width,
                -baseItem:getContentSize().height)
        end
        setCellPos()
        local function setRankItemScoreview()
            if self.rankMaxNum < #list then
                self.rankMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.rankCellPos, LayerCont, 'RankItem', setItem, baseItem, PlayerList)
        end
        setRankItemScoreview()

        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setRankItemScoreview()
                local children = LayerCont:getChildren()
                -- print('$ --------------- ' .. tostring(#children))
            end
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)

        local children = LayerCont:getChildren()
        -- print('$ --------------- ' .. tostring(#children))

        -- 自己的战绩需要全局遍厉
        for i, v in ipairs(self.list) do
            if v.uid and owneruid == v.uid then
                setRankItem(self.ownerItem, i, v)
                self.ownerItem:getChildByName("ImgNO"):setVisible(false)
                self.ownerItem:getChildByName("tNo"):setVisible(false)
                self.ownerItem:getChildByName("btXQ"):setVisible(true)
                bSetOwnerData = true
            end
        end
    else
        commonlib.showLocalTip(self.noRankStr)
        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)
    end

    -------------------------------------------------
    -- 没有自己的战绩，重置数据
    self.ownerItem:setVisible(true)
    self.countItem:setVisible(false)
    if self.data.club_info.isAKZJ and not (self.isBoss or self.isAdmin) then
        if self.data.club_info.isAKZJ == 1 then
            self.ownerItem:setVisible(true)
        else
            self.ownerItem:setVisible(false)
        end
    end
    if (self.isBoss or self.isAdmin) then
        self.ownerItem:setVisible(false)
        self.countItem:setVisible(true)
        local countItem = self.countItem
        if lnType == 1 then
            if self.today_userScore and self.today_userScore.total_ju then
                if not self.today_userScore.cost_card then
                    self.today_userScore.cost_card = 0
                end
                if not self.today_userScore.cost_card_js then
                    self.today_userScore.cost_card_js = 0
                end
                countItem:seekNode("tTotalJu"):setString(string.format("成局数：%d局", self.today_userScore.total_ju))
                countItem:seekNode("tTotalJuCost"):setString(string.format("耗卡成局：%d局", self.today_userScore.total_ju_cost))
                countItem:seekNode("tCostCard"):setString(string.format("总耗卡：%d张", self.today_userScore.cost_card))
                countItem:seekNode("tCostCardJs"):setString(string.format("中途解散耗卡：%d张", self.today_userScore.cost_card_js))
            end
        elseif lnType == 2 then
            if self.yesterday_userScore and self.yesterday_userScore.total_ju then
                if not self.yesterday_userScore.cost_card then
                    self.yesterday_userScore.cost_card = 0
                end
                if not self.yesterday_userScore.cost_card_js then
                    self.yesterday_userScore.cost_card_js = 0
                end
                countItem:seekNode("tTotalJu"):setString(string.format("成局数：%d局", self.yesterday_userScore.total_ju))
                countItem:seekNode("tTotalJuCost"):setString(string.format("耗卡成局：%d局", self.yesterday_userScore.total_ju_cost))
                countItem:seekNode("tCostCard"):setString(string.format("总耗卡：%d张", self.yesterday_userScore.cost_card))
                countItem:seekNode("tCostCardJs"):setString(string.format("中途解散耗卡：%d张", self.yesterday_userScore.cost_card_js))
            end
        end
        countItem:getChildByName("more"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_RANK,
                    club_id = self.club_id,
                    type    = 100,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)
    end

    if not bSetOwnerData then
        local item = self.ownerItem
        item:getChildByName("ImgNO"):setVisible(false)
        item:getChildByName("tNo"):setVisible(false)
        local head_url = commonlib.wxHead(gt.getData('head'))
        item:getChildByName("touxiang"):downloadImg(head_url)
        if pcall(commonlib.GetMaxLenString, gt.getData('name'), 12) then
            item:getChildByName("name"):setString(commonlib.GetMaxLenString(gt.getData('name'), 12))
        else
            item:getChildByName("name"):setString(gt.getData('name'))
        end
        item:getChildByName("id"):setString(gt.getData('uid'))
        item:getChildByName("btXQ"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                print("详情")
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_RANK_DETAIL,
                    club_id = self.club_id,
                    uid     = owneruid,
                    type    = lnType,
                    isGM    = self.isBoss or self.isAdmin
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)
        if lnType == 1 then
            -- log(self.today_userScore.total_score)
            item:getChildByName("score"):setString(self.today_userScore.total_score or tostring(0))
            item:getChildByName("count"):setString(self.today_userScore.total_ju2 or tostring(0))
            item:getChildByName("god"):setString(self.today_userScore.big_winner_count2 or tostring(0))
        else
            item:getChildByName("score"):setString(self.yesterday_userScore.total_score or tostring(0))
            item:getChildByName("count"):setString(self.yesterday_userScore.total_ju2 or tostring(0))
            item:getChildByName("god"):setString(self.yesterday_userScore.big_winner_count2 or tostring(0))
        end
    end
    ------------------------------------------------
end

function ClubRankLayer:refreshToday()
    -- self.today_list = {1,2,3,3,1,2,2,3,1,2,3,888}
    self.list         = self.today_list
    self.baseGrayItem = ccui.Helper:seekWidgetByName(self.RankTodayPanel, "item")
    self.baseBlueItem = ccui.Helper:seekWidgetByName(self.RankTodayPanel, "item1")
    self.ownerItem    = self.RankTodayPanel:getChildByName("itemowner")
    self.countItem    = self.RankTodayPanel:getChildByName("itemcount")
    self.listView     = self.RankTodayPanel:getChildByName("RankList")
    self.noRankStr    = "还没有今天的排行榜哦~~~"

    self:refreshRank(1, self.RankTodayPanel)
end

function ClubRankLayer:refreshYesterday()
    self.list         = self.yesterday_list
    self.baseGrayItem = ccui.Helper:seekWidgetByName(self.RankYesterdayPanel, "item")
    self.baseBlueItem = ccui.Helper:seekWidgetByName(self.RankYesterdayPanel, "item1")
    self.ownerItem    = self.RankYesterdayPanel:getChildByName("itemowner")
    self.countItem    = self.RankYesterdayPanel:getChildByName("itemcount")
    self.listView     = self.RankYesterdayPanel:getChildByName("RankList")
    self.noRankStr    = "还没有昨天的排行榜哦~~~"

    self:refreshRank(2, self.RankYesterdayPanel)
end

function ClubRankLayer:refreshTodaycount()

end

return ClubRankLayer