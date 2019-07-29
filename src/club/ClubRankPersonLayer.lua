require('club.ClubHallUI')

local cmd_list = {
    -- NetCmd.S2C_LOGDATA,
}

local ClubRankPersonLayer = class("ClubRankPersonLayer", function()
    return cc.Layer:create()
end)

function ClubRankPersonLayer:create(args)
    local layer = ClubRankPersonLayer.new(args)
    -- layer:createLayerMenu(args.list)
    return layer
end

function ClubRankPersonLayer:ctor(args)
    self.data = args.data
    self:createLayerMenu(args.list)
end

function ClubRankPersonLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        -- if rtn_msg.cmd == NetCmd.S2C_LOGDATA then
        --     dump(rtn_msg,"NetCmd.S2C_LOGDATA",10)
        -- end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ClubRankPersonLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubRankPersonLayer:exitLayer()
    -- self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubRankPersonLayer:convertRankPerson(list)
    local rtn_msg = list
    if rtn_msg and 0 == #rtn_msg then
        return rtn_msg
    end
    if rtn_msg[1].room_id then
        return rtn_msg
    end

    for i, v in ipairs(rtn_msg) do
        rtn_msg[i].id               = v[1]
        rtn_msg[i].uid              = v[2]
        rtn_msg[i].room_id          = v[3]
        rtn_msg[i].qipai_type       = v[4]
        rtn_msg[i].total_ju         = v[5]
        rtn_msg[i].create_uid       = v[6]
        rtn_msg[i].create_time      = v[7]
        rtn_msg[i].qunzhu           = v[8]
        rtn_msg[i].club_index       = v[9]
        rtn_msg[i].score            = v[10]
        rtn_msg[i].big_winner_count = v[11]
        rtn_msg[i].is_big_winner    = v[12]
    end

    return rtn_msg
end

function ClubRankPersonLayer:createLayerMenu(list)
    -- print('战绩时间 ```````````````````````````````````')
    -- dump(list)
    -- print('战绩时间 END````````````````````````````````')
    list = self:convertRankPerson(list)
    -- print('QQQQQQQQQQQQQQQ')
    -- dump(list,"ClubRankPersonLayer list")

    local csb  = ClubHallUI.getInstance().csb_club_rank_person
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

    self.RankPersonPanel = ccui.Helper:seekWidgetByName(node, "RankPersonPanel")

    local strWays = {
        ['mj_tdh']   = '推倒胡',
        ['mj_kd']    = '扣点',
        ['mj_xian']  = '西安麻将',
        ['mj_lisi']  = '立四',
        ['pk_ddz']   = '斗地主',
        ['pk_pdk']   = '跑得快',
        ['pk_zgz']   = '扎股子',
        ['mj_gsj']   = '拐三角',
        ['mj_jzgsj'] = '晋中拐三角',
        ['mj_jz']    = '晋中麻将',
        ['mj_hbtdh'] = '河北推倒胡',
        ['mj_hebei'] = '河北麻将',
        ['mj_dbz']   = '保定打八张',
        ['mj_fn']    = '丰宁麻将',
        ['pk_jdpdk'] = '经典跑得快',
    }

    local function sortRankPersonLayer(a, b)
        if a.create_time > b.create_time then
            return true
        end
        return false
    end
    table.sort(list, sortRankPersonLayer)

    local itemWidht  = 989.80
    local itemHeight = 90.00

    local PlayerList = self.RankPersonPanel:getChildByName("ListView")
    local LayerCont  = PlayerList:getChildByName('LayerCont')

    local baseItem = ccui.Helper:seekWidgetByName(self.RankPersonPanel, "item")
    baseItem:setVisible(false)

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(6, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)

    local function setItem(i, v)
        local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'RankPersonItem' .. i, self.rankPersonCellPos[i])
        item:setVisible(true)
        item:getChildByName("tDate"):setString(os.date("%Y-%m-%d\n %H:%M:%S", v.create_time))
        item:getChildByName("tRoomNO"):setString(v.room_id or "")
        -- 桌子号
        local desk = nil
        for j, k in ipairs(self.data.club_rooms) do
            local room = self.data.club_rooms[j]
            if room and room.room_id == v.room_id then
                desk = j
            end
        end
        local roomStr = tostring(v.room_id)
        local desk    = (v.club_index or desk)
        -- desk = v.club_index
        if v.room_id and desk then
            item:getChildByName("tRoomNO"):setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
            item:getChildByName("tRoomNO"):setString(desk .. '号桌' .. '\n' .. v.room_id)
        end

        if pcall(commonlib.GetMaxLenString, self.data.club_info.club_name, 12) then
            item:getChildByName("tRoomBoss"):setString(commonlib.GetMaxLenString(self.data.club_info.club_name, 12))
        else
            item:getChildByName("tRoomBoss"):setString(self.data.club_info.club_name)
        end
        item:getChildByName("tWays"):setString(v.qipai_type and strWays[v.qipai_type] or "")
        if v.total_ju >= 100 then
            item:getChildByName("tJuShu"):setString(v.total_ju and v.total_ju - 100 or "")
        else
            item:getChildByName("tJuShu"):setString(v.total_ju or "")
        end
        item:getChildByName("tScores"):setString(v.score or "")
        item:getChildByName("tGodNum"):setString((v.big_winner_count or "0") .. '人')
        item:getChildByName("tGodNum"):setVisible(v.is_big_winner and v.is_big_winner == 1)
        item:getChildByName("ImgGod"):setVisible(v.is_big_winner and v.is_big_winner == 1)
    end

    self.rankPersonMaxNum = CScrollViewLoad.resetList(self.rankPersonMaxNum, list, LayerCont, 'RankPersonItem')

    -- print(self.rankPersonMaxNum)

    local function setCellPos()
        self.rankPersonCellPos = CScrollViewLoad.setCellItemPos(self.rankPersonMaxNum,
            self.rankPersonCellPos,
            0,
            LayerCont:getContentSize().height - itemHeight,
            itemWidht,
            -itemHeight)
    end
    setCellPos()
    local function setRankItemScoreview()
        if self.rankPersonMaxNum < #list then
            self.rankPersonMaxNum = #list
            setCellPos()
        end
        CScrollViewLoad.setListItem(list, self.rankPersonCellPos, LayerCont, 'RankPersonItem', setItem, baseItem, PlayerList, itemHeight)
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

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

return ClubRankPersonLayer