local ErrStrToClient = require('common.ErrStrToClient')
local ErrNo          = require('common.ErrNo')
local DDZLogic       = require("logic.DDZLogic")

local DDZScene = class("DDZScene", require("scene.GameScene"))

local NET_CMDS = {
    NetCmd.S2C_BROAD,
    NetCmd.S2C_ROOM_CHAT,
    NetCmd.S2C_ROOM_CHAT_BQ,
    NetCmd.S2C_SYNC_USER_DATA,
    NetCmd.S2C_SYNC_CLUB_NOTIFY,
    NetCmd.S2C_CLUB_MODIFY,

    NetCmd.S2C_READY,
    NetCmd.S2C_LEAVE_ROOM,
    NetCmd.S2C_IN_LINE,
    NetCmd.S2C_OUT_LINE,
    NetCmd.S2C_JIESAN,
    NetCmd.S2C_APPLY_JIESAN,
    NetCmd.S2C_APPLY_JIESAN_AGREE,

    NetCmd.S2C_DDZ_TABLE_USER_INFO,
    NetCmd.S2C_DDZ_GAME_START,
    NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN,
    NetCmd.S2C_DDZ_CALL_SCORE,
    NetCmd.S2C_DDZ_JIABEN,
    NetCmd.S2C_DDZ_CALL_HOST,
    NetCmd.S2C_DDZ_QIANG_HOST,
    NetCmd.S2C_DDZ_SHOW_BANKER,
    NetCmd.S2C_DDZ_OUT_CARD,
    NetCmd.S2C_DDZ_RESULT,
    NetCmd.S2C_LOGIN_OTHER,
}

local SCENE_TAG = {
    EXIT_NODE   = 4532,
    RESULT_NODE = 10109,
    INPUT_NODE  = 81000,
    TIPS_NODE   = 85001,
}

-- 时钟位置
local watcher_lab_pos = {
    [1] = cc.p(g_visible_size.width / 2 - 23, g_visible_size.height / 2.26),
    [2] = cc.p(g_visible_size.width - 95, g_visible_size.height - 126),
    [3] = cc.p(400, g_visible_size.height - 126),
}

local baoting_pos = {
    [2] = cc.p(g_visible_size.width - 165, g_visible_size.height - 130),
    [3] = cc.p(165, g_visible_size.height - 130),
}

-- 手牌位置
local hand_card_pos = {
    [1] = cc.p((g_visible_size.width - 20 * 50 - 25) / 2, 103),
    [2] = cc.p(g_visible_size.width - 165, g_visible_size.height - 145),
    [3] = cc.p(165, g_visible_size.height - 145),
}

-- 手牌缩放参数
local hand_card_scale = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
}

-- 出牌位置
local out_card_pos = {
    [1] = cc.p(g_visible_size.width * 0.5, 400),
    [2] = cc.p(g_visible_size.width - 350, g_visible_size.height - 180),
    [3] = cc.p(280, g_visible_size.height - 180),
}

-- 出牌位置
local playback_card_pos = {
    [1] = cc.p(g_visible_size.width * 0.5, 400),
    [2] = cc.p(g_visible_size.width - 195, g_visible_size.height - 100),
    [3] = cc.p(170, g_visible_size.height - 100),
}

local img_ddzbg = {
    "ui/dt_ddz_play/dt_ddz_play_bg.png",
    "ui/dt_ddz_play/de_ddz_play_bg3.jpg",
    "ui/dt_ddz_play/dt_ddz_play_bg_2.jpg"
}

-- 手牌间距
local handMarginX = 55
-- 手牌宽度（cardWidth * scale）
local handCardWidth = 108
-- 出牌间距
local outMarginX = 35
-- 出牌宽度
local outCarWidth = 85

function DDZScene:ctor(param_list)
    DDZScene.super.ctor(self, param_list)

    self:runAction(cc.CallFunc:create(function()
        AudioManager:stopPubBgMusic()
        AudioManager:playDWCBgMusic("sound/ddz_bgplay.mp3")
    end))
end

function DDZScene:onEnter()
    gt.removeUnusedRes()

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

function DDZScene:onRcvGameMsg()
    local msg = GameController:getModel():getGameMsg()
    if #msg > 0 then
        for i, _ in ipairs(msg) do
            local rtn_msg = msg[i]
            self:onRcvMsg(rtn_msg)
        end
        GameController:getModel():reset()
    end
end

function DDZScene:registerEvent()
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

function DDZScene:registerEventListener()
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
                    self:onRcvMsg(self.order_list[1])
                    if self.order_list[1].cmd == NetCmd.S2C_DDZ_RESULT then
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

        pb_node:addBtListener("btn-rtn", function()
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
        end)

        pb_node.add_btn = pb_node:addBtListener("btn-add", function()
            AudioManager:playPressSound()
            pb_node.play_speed = pb_node.play_speed + 1
            if pb_node.play_speed == 5 then
                pb_node.play_speed = 1
            end
            pb_node.add_btn:loadTextureNormal("ui/qj_replay/speed"..pb_node.play_speed..".png")
            pb_node.add_btn:loadTexturePressed("ui/qj_replay/speed"..pb_node.play_speed..".png")
            cc.Director:getInstance():getScheduler():setTimeScale(pb_node.play_speed)
        end)

        pb_node.pause_btn = pb_node:addBtListener("btn-pause", function()
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
        end)
    end
end

-- 计算手牌位置
function DDZScene:calHandCardPos(playerIndex, totalNum, cardIndex)
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
function DDZScene:calOutCarPos(playerIndex, totalNum, cardIndex)
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
        posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2
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
        posX = iniPosX + (cardIndex - 1) * outMarginX + outCarWidth / 2
    end
    local desPos = cc.p(posX, posY)
    return desPos
end

function DDZScene:calPlayBackOutCarPos(playerIndex, totalNum, cardIndex)
    local posX           = playback_card_pos[playerIndex].x
    local posY           = playback_card_pos[playerIndex].y
    local totalCardWidth = outMarginX * (totalNum - 1) + outCarWidth
    local iniPosX        = 0
    if 1 == playerIndex then
        iniPosX = (g_visible_size.width - totalCardWidth) / 2
        posX    = iniPosX + (cardIndex - 1) * outMarginX * 1.25 + outCarWidth / 2
    elseif 2 == playerIndex then
        if totalNum >= 9 then
            if cardIndex > 10 then
                cardIndex = cardIndex - 10
                posX      = posX + outCarWidth * 0.5
            end
        end
        posY = posY - (cardIndex - 1) * outMarginX - outCarWidth / 2
    elseif 3 == playerIndex then
        if totalNum >= 9 then
            if cardIndex > 10 then
                cardIndex = cardIndex - 10
                posX      = posX + outCarWidth * 0.5
            end
        end
        posY = posY - (cardIndex - 1) * outMarginX - outCarWidth / 2
    end
    local desPos = cc.p(posX, posY)
    return desPos
end

function DDZScene:onRcvError(rtn_msg)
    if rtn_msg.errno and rtn_msg.errno ~= 0 then
        commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or 'Unknown Error ' .. rtn_msg.errno)
        if ErrNo.APPLY_JIESAN_TIME == rtn_msg.errno or ErrNo.APPLY_JIESAN_STATUS == rtn_msg.errno then
            commonlib.closeJiesan(self)
        end
        return true
    end
    return false
end

function DDZScene:registerNetCmd()
    -- for _, v in pairs(NET_CMDS) do
    --     gt.addNetMsgListener(v, handler(self, self.onRcvMsg))
    -- end

    local CUSTOM_LISTENERS = {
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function DDZScene:onRcvMsg(rtn_msg)
    local NET_CMD_LISTENERS = {
        [NetCmd.S2C_BROAD]        = handler(self, self.onRcvBroad),
        [NetCmd.S2C_ROOM_CHAT]    = handler(self, self.onRcvRoomChat),
        [NetCmd.S2C_ROOM_CHAT_BQ] = handler(self, self.onRcvRoomChatBQ),
        -- [NetCmd.S2C_SYNC_USER_DATA]   = handler(self, self.onRcvSyncUserData), -- @noused
        [NetCmd.S2C_SYNC_CLUB_NOTIFY] = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_MODIFY]      = handler(self, self.onRcvClubModify),

        [NetCmd.S2C_READY]              = handler(self, self.onRcvReady),
        [NetCmd.S2C_LEAVE_ROOM]         = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_IN_LINE]            = handler(self, self.onRcvInLine),
        [NetCmd.S2C_OUT_LINE]           = handler(self, self.onRcvOutLine),
        [NetCmd.S2C_JIESAN]             = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_APPLY_JIESAN]       = handler(self, self.onRcvApplyJieSan),
        [NetCmd.S2C_APPLY_JIESAN_AGREE] = handler(self, self.onRcvApplyJieSanAgree),

        [NetCmd.S2C_DDZ_TABLE_USER_INFO] = handler(self, self.onRcvDdzTableUserInfo),
        [NetCmd.S2C_DDZ_GAME_START]      = handler(self, self.onRcvDdzGameStart),
        [NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN] = handler(self, self.onRcvDdzJoinRoomAgain),

        [NetCmd.S2C_DDZ_SHOW_BANKER] = handler(self, self.onRcvDdzShowBanker),
        [NetCmd.S2C_DDZ_JIABEN]      = handler(self, self.onRcvDdzjiaBen),
        [NetCmd.S2C_DDZ_CALL_HOST]   = handler(self, self.onRcvDdzCallHost),
        [NetCmd.S2C_DDZ_QIANG_HOST]  = handler(self, self.onRcvDdzQiangHost),
        [NetCmd.S2C_DDZ_CALL_SCORE]  = handler(self, self.onRcvDdzCallScore),
        [NetCmd.S2C_DDZ_OUT_CARD]    = handler(self, self.onRcvDdzOutCard),
        [NetCmd.S2C_DDZ_RESULT]      = handler(self, self.onRcvDdzResult),
    }

    if NET_CMD_LISTENERS[rtn_msg.cmd] then
        if rtn_msg.errno and rtn_msg.errno ~= 0 then
            self:onRcvError(rtn_msg)
        end

        NET_CMD_LISTENERS[rtn_msg.cmd](rtn_msg)
    else
        ERROR("net cmd msg not handled!!!", rtn_msg)
    end
end

function DDZScene:unregisterNetCmd()
    GameController:unregisterEventListener()
    -- for _, v in pairs(NET_CMDS) do
    --     cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    -- end
end

function DDZScene:showDDZTitle(title)
    if self.btnOne.sp then
        self.btnOne.sp:removeFromParent(true)
        self.btnOne.sp = nil
    end
    if title then
        local sp = cc.Sprite:create("ui/ddz/bu"..title..".png")
        sp:setPosition(cc.p(120, 47))
        sp:setScale(0.9)
        self.btnOne:addChild(sp)
        self.btnOne.sp = sp
        self.btnOne:setTitleText("")
    else
        if self.jiaodifen == 10 then
            local sp5 = cc.Sprite:create("ui/ddz/5f.png")
            sp5:setScale(0.9)
            sp5:setPosition(cc.p(120, 50))
            self.btnOne:addChild(sp5)
            self.btnOne.sp = sp5
            self.btnOne:setTitleText("")
            self.btnOne:setPositionX(258.5)

        else
            local sp5 = cc.Sprite:create("ui/ddz/1f.png")
            sp5:setScale(0.9)
            sp5:setPosition(cc.p(120, 50))
            self.btnOne:addChild(sp5)
            self.btnOne.sp = sp5
            self.btnOne:setTitleText("")
        end
    end

    if self.btnTwo.sp then
        self.btnTwo.sp:removeFromParent(true)
        self.btnTwo.sp = nil
    end
    if title then
        local sp2 = cc.Sprite:create("ui/ddz/"..title.."dizhu.png")
        sp2:setScale(0.9)
        sp2:setPosition(cc.p(115, 47))
        self.btnTwo:addChild(sp2)
        self.btnTwo.sp = sp2
        self.btnTwo:setTitleText("")
    else
        if self.jiaodifen == 10 then
            self.btnTwo:setVisible(false)
            local sp4 = cc.Sprite:create("ui/ddz/10f.png")
            sp4:setScale(0.9)
            sp4:setPosition(cc.p(120, 50))
            self.btnThree:addChild(sp4)
            self.btnThree.sp = sp4
            self.btnThree:setTitleText("")
        else
            local sp3 = cc.Sprite:create("ui/ddz/2f.png")
            sp3:setScale(0.9)
            sp3:setPosition(cc.p(120, 50))
            self.btnTwo:addChild(sp3)
            self.btnTwo.sp = sp3
            self.btnTwo:setTitleText("")

            local sp4 = cc.Sprite:create("ui/ddz/3f.png")
            sp4:setScale(0.9)
            sp4:setPosition(cc.p(120, 50))
            self.btnThree:addChild(sp4)
            self.btnThree.sp = sp4
            self.btnThree:setTitleText("")
        end
    end
end

function DDZScene:showLeftHandCard(msg)
    for index, v in pairs(msg) do
        if index ~= 1 and #v > 0 then
            if self.last_out_card[index] ~= 0 then
                for _, v in ipairs(self.last_out_card[index]) do
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
                card.card:setPosition(cc.p(36, 45))
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
        for _, vv in ipairs(self.hand_card_list[k] or {}) do
            if vv and vv.removeFromParent then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[k] = {}
    end
end

