local cmd_list = {
    NetCmd.S2C_GET_USER_JU_RECORDS,
}

local ju_list =
{
    [1]  = 8, -- zzmj
    [3]  = 8, -- csmj
    [4]  = 8, -- phz
    [5]  = 10, -- pdk
    [6]  = 10, -- ddz
    [7]  = 8, -- hzmj
    [8]  = 10, -- whz
    [9]  = 8, -- tdh
    [10] = 8, -- jz
    [11] = 8, -- jzgsj
    [12] = 8, -- hbmj
    [13] = 8, -- hbtdh
    [14] = 8, -- bddbz
    [15] = 8, -- zgz
    [16] = 8, -- fnmj
    [17] = 4, -- jdpdk
}

local gm_name_list =
{
    [1]  = "推倒胡麻将",
    [3]  = "扣点麻将",
    [4]  = "立四麻将",
    [5]  = "跑得快",
    [6]  = "斗地主",
    [7]  = "西安麻将",
    [9]  = "拐三角",
    [10] = "晋中",
    [11] = "晋中拐三角",
    [12] = "河北麻将",
    [13] = "河北推倒胡",
    [14] = "保定打八张",
    [15] = "扎股子",
    [16] = "丰宁麻将",
    [17] = "经典跑得快",
}

local ZjLayer = class("ZjLayer", function()
    return cc.Layer:create()
end)

function ZjLayer:create()
    local layer = ZjLayer.new()
    return layer
end

function ZjLayer:ctor()
    self:enableNodeEvents()
end

function ZjLayer:onEnter()
    self:createLayerMenu()
    self:registerEventListener()
end

function ZjLayer:onExit()
    self:unregisterEventListener()
end

