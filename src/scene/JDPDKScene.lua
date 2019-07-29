local watcher_lab_pos = {
    [1] = cc.p(g_visible_size.width / 2 - 200, g_visible_size.height / 2.26),
    [2] = cc.p(g_visible_size.width - 95, g_visible_size.height - 126),
    [3] = cc.p(400, g_visible_size.height - 126),
}

local baoting_pos = {
    [2] = cc.p(g_visible_size.width - 150, g_visible_size.height - 270),
    [3] = cc.p(150, g_visible_size.height - 260),
}

local hand_card_pos = {
    [1] = cc.p((g_visible_size.width - 20 * 50 - 25) / 2, 103),
    [2] = cc.p(g_visible_size.width - 160, g_visible_size.height - 145),
    [3] = cc.p(160, g_visible_size.height - 145),
}

local out_card_pos = {
    [1] = cc.p(g_visible_size.width * 0.5, 400),
    [2] = cc.p(g_visible_size.width - 350, g_visible_size.height - 180),
    [3] = cc.p(230, g_visible_size.height - 180),
}

local hand_card_scale = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
}
-- 手牌间距
local handMarginX = 55
-- 手牌宽度（cardWidth * scale）
local handCardWidth = 108
-- 出牌间距
local outMarginX = 35
-- 出牌宽度
local outCarWidth = 85

local img_pdkbg = {
    "ui/dt_ddz_play/dt_ddz_play_bg.png",
    "ui/dt_ddz_play/de_ddz_play_bg3.jpg",
    "ui/dt_ddz_play/dt_ddz_play_bg_2.jpg"
}
local qie_card_pos   = cc.p(g_visible_size.width * 0.5 - 200, g_visible_size.height - 160)
local qie_card_width = 80
local qie_card_scale = 1

if g_channel_id == 800001 then
    qie_card_width = 90
    qie_card_scale = 0.8
end

local PDKLogic       = require("logic.JDPDKLogic")
local ErrStrToClient = require('common.ErrStrToClient')
local ErrNo          = require('common.ErrNo')

local PDKScene = class("PDKScene", function()
    return cc.Layer:create()
end)

function PDKScene.create(param_list)
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()

    local mj    = PDKScene.new()
    mj.my_index = param_list.room_info.index
    mj.desk     = param_list.room_id
    mj.club_id  = param_list.club_id
    -- 屏蔽互动表情的方位
    mj.ignoreArr = {}

    if param_list.is_playback then
        mj.is_playback = param_list.is_playback
        mj.order_list  = param_list.order
        mj.log_data_id = param_list.log_data_id
        mj.create_time = param_list.create_time
    end

    mj.club_id = param_list.room_info.club_id
    mj.room_id = param_list.room_id
    gt.setRoomID(mj.room_id)
    mj.club_name  = param_list.room_info.club_name
    mj.room_info  = param_list.room_info
    mj.club_index = param_list.room_info.club_index
    mj.isJZBQ     = param_list.room_info.isJZBQ

    if mj.club_id and mj.club_name and mj.club_index then
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = mj.club_id
        gt.setClubID(mj.club_id)
    end

    mj:createLayerMenu(param_list.room_info)
    mj:runAction(cc.CallFunc:create(function()
        AudioManager:stopPubBgMusic()
        if g_channel_id == 800002 then
            AudioManager:playDWCBgMusic("sound/ddz_bgplay.mp3")
        end
    end))

    local scene = cc.Scene:create()
    scene:addChild(mj)
    return scene
end

function PDKScene:onRcvGameMsg()
    local msg = GameController:getModel():getGameMsg()
    if #msg > 0 then
        for i, _ in ipairs(msg) do
            local rtn_msg = msg[i]
            self:onRcvMsg(rtn_msg)
        end
        GameController:getModel():reset()
    end
end

function PDKScene:ctor()
    self:enableNodeEvents()
end

function PDKScene.removeUnusedRes()
    gt.removeUnusedRes()
end

function PDKScene:onEnter()
    PDKScene.removeUnusedRes()

    gt.refreshSignal(self.signalImg)
    gt.listenBatterySignal()
    gt.updateBatterySignal(self)

    local SpeekNode = require("scene.SpeekNode")
    self.speekNode  = SpeekNode:create(self)
    self:addChild(self.speekNode, 999)

    local RedBagLaba = require("modules.view.RedBagLaba")
    local laba       = RedBagLaba:create(self)
    self:addChild(laba, 999)
    -- 红包消息分发注册 EventBus
    self:registerEvent()

    self:onRcvGameMsg()
end

function PDKScene:onExit()
    self:disableNodeEvents()
    PDKScene.removeUnusedRes()
    -- 红包消息分发注销 EventBus
    self:unregisterEvent()

    gt.setRoomID(nil)
end

function PDKScene:registerEvent()
    local events = {
        {
            eType = EventEnum.S2C_RB_INFO,
            func  = handler(self, self.onRbIsValid),
        },
        {
            eType = EventEnum.onRcvGameMsg,
            func  = handler(self, self.onRcvGameMsg),
        },
    }
    for i, v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function PDKScene:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function PDKScene:onRbIsValid(rtn_msg)
    -- 应急处理，防止未收到20002消息 没有显示红包按钮
    if rtn_msg and nil ~= next(rtn_msg) then
        self.btnRedBag:setVisible(true)
    end
end

function PDKScene:keypadEvent()

    local function onKeyReleased(keyCode, event)
        if keyCode == cc.KeyCode.KEY_BACK then
            print("key rtn exit touch")
            local exit_node = cc.Director:getInstance():getRunningScene():getChildByTag(4532)
            if exit_node then
                exit_node:removeFromParent(true)
                return
            end
            commonlib.showExitTip("您确定要退出游戏？", function(is_ok)
                if is_ok then
                    cc.UserDefault:getInstance():setStringForKey("lan_can_sel", "false")
                    cc.UserDefault:getInstance():setStringForKey("mmmx1", "")
                    cc.UserDefault:getInstance():setStringForKey("mmmx2", "")
                    cc.UserDefault:getInstance():setStringForKey("s1s1s1", "")
                    cc.UserDefault:getInstance():setStringForKey("s2s2s2", "")
                    cc.UserDefault:getInstance():flush()
                    cc.Director:getInstance():endToLua()
                end
            end)
        elseif keyCode == cc.KeyCode.KEY_MENU then
            print("key menu exit touch")
        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    self.listenerKeyboard = listener
end

function PDKScene:registerNetCmd()
    -- local NETMSG_LISTENERS = {
    --     [NetCmd.S2C_BROAD]                = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_PDK_TABLE_USER_INFO]  = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_PDK_GAME_START]       = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_READY]                = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_PDK_OUT_CARD]         = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_PDK_RESULT]           = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_JIESAN]               = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_APPLY_JIESAN]         = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_APPLY_JIESAN_AGREE]   = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_ROOM_CHAT]            = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_ROOM_CHAT_BQ]         = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_LEAVE_ROOM]           = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_IN_LINE]              = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_OUT_LINE]             = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_SYNC_USER_DATA]       = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_SYNC_CLUB_NOTIFY]     = handler(self, self.onRcvMsg),
    --     [NetCmd.S2C_CLUB_MODIFY]          = handler(self, self.onRcvMsg),

    -- }
    -- for k, v in pairs(NETMSG_LISTENERS) do
    --     gt.addNetMsgListener(k, v)
    -- end
    local CUSTOM_LISTENERS = {
        ["interupt_resume"] = handler(self, self.onRcvMsg),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function PDKScene:onRcvMsg(rtn_msg)
    local NETMSG_LISTENERS = {
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_PDK_TABLE_USER_INFO] = handler(self, self.onRcvPDKTableUserInfo),
        [NetCmd.S2C_PDK_GAME_START]      = handler(self, self.onRcvPDKGameStart),
        [NetCmd.S2C_READY]               = handler(self, self.onRcvReady),
        [NetCmd.S2C_PDK_OUT_CARD]        = handler(self, self.onRcvPDKOutCard),
        [NetCmd.S2C_PDK_RESULT]          = handler(self, self.onRcvPDKResult),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJieSan),
        [NetCmd.S2C_APPLY_JIESAN]        = handler(self, self.onRcvApplyJieSan),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]  = handler(self, self.onRcvApplyJieSanAgree),
        [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvRoomChat),
        [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvRoomChatBQ),
        [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN] = handler(self, self.onRcvPDKJoinRoomAgain),
        [NetCmd.S2C_LEAVE_ROOM]          = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_IN_LINE]             = handler(self, self.onRcvInLine),
        [NetCmd.S2C_OUT_LINE]            = handler(self, self.onRcvOutLine),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSynUserData),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSynClubNotify),
        [NetCmd.S2C_CLUB_MODIFY]         = handler(self, self.onRcvClubNotify),
        ["interupt_resume"]              = handler(self, self.onRcvInteruptResume),
    }
    if NETMSG_LISTENERS[rtn_msg.cmd] then
        if rtn_msg.errno and rtn_msg.errno ~= 0 or rtn_msg.errorNo then
            if rtn_msg.errorNo and (rtn_msg.errorNo == 1 or rtn_msg.errorNo == 2 or rtn_msg.errorNo == 3) then
                if self.oper_panel then
                    self.oper_panel:setVisible(true)
                    self.oper_panel:setEnabled(true)
                end
                for i, v in ipairs(self.hand_card_list[1]) do
                    for cii, cid in ipairs(self.sel_list) do
                        if v.card_id == cid then
                            table.remove(self.sel_list, cii)
                            v:setPositionY(hand_card_pos[1].y)
                            break
                        end
                    end
                end
            end
            commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or 'Unknown Error ' .. rtn_msg.errno)
            if ErrNo.APPLY_JIESAN_TIME == rtn_msg.errno or ErrNo.APPLY_JIESAN_STATUS == rtn_msg.errno then
                commonlib.closeJiesan(self)
            end
        else
            NETMSG_LISTENERS[rtn_msg.cmd](rtn_msg)
        end
    end
end

function PDKScene:unregisterNetCmd()
    local LISTENER_NAMES = {
        -- [NetCmd.S2C_BROAD]                = handler(self, self.onRcvBroad),
        -- [NetCmd.S2C_PDK_TABLE_USER_INFO]  = handler(self, self.onRcvPDKTableUserInfo),
        -- [NetCmd.S2C_PDK_GAME_START]       = handler(self, self.onRcvPDKGameStart),
        -- [NetCmd.S2C_READY]                = handler(self, self.onRcvReady),
        -- [NetCmd.S2C_PDK_OUT_CARD]         = handler(self, self.onRcvPDKOutCard),
        -- [NetCmd.S2C_PDK_RESULT]           = handler(self, self.onRcvPDKResult),
        -- [NetCmd.S2C_JIESAN]               = handler(self, self.onRcvJieSan),
        -- [NetCmd.S2C_APPLY_JIESAN]         = handler(self, self.onRcvApplyJieSan),
        -- [NetCmd.S2C_APPLY_JIESAN_AGREE]   = handler(self, self.onRcvApplyJieSanAgree),
        -- [NetCmd.S2C_ROOM_CHAT]            = handler(self, self.onRcvRoomChat),
        -- [NetCmd.S2C_ROOM_CHAT_BQ]         = handler(self, self.onRcvRoomChatBQ),
        -- [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvPDKJoinRoomAgain),
        -- [NetCmd.S2C_LEAVE_ROOM]           = handler(self, self.onRcvLeaveRoom),
        -- [NetCmd.S2C_IN_LINE]              = handler(self, self.onRcvInLine),
        -- [NetCmd.S2C_OUT_LINE]             = handler(self, self.onRcvOutLine),
        -- [NetCmd.S2C_SYNC_USER_DATA]       = handler(self, self.onRcvSynUserData),
        -- [NetCmd.S2C_SYNC_CLUB_NOTIFY]     = handler(self, self.onRcvSynClubNotify),
        -- [NetCmd.S2C_CLUB_MODIFY]          = handler(self, self.onRcvClubNotify),
        ["interupt_resume"] = handler(self, self.onRcvInteruptResume),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function PDKScene:registerEventListener()

    self:registerNetCmd()
    self:keypadEvent()

    ymkj.GlobalData:getInstance():clear()

    ymkj.setHeartInter(3000)
    if self.is_playback then

        local function roundCheck()
            if self.order_list[1] then
                local delay_time       = 1.5
                self.order_list[1].cmd = self.order_list[1].cddm
                self:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), cc.CallFunc:create(function()
                    commonlib.echo(self.order_list[1])
                    self:onRcvMsg(self.order_list[1])
                    if self.order_list[1].cmd == NetCmd.S2C_PDK_RESULT then
                        self.order_list = {}
                    else
                        table.remove(self.order_list, 1)
                    end
                    roundCheck()
                end)))
            end
        end
        roundCheck()

        local pb_node = tolua.cast(cc.CSLoader:createNode("ui/HuiFang.csb"), "ccui.Widget")
        self:addChild(pb_node, 20000, 9876)
        pb_node:setContentSize(g_visible_size)
        ccui.Helper:doLayout(pb_node)

        pb_node.play_speed = 1
        ccui.Helper:seekWidgetByName(pb_node, "btn-rtn"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:unregisterEventListener()
                AudioManager:stopPubBgMusic()
                local scene     = require("scene.MainScene")
                local gameScene = scene.create()
                if cc.Director:getInstance():getRunningScene() then
                    cc.Director:getInstance():replaceScene(gameScene)
                else
                    cc.Director:getInstance():runWithScene(gameScene)
                end
            end
        end)

        pb_node.add_btn = ccui.Helper:seekWidgetByName(pb_node, "btn-add")
        pb_node.add_btn:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                pb_node.play_speed = pb_node.play_speed + 1
                if pb_node.play_speed == 5 then
                    pb_node.play_speed = 1
                end
                pb_node.add_btn:loadTextureNormal("ui/qj_replay/speed"..pb_node.play_speed..".png")
                pb_node.add_btn:loadTexturePressed("ui/qj_replay/speed"..pb_node.play_speed..".png")
                cc.Director:getInstance():getScheduler():setTimeScale(pb_node.play_speed)
            end
        end)

        pb_node.pause_btn = tolua.cast(ccui.Helper:seekWidgetByName(pb_node, "btn-pause"), "ccui.Button")
        pb_node.pause_btn:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if not pb_node.is_pause then
                    self:pause()
                    pb_node.pause_btn:loadTextureNormal("ui/qj_replay/dt_replay_play_btn_0.png")
                    pb_node.pause_btn:loadTexturePressed("ui/qj_replay/dt_replay_play_btn_1.png")
                else
                    self:resume()
                    pb_node.pause_btn:loadTextureNormal("ui/qj_replay/dt_replay_stop_btn_0.png")
                    pb_node.pause_btn:loadTexturePressed("ui/qj_replay/dt_replay_stop_btn_1.png")
                end
                pb_node.is_pause = not pb_node.is_pause
            end
        end)

    end