function DDZScene:treatResume(rtn_msg)
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(false)

    self.quan_lbl:setVisible(true)
    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i + 1] = v
    end

    if rtn_msg.qiang_cishu and rtn_msg.qiang_cishu > 0 then
        self.rang_pai = rtn_msg.qiang_cishu
    end
    if self.is_game_start then
        for i, v in ipairs(self.wenhao_list) do
            v:setVisible(false)
        end
        if not self.is_playback then
            if self.people_num == 2 then
                if self.left_show == 1 then
                    if self.my_index == 1 then
                        self:setSyps(2, 17)
                    else
                        self:setSyps(3, 17)
                    end
                end
            else
                if self.left_show == 1 then
                    self:setSyps(2, 17)
                    self:setSyps(3, 17)
                end
            end
        end
    end
    rtn_msg.player_info.hand = rtn_msg.player_info.hand or rtn_msg.player_info.cards
    if rtn_msg.player_info.hand and #rtn_msg.player_info.hand > 0 then
        for i, v in ipairs(playerinfo_list) do
            local k = self:indexTrans(v.index)

            local count = 17
            local scal
            local desPos
            if self.is_playback then
                if v.cards then
                    count = #v.cards
                    DDZLogic:sortDESC(v.cards)
                elseif k == self.banker then
                    count = 20
                end

                if k == 1 then
                    if self.isRetroCard then
                        scal = 1.4
                    else
                        scal = hand_card_scale[k]
                    end
                else
                    scal = 0.5
                end
                for ii = 1, count do
                    if k == 1 then
                        desPos = self:calHandCardPos(k, count, ii)
                    else
                        desPos = self:calPlayBackOutCarPos(k, count, ii)
                    end
                    self.hand_card_list[k][ii] = self:getCardById(1, true)
                    self.hand_card_list[k][ii]:setScale(scal)
                    self.hand_card_list[k][ii]:setPosition(desPos)
                    self.node:addChild(self.hand_card_list[k][ii], 999)
                    if v.cards and v.cards[ii] then
                        self.hand_card_list[k][ii].card    = self:getCardById(v.cards[ii])
                        self.hand_card_list[k][ii].card_id = v.cards[ii]
                        self.hand_card_list[k][ii].card:setPosition(cc.p(self.hand_card_list[k][ii]:getContentSize().width / 2, self.hand_card_list[k][ii]:getContentSize().height / 2))
                        self.hand_card_list[k][ii]:addChild(self.hand_card_list[k][ii].card)
                    end
                end
            else
                if v.hand then
                    count = #v.hand
                    DDZLogic:sortDESC(v.hand)
                elseif k == self.banker then
                    count = 20
                end
                scal = hand_card_scale[k]
                if self.isRetroCard and k == 1 then
                    scal = 1.4
                end
                for ii = 1, count do
                    desPos = self:calHandCardPos(k, count, ii)

                    self.hand_card_list[k][ii] = self:getCardById(1, true)
                    if k == self.banker then
                        self.hand_card_list[k][ii]:setTexture("ui/dt_ddz_play/dizhupaibei-fs8.png")
                    end
                    self.hand_card_list[k][ii]:setScale(scal)
                    self.hand_card_list[k][ii]:setPosition(desPos)
                    self.node:addChild(self.hand_card_list[k][ii], 999)
                    if v.hand and v.hand[ii] then
                        self.hand_card_list[k][ii].card    = self:getCardById(v.hand[ii])
                        self.hand_card_list[k][ii].card_id = v.hand[ii]
                        self.hand_card_list[k][ii].card:setPosition(cc.p(self.hand_card_list[k][ii]:getContentSize().width / 2, self.hand_card_list[k][ii]:getContentSize().height / 2))
                        self.hand_card_list[k][ii]:addChild(self.hand_card_list[k][ii].card)
                    end
                end
            end

            if v.left_num then
                local bj_num = 2
                if self.people_num == 2 and k ~= self.banker then
                    bj_num = bj_num + (self.rang_pai or 0)
                end
                if v.left_num > 0 and v.left_num <= bj_num and not rtn_msg.result_packet then
                    self:showBaoTing(k)
                    if v.left_num == bj_num and count >= 2 then
                        local last_hand_card = self.hand_card_list[k][#self.hand_card_list[k]]
                        if last_hand_card then
                            if k == 2 then
                                last_hand_card:setPositionX(last_hand_card:getPositionX() - 20)
                            else
                                last_hand_card:setPositionX(last_hand_card:getPositionX() + 20)
                            end
                        end
                    end
                end
                self:setSyps(k, v.left_num)
            end
        end

    end

    for i, v in ipairs(playerinfo_list) do
        if v.jiabei == 1 then
            local k  = self:indexTrans(v.index)
            local sp = cc.Sprite:create("ui/ddz/jiabei.png")
            sp:setScale(0.7)
            sp:setPosition(self.player_ui[k].jiabei_pos)
            sp:setLocalZOrder(9000)
            self.node:addChild(sp)
            self.player_ui[k].jiabei_sp = sp
        end
    end

    rtn_msg.bank_card = rtn_msg.bank_card and rtn_msg.bank_card
    if rtn_msg.bank_card and #rtn_msg.bank_card > 0 then
        self.qie_card_list = {}
        local posOfTip     = cc.p(self.imageTip:getPosition())
        local sizeOfTip    = self.imageTip:getContentSize()
        local iniPosX      = posOfTip.x - sizeOfTip.width / 2 + 332
        local posY         = posOfTip.y - sizeOfTip.height + 25
        local qieScale     = 0.28
        if self.isRetroCard then
            iniPosX  = posOfTip.x - sizeOfTip.width / 2 + 341
            posY     = posOfTip.y - sizeOfTip.height + 35
            qieScale = 0.45
        end
        for i, v in ipairs(rtn_msg.bank_card) do
            self.qie_card_list[i] = self:getCardById(1, true)
            self.qie_card_list[i]:setLocalZOrder(i)
            if not self.isRetroCard then
                self.qie_card_list[i]:setAnchorPoint(0, 0)
            end
            self.qie_card_list[i]:setPosition(cc.p(iniPosX + 50 * i, posY))
            self.qie_card_list[i]:setScale(qieScale)
            self:addChild(self.qie_card_list[i])
            self.qie_card_list[i].card = self:getCardById(v)
            self.qie_card_list[i].card:setPosition(cc.p(self.qie_card_list[i]:getContentSize().width / 2, self.qie_card_list[i]:getContentSize().height / 2))
            self.qie_card_list[i]:addChild(self.qie_card_list[i].card)
        end
        -- self.qiepai:setVisible(false)
    end

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
        for _, v in pairs(last_out_card) do
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
            if self.banker then
                if rtn_msg.status ~= 103 then
                    local last_cards = nil -- self:canOutCard(true)
                    if last_cards then
                        self:sendOutCards(last_cards, rtn_msg.player_info.msgid)
                    elseif next_index ~= self.pre_out_direct then
                        self:updateHintList()
                        self:resetOperPanel(101, rtn_msg.player_info.msgid)
                        self:showWatcher(rtn_msg.time or 15, next_index)
                    else
                        self:resetOperPanel(100, rtn_msg.player_info.msgid)
                        self:showWatcher(rtn_msg.time or 15, next_index)
                    end
                else
                    self:showDDZTitle("jia")
                    self:resetOperPanel(5, rtn_msg.player_info.msgid)
                    self:showWatcher(rtn_msg.time or 15, next_index)
                end
            else
                if self.people_num == 2 then
                    if not rtn_msg.call_score or rtn_msg.call_score == 0 then
                        self:showDDZTitle("jiao")
                        self:resetOperPanel(1, rtn_msg.player_info.msgid)
                    else
                        self:showDDZTitle("qiang")
                        self:resetOperPanel(3, rtn_msg.player_info.msgid)
                    end
                else
                    local wang_count = 0
                    local er_count   = 0
                    for _, v in ipairs(rtn_msg.player_info.hand or {}) do
                        if v >= 78 then
                            wang_count = wang_count + 1
                        elseif v % 16 == 2 then
                            er_count = er_count + 1
                        end
                    end
                    if wang_count == 2 or er_count == 4 then
                        self.must_san = true
                    end
                    self:showDDZTitle()
                    self:resetOperPanel(rtn_msg.call_score + 1, rtn_msg.player_info.msgid)
                end
                self:showWatcher(rtn_msg.time or 15, next_index)
            end
        else
            self:showWatcher(rtn_msg.time or 15, next_index)
        end
    end
    if self.rang_pai and self.rang_lab then
        self.rang_lab:setString(self.rang_pai)
        if rtn_msg.rpfd == 1 then
            self.rang_lab2:setString(1)
        elseif rtn_msg.rpfd == 4 then
            if self.rang_pai == 0 then
                self.rang_lab2:setString(1)
            elseif self.rang_pai <= 2 then
                self.rang_lab2:setString(math.pow(2, self.rang_pai))
            else
                self.rang_lab2:setString(4)
            end
        elseif rtn_msg.rpfd == 8 then
            if self.rang_pai == 0 then
                self.rang_lab2:setString(1)
            elseif self.rang_pai <= 3 then
                self.rang_lab2:setString(math.pow(2, self.rang_pai))
            else
                self.rang_lab2:setString(8)
            end
        else
            if self.rang_pai == 0 then
                self.rang_lab2:setString(1)
            else
                self.rang_lab2:setString(math.pow(2, self.rang_pai))
            end
        end
    end

    if rtn_msg.result_packet then
        -- if self.is_game_start then
        --     return
        -- end
        if self.baoting_img then
            for _, v in pairs(self.baoting_img) do
                v:removeFromParent(true)
            end
            self.baoting_img = nil
        end

        local msg_result = {}
        for i, v in ipairs(rtn_msg.result_packet.players) do
            local index = self:indexTrans(v.index)
            if index == 1 then
                if v.score >= 0 then
                    AudioManager:playDWCSound("sound/win.mp3")
                else
                    AudioManager:playDWCSound("sound/lose.mp3")
                end
            end
            msg_result[index] = v.hands or {}
        end

        self:showLeftHandCard(msg_result)

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
            for _, v in ipairs(playerinfo_list) do
                local index = self:indexTrans(v.index)
                if self.player_ui[index] then
                    if v.ready then
                        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
                    end
                end
            end
            AudioManager:stopPubBgMusic()
            self:initResultUI(rtn_msg.result_packet)
        end)))

    end
end

function DDZScene:showBaoTing(direct)
    if direct == 1 then return end
    self.baoting_img = self.baoting_img or {}

    if not self.baoting_img[direct] then
        local sp = cc.Sprite:create("ddz/jingbaodeng1.png")
        sp:setPosition(baoting_pos[direct])
        self:addChild(sp)
        sp:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.8), cc.DelayTime:create(0.5), cc.FadeOut:create(0.3))))

        self.baoting_img[direct] = sp
    end
end

function DDZScene:sendOutCards(cards, msgid)
    if not cards then
        local input_msg = {
            cmd = NetCmd.C2S_DDZ_OUT_CARD,
        }
        if msgid or self.panOprCard.msgid then
            input_msg.msgid = msgid or self.panOprCard.msgid
        end
        ymkj.SendData:send(json.encode(input_msg))
    else
        local input_msg = {
            cmd       = NetCmd.C2S_DDZ_OUT_CARD,
            card_data = cards,
        }
        if msgid or self.panOprCard.msgid then
            input_msg.msgid = msgid or self.panOprCard.msgid
        end
        ymkj.SendData:send(json.encode(input_msg))
    end
    self.panOprCard.msgid = nil
end

function DDZScene:sendCallScore(score)
    local input_msg = {
        cmd   = NetCmd.C2S_DDZ_CALL_SCORE,
        score = score,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function DDZScene:showOutCardAni(typ, direct)
    if typ == 0 then
        local prefix = self:getSoundPrefix(direct)
        AudioManager:playDWCSound("sound/"..prefix.. "/yaobuqi.mp3")

        local sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_noout.png")
        if direct == 1 then
            sp:setPosition(cc.p(watcher_lab_pos[direct].x, watcher_lab_pos[direct].y))
        elseif direct == 2 then
            sp:setPosition(cc.p(watcher_lab_pos[direct].x - 200, watcher_lab_pos[direct].y))
        elseif direct == 3 then
            sp:setPosition(cc.p(watcher_lab_pos[direct].x - 100, watcher_lab_pos[direct].y))
        else
            sp:setPosition(watcher_lab_pos[direct])
        end
        self:addChild(sp, 10000)

        sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(0.3), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
            sp:removeFromParent(true)
        end)))
    end
end

function DDZScene:showOutJiaofenAni(typ, direct)
    -- if self.is_playback then return end
    local prefix = self:getSoundPrefix(direct)
    local sp     = nil
    if typ == 0 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_-1.png")
    elseif typ == 1 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_1.png")
    elseif typ == 2 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_2.png")
    elseif typ == 3 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_3.png")
    elseif typ == 5 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_5.png")
    elseif typ == 10 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_10.png")
    end

    if direct == 1 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x, watcher_lab_pos[direct].y))
    elseif direct == 2 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x - 200, watcher_lab_pos[direct].y))
    elseif direct == 3 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x - 100, watcher_lab_pos[direct].y))
    else
        sp:setPosition(watcher_lab_pos[direct])
    end
    self:addChild(sp, 10000)

    sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.1), cc.DelayTime:create(0.5), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
        sp:removeFromParent(true)
    end)))
end

function DDZScene:showQiangAni(typ, direct)
    -- if self.is_playback then return end
    local prefix = self:getSoundPrefix(direct)
    local sp     = nil
    if typ == 0 then
        sp = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_-1.png")
    elseif typ == 1 then
        sp = cc.Sprite:create("ui/dt_ddz_play/jiaodizhu.png")
    elseif typ == 10 then
        sp = cc.Sprite:create("ui/dt_ddz_play/buqiang.png")
    elseif typ == 11 then
        sp = cc.Sprite:create("ui/dt_ddz_play/qiangdizhu.png")
    end

    if direct == 1 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x + 30, watcher_lab_pos[direct].y))
    elseif direct == 2 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x - 200, watcher_lab_pos[direct].y))
    elseif direct == 3 then
        sp:setPosition(cc.p(watcher_lab_pos[direct].x - 100, watcher_lab_pos[direct].y))
    else
        sp:setPosition(watcher_lab_pos[direct])
    end
    self:addChild(sp, 10000)

    sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.1), cc.DelayTime:create(0.5), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
        sp:removeFromParent(true)
    end)))
end