function ZjLayer:registerEventListener()
    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg then return end

        -- rtn_msg = json.decode(rtn_msg)
        local data = nil
        local function jsonDecode()
            data = json.decode(rtn_msg)
        end
        if not pcall(jsonDecode) then
            print('ClubInviteLayer decode faild')
            gt.uploadErr(tostring(rtn_msg))
            return
        end
        rtn_msg = data

        commonlib.echo(rtn_msg)
        self.reqCount = self.reqCount - 1
        print("rcv self.reqCount", self.reqCount)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            local game_list = {[1] = self.zzmj_record, [3] = self.csmj_record,
                [4] = self.phz_record, [5] = self.pdk_record, [6] = self.ddz_record, [7] = self.hzmj_record, [8] = self.whz_record, [9] = self.tdh_record}
            local typ_list = {[1] = "zzrecord", [3] = "mjrecord", [4] = "phzrecord",
                [5] = "pdkrecord", [6] = "ddzrecord", [7] = "hzrecord", [8] = "whzrecord", [9] = "tdhrecord"}

            for __, data in ipairs(rtn_msg.datas) do
                -- 当前游戏类型的列表
                local game = nil
                -- 当前战绩第一局在game中的索引
                local gi = nil
                -- 游戏类型
                local gtyp = nil
                for k, gm in pairs(game_list) do
                    local exsit = nil
                    for i, gr in ipairs(gm) do
                        if gr.log_ju_id == data.log_ju_id then
                            game  = gm
                            gi    = i
                            gtyp  = k
                            exsit = true
                            break
                        end
                    end
                    if exsit then
                        break
                    end
                end

                if game and gi and gtyp then
                    for __, nr in ipairs(data.list) do
                        if not game[nr.cur_ju + gi - 1] or game[nr.cur_ju + gi - 1].cur_ju ~= nr.cur_ju or
                            game[nr.cur_ju + gi - 1].log_ju_id ~= data.log_ju_id then
                            local item = {log_ju_id = data.log_ju_id, log_data_id = nr.log_data_id, room_id = nr.room_id,
                                cur_ju = nr.cur_ju, time = nr.create_time}
                            for si, sum in ipairs(nr.summary) do
                                item["name"..si]  = sum.name or "匿名"
                                item["score"..si] = sum.score or 0
                            end
                            table.insert(game, nr.cur_ju + gi - 1, item)
                        end
                        game[nr.cur_ju + gi - 1].time = nr.create_time
                    end
                    for j = gi, gi + 200 do
                        if not game[j] or game[j].log_ju_id ~= data.log_ju_id then
                            break
                        end
                        game[j].refresh = true
                    end
                    cc.UserDefault:getInstance():setStringForKey(typ_list[gtyp], json.encode(game))
                    cc.UserDefault:getInstance():flush()
                elseif self.miss_ju_list and #self.miss_ju_list > 0 then
                    local isMiss = nil
                    for i, v in ipairs(self.miss_ju_list) do
                        if v == data.log_ju_id then
                            isMiss = true
                            break
                        end
                    end
                    if isMiss then
                        local gtyp = 1
                        local game = game_list[gtyp]
                        local gi   = #game + 1
                        for __, nr in ipairs(data.list) do
                            if not game[nr.cur_ju + gi - 1] or game[nr.cur_ju + gi - 1].cur_ju ~= nr.cur_ju or
                                game[nr.cur_ju + gi - 1].log_ju_id ~= data.log_ju_id then
                                local item = {log_ju_id = data.log_ju_id, log_data_id = nr.log_data_id, room_id = nr.room_id,
                                    cur_ju = nr.cur_ju, time = nr.create_time}
                                for si, sum in ipairs(nr.summary) do
                                    item["name"..si]  = sum.name or "匿名"
                                    item["score"..si] = sum.score or 0
                                end
                                table.insert(game, nr.cur_ju + gi - 1, item)
                            end
                            game[nr.cur_ju + gi - 1].time = nr.create_time
                        end
                        for j = gi, gi + 200 do
                            if not game[j] or game[j].log_ju_id ~= data.log_ju_id then
                                break
                            end
                            game[j].refresh = true
                        end
                        cc.UserDefault:getInstance():setStringForKey(typ_list[gtyp], json.encode(game))
                        cc.UserDefault:getInstance():flush()
                    end
                end
                gt.rmMissJuId(data.log_ju_id)
            end
            if self.reqCount <= 0 then
                self:initMsgList(self.zzmj_record)
                return
            end
        else
            if rtn_msg.msg or rtn_msg.errno then
                commonlib.showLocalTip(rtn_msg.msg or rtn_msg.errno)
            end
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ZjLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ZjLayer:reqKefuInfo(log_ids)
    -- print('``````````````````')
    local input_msg = {
        cmd        = NetCmd.C2S_GET_USER_JU_RECORDS,
        log_ju_ids = log_ids,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function ZjLayer:createLayerMenu()
    local csb  = DTUI.getInstance().csb_DT_RecordLayer
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                if self.SubRecordPanel and self.SubRecordPanel:isVisible() then
                    print('关次战绩')
                    GameGlobal.ZjLayerMainMsg      = nil
                    GameGlobal.ZjLayerMain         = nil
                    GameGlobal.ZjLayerMainMsgCurJu = nil

                    if self.cur_room_type == 1 then
                        self:initMsgList(self.zzmj_record)
                    end
                else
                    print('关主战绩')
                    GameGlobal.ZjLayerMainMsg      = nil
                    GameGlobal.ZjLayerMain         = nil
                    GameGlobal.ZjLayerMainMsgCurJu = nil

                    self:unregisterEventListener()
                    self.SubRecordPanel = nil
                    self.SubRecordCell  = nil
                    self.cur_room_type  = nil
                    self.MainRecordPanel:setVisible(false)
                    commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Img-kuang"), function()
                        self:removeFromParent(true)
                    end)
                    -- self.main_listView:setVisible(false)
                end
            end
        end
    )

    local btnCk = ccui.Helper:seekWidgetByName(node, "btn-ck")
    btnCk:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:inputRecord()
            end
        end
    )
    btnCk:setVisible(not ios_checking)

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))

    self.wu_tip = ccui.Helper:seekWidgetByName(node, "wu")
    self.wu_tip:setVisible(false)

    -- 主战绩列表
    self.MainRecordPanel = ccui.Helper:seekWidgetByName(node, "MainRecordPanel")
    self.SubRecordPanel  = ccui.Helper:seekWidgetByName(node, "SubRecordPanel")
    self.MainRecordPanel:setVisible(false)
    self.SubRecordPanel:setVisible(false)

    self.MainRecordView = ccui.Helper:seekWidgetByName(node, "MainRecordView")
    self.MainRecordCell = ccui.Helper:seekWidgetByName(node, "MainRecordCell")

    self.SubRecordView = ccui.Helper:seekWidgetByName(node, "SubRecordView")
    self.SubRecordCell = ccui.Helper:seekWidgetByName(node, "SubRecordCell")

    ---- 战绩
    self.cur_room_type = 1
    if not self.zzmj_record then
        local mjrecord = cc.UserDefault:getInstance():getStringForKey("zzrecord")
        if mjrecord and mjrecord ~= "" then
            self.zzmj_record = json.decode(mjrecord)
        else
            self.zzmj_record = {}
        end
    end
    self:initMsgList(self.zzmj_record)

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Img-kuang"), function()
        -- self.MainRecordPanel:setVisible(false)
        -- self.SubRecordPanel:setVisible(false)
    end)