end

function PDKScene:unregisterEventListener()
    self:stopAllActions()
    self:unregisterNetCmd()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    ymkj.setHeartInter(0)

    GameController:unregisterEventListener()
end

function PDKScene:onRcvBroad(rtn_msg)
    if not rtn_msg.typ then
        commonlib.showTipDlg(rtn_msg.content or "系统提示")
    end
end

function PDKScene:onRcvPDKTableUserInfo(rtn_msg)
    local v     = rtn_msg
    local index = self:indexTrans(v.index)
    if self.player_ui[index] then
        local head = commonlib.wxHead(v.head)
        self.player_ui[index]:setVisible(true)
        self.player_ui[index].coin = v.score
        self.player_ui[index].user = {user_id = v.uid, sex = v.sex, photo = head, nickname = v.name, u_coin = v.score, ip = v.ip, lon = v.lon, lat = v.lat}
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name, 14))
        else
            tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(v.name)
        end
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.score + 1000))
        if index ~= 1 then
            commonlib.lixian(self.player_ui[index])
        end
        self.player_ui[index]:getChildByName("zhunbei"):setVisible(false)
        if head ~= "" then
            self.player_ui[index].head_sp:setVisible(true)
            self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
        else
            self.player_ui[index].head_sp:setVisible(false)
        end
        self:checkIpWarn()
        if self.is_qinyouquan and self.people_num == self:getNowPlayerNum() and not self.is_game_start then
            self.btnReady:setVisible(false)
            self.btnReady:setTouchEnabled(false)
            commonlib.showShareBtn(self.share_list)
            commonlib.showbtn(self.jiesanroom)
        end
    end
    RoomController:getModel():addPlayer(rtn_msg)
end

function PDKScene:onRcvPDKGameStart(rtn_msg)
    local result_node = self:getChildByTag(10109)
    if result_node then
        result_node:removeFromParent(true)
    end
    self.quan_lbl:setVisible(true)
    for i_ui, v_ui in ipairs(self.player_ui) do
        v_ui:getChildByName("zhunbei"):setVisible(false)
        if self.player_ui[i_ui].is_piaofen == 1 then
            v_ui:getChildByName("PFN"):setVisible(true)
        end
    end

    local num = 0
    for i, v in pairs(self.player_ui) do
        if v and v.user then
            num = num + 1
        end
    end
    INFO('实际玩家人数', num, '应到玩家人数', self.people_num)
    if num ~= self.people_num then
        gt.uploadErr('pdk start peopleNumErroJoinRoomAgain')
        self:peopleNumErroJoinRoomAgain()
        return
    end

    commonlib.showShareBtn(self.share_list)
    commonlib.showbtn(self.jiesan)
    commonlib.showbtn(self.jiesanroom)
    commonlib.showbtn(self.wanfa, 1)
    if not self.is_playback then
        ymkj.setHeartInter(0)
    end

    self.is_game_start = (rtn_msg.status ~= 0)
    self:disapperClubInvite()

    if not self.jushu then
        self:playKaiju()
    end

    for i, v in ipairs(self.wenhao_list) do
        v:setVisible(false)
    end

    for i, v in ipairs(self.hand_card_list) do
        for __, vv in ipairs(v) do
            if vv then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[i] = {}
    end

    if rtn_msg.cards and #rtn_msg.cards > 0 then
        PDKLogic:sortDESC(rtn_msg.cards)
        if self.people_num == 2 then
            if self.my_index == 1 then
                self:setSyps(2, #rtn_msg.cards)
            else
                self:setSyps(3, #rtn_msg.cards)
            end
        else
            self:setSyps(2, #rtn_msg.cards)
            self:setSyps(3, #rtn_msg.cards)
        end
    end

    self.my_cards = rtn_msg.cards

    local direct_list = {1, 2}
    if self.people_num == 3 then
        direct_list[3] = 3
    else
        if self.my_index == 2 then
            direct_list[2] = 3
        end
    end

    for _, k in ipairs(direct_list) do
        -- local index = self:indexTrans(i)
        -- self:setSypsVisible(index)
        local scal       = hand_card_scale[k]
        if k == 1 and self.isRetroCard then
            scal = 1.4
        end
        local pos_margin = handMarginX
        if k ~= 1 then
            pos_margin = 0
        end

        for i = 1, #rtn_msg.cards do
            self.hand_card_list[k][i] = self:getCardById(1, true)
            local curCard             = nil
            if k == 1 and rtn_msg.cards and rtn_msg.cards[i] then
                curCard                           = rtn_msg.cards[i]
                self.hand_card_list[k][i].card_id = curCard
            end
            self.hand_card_list[k][i]:setPosition(cc.p(g_visible_size.width * 0.5, g_visible_size.height * 0.5))
            self.node:addChild(self.hand_card_list[k][i], 999)
            local desPos = self:calHandCardPos(k, 16, i)
            self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.DelayTime:create(i * 0.075), cc.Show:create(), cc.CallFunc:create(function()
                AudioManager:playDWCSound("sound/m_sendcard.mp3")
            end), cc.Spawn:create(cc.ScaleTo:create(0.075, scal), cc.MoveTo:create(0.075, desPos)), cc.CallFunc:create(function()
                if k == 1 and curCard then
                    self.hand_card_list[k][i].card = self:getCardById(curCard)
                    self.hand_card_list[k][i].card:setPosition(cc.p(self.hand_card_list[k][i]:getContentSize().width / 2, self.hand_card_list[k][i]:getContentSize().height / 2))
                    self.hand_card_list[k][i]:addChild(self.hand_card_list[k][i].card)
                    self.hand_card_list[k][i].card:setVisible(false)

                    self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0), cc.CallFunc:create(function()
                        self.hand_card_list[k][i].card:setVisible(true)
                    end), cc.OrbitCamera:create(0, 1, 0, 0, 0, 0, 0)))
                    AudioManager:playDWCSound("sound/m_turncard.mp3")
                end
            end)))
        end
    end

    local index = self:indexTrans(rtn_msg.host_id)
    if index == 1 then
        local ht3 = nil
        -- 没有红三出其它三，没有三出四，
        if self.chu_san then
            -- 红桃三
            local target  = 0x23
            local isFirst = true
            while not ht3 do
                for __, v in ipairs(rtn_msg.cards) do
                    if v == target then
                        ht3 = v
                        break
                    end
                end
                -- 没有红桃三
                if not ht3 then
                    if target < 0x10 then
                        -- 没3进阶出4
                        target = target + 0x31
                    else
                        -- 梅花三
                        target = target - 0x10
                    end
                else
                    break
                end
                if not ht3 and isFirst then
                    -- 黑桃三
                    target  = 0x33
                    isFirst = false
                end
            end
            self.target = target
        end

        -- 必须出三
        if ht3 then
            self.mustChuSan = true
        end
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
        if index == 1 then
            self:resetOperPanel({0, 1}, rtn_msg.msgid)
        end
    end)))
    for ii = 1, 3 do
        self:setSyps(ii, #self.my_cards)
    end
    self:showWatcher(rtn_msg.time or 500, index)

    if self.total_ju == 1 and rtn_msg.log_ju_id then
        gt.addMissJuId(rtn_msg.log_ju_id)
    end
end

function PDKScene:onRcvReady(rtn_msg)
    local v     = rtn_msg
    local index = self:indexTrans(v.index)
    if self.player_ui[index] then
        self.player_ui[index].coin = v.score
        if self.player_ui[index].user then
            self.player_ui[index].user.u_coin = v.score
        end
        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
        if not v.piaoniao or v.piaoniao == 0 then
            self.player_ui[index].is_piaofen = 0
        else
            self.player_ui[index].is_piaofen = 1
            tolua.cast(self.player_ui[index]:getChildByName("PFN"), "ccui.ImageView"):loadTexture("ui/qj_pdk/piao"..v.piaoniao.."fen.png")
        end
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.score + 1000))
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function PDKScene:setSypsVisible(play_index, visible)
    local play = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "play"..play_index), "ccui.ImageView")
    if not play then
        return
    end
    local syps = play:getChildByName('syps')
    if not syps then
        return
    end
    syps:setVisible(visible)
end

function PDKScene:setSyps(play_index, left_num)
    logUp('[setSyps]')
    if not left_num then
        return
    end
    local play = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "play"..play_index), "ccui.ImageView")
    if not play then
        return
    end
    local syps = play:getChildByName('syps')
    if not syps then
        return
    end
    syps:setString(left_num)
    syps:setVisible(self.left_show == 1)
end

function PDKScene:getNextIndex(index)
    if self.people_num == 2 then
        if index == 2 then
            return self:indexTrans(1)
        else
            return self:indexTrans(2)
        end
    else
        if index == 1 then
            return self:indexTrans(2)
        elseif index == 2 then
            return self:indexTrans(3)
        else
            return self:indexTrans(1)
        end
    end
end

function PDKScene:onRcvPDKOutCard(rtn_msg)
    print('-------------------------------------')
    dump(rtn_msg)
    print('-------------------------------------')
    log('onRcvPDKOutCard')
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(false)
    self:resetData()
    local index = self:indexTrans(rtn_msg.index)
    self:setSyps(index, rtn_msg.left_num)

    local next_index = 0

    if rtn_msg.cur_user then
        if rtn_msg.cur_user >= 1 and rtn_msg.cur_user <= 3 then
            next_index = self:indexTrans(rtn_msg.cur_user)
        else
            rtn_msg.cur_user = 0
        end
    else
        next_index   = self:getNextIndex(rtn_msg.index)
        local errStr = string.format("rtn_msg.cur_user is nil ? = %s", json.encode(rtn_msg))
        log(errStr)
        gt.uploadErr(errStr)
    end

    if index == 1 then
        self:resetOperPanel({0, 0})
        for __, vv in ipairs(rtn_msg.out_card_data or {}) do
            for ii, kk in ipairs(self.my_cards) do
                if vv == kk then
                    table.remove(self.my_cards, ii)
                    break
                end
            end
        end
    end

    if not rtn_msg.out_card_data or #rtn_msg.out_card_data == 0 then
        self:showOutCardAni(0, index)
    else
        local card_typ = PDKLogic:GetCardType(rtn_msg.out_card_data, self.opts, false)
        local prefix   = self:getSoundPrefix(index)
        local fix      = ".mp3"
        if prefix == "women" then
            fix = "-0.mp3"
        end
        if card_typ == 12 then
            AudioManager:playDWCSound("sound/"..prefix.."/zhadan"..fix)
            self:playBombAni(index)
        elseif card_typ == 11 then
            AudioManager:playDWCSound("sound/"..prefix.."/sidaier"..fix)
        elseif card_typ == 8 or card_typ == 9 or card_typ == 10 then
            AudioManager:playDWCSound("sound/"..prefix.."/feiji"..fix)
            self:playFeiJiAni()
        elseif card_typ == 7 then
            AudioManager:playDWCSound("sound/"..prefix.."/sandaiyidui"..fix)
        elseif card_typ == 6 then
            AudioManager:playDWCSound("sound/"..prefix.."/sandaiyi"..fix)
        elseif card_typ == 5 then
            self:playLianduiAni(index)
            AudioManager:playDWCSound("sound/"..prefix.."/liandui"..fix)
        elseif card_typ == 4 then
            self:playShunziAni(index)
            AudioManager:playDWCSound("sound/"..prefix.."/shunzi"..fix)
        elseif card_typ == 3 then
            AudioManager:playDWCSound("sound/"..prefix.."/sange"..fix)
        elseif card_typ == 2 then
            local vl = rtn_msg.out_card_data[1] % 16 + 100
            if vl < 103 then
                vl = vl + 13
            end
            AudioManager:playDWCSound("sound/"..prefix.."/dui"..vl..fix)
        elseif card_typ == 1 then
            local vl = rtn_msg.out_card_data[1] % 16
            if rtn_msg.out_card_data[1] >= 78 then
                vl = vl + 2
            elseif vl < 3 then
                vl = vl + 13
            end
            AudioManager:playDWCSound("sound/"..prefix.."/"..vl..fix)
        end

        self.pre_out_direct = index
        if rtn_msg.baoting then
            self:showBaoTing(index)

            local prefix = self:getSoundPrefix(direct)
            AudioManager:playDWCSound("sound/ddz_music/"..prefix.. "/baojing.mp3")
        else
            AudioManager:playDWCSound("sound/m_sendcard.mp3")
        end
        local out_card   = {}
        local outCardNum = #rtn_msg.out_card_data
        if index == 1 then
            local myscal = 0.7
            if self.isRetroCard then
                myscal = 1
            end
            for ci, card_id in ipairs(rtn_msg.out_card_data) do
                for i, v in ipairs(self.hand_card_list[index]) do
                    if v.card_id == card_id then
                        out_card[#out_card + 1] = v
                        table.remove(self.hand_card_list[index], i)
                        local desPos = self:calOutCarPos(index, outCardNum, ci)
                        v:runAction(cc.Spawn:create(cc.ScaleTo:create(0.075, myscal), cc.MoveTo:create(0.075, desPos)))
                        v:setLocalZOrder(ci + 10)
                        break
                    end
                end
                for i, v in ipairs(self.sel_list) do
                    if v == card_id then
                        table.remove(self.sel_list, i)
                    end
                end
            end
            local handCardNum = #(self.hand_card_list[index])
            for i, v in ipairs(self.hand_card_list[index]) do
                local desPos = self:calHandCardPos(index, handCardNum, i)
                v:setPosition(desPos)
            end
        else
            if self.is_playback then
                local myscal = 0.7
                if self.isRetroCard then
                    myscal = 1
                end
                for ci, card_id in ipairs(rtn_msg.out_card_data) do
                    for i, v in ipairs(self.hand_card_list[index]) do
                        if v.card_id == card_id then
                            out_card[#out_card + 1] = v
                            table.remove(self.hand_card_list[index], i)
                            local desPos = self:calOutCarPos(index, outCardNum, ci)
                            v:runAction(cc.Spawn:create(cc.ScaleTo:create(0.075, myscal), cc.MoveTo:create(0.075, desPos)))
                            v:setLocalZOrder(ci + 100000)
                            break
                        end
                    end
                    for i, v in ipairs(self.sel_list) do
                        if v == card_id then
                            table.remove(self.sel_list, i)
                        end
                    end
                end
                local handCardNum = #(self.hand_card_list[index])
                for i, v in ipairs(self.hand_card_list[index]) do
                    local desPos = self:calOutCarPos(index, handCardNum, i, true)
                    v:setPosition(desPos)
                end
            else
                local otherScale = 0.5
                if self.isRetroCard then
                    otherScale = 0.8
                end
                for ci, card_id in ipairs(rtn_msg.out_card_data) do
                    local card              = self.hand_card_list[index][#self.hand_card_list[index]]
                    card.card_id            = card_id
                    out_card[#out_card + 1] = card
                    table.remove(self.hand_card_list[index], #self.hand_card_list[index])
                    card.card = self:getCardById(card_id)
                    card.card:setPosition(cc.p(card:getContentSize().width / 2, card:getContentSize().height / 2))
                    card:addChild(card.card)
                    card:setScale(otherScale)
                    local desPos = self:calOutCarPos(index, outCardNum, ci)
                    card:runAction(cc.Sequence:create(cc.MoveTo:create(0.05, desPos), cc.CallFunc:create(function ()
                        card:stopAllActions()
                    end)))
                    card:setLocalZOrder(ci)
                end
            end

            -- if rtn_msg.left_num == bj_num then
            --     local last_hand_card = self.hand_card_list[index]
            --     if last_hand_card and #last_hand_card >= 2 then
            --         last_hand_card = last_hand_card[#last_hand_card]
            --         if last_hand_card then
            --             if index == 2 then
            --                 last_hand_card:setPositionX(last_hand_card:getPositionX() - 20)
            --             else
            --                 last_hand_card:setPositionX(last_hand_card:getPositionX() + 20)
            --             end
            --         end
            --     end
            -- end
        end
        self.last_out_card[index] = out_card
    end

    if next_index ~= 0 and self.last_out_card[next_index] ~= 0 then
        for __, v in ipairs(self.last_out_card[next_index]) do
            v:removeFromParent(true)
        end
        self.last_out_card[next_index] = 0
    end

    if next_index ~= 0 and not self.is_playback then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function()
            if next_index == 1 then

                if self:canOutCard(true) then
                    self:sendOutCards(self:canOutCard(true), rtn_msg.msgid)
                end
                if self.pre_out_direct and next_index ~= self.pre_out_direct then
                    self:updateHintList()
                    self:resetOperPanel({1, 1}, rtn_msg.msgid)
                    self:showWatcher(rtn_msg.time or 500, next_index)
                else
                    self:resetOperPanel({0, 1}, rtn_msg.msgid)
                    self:showWatcher(rtn_msg.time or 500, next_index)
                end
            else
                self:showWatcher(rtn_msg.time or 500, next_index)
            end
        end)))
    end
end

function PDKScene:onRcvPDKResult(rtn_msg)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.CallFunc:create(function()
        if self.baoting_img then
            for __, v in pairs(self.baoting_img) do
                v:removeFromParent(true)
            end
            self.baoting_img = nil
        end

        self:setSypsVisible(2, false)
        self:setSypsVisible(3, false)

        if self.js_node and rtn_msg.jiesan_detail then
            self.js_node:removeFromParent(true)
            self.js_node = nil
        end

        if g_channel_id == 800002 then
            AudioManager:stopPubBgMusic()
        end

        local msg = {}
        for i, v in ipairs(rtn_msg.players) do
            local index = self:indexTrans(v.index)
            if index == 1 then
                if v.score >= 0 then
                    AudioManager:playDWCSound("sound/win.mp3")
                    self:playWinAni()
                else
                    AudioManager:playDWCSound("sound/lose.mp3")
                end
            end
            msg[index] = v.hands
        end

        if rtn_msg.chuntian == 1 or rtn_msg.chuntian == true then
            self:playSpringAni()
        end

        if #msg < 3 then
            msg[3] = {index = 3, cards = rtn_msg.ai_cards or {}}
        end
        self:showLeftHandCard(msg)

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
            self:initResultUI(rtn_msg)
        end)))

    end)))