function DDZScene:getCardById(paramPokerId, showCardBack)
    if not showCardBack then
        if paramPokerId >= 78 then
            paramPokerId = paramPokerId - 13
        end
        local color = 4 - math.floor(paramPokerId / 16)
        if color > 4 or color < 0 then
            commonlib.showLocalTip("花色不正确")
            return
        end

        local value = paramPokerId % 16
        if value > 13 or value < 1 then
            commonlib.showLocalTip("牌值不正确")
            return
        end

        local colorImgName = "w"
        if color == 1 then
            colorImgName = "S@2x"
        elseif color == 2 then
            colorImgName = "H@2x"
        elseif color == 3 then
            colorImgName = "C@2x"
        elseif color == 4 then
            colorImgName = "D@2x"
        end

        if self.isRetroCard then
            return self:creteNewCard(color, value)
        end

        if color ~= 0 then
            if value == 1 then
                value = "A"
            elseif value == 11 then
                value = "J"
            elseif value == 12 then
                value = "Q"
            elseif value == 13 then
                value = "K"
            end
            local card = cc.Sprite:create("ui/Majiang/pai/"..value..colorImgName..".png")
            return card
        else
            local card = cc.Sprite:create("poker/"..colorImgName..value..".png")
            return card
        end
    else
        -- if self.isRetroCard then
        --     return self:creteNewCard(nil, nil, showCardBack)
        -- end
        local card = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_otherCards.png")
        return card
    end
end

function DDZScene:showWatcher(time, direct)
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