end

function ZjLayer:initMsgList(all_xj_list)
    log("创建战绩\n")
    self.SubRecordPanel:setVisible(false)
    local dj_list = {}
    if all_xj_list and #all_xj_list > 0 then
        local no = nil
        for __, vv in ipairs(all_xj_list) do
            if vv.log_ju_id then
                if vv.log_ju_id ~= no then
                    dj_list[#dj_list + 1] = {}
                    no                    = vv.log_ju_id
                end
            else
                if vv.room_id ~= no then
                    dj_list[#dj_list + 1] = {}
                    no                    = vv.room_id
                end
            end
            local xj_list         = dj_list[#dj_list]
            xj_list[#xj_list + 1] = vv
        end
    end

    local miss_list = {}

    for i, v in ipairs(dj_list) do
        local last_record = v[#v]
        if not last_record.refresh and last_record.log_ju_id then
            miss_list[#miss_list + 1] = last_record.log_ju_id
        end
        if last_record.log_ju_id then
            gt.rmMissJuId(last_record.log_ju_id)
        end
    end
    self.miss_ju_list = gt.getMissJuIds()
    for i, v in ipairs(self.miss_ju_list) do
        miss_list[#miss_list + 1] = v
    end

    if #dj_list > 0 then
        table.sort(dj_list, function(a, b)
            return a[1].time > b[1].time
        end)
        self.MainRecordPanel:setVisible(true)
        local list       = dj_list
        local PlayerList = self.MainRecordView
        local LayerCont  = PlayerList:getChildByName('LayerCont')
        local baseItem   = self.MainRecordCell
        baseItem:setVisible(false)
        local CScrollViewLoad = require('club.CScrollViewLoad')
        local minCell         = math.max(3, #list)
        CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
        local function setItem(i, v)
            local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'MainRecordCell' .. i, self.mainRecordCellPos[i])
            tolua.cast(ccui.Helper:seekWidgetByName(item, "tRoomID"), "ccui.Text"):setString(v[1].room_id)
            tolua.cast(ccui.Helper:seekWidgetByName(item, "tTime"), "ccui.Text"):setString(os.date("%Y-%m-%d\n%H:%M:%S", v[#v].time))
            local score = {}
            for ii, vv in ipairs(v) do
                for k = 1, 7 do
                    local hasName = false
                    for kk =1, 7 do
                        if vv["userId".. kk] and vv["userId".. kk] == v[1]["userId".. k] and vv["score"..kk] then
                            hasName = true
                            if not score[k] then
                                score[k] = 0
                            end
                            score[k] = score[k] + vv["score"..kk]
                            break
                        end
                    end

                    if not hasName then
                        if vv["score"..k] then
                            score[k] = (score[k] or 0) + vv["score"..k]
                        end
                    end
                end
            end

            local ziSize = 14
            if v[1]["name5"] then
                self:nameSize(item, 2)
                ziSize = 6
            else
                self:nameSize(item, 1)
            end
            local str  = ""
            local str4 = ""
            for k = 1, 6 do
                if v[1]["name"..k] then
                    if pcall(commonlib.GetMaxLenString, v[1]["name"..k], ziSize) then
                        str = commonlib.GetMaxLenString(v[1]["name"..k], ziSize)
                        tolua.cast(item:getChildByName("Text_"..k), "ccui.Text"):setString(str)
                    else
                        str = v[1]["name"..k]
                        tolua.cast(item:getChildByName("Text_"..k), "ccui.Text"):setString(v[1]["name"..k])
                    end
                    if score[k] and score[k] > 0 and k < 6 then
                        tolua.cast(item:getChildByName("score_"..k), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
                    end
                    tolua.cast(item:getChildByName("score_"..k), "ccui.Text"):setString(score[k])
                    if v[1]["owner_name"] then
                        if pcall(commonlib.GetMaxLenString, v[1]["owner_name"], ziSize) then
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v[1]["owner_name"], ziSize) .. "\n的亲友圈")
                        else
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v[1]["owner_name"] .. "\n的亲友圈")
                        end
                    elseif v[1]["roomOwner_name"] then
                        if pcall(commonlib.GetMaxLenString, v[1]["roomOwner_name"], ziSize) then
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v[1]["roomOwner_name"], ziSize))
                        else
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v[1]["roomOwner_name"])
                        end
                    else
                        if pcall(commonlib.GetMaxLenString, v[1]["name1"], ziSize) then
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v[1]["name1"], ziSize))
                        else
                            tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v[1]["name1"])
                        end
                    end
                else
                    tolua.cast(item:getChildByName("Text_"..k), "ccui.Text"):setVisible(false)
                end
                if not score[k] and k < 7 then
                    tolua.cast(item:getChildByName("score_"..k), "ccui.Text"):setVisible(false)
                end
            end
            item:getChildByName("btMore"):addTouchEventListener(
                function(sender, eventType)
                    print('touch btmore')
                    if eventType == ccui.TouchEventType.ended then
                        self.MainRecordPanel:setVisible(false)
                        self:initSubMsgList(v)

                        GameGlobal.ZjLayerMainMsg = clone(v)
                        GameGlobal.ZjLayerMain    = nil
                    end
                end
            )
        end

        self.mainRecordMaxNum = CScrollViewLoad.resetList(self.mainRecordMaxNum, list, LayerCont, 'MainRecordCell')
        local function setCellPos()
            self.mainRecordCellPos = CScrollViewLoad.setCellItemPos(self.mainRecordMaxNum,
                self.mainRecordCellPos,
                baseItem:getContentSize().width / 2,
                LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
                baseItem:getContentSize().width,
                -baseItem:getContentSize().height)
        end
        setCellPos()

        local function setMemberItem()
            if self.mainRecordMaxNum < #list then
                self.mainRecordMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.mainRecordCellPos, LayerCont, 'MainRecordCell', setItem, baseItem, PlayerList)
        end
        setMemberItem()

        local children = LayerCont:getChildren()
        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setMemberItem()
            end
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)
        self.wu_tip:setVisible(false)
    else
        self.MainRecordPanel:setVisible(false)
        self.wu_tip:setVisible(true)
    end
    if #miss_list > 0 then
        commonlib.echo(miss_list)
        for i, v in ipairs(miss_list) do
            self:reqKefuInfo({miss_list[i]})
            print("reqKefuInfo", miss_list[i])
        end
        self.reqCount = #miss_list
        print("send reqCount", self.reqCount)
    end

    if GameGlobal.ZjLayerMainMsg then
        self.MainRecordPanel:setVisible(false)
        self:initSubMsgList(GameGlobal.ZjLayerMainMsg)
    end
    GameGlobal.ZjLayerMain = nil