end

function PDKScene:onRcvJieSan(rtn_msg)
    self:unregisterEventListener()
    AudioManager:stopPubBgMusic()
    if self.is_fangzhu then
        commonlib.showTipDlg("游戏未开始，解散包厢将不会扣除房卡", function(is_ok)
            if is_ok then
                local scene     = require("scene.MainScene")
                local gameScene = scene.create()
                if cc.Director:getInstance():getRunningScene() then
                    cc.Director:getInstance():replaceScene(gameScene)
                else
                    cc.Director:getInstance():runWithScene(gameScene)
                end
            end
        end, 1)
    else
        if self.ownername then
            commonlib.showTipDlg("房间已被 " .. self.ownername .. " 解散,请重新加入游戏", function(is_ok)
                if is_ok then
                    local scene     = require("scene.MainScene")
                    local gameScene = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                end
            end, 1)
        else
            local scene     = require("scene.MainScene")
            local gameScene = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end
end

function PDKScene:onRcvApplyJieSan(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, self.people_num)
end

function PDKScene:onRcvApplyJieSanAgree(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, self.people_num)
end

function PDKScene:onRcvRoomChat(rtn_msg)
    if rtn_msg.msg_type == 3 then
        EventBus:dispatchEvent(EventEnum.onRcvSpeek, rtn_msg)
    else
        EventBus:dispatchEvent(EventEnum.onPokerSound, rtn_msg)
    end
end

function PDKScene:onRcvRoomChatBQ(rtn_msg)
    if (not rtn_msg.index) or (not rtn_msg.to_index) then return end
    local index   = self:indexTrans(rtn_msg.index)
    local toindex = self:indexTrans(rtn_msg.to_index)
    if (not self.player_ui[index]) or (not self.player_ui[toindex]) then return end
    if self.my_index ~= rtn_msg.index and (self.ignoreArr[self.my_index] or self.ignoreArr[rtn_msg.index]) then return end
    commonlib.runInteractiveEffecttwo(self, self.player_ui[index], self.player_ui[toindex], rtn_msg.msg_id, toindex)
end

function PDKScene:onRcvPDKJoinRoomAgain(rtn_msg)
    self:unregisterEvent()
    self:unregisterEventListener()
    AudioManager:stopPubBgMusic()
    if (not rtn_msg.errno or rtn_msg.errno == 0) and rtn_msg.room_id ~= 0 then
        GameController:registerEventListener()
        local PDKScene = require("scene.PDKScene")
        cc.Director:getInstance():replaceScene(PDKScene.create(rtn_msg))
    else
        local scene     = require("scene.MainScene")
        local gameScene = scene.create()
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end
        gameScene:runAction(cc.CallFunc:create(function()
            commonlib.showLocalTip("您的房间已经结束或解散了")
        end))
    end
end

function PDKScene:onRcvLeaveRoom(rtn_msg)
    self:setClubInvite()
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 then
        if self.player_ui[index] then
            commonlib.lixian(self.player_ui[index])
            self.player_ui[index]:setVisible(false)
            self.player_ui[index].coin = nil
            self.player_ui[index].user = nil
            self.player_ui[index].ver  = nil
            local ipui                 = self:getChildByTag(81000 + index)
            if ipui then
                ipui:removeFromParent(true)
            end
            self:checkIpWarn()
            if self.is_qinyouquan then
                self.btnReady:setVisible(false)
                self.btnReady:setTouchEnabled(false)
                for i, v in ipairs(self.share_list) do
                    v:setVisible(true)
                    v:setTouchEnabled(true)
                end
                if self.panel_piaofen:isVisible() then
                    self.panel_piaofen:setVisible(false)
                    self.panel_piaofen:setEnabled(false)
                end
                self.jiesanroom:setVisible(true)
                self.jiesanroom:setTouchEnabled(true)
                for i, play in ipairs(self.player_ui) do
                    play:getChildByName("zhunbei"):setVisible(false)
                end
            end
        end
    else
        self:unregisterEventListener()
        AudioManager:stopPubBgMusic()
        local scene     = require("scene.MainScene")
        local gameScene = scene.create({operType = rtn_msg.operType})
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end
    end
end

function PDKScene:onRcvInLine(rtn_msg)
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index])
    end
end

function PDKScene:onRcvOutLine(rtn_msg)
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index], "zhunbei")
    end
end

function PDKScene:onRcvSynUserData(rtn_msg)
    if rtn_msg.key == "card" then
        local profile = ProfileManager.GetProfile()
        if profile then
            profile.card = rtn_msg.value
        end
    elseif rtn_msg.key == "score" then
        local profile = ProfileManager.GetProfile()
        if profile then
            profile.score = rtn_msg.value
        end
    end
end

function PDKScene:onRcvSynClubNotify(rtn_msg)
    if not rtn_msg.errno or rtn_msg.errno == 0 then
        if rtn_msg.club_info then
            if rtn_msg.tag == 1 then
                commonlib.showLocalTip(string.format("%s同意了你的亲友圈申请", rtn_msg.club_info.club_name))
            elseif rtn_msg.tag == 2 then
                commonlib.showLocalTip(string.format("%s拒绝了你的申请,加入亲友圈失败", rtn_msg.club_info.club_name))
            elseif rtn_msg.tag == 3 then
                commonlib.showLocalTip(string.format("您被 '%s' 管理员踢出了亲友圈!", rtn_msg.club_info.club_name))
            end
        end
        if rtn_msg.tag == 5 then
            clubAgentBindMsg = clone(rtn_msg)
        end
    end
end

function PDKScene:onRcvClubNotify(rtn_msg)
    self:clubRename(rtn_msg)
end

function PDKScene:onRcvInteruptResume(rtn_msg)
    if not self.is_playback then
        local net_msg = {
            cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
            room_id = self.desk,
        }
        ymkj.SendData:send(json.encode(net_msg))
    end
end

function PDKScene:sendReady(num)
    if self.is_playback then
        return
    end

    local input_msg = {
        cmd = NetCmd.C2S_READY,
    }

    if num then
        input_msg.piaoniao = num
    end

    ymkj.SendData:send(json.encode(input_msg))
    self.btnReady:setVisible(false)
    self.btnReady:setTouchEnabled(false)
end

function PDKScene:calHandCardNumPos(player, index)
    local playerPosX     = player:getPositionX()
    local playerPosY     = player:getPositionY()
    local handCardNumPos = nil
    handCardNumPosX      = hand_card_pos[index].x - playerPosX
    handCardNumPosY      = hand_card_pos[index].y - playerPosY
    handCardNumPosX      = handCardNumPosX + 42
    handCardNumPosY      = handCardNumPosY + 48
    return cc.p(handCardNumPosX, handCardNumPosY)
end

-- 计算手牌位置
function PDKScene:calHandCardPos(playerIndex, totalNum, cardIndex)
    local posX = hand_card_pos[playerIndex].x
    local posY = hand_card_pos[playerIndex].y
    if 1 == playerIndex then
        local totalCardWidth = handMarginX * (totalNum - 1) + handCardWidth
        local iniPosX        = (g_visible_size.width - totalCardWidth) / 2
        posX                 = iniPosX + (cardIndex - 1) * handMarginX + handCardWidth / 2
    end
    local desPos = cc.p(posX, posY)
    return desPos
end

-- 计算出牌位置
function PDKScene:calOutCarPos(playerIndex, totalNum, cardIndex, is_playback)
    local posX           = out_card_pos[playerIndex].y
    local posY           = out_card_pos[playerIndex].y
    local totalCardWidth = outMarginX * (totalNum - 1) + outCarWidth
    local iniPosX        = 0
    if 1 == playerIndex then
        iniPosX = (g_visible_size.width - totalCardWidth) / 2
        posX    = iniPosX + (cardIndex - 1) * outMarginX * 1.25 + outCarWidth / 2
    elseif 2 == playerIndex then
        if totalNum >= 9 then
            if cardIndex <= 10 then
                totalCardWidth = outMarginX * (10 - 1) + outCarWidth
            else
                cardIndex      = cardIndex - 10
                totalNum       = totalNum - 10
                totalCardWidth = outMarginX * (totalNum - 1) + outCarWidth
                posY           = posY - outCarWidth * 0.5 - 10
            end
            iniPosX = out_card_pos[playerIndex].x - totalCardWidth + outCarWidth + outCarWidth * 0.6
        else
            iniPosX = out_card_pos[playerIndex].x - totalCardWidth + outCarWidth
        end

        if not is_playback then
            posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2
        else
            posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2 + 100
        end
    elseif 3 == playerIndex then
        if totalNum >= 9 then
            if cardIndex <= 10 then
                totalCardWidth = outMarginX * (10 - 1) + outCarWidth
            else
                cardIndex      = cardIndex - 10
                totalNum       = totalNum - 10
                totalCardWidth = outMarginX * (totalNum - 1) + outCarWidth
                posY           = posY - outCarWidth * 0.5 - 10
            end
            iniPosX = out_card_pos[playerIndex].x - outCarWidth * 0.6
        else
            iniPosX = out_card_pos[playerIndex].x
        end
        if not is_playback then
            posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2
        else
            posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2 - 80
        end
    end
    local desPos = cc.p(posX, posY)
    return desPos
end

function PDKScene:getNowPlayerNum()
    local count = 0
    for i, v in ipairs(self.player_ui) do
        if v.user then
            count = count + 1
        end
    end
    return count
end

function PDKScene:setPiaoNiaoNum(rtn_msg)
    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i + 1] = v
    end

    for i, v in ipairs(playerinfo_list) do
        local idx = self:indexTrans(v.index)
        if v.piaoniao and v.piaoniao ~= 0 then
            self.player_ui[idx].is_piaofen = 1
            self.player_ui[idx]:getChildByName("PFN"):loadTexture("ui/qj_pdk/piao"..v.piaoniao.."fen.png")
        end
    end
end