function DDZScene:createLayerMenu(room_info)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end

    local node = self:addCSNode("ui/ddzroom.csb")
    self.node  = tolua.cast(node, "ccui.Widget")
    self.node:setContentSize(g_visible_size)
    ccui.Helper:doLayout(self.node)

    self:setClubEnterMsg()

    -- 除房主外的人获取房主的名字
    self:setOwnerName(room_info)

    self.batteryProgress = self:seekNode("battery")
    gt.refreshBattery(self.batteryProgress)
    self.signalImg = self:seekNode("img_xinhao")
    self.pkzhuobu  = gt.getLocal("int", "pkzhuobu", 1)

    local img_bg = self:seekNode("Image_2")
    img_bg:loadTexture(img_ddzbg[self.pkzhuobu])

    self.wenhao_list = {
        self:seekNode("wenhao1"),
        self:seekNode("wenhao2"),
        self:seekNode("wenhao3"),
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

    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
    local XQLayer       = RedBagXQLayer:create({_scene = self, isMJ = false})
    self:addChild(XQLayer, 999)

    -- 红包按钮延时出现 防止收到消息未处理
    self.btnRedBag = self:seekNode("btn_redbag")
    self.btnRedBag:setVisible(false)
    gt.performWithDelay(self.btnRedBag, function()
        self.btnRedBag:setVisible(RedBagController:getModel():getIsValid())
    end, 1.0)
    self.btnRedBag:addClickEventListener(function()
        AudioManager:playPressSound()
        if nil == XQLayer then
            local RedBagXQLayer = require("modules.view.RedBagXQLayer")
            local XQLayer       = RedBagXQLayer:create({_scene = self, isMJ = false})
            self:addChild(XQLayer, 999)
        end
        XQLayer:setHbVisibale(true)
        XQLayer:reFreshHB()
    end)

    local szBtn = self:seekNode("btn-shezhi")
    if szBtn then
        szBtn:addClickEventListener(function()
            AudioManager:playPressSound()
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
                    img_bg:loadTexture(img_ddzbg[ys - 10])
                end, nil, callbackPkCard)
                -- shezhi.is_in_main = true
                self:addChild(shezhi, 100000)
            end
        end)
    end
    self.qiepai = self:seekNode("Panel_17")
    self.qiepai:setLocalZOrder(11)
    -- self.qiepai = qiepai
    self:seekNode("btn-gps"):setVisible(false)
    self:seekNode("btn-gps"):addClickEventListener(function()
        AudioManager:playPressSound()
        self:checkIpWarn(true)
    end)

    local btnFaYan = self:seekNode("btn-fayan")
    self.btnFaYan  = btnFaYan
    self.btnFaYan:addClickEventListener(function()
        AudioManager:playPressSound()
        local RoomMsgLayer = require("scene.RoomMsgLayer")
        self:addChild(RoomMsgLayer.create(nil, function()
        end), 100000)
    end)

    local btnLiaoTian = self:seekNode("btn-liaotian")
    btnLiaoTian:addTouchEventListener(function(sender, eventType)
        self.speekNode:touchEvent(sender, eventType)
    end)
    self.sys = self:seekNode("Panel_2")
    self.sys:setLocalZOrder(1010)

    self.bigbq = self:seekNode("Panel_3")
    self.bigbq:setVisible(false)
    local btnWang = self:seekNode("btn_wang")
    btnWang:addClickEventListener(function()
        AudioManager:playPressSound()
        self.bigbq:setVisible(not self.bigbq:isVisible())
    end)

    self.bigbq:addBtListener("btn_xishou", function()
        AudioManager:playPressSound()
        self.bigbq:setVisible(false)
        gt.playInteractiveSpine(self, "xishou")
        btnWang:setTouchEnabled(false)
        btnWang:setBright(false)
        self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function()
            btnWang:setTouchEnabled(true)
            btnWang:setBright(true)
        end)))
    end)

    self.bigbq:addBtListener("btn_shaoxiang", function()
        AudioManager:playPressSound()
        self.bigbq:setVisible(false)
        gt.playInteractiveSpine(self, "shaoxiang")
        btnWang:setTouchEnabled(false)
        btnWang:setBright(false)
        self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function()
            btnWang:setTouchEnabled(true)
            btnWang:setBright(true)
        end)))
    end)

    -- if room_info.status ~= 0 then
    --     jiesan:setVisible(false)
    -- end
    self:seekNode("df"):setString(room_info.difen)
    self.ddzdifen = room_info.difen

    self.hand_card_list    = {}
    self.hand_card_list[1] = {}
    self.hand_card_list[2] = {}
    self.hand_card_list[3] = {}

    self.left_lbl    = {}
    self.left_lbl[2] = {}
    self.left_lbl[3] = {}
    self.watcher_lab = self:addCSNode("ui/Biao.csb", 100)
    self.watcher_lab:setVisible(false)
    self.watcher_lab.lab = self.watcher_lab:seekNode("Text_1")
    self.watcher_lab.lab:setString("")

    self.player_ui = {}

    for play_index = 1, 3 do
        local play                 = self:seekNode("play"..play_index)
        self.player_ui[play_index] = play

        if play_index == 1 then
            play:setPosition(cc.p(self.wenhao_list[1]:getPosition()))
        elseif play_index == 2 then
            play:setPosition(cc.p(self.wenhao_list[2]:getPosition()))
        elseif play_index == 3 then
            play:setPosition(cc.p(self.wenhao_list[3]:getPosition()))
        end

        self.player_ui[play_index].head_sp = commonlib.stenHead(play:getChildByName("Image_8"), 1)

        play:setVisible(false)

        play:getChildByName("Zhang"):setVisible(false)
        play:getChildByName("txkuang"):loadTexture("ui/dt_ddz_play/dt_ddz_play_headBg.png")
        play:getChildByName("Text_2"):setColor(cc.c3b(255, 255, 255))
        play:getChildByName("Zhang"):setLocalZOrder(2)

        play:getChildByName("zhunbei"):setVisible(false)
        play:getChildByName("zhunbei"):setLocalZOrder(2)

        if play_index ~= 1 then
            play:getChildByName("lixian"):setVisible(false)
            play:getChildByName("lixian"):setLocalZOrder(1)

            self.left_lbl[play_index] = ccui.TextBMFont:create()
            self.left_lbl[play_index]:setPosition(cc.p(hand_card_pos[play_index].x - 5, hand_card_pos[play_index].y + 28))
            self.node:addChild(self.left_lbl[play_index], 1000)
            self.left_lbl[play_index]:setFntFile("ui/dt_ddz_play/fnt/normal_num-export.fnt")
            self.left_lbl[play_index]:setVisible(false)
            -- self.node:addChild(self.left_lbl[play_index])
            if self.is_playback then
                self.left_lbl[play_index]:setVisible(false)
            end
            if self.left_lbl[play_index] then
                if room_info.left_show == 1 then
                    self.left_lbl[play_index]:setString(0)
                else
                    -- local sy_ic = play:seekNode("syps_ic")
                    if sy_ic then
                        sy_ic:setVisible(false)
                    end
                    self.left_lbl[play_index]:setVisible(false)
                end
            end
        end

        if play_index ~= 2 then
            play.jiabei_pos   = commonlib.worldPos(play)
            play.jiabei_pos.x = play.jiabei_pos.x + 60
        else
            play.jiabei_pos   = commonlib.worldPos(play)
            play.jiabei_pos.x = play.jiabei_pos.x - 60
        end

        play:getChildByName("Text_2"):setLocalZOrder(1)
        play:getChildByName("Image_9"):setLocalZOrder(1)

        play:addClickEventListener(function()
            if self.player_ui[play_index].user then
                AudioManager:playPressSound()
                local svr_index = self.my_index + play_index - 1
                if svr_index > 3 then
                    svr_index = svr_index - 3
                end
                local PlayerInfo = require("scene.PlayerInfo")
                self:addChild(PlayerInfo.create(self.player_ui[play_index].user, svr_index, play_index == 1, self.ignoreArr, self), 100000)
            end
        end)
    end

    self.panJiaoFen = self:seekNode("panJiaoFen")
    self.panOprCard = self:seekNode("panOprCard")
    self.btnOutCard = self.panOprCard:seekNode("btn-chupai")
    self.btnTiShi   = self.panOprCard:seekNode("btn-tishi")
    self.btnBuChu   = self.panOprCard:seekNode("btn-buchu")
    self.btnYaoBuQi = self:seekNode("btnYaobuqi")
    self.btnBujiao  = self.panJiaoFen:seekNode("btn-bujiao")
    self.btnOne     = self.panJiaoFen:seekNode("btn-one")
    self.btnTwo     = self.panJiaoFen:seekNode("btn-two")
    self.btnThree   = self.panJiaoFen:seekNode("btn-three")
    self.zhegai     = self:seekNode("zhegai")

    self.btnYaoBuQi:setLocalZOrder(1000)
    self.people_num = room_info.people_num or 3
    self.zhegai:setLocalZOrder(10000)
    if self.people_num == 2 then
        self.btnBujiao:setVisible(false)
        self.btnBujiao:setTouchEnabled(false)

        self.btnThree:setVisible(false)
        self.btnThree:setTouchEnabled(false)

        self.btnTwo:setTitleText("")
        self.btnOne:setTitleText("")
    end
    -- 绑定事件
    self.btnBujiao:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBuJiaoClicked()
    end)
    self.btnOne:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBtnOneClicked()
    end)
    self.btnTwo:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBtnTwoClicked()
    end)
    self.btnThree:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBtnThreeClicked()
    end)
    self.btnTiShi:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onTiShiClicked()
    end)
    self.btnOutCard:addClickEventListener(function()
        AudioManager:playPressSound()
        if self:canOutCard() then
            self:onBtnOutCardClicked()
        else
            commonlib.showLocalTip("不符合出牌规则")
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
    end)
    self.btnBuChu:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBuChuClicked()
    end)

    self.btnYaoBuQi:addClickEventListener(function()
        AudioManager:playPressSound()
        self:onBuChuClicked()
        self.btnYaoBuQi:setVisible(false)
        self.zhegai:setVisible(false)
    end)

    self.panOprCard:setVisible(false)
    self.panJiaoFen:setVisible(false)
    self.btnYaoBuQi:setVisible(false)
    self.zhegai:setVisible(false)

    self.imageTip = self:seekNode("Image_tip")
    self.panDiPai = self.imageTip:seekNode("panDiPai")
    self.imageTip:setLocalZOrder(10)
    if self.is_playback then
        commonlib.showSysTime(self:seekNode("time"), self.create_time)
    else
        local time = time or os.time()
        self:seekNode("time"):setString(os.date("%H:%M", time))
        self:seekNode("time"):runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            time = time + 1
            self:seekNode("time"):setString(os.date("%H:%M", time))
        end))))
    end
    self.rpfd      = room_info.rpfd
    self.jiaodifen = room_info.jiaofen

    self.share_list = {
        self:seekNode("WxShare"),
        self:seekNode("btn-copyroom"),
        self:seekNode("DdShare"),
        self:seekNode("YxShare"),
    }

    self.jiesan = self:seekNode("btn-jiesan")
    self.jiesan:setVisible(not ios_checking)
    self.jiesan:addClickEventListener(function()
        AudioManager:playPressSound()
        if self.is_fangzhu then
            commonlib.showTipDlg("返回大厅包厢仍然保留，赶紧去邀请好友吧", function(is_ok)
                if is_ok then
                    self:unregisterEventListener()
                    gt.setLocalString("is_back_fromroom", "true")
                    gt.flushLocal()
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
    end)

    self.jiesanroom = self:seekNode("btn_jiesanroom")
    if ios_checking then
        self.jiesanroom:setPositionX(g_visible_size.width * 0.5)
    end
    self.jiesanroom:addClickEventListener(function()
        AudioManager:playPressSound()
        gt.setLocalString("is_back_fromroom", "false")
        gt.flushLocal()

        commonlib.sendJiesan(self.is_game_start, self.is_fangzhu)
    end)
    self.wanfa = self:seekNode("btn_wanfa")
    self.wanfa:setVisible(false)
    self.wanfa:addClickEventListener(function()
        AudioManager:playPressSound()
        local HelpLayer = require("scene.kit.HelpDialog")
        local help      = HelpLayer.create(self, "ddz")
        help.is_in_main = true
        self:addChild(help, 100000)
    end)
    if self.is_playback then
        btnFaYan:setVisible(false)
        btnWang:setVisible(false)
        btnLiaoTian:setVisible(false)
    end
    if ios_checking then
        btnLiaoTian:setVisible(false)
    end

    self.beishu_lbl = self:seekNode("bs")
    if self.people_num == 3 then
        local call_score   = math.max(room_info.call_score or 1, 1)
        self.beishu_lbl.bs = math.max(room_info.beishu or 1, call_score)
    else
        self.beishu_lbl.bs = math.max(room_info.beishu or 1, 1)
    end

    if room_info.result_packet then
        room_info.cur_ju = room_info.result_packet.cur_ju or room_info.cur_ju or 1
        if room_info.result_packet.chuntian == true or room_info.result_packet.chuntian == 1 then
            self.beishu_lbl.bs = self.beishu_lbl.bs * 2
        end
    else
        room_info.cur_ju = room_info.cur_ju or 1
    end
    self.beishu_lbl:setString(self.beishu_lbl.bs)
    self.total_ju = room_info.total_ju or nil
    self.quan_lbl = self:seekNode("jushu")

    self.is_game_start = (room_info.status ~= 0 or room_info.cur_ju ~= 1)
    self.is_fangzhu    = (room_info.qunzhu ~= 1 and self.my_index == 1)

    if self.is_game_start then
        self.quan_lbl:setVisible(true)
    else
        self.quan_lbl:setVisible(false)
    end
    if self.is_playback then
        self.quan_lbl:setString("第"..room_info.cur_ju.."局")
    else
        self.quan_lbl:setString("剩余" .. (room_info.total_ju - room_info.cur_ju) .. "局")
    end
    self:setRoomData()
    -- self:seekNode("roomid"):setString(self.desk)

    local playerinfo_list = {room_info.player_info}
    for i, v in ipairs(room_info.other) do
        playerinfo_list[i + 1] = v
    end
    -- dump(playerinfo_list)
    local need_ready = (room_info.status == 0 or room_info.status == 102 and not room_info.result_packet)
    for _, v in ipairs(playerinfo_list) do
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

            self.player_ui[index]:seekNode("lab-jinbishu"):setString(commonlib.goldStr(v.score + 1000))
            if index ~= 1 and v.out_line then
                if type(v.out_line) == "boolean" then v.out_line = 0 end
                commonlib.lixian(self.player_ui[index], "likai", v.out_line)
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

    local str           = ""
    local wfstr         = ""
    local max_zhadanshu = ""
    if room_info.max_zhai == 8 then
        max_zhadanshu = 3
    elseif room_info.max_zhai == 16 then
        max_zhadanshu = 4
    elseif room_info.max_zhai == 32 then
        max_zhadanshu = 5
    end

    if room_info.max_zhai and room_info.max_zhai ~= 0 then
        wfstr = wfstr..max_zhadanshu.."个炸封顶."
    else
        wfstr = wfstr.."不封顶."
    end
    str = str..room_info.people_num.."人玩."
    str = str..room_info.total_ju.."局."
    if room_info.host_type == 1 then
        str = str.."赢家坐庄."
    elseif room_info.host_type == 2 then
        str = str.."轮流坐庄."
    else
        str = str.."随机坐庄."
    end

    if room_info.difen == 1 then
        str = str.."一分底."
    elseif room_info.difen == 2 then
        str = str.."二分底."
    else
        str = str.."三分底."
    end

    if self.people_num == 2 then
        if room_info.max_zhai and room_info.max_zhai ~= 0 then
            str = str..max_zhadanshu.."个炸封顶."
        else
            str = str.."不封顶."
        end
        if room_info.rpfd == 1 then
            str = str .. "让牌1倍."
        elseif room_info.rpfd == 4 then
            str = str .. "让牌4倍."
        elseif room_info.rpfd == 8 then
            str = str .. "让牌8倍."
        else
            str = str .. "让牌16倍."
        end
    else
        if room_info.max_zhai and room_info.max_zhai ~= 0 then
            str = str..max_zhadanshu.."个炸封顶."
        else
            str = str.."不封顶."
        end
        if room_info.can_jiabei == 1 then
            str = str.."可加倍."
        end
    end
    if room_info.left_show == 1 then
        str = str.."牌数显示."
    end

    if room_info.people_num == 3 then
        if room_info.jiaofen == 10 then
            str = str.."5/10分."
        else
            str = str.."1/2/3分."
        end
    end

    if room_info.isFDBHCT == 1 then
        str = str.."封顶包含春天."
    end

    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)."
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)."
    else
        room_type = "(房主房)."
    end
    str = str..room_type

    self.wanfa_str = str

    self:setShuoMing(self.wanfa_str)

    self.ddzwanfa_str  = wfstr
    self.sel_list      = {}
    self.last_out_card = {0, 0, 0}

    local wanfa_lbl = self:seekNode("lab-wanfa")
    wanfa_lbl:setString(self.ddzwanfa_str)

    if self.people_num == 2 then
        local sp = cc.Sprite:create("ui/ddz/ddz_r.png")
        sp:setScale(0.6)
        sp:setAnchorPoint(1, 0.5)
        sp:setPosition(cc.p(g_visible_size.width / 2 - 120, g_visible_size.height - 140))
        self.node:addChild(sp)

        self.rang_lab = ccui.TextAtlas:create(0, "ui/ddz/ddz_num.png", 42, 58, 0)
        self.rang_lab:setScale(0.5)
        self.rang_lab:setAnchorPoint(0, 0.5)
        self.rang_lab:setPosition(cc.p(g_visible_size.width / 2 - 50, g_visible_size.height - 140))
        sp:setAnchorPoint(0, 0.5)
        self.node:addChild(self.rang_lab)

        local sp2 = cc.Sprite:create("ui/ddz/ddz_r-fs8.png")
        sp2:setScale(0.6)
        sp2:setPosition(cc.p(g_visible_size.width / 2 + 120, g_visible_size.height - 140))
        self.node:addChild(sp2)

        self.rang_lab2 = ccui.TextAtlas:create(0, "ui/ddz/ddz_num.png", 42, 58, 0)
        self.rang_lab2:setScale(0.5)
        self.rang_lab2:setAnchorPoint(0.5, 0.5)
        self.rang_lab2:setPosition(cc.p(g_visible_size.width / 2 + 130, g_visible_size.height - 140))
        self.node:addChild(self.rang_lab2)
        self.rang_lab2:setString(1)
    end

    room_info.host_id = (room_info.host_id or room_info.player_info.host_id)
    if room_info.host_id > 0 and room_info.host_id <= 3 and not self.is_playback then
        self.banker = self:indexTrans(room_info.host_id)
    end

    self.copy = (room_info.copy == 1)

    self.left_show = room_info.left_show
    if room_info.status ~= 0 then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:treatResume(room_info)
        end
    else
        if not room_info.player_info or not room_info.player_info.ready then
            self:checkIpWarn()
            self:sendReady()
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

    if self.banker then
        self.player_ui[self.banker]:getChildByName("Zhang"):setVisible(true)
        self.player_ui[self.banker]:getChildByName("txkuang"):loadTexture("ui/dt_ddz_play/dizhu-fs8.png")
        self.player_ui[self.banker]:getChildByName("Text_2"):setColor(cc.c3b(252, 235, 180))
        if self.left_lbl[self.banker] then
            log(self.banker)
            self.left_lbl[self.banker]:setFntFile("ui/dt_ddz_play/fnt/dizhu_num-export.fnt")
        end
    end

    self:registerEventListener()

    -- if ios_checking or g_author_game then
    --     commonlib.showShareBtn(self.share_list)
    -- else
    local share_title = self.desk..g_game_name
    commonlib.showShareBtn(self.share_list, "斗地主"..str, share_title, self.desk, self.copy, function()
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
                local pos = cc.p(xx, yy)
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
                self.btnOutCard:setBright(true)
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
                            rect.width = 40
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
                        local exist = nil
                        local v     = self.hand_card_list[1][i]
                        if v then
                            for cii, cid in ipairs(self.sel_list) do
                                if v.card_id == cid then
                                    exist = cii
                                    break
                                end
                            end
                            if not exist then
                                self.sel_list[#self.sel_list + 1] = v.card_id
                                --- 滑动手牌时若存在顺子则将顺子选择出来
                                self:shunziChoose(self.sel_list, v)
                            else
                                table.remove(self.sel_list, exist)
                                v:setPositionY(hand_card_pos[1].y)
                            end
                        end
                    end
                end
            else
                if self:canOutCard() then
                    self.btnOutCard:setTouchEnabled(true)
                    self.btnOutCard:setBright(true)
                else
                    self.btnOutCard:setTouchEnabled(true)
                    self.btnOutCard:setBright(true)
                end
            end
        end)

    end

    self.qunzhu = room_info.qunzhu
    self:setClubInvite()
end

function DDZScene:jiaoFen(score)
    self.panJiaoFen:setVisible(false)
    self:sendCallScore(score)
end

function DDZScene:onBuJiaoClicked()
    self:jiaoFen(0)
end

function DDZScene:onBtnOneClicked()
    if self.people_num == 2 then
        if self.panJiaoFen.oper == 1 then
            local input_msg = {
                cmd  = NetCmd.C2S_DDZ_CALL_HOST,
                call = 0,
            }
            ymkj.SendData:send(json.encode(input_msg))
        else
            local input_msg = {
                cmd   = NetCmd.C2S_DDZ_QIANG_HOST,
                qiang = 0,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
        self.panJiaoFen:setVisible(false)
    else
        if self.panJiaoFen.oper == 5 then
            local input_msg = {
                cmd = NetCmd.C2S_DDZ_JIABEN,
                typ = 0,
            }
            ymkj.SendData:send(json.encode(input_msg))
            self.panJiaoFen:setVisible(false)
        else
            if self.jiaodifen == 10 then
                self:jiaoFen(5)
            else
                self:jiaoFen(1)
            end
        end
    end
end

function DDZScene:onBtnTwoClicked()
    if self.people_num == 2 then
        if self.panJiaoFen.oper == 1 then
            local input_msg = {
                cmd  = NetCmd.C2S_DDZ_CALL_HOST,
                call = 1,
            }
            ymkj.SendData:send(json.encode(input_msg))
        else
            local input_msg = {
                cmd   = NetCmd.C2S_DDZ_QIANG_HOST,
                qiang = 1,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
        self.panJiaoFen:setVisible(false)
    else
        if self.panJiaoFen.oper == 5 then
            local input_msg = {
                cmd = NetCmd.C2S_DDZ_JIABEN,
                typ = 1,
            }
            ymkj.SendData:send(json.encode(input_msg))
            self.panJiaoFen:setVisible(false)
        else
            self:jiaoFen(2)
        end
    end
end

function DDZScene:onBtnThreeClicked()
    if self.jiaodifen == 10 then
        self:jiaoFen(10)
    else
        self:jiaoFen(3)
    end
end

-- 提示
function DDZScene:onTiShiClicked()
    local tishi_cards = nil
    if self.hint_list and #self.hint_list > 0 then
        self.cur_hint = (self.cur_hint or 0) + 1
        if self.cur_hint > #self.hint_list then
            self.cur_hint = 1
        end
        tishi_cards = self.hint_list[self.cur_hint]
    end
    if not tishi_cards or #tishi_cards <= 0 then
        self:sendOutCards()
        self.panOprCard:setVisible(false)
    else
        for _, v in ipairs(self.hand_card_list[1]) do
            for cii, cid in ipairs(self.sel_list) do
                if v.card_id == cid then
                    table.remove(self.sel_list, cii)
                    v:setPositionY(hand_card_pos[1].y)
                    break
                end
            end
            for _, cid in ipairs(tishi_cards) do
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

function DDZScene:onBtnOutCardClicked()
    if #self.sel_list < 0 then
        self:sendOutCards()
    else
        self:sendOutCards(self.sel_list)
    end
    self.panOprCard:setVisible(false)
end

function DDZScene:onBuChuClicked()
    self:sendOutCards()
    self.panOprCard:setVisible(false)
end

function DDZScene:getSoundPrefix(index)
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

function DDZScene:canOutCard(is_last)
    local pre_card = self.last_out_card[3]
    if pre_card == 0 then
        pre_card = self.last_out_card[2]
    end
    local next_cards = nil
    if is_last then
        next_cards = {}
        for i, v in ipairs(self.hand_card_list[1]) do
            next_cards[i] = v.card_id
        end
    else
        next_cards = self.sel_list
    end
    local can = nil
    if pre_card ~= 0 then
        local last_id_list = {}
        for _, pre in ipairs(pre_card) do
            last_id_list[#last_id_list + 1] = pre.card_id
        end
        can = DDZLogic:CompareCard(last_id_list, next_cards)
    else
        can = DDZLogic:GetCardType(next_cards) > 0
    end
    if can then
        if is_last then
            can = DDZLogic:GetCardType(next_cards)
            if can == 11 or can == 12 then
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

function DDZScene:updateHintList()
    local pre_card = self.last_out_card[3]
    if pre_card == 0 then
        pre_card = self.last_out_card[2]
    end
    local next_cards = {}
    for i, v in ipairs(self.hand_card_list[1]) do
        next_cards[i] = v.card_id
    end
    local rtn      = nil
    self.hint_list = {}
    self.cur_hint  = 0
    if pre_card ~= 0 then
        local last_id_list = {}
        for _, pre in ipairs(pre_card) do
            last_id_list[#last_id_list + 1] = pre.card_id
        end
        DDZLogic:SearchOutCard(next_cards, last_id_list, self.hint_list)
    end
end

function DDZScene:resetOperPanel(oper, msgid)
    if not oper then
        self.panOprCard:setVisible(false)
        self.panJiaoFen:setVisible(false)
        self.btnYaoBuQi:setVisible(false)
        self.zhegai:setVisible(false)
        self.panOprCard.msgid = nil
    else
        if 100 <= oper then
            if (oper == 101) and (not self.hint_list or #self.hint_list <= 0) then
                self.panOprCard:setVisible(false)
                self.panJiaoFen:setVisible(false)
                self.btnYaoBuQi:setVisible(true)
                self.zhegai:setVisible(true)
            else
                self.panOprCard:setVisible(true)
                self.panJiaoFen:setVisible(false)
                self.btnYaoBuQi:setVisible(false)
                self.zhegai:setVisible(false)

                self.btnBuChu:setVisible(100 ~= oper)
                self.btnTiShi:setVisible(100 ~= oper)

                local x, y = self.btnTiShi:getPosition()
                if not self.btnTiShi:isVisible() then
                    self.btnOutCard:setPosition(x, y)
                else
                    self.btnOutCard:setPosition(cc.p(470, 61.5))
                end
                local boCanOutCard = self:canOutCard()
                if boCanOutCard then
                    self.btnOutCard:setTouchEnabled(true)
                    self.btnOutCard:setBright(true)
                else
                    self.btnOutCard:setTouchEnabled(false)
                    self.btnOutCard:setBright(true)
                end
            end
        else
            self.btnYaoBuQi:setVisible(false)
            self.zhegai:setVisible(false)
            self.panOprCard:setVisible(false)
            self.panJiaoFen:setVisible(true)
            self.panJiaoFen.oper = oper
            if self.people_num == 3 then
                if oper == 6 then
                    self.btnBujiao:setVisible(true)
                    self.btnBujiao:setTouchEnabled(true)
                    self.btnBujiao:setBright(true)

                    self.btnOne:setTouchEnabled(false)
                    self.btnOne:setBright(false)

                    self.btnThree:setVisible(true)
                    self.btnThree:setTouchEnabled(true)
                    self.btnThree:setBright(true)
                elseif oper >= 5 then
                    self.btnBujiao:setTouchEnabled(false)
                    self.btnBujiao:setBright(false)
                    self.btnBujiao:setVisible(false)

                    self.btnThree:setTouchEnabled(false)
                    self.btnThree:setBright(false)
                    self.btnThree:setVisible(false)

                    self.btnOne:setPositionX(164.5)
                    self.btnOne:setTouchEnabled(true)
                    self.btnOne:setBright(true)
                    self.btnTwo:setTouchEnabled(true)
                    self.btnTwo:setBright(true)
                    self.btnTwo:setVisible(true)
                elseif self.must_san then
                    self.btnBujiao:setVisible(true)
                    self.btnBujiao:setTouchEnabled(false)
                    self.btnBujiao:setBright(false)

                    self.btnOne:setTouchEnabled(false)
                    self.btnOne:setBright(false)

                    self.btnTwo:setTouchEnabled(false)
                    self.btnTwo:setBright(false)

                    self.btnThree:setVisible(true)
                    self.btnThree:setTouchEnabled(true)
                    self.btnThree:setBright(true)
                elseif oper >= 3 then
                    self.btnBujiao:setVisible(true)
                    self.btnBujiao:setTouchEnabled(true)
                    self.btnBujiao:setBright(true)

                    self.btnOne:setTouchEnabled(false)
                    self.btnOne:setBright(false)

                    self.btnTwo:setTouchEnabled(false)
                    self.btnTwo:setBright(false)

                    self.btnThree:setVisible(true)
                    self.btnThree:setTouchEnabled(true)
                    self.btnThree:setBright(true)
                elseif oper >= 2 then
                    self.btnBujiao:setVisible(true)
                    self.btnBujiao:setTouchEnabled(true)
                    self.btnBujiao:setBright(true)

                    self.btnOne:setTouchEnabled(false)
                    self.btnOne:setBright(false)

                    self.btnTwo:setTouchEnabled(true)
                    self.btnTwo:setBright(true)

                    self.btnThree:setVisible(true)
                    self.btnThree:setTouchEnabled(true)
                    self.btnThree:setBright(true)
                elseif oper >= 1 then
                    self.btnBujiao:setVisible(true)
                    self.btnBujiao:setTouchEnabled(true)
                    self.btnBujiao:setBright(true)

                    self.btnOne:setTouchEnabled(true)
                    self.btnOne:setBright(true)

                    self.btnTwo:setTouchEnabled(true)
                    self.btnTwo:setBright(true)

                    self.btnThree:setVisible(true)
                    self.btnThree:setTouchEnabled(true)
                    self.btnThree:setBright(true)
                end
            end
        end
        self.panOprCard.msgid = msgid
    end
end

function DDZScene:peopleNumErroJoinRoomAgain()
    gt.uploadErr('ddz peopleNumErroJoinRoomAgain')
    local net_msg = {
        cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
        room_id = self.desk,
    }
    ymkj.SendData:send(json.encode(net_msg))
end

function DDZScene:initResultUI(rtn_msg)
    local Record = require('scene.Record')
    Record.save_new_record(self, rtn_msg, RecordGameType.DDZ)

    local node = self:addCSNode("ui/DDZxjs.csb", 100000)
    node       = tolua.cast(node, "ccui.Widget")
    node:setTag(SCENE_TAG.RESULT_NODE)

    node:setContentSize(g_visible_size)
    ccui.Helper:doLayout(node)

    if rtn_msg.jiesan_detail then
        node:seekNode("dijiju"):setString("中途解散")
    else
        node:seekNode("dijiju"):setString("第"..rtn_msg.cur_ju.."局")
    end
    self.jushu     = rtn_msg.cur_ju
    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()) .. "斗地主"..self.desk.."房第"..rtn_msg.cur_ju.."局切磋详情:\n"
    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        if not self.player_ui[play_index] then
            gt.uploadErr('ddz result peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end
        local player_id   = self.player_ui[play_index].user and self.player_ui[play_index].user.user_id or ''
        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''

        copy_str = copy_str.."选手号:"..player_id.."  名字:"
        copy_str = copy_str..player_name.."  成绩:"..v.score.."\n"
    end
    if self.is_playback then
        log(self.log_data_id)
        node:seekNode("huifangma"):setString("安全码:"..self.log_data_id)
    else
        node:seekNode("huifangma"):setString("安全码:"..rtn_msg.log_data_id)
    end
    commonlib.shareResult(node, copy_str, g_game_name.."房号:"..self.desk, self.desk, self.copy)

    for i, v in ipairs(self.hand_card_list) do
        for _, vv in ipairs(v) do
            if vv then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[i] = {}
    end

    node:seekNode("btn-jxyx"):addClickEventListener(function()
        print("open continue")

        node:removeFromParent(true)

        if self.rang_lab then
            self.rang_lab:setString(0)
            self.rang_lab2:setString(1)
            self.rang_pai = nil
        end

        self.beishu_lbl.bs = 1
        self.beishu_lbl:setString(1)

        for play_index = 1, 3 do
            self.player_ui[play_index]:getChildByName("Zhang"):setVisible(false)
            self.player_ui[play_index]:getChildByName("txkuang"):loadTexture("ui/dt_ddz_play/dt_ddz_play_headBg.png")
            self.player_ui[play_index]:getChildByName("Text_2"):setColor(cc.c3b(255, 255, 255))
            if play_index ~= 1 then
                self.left_lbl[play_index]:setFntFile("ui/dt_ddz_play/fnt/normal_num-export.fnt")
            end
        end

        for ii, vv in ipairs(self.last_out_card) do
            if vv ~= 0 then
                for _, v in ipairs(vv) do
                    v:removeFromParent(true)
                end
                self.last_out_card[ii] = 0
            end
        end

        for _, v in ipairs(self.qie_card_list or {}) do
            if v then
                v:removeFromParent(true)
            end
        end
        self.qie_card_list = nil
        self.sel_list      = {}

        self.qiepai:setVisible(true)

        for _, v in ipairs(self.player_ui) do
            if v.coin then
                v:seekNode("lab-jinbishu"):setString(commonlib.goldStr(v.coin + 1000))
            end

            if v.jiabei_sp then
                v.jiabei_sp:removeFromParent(true)
                v.jiabei_sp = nil
            end
        end

        for _, v in ipairs(self.left_lbl) do
            if v then
                v:setString(0)
            end
        end

        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)

        self.panOprCard:setVisible(false)
        self.panJiaoFen:setVisible(false)

        if not self.is_playback then
            if not rtn_msg.results then
                self.quan_lbl:setString("剩余" .. (self.total_ju - rtn_msg.cur_ju - 1) .. "局")
                self:sendReady()
                AudioManager:playDWCBgMusic("sound/ddz_bgplay.mp3")
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
    end)

    if rtn_msg.results then
        local btJXYX = node:seekNode("btn-jxyx")
        btJXYX:loadTextureNormal("ui/qj_ddz_final/dt_ddz_finalone_goon1.png")
        btJXYX:loadTexturePressed("ui/qj_ddz_final/dt_ddz_finalone_goon1.png")
    end

    local chun_bs = 0
    if rtn_msg.chuntian == 1 or rtn_msg.chuntian == true then
        chun_bs = 2
    end

    if self.people_num == 2 then
        local rang_bs = 1
        if self.rang_pai and self.rang_pai > 0 then
            rang_bs = math.pow(2, self.rang_pai)
        end
        node:seekNode("shuoming"):setString("结算：" .. " 让牌" .. (self.rang_pai or 0) .. " 炸弹" .. (rtn_msg.zhadan or 0) .. "个" .. " 春天x" .. (chun_bs / 2) .. ".")
        node:seekNode("shuoming_0"):setString("玩法："..self.people_num.."人斗地主 "..self.total_ju.."局 "..self.ddzwanfa_str.. "让牌"..self.rpfd .. "倍封顶.")
    else
        node:seekNode("shuoming"):setString("结算：" .. " 炸弹" .. (rtn_msg.zhadan or 0) .. "个" .. " 春天x" .. (chun_bs / 2) .. " 叫分x" .. rtn_msg.call_score .. ".")
        node:seekNode("shuoming_0"):setString("玩法："..self.people_num.."人斗地主 "..self.total_ju.."局 "..self.ddzwanfa_str..".")
    end

    table.sort(rtn_msg.players, function(x, y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)

    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        local sortIndex  = self:setResultIndex(play_index)
        local play       = tolua.cast(node:seekNode("play"..sortIndex), "ccui.ImageView")

        local player_head = self.player_ui[play_index].user and self.player_ui[play_index].user.photo or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(player_head), g_wxhead_addr)

        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        if pcall(commonlib.GetMaxLenString, player_name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(commonlib.GetMaxLenString(player_name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(player_name)
        end
        -- tolua.cast(ccui.Helper:seekWidgetByName(play, "id"), "ccui.Text"):setString(self.player_ui[play_index].user.user_id)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "benju"), "ccui.Text"):setString(v.score)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "zhadanshu"), "ccui.Text"):setString(self.ddzdifen)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "shengyushu"), "ccui.Text"):setString("x"..self.beishu_lbl.bs)
        if ccui.Helper:seekWidgetByName(play, "PFN") then
            ccui.Helper:seekWidgetByName(play, "PFN"):setVisible(false)
        else
            local version = gt.getVersion()
            log('PFN' .. version)
            gt.uploadErr('PFN' .. version)
        end
        if play_index ~= self.banker then
            ccui.Helper:seekWidgetByName(play, "dizhu"):setVisible(false)
        end

        if v.index == self.my_index then
            if v.score >= 0 then
                node:seekNode("win"):loadTexture("ui/qj_ddz_final/dt_ddz_finalone_winBg.png")
                node:seekNode("Image_31"):loadTexture("ui/qj_ddz_final/dt_ddz_finalone_winTitleBg.png")
            else
                node:seekNode("win"):loadTexture("ui/qj_ddz_final/dt_ddz_finalone_failBg.png")
                node:seekNode("Image_31"):loadTexture("ui/qj_ddz_final/dt_ddz_finalone_failTitleBg.png")
            end
            ccui.Helper:seekWidgetByName(play, "name"):setColor(cc.c3b(255, 255, 255))
            ccui.Helper:seekWidgetByName(play, "zhadanshu"):setColor(cc.c3b(255, 255, 255))
            ccui.Helper:seekWidgetByName(play, "shengyushu"):setColor(cc.c3b(255, 255, 255))
            ccui.Helper:seekWidgetByName(play, "benju"):setColor(cc.c3b(255, 255, 255))
        end

        tolua.cast(ccui.Helper:seekWidgetByName(play, "quanguan"), "ccui.ImageView"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "baopei"), "ccui.ImageView"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "ht10"), "ccui.ImageView"):setVisible(false)

        if v.jiabei == 1 then
            local pos = cc.p(ccui.Helper:seekWidgetByName(play, "name"):getPosition())
            local sp  = cc.Sprite:create("ui/ddz/jiabei.png")
            sp:setScale(0.7)
            sp:setPosition(cc.p(pos.x + 100, pos.y))
            play:addChild(sp)
        end

        self.player_ui[play_index].coin = v.total_score or (self.player_ui[play_index].coin + v.score)

        v.out_cards             = v.out_cards or {}
        local hand_index        = #v.out_cards + 1
        v.out_cards[hand_index] = v.hands

    end

    if #rtn_msg.players < 3 then
        node:seekNode("play3"):setVisible(false)
    end
