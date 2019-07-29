require('club.ClubHallUI')

local cmd_list = {
    NetCmd.S2C_CLUB_VIP_LIST,
    NetCmd.S2C_GET_USER_JU_RECORDS,
    NetCmd.S2C_CLUB_LOG,
}

local ClubLogLayer = class("ClubLogLayer", function()
    return cc.Layer:create()
end)

function ClubLogLayer:create(args)
    local layer = ClubLogLayer.new(args)
    -- layer:createLayerMenu()
    return layer
end

function ClubLogLayer:ctor(args)
    self.data = args.data
    self:setName('ClubLogLayer')
    self.club_id = args.data.club_info.club_id
    self:createLayerMenu()
    self:registerEventListener()
    self:onHistory()

    self:enableNodeEvents()
end

function ClubLogLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        local data = nil
        local function jsonDecode()
            data = json.decode(rtn_msg)
        end
        if not pcall(jsonDecode) then
            print('ClubLogLayer decode faild')
            gt.uploadErr(tostring(rtn_msg))
            return
        end
        rtn_msg = data
        commonlib.echo(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_CLUB_VIP_LIST then
            -- dump(rtn_msg,"NetCmd.S2C_CLUB_VIP_LIST",10)
            self.history_list = rtn_msg.list
            self:refreshHistory()
        elseif rtn_msg.cmd == NetCmd.S2C_GET_USER_JU_RECORDS then
            -- dump(rtn_msg,"NetCmd.S2C_GET_USER_JU_RECORDS",10)
            local ClubZhanJiLayer = require("club.ClubZhanJiLayer")
            self:addChild(ClubZhanJiLayer:create({
                list = rtn_msg.datas[1].list,
                data = self.data,
            }))
        elseif rtn_msg.cmd == NetCmd.S2C_CLUB_LOG then
            -- dump(rtn_msg,"NetCmd.S2C_CLUB_LOG",10)
            self.log_list = rtn_msg.list
            self:refreshLog()
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end

    -- local function onNodeEvent(event)
    --     if event == "exitTransitionStart" then
    --         self:unregisterEventListener()
    --     end
    -- end
    -- self:registerScriptHandler(onNodeEvent)
end

function ClubLogLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubLogLayer:exitLayer()
    -- self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubLogLayer:onExitTransitionStart()
    -- print('退出前 ClubLogLayer:exitTransitionStart')
    self:unregisterEventListener()
    self:unregisterEvent()
end

function ClubLogLayer:onEnterTransitionFinish()
    -- print('进入后 ClubLogLayer:enterTransitionFinish')
    self:registerEvent()
end

function ClubLogLayer:onReconnect()
    log('重连')
    if self.HistoryPanel:isVisible() then
        log('重新请求成员列表')
        self:onHistory()
    elseif self.LogPanel:isVisible() then
        log('重新请求请求列表')
        self:onLog()
    end
end

function ClubLogLayer:registerEvent()
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

function ClubLogLayer:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function ClubLogLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_log
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:exitLayer()
            GameGlobal.C2S_GET_USER_JU_RECORDS_log_ju_ids = nil
        end
    end)

    self.HistoryPanel = ccui.Helper:seekWidgetByName(node, "HistoryPanel")
    ccui.Helper:seekWidgetByName(self.HistoryPanel, "item"):setVisible(false)
    self.LogPanel = ccui.Helper:seekWidgetByName(node, "LogPanel")
    ccui.Helper:seekWidgetByName(self.LogPanel, "item"):setVisible(false)
    self.logBtn     = ccui.Helper:seekWidgetByName(node, "btn-log")
    self.historyBtn = ccui.Helper:seekWidgetByName(node, "btn-history")

    self.logBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.notMemory = true
            self:onLog()
        end
    end)

    self.historyBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.notMemory = true
            self:onHistory()
        end
    end)

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

function ClubLogLayer:onHistory()
    self.LogPanel:setVisible(false)
    self.HistoryPanel:setVisible(true)
    self.historyBtn:setTouchEnabled(false)
    self.logBtn:setTouchEnabled(true)
    self.logBtn:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.historyBtn:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.historyBtn:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.historyBtn:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.logBtn:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_1.png")
    self.logBtn:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    -- if not self.history_list then
    local uid       = gt.getData('uid') or ''
    self.max_his_id = cc.UserDefault:getInstance():getStringForKey("club_log_max_id_" .. uid.."_"..self.club_id, 0)
    local input_msg = {
        cmd     = NetCmd.C2S_CLUB_VIP_LIST,
        max_id  = self.max_his_id or 0,
        club_id = self.data.club_info.club_id,
    }
    ymkj.SendData:send(json.encode(input_msg))
    -- end