function PDKScene:treatResume(rtn_msg)

    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(false)

    self.quan_lbl:setVisible(true)
    local msg = {out_index = rtn_msg.last_id, next_index = rtn_msg.cur_id, status = self.is_game_start,
        out_cards = rtn_msg.last_out_card, }

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i + 1] = v
    end

    if self.is_game_start then
        for i, v in ipairs(self.wenhao_list) do
            v:setVisible(false)
        end
        if not self.is_playback then
            local cardNum = 16
            if self.people_num == 2 then
                if self.my_index == 1 then
                    self:setSyps(2, cardNum)
                else
                    self:setSyps(3, cardNum)
                end
            else
                self:setSyps(2, cardNum)
                self:setSyps(3, cardNum)
            end
        end
    end

    local has_hand_card = (rtn_msg.player_info.hand and #rtn_msg.player_info.hand > 0)
    msg.players         = {}
    for i, v in ipairs(playerinfo_list) do
        v.hand         = v.hand or v.cards
        msg.players[i] = {index = v.index, cards = v.hand, }
        if v.hand then
            msg.players[i].num = #v.hand
        elseif rtn_msg.result_packet or not has_hand_card then
            msg.players[i].num = 0
        else
            msg.players[i].num = 16
        end
        local idx   = self:indexTrans(v.index)
        local count = 16
        local scal
        local desPos
        if self.is_playback then
            if v.cards then
                count = #v.cards
                PDKLogic:sortDESC(v.cards)
            end

            if idx == 1 then
                if self.isRetroCard then
                    scal = 1.4
                else
                    scal = hand_card_scale[idx]
                end
            else
                scal = 0.5
            end
            for ii = 1, count do
                if idx == 1 then
                    desPos = self:calHandCardPos(idx, count, ii)
                else
                    desPos = self:calOutCarPos(idx, count, ii, true)
                end
                self.hand_card_list[idx][ii] = self:getCardById(1, true)
                self.hand_card_list[idx][ii]:setScale(scal)
                self.hand_card_list[idx][ii]:setPosition(desPos)
                self.node:addChild(self.hand_card_list[idx][ii], 999)
                if v.cards and v.cards[ii] then
                    self.hand_card_list[idx][ii].card    = self:getCardById(v.cards[ii])
                    self.hand_card_list[idx][ii].card_id = v.cards[ii]
                    self.hand_card_list[idx][ii].card:setPosition(cc.p(self.hand_card_list[idx][ii]:getContentSize().width / 2,
                                                                        self.hand_card_list[idx][ii]:getContentSize().height / 2))
                    self.hand_card_list[idx][ii]:addChild(self.hand_card_list[idx][ii].card)
                end
            end
        else
            if v.hand then
                count = #v.hand
                PDKLogic:sortDESC(v.hand)
            end
            scal = hand_card_scale[idx]
            if self.isRetroCard and idx == 1 then
                scal = 1.4
            end
            for ii = 1, count do
                desPos = self:calHandCardPos(idx, count, ii)

                self.hand_card_list[idx][ii] = self:getCardById(1, true)

                self.hand_card_list[idx][ii]:setScale(scal)
                self.hand_card_list[idx][ii]:setPosition(desPos)
                self.node:addChild(self.hand_card_list[idx][ii], 999)
                if v.hand and v.hand[ii] then
                    self.hand_card_list[idx][ii].card    = self:getCardById(v.hand[ii])
                    self.hand_card_list[idx][ii].card_id = v.hand[ii]
                    self.hand_card_list[idx][ii].card:setPosition(cc.p(self.hand_card_list[idx][ii]:getContentSize().width / 2,
                                                                        self.hand_card_list[idx][ii]:getContentSize().height / 2))
                    self.hand_card_list[idx][ii]:addChild(self.hand_card_list[idx][ii].card)
                end
            end
        end
        if v.baoting then
            self:showBaoTing(idx)
        end

        self:setSyps(idx, v.left_num)

        if self.player_ui[idx] then
            if v.piaoniao and v.piaoniao ~= 0 then
                self.player_ui[idx]:getChildByName("PFN"):setVisible(true)
                tolua.cast(self.player_ui[idx]:getChildByName("PFN"), "ccui.ImageView"):loadTexture("ui/qj_pdk/piao"..v.piaoniao.."fen.png")
            end
        end
    end

    self.my_cards = rtn_msg.player_info.hand or {}

    if rtn_msg.last_id then
        self.pre_out_direct = self:indexTrans(rtn_msg.last_id)
    end
    local next_index = 0
    if rtn_msg.cur_id and rtn_msg.cur_id >= 1 and rtn_msg.cur_id <= 3 then
        next_index = self:indexTrans(rtn_msg.cur_id)
    end

    if type(rtn_msg.last_out_card) == "string" then
        if rtn_msg.last_out_card ~= "" then
            rtn_msg.last_out_card = ymkj.base64Decode(rtn_msg.last_out_card)
            rtn_msg.last_out_card = string.split(rtn_msg.last_out_card, "|")
            for ii, mm in ipairs(rtn_msg.last_out_card) do
                rtn_msg.last_out_card[ii] = 80 + ii * 2 - string.byte(mm)
            end
        else
            rtn_msg.last_out_card = {}
        end
    end

    if rtn_msg.last_out_card and rtn_msg.last_id ~= rtn_msg.cur_id then
        local last_out_card = rtn_msg.last_out_card
        for __, v in pairs(last_out_card) do
            if type(v) ~= "table" then
                last_out_card = {[rtn_msg.last_id] = rtn_msg.last_out_card}
                break
            end
        end
        for i, v in pairs(last_out_card) do
            local dir = self:indexTrans(i)
            if dir ~= next_index then
                local out_card   = {}
                local outCardNum = #v
                for ci, vv in ipairs(v) do
                    local card              = self:getCardById(1, true)
                    card.card_id            = vv
                    out_card[#out_card + 1] = card
                    card.card               = self:getCardById(vv)
                    card.card:setPosition(cc.p(card:getContentSize().width / 2, card:getContentSize().height / 2))
                    card:addChild(card.card)
                    self:addChild(card, 100)
                    if dir == 1 then
                        if self.isRetroCard then
                            card:setScale(1)
                        else
                            card:setScale(0.7)
                        end
                    else
                        if self.isRetroCard then
                            card:setScale(0.8)
                        else
                            card:setScale(0.5)
                        end
                    end
                    local desPos = self:calOutCarPos(dir, outCardNum, ci)
                    card:setPosition(desPos)
                end
                self.last_out_card[dir] = out_card
            end
        end
    end

    if next_index > 0 then
        if next_index == 1 then
            local ht3 = nil
            local num = 16

            if self.chu_san and rtn_msg.player_info.hand and #rtn_msg.player_info.hand >= num then
                local target  = 35
                local isFirst = true
                while not ht3 do
                    for __, v in ipairs(rtn_msg.player_info.hand) do
                        if v == target then
                            ht3 = v
                            break
                        end
                    end
                    if not ht3 then
                        if target < 16 then
                            target = target + 49
                        else
                            target = target - 16
                        end
                    else
                        break
                    end
                    if not ht3 and isFirst then
                        target  = 51
                        isFirst = false
                    end
                end
                self.target = target
            end
            if self:canOutCard(true) then
                self:sendOutCards(self:canOutCard(true), rtn_msg.player_info.msgid)
            end
            if self.pre_out_direct and next_index ~= self.pre_out_direct then
                self:updateHintList()
                self:resetOperPanel({1, 1}, rtn_msg.player_info.msgid)
                self:showWatcher(rtn_msg.time or 500, next_index)
            else
                if ht3 then
                    self.mustChuSan = true
                end
                self:resetOperPanel({0, 1}, rtn_msg.player_info.msgid)
                self:showWatcher(rtn_msg.time or 500, next_index)
            end
        else
            self:showWatcher(rtn_msg.time or 500, next_index)
        end

    end

    if rtn_msg.result_packet then

        if self.baoting_img then
            for __, v in pairs(self.baoting_img) do
                v:removeFromParent(true)
            end
            self.baoting_img = nil
        end

        local msg_result = {}
        for i, v in ipairs(rtn_msg.result_packet.players) do
            local index = self:indexTrans(v.index)
            if index == 1 then
                if v.score > 0 then
                    AudioManager:playDWCSound("sound/win.mp3")
                else
                    AudioManager:playDWCSound("sound/lose.mp3")
                end
            end
            msg_result[i] = {index = v.index, cards = v.hands}
        end

        if #msg_result < 3 then
            msg_result[3] = {index = 3, cards = rtn_msg.result_packet.ai_cards or {}}
        end

        -- self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        for __, v in ipairs(playerinfo_list) do
            local index = self:indexTrans(v.index)
            if self.player_ui[index] then
                if v.ready then
                    self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
                end
            end
        end
        if g_channel_id == 800002 then
            AudioManager:stopPubBgMusic()
        end
        self:initResultUI(rtn_msg.result_packet)
        -- end)))

    end
end

function PDKScene:showBaoTing(direct)
    if direct == 1 then return end
    self.baoting_img = self.baoting_img or {}

    local sp = cc.Sprite:create("ddz/jingbaodeng1.png")
    sp:setPosition(baoting_pos[direct])
    self:addChild(sp)
    sp:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.8), cc.DelayTime:create(0.5), cc.FadeOut:create(0.3))))

    self.baoting_img[direct] = sp
end

function PDKScene:showNextBaoTing()
    local tips = cc.Sprite:create("ui/qj_majiang/dt/baodan.png")
    tips:setPosition(cc.p(g_visible_size.width / 2, 230))
    self:addChild(tips, 9999)
    tips:setOpacity(0)
    tips:runAction(cc.Sequence:create(cc.FadeIn:create(0.2), cc.DelayTime:create(3), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
        tips:removeFromParent(true)
    end)))
end

function PDKScene:indexTrans(index)
    if index == self.my_index then
        return 1
    end
    if index > self.my_index then
        return index - self.my_index + 1
    end
    if index < self.my_index then
        return index - self.my_index + 4
    end
end

function PDKScene:sendOutCards(cards, msgid)
    logUp("sendOutCards")
    if not cards then
        local input_msg = {
            {cmd = NetCmd.C2S_PDK_OUT_CARD},
        }
        if msgid then
            input_msg[#input_msg + 1] = {msgid = msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    else
        local input_msg = {
            {cmd       = NetCmd.C2S_PDK_OUT_CARD},
            {card_data = cards},
        }
        if msgid or self.oper_panel.msgid then
            input_msg[#input_msg + 1] = {msgid = msgid or self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    end
    self.oper_panel.msgid = nil
    self.chooseResult     = {}
end

function PDKScene:showOutCardAni(typ, direct)
    if typ == 0 then
        local prefix = self:getSoundPrefix(direct)
        AudioManager:playDWCSound("sound/"..prefix.. "/yaobuqi.mp3")

        local sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_noout.png")
        if direct == 1 then
            sp:setPosition(cc.p(out_card_pos[direct].x, out_card_pos[direct].y - 60))
        elseif direct == 2 then
            sp:setPosition(cc.p(out_card_pos[direct].x, out_card_pos[direct].y))
        else
            sp:setPosition(cc.p(out_card_pos[direct].x + 90, out_card_pos[direct].y))
        end
        self:addChild(sp, 10000)

        sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(0.3), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
            sp:removeFromParent(true)
        end)))
    end
end

function PDKScene:getCardById(paramPokerId, showCardBack)
    if not showCardBack then
        local color = 3 - math.floor(paramPokerId / 16)
        if color > 3 or color < 0 then
            commonlib.showLocalTip("花色不正确")
            return
        end

        local value = paramPokerId % 16
        if value > 13 or value < 1 then
            commonlib.showLocalTip("牌值不正确")
            return
        end

        local colorImgName = "h"
        if color == 1 then
            colorImgName = "r"
        elseif color == 2 then
            colorImgName = "m"
        elseif color == 3 then
            colorImgName = "f"
        end
        if self.isRetroCard then
            return self:creteNewCard(color, value)
        end
        local card = cc.Sprite:create("poker/"..colorImgName..value..".png")
        return card
    else
        local card = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_otherCards.png")
        return card
    end
end

function PDKScene:showWatcher(time, direct)
    time = math.min(time, 15)
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(true)
    self.watcher_lab:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
        self.watcher_lab.lab:setString(string.format("%02d", time))
        if time <= 5 and time >= 3 then
            AudioManager:playDWCSound("sound/timeup_alarm.mp3")
        end
        if time <= 0 then
            self.watcher_lab:stopAllActions()
        end
        time = time - 1
    end), cc.DelayTime:create(1))))

    self.watcher_lab:setPosition(watcher_lab_pos[direct])
end