end

function ZjLayer:initSubMsgList(msg_list)
    if msg_list and #msg_list > 0 then
        self.SubRecordPanel:setVisible(true)
        local list       = msg_list
        local PlayerList = self.SubRecordView
        local LayerCont  = PlayerList:getChildByName('LayerCont')
        local baseItem   = self.SubRecordCell
        baseItem:setVisible(false)
        local CScrollViewLoad = require('club.CScrollViewLoad')
        local minCell         = math.max(3, #list)
        CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
        local function setItem(i, v)
            local item     = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'SubRecordCell' .. i, self.subRecordCellPos[i])
            local namelist = {v.name1, v.name2, v.name3, v.name4, v.name5}
            if GameGlobal.ZjLayerMainMsgCurJu and GameGlobal.ZjLayerMainMsgCurJu == v.cur_ju then
                item:loadTexture("ui/qj_zhanji/kk-fs8.png")
                local child = {"tTime", "tRoomID", "tOwnerName", "Text_1", "Text_2",
                    "Text_3", "Text_4", "Text_5", "Text_6", "score_1", "score_2",
                    "score_3", "score_4", "score_5", "score_6"}
                for i, v in ipairs(child) do
                    item:getChildByName(v):setColor(cc.c3b(62, 81, 134))
                end
            end
            local ziSize = 14
            if v.name5 and v.score5 then
                self:nameSize(item, 2)
                ziSize = 6
            else
                self:nameSize(item, 1)
            end
            if pcall(commonlib.GetMaxLenString, v.name1, ziSize) then
                v.name1 = commonlib.GetMaxLenString(v.name1, ziSize)
                tolua.cast(item:getChildByName("Text_1"), "ccui.Text"):setString(v.name1)
            else
                v.name1 = v.name1
                tolua.cast(item:getChildByName("Text_1"), "ccui.Text"):setString(v.name1)
            end
            if pcall(commonlib.GetMaxLenString, v.name2, ziSize) then
                v.name2 = commonlib.GetMaxLenString(v.name2, ziSize)
                tolua.cast(item:getChildByName("Text_2"), "ccui.Text"):setString(v.name2)
            else
                v.name2 = v.name2
                tolua.cast(item:getChildByName("Text_2"), "ccui.Text"):setString(v.name2)
            end

            local str = (v.name1 or "匿名") .. "\n" .. (v.name2 or "匿名")
            -- local str4 = (v.score1 or 0).."\n"..(v.score2 or 0)
            local str1 = os.date("%Y-%m-%d\n%H:%M:%S", v.time)
            local str2 = v.room_id.."\n" .. "第"..v.cur_ju.."局 "
            if v.name3 and v.score3 then
                if pcall(commonlib.GetMaxLenString, v.name3, ziSize) then
                    v.name3 = commonlib.GetMaxLenString(v.name3, ziSize)
                    tolua.cast(item:getChildByName("Text_3"), "ccui.Text"):setString(v.name3)
                else
                    v.name3 = v.name3
                    tolua.cast(item:getChildByName("Text_3"), "ccui.Text"):setString(v.name3)
                end
                if v.name3 == "" then
                    v.name3 = "匿名"
                end
                if v.score3 == "" then
                    v.score3 = 0
                end
                str = str.."\n"..v.name3
                -- str4 = str4.."\n"..v.score3
                tolua.cast(item:getChildByName("score_3"), "ccui.Text"):setString(v.score3)
            else
                tolua.cast(item:getChildByName("score_3"), "ccui.Text"):setVisible(false)
                tolua.cast(item:getChildByName("Text_3"), "ccui.Text"):setVisible(false)
            end
            if v.name4 and v.score4 then
                if pcall(commonlib.GetMaxLenString, v.name4, ziSize) then
                    v.name4 = commonlib.GetMaxLenString(v.name4, ziSize)
                    tolua.cast(item:getChildByName("Text_4"), "ccui.Text"):setString(v.name4)
                else
                    v.name4 = v.name4
                    tolua.cast(item:getChildByName("Text_4"), "ccui.Text"):setString(v.name4)
                end
                if v.name4 == "" then
                    v.name4 = "匿名"
                end
                if v.score4 == "" then
                    v.score4 = 0
                end
                str = str.."\n"..v.name4
                -- str4 = str4.."\n"..v.score4
                tolua.cast(item:getChildByName("score_4"), "ccui.Text"):setString(v.score4)
            else
                tolua.cast(item:getChildByName("score_4"), "ccui.Text"):setVisible(false)
                tolua.cast(item:getChildByName("Text_4"), "ccui.Text"):setVisible(false)
            end
            if v.name5 and v.score5 then
                if pcall(commonlib.GetMaxLenString, v.name5, ziSize) then
                    v.name5 = commonlib.GetMaxLenString(v.name5, ziSize)
                    tolua.cast(item:getChildByName("Text_5"), "ccui.Text"):setString(v.name5)
                else
                    v.name5 = v.name5
                    tolua.cast(item:getChildByName("Text_5"), "ccui.Text"):setString(v.name5)
                end
                if v.name5 == "" then
                    v.name5 = "匿名"
                end
                if v.score5 == "" then
                    v.score5 = 0
                end
                str = str.."\n"..v.name5
                -- str4 = str4.."\n"..v.score4
                tolua.cast(item:getChildByName("score_5"), "ccui.Text"):setString(v.score5)
            else
                tolua.cast(item:getChildByName("score_5"), "ccui.Text"):setVisible(false)
                tolua.cast(item:getChildByName("Text_5"), "ccui.Text"):setVisible(false)
            end
            if v.name6 and v.score6 then
                if pcall(commonlib.GetMaxLenString, v.name6, ziSize) then
                    v.name6 = commonlib.GetMaxLenString(v.name6, ziSize)
                    tolua.cast(item:getChildByName("Text_6"), "ccui.Text"):setString(v.name6)
                else
                    v.name6 = v.name6
                    tolua.cast(item:getChildByName("Text_6"), "ccui.Text"):setString(v.name6)
                end
                if v.name6 == "" then
                    v.name6 = "匿名"
                end
                if v.score6 == "" then
                    v.score6 = 0
                end
                str = str.."\n"..v.name6
                tolua.cast(item:getChildByName("score_6"), "ccui.Text"):setString(v.score6)
            else
                tolua.cast(item:getChildByName("score_6"), "ccui.Text"):setVisible(false)
                tolua.cast(item:getChildByName("Text_6"), "ccui.Text"):setVisible(false)
            end
            if v.name7 and v.score7 then
                if v.name7 == "" then
                    v.name7 = "匿名"
                end
                if v.score7 == "" then
                    v.score7 = 0
                end
                str = str.."\n"..v.name7
            end
            tolua.cast(item:getChildByName("score_1"), "ccui.Text"):setString(v.score1 or 0)
            tolua.cast(item:getChildByName("score_2"), "ccui.Text"):setString(v.score2 or 0)
            if v.score1 and v.score1 > 0 then
                tolua.cast(item:getChildByName("score_1"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            if v.score2 and v.score2 > 0 then
                tolua.cast(item:getChildByName("score_2"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            if v.score3 and v.score3 > 0 then
                tolua.cast(item:getChildByName("score_3"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            if v.score4 and v.score4 > 0 then
                tolua.cast(item:getChildByName("score_4"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            if v.score5 and v.score5 > 0 then
                tolua.cast(item:getChildByName("score_5"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            if v.score6 and v.score6 > 0 then
                tolua.cast(item:getChildByName("score_6"), "ccui.Text"):setColor(cc.c3b(255, 97, 60))
            end
            -- tolua.cast(item:getChildByName("score"), "ccui.Text"):setString(str4)
            tolua.cast(item:getChildByName("tTime"), "ccui.Text"):setString(str1)
            tolua.cast(item:getChildByName("tRoomID"), "ccui.Text"):setString(str2)
            -- if pcall(commonlib.GetMaxLenString, str3, 14) then
            --     tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(str3, 14))
            -- else
            --     tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(str3)
            -- end
            if v.owner_name then
                if pcall(commonlib.GetMaxLenString, v.owner_name, ziSize) then
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.owner_name, ziSize) .. "\n的亲友圈")
                else
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v.owner_name.."\n的亲友圈")
                end
            elseif v.roomOwner_name then
                if pcall(commonlib.GetMaxLenString, v.roomOwner_name, ziSize) then
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.roomOwner_name, ziSize))
                else
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v.roomOwner_name)
                end
            else
                if pcall(commonlib.GetMaxLenString, v.name1, ziSize) then
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name1, ziSize))
                else
                    tolua.cast(item:getChildByName("tOwnerName"), "ccui.Text"):setString(v.name1)
                end
            end
            item:getChildByName("Button_4"):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    commonlib.echo(v)

                    local net_msg = {
                        cmd = NetCmd.C2S_LOGDATA,
                        id  = v.log_data_id,
                    }
                    ymkj.SendData:send(json.encode(net_msg))
                    if v.cur_ju then
                        GameGlobal.ZjLayerMainMsgCurJu = v.cur_ju
                    end
                    gt.playback_log_ju_id = v.log_ju_id
                end
            end)
            item:getChildByName("btshare"):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    self:shareZhanji(v)
                end
            end)
            if ios_checking then
                item:getChildByName("btshare"):setVisible(false)
            end
        end

        self.subRecordMaxNum = CScrollViewLoad.resetList(self.subRecordMaxNum, list, LayerCont, 'SubRecordCell')
        local function setCellPos()
            self.subRecordCellPos = CScrollViewLoad.setCellItemPos(self.subRecordMaxNum,
                self.subRecordCellPos,
                baseItem:getContentSize().width / 2,
                LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
                baseItem:getContentSize().width,
                -baseItem:getContentSize().height)
        end
        setCellPos()
        local function setMemberItem()
            if self.subRecordMaxNum < #list then
                self.subRecordMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.subRecordCellPos, LayerCont, 'SubRecordCell', setItem, baseItem, PlayerList)
        end
        setMemberItem()
        local children = LayerCont:getChildren()
        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setMemberItem()
            end
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)
        self.wu_tip:setVisible(false)
        if GameGlobal.ZjLayerMainMsgCurJu then
            local index = GameGlobal.ZjLayerMainMsgCurJu - 1
            -- self.SubRecordView:refreshView()
            local percent = self:CalculationInnerPosY(self.SubRecordView, self.SubRecordCell:getContentSize().height, index)
            -- self.SubRecordView:scrollToPercentVertical(percent,1,true)
            self.SubRecordView:jumpToPercentVertical(percent)
            setMemberItem()
        else
            -- self.SubRecordView:refreshView()
            -- self.SubRecordView:scrollToPercentVertical(0,1,true)
            self.SubRecordView:jumpToPercentVertical(0)
            setMemberItem()
        end
    else
        self.SubRecordPanel:setVisible(false)
        self.wu_tip:setVisible(true)
    end
