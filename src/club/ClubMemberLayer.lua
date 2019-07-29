require('club.ClubHallUI')

local cmd_list = {
    NetCmd.S2C_CLUB_GET_APPLY_LIST,
    NetCmd.S2C_CLUB_DO_APPLY,
    NetCmd.S2C_CLUB_USER_LIST,
    NetCmd.S2C_CLUB_DEL_BIND_USER,
}

local ClubMemberLayer = class("ClubMemberLayer", function()
    return cc.Layer:create()
end)

function ClubMemberLayer:create(args)
    local layer = ClubMemberLayer.new(args)
    return layer
end

local REQ_LESS_NUM = 6

function ClubMemberLayer:ctor(args)
    self.minId   = self.minId or 1
    self.isEnded = self.isEnded or false

    self.data        = args.data
    self.isBoss      = args.isBoss
    self.isAdmin     = args.isAdmin
    self.parent      = args.parent
    self.isFullAdmin = args.isFullAdmin
    self:createLayerMenu()
    self:registerEventListener()
    if self.isBoss or self.isAdmin then
        self:onSq(true)
    else
        self.btnPlayer:setVisible(false)
        self.btnSq:setVisible(false)
        self:onUserPlayer(true)
    end
    self:enableNodeEvents()
end

function ClubMemberLayer:onReconnect()

    log('重连')
    if self.MemPanel:isVisible() or self.MemBossPanel:isVisible() or self.MemAdminPanel:isVisible() then
        log('重新请求成员列表')
        self:onClubUserList()
    elseif self.SqPanel:isVisible() then
        log('重新请求请求列表')
        self:reqSq()
    end
end

function ClubMemberLayer:registerEvent()
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

function ClubMemberLayer:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function ClubMemberLayer:onEnter()
    print('onEnter')
    self:registerEvent()
end

function ClubMemberLayer:onExit()
    self:unregisterEvent()
    self:unregisterEventListener()
    self.parent:refreshRodHot(false)
end

function ClubMemberLayer:onRcvClubUserType(rtn_msg)
    if self.users then
        local count = 0
        for i, v in ipairs(self.users) do
            if v.uid == rtn_msg.uid then
                v.type = rtn_msg.type
            end
            if v.type == 2 then
                count = count + 1
            end
        end
        if count >= 3 then
            self.isFullAdmin        = true
            self.parent.isFullAdmin = true
        else
            self.isFullAdmin        = false
            self.parent.isFullAdmin = false
        end
        if self.isBoss then
            self:onUserBoss()
            self:refreshBossList(self.users)
        elseif self.isAdmin then
            self:onUserAdmin()
            self:refreshAdminList(self.users)
        else
            self:onUserPlayer()
            self:refreshPlayerList(self.users)
        end
    end
end

function ClubMemberLayer:resetSqList()
    local serverUidToClub = {}
    for i, v in ipairs(self.sq_list or {}) do
        serverUidToClub[v.uid] = self.sq_list[i]
    end
    local localUidToClub = {}
    for i, v in ipairs(GameGlobal.clubMemberLayerSqList or {}) do
        localUidToClub[v.uid] = GameGlobal.clubMemberLayerSqList[i]
    end

    for i, v in pairs(serverUidToClub) do
        localUidToClub[v.uid]            = serverUidToClub[v.uid]
        localUidToClub[v.uid].fromServer = true
        localUidToClub[v.uid].time       = nil
        localUidToClub[v.uid].tOper      = nil
    end

    for i, v in pairs(localUidToClub) do
        for j, vv in ipairs(GameGlobal.clubMemberLayerSqList) do
            if GameGlobal.clubMemberLayerSqList[j].uid == i then
                GameGlobal.clubMemberLayerSqList[j] = localUidToClub[i]
                localUidToClub[v.uid].fromServer    = false
            end
        end
    end

    for i, v in pairs(localUidToClub) do
        if localUidToClub[i].fromServer then
            table.insert(GameGlobal.clubMemberLayerSqList, 1, localUidToClub[i])
        end
    end

    return GameGlobal.clubMemberLayerSqList
end

function ClubMemberLayer:clubMemberLayerSqListSort()
    GameGlobal.clubMemberLayerSqList = GameGlobal.clubMemberLayerSqList or {}
    local function clubMemberLayerSqListSort(a, b)
        if not a.tOper and b.tOper then
            return true
        end
        return false
    end
    table.sort(GameGlobal.clubMemberLayerSqList, clubMemberLayerSqListSort)
end

function ClubMemberLayer:convertUser(rtn_msg)
    if rtn_msg and 0 == #rtn_msg then
        return rtn_msg
    end
    if rtn_msg[1].uid then
        return rtn_msg
    end
    if #rtn_msg[1] == 7 then
        -- TODO:更新到最新版本
        for i, v in ipairs(rtn_msg) do
            rtn_msg[i].uid             = v[1]
            rtn_msg[i].name            = v[2]
            rtn_msg[i].head            = v[3]
            rtn_msg[i].type            = v[4]
            rtn_msg[i].room_id         = v[5]
            rtn_msg[i].last_login_time = v[6]
            rtn_msg[i].online          = v[7]
        end
    else
        for i, v in ipairs(rtn_msg) do
            rtn_msg[i].uid             = v[1]
            rtn_msg[i].name            = v[2]
            rtn_msg[i].head            = v[3]
            rtn_msg[i].room_id         = v[4]
            rtn_msg[i].last_login_time = v[5]
            rtn_msg[i].online          = v[6]
        end
    end

    return rtn_msg