end

function DDZScene:initVIPResultUI(rtn_msg, jiesan_detail, club_name, log_ju_id, gmId)
    local result_node = self:getChildByTag(SCENE_TAG.RESULT_NODE)
    if result_node then
        result_node:removeFromParent(true)
    end

    local node = tolua.cast(cc.CSLoader:createNode("ui/DDZdjs.csb"), "ccui.Widget")
    self:addChild(node, 100000)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    local max_score = 0
    for _, v in ipairs(rtn_msg) do
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

    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()) .. "斗地主切磋详情:\n"
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

    node:seekNode("exit"):addClickEventListener(function()
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
    end)
    node:seekNode("btn-exit"):addClickEventListener(function()
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
    end)
    if self.is_playback then
        tolua.cast(node:seekNode("lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分", self.create_time))
    else
        tolua.cast(node:seekNode("lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分", os.time()))
    end

    if not club_name then
        tolua.cast(node:seekNode("lab-fangjianhao"), "ccui.Text"):setString("房间号："..self.desk)
    else
        if pcall(commonlib.GetMaxLenString, club_name, 12) then
            tolua.cast(node:seekNode("lab-fangjianhao"), "ccui.Text"):setString(commonlib.GetMaxLenString(club_name, 12) .. "的亲友圈")
        else
            tolua.cast(node:seekNode("lab-fangjianhao"), "ccui.Text"):setString(club_name .. "的亲友圈")
        end
        if self.club_index then
            if pcall(commonlib.GetMaxLenString, club_name, 12) then
                tolua.cast(node:seekNode("lab-fangjianhao"), "ccui.Text"):setString(commonlib.GetMaxLenString(club_name, 12) .. "亲友圈" .. self.club_index .. '号')
            else
                tolua.cast(node:seekNode("lab-fangjianhao"), "ccui.Text"):setString(club_name .. "亲友圈" .. self.club_index .. '号')
            end
        end
    end

    table.sort(rtn_msg, function(x, y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg) do
        local play_index = self:indexTrans(v.index)
        local sortIndex  = self:setResultIndex(play_index)
        local play       = tolua.cast(node:seekNode("play"..sortIndex), "ccui.ImageView")

        local player_head = self.player_ui[play_index].user and self.player_ui[play_index].user.photo or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(player_head), g_wxhead_addr)

        local player_name = self.player_ui[play_index].user and self.player_ui[play_index].user.nickname or ''
        if pcall(commonlib.GetMaxLenString, player_name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(commonlib.GetMaxLenString(player_name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(player_name)
        end

        local player_id = self.player_ui[play_index].user and self.player_ui[play_index].user.user_id or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-id"), "ccui.Text"):setString("ID:"..player_id)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "benju"), "ccui.Text"):setString(v.total_score)

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
        node:seekNode("play3"):setVisible(false)
    end

    local btn_jiesan = node:seekNode("btn-jsxq")
    if jiesan_detail then
        btn_jiesan:setVisible(true)
        btn_jiesan:addClickEventListener(function()
            local JiesanLayer = require("scene.JiesanLayer")
            local jiesan      = JiesanLayer:create(jiesan_detail, self.desk, gmId)
            self:addChild(jiesan, 100001)
        end)
    else
        btn_jiesan:setVisible(false)
    end

    local btnOpenwx = node:seekNode("btn-openwx")
    if btnOpenwx then
        btnOpenwx:addClickEventListener(function()
            gt.openApp("weixin")
        end)
    else
        local version = gt.getVersion()
        log('btnOpenwx' .. version)
        gt.uploadErr('btnOpenwx' .. version)
    end

    -- local copy_btn = ccui.Button:create()
    -- copy_btn:loadTextureNormal("ui/qj_majiang/dt/com_fzzj.png")
    -- copy_btn:addClickEventListener(function()
    --         AudioManager:playPressSound()
    --         print(copy_str)
    --         if ymkj.copyClipboard then
    --             ymkj.copyClipboard(copy_str)
    --         end
    --         commonlib.showLocalTip("已复制战绩，可打开微信分享")
    -- end)
    -- copy_btn:setPosition(cc.p(g_visible_size.width-60, 60))
    -- node:addChild(copy_btn)

end

function DDZScene:checkIpWarn(is_click_see)
    if self.is_playback then return end

    self:runAction(cc.CallFunc:create(function()

        local tips = cc.Director:getInstance():getRunningScene():getChildByTag(SCENE_TAG.TIPS_NODE)
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
            -- self:sendReady()
            return
        end

        self:disapperClubInvite(true)
        -- local GpsMap = require('scene.GpsMap')
        -- GpsMap.showMap(self,people_num,is_click_see)
        local node = tolua.cast(cc.CSLoader:createNode("ui/"..people_num.."dizhi.csb"), "ccui.Widget")
        cc.Director:getInstance():getRunningScene():addChild(node, 999999, SCENE_TAG.TIPS_NODE)

        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

        ccui.Helper:doLayout(node)

        local bg = node:seekNode("bg")
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
            local play_ui = node:seekNode("play"..math.min(i, people_num))
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

                for _, ii in ipairs(neighbor[i] or {}) do
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
                            node:seekNode("xiangju"..i..neighbor_index):setString(strPrefix.."相距5千米以上"..strIpWarn)
                        else
                            node:seekNode("xiangju"..i..neighbor_index):setString(strPrefix.."相距约"..dis.."米"..strIpWarn)
                        end
                        node:seekNode("line"..i..neighbor_index):setVisible(true)
                        if strIpWarn ~= "" or dis <= 300 then
                            node:seekNode("xiangju"..i..neighbor_index):setColor(cc.c3b(228, 81, 54))
                            node:seekNode("line"..i..neighbor_index):loadTexture("ui/xclub/1-fs8.png")
                        else
                            node:seekNode("xiangju"..i..neighbor_index):setColor(cc.c3b(17, 200, 8))
                            node:seekNode("line"..i..neighbor_index):loadTexture("ui/xclub/2-fs8.png")
                        end
                    else
                        node:seekNode("xiangju"..i..neighbor_index):setString("")
                        node:seekNode("line"..i..neighbor_index):setVisible(false)
                    end
                end
            elseif neighbor[i] then
                for _, ii in ipairs(neighbor[i] or {}) do
                    local neighbor_index = math.min(ii, people_num)
                    node:seekNode("xiangju"..i..neighbor_index):setString("")
                    node:seekNode("line"..i..neighbor_index):setVisible(false)
                end
                play_ui:setVisible(false)
            end
        end

        if is_click_see then
            node:seekNode("btn-butongyi"):setTouchEnabled(false)
            node:seekNode("btn-butongyi"):setBright(false)
            node:seekNode("btn-butongyi"):setVisible(false)
            node:seekNode("btn-tongyijiesan"):setVisible(false)
        else
            node:addBtListener("btn-butongyi", function()
                AudioManager:playPressSound()
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
            end)
        end

        node:addBtListener("btn-tongyijiesan", function()
            AudioManager:playPressSound()
            node:removeFromParent(true)
            -- 继续游戏
            if not is_click_see then
                -- if parent.piaoniao_mode == 0 then
                self:sendReady()
                -- else
                --     parent.piaoniao_panel:setVisible(true)
                --     parent.piaoniao_panel:setEnabled(true)
                -- end
            end
        end)

        if is_click_see then
            node:addBtListener("Panel_1", function()
                AudioManager:playPressSound()
                node:removeFromParent(true)
            end)
        end

    end))
end

function DDZScene:playBombAni(direct)
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
    sprEmotion:runAction(cc.Sequence:create(moveto1, fadeout1, callfunc))
end

function DDZScene:playRocketAni()
    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/huojian/huojian'
    AudioManager:playDWCSound("sound/game/huojian.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(
        cc.MoveTo:create(1, cc.p(g_visible_size.width / 2, g_visible_size.height)),
        cc.RemoveSelf:create()))
end

function DDZScene:playLianduiAni(direct)
    -- if g_os == "win" then return end
    spineFile = 'ui/qj_ddz_ani/liandui/liandui'
    AudioManager:playDWCSound("sound/game/shunzi.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(0.5)
    local windowSize = cc.Director:getInstance():getWinSize()
    -- skeletonNode:setPosition(cc.p(windowSize.width/2, windowSize.height/2))
    if direct == 2 then
        skeletonNode:setPosition(out_card_pos[direct].x - 70, out_card_pos[direct].y)
    elseif direct == 3 then
        skeletonNode:setPosition(out_card_pos[direct].x + 100, out_card_pos[direct].y)
    else
        skeletonNode:setPosition(out_card_pos[direct].x + 50, out_card_pos[direct].y)
    end
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()))
end

function DDZScene:playShunziAni(direct)
    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/shunzi/longzhou'
    AudioManager:playDWCSound("sound/game/shunzi.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    if direct == 2 then
        skeletonNode:setPosition(out_card_pos[direct].x - 110, out_card_pos[direct].y)
    else
        skeletonNode:setPosition(out_card_pos[direct].x + 80, out_card_pos[direct].y)
    end
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()))
end