end

function ZjLayer:shareZhanji(v)
    local csb  = DTUI.getInstance().csb_recordshare
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node     = node
    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    local WXBtn   = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn_wx"), "ccui.Button")
    local PYQBtn  = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn_pyq"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)

            end
        end
    )
    if not v.yx_type then
        v.yx_type = self.cur_room_type
    end
    WXBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                gt.wechatShareChatStart()
                ymkj.wxReq(2, "玩家"..ProfileManager.GetProfile().name.."分享了一个回放码:"..v.log_data_id.."(请在战绩-查看他人回放中输入回放码)", gm_name_list[v.yx_type]..g_game_name.."牌局回放码", g_share_url)
                gt.wechatShareChatEnd()
                log(tostring(ProfileManager.GetProfile().name) .. "分享了一个回放码:"..tostring(v.log_data_id) .. "(请在战绩-查看他人回放中输入回放码)", tostring(gm_name_list[v.yx_type])..tostring(g_game_name) .. "牌局回放码", tostring(g_share_url))
            end
        end
    )
    PYQBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                ymkj.wxReq(2, "玩家"..ProfileManager.GetProfile().name.."分享了一个回放码:"..v.log_data_id.."(请在战绩-查看他人回放中输入回放码)", gm_name_list[v.yx_type]..g_game_name.."牌局回放码", g_share_url, 2)
                log(tostring(ProfileManager.GetProfile().name) .. "分享了一个回放码:"..tostring(v.log_data_id) .. "(请在战绩-查看他人回放中输入回放码)", tostring(gm_name_list[v.yx_type])..tostring(g_game_name) .. "牌局回放码", tostring(g_share_url))
            end
        end
    )
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))