function PDKScene:createLayerMenu(room_info)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end

    self:setClubEnterMsg()

    local node = tolua.cast(cc.CSLoader:createNode("ui/pdkroom.csb"), "ccui.Widget")

    local bg_img = tolua.cast(ccui.Helper:seekWidgetByName(node, "Image_2"), "ccui.ImageView")
    self.desk_ys = cc.UserDefault:getInstance():getStringForKey("zhuozi", "1")

    self:addChild(node)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node

    self.batteryProgress = ccui.Helper:seekWidgetByName(node, "battery")
    gt.refreshBattery(self.batteryProgress)
    self.signalImg = ccui.Helper:seekWidgetByName(node, "img_xinhao")
    self.pkzhuobu  = gt.getLocal("int", "pkzhuobu", 1)
    local img_bg   = ccui.Helper:seekWidgetByName(node, "Image_2")
    img_bg:loadTexture(img_pdkbg[self.pkzhuobu])
    local logo = ccui.Helper:seekWidgetByName(node, "Image_47")
    logo:loadTexture("ui/qj_pdk/jdpdkLogo.png")
    logo:setContentSize(cc.size(320, 75))
    logo:setOpacity(50)
    self.wenhao_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(node, "wenhao1"), "ccui.ImageView"),
        tolua.cast(ccui.Helper:seekWidgetByName(node, "wenhao2"), "ccui.ImageView"),
        tolua.cast(ccui.Helper:seekWidgetByName(node, "wenhao3"), "ccui.ImageView"),
    }
    if room_info.people_num == 2 then
        if room_info.index == 1 then
            self.wenhao_list[3]:setVisible(false)
        else
            self.wenhao_list[2]:setVisible(false)
        end
    end

    -- 牌的类型 classic 为经典模式， retro 为复古模式
    local cardType = gt.getLocalString("cardType", "classic")
    if cardType == "retro" then
        self.isRetroCard = true
    end
    self:setOwnerName(room_info)

    self.btnReady = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-ready"), "ccui.Button")
    if self.btnReady then
        self.btnReady:addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    self:sendReady()
                end
            end
        )
    end

    self.btnReady:setVisible(false)
    self.btnReady:setTouchEnabled(false)

    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
    local XQLayer       = RedBagXQLayer:create({_scene = self, isMJ = false})
    self:addChild(XQLayer, 999)

    -- 红包按钮延时出现 防止收到消息未处理
    self.btnRedBag = ccui.Helper:seekWidgetByName(self.node, "btn_redbag")
    self.btnRedBag:setVisible(false)
    gt.performWithDelay(self.btnRedBag, function()
        self.btnRedBag:setVisible(RedBagController:getModel():getIsValid())
    end, 1.0)
    self.btnRedBag:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if nil == XQLayer then
                    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
                    local XQLayer       = RedBagXQLayer:create({_scene = self, isMJ = false})
                    self:addChild(XQLayer, 999)
                end
                XQLayer:setHbVisibale(true)
                XQLayer:reFreshHB()
            end
        end
    )

    local szBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-shezhi"), "ccui.Widget")
    if szBtn then
        szBtn:addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local SetLayer = require("scene.RoomSetingLayer")
                    if self.is_playback then
                        local SetLayer = require("scene.RoomSetingLayer")
                        self:addChild(SetLayer.create(self.is_game_start, self.is_fangzhu, true), 100000)
                    else
                        local SetLayer = require("scene.kit.SetDialog")
                        local function callbackPkCard(ys)
                            if ys then
                                local net_msg = {
                                    cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
                                    room_id = self.desk,
                                }
                                ymkj.SendData:send(json.encode(net_msg))
                            end
                        end
                        local shezhi = SetLayer.create(self, self.is_game_start, true, function (ys)
                            img_bg:loadTexture(img_pdkbg[ys - 10])
                        end,  nil, callbackPkCard)
                        self:addChild(shezhi, 100000)
                    end
                end
            end
        )
    end

    ccui.Helper:seekWidgetByName(node, "btn-gps"):addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:checkIpWarn(true)
            end
        end
    )
    ccui.Helper:seekWidgetByName(node, "btn-gps"):setVisible(false)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Widget")
    if backBtn then
        backBtn:setVisible(false)
    end

    local lt = ccui.Helper:seekWidgetByName(node, "btn-liaotian_0")
    if lt then
        lt:removeFromParent(true)
    end

    local btnFaYan = ccui.Helper:seekWidgetByName(node, "btn-fayan")
    self.btnFaYan  = btnFaYan
    self.btnFaYan:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local RoomMsgLayer = require("scene.RoomMsgLayer")
            self:addChild(RoomMsgLayer.create(nil, function()
            end), 100000)
        end
    end
    )
    local btnLiaoTian = ccui.Helper:seekWidgetByName(node, "btn-liaotian")
    btnLiaoTian:addTouchEventListener(function(sender, eventType)
        self.speekNode:touchEvent(sender, eventType)
    end
    )

    self.bigbq = tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_3"), "ccui.Widget")
    self.bigbq:setVisible(false)
    local btnWang = ccui.Helper:seekWidgetByName(node, "btn_wang")
    btnWang:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.bigbq:setVisible(not self.bigbq:isVisible())
        end
    end
    )

    local btnXiShou = ccui.Helper:seekWidgetByName(self.bigbq, "btn_xishou")
    btnXiShou:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.bigbq:setVisible(false)
            gt.playInteractiveSpine(self, "xishou")
            btnWang:setTouchEnabled(false)
            btnWang:setBright(false)
            self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function()
                btnWang:setTouchEnabled(true)
                btnWang:setBright(true)
            end)))
        end
    end
    )

    local btnShaoXiang = ccui.Helper:seekWidgetByName(self.bigbq, "btn_shaoxiang")
    btnShaoXiang:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.bigbq:setVisible(false)
            gt.playInteractiveSpine(self, "shaoxiang")
            btnWang:setTouchEnabled(false)
            btnWang:setBright(false)
            self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function()
                btnWang:setTouchEnabled(true)
                btnWang:setBright(true)
            end)))
        end
    end
    )
    self.btnjiesan = ccui.Helper:seekWidgetByName(node, "btn-jiesan")
    self.btnjiesan:setVisible(not ios_checking)
    self.btnjiesan:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.is_fangzhu then
                commonlib.showTipDlg("返回大厅包厢仍然保留，赶紧去邀请好友吧", function(is_ok)
                    if is_ok then
                        self:unregisterEventListener()
                        cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "true")
                        cc.UserDefault:getInstance():flush()
                        local scene     = require("scene.MainScene")
                        local gameScene = scene.create()
                        if cc.Director:getInstance():getRunningScene() then
                            cc.Director:getInstance():replaceScene(gameScene)
                        else
                            cc.Director:getInstance():runWithScene(gameScene)
                        end
                    end
                end)
            else
                commonlib.showTipDlg("返回大厅包厢将退出游戏，确定退出包厢吗？", function(is_ok)
                    if is_ok then
                        local input_msg = {
                            cmd = NetCmd.C2S_LEAVE_ROOM,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end)
            end
        end
    end)

    tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_2"), "ccui.Widget"):setLocalZOrder(1000)
    self.hand_card_list    = {}
    self.hand_card_list[1] = {}
    self.hand_card_list[2] = {}
    self.hand_card_list[3] = {}

    self.watcher_lab = tolua.cast(cc.CSLoader:createNode("ui/Biao.csb"), "ccui.Widget")
    self:addChild(self.watcher_lab, 100)
    self.watcher_lab:setVisible(false)
    self.watcher_lab.lab = tolua.cast(ccui.Helper:seekWidgetByName(self.watcher_lab, "Text_1"), "ccui.Text")
    self.watcher_lab.lab:setString("")

    self.player_ui = {}

    for play_index = 1, 3 do
        local play                 = tolua.cast(ccui.Helper:seekWidgetByName(node, "play"..play_index), "ccui.ImageView")
        self.player_ui[play_index] = play

        self.player_ui[play_index].head_sp = commonlib.stenHead(play:getChildByName("tx"), 1)

        play:setVisible(false)

        if play_index == 1 then
            play:setPosition(cc.p(self.wenhao_list[1]:getPosition()))
        elseif play_index == 2 then
            play:setPosition(cc.p(self.wenhao_list[2]:getPosition()))
        elseif play_index == 3 then
            play:setPosition(cc.p(self.wenhao_list[3]:getPosition()))
        end
        play:getChildByName("PFN"):setVisible(false)
        play:getChildByName("PFN"):setLocalZOrder(2)

        if play_index ~= 1 then
            play:getChildByName("lixian"):setVisible(false)
            play:getChildByName("lixian"):setLocalZOrder(1)

            play:getChildByName("zhunbei"):setVisible(false)
            play:getChildByName("zhunbei"):setLocalZOrder(2)

            play.left_lbl = ccui.Helper:seekWidgetByName(play, "syps")
            play.left_lbl:setVisible(false)
            if play.left_lbl then
                play.left_lbl:setString(0)
                play.left_lbl:setPosition(self:calHandCardNumPos(play, play_index))
            end
        else
            play:getChildByName("zhunbei"):setVisible(false)
        end

        play:getChildByName("Image_8"):setLocalZOrder(1)
        play:getChildByName("Text_2"):setLocalZOrder(1)
        play:getChildByName("Image_9"):setLocalZOrder(1)

        play:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                if self.player_ui[play_index].user then
                    AudioManager:playPressSound()
                    local svr_index = self.my_index + play_index - 1
                    if svr_index > 3 then
                        svr_index = svr_index - 3
                    end
                    local PlayerInfo = require("scene.PlayerInfo")
                    self:addChild(PlayerInfo.create(self.player_ui[play_index].user, svr_index, play_index == 1, self.ignoreArr, self), 100000)
                end
            end
        end)
    end

    self.panel_piaofen = tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_piaofen"), "ccui.Widget")
    self.panel_piaofen:setVisible(false)

    ccui.Helper:seekWidgetByName(self.panel_piaofen, "btn0"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:sendReady(0)
            self.panel_piaofen:setVisible(false)
            self.panel_piaofen:setEnabled(false)
        end
    end)

    ccui.Helper:seekWidgetByName(self.panel_piaofen, "btn2"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:sendReady(2)
            self.panel_piaofen:setVisible(false)
            self.panel_piaofen:setEnabled(false)
        end
    end)

    ccui.Helper:seekWidgetByName(self.panel_piaofen, "btn5"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:sendReady(5)
            self.panel_piaofen:setVisible(false)
            self.panel_piaofen:setEnabled(false)
        end
    end)

    ccui.Helper:seekWidgetByName(self.panel_piaofen, "btn8"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:sendReady(8)
            self.panel_piaofen:setVisible(false)
            self.panel_piaofen:setEnabled(false)
        end
    end)

    self.oper_panel = tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_caozuo"), "ccui.Widget")
    self.btnOutCard = ccui.Helper:seekWidgetByName(self.oper_panel, "btn-chupai")
    self.btnOutCard:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onBtnOutCardClicked()
        end
    end)

    ccui.Helper:seekWidgetByName(self.oper_panel, "btn-tishi"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onTiShiClicked()
        end
    end)

    self.oper_panel:setVisible(false)
    self.oper_panel:setEnabled(false)

    if self.is_playback then
        commonlib.showSysTime(tolua.cast(ccui.Helper:seekWidgetByName(node, "time"), "ccui.Text"), self.create_time)
    else
        local time = time or os.time()
        tolua.cast(ccui.Helper:seekWidgetByName(node, "time"), "ccui.Text"):setString(os.date("%H:%M", time))
        tolua.cast(ccui.Helper:seekWidgetByName(node, "time"), "ccui.Text"):runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            time = time + 1
            tolua.cast(ccui.Helper:seekWidgetByName(node, "time"), "ccui.Text"):setString(os.date("%H:%M", time))
        end))))
    end

    self.share_list = {ccui.Helper:seekWidgetByName(node, "WxShare"),
        ccui.Helper:seekWidgetByName(node, "btn-copyroom"),
        ccui.Helper:seekWidgetByName(node, "DdShare"),
        ccui.Helper:seekWidgetByName(node, "YxShare"),
    }
    tolua.cast(ccui.Helper:seekWidgetByName(node, "WxShare"), "ccui.Button")

    self.jiesan = ccui.Helper:seekWidgetByName(node, "btn-jiesan")
    self.jiesan:setVisible(not ios_checking)
    self.jiesan:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.is_fangzhu then
                commonlib.showTipDlg("返回大厅包厢仍然保留，赶紧去邀请好友吧", function(is_ok)
                    if is_ok then
                        self:unregisterEventListener()
                        cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "true")
                        cc.UserDefault:getInstance():flush()
                        local scene     = require("scene.MainScene")
                        local gameScene = scene.create()
                        if cc.Director:getInstance():getRunningScene() then
                            cc.Director:getInstance():replaceScene(gameScene)
                        else
                            cc.Director:getInstance():runWithScene(gameScene)
                        end
                    end
                end)
            else
                commonlib.showTipDlg("返回大厅包厢将退出游戏，确定退出包厢吗？", function(is_ok)
                    if is_ok then
                        local input_msg = {
                            cmd = NetCmd.C2S_LEAVE_ROOM,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end)
            end
        end
    end)

    self.jiesanroom = ccui.Helper:seekWidgetByName(node, "btn_jiesanroom")
    if ios_checking then
        self.jiesanroom:setPositionX(g_visible_size.width * 0.5)
    end
    self.jiesanroom:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
            cc.UserDefault:getInstance():flush()

            commonlib.sendJiesan(self.is_game_start, self.is_fangzhu)
        end
    end)
    self.wanfa = ccui.Helper:seekWidgetByName(node, "btn_wanfa")
    self.wanfa:setVisible(false)
    self.wanfa:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local HelpLayer = require("scene.kit.HelpDialog")
            local help      = HelpLayer.create(self, "pdk")
            help.is_in_main = true
            self:addChild(help, 100000)
        end
    end
    )

    if room_info.result_packet then
        room_info.cur_ju = room_info.result_packet.cur_ju or room_info.cur_ju or 1
    else
        room_info.cur_ju = room_info.cur_ju or 1
    end
    self.total_ju = room_info.total_ju
    self.cur_ju   = room_info.cur_ju
    self.quan_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "jushu"), "ccui.Text")
    self.quan_lbl:setVisible(false)
    if self.is_playback then
        self.quan_lbl:setString("第"..room_info.cur_ju.."局")
    else
        self.quan_lbl:setString("局数："..room_info.cur_ju.."/"..room_info.total_ju.."局")
    end

    self.is_game_start = (room_info.status ~= 0 or room_info.cur_ju ~= 1)
    self.is_fangzhu    = (room_info.qunzhu ~= 1 and self.my_index == 1)
    self.is_qinyouquan = (room_info.qunzhu == 4 or room_info.qunzhu == 3 or room_info.qunzhu == 1)

    self:setRoomData()

    local playerinfo_list = {room_info.player_info}
    for i, v in ipairs(room_info.other) do
        playerinfo_list[i + 1] = v
    end

    local need_ready = (room_info.status == 0 and not room_info.result_packet)
    for __, v in ipairs(playerinfo_list) do
        local index = self:indexTrans(v.index)
        if self.player_ui[index] then
            local head = commonlib.wxHead(v.head)
            self.player_ui[index]:setVisible(true)
            self.player_ui[index].coin = v.score
            self.player_ui[index].user = {user_id = v.uid, sex = v.sex, photo = head, nickname = v.name, u_coin = v.score, ip = v.ip, lon = v.lon, lat = v.lat}
            if pcall(commonlib.GetMaxLenString, v.name, 14) then
                tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name, 14))
            else
                tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(v.name)
            end
            tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.score + 1000))
            if index ~= 1 and v.out_line then
                if type(v.out_line) == "boolean" then v.out_line = 0 end
                commonlib.lixian(self.player_ui[index], "zhunbei", v.out_line)
            end
            if head ~= "" then
                self.player_ui[index].head_sp:setVisible(true)
                self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
            else
                self.player_ui[index].head_sp:setVisible(false)
            end
            if need_ready and v.ready then
                self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
            end
        end
    end
    self.next_direct = 2
    self.people_num  = room_info.people_num

    if room_info.people_num == 2 then
        playerinfo_list[#playerinfo_list + 1] = {index = 3, uid = 0, sex = 1}
        if self.my_index == 2 then
            self.next_direct = 3
        end
    end

    -- 是否要先出三
    self.chu_san = room_info.chu_san == 1
    -- 飘分
    self.piaofen = 0

    self.opts = {
        ["zddp"] = 2,
    }

    local str = room_info.people_num.."人玩."
    str       = str..room_info.total_ju.."局."

    if room_info.chu_san == 1 then
        str = str.."首出必带红桃3."
    end

    local room_type = nil
    if room_info.qunzhu == 1 then
        room_type = "(亲友圈房)."
    end
    room_type = room_type or ""
    str       = str..room_type

    self.left_show = room_info.left_show
    dump(room_info)

    self:setShuoMing(str)

    self.wanfa_str     = str
    self.sel_list      = {}
    self.last_out_card = {0, 0, 0}
    self.copy          = (room_info.copy == 1)
    self:setPiaoNiaoNum(room_info)
    if room_info.status ~= 0 then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:treatResume(room_info)
        end
    else
        if not room_info.player_info or not room_info.player_info.ready then
            self:checkIpWarn()
            if not self.piaofen or self.piaofen == 0 then
                self:sendReady()
            end
        end
    end
    if room_info.status ~= 0 or room_info.cur_ju > 1 then
        commonlib.showShareBtn(self.share_list)
        commonlib.showbtn(self.jiesan)
        commonlib.showbtn(self.jiesanroom)
        commonlib.showbtn(self.wanfa, 1)
        if not self.is_playback then
            ymkj.setHeartInter(0)
        end
    end

    self:registerEventListener()

    if self.is_playback then
        ccui.Helper:seekWidgetByName(node, "btn-gps"):setVisible(false)
        btnFaYan:setVisible(false)
        btnWang:setVisible(false)
        btnLiaoTian:setVisible(false)
    end
    if ios_checking then
        btnLiaoTian:setVisible(false)
    end

    tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-wanfa"), "ccui.Text"):setString(str)
    tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-wanfa"), "ccui.Text"):setVisible(false)

    self.share_content = "经典跑得快"..str
    self.share_title   = "包厢号:"..self.desk..g_game_name
    -- if ios_checking or g_author_game then
    --     commonlib.showShareBtn(self.share_list)
    --     commonlib.showbtn(self.jiesanroom)
    -- else
    commonlib.showShareBtn(self.share_list, self.share_content, self.share_title, self.desk, self.copy, function()
        local ren_cc = 0
        for i, v in ipairs(self.player_ui) do
            if v.user then
                ren_cc = ren_cc + 1
            end
        end
        return ren_cc.."缺" .. (self.people_num - ren_cc)
    end)
    -- end

    if not self.is_playback then

        local began_index = nil
        local ended_index = nil
        self:setTouchEnabled(true)
        self:registerScriptTouchHandler(function(touch_type, xx, yy)
            if touch_type == "began" then
                self.chooseResult = {}
                local pos         = cc.p(xx, yy)
                for i, v in ipairs(self.hand_card_list[1]) do
                    if v.card then
                        local p    = v.card:convertToNodeSpace(pos)
                        local s    = v.card:getContentSize()
                        local rect = cc.rect(0, 0, s.width, s.height)
                        if i ~= #self.hand_card_list[1] then
                            rect.width = handMarginX
                        end
                        if cc.rectContainsPoint(rect, p) then
                            local exist = nil
                            for cii, cid in ipairs(self.sel_list) do
                                if v.card_id == cid then
                                    exist = cii
                                    break
                                end
                            end
                            if not exist then
                                self.sel_list[#self.sel_list + 1] = v.card_id
                                v:setPositionY(hand_card_pos[1].y + 30)
                            else
                                table.remove(self.sel_list, exist)
                                v:setPositionY(hand_card_pos[1].y)
                            end
                            began_index = i
                            ended_index = i
                            self.btnOutCard:setTouchEnabled(false)
                            self.btnOutCard:setBright(false)
                            return true
                        end
                    end
                end
                for i, v in ipairs(self.hand_card_list[1]) do
                    for cii, cid in ipairs(self.sel_list) do
                        if v.card_id == cid then
                            table.remove(self.sel_list, cii)
                            v:setPositionY(hand_card_pos[1].y)
                            break
                        end
                    end
                end
                self.btnOutCard:setTouchEnabled(false)
                self.btnOutCard:setBright(false)
            elseif touch_type == "moved" then
                local pos       = cc.p(xx, yy)
                local var_begin = nil
                local var_end   = nil
                for i, v in ipairs(self.hand_card_list[1]) do
                    if v.card then
                        local p    = v.card:convertToNodeSpace(pos)
                        local s    = v.card:getContentSize()
                        local rect = cc.rect(0, 0, s.width, s.height)
                        if i ~= #self.hand_card_list[1] then
                            rect.width = handMarginX
                        end
                        if cc.rectContainsPoint(rect, p) then
                            if i < began_index then
                                var_begin   = i
                                var_end     = began_index - 1
                                began_index = i
                            elseif i ~= began_index and i ~= ended_index then
                                if i < ended_index then
                                    var_end   = ended_index
                                    var_begin = i + 1
                                else
                                    var_begin = ended_index + 1
                                    var_end   = i
                                end
                                ended_index = i
                            end
                            break
                        end
                    end
                end
                if var_begin and var_end then
                    for i = var_begin, var_end do
                        local exist    = nil
                        local v        = self.hand_card_list[1][i]
                        local cardList = {}
                        if v then
                            for cii, cid in ipairs(self.sel_list) do
                                if v.card_id == cid then
                                    exist = cii
                                    break
                                end
                            end
                            if not exist then
                                self.sel_list[#self.sel_list + 1] = v.card_id
                                cardList[#cardList + 1]           = v

                                -- 滑动手牌时选择能出牌型中牌数最多的牌型
                                self:chooseCardBySlide(v)
                            else
                                table.remove(self.sel_list, exist)
                                table.remove(self.chooseResult, exist)
                                table.remove(cardList, exist)
                                v:setPositionY(hand_card_pos[1].y)
                            end
                        end
                    end
                end
            else
                log(self:canOutCard())
                log(self:isMustChuCard())
                if self.chooseResult and #self.chooseResult > 0 then
                    self.sel_list = clone(self.chooseResult)
                end
                if self:canOutCard() and self:isMustChuCard() then
                    self.btnOutCard:setTouchEnabled(true)
                    self.btnOutCard:setBright(true)
                else
                    self.btnOutCard:setTouchEnabled(false)
                    self.btnOutCard:setBright(false)
                end
            end
        end)

    end

    if self.is_qinyouquan and self.people_num == self:getNowPlayerNum() and not self.is_game_start then
        self.btnReady:setVisible(false)
        self.btnReady:setTouchEnabled(false)
        commonlib.showShareBtn(self.share_list)
        commonlib.showbtn(self.jiesanroom)
    end

    self.qunzhu = room_info.qunzhu
    self:setClubInvite()
end

function PDKScene:getSoundPrefix(index)
    if not self.player_ui[index] then
        return "men"
    end

    if not self.player_ui[index].user then
        return "men"
    end

    if self.player_ui[index].user.sex ~= 2 then
        return "men"
    else
        return "men"
    end
end

function PDKScene:chooseCardBySlide(card)
    self.chooseResult = PDKLogic:SearchCanOutCards(self.sel_list, self.opts)
    local compareList = nil
    if self.chooseResult and #self.chooseResult > 0 then
        compareList = self.chooseResult
    else
        compareList = self.sel_list
    end
    local function isInSel(cardId)
        for i, v in ipairs(compareList) do
            if v == cardId then
                return true
            end
        end
        return false
    end

    for i, handCard in ipairs(self.hand_card_list[1]) do
        if isInSel(handCard.card_id) then
            handCard:setPositionY(hand_card_pos[1].y + 30)
        else
            handCard:setPositionY(hand_card_pos[1].y)
        end
    end
end

function PDKScene:onBtnOutCardClicked()
    local isChaiZhaDan = false
    if not self.sel_list or #self.sel_list < 0 then
        self:sendOutCards()
    else
        self:sendOutCards(self.sel_list)
    end
    self.oper_panel:setVisible(false)
    self.oper_panel:setEnabled(false)
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(false)
end

function PDKScene:updateHintList()
    local pre_card = self.last_out_card[3]
    if pre_card == 0 then
        pre_card = self.last_out_card[2]
    end
    local next_cards = {}
    for i, v in ipairs(self.hand_card_list[1]) do
        next_cards[i] = v.card_id
    end

    self.hint_list = {}
    self.cur_hint  = 0

    local is_last = false
    if PDKLogic:GetCardType(next_cards, self.opts, true) > 0 then
        is_last = true
    end

    if pre_card ~= 0 then
        local last_id_list = {}
        for __, pre in ipairs(pre_card) do
            last_id_list[#last_id_list + 1] = pre.card_id
        end
        PDKLogic:SearchOutCard(next_cards, last_id_list, self.hint_list, nil, self.opts, is_last)
    end
    if not self.hint_list or #self.hint_list == 0 then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
            self:sendOutCards()
            self.oper_panel:setVisible(false)
            self.watcher_lab:stopAllActions()
            self.watcher_lab:setVisible(false)
        end)))
    end
end

function PDKScene:onTiShiClicked()
    log('onTiShiClicked')
    local tishi_cards = nil
    log(self.hint_list)
    if self.hint_list and #self.hint_list > 0 then
        self.cur_hint = (self.cur_hint or 0) + 1
        if self.cur_hint > #self.hint_list then
            self.cur_hint = 1
        end
        tishi_cards = self.hint_list[self.cur_hint]
    end
    log(tishi_cards)
    if not tishi_cards or #tishi_cards <= 0 then
        self:sendOutCards()
        self.oper_panel:setVisible(false)
        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)
    else
        for __, v in ipairs(self.hand_card_list[1]) do
            for cii, cid in ipairs(self.sel_list) do
                if v.card_id == cid then
                    table.remove(self.sel_list, cii)
                    v:setPositionY(hand_card_pos[1].y)
                    break
                end
            end
            for __, cid in ipairs(tishi_cards) do
                if v.card_id == cid then
                    self.sel_list[#self.sel_list + 1] = cid
                    v:setPositionY(hand_card_pos[1].y + 30)
                    break
                end
            end
        end
        self.btnOutCard:setTouchEnabled(true)
        self.btnOutCard:setBright(true)
    end
end

function PDKScene:resetData()
    if self.mustChuSan then
        self.mustChuSan = nil
    end
end

-- 必须出牌
function PDKScene:isMustChuCard()
    -- 必须出指定牌
    if self.mustChuSan then
        if self.sel_list and #self.sel_list > 0 then
            for __, v in ipairs(self.sel_list) do
                if v == self.target then
                    return true
                end
            end
            return false
        else
            return false
        end
    end
    return true
end

function PDKScene:canOutCard(isAuto)
    -- 上家出的牌
    local pre_card = self.last_out_card[3]
    if pre_card == 0 then
        -- 上上家出的牌
        pre_card = self.last_out_card[2]
    end
    local is_last    = nil
    local next_cards = nil
    if isAuto then
        next_cards = {}
        for i, v in ipairs(self.hand_card_list[1]) do
            next_cards[i] = v.card_id
        end
        is_last = true
    else
        -- 选中的牌
        next_cards = clone(self.sel_list)
        self:sortCard(next_cards)
        local myCards = clone(self.my_cards)
        self:sortCard(myCards)
        -- 最后一手牌
        if self:deepcompare(next_cards, myCards) then
            is_last = true
        end
        if PDKLogic:GetCardType(myCards, self.opts, true) == PDKLogic.CT_THREE_LINE_TAKE then
            is_last = true
        end
    end

    local can = nil
    if pre_card ~= 0 then
        local last_id_list = {}
        for __, pre in ipairs(pre_card) do
            last_id_list[#last_id_list + 1] = pre.card_id
        end
        -- 是否能打起上家
        can = PDKLogic:CompareCard(last_id_list, next_cards, self.opts, is_last)
    else
        -- 是否能这样出牌
        can = PDKLogic:GetCardType(next_cards, self.opts, is_last) > 0
    end

    -- 能出牌
    if can then
        -- 自动出牌
        if isAuto then
            log('[isAuto]', isAuto)
            can = PDKLogic:GetCardType(next_cards, self.opts, is_last)
            PDKLogic:sortDESC(next_cards)
            -- 有炸弹不能自动出
            if self:hasBomb(next_cards) then
                return false
            end

            -- 四带二 11     四带三 13  -- 飞机少带
            if can == 11 or can == 13 or can == 9 then
                return false
            else
                return next_cards
            end
        else
            return next_cards
        end
    else
        return false
    end
end

function PDKScene:sortCard(t)
    table.sort(t, function(a, b)
        return a < b
    end)
end

function PDKScene:hasBomb(data)
    local count     = #data
    local fourCount = 0
    local i         = 1
    while i <= count do
        local sameCount  = 1
        local logicValue = PDKLogic:GetLogicValue(data[i])
        -- 搜索同牌
        for j = i + 1, count do
            -- 获取扑克
            if PDKLogic:GetLogicValue(data[j]) ~= logicValue then break end
            sameCount = sameCount + 1
        end
        -- 四张炸弹
        if sameCount == 4 then
            return true
        end
        i = i + sameCount
    end
    return false
end

function PDKScene:deepcompare(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    for k1, v1 in pairs(t1) do
        if k1 ~= ignore_mt then
            local v2 = t2[k1]
            if v2 == nil or not self:deepcompare(v1, v2) then return false end
        end
    end
    for k2, v2 in pairs(t2) do
        if k2 ~= ignore_mt then
            local v1 = t1[k2]
            if v1 == nil or not self:deepcompare(v1, v2) then return false end
        end
    end
    return true
end

function PDKScene:resetOperPanel(oper_list, msgid)

    self.oper_panel:setVisible(true)
    self.oper_panel:setEnabled(true)

    local has_oper = false
    -- 第1个是提示
    if oper_list[1] == 0 then
        ccui.Helper:seekWidgetByName(self.oper_panel, "btn-tishi"):setTouchEnabled(false)
        ccui.Helper:seekWidgetByName(self.oper_panel, "btn-tishi"):setBright(false)
    else
        ccui.Helper:seekWidgetByName(self.oper_panel, "btn-tishi"):setTouchEnabled(true)
        ccui.Helper:seekWidgetByName(self.oper_panel, "btn-tishi"):setBright(true)
        has_oper = true
    end

    -- 第2个是出牌
    if oper_list[2] == 0 then
        self.btnOutCard:setTouchEnabled(false)
        self.btnOutCard:setBright(false)
    else
        self.btnOutCard:setTouchEnabled(true)
        self.btnOutCard:setBright(true)
        has_oper = true
    end

    if not has_oper then
        self.oper_panel:setVisible(false)
        self.oper_panel:setEnabled(false)
        self.oper_panel.msgid = nil
    else
        if self:canOutCard() and self:isMustChuCard() then
            self.btnOutCard:setTouchEnabled(true)
            self.btnOutCard:setBright(true)
        else
            self.btnOutCard:setTouchEnabled(false)
            self.btnOutCard:setBright(false)
        end
        self.oper_panel.msgid = msgid
    end
end

function PDKScene:showLeftHandCard(msg)
    log('showLeftHandCard')
    for index, v in pairs(msg) do
        if index ~= 1 and #v > 0 then
            -- 打出的最后一手牌
            if self.last_out_card[index] ~= 0 then
                for __, v in ipairs(self.last_out_card[index]) do
                    v:removeFromParent(true)
                end
            end
            local out_card   = {}
            local outCardNum = #v
            for ci, card_id in ipairs(v) do
                local card = self.hand_card_list[index][#self.hand_card_list[index]]
                if not card then
                    card = self:getCardById(1, true)
                    card:setScale(hand_card_scale[index])
                    card:setPosition(hand_card_pos[index])
                    self:addChild(card)
                end
                card.card_id            = card_id
                out_card[#out_card + 1] = card
                table.remove(self.hand_card_list[index], #self.hand_card_list[index])
                card.card = self:getCardById(card_id)
                card.card:setPosition(cc.p(card:getContentSize().width / 2, card:getContentSize().height / 2))
                card:addChild(card.card)
                card:setScale(0.7)
                local desPos = self:calOutCarPos(index, outCardNum, ci)
                card:runAction(cc.MoveTo:create(0.05, desPos))
                card:setLocalZOrder(ci)
            end
            self.last_out_card[index] = out_card
        end
    end

    for k = 2, 3 do
        for __, vv in ipairs(self.hand_card_list[k] or {}) do
            if vv and vv.removeFromParent then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[k] = {}
    end
end

function PDKScene:peopleNumErroJoinRoomAgain()
    gt.uploadErr('pdk peopleNumErroJoinRoomAgain')
    local net_msg = {
        cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
        room_id = self.desk,
    }
    ymkj.SendData:send(json.encode(net_msg))
end

function PDKScene:initResultUI(rtn_msg)
    local Record = require('scene.Record')
    Record.save_new_record(self, rtn_msg, RecordGameType.JDPDK)

    local node = tolua.cast(cc.CSLoader:createNode("ui/DDZxjs.csb"), "ccui.Widget")
    self:addChild(node, 100000, 10109)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)
    if rtn_msg.jiesan_detail then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "dijiju"), "ccui.Text"):setString("中途解散")
    else
        tolua.cast(ccui.Helper:seekWidgetByName(node, "dijiju"), "ccui.Text"):setString("第"..rtn_msg.cur_ju.."局")
    end
    self.jushu     = rtn_msg.cur_ju
    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()) .. "经典跑得快"..self.desk.."房第"..rtn_msg.cur_ju.."局切磋详情:\n"
    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        if not self.player_ui[play_index] then
            gt.uploadErr('pdk result peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end
        local player_id   = self.player_ui[play_index].user and self.player_ui[play_index].user.user_id or ''
        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''

        copy_str = copy_str.."选手号:"..player_id.."  名字:"
        copy_str = copy_str..player_name.."  成绩:"..v.score.."\n"
    end
    commonlib.shareResult(node, copy_str, g_game_name.."房号:"..self.desk, self.desk, self.copy)

    for play_index = 1, 3 do
        self.player_ui[play_index]:getChildByName("PFN"):setVisible(false)
    end

    if self.is_playback then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "huifangma"), "ccui.Text"):setString("安全码:"..self.log_data_id)
    else
        tolua.cast(ccui.Helper:seekWidgetByName(node, "huifangma"), "ccui.Text"):setString("安全码:"..rtn_msg.log_data_id)
    end

    for i, v in ipairs(self.hand_card_list) do
        for __, vv in ipairs(v) do
            if vv then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[i] = {}
    end

    local bg = ccui.Helper:seekWidgetByName(node, "win")
    ccui.Helper:seekWidgetByName(node, "btn-jxyx"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            print("open continue")

            node:removeFromParent(true)
            self:resetData()
            self.my_cards = {}
            for ii, vv in ipairs(self.last_out_card) do
                if vv ~= 0 then
                    for __, v in ipairs(vv) do
                        v:removeFromParent(true)
                    end
                    self.last_out_card[ii] = 0
                end
            end

            self.sel_list = {}
            for __, v in ipairs(self.player_ui) do
                if v.coin then
                    tolua.cast(ccui.Helper:seekWidgetByName(v, "lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.coin + 1000))
                end
                if v.left_lbl then
                    v.left_lbl:setString(0)
                end
            end

            self.watcher_lab:stopAllActions()
            self.watcher_lab:setVisible(false)

            self.oper_panel:setVisible(false)
            self.oper_panel:setEnabled(false)

            if not self.is_playback then
                if not rtn_msg.results then
                    self.quan_lbl:setString("局数：" .. (rtn_msg.cur_ju + 1) .. "/"..self.total_ju.."局")
                    self.cur_ju = self.cur_ju + 1
                    if self.piaofen and self.panel_piaofen and self.piaofen == 1 then
                        self.panel_piaofen:setVisible(true)
                        self.panel_piaofen:setEnabled(true)
                    else
                        self:sendReady()
                    end
                    if g_channel_id == 800002 then
                        AudioManager:playDWCBgMusic("sound/ddz_bgplay.mp3")
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, rtn_msg.log_ju_id, rtn_msg.gmId)
                end
            else
                if not rtn_msg.results then
                    self:unregisterEventListener()
                    AudioManager:stopPubBgMusic()
                    local scene     = require("scene.MainScene")
                    local gameScene = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, gt.playback_log_ju_id, rtn_msg.gmId)
                end
            end
        end
    end)

    if rtn_msg.results then
        ccui.Helper:seekWidgetByName(node, "btn-jxyx"):loadTextureNormal("ui/qj_ddz_final/dt_ddz_finalone_goon1.png")
        ccui.Helper:seekWidgetByName(node, "btn-jxyx"):loadTexturePressed("ui/qj_ddz_final/dt_ddz_finalone_goon1.png")
    end

    tolua.cast(ccui.Helper:seekWidgetByName(node, "shuoming"), "ccui.Text"):setVisible(false)
    tolua.cast(ccui.Helper:seekWidgetByName(node, "shuoming_0"), "ccui.Text"):setString("玩法: 经典跑得快 "..self.wanfa_str)

    table.sort(rtn_msg.players, function(x, y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg.players) do
        local play_index  = self:indexTrans(v.index)
        local sortIndex   = self:setResultIndex(play_index)
        local play        = tolua.cast(ccui.Helper:seekWidgetByName(node, "play"..sortIndex), "ccui.ImageView")
        local player_head = self.player_ui[play_index].user and self.player_ui[play_index].user.photo or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(player_head, g_wxhead_addr)

        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        if pcall(commonlib.GetMaxLenString, player_name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(commonlib.GetMaxLenString(player_name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(player_name)
        end
        -- tolua.cast(ccui.Helper:seekWidgetByName(play, "id"), "ccui.Text"):setString(self.player_ui[play_index].user.user_id)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "dizhu"), "ccui.ImageView"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "benju"), "ccui.Text"):setString(v.score)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "zhadanshu"), "ccui.Text"):setString(#v.hands)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "shengyushu"), "ccui.Text"):setString(v.zhai)

        if v.piaoniao and v.piaoniao ~= 0 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "PFN"), "ccui.ImageView"):loadTexture("ui/qj_pdk/piao"..v.piaoniao.."fen.png")
        else
            ccui.Helper:seekWidgetByName(play, "PFN"):setVisible(false)
        end
        if not v.is_chuntian or v.is_chuntian == 0 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "quanguan"), "ccui.ImageView"):setVisible(false)
        end

        if not v.is_quanbao or v.is_quanbao == 0 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "baopei"), "ccui.ImageView"):setVisible(false)
        end
        tolua.cast(ccui.Helper:seekWidgetByName(play, "qiangguan"), "ccui.ImageView"):setVisible(false)
        if not v.is_houzi then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "ht10"), "ccui.ImageView"):setVisible(false)
        end
        if v.index == self.my_index then
            if v.score >= 0 then
                bg:loadTexture("ui/qj_ddz_final/dt_ddz_finalone_winBg.png")
                ccui.Helper:seekWidgetByName(node, "Image_31"):loadTexture("ui/qj_ddz_final/dt_ddz_pdk_finalone_winTitleBg.png")
            else
                bg:loadTexture("ui/qj_ddz_final/dt_ddz_finalone_failBg.png")
                ccui.Helper:seekWidgetByName(node, "Image_31"):loadTexture("ui/qj_ddz_final/dt_ddz_pdk_finalone_failTitleBg.png")
            end
        end
        ccui.Helper:seekWidgetByName(play, "name"):setColor(cc.c3b(255, 255, 255))
        ccui.Helper:seekWidgetByName(play, "zhadanshu"):setColor(cc.c3b(255, 255, 255))
        ccui.Helper:seekWidgetByName(play, "shengyushu"):setColor(cc.c3b(255, 255, 255))
        ccui.Helper:seekWidgetByName(play, "benju"):setColor(cc.c3b(255, 255, 255))
        self.player_ui[play_index].coin = v.total_score or (self.player_ui[play_index].coin + v.score)
        local margin                    = 24
        if g_visible_size.width / g_visible_size.height <= 3 / 2 then
            margin = 22
        end

        v.out_cards             = v.out_cards or {}
        local hand_index        = #v.out_cards + 1
        v.out_cards[hand_index] = v.hands

    end

    if #rtn_msg.players < 3 then
        ccui.Helper:seekWidgetByName(node, "play3"):setVisible(false)
        -- ccui.Helper:seekWidgetByName(node,"win3"):setVisible(false)
    end