function DDZScene:playSpringAni()
    local sp = cc.Sprite:create("ui/dt_ddz_play/dtddz_game_chuntian.png")

    sp:setPosition(cc.p(g_visible_size.width / 2, g_visible_size.height / 2))
    self:addChild(sp, 10000)

    sp:runAction(cc.Sequence:create(cc.DelayTime:create(0.3),
        cc.CallFunc:create(function()
            AudioManager:playDWCSound("sound/game/huojian.mp3")
        end),
        cc.DelayTime:create(0.7), cc.RemoveSelf:create()))

end

function DDZScene:playFeiJiAni()
    -- if g_os == "win" then return end
    local spineFile = 'ui/qj_ddz_ani/feiji/feiji'
    AudioManager:playDWCSound("sound/game/feiji.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(
        cc.MoveTo:create(1, cc.p(0, g_visible_size.height / 2)),
        cc.RemoveSelf:create()))
end

function DDZScene:playWinAni()
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

function DDZScene:playKaiju()
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

function DDZScene:animationWithFile(name, startFrameIndex, endFrameIndex, delay_time)
    local frames = {}
    for i = startFrameIndex, endFrameIndex do
        local texture       = cc.Director:getInstance():getTextureCache():addImage(name..i..".png")
        local texSize       = texture:getContentSize()
        frames[#frames + 1] = cc.SpriteFrame:createWithTexture(texture, cc.rect(0, 0, texSize.width, texSize.height))
    end
    local animation = cc.Animation:createWithSpriteFrames(frames, delay_time or 0.5)
    return animation
end

function DDZScene:setClubInvite()
    local btnClubInvite = self:seekNode("btn-clubinvite")
    if btnClubInvite then
        btnClubInvite:setVisible(not self.is_game_start and self.qunzhu == 1)
        if self.qunzhu == 1 then
            -- 邀请亲友圈成员
            btnClubInvite:addClickEventListener(function()
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
            end)
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

-- 滑动手牌时若存在顺子则将顺子选择出来
-- 这个方法不完善，还需改进优化
function DDZScene:shunziChoose(list, v)
    self.sel_pailist = {}
    -- 把牌值换为1-15
    local count = 0
    for i = 1, #list do
        self.sel_pailist[i] = list[i] % 16
    end
    -- 牌值冒泡排序
    for i = 1, #self.sel_pailist do
        for j = 1, #self.sel_pailist - i do
            if self.sel_pailist[j] > self.sel_pailist[j + 1] then
                temp                    = self.sel_pailist[j]
                self.sel_pailist[j]     = self.sel_pailist[j + 1]
                self.sel_pailist[j + 1] = temp
            end
        end
    end
    -- 去掉重复的牌值
    for i = 1, 2 do
        for j = 1, #self.sel_pailist - 1 do
            if self.sel_pailist[j] == self.sel_pailist[j + 1] then
                table.remove(self.sel_pailist, j + 1)
            end
        end
        for i = 1, #self.sel_pailist do
            if self.sel_pailist[i] == 15 or self.sel_pailist[i] == 2 or self.sel_pailist[i] == 14 then
                table.remove(self.sel_pailist, i)
            end
        end
    end
    -- 把A的牌值从1换为14
    if self.sel_pailist and self.sel_pailist[1] and self.sel_pailist[1] == 1 then
        table.remove(self.sel_pailist, 1)
        table.insert(self.sel_pailist, 14)
    end
    -- 判断所选牌顺子的长度，count为1则顺子长度为5，count为2则顺子长度为6
    if #self.sel_pailist >= 5 then
        for j = 1, #self.sel_pailist - 4 do
            if self.sel_pailist[j + 4] - self.sel_pailist[j] == 4 then
                count = count + 1
            end
        end
    end
    -- 借用提示选择顺子的方式，选择出所选牌中的顺子
    self.cur_hinti     = 0
    self.hint_listi    = {}
    local last_id_list = {}
    if count == 1 then
        last_id_list = {3, 4, 5, 6, 7}
    elseif count == 2 then
        last_id_list = {3, 4, 5, 6, 7, 8}
    elseif count == 3 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9}
    elseif count == 4 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9, 10}
    elseif count == 5 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9, 10, 11}
    elseif count == 6 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
    elseif count == 7 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    elseif count == 8 then
        last_id_list = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
    else
        last_id_list = {3, 4, 5, 6, 7}
    end
    -- 第4个参数为true时，则与last_id_list值相等时也会被选择
    DDZLogic:SearchOutCard(list, last_id_list, self.hint_listi, true)
    local tishi_cards = nil
    if self.hint_listi and #self.hint_listi > 0 then
        self.cur_hinti = (self.cur_hinti or 0) + 1
        if self.cur_hinti > #self.hint_listi then
            self.cur_hinti = 1
        end
        tishi_cards = self.hint_listi[self.cur_hinti]
    end
    if not tishi_cards or #tishi_cards <= 0 then
        v:setPositionY(hand_card_pos[1].y + 30)
    else
        for _, v in ipairs(self.hand_card_list[1]) do
            for cii, cid in ipairs(list) do
                if v.card_id == cid then
                    table.remove(list, cii)
                    v:setPositionY(hand_card_pos[1].y)
                    break
                end
            end
            for _, cid in ipairs(tishi_cards) do
                if v.card_id == cid then
                    list[#list + 1] = cid
                    v:setPositionY(hand_card_pos[1].y + 30)
                    break
                end
            end
        end
    end
end

function DDZScene:setResultIndex(index)
    if self.people_num == 2 then
        if index == 3 then
            index = 2
        end
    end
    return index
end

function DDZScene:setShuoMing(str)
    str                = string.gsub(str, "[.]+", "\n")
    local shuoming     = true
    local btn_shuoming = self.node:seekNode("btn-shuoming")
    local shuoming_lbl = self.node:seekNode("shuomingBg")
    shuoming_lbl:setLocalZOrder(9999)
    shuoming_lbl:setVisible(false)
    local shuoming_txt = self.node:seekNode("shuoming")
    shuoming_txt:setString("斗地主\n"..str)
    btn_shuoming:addClickEventListener(function()
        if shuoming == false then
            shuoming = true
            shuoming_lbl:setVisible(false)
        else
            shuoming = false
            shuoming_lbl:setVisible(true)
        end
    end)
    local shuoming_lbl_size = shuoming_lbl:getContentSize()
    local shuoming_txt_size = shuoming_txt:getContentSize()
    if shuoming_txt_size.height + 20 > shuoming_lbl_size.height then
        shuoming_lbl:setContentSize(cc.size(shuoming_lbl_size.width, shuoming_txt_size.height + 20))
        shuoming_txt:setPositionY(shuoming_txt_size.height + 10)
    end
end

function DDZScene:onRcvClubModify(rtn_msg)
    self:clubRename(rtn_msg)
end

function DDZScene:onRcvReady(rtn_msg)
    local v     = rtn_msg
    local index = self:indexTrans(v.index)
    if self.player_ui[index] then
        self.player_ui[index].coin = v.score
        if self.player_ui[index].user then
            self.player_ui[index].user.u_coin = v.score
        end
        -- if index ~= 1 then
        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
        -- end
        self.player_ui[index]:seekNode("lab-jinbishu"):setString(commonlib.goldStr(v.score + 1000))
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function DDZScene:onRcvLeaveRoom(rtn_msg)
    self:setClubInvite()
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 then
        if self.player_ui[index] then
            commonlib.lixian(self.player_ui[index])
            self.player_ui[index]:setVisible(false)
            self.player_ui[index].coin = nil
            self.player_ui[index].user = nil
            local ipui                 = self:getChildByTag(SCENE_TAG.INPUT_NODE + index)
            if ipui then
                ipui:removeFromParent(true)
            end
            self:checkIpWarn()
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

function DDZScene:onRcvInLine(rtn_msg)
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index])
    end
