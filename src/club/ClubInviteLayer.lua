local cmd_list = {
    NetCmd.S2C_CLUB_IDLE_PLAYERS,
}

local RESET_INVITE_BUTTON_TIME = 120

local ClubInviteLayer = class("ClubInviteLayer", function()
    return cc.Layer:create()
end)

function ClubInviteLayer:create(args)
    local layer = ClubInviteLayer.new(args)
    print('invite')
    -- dump(args)
    -- layer:createLayerMenu()
    return layer
end

function ClubInviteLayer:ctor(args)
    self.club_id   = args.club_id
    self.club_name = args.club_name
    self.room_id   = args.room_id
    self.room_info = args.room_info
    self.parent    = args.parent
    self:createLayerMenu()
    self:registerEventListener()
    self:onInvite()

    self:enableNodeEvents()
end

function ClubInviteLayer:onEnter()
    -- self:registerEventListener()
    -- self:onInvite()
end

function ClubInviteLayer:onExit()
    self:stopListItemAction()
    self:unregisterEventListener()
end

function ClubInviteLayer:registerEventListener()

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
            print('ClubInviteLayer decode faild')
            gt.uploadErr(tostring(rtn_msg))
            return
        end
        rtn_msg = data
        commonlib.echo(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_CLUB_IDLE_PLAYERS then

            rtn_msg = self:convertClubIdlePlayers(rtn_msg)

            -- dump(rtn_msg)

            self.player_list = rtn_msg.idleUsers

            self:refreshInvite()
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ClubInviteLayer:convertClubIdlePlayers(rtn_msg)
    if rtn_msg.idleUsers and 0 == #rtn_msg.idleUsers then
        return rtn_msg
    end
    if rtn_msg.idleUsers[1].uid then
        return rtn_msg
    end
    -- dump(rtn_msg.idleUsers)

    for i, v in ipairs(rtn_msg.idleUsers) do
        rtn_msg.idleUsers[i].uid  = v[1]
        rtn_msg.idleUsers[i].name = v[2]
        rtn_msg.idleUsers[i].head = v[3]
    end

    return rtn_msg
end

function ClubInviteLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubInviteLayer:exitLayer()
    self:removeFromParent(true)
end

function ClubInviteLayer:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/club_invite.csb"), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node

    local function exitCallBack()
        self.parentBtnClubInvite:setVisible(true)
        self:exitLayer()
    end
    local tInviteClubName = ccui.Helper:seekWidgetByName(node, "tInviteClubName")
    if pcall(commonlib.GetMaxLenString, self.club_name, 14) then
        tInviteClubName:setString(commonlib.GetMaxLenString(self.club_name, 10) or self.club_id)
    else
        tInviteClubName:setString(self.club_name or self.club_id)
    end

    local TouchPanel = ccui.Helper:seekWidgetByName(node, "TouchPanel")
    local Layer      = cc.Layer:create()
    TouchPanel:addChild(Layer)

    Layer:setTouchEnabled(true)
    Layer:registerScriptTouchHandler(function(touch_type, xx, yy)
        exitCallBack()
    end)

    self.FriendPanel = ccui.Helper:seekWidgetByName(node, "FriendPanel")
    local item       = ccui.Helper:seekWidgetByName(self.FriendPanel, "item")
    item:setVisible(false)

    self.tInviteNoMemNotice = ccui.Helper:seekWidgetByName(node, "tInviteNoMemNotice")
    self.tInviteNoMemNotice:setVisible(false)

    self.btnClubInvite       = ccui.Helper:seekWidgetByName(node, "btn-clubinvite")
    self.parentBtnClubInvite = ccui.Helper:seekWidgetByName(self.parent, "btn-clubinvite")
    self.parentBtnClubInvite:setVisible(false)

    local parentPosX, parentPosY = self.parentBtnClubInvite:getPosition()
    local worldPos = self.parent:convertToWorldSpace(cc.p(parentPosX, parentPosY))
    local layerpos = node:convertToNodeSpace(worldPos)

    self.btnClubInvite:setPosition(layerpos)
    self.btnClubInvite:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                print('btnClubInvite ClubInviteLayer')
                exitCallBack()
            end
        end
    )

    self.FriendPanel:setPositionX(self.FriendPanel:getContentSize().width / 2 + self.btnClubInvite:getContentSize().width / 2 + self.btnClubInvite:getPositionX() + 5)
end