end

function PDKScene:initVIPResultUI(rtn_msg, jiesan_detail, club_name, log_ju_id, gmId)

    local result_node = self:getChildByTag(10109)
    if result_node then
        result_node:removeFromParent(true)
    end

    local node = tolua.cast(cc.CSLoader:createNode("ui/DDZdjs.csb"), "ccui.Widget")
    self:addChild(node, 100000)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    local max_score = 0
    for __, v in ipairs(rtn_msg) do
        if v.total_score > max_score then
            max_score = v.total_score
        end
    end

    local params = {log_ju_id = log_ju_id, players = {}}
    for i, v in ipairs(rtn_msg) do
        local play_index  = self:indexTrans(v.index)
        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        params.players[#params.players + 1] = {
            nickname = player_name,
        }
    end

    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()) .. "经典跑得快切磋详情:\n"

    table.sort(rtn_msg, function(x, y)
        return x.total_score > y.total_score
    end)

    for i, v in ipairs(rtn_msg) do
        local play_index  = self:indexTrans(v.index)
        local player_id   = self.player_ui[play_index].user and self.player_ui[play_index].user.user_id or ''
        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        copy_str          = copy_str.."选手号:"..player_id.."  名字:"
        copy_str          = copy_str..player_name.."  成绩:"..v.total_score.."\n"
    end

    local title = ""

    if not club_name then
        title = "擂台:"..self.desk
    else
        title = "亲友:"..self.desk
    end

    commonlib.shareResult(node, copy_str, title, self.desk, self.copy, params)

    ccui.Helper:seekWidgetByName(node, "exit"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node:removeFromParent(true)
            self:unregisterEventListener()
            AudioManager:stopPubBgMusic()
            local scene     = require("scene.MainScene")
            local gameScene = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end)
    ccui.Helper:seekWidgetByName(node, "btn-exit"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node:removeFromParent(true)
            self:unregisterEventListener()
            AudioManager:stopPubBgMusic()
            local scene     = require("scene.MainScene")
            local gameScene = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end)

    if self.is_playback then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分", self.create_time))
    else
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分", os.time()))
    end

    if not club_name then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"):setString("房间号："..self.desk)
    else
        if pcall(commonlib.GetMaxLenString, club_name, 12) then
            tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"):setString(commonlib.GetMaxLenString(club_name, 12) .. "的亲友圈")
        else
            tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"):setString(club_name .. "的亲友圈")
        end
        if self.club_index then
            if pcall(commonlib.GetMaxLenString, club_name, 12) then
                tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"):setString(commonlib.GetMaxLenString(club_name, 12) .. "亲友圈" .. self.club_index .. '号')
            else
                tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"):setString(club_name .. "亲友圈" .. self.club_index .. '号')
            end
        end
    end
    -- tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString(self.desk)

    -- tolua.cast(ccui.Helper:seekWidgetByName(node, "shuoming"), "ccui.Text"):setString(self.wanfa_str)
    table.sort(rtn_msg, function(x, y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg) do
        local play_index = self:indexTrans(v.index)
        local sortIndex  = self:setResultIndex(play_index)
        local play       = tolua.cast(ccui.Helper:seekWidgetByName(node, "play"..sortIndex), "ccui.ImageView")

        local player_head = self.player_ui[play_index].user and self.player_ui[play_index].user.photo or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(player_head, g_wxhead_addr)

        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        if pcall(commonlib.GetMaxLenString, player_name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(commonlib.GetMaxLenString(player_name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(player_name)
        end

        local player_id = self.player_ui[play_index].user and self.player_ui[play_index].user.user_id or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-id"), "ccui.Text"):setString("ID:"..player_id)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "benju"), "ccui.Text"):setString(v.total_score)

        -- tolua.cast(ccui.Helper:seekWidgetByName(play, "zhadanshu"), "ccui.Text"):setString(v.total_zhai)
        -- tolua.cast(ccui.Helper:seekWidgetByName(play, "zuigaofen"), "ccui.Text"):setString(v.best_win_socre)
        -- tolua.cast(ccui.Helper:seekWidgetByName(play, "shuyingjushu"), "ccui.Text"):setString((v.lose_ju or 0).."/"..(v.win_ju or 0))

        ccui.Helper:seekWidgetByName(play, "master"):setVisible(false)
        if not self.club_name then
            if v.index == 1 then
                ccui.Helper:seekWidgetByName(play, "master"):setVisible(true)
            end
        end

        if v.total_score <= 0 or v.total_score ~= max_score then
            ccui.Helper:seekWidgetByName(play, "Win"):setVisible(false)
        end

    end

    if #rtn_msg < 3 then
        ccui.Helper:seekWidgetByName(node, "play3"):setVisible(false)
    end

    -- local copy_btn = ccui.Button:create()
    -- copy_btn:loadTextureNormal("ui/qj_majiang/dt/com_fzzj.png")
    -- copy_btn:addTouchEventListener(function(sender, eventType)
    --     if eventType == ccui.TouchEventType.ended then
    --         AudioManager:playPressSound()
    --         print(copy_str)
    --         if ymkj.copyClipboard then
    --             ymkj.copyClipboard(copy_str)
    --         end
    --         commonlib.showLocalTip("已复制战绩，可打开微信分享")
    --     end
    -- end)
    -- copy_btn:setPosition(cc.p(g_visible_size.width-60, 60))
    -- node:addChild(copy_btn)

    local btn_jiesan = ccui.Helper:seekWidgetByName(node, "btn-jsxq")
    if jiesan_detail then
        btn_jiesan:setVisible(true)
        btn_jiesan:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local JiesanLayer = require("scene.JiesanLayer")
                local jiesan      = JiesanLayer:create(jiesan_detail, self.desk, gmId)
                self:addChild(jiesan, 100001)
            end
        end)
    else
        btn_jiesan:setVisible(false)
    end

    local btnOpenwx = ccui.Helper:seekWidgetByName(node, "btn-openwx")
    btnOpenwx:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            gt.openApp("weixin")
        end
    end)

    -- local label_clubid = ccui.Helper:seekWidgetByName(node, "label_clubid")
    -- if self.club_id then
    --     label_clubid:setString(string.format("亲友圈ID:%d",self.club_id))
    -- else
    --     label_clubid:setVisible(false)
    -- end
end

function PDKScene:checkIpWarn(is_click_see)
    if self.is_playback then return end

    self:runAction(cc.CallFunc:create(function()

        local tips = cc.Director:getInstance():getRunningScene():getChildByTag(85001)
        if tips then
            tips:removeFromParent(true)
        end

        local count = 0
        for i, v in ipairs(self.player_ui) do
            if v.user then
                count = count + 1
            end
        end

        local people_num = self.people_num or 2
        if count < people_num then
            if is_click_see then
                commonlib.showLocalTip("房间满人可查看")
            end
            return
        end

        if (people_num == 2 or people_num == 3) and not is_click_see then
            if self.piaofen and self.piaofen == 1 then
                self.panel_piaofen:setVisible(true)
                self.panel_piaofen:setEnabled(true)
                commonlib.showShareBtn(self.share_list)
                commonlib.showbtn(self.jiesanroom)
            end
            return
        end

        self:disapperClubInvite(true)

        -- local GpsMap = require('scene.GpsMap')
        -- GpsMap.showMap(self,people_num,is_click_see)
        local node = tolua.cast(cc.CSLoader:createNode("ui/"..people_num.."dizhi.csb"), "ccui.Widget")
        cc.Director:getInstance():getRunningScene():addChild(node, 999999, 85001)

        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(node)

        local bg = ccui.Helper:seekWidgetByName(node, "bg")
        -- local minScale = math.min(g_visible_size.width/1280,g_visible_size.height/720)
        -- bg:setScale(minScale)

        local neighbor = {}
        if people_num == 2 then
            if self.my_index == 1 then
                neighbor[1] = {2}
                neighbor[2] = {}
            else
                neighbor[1] = {3}
                neighbor[3] = {}
            end
        else
            neighbor[1] = {2, 3}
            neighbor[2] = {3}
            neighbor[3] = {}
        end

        for i, v in ipairs(self.player_ui) do
            -- 本地位置的index UI
            local play_ui = ccui.Helper:seekWidgetByName(node, "play"..math.min(i, people_num))
            if v.user then
                -- 设置头像
                tolua.cast(play_ui:getChildByName("Image_8"), "ccui.ImageView"):downloadImg(v.user.photo, g_wxhead_addr)
                -- 设置昵称
                if pcall(commonlib.GetMaxLenString, v.user.nickname, 8) then
                    tolua.cast(ccui.Helper:seekWidgetByName(play_ui, "Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.user.nickname, 8))
                else
                    tolua.cast(play_ui:getChildByName(play_ui, "Text_2"), "ccui.Text"):setString(v.user.nickname)
                end
                -- IP
                tolua.cast(play_ui:getChildByName("ip"), "ccui.Text"):setString(v.user.ip)
                local lons = string.split(v.user.lon, "&")
                -- 地址
                tolua.cast(play_ui:getChildByName("weizhi"), "ccui.Text"):setString(lons[2] and "" or "未取到精确位置\n(或未开启定位)")

                for __, ii in ipairs(neighbor[i] or {}) do
                    local neighbor_index = math.min(ii, people_num)
                    -- 用户 和 用户信息
                    if self.player_ui[ii] and self.player_ui[ii].user then
                        local lons2 = string.split(self.player_ui[ii].user.lon, "&")
                        local dis   = commonlib.distanceLatLon(tonumber(lons[1]), tonumber(v.user.lat), tonumber(lons2[1]), tonumber(self.player_ui[ii].user.lat))
                        if dis < 5000 then dis = math.floor(dis * 0.5) end
                        local strIpWarn = ""
                        if v.user.ip == self.player_ui[ii].user.ip then
                            strIpWarn = "\nIP相同"
                        end
                        local strPrefix = ""
                        if i == 2 and neighbor_index == 4 then
                            strPrefix = "左右两家"
                        end
                        if dis >= 5000 then
                            ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString(strPrefix.."相距5千米以上"..strIpWarn)
                        else
                            ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString(strPrefix.."相距约"..dis.."米"..strIpWarn)
                        end
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(true)
                        if strIpWarn ~= "" or dis <= 300 then
                            ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setColor(cc.c3b(228, 81, 54))
                            ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/1-fs8.png")
                        else
                            ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setColor(cc.c3b(17, 200, 8))
                            ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/2-fs8.png")
                        end
                    else
                        ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
                    end
                end
            elseif neighbor[i] then
                for __, ii in ipairs(neighbor[i] or {}) do
                    local neighbor_index = math.min(ii, people_num)
                    ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                    ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
                end
                play_ui:setVisible(false)
            end
        end

        if is_click_see then
            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setTouchEnabled(false)
            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setBright(false)
            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):setVisible(false)
        else
            ccui.Helper:seekWidgetByName(node, "btn-butongyi"):addTouchEventListener(
                function(__, eventType)
                    if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                        -- print("cancel")
                        node:removeFromParent(true)
                        -- 房主解散房间
                        if self.is_fangzhu then
                            local input_msg = {
                                cmd = NetCmd.C2S_JIESAN,
                            }
                            ymkj.SendData:send(json.encode(input_msg))
                        else
                            -- 非房主退出房间
                            local input_msg = {
                                cmd = NetCmd.C2S_LEAVE_ROOM,
                            }
                            ymkj.SendData:send(json.encode(input_msg))
                        end

                    end
                end)
            end

            ccui.Helper:seekWidgetByName(node, "btn-tongyijiesan"):addTouchEventListener(
                function(__, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        node:removeFromParent(true)
                        -- 继续游戏
                        if not is_click_see then
                            if self.piaofen and self.panel_piaofen and self.piaofen == 1 then
                                self.panel_piaofen:setVisible(true)
                                self.panel_piaofen:setEnabled(true)
                            else
                                self:sendReady()
                            end
                        end
                    end
                end
            )

            if is_click_see then
                ccui.Helper:seekWidgetByName(node, "Panel_1"):addTouchEventListener(
                    function(__, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            node:removeFromParent(true)
                        end
                    end
                )
            end

            self.btnReady:setVisible(false)
            self.btnReady:setTouchEnabled(false)
        end))
end

function PDKScene:playShunziAni(direct)
    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/shunzi/longzhou'
    AudioManager:playDWCSound("sound/game/shunzi.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    local windowSize = cc.Director:getInstance():getWinSize()
    if direct == 2 then
        skeletonNode:setPosition(out_card_pos[direct].x, out_card_pos[direct].y)
        skeletonNode:setScale(0.7)
    elseif direct == 3 then
        skeletonNode:setPosition(out_card_pos[direct].x + 80, out_card_pos[direct].y)
        skeletonNode:setScale(0.7)
    else
        skeletonNode:setPosition(out_card_pos[direct].x, out_card_pos[direct].y - 50)
    end

    self:addChild(skeletonNode, 100)
    skeletonNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()))

end

function PDKScene:playSpringAni()

    local sp = cc.Sprite:create("ui/dt_ddz_play/dtddz_game_chuntian.png")

    sp:setPosition(cc.p(g_visible_size.width / 2, g_visible_size.height / 2))
    self:addChild(sp, 10000)

    sp:runAction(cc.Sequence:create(cc.DelayTime:create(0.3),
        cc.CallFunc:create(function()
            AudioManager:playDWCSound("sound/game/huojian.mp3")
        end), cc.DelayTime:create(0.7), cc.RemoveSelf:create()))

end

function PDKScene:playWinAni()
    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/ddzWin/shengli'

    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)
    skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.RemoveSelf:create()))
    -- skeletonNode:runAction(cc.RemoveSelf:create())

end

function PDKScene:playBombAni(direct)
    -- if g_os == "win" then return end
    local spineFile  = 'ui/qj_ddz_ani/zhadan/zhadan'
    local sprEmotion = cc.Sprite:create("ui/qj_ddz_ani/zhadan/zd.png")
    AudioManager:playDWCSound("sound/game/zhdan.mp3")
    self:addChild(sprEmotion, 300)
    sprEmotion:setPosition(hand_card_pos[direct])
    sprEmotion:setScale(0.7)

    local position = out_card_pos[direct]

    local moveto1  = cc.MoveTo:create(0.5, position)
    local fadeout1 = cc.FadeOut:create(0.1)
    local callfunc = cc.CallFunc:create(function()
        sprEmotion:removeFromParent(true)
        skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
        skeletonNode:setAnimation(0, "animation", false)
        skeletonNode:setPosition(position)
        self:addChild(skeletonNode, 300)
        skeletonNode:setScale(0.7)
    end)
    sprEmotion:runAction(cc.Sequence:create(
        moveto1, fadeout1, callfunc
    ))
end

function PDKScene:playLianduiAni(direct)
    -- if g_os == "win" then return end
    spineFile = 'ui/qj_ddz_ani/liandui/liandui'
    AudioManager:playDWCSound("sound/game/shunzi.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    local windowSize = cc.Director:getInstance():getWinSize()
    if direct == 2 then
        skeletonNode:setPosition(out_card_pos[direct].x, out_card_pos[direct].y)
        skeletonNode:setScale(0.5)
    elseif direct == 3 then
        skeletonNode:setPosition(out_card_pos[direct].x + 80, out_card_pos[direct].y)
        skeletonNode:setScale(0.5)
    else
        skeletonNode:setPosition(out_card_pos[direct].x, out_card_pos[direct].y - 50)
        skeletonNode:setScale(0.7)
    end
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()))