end

function ClubLogLayer:refreshHistory()

    local uid       = gt.getData('uid') or ''
    self.max_his_id = cc.UserDefault:getInstance():getStringForKey("club_log_max_id_" .. uid.."_"..self.club_id, 0)
    self.max_his_id = self.max_his_id or 0

    local uid                = gt.getData('uid') or ''
    local local_history_list = cc.UserDefault:getInstance():getStringForKey("club_log_history" .. uid.."_"..self.club_id, '')
    if local_history_list and local_history_list ~= "" then
        local_history_list = json.decode(local_history_list)
    else
        local_history_list = {}
    end
    local function server_history_list_sort(a, b)
        if a.id < b.id then
            return true
        end
        return false
    end
    table.sort(self.history_list, server_history_list_sort)
    local max_his_id = nil
    for i, v in ipairs(self.history_list) do
        local history = self.history_list[i]
        if history.status == 1 then
            max_his_id = v.id
            break
        end
    end

    -- 清除status为1的数据
    for i = #self.history_list, 1, -1 do
        local history = self.history_list[i]
        if history.status == 1 then
            table.remove(self.history_list, i)
        end
    end
    local client_list = {}
    for i = 1, #local_history_list do
        client_list[local_history_list[i].id] = local_history_list[i]
    end
    for i = #self.history_list, 1, -1 do
        client_list[self.history_list[i].id] = self.history_list[i]
    end

    local_history_list = {}
    for i, v in pairs(client_list) do
        table.insert(local_history_list, client_list[i])
    end
    local function local_history_list_sort(a, b)
        if a.create_time > b.create_time then
            return true
        end
        return false
    end
    table.sort(local_history_list, local_history_list_sort)

    for i = #local_history_list, 50 + 1, -1 do
        table.remove(local_history_list, i)
    end
    cc.UserDefault:getInstance():setStringForKey("club_log_history" .. uid.."_"..self.club_id, json.encode(local_history_list))
    cc.UserDefault:getInstance():flush()

    self.history_list = local_history_list

    if not max_his_id then
        for i, v in ipairs(self.history_list) do
            self.max_his_id = math.max(self.max_his_id, v.id)
        end
    else
        self.max_his_id = max_his_id - 1
    end

    local uid = gt.getData('uid') or ''
    if uid ~= '' then
        cc.UserDefault:getInstance():setStringForKey("club_log_max_id_" .. uid.."_"..self.club_id, self.max_his_id)
        cc.UserDefault:getInstance():flush()
    end

    -- print('``````````````````````````````````````')
    -- dump(self.history_list)
    -- print('``````````````````````````````````````')

    local PlayerList = self.HistoryPanel:getChildByName("ScrollView")
    local LayerCont  = PlayerList:getChildByName('LayerCont')
    local baseItem   = LayerCont:getChildByName("item")

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(5, #self.history_list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)

    -- print('历史列表 START')
    -- dump(self.history_list)
    -- print('历史列表 END')
    if self.history_list and #self.history_list > 0 then
        local function setItem(i, v)
            local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'HistoryItem' .. i, self.historyCellPos[i])
            item:setVisible(true)
            item:getChildByName("tDate"):setString(os.date("%Y-%m-%d\n %H:%M:%S", v.create_time))
            local str = ''
            if v.total_ju >= 100 then
                str = v.total_ju - 100 .. '圈'
            else
                str = v.total_ju .. '局'
            end

            local paizhuohao = nil
            -- -- for j,k in ipairs(self.data.club_rooms) do
            -- for j = 1, table.maxn(self.data.club_rooms) do
            --     local room = self.data.club_rooms[j]
            --     if room and room.room_id == v.room_id then
            --         paizhuohao = j
            --     end
            -- end
            local roomStr   = tostring(v.room_id)
            local ZhuoziStr = (v.club_index or tostring(paizhuohao)) .. "号牌桌"
            local JuStr     = str
            local Ka        = string.format("-%s房卡", tostring(v.cost_card))

            item:getChildByName("tRoomNO"):setString(roomStr)
            item:getChildByName("tRoomZhuozi"):setString(ZhuoziStr)
            item:getChildByName("tRoomJu"):setString(JuStr)
            item:getChildByName("tRoomka"):setString(Ka)

            local nameStr1  = ""
            local nameStr2  = ""
            local nameStr3  = ""
            local nameStr4  = ""
            local nameStr5  = ""
            local nameStr6  = ""
            local scoreStr1 = ""
            local scoreStr2 = ""
            local scoreStr3 = ""
            local scoreStr4 = ""
            local scoreStr5 = ""
            local scoreStr6 = ""
            local players   = v.content and '' ~= v.content and json.decode(v.content) or {}

            local ziSize = 14
            if #players < 5 then
                self:nameSize(item, 1)
            else
                self:nameSize(item, 2)
                ziSize = 6
            end
            for j, player in ipairs(players) do
                if pcall(commonlib.GetMaxLenString, player.name, ziSize) then
                    player.name = commonlib.GetMaxLenString(player.name, ziSize) .. "\n"
                else
                    player.name = player.name
                end
                if j == 1 then
                    nameStr1  = player.name
                    scoreStr1 = player.score
                elseif j == 2 then
                    nameStr2  = player.name
                    scoreStr2 = player.score
                elseif j == 3 then
                    nameStr3  = player.name
                    scoreStr3 = player.score
                elseif j == 4 then
                    nameStr4  = player.name
                    scoreStr4 = player.score
                elseif j == 5 then
                    nameStr5  = player.name
                    scoreStr5 = player.score
                elseif j == 6 then
                    nameStr6  = player.name
                    scoreStr6 = player.score
                end
            end

            item:getChildByName("tPlayers1"):setString(nameStr1)
            item:getChildByName("tPlayers2"):setString(nameStr2)
            item:getChildByName("tPlayers3"):setString(nameStr3)
            item:getChildByName("tPlayers4"):setString(nameStr4)
            item:getChildByName("tPlayers5"):setString(nameStr5)
            item:getChildByName("tPlayers6"):setString(nameStr6)
            item:getChildByName("tScores1"):setString(scoreStr1)
            item:getChildByName("tScores2"):setString(scoreStr2)
            item:getChildByName("tScores3"):setString(scoreStr3)
            item:getChildByName("tScores4"):setString(scoreStr4)
            item:getChildByName("tScores5"):setString(scoreStr5)
            item:getChildByName("tScores6"):setString(scoreStr6)
            if tonumber(scoreStr1) and tonumber(scoreStr1) > 0 then
                item:getChildByName("tScores1"):setColor(cc.c3b(255, 97, 60))
            end
            if tonumber(scoreStr2) and tonumber(scoreStr2) > 0 then
                item:getChildByName("tScores2"):setColor(cc.c3b(255, 97, 60))
            end
            if tonumber(scoreStr3) and tonumber(scoreStr3) > 0 then
                item:getChildByName("tScores3"):setColor(cc.c3b(255, 97, 60))
            end
            if tonumber(scoreStr4) and tonumber(scoreStr4) > 0 then
                item:getChildByName("tScores4"):setColor(cc.c3b(255, 97, 60))
            end
            if tonumber(scoreStr5) and tonumber(scoreStr5) > 0 then
                item:getChildByName("tScores5"):setColor(cc.c3b(255, 97, 60))
            end
            if tonumber(scoreStr6) and tonumber(scoreStr6) > 0 then
                item:getChildByName("tScores6"):setColor(cc.c3b(255, 97, 60))
            end
            item:getChildByName('is4To32'):setVisible(v.is4To32 and v.is4To32 == 1)

            item:getChildByName("btXQ"):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    print("详情")
                    local input_msg = {
                        cmd        = NetCmd.C2S_GET_USER_JU_RECORDS,
                        log_ju_ids = {v.id},
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                    dump(input_msg)
                    GameGlobal.C2S_GET_USER_JU_RECORDS_log_ju_ids = v.id
                    self:resetItemType(LayerCont:getChildren())
                    self:setItemType(item, true)
                end
            end)
        end

        -- for i,v in ipairs(self.history_list) do
        --     setItem(i,v)
        -- end

        local list         = self.history_list
        self.historyMaxNum = CScrollViewLoad.resetList(self.historyMaxNum, list, LayerCont, 'HistoryItem')

        local function setCellPos()
            self.historyCellPos = CScrollViewLoad.setCellItemPos(self.historyMaxNum,
                self.historyCellPos,
                baseItem:getContentSize().width / 2,
                LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
                baseItem:getContentSize().width,
                -baseItem:getContentSize().height)
        end
        setCellPos()
        local function setSqItem()
            if self.historyMaxNum < #list then
                self.historyMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.historyCellPos, LayerCont, 'HistoryItem', setItem, baseItem, PlayerList)
        end
        setSqItem()

        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setSqItem()
                local children = LayerCont:getChildren()
                -- print('$ --------------- ' .. tostring(#children))
            end
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)

        local children = LayerCont:getChildren()
        -- print('$ --------------- ' .. tostring(#children))
    else
        commonlib.showLocalTip("还没有新的战绩哦~~~")
    end
    if not self.notMemory then
        self:memoryLog()
    end
end

function ClubLogLayer:memoryLog()
    if GameGlobal.C2S_GET_USER_JU_RECORDS_log_ju_ids then
        local input_msg = {
            cmd        = NetCmd.C2S_GET_USER_JU_RECORDS,
            log_ju_ids = {GameGlobal.C2S_GET_USER_JU_RECORDS_log_ju_ids},
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
end

function ClubLogLayer:onLog()
    self.LogPanel:setVisible(true)
    self.HistoryPanel:setVisible(false)
    self.historyBtn:setTouchEnabled(true)
    self.logBtn:setTouchEnabled(false)
    self.logBtn:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.historyBtn:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.historyBtn:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.historyBtn:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.logBtn:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    self.logBtn:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_1.png")

    -- print('新日记ID', self.max_log_id)
    local uid       = gt.getData('uid') or ''
    self.max_log_id = cc.UserDefault:getInstance():getStringForKey("club_log_max_log_id_" .. uid.."_"..self.club_id, 0)
    local input_msg = {
        cmd     = NetCmd.C2S_CLUB_LOG,
        max_id  = tonumber(self.max_log_id) or 0,
        club_id = self.data.club_info.club_id,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function ClubLogLayer:refreshLog()
    self.max_log_id = self.max_log_id or 0
    -- print('````````````````````````')
    -- dump(self.log_list)
    -- print('````````````````````````')

    local uid            = gt.getData('uid') or ''
    local local_log_list = cc.UserDefault:getInstance():getStringForKey("club_log_log_" .. uid.."_"..self.club_id, '')
    if local_log_list and local_log_list ~= "" then
        local_log_list = json.decode(local_log_list)
    else
        local_log_list = {}
    end
    local client_list = {}
    for i = 1, #local_log_list do
        client_list[local_log_list[i].id] = local_log_list[i]
    end
    for i = #self.log_list, 1, -1 do
        client_list[self.log_list[i].id] = self.log_list[i]
    end

    local_log_list = {}
    for i, v in pairs(client_list) do
        table.insert(local_log_list, client_list[i])
    end

    local function local_log_list_sort(a, b)
        if a.create_time > b.create_time then
            return true
        end
        return false
    end
    table.sort(local_log_list, local_log_list_sort)

    for i = #local_log_list, 50 + 1, -1 do
        table.remove(local_log_list, i)
    end
    cc.UserDefault:getInstance():setStringForKey("club_log_log_" .. uid.."_"..self.club_id, json.encode(local_log_list))
    cc.UserDefault:getInstance():flush()

    self.log_list = local_log_list

    for i, v in ipairs(self.log_list) do
        self.max_log_id = math.max(self.max_log_id, v.id)
        local uid       = gt.getData('uid') or ''
        if uid ~= '' then
            cc.UserDefault:getInstance():setStringForKey("club_log_max_log_id_" .. uid.."_"..self.club_id, self.max_log_id)
            cc.UserDefault:getInstance():flush()
        end
    end

    -- print('````````````````````````')
    -- dump(self.log_list)
    -- print('````````````````````````')

    local PlayerList = self.LogPanel:getChildByName("ListView")
    local LayerCont  = PlayerList:getChildByName('LayerCont')
    local baseItem   = LayerCont:getChildByName("item")
    -- baseItem:setVisible(true)

    -- print(baseItem:getPositionX(),baseItem:getPositionY())

    local itemWidth  = 990
    local itemHeight = 40

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(14, #self.log_list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, itemHeight * minCell)
    if self.log_list and #self.log_list > 0 then
        local function setItem(i, v)
            local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'LogItem' .. i, self.logCellPos[i])
            item:setContentSize(cc.size(990, 40))
            item:setVisible(true)
            -- print(item:getPositionX(),item:getPositionY())
            local oprStr = ""
            if v.type == 1 then
                oprStr = string.format("玩家 %s[%s] 加入了亲友圈", v.name, tostring(v.uid))
            elseif v.type == 2 then
                oprStr = string.format("玩家 %s[%s] 被踢出了亲友圈", v.name, tostring(v.uid))
            elseif v.type == 3 then
                oprStr = string.format("%s创建了亲友圈", v.name, tostring(v.uid))
            elseif v.type == 4 then
                oprStr = string.format("玩家 %s[%s] 退出了亲友圈", v.name, tostring(v.uid))
            elseif v.type == 5 then
                oprStr = string.format("玩家 %s[%s] 修改了亲友圈的默认玩法", v.name, tostring(v.uid))
            elseif v.type == 6 then
                oprStr = string.format("玩家 [%s] 修改了亲友圈第[%s]桌的默认玩法", tostring(v.uid), v.name)
            elseif v.type == 7 then
                oprStr = string.format("玩家 [%s] 修改了亲友圈微信号为 [%s]", tostring(v.uid), v.name)
            end
            item:getChildByName("tLogOper"):setString(oprStr)
            -- print(v.type)
            -- item:getChildByName("tLogOper"):setString('222222222222222222222222222222222222222')
            item:getChildByName("tLogDate"):setString(os.date("%Y/%m/%d %H:%M:%S", v.create_time))
            -- item:getChildByName("tLogDate"):setString('111111111111111111111111111111111111111')
        end

        local list = self.log_list

        self.logMaxNum = CScrollViewLoad.resetList(self.logMaxNum, list, LayerCont, 'LogItem')

        local function setCellPos()
            self.logCellPos = CScrollViewLoad.setCellItemPos(self.logMaxNum,
                self.logCellPos,
                0,
                LayerCont:getContentSize().height - itemHeight,
                itemWidth,
                -itemHeight)
        end
        setCellPos()
        local function setLogItem()
            if self.logMaxNum < #list then
                self.logMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.logCellPos, LayerCont, 'LogItem', setItem, nil, PlayerList, itemHeight)
        end
        setLogItem()

        require 'scene.ScrollViewBar'
        local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setLogItem()
                local children = LayerCont:getChildren()
                -- print('$ --------------- ' .. tostring(#children))
            end
            scorllCallBack(sender, eventType)
        end
        PlayerList:addEventListener(ScrollViewCallBack)
        PlayerList:addTouchEventListener(touchCallBack)

        local children = LayerCont:getChildren()
        -- print('$ --------------- ' .. tostring(#children))
    else
        commonlib.showLocalTip("还没有新的日志哦~~~")
    end
end

function ClubLogLayer:resetItemType(items)
    if items and #items > 0 then
        for i, v in ipairs(items) do
            self:setItemType(v)
        end
    end
end

function ClubLogLayer:setItemType(item, isSelect)
    if isSelect then
        item:loadTexture("ui/qj_zhanji/kk-fs8.png")
        local child = {"tDate", "tRoomNO", "tRoomZhuozi", "tRoomJu", "tRoomka",
            "tPlayers1", "tPlayers2", "tPlayers3", "tPlayers4", "tPlayers5", "tPlayers6", "tScores1",
            "tScores2", "tScores3", "tScores4", "tScores5", "tScores6"}
        for i, v in ipairs(child) do
            item:getChildByName(v):setColor(cc.c3b(62, 81, 134))
        end
    else
        item:loadTexture("ui/qj_club/dt_clubOther_ways_itemBg.png")
        local child = {"tDate", "tRoomNO", "tRoomZhuozi", "tRoomJu", "tRoomka",
            "tPlayers1", "tPlayers2", "tPlayers3", "tPlayers4", "tPlayers5", "tPlayers6", "tScores1",
            "tScores2", "tScores3", "tScores4", "tScores5", "tScores6"}
        for i, v in ipairs(child) do
            item:getChildByName(v):setColor(cc.c3b(160, 89, 83))
        end
    end
end

function ClubLogLayer:nameSize(item, typ)
    if typ == 1 then
        for i = 1, 6 do
            local positionx1 = 643.50
            local positionx2 = 841.50
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setAnchorPoint(cc.p(0.5, 1))
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setFontSize(30)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setFontSize(30)
        end
    else
        for i = 1, 6 do
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setFontSize(28)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setFontSize(28)
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setAnchorPoint(cc.p(0, 1))
            if i < 5 then
                local positionx1 = 525.38
                local positionx2 = 821.50
                tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            else
                local positionx1 = 655.03
                local positionx2 = 878.40
                tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            end
        end
    end
end

return ClubLogLayer