function ClubInviteLayer:onInvite()
    local input_msg = {
        cmd     = NetCmd.C2S_CLUB_IDLE_PLAYERS,
        club_id = self.club_id,
        room_id = self.room_id,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function ClubInviteLayer:stopListItemAction()
    local listView  = self.FriendPanel:getChildByName("PlayerList")
    local LayerCont = listView:getChildByName("LayerCont")
    local all_items = LayerCont:getChildren()
    for i, v in ipairs(all_items) do
        v:stopAllActions()
    end
end

function ClubInviteLayer:refreshInvite()

    local list = self.player_list

    local PlayerList = self.FriendPanel:getChildByName("PlayerList")
    local LayerCont  = PlayerList:getChildByName('LayerCont')

    local baseItem = ccui.Helper:seekWidgetByName(self.FriendPanel, "item")
    baseItem:setVisible(false)

    local CScrollViewLoad = require('club.CScrollViewLoad')
    local minCell         = math.max(6, #list)
    CScrollViewLoad.setLayerCont(PlayerList, LayerCont, baseItem:getContentSize().height * minCell)

    if self.player_list and #self.player_list > 0 then
        local function setItem(i, v)
            local item = CScrollViewLoad.newCellorGetCellByName(LayerCont, baseItem, 'PlayerItem' .. i, self.playerCellPos[i])
            item:setVisible(true)
            item:getChildByName("touxiang"):downloadImg(commonlib.wxHead(v.head or ''))
            item:getChildByName("tStatus"):setString('空闲')
            if pcall(commonlib.GetMaxLenString, tostring(v.name), 12) then
                item:getChildByName("name"):setString(commonlib.GetMaxLenString(tostring(v.name), 12))
            else
                item:getChildByName("name"):setString(tostring(v.name))
            end
            -- listView:pushBackCustomItem(item)

            item.uid = v.uid
            --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            local function setItemNormalStatus(item)
                item:stopAllActions()
                item:getChildByName("btn-invite"):getChildByName('zi'):setVisible(true)
                item:getChildByName("btn-invite"):setTitleText('')
                item:getChildByName("btn-invite"):setTouchEnabled(true)
                item:getChildByName("btn-invite"):setBright(true)
            end

            local function setItemTimecount(item)
                item:getChildByName("btn-invite"):getChildByName('zi'):setVisible(false)
                local lLastTime = GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] - os.time()
                local second    = string.format('邀请%ds', lLastTime)
                item:getChildByName("btn-invite"):setTitleText(second)
                item:getChildByName("btn-invite"):setTouchEnabled(false)
                item:getChildByName("btn-invite"):setBright(false)
                item:stopAllActions()
                item:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
                    local lLastTime = GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] - os.time()
                    if lLastTime <= 0 then
                        item:stopAllActions()
                        setItemNormalStatus(item)
                        return
                    end
                    local second = string.format('邀请%ds', lLastTime)
                    item:getChildByName("btn-invite"):setTitleText(second)
                end))))
            end

            if GameGlobal.tClubInviteLastCanInviteTime and
                GameGlobal.tClubInviteLastCanInviteTime[self.club_id] and
                GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] and
                GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] - os.time() > 0
                then

                setItemTimecount(item)
            else
                GameGlobal.tClubInviteLastCanInviteTime                      = GameGlobal.tClubInviteLastCanInviteTime or {}
                GameGlobal.tClubInviteLastCanInviteTime[self.club_id]        = GameGlobal.tClubInviteLastCanInviteTime[self.club_id] or {}
                GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] = 0

                setItemNormalStatus(item)
            end
            --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            item:getChildByName("btn-invite"):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    print("邀请")
                    --------------------------------------------------------------------------------
                    --------------------------------------------------------------------------------
                    GameGlobal.tClubInviteLastCanInviteTime                      = GameGlobal.tClubInviteLastCanInviteTime or {}
                    GameGlobal.tClubInviteLastCanInviteTime[self.club_id]        = GameGlobal.tClubInviteLastCanInviteTime[self.club_id] or {}
                    GameGlobal.tClubInviteLastCanInviteTime[self.club_id][v.uid] = os.time() + RESET_INVITE_BUTTON_TIME

                    setItemTimecount(item)
                    --------------------------------------------------------------------------------
                    --------------------------------------------------------------------------------
                    local input_msg = {
                        cmd       = NetCmd.C2S_CLUB_INVITE_PLAY,
                        uid       = v.uid,
                        room_id   = self.room_id,
                        name      = gt.getData('name'),
                        club_name = self.club_name,
                        head      = gt.getData('head'),
                        room_info = self.room_info,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                end
            end)
        end
        self.tInviteNoMemNotice:setVisible(false)

        self.playerMaxNum = CScrollViewLoad.resetList(self.playerMaxNum, list, LayerCont, 'PlayerItem')

        local function setCellPos()
            self.playerCellPos = CScrollViewLoad.setCellItemPos(self.playerMaxNum,
                self.playerCellPos,
                baseItem:getContentSize().width / 2,
                LayerCont:getContentSize().height - baseItem:getContentSize().height / 2,
                baseItem:getContentSize().width,
                -baseItem:getContentSize().height)
        end
        setCellPos()
        local function setPlayerItem()
            if self.playerMaxNum < #list then
                self.playerMaxNum = #list
                setCellPos()
            end
            CScrollViewLoad.setListItem(list, self.playerCellPos, LayerCont, 'PlayerItem', setItem, baseItem, PlayerList)
        end
        setPlayerItem()

        local function ScrollViewCallBack(sender, eventType)
            if eventType == 4 then
                setPlayerItem()
                local children = LayerCont:getChildren()
                -- print('$ --------------- ' .. tostring(#children))
            end
        end
        PlayerList:addEventListener(ScrollViewCallBack)

        local children = LayerCont:getChildren()
        -- print('$ --------------- ' .. tostring(#children))
    else
        -- local listView = self.FriendPanel:getChildByName("PlayerList")
        -- listView:removeAllItems()
        self.tInviteNoMemNotice:setVisible(true)
        -- commonlib.showLocalTip("还没有空闲的玩家哦~~~")
    end
end

function ClubInviteLayer:refreshInviteClubName(club_name)
    local tInviteClubName = ccui.Helper:seekWidgetByName(self.node, "tInviteClubName")
    self.club_name        = club_name
    tInviteClubName:setString(self.club_name)
end

return ClubInviteLayer