end

function DDZScene:onRcvOutLine(rtn_msg)
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index], "likai")
    end
end

function DDZScene:onRcvJiesan(rtn_msg)
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

function DDZScene:onRcvApplyJiesan(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, 3)
end

function DDZScene:onRcvApplyJiesanAgree(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, 3)
end

function DDZScene:onRcvDdzTableUserInfo(rtn_msg)
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
        self.player_ui[index]:seekNode("lab-jinbishu"):setString(commonlib.goldStr(v.score + 1000))
        -- if index ~= 1 then
        commonlib.lixian(self.player_ui[index])
        self.player_ui[index]:getChildByName("zhunbei"):setVisible(false)
        -- end
        if head ~= "" then
            self.player_ui[index].head_sp:setVisible(true)
            self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
        else
            self.player_ui[index].head_sp:setVisible(false)
        end

        self:checkIpWarn()
    end
    RoomController:getModel():addPlayer(rtn_msg)
end

function DDZScene:onRcvDdzGameStart(rtn_msg)
    local result_node = self:getChildByTag(SCENE_TAG.RESULT_NODE)
    if result_node then
        result_node:removeFromParent(true)
    end
    self.sel_list = {}
    self.quan_lbl:setVisible(true)
    for i_ui, v_ui in ipairs(self.player_ui) do
        -- if i_ui ~= 1 then
        v_ui:getChildByName("zhunbei"):setVisible(false)
        -- end

        v_ui:getChildByName("Zhang"):setVisible(false)
        v_ui:getChildByName("txkuang"):loadTexture("ui/dt_ddz_play/dt_ddz_play_headBg.png")
        v_ui:getChildByName("Text_2"):setColor(cc.c3b(255, 255, 255))
        if i_ui ~= 1 then
            self.left_lbl[i_ui]:setFntFile("ui/dt_ddz_play/fnt/normal_num-export.fnt")
        end

        if v_ui.jiabei_sp then
            v_ui.jiabei_sp:removeFromParent(true)
            v_ui.jiabei_sp = nil
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
        gt.uploadErr('ddz start peopleNumErroJoinRoomAgain')
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

    if rtn_msg.cur_ju then
        self.quan_lbl:setString("剩余" .. (rtn_msg.cur_ju + 1) .. "局")
    end

    if not self.jushu then
        self:playKaiju()
    end

    for i, v in ipairs(self.wenhao_list) do
        v:setVisible(false)
    end

    for i, v in ipairs(self.hand_card_list) do
        for _, vv in ipairs(v) do
            if vv then
                vv:removeFromParent(true)
            end
        end
        self.hand_card_list[i] = {}
    end
    if self.people_num == 2 then
        if self.left_show == 1 then
            if self.my_index == 1 then
                self:setSyps(2, 17)
            else
                self:setSyps(3, 17)
            end
        end
    else
        if self.left_show == 1 then
            self:setSyps(2, 17)
            self:setSyps(3, 17)
        end
    end

    self.must_san = nil
    if rtn_msg.cards and #rtn_msg.cards > 0 then
        DDZLogic:sortDESC(rtn_msg.cards)
        local wang_count = 0
        local er_count   = 0
        for _, v in ipairs(rtn_msg.cards) do
            if v >= 78 then
                wang_count = wang_count + 1
            elseif v % 16 == 2 then
                er_count = er_count + 1
            end
        end
        if wang_count == 2 or er_count == 4 then
            self.must_san = true
        end
    end

    local direct_list = {1, 2}
    if self.people_num == 3 then
        direct_list[3] = 3
    else
        if self.my_index == 2 then
            direct_list[2] = 3
        end
    end
    for _, k in ipairs(direct_list) do
        local scal       = hand_card_scale[k]
        if k == 1 and self.isRetroCard then
            scal = 1.4
        end
        local pos_margin = handMarginX
        if k ~= 1 then
            pos_margin = 0
        end

        for i = 1, 17 do
            self.hand_card_list[k][i] = self:getCardById(1, true)
            if k == 1 and rtn_msg.cards and rtn_msg.cards[i] then
                self.hand_card_list[k][i].card_id = rtn_msg.cards[i]
            end
            self.hand_card_list[k][i]:setPosition(cc.p(g_visible_size.width * 0.5, g_visible_size.height * 0.5))
            self.node:addChild(self.hand_card_list[k][i], 999)
            local desPos = self:calHandCardPos(k, 17, i)
            self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.DelayTime:create(i * 0.075), cc.Show:create(), cc.CallFunc:create(function()
                AudioManager:playDWCSound("sound/m_sendcard.mp3")
            end), cc.Spawn:create(cc.ScaleTo:create(0.075, scal), cc.MoveTo:create(0.075, desPos)), cc.CallFunc:create(function()
                if k == 1 and rtn_msg.cards and rtn_msg.cards[i] then
                    self.hand_card_list[k][i].card = self:getCardById(rtn_msg.cards[i])
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

    if self.rang_lab then
        self.rang_pai = nil
        self.rang_lab:setString(0)
    end

    local index = self:indexTrans(rtn_msg.cur_user or 1)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(1.6), cc.CallFunc:create(function()
        if index == 1 then
            if self.people_num == 2 then
                self:showDDZTitle("jiao")
            else
                self:showDDZTitle()
            end
            self:resetOperPanel(1, rtn_msg.msgid)
        end
    end)))
    for ii = 1, self.people_num do
        self:setSyps(ii, 17)
    end
    self:showWatcher(rtn_msg.time or 15, index)

    if self.total_ju == 1 and rtn_msg.log_ju_id then
        gt.addMissJuId(rtn_msg.log_ju_id)
    end
end

function DDZScene:onRcvDdzJoinRoomAgain(rtn_msg)
    self:unregisterNetCmd()
    self:unregisterEvent()
    self:unregisterEventListener()
    AudioManager:stopPubBgMusic()
    if (not rtn_msg.errno or rtn_msg.errno == 0) and rtn_msg.room_id ~= 0 then
        dump(rtn_msg)
        GameController:registerEventListener()
        local ddz_scene = require("scene.DDZScene")
        local gameScene = cc.Scene:create()
        gameScene:addChild(ddz_scene:create(rtn_msg))
        cc.Director:getInstance():replaceScene(gameScene)
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

function DDZScene:onRcvDdzCallScore(rtn_msg)
    local index  = self:indexTrans(rtn_msg.index)
    local prefix = self:getSoundPrefix(index)
    local fix    = ".mp3"
    if prefix == "women" then
        fix = "-0.mp3"
    end
    if rtn_msg.score == 0 then
        AudioManager:playDWCSound("sound/"..prefix.. "/bujiao"..fix)
        self:showOutJiaofenAni(rtn_msg.score, index)
    else
        AudioManager:playDWCSound("sound/"..prefix.. "/"..rtn_msg.score.."fen"..fix)
        if self.is_playback then
            self:showOutJiaofenAni(rtn_msg.score, index)
        else
            if rtn_msg.score ~= 3 and rtn_msg.score ~= 10 then
                self:showOutJiaofenAni(rtn_msg.score, index)
            end
        end
    end
    if rtn_msg.cur_score > 0 then
        self.beishu_lbl.bs = rtn_msg.cur_score
        self.jiaofenshu    = rtn_msg.cur_score
        self.beishu_lbl:setString(rtn_msg.cur_score)
    end
    if rtn_msg.next_index and rtn_msg.next_index >= 1 and rtn_msg.next_index <= 3 then
        local next_index = self:indexTrans(rtn_msg.next_index or 1)
        if next_index == 1 then
            self:showDDZTitle()
            self:resetOperPanel(rtn_msg.cur_score + 1, rtn_msg.msgid)
        end
        self:showWatcher(rtn_msg.time or 15, next_index)
    else
        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)
    end
end

function DDZScene:onRcvDdzjiaBen(rtn_msg)
    local index  = self:indexTrans(rtn_msg.index)
    local prefix = self:getSoundPrefix(index)
    local fix    = ".mp3"
    if prefix == "women" then
        fix = "-0.mp3"
    end

    if rtn_msg.typ == 0 then
        AudioManager:playDWCSound("sound/ddz_music/"..prefix.. "/ddz_opt_6"..fix)
    elseif rtn_msg.typ == 1 then
        AudioManager:playDWCSound("sound/ddz_music/"..prefix.. "/ddz_opt_5"..fix)
        local sp = cc.Sprite:create("ui/ddz/jiabei.png")
        sp:setScale(0.7)
        sp:setPosition(self.player_ui[index].jiabei_pos)
        sp:setLocalZOrder(9000)
        self.node:addChild(sp)
        self.player_ui[index].jiabei_sp = sp
    end

    if rtn_msg.next_index and rtn_msg.next_index >= 1 and rtn_msg.next_index <= 3 then
        local next_index = self:indexTrans(rtn_msg.next_index or 1)
        if next_index == 1 then
            self:showDDZTitle("jia")
            self:resetOperPanel(5, rtn_msg.msgid)
        end
        self:showWatcher(rtn_msg.time or 15, next_index)
    else
        if self.banker == 1 then
            self:resetOperPanel(100, rtn_msg.msgid)
        end
        self:showWatcher(rtn_msg.time or 15, self.banker)
    end
end

function DDZScene:onRcvDdzCallHost(rtn_msg)
    local index  = self:indexTrans(rtn_msg.index)
    local prefix = self:getSoundPrefix(index)
    local fix    = ".mp3"
    if prefix == "women" then
        fix = "-0.mp3"
    end
    if rtn_msg.call == 0 then
        AudioManager:playDWCSound("sound/"..prefix.. "/bujiao"..fix)
        self:showQiangAni(rtn_msg.call, index)
    elseif rtn_msg.call == 1 then
        AudioManager:playDWCSound("sound/"..prefix.. "/jiaodizhu"..fix)
        self:showQiangAni(rtn_msg.call, index)
    end
    if rtn_msg.qiang_cishu then
        self.beishu_lbl.bs = math.pow(2, rtn_msg.qiang_cishu)
        self.beishu_lbl:setString(self.beishu_lbl.bs)
        if rtn_msg.qiang_cishu > 0 then
            self.rang_lab:setString(rtn_msg.qiang_cishu)
            self.rang_lab2:setString(1)
            self.rang_pai = rtn_msg.qiang_cishu
        end
    end
    if rtn_msg.next_index and rtn_msg.next_index >= 1 and rtn_msg.next_index <= 3 then
        local next_index = self:indexTrans(rtn_msg.next_index or 1)
        if not self.is_playback then
            if next_index == 1 then
                if rtn_msg.call == 0 then
                    self:showDDZTitle("jiao")
                    self:resetOperPanel(1, rtn_msg.msgid)
                else
                    self:showDDZTitle("qiang")
                    self:resetOperPanel(3, rtn_msg.msgid)
                end
            end
        end
        self:showWatcher(rtn_msg.time or 15, next_index)
    else
        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)
    end
end

function DDZScene:onRcvDdzQiangHost(rtn_msg)
    local index  = self:indexTrans(rtn_msg.index)
    local prefix = self:getSoundPrefix(index)
    local fix    = ".mp3"
    if prefix == "women" then
        fix = "-0.mp3"
    end
    if rtn_msg.qiang == 0 then
        AudioManager:playDWCSound("sound/ddz_music/"..prefix.. "/ddz_opt_4"..fix)
        self:showQiangAni(rtn_msg.qiang + 10, index)
    elseif rtn_msg.qiang == 1 then
        AudioManager:playDWCSound("sound/ddz_music/"..prefix.. "/ddz_opt_3"..fix)
        self:showQiangAni(rtn_msg.qiang + 10, index)
    end
    if rtn_msg.qiang_cishu then
        if rtn_msg.beishu == 0 then
            self.beishu_lbl.bs = 1
        else
            self.beishu_lbl.bs = rtn_msg.beishu
        end
        self.rang_lab2:setString(rtn_msg.beishu)
        self.beishu_lbl:setString(self.beishu_lbl.bs)
        if rtn_msg.qiang_cishu > 0 then
            self.rang_lab:setString(rtn_msg.qiang_cishu)
            self.rang_pai = rtn_msg.qiang_cishu
        end
    end
    if rtn_msg.next_index and rtn_msg.next_index >= 1 and rtn_msg.next_index <= 3 then
        local next_index = self:indexTrans(rtn_msg.next_index or 1)
        if not self.is_playback then
            if next_index == 1 then
                self:showDDZTitle("qiang")
                self:resetOperPanel(3, rtn_msg.msgid)
            end
        end
        self:showWatcher(rtn_msg.time or 15, next_index)
    else
        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)
    end
end