end

function PDKScene:playKaiju()
    -- if g_os == "win" then return end
    spineFile = 'ui/qj_mj/huSpine/kaiju'

    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.RemoveSelf:create()))

end

function PDKScene:playFeiJiAni()

    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/feiji/feiji'
    AudioManager:playDWCSound("sound/game/feiji.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(cc.MoveTo:create(1, cc.p(0, g_visible_size.height / 2)),
        cc.RemoveSelf:create()))

end

function PDKScene:setClubInvite()
    local btnClubInvite = ccui.Helper:seekWidgetByName(self.node, "btn-clubinvite")
    if btnClubInvite then
        btnClubInvite:setVisible(not self.is_game_start and self.qunzhu == 1)
        if self.qunzhu == 1 then
            -- 邀请亲友圈成员
            btnClubInvite:addTouchEventListener(
                function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        local ClubInviteLayer = require('club.ClubInviteLayer')
                        local layer = ClubInviteLayer:create({
                            club_name = self.club_name,
                            club_id   = self.club_id,
                            room_id   = self.room_id,
                            room_info = self.room_info,
                            parent    = self.node,
                        })
                        layer:setName('ClubInviteLayer')
                        self:addChild(layer)
                    end
                end
            )
            local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
            if ClubInviteLayer then
                ClubInviteLayer:exitLayer()
                ClubInviteLayer = nil
            end
        else
            btnClubInvite:setVisible(false)
        end
    end