end

function ClubMemberLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        -- rtn_msg = json.decode(rtn_msg)
        local data = nil
        local function jsonDecode()
            data = json.decode(rtn_msg)
        end
        if not pcall(jsonDecode) then
            print('ClubMemberLayer decode faild')
            gt.uploadErr(tostring(rtn_msg))
            return
        end
        rtn_msg = data
        commonlib.echo(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_CLUB_GET_APPLY_LIST then

            GameGlobal.clubMemberLayerSqList = rtn_msg.list or {}

            self:clubMemberLayerSqListSort()

            self:refreshSqList(GameGlobal.clubMemberLayerSqList)
        elseif rtn_msg.cmd == NetCmd.S2C_CLUB_USER_LIST then
            self:onRcvClubUserList(rtn_msg)
        elseif rtn_msg.cmd == NetCmd.S2C_CLUB_DEL_BIND_USER then
            -- dump(rtn_msg,"S2C_CLUB_DEL_BIND_USER")
            if not rtn_msg.errno or rtn_msg.errno == 0 then
                -- 等 csb 后续优化

                -- 默认为群主删除成员
                local listView = self.MemBossPanel:getChildByName("PlayerList")
                -- 若是管理者，则为管理者删除成员
                if self.isAdmin then
                    listView = self.MemAdminPanel:getChildByName("PlayerList")
                end
                local LayerCont    = listView:getChildByName('LayerCont')
                local itemChildren = LayerCont:getChildren()

                for i, item in pairs(itemChildren) do
                    if item.uid == rtn_msg.uid then
                        item:getChildByName("delete_result"):setVisible(true)
                        item:getChildByName("btn-del"):setVisible(false)
                        -- 群主才有升职按钮，管理者没有升职按钮
                        if not self.isAdmin then
                            item:getChildByName("btn-setting"):setVisible(false)
                        end
                        -- 找到删除的成员
                        break
                    end
                end

                -- 暂时用以下代码重刷 5 个可见
                for i, item in ipairs(self.users or {}) do
                    if item.uid == rtn_msg.uid then
                        table.remove(self.users, i)
                        break
                    end
                end
            else
                commonlib.showLocalTip(rtn_msg.msg or "删除失败")
            end
        elseif rtn_msg.cmd == NetCmd.S2C_CLUB_DO_APPLY then
            -- 有新成员加入，可以重新请求
            if rtn_msg.tag == 1 then
                self.isEnded = false
            end
            if rtn_msg.errno and rtn_msg.errno == 1046 then
                commonlib.showLocalTip("该申请消息已被处理！")
            end
            local listView     = self.SqPanel:getChildByName("PlayerList")
            local LayerCont    = listView:getChildByName('LayerCont')
            local itemChildren = LayerCont:getChildren()
            for i, item in pairs(itemChildren) do
                if item.uid == rtn_msg.uid then
                    item.btnRefuse:setVisible(false)
                    item.btnAgree:setVisible(false)
                    item.tOperResult:setVisible(true)
                    if rtn_msg.tag == 1 then
                        item.tOperResult:setString("已同意")
                    else
                        item.tOperResult:setString("已拒绝")
                    end
                    break
                end
            end

            for index, vv in ipairs(GameGlobal.clubMemberLayerSqList) do
                if GameGlobal.clubMemberLayerSqList[index].uid == rtn_msg.uid then
                    local time = os.time()
                    if rtn_msg.tag == 1 then
                        GameGlobal.clubMemberLayerSqList[index].tOper = 1
                    else
                        GameGlobal.clubMemberLayerSqList[index].tOper = 2
                    end
                    GameGlobal.clubMemberLayerSqList[index].time = time

                    self:clubMemberLayerSqListSort()

                    self:refreshSqList(GameGlobal.clubMemberLayerSqList)

                    self.parent:refreshRodHot(false)
                    break
                end
            end
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end

end

function ClubMemberLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubMemberLayer:exitLayer()
    self.parent:refreshRodHot(false)
    self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubMemberLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_member
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)

    self.MemPanel = ccui.Helper:seekWidgetByName(node, "MemPanel")
    ccui.Helper:seekWidgetByName(self.MemPanel, "item"):setVisible(false)
    self.MemBossPanel = ccui.Helper:seekWidgetByName(node, "MemBossPanel")
    ccui.Helper:seekWidgetByName(self.MemBossPanel, "item"):setVisible(false)
    self.MemAdminPanel = ccui.Helper:seekWidgetByName(node, "MemAdminPanel")
    ccui.Helper:seekWidgetByName(self.MemAdminPanel, "item"):setVisible(false)
    self.SqPanel = ccui.Helper:seekWidgetByName(node, "SqPanel")
    ccui.Helper:seekWidgetByName(self.SqPanel, "itemsq"):setVisible(false)
    self.MemPanel:setVisible(false)
    self.MemBossPanel:setVisible(false)
    self.MemAdminPanel:setVisible(false)
    self.SqPanel:setVisible(false)

    self.btnPlayer = ccui.Helper:seekWidgetByName(node, "btn-player")
    self.btnSq     = ccui.Helper:seekWidgetByName(node, "btn-sq")
    self.find_img  = ccui.Helper:seekWidgetByName(node, "find_img")

    self.btnSq:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:onSq(true)
        end
    end)

    self.btnPlayer:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.fisrtRefresh = false
            if self.isBoss then
                self:onUserBoss(true)
            elseif self.isAdmin then
                self:onUserAdmin(true)
            else
                self:onUserPlayer(true)
            end
        end
    end)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:exitLayer()
        end
    end)

    local InputID = self.find_img:getChildByName("InputID")
    InputID:onEvent(function(event)
        -- dump(event,"InputID")
        if event.name == "INSERT_TEXT" or event.name == "DELETE_BACKWARD" then
            local list     = {}
            local tempList = {}
            if self.SqPanel:isVisible() then
                tempList = GameGlobal.clubMemberLayerSqList
            else
                tempList = self.users
            end
            local str = InputID:getString()
            print("str", str)
            if str == "" then
                list = tempList
            else
                for i, v in ipairs(tempList) do
                    if string.find(v.name, str) or string.find(v.uid, str) then
                        list[#list + 1] = v
                    end
                end
            end
            if self.SqPanel:isVisible() then
                self:refreshSqList(list)
            else
                if self.isBoss then
                    self:refreshBossList(list)
                else
                    self:refreshAdminList(list)
                end
            end
        end
    end)

    self.parent:refreshRodHot(false)

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

function ClubMemberLayer:refreshSqList(list)
    local PlayerList = self.SqPanel:getChildByName("PlayerList")
    local LayerCont  = PlayerList:getChildByName('LayerCont')

    local baseItem = ccui.Helper:seekWidgetByName(self.SqPanel, "itemsq")
    baseItem:setVisible(false)

    self:clubMemberLayerSqListSort()

    local CScrollViewLoad = require('club.CScrollViewLoad')
    if not CScrollViewLoad then
        gt.uploadErr('not CScrollViewLoad old res')
        return
    end
    local minCell = math.max(5, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
    local function setItem(i, v)
        local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'SqItem' .. i, self.sqCellPos[i])

        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        item:getChildByName("touxiang"):downloadImg(commonlib.wxHead(v.head))
        item:getChildByName("id"):setString(tostring(v.uid))
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            item:getChildByName("name"):setString(tostring(commonlib.GetMaxLenString(v.name, 14)))
        else
            item:getChildByName("name"):setString(tostring(v.name))
        end

        -- item:getChildByName("name"):setString(tostring(i))

        item:getChildByName("tDate"):setString(os.date("%Y/%m/%d", v.last_login_time))
        item.tOperResult = item:getChildByName("tOperResult"):setVisible(false)
        item.btnRefuse   = item:getChildByName("btn-refuse")
        item.btnRefuse:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_DO_APPLY,
                    uid     = v.uid,
                    tag     = 2,
                    id      = v.id,
                    name    = v.name,
                    club_id = self.data.club_info.club_id,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)
        item.btnAgree = item:getChildByName("btn-agree")
        item.btnAgree:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_DO_APPLY,
                    uid     = v.uid,
                    tag     = 1,
                    id      = v.id,
                    name    = v.name,
                    club_id = self.data.club_info.club_id,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)

        if GameGlobal.clubMemberLayerSqList[i].tOper then
            item.btnRefuse:setVisible(false)
            item.btnAgree:setVisible(false)
            item.tOperResult:setVisible(true)
            if GameGlobal.clubMemberLayerSqList[i].tOper == 1 then
                item.tOperResult:setString("已同意")
            else
                item.tOperResult:setString("已拒绝")
            end
        else
            item.btnRefuse:setVisible(true)
            item.btnAgree:setVisible(true)
            item.tOperResult:setVisible(false)
        end

        item.uid = v.uid
    end

    -- for i,v in ipairs(list or {}) do
    --     setItem(i,v)
    -- end
    self.sqMaxNum = CScrollViewLoad.resetList(self.sqMaxNum, list, LayerCont, 'SqItem')

    local function setCellPos()
        self.sqCellPos = CScrollViewLoad.setCellItemPos(self.sqMaxNum,
            self.sqCellPos,
            baseItem:getContentSize().width / 2,
            LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
            baseItem:getContentSize().width,
            -baseItem:getContentSize().height)
    end
    setCellPos()
    local function setSqItem()
        if self.sqMaxNum < #list then
            self.sqMaxNum = #list
            setCellPos()
        end
        CScrollViewLoad.setListItem(list, self.sqCellPos, LayerCont, 'SqItem', setItem, baseItem, PlayerList)
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
end