function DDZScene:onRcvDdzShowBanker(rtn_msg)
    self.must_san = nil

    local k     = self:indexTrans(rtn_msg.host_id)
    self.banker = k
    self.player_ui[self.banker]:getChildByName("Zhang"):setVisible(true)
    if self.is_playback and self.banker ~= 1 then
        self.player_ui[self.banker]:getChildByName("Zhang"):getChildByName("dizhu"):setVisible(false)
    end
    self.player_ui[self.banker]:getChildByName("txkuang"):loadTexture("ui/dt_ddz_play/dizhu-fs8.png")
    self.player_ui[self.banker]:getChildByName("Text_2"):setColor(cc.c3b(252, 235, 180))
    if self.banker ~= 1 then
        self.left_lbl[self.banker]:setFntFile("ui/dt_ddz_play/fnt/dizhu_num-export.fnt")
    end

    local card_list = {}

    self.qiepai:setVisible(false)
    self.qie_card_list = {}
    local posOfTip     = cc.p(self.imageTip:getPosition())
    local sizeOfTip    = self.imageTip:getContentSize()
    local iniPosX      = posOfTip.x - sizeOfTip.width / 2 + 400
    local posY         = posOfTip.y - sizeOfTip.height + 25
    local qieScale     = 0.28
    if self.isRetroCard then
        qieScale = 0.45
    end
    for i, v in ipairs(rtn_msg.bank_card) do
        card_list[i]          = v
        self.qie_card_list[i] = self:getCardById(1, true)
        self.qie_card_list[i]:setPosition(cc.p(g_visible_size.width * 0.73, g_visible_size.height * 0.92))
        self.node:addChild(self.qie_card_list[i], 998)

        self.qie_card_list[i].card = self:getCardById(v)
        self.qie_card_list[i].card:setPosition(cc.p(self.qie_card_list[i]:getContentSize().width / 2, self.qie_card_list[i]:getContentSize().height / 2))
        self.qie_card_list[i]:addChild(self.qie_card_list[i].card)
        self.qie_card_list[i].card:setVisible(false)
        self.qie_card_list[i].card:setVisible(true)
        self.qie_card_list[i]:setScale(qieScale)
        self.qie_card_list[i]:setPosition(cc.p(iniPosX - 59 + 50 * i, posY + 10))
        AudioManager:playDWCSound("sound/m_turncard.mp3")
    end

    if k == 1 then
        local count = #card_list
        -- if self.is_playback then
        --     for j, v in ipairs(self.hand_card_list[k]) do
        --         card_list[count + j] = v.card_id
        --         v:removeFromParent(true)
        --     end
        --     DDZLogic:sortDESC(card_list)
        --     self.hand_card_list[k] = {}
        -- else
        --     for j, v in ipairs(self.hand_card_list[1]) do
        --         card_list[count + j] = v.card_id
        --         v:removeFromParent(true)
        --     end
        --     DDZLogic:sortDESC(card_list)
        --     self.hand_card_list[1] = {}
        -- end
        for j, v in ipairs(self.hand_card_list[k]) do
            card_list[count + j] = v.card_id
            v:removeFromParent(true)
        end
        DDZLogic:sortDESC(card_list)
        self.hand_card_list[k] = {}
        count                  = #card_list
        local scal             = hand_card_scale[k]
        if self.isRetroCard then
            scal = 1.4
        end
        for i, v in ipairs(card_list) do
            local desPos                      = self:calHandCardPos(k, count, i)
            self.hand_card_list[k][i]         = self:getCardById(1, true)
            self.hand_card_list[k][i].card_id = v
            self.hand_card_list[k][i]:setPosition(desPos)
            self.hand_card_list[k][i]:setScale(scal)
            self.node:addChild(self.hand_card_list[k][i], 997)

            self.hand_card_list[k][i].card = self:getCardById(v)
            self.hand_card_list[k][i].card:setPosition(cc.p(self.hand_card_list[k][i]:getContentSize().width / 2, self.hand_card_list[k][i]:getContentSize().height / 2))
            self.hand_card_list[k][i]:addChild(self.hand_card_list[k][i].card)

            if v == rtn_msg.bank_card[1] or v == rtn_msg.bank_card[2] or v == rtn_msg.bank_card[3] then
                self.sel_list[#self.sel_list + 1] = v
                self.hand_card_list[k][i]:setPositionY(hand_card_pos[1].y + 30)
                self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function ()
                    for i, v in ipairs(self.hand_card_list[1]) do
                        for cii, cid in ipairs(self.sel_list) do
                            if v.card_id == cid then
                                table.remove(self.sel_list, cii)
                                v:setPositionY(hand_card_pos[1].y)
                                break
                            end
                        end
                    end
                end)))
            end
        end
        -- 确定地主后地主牌上显示标识
        self.dizhupai = cc.Sprite:create("ui/qj_room/Card_Dizhu.png")
        self.hand_card_list[k][count]:addChild(self.dizhupai)
        if self.isRetroCard then
            self.dizhupai:setPosition(cc.p(40, 65))
        else
            self.dizhupai:setPosition(cc.p(60, 100))
        end
    else
        if self.is_playback then
            local count = #card_list
            for j, v in ipairs(self.hand_card_list[k]) do
                card_list[count + j] = v.card_id
                v:removeFromParent(true)
            end
            DDZLogic:sortDESC(card_list)
            self.hand_card_list[k] = {}
            count                  = #card_list
            local scal             = 0.5
            for i, v in ipairs(card_list) do
                local desPos                      = self:calPlayBackOutCarPos(k, count, i)
                self.hand_card_list[k][i]         = self:getCardById(1, true)
                self.hand_card_list[k][i].card_id = v
                self.hand_card_list[k][i]:setPosition(desPos)
                self.hand_card_list[k][i]:setScale(scal)
                self.node:addChild(self.hand_card_list[k][i], 997)

                self.hand_card_list[k][i].card = self:getCardById(v)
                self.hand_card_list[k][i].card:setPosition(cc.p(self.hand_card_list[k][i]:getContentSize().width / 2, self.hand_card_list[k][i]:getContentSize().height / 2))
                self.hand_card_list[k][i]:addChild(self.hand_card_list[k][i].card)

                if v == rtn_msg.bank_card[1] or v == rtn_msg.bank_card[2] or v == rtn_msg.bank_card[3] then
                    self.sel_list[#self.sel_list + 1] = v
                    self.hand_card_list[k][i]:setPositionY(hand_card_pos[1].y + 30)
                    self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.MoveTo:create(0.1, desPos)))
                end
            end
            -- 确定地主后地主牌上显示标识
            self.dizhupai = cc.Sprite:create("ui/qj_room/Card_Dizhu.png")
            self.hand_card_list[k][count]:addChild(self.dizhupai)
            if self.isRetroCard then
                self.dizhupai:setPosition(cc.p(40, 65))
            else
                self.dizhupai:setPosition(cc.p(60, 100))
            end
        else
            for i = 18, 20 do
                self.hand_card_list[k][i] = self:getCardById(1, true)
                self.hand_card_list[k][i]:setPosition(cc.p(hand_card_pos[k].x, hand_card_pos[k].y))
                self.node:addChild(self.hand_card_list[k][i], 996)
                self.hand_card_list[k][i]:setScale(hand_card_scale[k])
            end
            for i = 1, 20 do
                self.hand_card_list[k][i]:setTexture("ui/dt_ddz_play/dizhupaibei-fs8.png")
            end
        end
        self:setSyps(k, 20)
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.19), cc.CallFunc:create(function()
        if self.people_num == 2 or rtn_msg.need_jiabei ~= true then
            if self.banker == 1 then
                self:resetOperPanel(100, rtn_msg.msgid)
            end
            self:showWatcher(rtn_msg.time or 15, self.banker)
        else
            local next_index = self.banker + 1
            if next_index > 3 then
                next_index = 1
            end
            if next_index == 1 then
                self:showDDZTitle("jia")
                self:resetOperPanel(5, rtn_msg.msgid)
            end
            self:showWatcher(rtn_msg.time or 15, next_index)
        end
    end)))
end

function DDZScene:onRcvDdzOutCard(rtn_msg)
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setVisible(false)

    local index = self:indexTrans(rtn_msg.index)
    self:setSyps(index, rtn_msg.left_num)
    local next_index = 0
    if rtn_msg.cur_user >= 1 and rtn_msg.cur_user <= 3 then
        next_index = self:indexTrans(rtn_msg.cur_user)
    end

    if index == 1 then
        self:resetOperPanel()
    end

    if type(rtn_msg.out_card_data) == "string" then
        if rtn_msg.out_card_data ~= "" then
            rtn_msg.out_card_data = ymkj.base64Decode(rtn_msg.out_card_data)
            rtn_msg.out_card_data = string.split(rtn_msg.out_card_data, "|")
            for ii, mm in ipairs(rtn_msg.out_card_data) do
                rtn_msg.out_card_data[ii] = 80 + ii * 2 - string.byte(mm)
            end
        else
            rtn_msg.out_card_data = {}
        end
    end

    if not rtn_msg.out_card_data or #rtn_msg.out_card_data == 0 then
        self:showOutCardAni(0, index)
    else
        local card_typ = DDZLogic:GetCardType(rtn_msg.out_card_data)
        local prefix   = self:getSoundPrefix(index)
        if card_typ >= 13 then
            self.beishu_lbl.bs = self.beishu_lbl.bs * 2
            self.beishu_lbl:setString(self.beishu_lbl.bs)
        end

        local fix = ".mp3"
        if prefix == "women" then
            fix = "-0.mp3"
        end
        if card_typ == 14 then
            self:playRocketAni()
            AudioManager:playDWCSound("sound/"..prefix.."/wangzha"..fix)
        elseif card_typ == 13 then
            AudioManager:playDWCSound("sound/"..prefix.."/zhadan"..fix)
            self:playBombAni(index)

        elseif card_typ == 12 then
            AudioManager:playDWCSound("sound/ddz_music/"..prefix.."/sidailiangdui"..fix)
        elseif card_typ == 11 then
            AudioManager:playDWCSound("sound/"..prefix.."/sidaier"..fix)
        elseif card_typ == 10 or card_typ == 9 or card_typ == 8 then
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

        rtn_msg.left_num = rtn_msg.left_num or 17
        local bj_num     = 2
        if self.people_num == 2 and index ~= self.banker then
            bj_num = bj_num + (self.rang_pai or 0)
        end
        if rtn_msg.left_num > 0 then
            if rtn_msg.left_num == 2 then
                self:showBaoTing(index)
                AudioManager:playDWCSound("sound/men/baojing2.mp3")
            elseif rtn_msg.left_num == 1 then
                self:showBaoTing(index)
                AudioManager:playDWCSound("sound/men/baojing1.mp3")
            else
                AudioManager:playDWCSound("sound/m_sendcard.mp3")
            end
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
            -- 地主牌有地主标识
            if self.dizhupai and index == self.banker then
                self.dizhupai:removeFromParent()
            end
            if handCardNum ~= 0 and self.banker == index then
                self.dizhupai = cc.Sprite:create("ui/qj_room/Card_Dizhu.png")
                self.hand_card_list[self.banker][handCardNum]:addChild(self.dizhupai)
                if self.isRetroCard then
                    self.dizhupai:setPosition(cc.p(40, 65))
                else
                    self.dizhupai:setPosition(cc.p(60, 100))
                end
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
                    local desPos = self:calPlayBackOutCarPos(index, handCardNum, i)
                    v:setPosition(desPos)
                end
                -- 地主牌有地主标识
                if self.dizhupai and index == self.banker then
                    self.dizhupai:removeFromParent()
                end
                if handCardNum ~= 0 and self.banker == index then
                    self.dizhupai = cc.Sprite:create("ui/qj_room/Card_Dizhu.png")
                    self.hand_card_list[self.banker][handCardNum]:addChild(self.dizhupai)
                    if self.isRetroCard then
                        self.dizhupai:setPosition(cc.p(40, 65))
                    else
                        self.dizhupai:setPosition(cc.p(60, 100))
                    end
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

            -- if rtn_msg.left_num == bj_num and not self.is_playback then
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
        -- 地主打出的牌有地主标识
        if index == self.banker then
            self.dizhupai2 = cc.Sprite:create("ui/qj_room/Card_Dizhu.png")
            self.last_out_card[index][outCardNum]:addChild(self.dizhupai2)
            if self.isRetroCard then
                self.dizhupai2:setPosition(cc.p(40, 65))
            else
                self.dizhupai2:setPosition(cc.p(60, 100))
            end
        end

    end

    if next_index ~= 0 and self.last_out_card[next_index] ~= 0 then
        for _, v in ipairs(self.last_out_card[next_index]) do
            v:removeFromParent(true)
        end
        self.last_out_card[next_index] = 0
    end

    if next_index ~= 0 and not self.is_playback then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function()
            if next_index == 1 then
                local last_cards = nil -- self:canOutCard(true)
                if last_cards then
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function()
                        self:sendOutCards(last_cards, rtn_msg.msgid)
                    end)))

                elseif self.pre_out_direct and next_index ~= self.pre_out_direct then
                    self:updateHintList()
                    self:resetOperPanel(101, rtn_msg.msgid)
                    self:showWatcher(rtn_msg.time or 15, next_index)
                else
                    self:resetOperPanel(100, rtn_msg.msgid)
                    self:showWatcher(rtn_msg.time or 15, next_index)
                end
            else
                self:showWatcher(rtn_msg.time or 15, next_index)
            end
        end)))
    end
end

function DDZScene:onRcvDdzResult(rtn_msg)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.CallFunc:create(function()
        if self.baoting_img then
            for _, v in pairs(self.baoting_img) do
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

        AudioManager:stopPubBgMusic()

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
            self.beishu_lbl.bs = self.beishu_lbl.bs * 2
            self.beishu_lbl:setString(self.beishu_lbl.bs)
            self:playSpringAni()
        end

        self:showLeftHandCard(msg)

        self.watcher_lab:stopAllActions()
        self.watcher_lab:setVisible(false)

        self:runAction(cc.Sequence:create(cc.DelayTime:create(2.5), cc.CallFunc:create(function()
            self:initResultUI(rtn_msg)
        end)))
    end)))
end

function DDZScene:onRcvSyncClubNotify(rtn_msg)
end

function DDZScene:setSypsVisible(play_index, visible)
    if not left_num then
        return
    end

    local syps = self.left_lbl[play_index]
    if not syps then
        return
    end
    syps:setVisible(visible)
end

function DDZScene:setSyps(play_index, left_num)
    if not left_num then
        return
    end
    if self.left_show ~= 1 or self.is_playback then
        return
    end
    local syps = self.left_lbl[play_index]
    if not syps then
        return
    end
    syps:setString(left_num)
    syps:setVisible(true)
end

function DDZScene:creteNewCard(color, num, showCardBack)
    local colorImgName = "joker"
    if color == 1 then
        colorImgName = "spade"
    elseif color == 2 then
        colorImgName = "heart"
    elseif color == 3 then
        colorImgName = "club"
    elseif color == 4 then
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
    local card       =  nil
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

return DDZScene