end

function ZjLayer:inputRecord()

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

                GameGlobal.ZjLayerMain = nil
            end
        end
    )

    local number     = 0
    local number_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "tRoomID"), "ccui.Text")
    number_lbl:setString("请输入回放码")
    local inputNum = 0

    for i = 0, 9 do
        ccui.Helper:seekWidgetByName(node, string.format("%d", i)):addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    number = number * 10 + i
                    number_lbl:setString(number)
                    inputNum = inputNum + 1
                    if number >= 10000000000 then
                        number   = 0
                        inputNum = 0
                        commonlib.showLocalTip("输入不能超过10位数")
                        number_lbl:setString("请输入回放码")
                    end
                end
            end)
    end

    ccui.Helper:seekWidgetByName(node, "btReinput"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            number   = 0
            inputNum = 0
            number_lbl:setString("请输入回放码")
        end
    end)

    ccui.Helper:seekWidgetByName(node, "btOk"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            -- number = number_lbl:getString()
            if number == 0 then
                return
            end

            local net_msg = {
                cmd = NetCmd.C2S_LOGDATA,
                id  = number,
            }
            ymkj.SendData:send(json.encode(net_msg))

            GameGlobal.ZjLayerMain         = true
            GameGlobal.ZjLayerMainMsg      = nil
            GameGlobal.ZjLayerMainMsgCurJu = nil
        end
    end)
    ccui.Helper:seekWidgetByName(node, "btDel"):setVisible(false)