-- 亲友圈成员列表
function ClubMemberLayer:refreshPlayerList(list)
    print('--------------------')
    print('--------------------')
    print('--------------------')
    print('--------------------')
    print('--------------------')
    local PlayerList = self.MemPanel:getChildByName("PlayerList")
    local LayerCont  = PlayerList:getChildByName('LayerCont')
    local baseItem   = ccui.Helper:seekWidgetByName(self.MemPanel, "item")
    baseItem:setVisible(false)

    self:sortMemberPlayer(list)

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(5, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
    local function setItem(i, v)
        local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'memberItem' .. i, self.member2CellPos[i])
        item:setVisible(true)
        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        -- dump(v,"v")
        local profile = ProfileManager.GetProfile()
        if profile.uid == v.uid and v.type == 3 then
            item:getChildByName("touxiangk"):getChildByName("banLogo"):setVisible(true)
        else
            item:getChildByName("touxiangk"):getChildByName("banLogo"):setVisible(false)
        end
        local head_url = commonlib.wxHead(v.head)
        item:getChildByName("touxiang"):downloadImg(head_url)
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            item:getChildByName("name"):setString(tostring(commonlib.GetMaxLenString(v.name, 14)))
        else
            item:getChildByName("name"):setString(tostring(v.name))
        end
        local statusLabel = item:getChildByName("staus")
        if v.online == 0 then
            local outLineTime = os.time() - v.last_login_time
            if outLineTime < 3600 then
                statusLabel:setString("离线小于1小时")
            elseif outLineTime <= 86400 then
                statusLabel:setString("离线" .. (math.modf(outLineTime / 3600)) .. "小时")
            else
                statusLabel:setString("离线大于" .. (math.modf(outLineTime / 86400)) .. "天")
            end
            statusLabel:setColor(cc.c3b(104, 103, 103))
        elseif v.online == 1 then
            if v.room_id == 0 then
                statusLabel:setString("空闲中")
                statusLabel:setColor(cc.c3b(174, 91, 86))
            else
                statusLabel:setString("游戏中")
                statusLabel:setColor(cc.c3b(224, 8, 30))
            end
        end

        item:getChildByName("id"):setString(string.format("ID:%s", tostring(v.uid)))
        item.uid = v.uid
    end

    -- for i,v in ipairs(list or {}) do
    --     setItem(i,v)
    -- end

    self.member2MaxNum = CScrollViewLoad.resetList(self.member2MaxNum, list, LayerCont, 'memberItem')

    local function setCellPos()
        self.member2CellPos = CScrollViewLoad.setCellItemPos(self.member2MaxNum,
            self.member2CellPos,
            baseItem:getContentSize().width / 2,
            LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
            baseItem:getContentSize().width,
            -baseItem:getContentSize().height)
    end
    setCellPos()

    local function setMemberItem()
        if self.member2MaxNum < #list then
            self.member2MaxNum = #list
            setCellPos()
        end
        CScrollViewLoad.setListItem(list, self.member2CellPos, LayerCont, 'memberItem', setItem, baseItem, PlayerList)
    end
    setMemberItem()

    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
    local function ScrollViewCallBack(sender, eventType)
        if eventType == 4 then
            setMemberItem()
            local children = LayerCont:getChildren()
            -- print('$ --------------- ' .. tostring(#children))

        end
        scorllCallBack(sender, eventType)
    end
    PlayerList:addEventListener(ScrollViewCallBack)
    PlayerList:addTouchEventListener(touchCallBack)

    local children = LayerCont:getChildren()
    -- print('$ --------------- ' .. tostring(#children))
end

-- 对普通成员排序
function ClubMemberLayer:sortMemberPlayer(list)
    local function listSort(a, b)
        if a.uid == self.data.club_info.club_id then
            return true
        elseif a.uid ~= self.data.club_info.club_id and b.uid ~= self.data.club_info.club_id and a.uid == gt.getData('uid') then
            return true
        elseif a.uid ~= self.data.club_info.club_id and b.uid ~= self.data.club_info.club_id and a.uid ~= gt.getData('uid') and b.uid ~= gt.getData('uid') then
            -- 在线中
            if a.online == 1 and b.online ~= 1 then
                return true
            elseif a.online == 1 and b.online == 1 then
                if a.room_id ~= 0 and b.room_id == 0 then
                    return true
                elseif a.room_id ~= 0 and b.room_id ~= 0 then
                    return false
                elseif a.room_id == 0 and b.room_id == 0 then
                    return false
                end
            elseif a.online == 0 and b.online == 0 then
                if a.last_login_time > b.last_login_time then
                    return true
                end
                return false
            end
        end
        return false
    end
    commonlib.insertSort(list, listSort)
    return list
end

-- 对管理者排序
function ClubMemberLayer:sortMemberAdmin(list)
    function listSort(a, b)
        if a.uid == self.data.club_info.club_id then
            return true
            -- 1群主 2 管理员 0普通成员
        elseif a.uid ~= self.data.club_info.club_id and b.uid ~= self.data.club_info.club_id and (a.type ~= b.type) then
            if (a.type == 3 or b.type == 3) and a.type ~= 0 and b.type ~= 0 then
                if a.type < b.type then
                    return true
                end
            else
                if a.type > b.type then
                    return true
                end
            end
        elseif a.uid ~= self.data.club_info.club_id and b.uid ~= self.data.club_info.club_id and a.uid == gt.getData('uid') then
            return true
        elseif a.uid ~= self.data.club_info.club_id and b.uid ~= self.data.club_info.club_id and a.uid ~= gt.getData('uid') and b.uid ~= gt.getData('uid') then
            -- 在线中
            if a.online == 1 and b.online ~= 1 then
                return true
            elseif a.online == 1 and b.online == 1 then
                if a.room_id ~= 0 and b.room_id == 0 then
                    return true
                elseif a.room_id ~= 0 and b.room_id ~= 0 then
                    return false
                elseif a.room_id == 0 and b.room_id == 0 then
                    return false
                end
            elseif a.online == 0 and b.online == 0 then
                if a.last_login_time > b.last_login_time then
                    return true
                end
                return false
            end
        end
        return false
    end
    commonlib.insertSort(list, listSort)
    return list
end

-- 亲友圈成员管理者列表
function ClubMemberLayer:refreshAdminList(list)
    local PlayerList = self.MemAdminPanel:getChildByName("PlayerList")
    local LayerCont  = PlayerList:getChildByName('LayerCont')
    local baseItem   = ccui.Helper:seekWidgetByName(self.MemAdminPanel, "item")
    baseItem:setVisible(false)

    self:sortMemberAdmin(list)

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(5, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
    local function setItem(i, v)
        local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'memberItem' .. i, self.memberCellPos[i])

        item:setVisible(true)
        -- item:getChildByName("managerlogo"):setVisible(false)
        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        local adminLogo = item:getChildByName("touxiangk"):getChildByName("adminLogo")
        local banLogo   = item:getChildByName("touxiangk"):getChildByName("banLogo")
        local btnBan    = item:getChildByName("btn-ban")
        banLogo:setVisible(false)
        if v.type == 1 or v.type == 2 then
            btnBan:setVisible(false)
        elseif v.type == 0 then
            btnBan:loadTextureNormal("ui/qj_club/btnBan.png")
            btnBan:setVisible(true)
        elseif v.type == 3 then
            btnBan:setVisible(true)
            btnBan:loadTextureNormal("ui/qj_club/btnUnban.png")
            banLogo:setVisible(true)
        end
        if v.type == 2 then
            adminLogo:setVisible(true)
        else
            adminLogo:setVisible(false)
        end
        local head_url = commonlib.wxHead(v.head)
        item:getChildByName("touxiang"):downloadImg(head_url)
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            item:getChildByName("name"):setString(tostring(commonlib.GetMaxLenString(v.name, 14)))
        else
            item:getChildByName("name"):setString(tostring(v.name))
        end
        -- 设置删除玩家结果不可见
        item:getChildByName("delete_result"):setVisible(false)
        local statusLabel = item:getChildByName("staus")
        if v.online == 0 then
            local outLineTime = os.time() - v.last_login_time
            if outLineTime < 3600 then
                statusLabel:setString("离线小于1小时")
            elseif outLineTime <= 86400 then
                statusLabel:setString("离线" .. (math.modf(outLineTime / 3600)) .. "小时")
            else
                statusLabel:setString("离线大于" .. (math.modf(outLineTime / 86400)) .. "天")
            end
            statusLabel:setColor(cc.c3b(104, 103, 103))
        elseif v.online == 1 then
            if v.room_id == 0 then
                statusLabel:setString("空闲中")
                statusLabel:setColor(cc.c3b(174, 91, 86))
            else
                statusLabel:setString("游戏中")
                statusLabel:setColor(cc.c3b(224, 8, 30))
            end
        end
        item:getChildByName("id"):setString(string.format("ID:%s", tostring(v.uid)))
        item.btnDel = item:getChildByName("btn-del")
        if v.type == 1 or v.type == 2 then
            item.btnDel:setTouchEnabled(false)
            item.btnDel:setVisible(false)
        else
            item.btnDel:setTouchEnabled(true)
            item.btnDel:setVisible(true)
        end
        if v.uid == self.data.club_info.club_id or v.uid == gt.getData('uid') then
            item.btnDel:setTouchEnabled(false)
            item.btnDel:setVisible(false)
        end
        btnBan:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local str      = ""
                local userType = 0
                if v.type == 3 then
                    str      = "解封玩家"
                    userType = 0
                else
                    str      = "封禁玩家"
                    userType = 3
                end
                self.send_UserType = userType
                self.send_UserId   = v.uid
                local args = {
                    msg = string.format("你确定要"..str.."%s(%s)吗？", tostring(v.name), tostring(v.uid)),
                    okFunc = function()
                        -- 向服务器发送对应的消息
                        local input_msg = {
                            cmd     = NetCmd.C2S_CLUB_USER_TYPE,
                            uid     = v.uid,
                            type    = userType,
                            club_id = self.data.club_info.club_id,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)
        item.btnDel:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local args = {
                    msg = string.format("你确定把%s(%s)踢出亲友圈吗?", tostring(v.name), tostring(v.uid)),
                    okFunc = function()
                        local input_msg = {
                            cmd     = NetCmd.C2S_CLUB_DEL_BIND_USER,
                            club_id = self.data.club_info.club_id,
                            uid     = v.uid,
                            name    = v.name,
                            isBoss  = true,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)
        -- 记录成员的id
        item.uid = v.uid

    end
    self.memberMaxNum = CScrollViewLoad.resetList(self.memberMaxNum, list, LayerCont, 'memberItem')

    local function setCellPos()
        self.memberCellPos = CScrollViewLoad.setCellItemPos(self.memberMaxNum,
            self.memberCellPos,
            baseItem:getContentSize().width / 2,
            LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
            baseItem:getContentSize().width,
            -baseItem:getContentSize().height)
    end
    setCellPos()

    local function setMemberItem()
        if self.memberMaxNum < #list then
            self.memberMaxNum = #list
            setCellPos()
        end
        CScrollViewLoad.setListItem(list, self.memberCellPos, LayerCont, 'memberItem', setItem, baseItem, PlayerList)
    end
    setMemberItem()

    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
    local function ScrollViewCallBack(sender, eventType)
        if eventType == 4 then
            setMemberItem()
            local children = LayerCont:getChildren()

            -- print('$ --------------- ' .. tostring(#children))
        end
        scorllCallBack(sender, eventType)
    end
    PlayerList:addEventListener(ScrollViewCallBack)
    PlayerList:addTouchEventListener(touchCallBack)

    local children = LayerCont:getChildren()
    -- print('$ --------------- ' .. tostring(#children))
end

-- 亲友圈群主列表
function ClubMemberLayer:refreshBossList(list)
    local PlayerList = self.MemBossPanel:getChildByName("PlayerList")   -- 是一个ScrollView
    local LayerCont  = PlayerList:getChildByName('LayerCont')            -- 是一个Layout
    local baseItem   = ccui.Helper:seekWidgetByName(self.MemBossPanel, "item")   -- 每一个成员
    baseItem:setVisible(false)

    self:sortMemberAdmin(list)

    local adminCount = 0 -- 管理者人员数量
    for __, v in ipairs(list) do
        if v.type == 2 then
            adminCount = adminCount + 1
        end
    end
    if adminCount >= 3 then
        self.isFullAdmin        = true
        self.parent.isFullAdmin = true
    else
        self.isFullAdmin        = false
        self.parent.isFullAdmin = false
    end

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(5, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)
    local function setItem(i, v)
        local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'memberItem' .. i, self.memberCellPos[i])

        item:setVisible(true)
        local adminLogo = item:getChildByName("touxiangk"):getChildByName("adminLogo")
        local banLogo   = item:getChildByName("touxiangk"):getChildByName("banLogo")
        local btnBan    = item:getChildByName("btn-ban")
        banLogo:setVisible(false)
        if v.type == 1 then
            btnBan:setVisible(false)
        elseif v.type == 0 or v.type == 2 then
            btnBan:setVisible(true)
            btnBan:loadTextureNormal("ui/qj_club/btnBan.png")
        elseif v.type == 3 then
            btnBan:setVisible(true)
            btnBan:loadTextureNormal("ui/qj_club/btnUnban.png")
            banLogo:setVisible(true)
        end
        if v.type == 2 then
            adminLogo:setVisible(true)
        else
            adminLogo:setVisible(false)
        end
        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        local head_url = commonlib.wxHead(v.head)
        item:getChildByName("touxiang"):downloadImg(head_url)
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            item:getChildByName("name"):setString(tostring(commonlib.GetMaxLenString(v.name, 14)))
        else
            item:getChildByName("name"):setString(tostring(v.name))
        end
        -- 设置删除玩家结果不可见
        item:getChildByName("delete_result"):setVisible(false)
        local statusLabel = item:getChildByName("staus")
        if v.online == 0 then
            local outLineTime = os.time() - v.last_login_time
            if outLineTime < 3600 then
                statusLabel:setString("离线小于1小时")
            elseif outLineTime <= 86400 then
                statusLabel:setString("离线" .. (math.modf(outLineTime / 3600)) .. "小时")
            else
                statusLabel:setString("离线大于" .. (math.modf(outLineTime / 86400)) .. "天")
            end
            statusLabel:setColor(cc.c3b(104, 103, 103))
        elseif v.online == 1 then
            if v.room_id == 0 then
                statusLabel:setString("空闲中")
                statusLabel:setColor(cc.c3b(174, 91, 86))
            else
                statusLabel:setString("游戏中")
                statusLabel:setColor(cc.c3b(224, 8, 30))
            end
        end
        item:getChildByName("id"):setString(string.format("ID:%s", tostring(v.uid))) -- 玩家ID
        -- 踢出按钮
        item.btnDel = item:getChildByName("btn-del")
        -- 升职按钮
        item.btnSet = item:getChildByName("btn-setting")

        -- self.isBoss = args.isBoss    -- 群主ID
        -- self.isAdmin = args.isAdmin  -- 管理员ID
        -- club_id = self.data.club_info.club_id -- 亲友圈ID也是群主ID
        -- v.uid:每一行的ID    gt.getData("uid")：获得本人的ID
        if v.uid == gt.getData("uid") then
            if gt.getData("uid") == self.data.club_info.club_id then
                item.btnDel:setTouchEnabled(false)
                item.btnDel:setVisible(false)
                item.btnSet:setTouchEnabled(false)
                item.btnSet:setVisible(false)
            end
        else
            item.btnDel:setTouchEnabled(true)
            item.btnDel:setVisible(true)
            item.btnSet:setTouchEnabled(true)
            item.btnSet:setVisible(true)
        end

        btnBan:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local str      = ""
                local userType = 0
                if v.type == 3 then
                    str      = "解封玩家"
                    userType = 0
                else
                    str      = "封禁玩家"
                    userType = 3
                end
                self.send_UserType = userType
                self.send_UserId   = v.uid
                local args = {
                    msg = string.format("你确定要"..str.."%s(%s)吗？", tostring(v.name), tostring(v.uid)),
                    okFunc = function()
                        -- 向服务器发送对应的消息
                        local input_msg = {
                            cmd  = NetCmd.C2S_CLUB_USER_TYPE,
                            uid  = v.uid,
                            type = userType,
                            club_id = self.data.club_info.club_id,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)

        self:refreshBtnSet(item.btnSet, v.type or 0)
        item.btnSet:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local str      = ""
                local userType = 0
                if v.type == 2 then
                    str      = "降职为普通成员吗？"
                    userType = 0
                else
                    str      = "升职为管理员吗？"
                    userType = 2
                end
                self.send_UserType = userType
                self.send_UserId   = v.uid
                local args = {
                    msg = string.format("你确定把%s(%s)"..str, tostring(v.name), tostring(v.uid)),
                    okFunc = function()
                        -- 向服务器发送对应的消息
                        local input_msg = {
                            cmd  = NetCmd.C2S_CLUB_USER_TYPE,
                            uid  = v.uid,
                            type = userType,
                            club_id = self.data.club_info.club_id,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)
        item.btnDel:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local str = ""
                if v.type == 2 then
                    str = "管理员"
                end
                local args = {
                    msg = string.format("你确定把"..str.."%s(%s)踢出亲友圈吗?", tostring(v.name), tostring(v.uid)),
                    okFunc = function()
                        local input_msg = {
                            cmd     = NetCmd.C2S_CLUB_DEL_BIND_USER,
                            club_id = self.data.club_info.club_id,  -- 亲友圈ID也是群主ID
                            uid     = v.uid,
                            name    = v.name,
                            isBoss  = true,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)
        -- 记录成员的id
        item.uid = v.uid
    end
    self.memberMaxNum = CScrollViewLoad.resetList(self.memberMaxNum, list, LayerCont, 'memberItem')

    local function setCellPos()
        self.memberCellPos = CScrollViewLoad.setCellItemPos(self.memberMaxNum,
            self.memberCellPos,
            baseItem:getContentSize().width / 2,
            LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
            baseItem:getContentSize().width,
            -baseItem:getContentSize().height)
    end
    setCellPos()

    local function setMemberItem()
        if self.memberMaxNum < #list then
            self.memberMaxNum = #list
            setCellPos()
        end
        CScrollViewLoad.setListItem(list, self.memberCellPos, LayerCont, 'memberItem', setItem, baseItem, PlayerList)
    end
    setMemberItem()

    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(PlayerList)
    local function ScrollViewCallBack(sender, eventType)
        if eventType == 4 then
            setMemberItem()
            local children = LayerCont:getChildren()

            -- print('$ --------------- ' .. tostring(#children))
        end
        scorllCallBack(sender, eventType)
    end
    PlayerList:addEventListener(ScrollViewCallBack)
    PlayerList:addTouchEventListener(touchCallBack)

    local children = LayerCont:getChildren()
    -- print('$ --------------- ' .. tostring(#children))
    -- if bListView then
    --     _parent:addScrollViewEventListener(ScrollViewCallBack)
    -- end
    -- _parent:addEventListener(ScrollViewCallBack)
    -- _parent:addTouchEventListener(touchCallBack)
end

function ClubMemberLayer:onSq(bForce)
    self.MemPanel:setVisible(false)
    self.MemBossPanel:setVisible(false)
    self.MemAdminPanel:setVisible(false)
    self.SqPanel:setVisible(true)
    self.btnSq:setTouchEnabled(false)
    self.btnPlayer:setTouchEnabled(true)
    self.btnSq:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.btnPlayer:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.btnSq:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btnSq:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btnPlayer:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_1.png")
    self.btnPlayer:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_2.png")

    self:reqSq()
end

function ClubMemberLayer:reqSq()
    if self.sq_list == nil or bForce then
        local net_msg = {
            cmd     = NetCmd.C2S_CLUB_GET_APPLY_LIST,
            club_id = self.data.club_info.club_id
        }
        ymkj.SendData:send(json.encode(net_msg))
    end
end

-- 请求亲友圈成员列表
function ClubMemberLayer:onClubUserList()
    if self.isEnded then
        return
    end
    local net_msg = {
        cmd     = NetCmd.C2S_CLUB_USER_LIST,
        club_id = self.data.club_info.club_id,
        minId   = self.minId,
    }
    print('请求服务端 club user list')
    dump(net_msg)
    ymkj.SendData:send(json.encode(net_msg))

    self.getClubUserListShow = true
    -- 若能在3秒内能收到亲友圈点击的消息，则把 self.getClubUserListShow 设置为false
    self:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function ()
        if self.getClubUserListShow then
            commonlib.showLocalTip("拉取数据失败，请关闭后重新打开")
        end
    end)))
end

function ClubMemberLayer:onUserPlayer(isUpdate)
    self.MemPanel:setVisible(true)
    self.MemBossPanel:setVisible(false)
    self.MemAdminPanel:setVisible(false)
    self.SqPanel:setVisible(false)
    self.btnSq:setTouchEnabled(false)
    self.btnSq:setVisible(false)
    self.btnPlayer:setTouchEnabled(false)
    self.btnPlayer:setVisible(false)
    self.find_img:setVisible(false)
    self.btnSq:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.btnPlayer:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.btnSq:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btnSq:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btnPlayer:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    self.btnPlayer:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_1.png")

    self.refreash = false
    if isUpdate then
        self:onClubUserList()
    end
end

function ClubMemberLayer:onUserAdmin(isUpdate)
    self.MemPanel:setVisible(false)
    self.MemBossPanel:setVisible(false)
    self.MemAdminPanel:setVisible(true)
    self.SqPanel:setVisible(false)
    self.btnSq:setTouchEnabled(true)
    self.btnSq:setVisible(true)
    self.btnPlayer:setVisible(true)
    self.btnPlayer:setTouchEnabled(false)
    self.btnSq:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.btnPlayer:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.btnSq:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btnSq:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btnPlayer:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    self.btnPlayer:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_1.png")

    if isUpdate then
        self:onClubUserList()
    end
end

function ClubMemberLayer:onUserBoss(isUpdate)
    self.MemPanel:setVisible(false)
    self.MemBossPanel:setVisible(true)
    self.MemAdminPanel:setVisible(false)
    self.SqPanel:setVisible(false)
    self.btnSq:setVisible(true)
    self.btnSq:setTouchEnabled(true)
    self.btnPlayer:setVisible(true)
    self.btnPlayer:setTouchEnabled(false)
    self.btnSq:getChildByName("Text_3"):setColor(cc.c3b(124, 125, 159))
    self.btnPlayer:getChildByName("Text_3"):setColor(cc.c3b(224, 229, 254))
    self.btnSq:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_left_1.png")
    self.btnSq:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_left_2.png")
    self.btnPlayer:loadTextureNormal("ui/qj_button/dt_clubOther_biaoqian_right_2.png")
    self.btnPlayer:loadTexturePressed("ui/qj_button/dt_clubOther_biaoqian_right_1.png")

    if isUpdate then
        self:onClubUserList()
    end
end
-- btnType = 0 普通成员
-- btnType = 1 群主
-- btnType = 2 管理员
-- btnType = 3 被封禁成员
function ClubMemberLayer:refreshBtnSet(btn, btnType)
    if btnType == 2 then
        btn:setBright(true)
        btn:setTouchEnabled(true)
        btn:loadTextureNormal("ui/qj_club/btnBg2.png")
        btn:loadTexturePressed("ui/qj_club/btnBg0.png")
        btn:getChildByName("zi"):loadTexture("ui/qj_club/demotion.png")
    elseif btnType == 0 or btnType == 3 then
        if self.isFullAdmin then
            btn:setBright(false)
            btn:setTouchEnabled(false)
            btn:getChildByName("zi"):loadTexture("ui/qj_club/promote0.png")
        else
            btn:setBright(true)
            btn:setTouchEnabled(true)
            btn:loadTextureNormal("ui/qj_club/btnBg1.png")
            btn:loadTexturePressed("ui/qj_club/btnBg0.png")
            btn:getChildByName("zi"):loadTexture("ui/qj_club/promote1.png")
        end
    end
end

-- 接受到 显示亲友圈成员列表 消息 调用
function ClubMemberLayer:onRcvClubUserList(rtn_msg)
    print('收服务端信息 club user list')

    self.getClubUserListShow = false

    rtn_msg.users = self:convertUser(rtn_msg.users)
    local minId   = rtn_msg.minId
    self.users    = self.users or {}

    local function checkMinId(localMinId, serverMinId)
        if localMinId ~= serverMinId then
            return false
        end
        return true
    end

    if not checkMinId(self.minId, minId) then
        return
    end

    self.isEnded = rtn_msg.isEnded

    self.minId = self.minId + #rtn_msg.users

    self.users = commonlib.appendTable(self.users, rtn_msg.users)

    self:onClubUserList()

    if not self.isEnded and self.fisrtRefresh then
        return
    end
    print('总共' .. self.minId - 1)
    if self.isBoss then
        self:refreshBossList(self.users)
    elseif self.isAdmin then
        self:refreshAdminList(self.users)
    else
        self:refreshPlayerList(self.users)
    end

    self.fisrtRefresh = true
end

return ClubMemberLayer