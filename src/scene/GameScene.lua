local ErrStrToClient = require('common.ErrStrToClient')
local ErrNo          = require('common.ErrNo')

local GameScene = class("GameScene", function()
    return cc.Layer:create()
end)

local SCENE_TAG = {
    EXIT_NODE   = 4532,
    RESULT_NODE = 10109,
    INPUT_NODE  = 81000,
    TIPS_NODE   = 85001,
}

function GameScene:ctor(param_list)
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()

    self.my_index  = param_list.room_info.index
    self.desk      = param_list.room_id
    self.club_id   = param_list.club_id
    self.ignoreArr = {} -- 屏蔽互动表情的方位

    self.club_id = param_list.room_info.club_id
    self.room_id = param_list.room_id
    gt.setRoomID(self.room_id)
    self.club_name  = param_list.room_info.club_name
    self.room_info  = param_list.room_info
    self.club_index = param_list.room_info.club_index
    self.isJZBQ     = param_list.room_info.isJZBQ

    if param_list.is_playback then
        self.is_playback = param_list.is_playback
        self.order_list  = param_list.order
        self.log_data_id = param_list.log_data_id
        self.create_time = param_list.create_time
    end

    if self.club_id and self.club_name and self.club_index then
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = self.club_id
        gt.setClubID(self.club_id)
    end

    self:createLayerMenu(param_list.room_info)
    self:enableNodeEvents()
end

function GameScene:onEnter()
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
end

function GameScene:onExit()
    gt.removeUnusedRes()

    -- 红包消息分发注销 EventBus
    self:unregisterEvent()

    gt.setRoomID(nil)
end

function GameScene:onRbIsValid(rtn_msg)
    -- 应急处理，防止未收到20002消息 没有显示红包按钮
    if rtn_msg and nil ~= next(rtn_msg) then
        self.btnRedBag:setVisible(true)
    end
end

function GameScene:registerEvent()
    local events = {
        {
            eType = EventEnum.S2C_RB_INFO,
            func  = handler(self, self.onRbIsValid),
        },
    }
    for i, v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function GameScene:unregisterEvent()
    for _, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function GameScene:keypadEvent()
    local function onKeyReleased(keyCode, event)
        if keyCode == cc.KeyCode.KEY_BACK then
            local exit_node = cc.Director:getInstance():getRunningScene():getChildByTag(SCENE_TAG.EXIT_NODE)
            if exit_node then
                exit_node:removeFromParent(true)
                return
            end
            commonlib.showExitTip("您确定要退出游戏？", function(is_ok)
                if is_ok then
                    gt.setLocalString("lan_can_sel", "false")
                    gt.setLocalString("mmmx1", "")
                    gt.setLocalString("mmmx2", "")
                    gt.setLocalString("s1s1s1", "")
                    gt.setLocalString("s2s2s2", "")
                    gt.flushLocal()
                    cc.Director:getInstance():endToLua()
                end
            end)
        elseif keyCode == cc.KeyCode.KEY_MENU then
        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    self.listenerKeyboard = listener
end

function GameScene:registerNetCmd()
    for _, v in pairs(NET_CMDS) do
        gt.addNetMsgListener(v, handler(self, self.onRcvMsg))
    end

    local CUSTOM_LISTENERS = {
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function GameScene:unregisterNetCmd()
    for _, v in pairs(NET_CMDS) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function GameScene:unregisterEventListener()
    self:unregisterNetCmd()

    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    ymkj.setHeartInter(0)
end

function GameScene:sendReady()
    if self.is_playback then
        return
    end
    local input_msg = {
        cmd = NetCmd.C2S_READY,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function GameScene:indexTrans(index)
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

function GameScene:getSoundPrefix(index)
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

function GameScene:animationWithFile(name, startFrameIndex, endFrameIndex, delay_time)
    local frames = {}
    for i = startFrameIndex, endFrameIndex do
        local texture       = cc.Director:getInstance():getTextureCache():addImage(name..i..".png")
        local texSize       = texture:getContentSize()
        frames[#frames + 1] = cc.SpriteFrame:createWithTexture(texture, cc.rect(0, 0, texSize.width, texSize.height))
    end
    local animation = cc.Animation:createWithSpriteFrames(frames, delay_time or 0.5)
    return animation
end

function GameScene:setClubInvite()
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

function GameScene:disapperClubInvite(bForceDiscover)
    local btnClubInvite = self:seekNode("btn-clubinvite")
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
end

function GameScene:setRoomData()
    local roomid             = self:seekNode("roomid")
    local qingyouquanfanghao = self:seekNode("qingyouquanfanghao")
    if self.club_name and self.club_index then
        roomid:setVisible(false)

        qingyouquanfanghao:setVisible(true)
        if pcall(commonlib.GetMaxLenString, self.club_name, 12) then
            qingyouquanfanghao:setString(commonlib.GetMaxLenString(self.club_name, 12) .. self.club_index .. "号[" .. self.desk.. "]")
        else
            qingyouquanfanghao:setString(self.club_name .. self.club_index.."号[" .. self.desk.. "]")
        end
    else
        roomid:setVisible(true)
        roomid:setString(self.desk)

        qingyouquanfanghao:setVisible(false)
    end
end

function GameScene:clubRename(rtn_msg)
    if rtn_msg and self.club_id == rtn_msg.club_id then
        self.club_name = rtn_msg.club_name or self.club_name

        local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
        if ClubInviteLayer then
            ClubInviteLayer:refreshInviteClubName(self.club_name)
        end
    end
end

function GameScene:setOwnerName(room_info)
    if room_info.index ~= 1 and room_info.other and room_info.other[1] then
        self.ownername = room_info.other[1].name
    end
end

function GameScene:setClubEnterMsg()
    if self.club_id and self.club_name and self.club_index then
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = self.club_id
    end
end

function GameScene:onRcvBroad(rtn_msg)
    if not rtn_msg.typ then
        commonlib.showTipDlg(rtn_msg.content or "系统提示")
    end
end

function GameScene:onRcvRoomChat(rtn_msg)
    if rtn_msg.msg_type == 3 then
        EventBus:dispatchEvent(EventEnum.onRcvSpeek, rtn_msg)
    else
        EventBus:dispatchEvent(EventEnum.onPokerSound, rtn_msg)
    end
end

function GameScene:onRcvRoomChatBQ(rtn_msg)
    if (not rtn_msg.index) or (not rtn_msg.to_index) then return end
    local index   = self:indexTrans(rtn_msg.index)
    local toindex = self:indexTrans(rtn_msg.to_index)
    if (not self.player_ui[index]) or (not self.player_ui[toindex]) then return end
    if self.my_index ~= rtn_msg.index and (self.ignoreArr[self.my_index] or self.ignoreArr[rtn_msg.index]) then return end
    commonlib.runInteractiveEffecttwo(self, self.player_ui[index], self.player_ui[toindex], rtn_msg.msg_id, toindex)
end

function GameScene:onRcvSynUserData(rtn_msg)
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

function GameScene:onRcvSynClubNotify(rtn_msg)
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

function GameScene:onRcvApplyJieSan(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, self.people_num)
end

function GameScene:onRcvApplyJieSanAgree(rtn_msg)
    local index      = self:indexTrans(rtn_msg.index)
    rtn_msg.nickname = self.player_ui[index].user.nickname
    rtn_msg.uid      = self.player_ui[index].user.user_id
    rtn_msg.self     = (rtn_msg.index == self.my_index)
    commonlib.showJiesan(self, rtn_msg, self.people_num)
end

return GameScene