end

function ZjLayer:CalculationInnerPosY(listView, itemHeight, index)
    local minY    = listView:getContentSize().height - listView:getInnerContainerSize().height
    local PosY    = itemHeight * index - minY
    local percent = ((PosY + minY) * 100) /- minY
    if minY == 0 then
        percent = 0
    end
    if percent < 0 then
        return 0
    elseif percent > 100 then
        return 100
    elseif percent >= 0 and percent <= 100 then
        return percent
    else
        return 0
    end
end

-- typ = 1 时为1-4人时的战绩位置
-- typ = 2 时为5人时的战绩位置
function ZjLayer:nameSize(list, typ)
    if typ == 1 then
        for i = 1, 6 do
            local positionx1 = 731.96
            local positionx2 = 934.71
            tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setAnchorPoint(cc.p(0.5, 1))
            tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setPositionX(positionx1)
            tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setFontSize(30)
            tolua.cast(list:getChildByName("score_"..i), "ccui.Text"):setPositionX(positionx2)
            tolua.cast(list:getChildByName("score_"..i), "ccui.Text"):setFontSize(30)
        end
    else
        for i = 1, 6 do
            tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setFontSize(25)
            tolua.cast(list:getChildByName("score_"..i), "ccui.Text"):setFontSize(25)
            tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setAnchorPoint(cc.p(0, 1))
            if i < 5 then
                local positionx1 = 610.53
                local positionx2 = 903.00
                tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(list:getChildByName("score_"..i), "ccui.Text"):setPositionX(positionx2)
            else
                local positionx1 = 744.03
                local positionx2 = 968.10
                tolua.cast(list:getChildByName("Text_"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(list:getChildByName("score_"..i), "ccui.Text"):setPositionX(positionx2)
            end
        end
    end
end

return ZjLayer