end

function PDKScene:disapperClubInvite(bForceDiscover)
    --------------------------------------------------------
    local btnClubInvite = ccui.Helper:seekWidgetByName(self.node, "btn-clubinvite")
    if btnClubInvite then
        btnClubInvite:setVisible(not self.is_game_start and self.qunzhu == 1)
        if bForceDiscover then
            btnClubInvite:setVisible(false)
        end
    end
    local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
    if ClubInviteLayer then
        ClubInviteLayer:exitLayer()
        ClubInviteLayer = nil
    end
    --------------------------------------------------------
end

function PDKScene:setRoomData()
    -- 房号
    if self.club_name and self.club_index then
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "roomid"), "ccui.Text"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setVisible(true)
        if pcall(commonlib.GetMaxLenString, self.club_name, 12) then
            tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setString(commonlib.GetMaxLenString(self.club_name, 12) .. self.club_index .. "号[" .. self.desk.. "]")
        else
            tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setString(self.club_name .. self.club_index .. "号[" .. self.desk.. "]")
        end
    else
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "roomid"), "ccui.Text"):setString("房间号："..self.desk)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "roomid"), "ccui.Text"):setVisible(true)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setVisible(false)
    end
end

function PDKScene:clubRename(rtn_msg)
    if rtn_msg and self.club_id == rtn_msg.club_id then
        self.club_name = rtn_msg.club_name or self.club_name

        local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
        if ClubInviteLayer then
            ClubInviteLayer:refreshInviteClubName(self.club_name)
        end
    end
end

function PDKScene:setOwnerName(room_info)
    if room_info.index ~= 1 and room_info.other and room_info.other[1] then
        self.ownername = room_info.other[1].name
    end
end

function PDKScene:setClubEnterMsg()
    if self.club_id and self.club_name and self.club_index then
        print('```````````````````````````')
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = self.club_id
    end
end

function PDKScene:setResultIndex(index)
    if self.people_num == 2 then
        if index == 3 then
            index = 2
        end
    end
    return index
end

function PDKScene:setShuoMing(str)
    str                = string.gsub(str, "[.]+", "\n")
    local shuoming     = true
    local btn_shuoming = ccui.Helper:seekWidgetByName(self.node, "btn-shuoming")
    local shuoming_lbl = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "shuomingBg"), "ccui.ImageView")
    shuoming_lbl:setLocalZOrder(9999)
    shuoming_lbl:setVisible(false)
    local shuoming_txt = ccui.Helper:seekWidgetByName(self.node, "shuoming")
    shuoming_txt:setString("经典跑得快\n"..str)
    btn_shuoming:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if shuoming == false then
                shuoming = true
                shuoming_lbl:setVisible(false)
            else
                shuoming = false
                shuoming_lbl:setVisible(true)
            end
        end
    end)
    local shuoming_lbl_size = shuoming_lbl:getContentSize()
    local shuoming_txt_size = shuoming_txt:getContentSize()
    if shuoming_txt_size.height + 20 > shuoming_lbl_size.height then
        shuoming_lbl:setContentSize(cc.size(shuoming_lbl_size.width, shuoming_txt_size.height + 20))
        shuoming_txt:setPositionY(shuoming_txt_size.height + 10)
    end
end

function PDKScene:creteNewCard(color, num, showCardBack)
    local colorImgName = "joker"
    if color == 0 then
        colorImgName = "spade"
    elseif color == 1 then
        colorImgName = "heart"
    elseif color == 2 then
        colorImgName = "club"
    elseif color == 3 then
        colorImgName = "diamond"
    end

    local texture  = cc.Director:getInstance():getTextureCache():addImage("ui/qj_zgz/card.png")
    local filePath =  cc.FileUtils:getInstance():fullPathForFilename("ui/qj_zgz/card.json")
    local jsonData = nil
    local f = io.open(filePath, "r")
    local t = f:read("*all")
    f:close()
    jsonData = json.decode(t)
    local cardFrames = nil
    local card       = nil
    if showCardBack then
        cardFrames = cc.SpriteFrame:createWithTexture(texture, cc.rect(
            jsonData.frames.card_back.x + 5,
            jsonData.frames.card_back.y + 5,
            jsonData.frames.card_back.w - 10,
            jsonData.frames.card_back.h - 10)
        )
        card = cc.Sprite:createWithSpriteFrame(cardFrames)
        card:setScale(0.5)
    else
        cardFrames = cc.SpriteFrame:createWithTexture(texture, cc.rect(
            jsonData.frames[colorImgName .. "_".. num].x,
            jsonData.frames[colorImgName .. "_".. num].y,
            jsonData.frames[colorImgName .. "_".. num].w,
            jsonData.frames[colorImgName .. "_".. num].h)
        )
        card = cc.Sprite:createWithSpriteFrame(cardFrames)
    end

    return card
end

return PDKScene