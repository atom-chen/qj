-- total error 222 lines ylqj/1.0.21012
--
-- 听牌 x + 0x80
-- 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,万
-- 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,筒
-- 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,条
-- 0x31, 0x32, 0x33, 0x34,东南西北
-- 0x41, 0x42, 0x43 中发白

local AUTO_PLAY = false

local ErrStrToClient = require('common.ErrStrToClient')

local ErrNo = require('common.ErrNo')

local MJCardPosition = require('scene.MJCardPosition')

local MJClickAction = require('scene.MJClickAction')

RecordGameType = require('scene.RecordGameType')

require('scene.RoomInfo')

require('scene.PlayerData')

local MJHeadPos = require('scene.MJHeadPos')

local MJBaseScene = class("MJBaseScene",function()
    return cc.Layer:create()
end)

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
    NetCmd.S2C_APPLY_START,
    NetCmd.S2C_APPLY_START_AGREE,

    NetCmd.S2C_MJ_TABLE_USER_INFO,
    NetCmd.S2C_MJ_GAME_INFO, -- @noused
    NetCmd.S2C_MJ_GAME_START,
    NetCmd.S2C_MJ_JOIN_ROOM_AGAIN,
    NetCmd.S2C_MJ_KOUPAI,
    NetCmd.S2C_MJ_COOL_DOWN,
    NetCmd.S2C_MJ_DRAW_CARD,
    NetCmd.S2C_MJ_OUT_CARD,
    NetCmd.S2C_MJ_CHI_CARD,
    NetCmd.S2C_OPER_OTHER,
    NetCmd.S2C_MJ_PENG,
    NetCmd.S2C_MJ_GANG,
    NetCmd.S2C_MJ_TINGPAI,
    NetCmd.S2C_MJ_DO_PASS_HU,
    NetCmd.S2C_MJ_HU,
    NetCmd.S2C_MJ_CHI_HU,
    NetCmd.S2C_RESULT,
    NetCmd.S2C_LOGIN_OTHER,
    NetCmd.S2C_TUOGUAN,
}

function printErrorMsg(msg)
    logMsg('---------------- 无数据----------------')
    logUp(msg)
    logMsg('---------------- 无数据----------------')
end


function MJBaseScene:registerNetCmd()
    for _, v in pairs(NET_CMDS) do
        gt.addNetMsgListener(v, handler(self, self.onRcvMsg))
    end

    local CUSTOM_LISTENERS = {
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function MJBaseScene:onRcvMsg(rtn_msg)
    local NET_CMD_LISTENERS = {
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvRoomChat),
        [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvRoomChatBQ),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSyncUserData),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_MODIFY]         = handler(self, self.onRcvClubModify),

        [NetCmd.S2C_READY]               = handler(self, self.onRcvReady),
        [NetCmd.S2C_LEAVE_ROOM]          = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_IN_LINE]             = handler(self, self.onRcvInLine),
        [NetCmd.S2C_OUT_LINE]            = handler(self, self.onRcvOutLine),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_APPLY_JIESAN]        = handler(self, self.onRcvApplyJieSan),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]  = handler(self, self.onRcvApplyJieSanAgree),
        [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvApplyStart),
        [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvApplyStartAgree),

        [NetCmd.S2C_MJ_TABLE_USER_INFO]  = handler(self, self.onRcvMjTableUserInfo),
        -- [NetCmd.S2C_MJ_GAME_INFO]        = handler(self, self.onRcvGameInfo),
        [NetCmd.S2C_MJ_GAME_START]       = handler(self, self.onRcvMjGameStart),
        [NetCmd.S2C_MJ_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvMjJoinRoomAgain),
        [NetCmd.S2C_MJ_KOUPAI]           = handler(self, self.onRcvKouPai),

        [NetCmd.S2C_MJ_COOL_DOWN]        = handler(self, self.onRcvMjCoolDown),
        [NetCmd.S2C_MJ_DRAW_CARD]        = handler(self, self.onRcvMjDrawCard),
        [NetCmd.S2C_MJ_OUT_CARD]         = handler(self, self.onRcvMjOutCard),
        [NetCmd.S2C_MJ_CHI_CARD]         = handler(self, self.onRcvMjOutCard),
        [NetCmd.S2C_MJ_PENG]             = handler(self, self.onRcvMjOutCard),
        [NetCmd.S2C_MJ_GANG]             = handler(self, self.onRcvMjOutCard),
        [NetCmd.S2C_OPER_OTHER]          = handler(self, self.onRcvMjOperOther),
        [NetCmd.S2C_MJ_TINGPAI]          = handler(self, self.onRcvMjTingPai),
        [NetCmd.S2C_MJ_DO_PASS_HU]       = handler(self, self.onRcvPassHu),
        [NetCmd.S2C_MJ_HU]               = handler(self, self.onRcvHu),
        [NetCmd.S2C_MJ_CHI_HU]           = handler(self, self.onRcvHu),
        [NetCmd.S2C_RESULT]              = handler(self, self.onRcvReault),
        [NetCmd.S2C_TUOGUAN]             = handler(self, self.onRcvTuoGuan),
    }
    if NET_CMD_LISTENERS[rtn_msg.cmd] then
        if rtn_msg.errno and rtn_msg.errno ~= 0 then
            commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or 'Unknown Error ' .. rtn_msg.errno)
            if ErrNo.APPLY_JIESAN_TIME == rtn_msg.errno or ErrNo.APPLY_JIESAN_STATUS == rtn_msg.errno then
                commonlib.closeJiesan(self)
            end
        else
            NET_CMD_LISTENERS[rtn_msg.cmd](rtn_msg)
        end
    else
        ERROR("net cmd msg not handled!!!", rtn_msg)
    end
end

function MJBaseScene:unregisterNetCmd()
    for _, v in pairs(NET_CMDS) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function MJBaseScene.removeUnusedRes()
    -- if GameGlobal.MjSceneReplaceMJScene then
    --     return
    -- end
    -- gt.removeUnusedRes()
end

function MJBaseScene:ctor(param_list)

    require 'scene.GameSettingDefault'

    local starttime = os.clock()

    self.MJClickAction = MJClickAction

    local speed = cc.UserDefault:getInstance():getStringForKey("TingAutoOutCard", GameSettingDefault.MJ_TING_OUT_SPEED)
    self.TingAutoOutCard = tonumber(speed) --快的用0.3  慢的用0.55

    self.TING_OPERATOR = 7

    self.ZOrder = {}

    self.ZOrder.HAND_CARD_ZORDER_1 = 170
    self.ZOrder.HAND_CARD_ZORDER_2 = 150
    self.ZOrder.HAND_CARD_ZORDER_3 = 150
    self.ZOrder.HAND_CARD_ZORDER_4 = 130
    self.ZOrder.SEND_OUT_CARD_ZORDER = 190

    self.ZOrder.OUT_CARD_ZORDER = 80

    self.ZOrder.DIAN_PAO_ZOREDER = 199
    self.ZOrder.GUO_HU_TAG_ZOREDER    = 190
    self.ZOrder.BEYOND_CARD_ZOREDER   = 200
    self.ZOrder.WANGFA_ZOREDER   = 201

    self:loadMjLogic()

    self.my_index = param_list.room_info.index
    self.desk = param_list.room_id
    self.club_id = param_list.club_id
    self.is_ningxiang = param_list.room_info.is_ningxiang
    --屏蔽互动表情的方位
    self.ignoreArr = {}

    if param_list.is_playback then
        self.is_playback = param_list.is_playback
        self.order_list = param_list.order
        self.log_data_id = param_list.log_data_id
        self.create_time= param_list.create_time
    end

    self.drawCardActionTime = 0.1

    local pingmian = gt.getLocal("int","pingmian", GameSettingDefault.MJ_STYLE)
    if pingmian == 1 then
        self.hand_card_pos_list = MJCardPosition.pm_show_param.hand_card_pos_list
        self.out_card_pos_list = MJCardPosition.pm_show_param.out_card_pos_list
        self.ori_out_card_pos_list = MJCardPosition.pm_show_param.ori_out_card_pos_list
        self.ori_out_card_pos_list_34r = MJCardPosition.pm_show_param.ori_out_card_pos_list_34r
        self.scard_space_scale = MJCardPosition.pm_show_param.scard_space_scale
        self.z_p_s = MJCardPosition.pm_show_param.z_p_s

        self.is_pmmj = true
    elseif pingmian == 2 then
        self.hand_card_pos_list = MJCardPosition.pm_yellow_show_param.hand_card_pos_list
        self.out_card_pos_list = MJCardPosition.pm_yellow_show_param.out_card_pos_list
        self.ori_out_card_pos_list = MJCardPosition.pm_yellow_show_param.ori_out_card_pos_list
        self.ori_out_card_pos_list_34r = MJCardPosition.pm_yellow_show_param.ori_out_card_pos_list_34r
        self.scard_space_scale = MJCardPosition.pm_yellow_show_param.scard_space_scale
        self.z_p_s = MJCardPosition.pm_yellow_show_param.z_p_s

        self.is_pmmjyellow = true
    else
        self.hand_card_pos_list = MJCardPosition.show_param.hand_card_pos_list
        self.out_card_pos_list = MJCardPosition.show_param.out_card_pos_list
        self.ori_out_card_pos_list = MJCardPosition.show_param.ori_out_card_pos_list
        self.ori_out_card_pos_list_34r = MJCardPosition.show_param.ori_out_card_pos_list_34r
        self.scard_space_scale = MJCardPosition.show_param.scard_space_scale
        self.z_p_s = MJCardPosition.show_param.z_p_s

        self.is_3dmj = true
    end

    self.zhuobu =  gt.getLocal("int", "zhuobu", 1)

    self.img_2d = {"ui/qj_bg/mjbg.jpg",
                   "ui/qj_bg/blue2.jpg",
                   "ui/qj_bg/yellow2d.jpg",
                   "ui/qj_bg/bluebj.jpg",
                   "ui/qj_bg/green2.jpg"
               }

    self.img_3d = {"ui/qj_bg/zhuyobu1.jpg",
                   "ui/qj_bg/3dzhuobu-blue2.jpg",
                   "ui/qj_bg/yellow.jpg",
                   "ui/qj_bg/3dblue.jpg",
                   "ui/qj_bg/3dzhuobu-green2.jpg"
                }
    -- 麻将选中时的放大系统
    self.card_scale = 1.3

    self.open_card_pos_list = MJCardPosition.open_card_pos_list

    self.open_card_ani_pos_list = MJCardPosition.open_card_ani_pos_list

    self.single_scale =  MJCardPosition.single_scale

    self.scard_size_scale = {0.9*self.single_scale, 0.8, 0.6, 0.8}

    self.single_card_size = MJCardPosition.single_card_size

    self.club_id = param_list.room_info.club_id
    self.room_id = param_list.room_id
    gt.setRoomID(self.room_id)
    self.club_name  = param_list.room_info.club_name
    self.room_info  = param_list.room_info
    self.club_index = param_list.room_info.club_index

    RoomInfo.setRoomInfo(param_list.room_info,param_list.room_id)

    self.isJZBQ    = param_list.room_info.isJZBQ
    self.huaCount  = {0, 0, 0, 0}
    self.huapArrow = {}
    self.isTuoGuan = false
    if self.club_id and self.club_name and self.club_index then
        GameGlobal.is_los_club = true
        GameGlobal.is_los_club_id = self.club_id
        gt.setClubID(self.club_id)
    end
    self:setClubEnterMsg()

    self:setMjSpecialData()

    local endtime = os.clock()
    print(string.format("设置坐标时间 cost time  : %.4f", endtime - starttime))

    dump(param_list.room_info)

    local people_num = self:setRoomCurPeopleNumByRoomInfo(param_list.room_info)
    RoomInfo.updateCurPeopleNum(people_num)

    self.people_num = param_list.room_info.people_num or 4
    RoomInfo.updateTotalPeopleNum(self.people_num)

    PlayerData.setServerIDToClientIDDelegate(nil)
    -- 自己信息
    local playerinfo_list = {param_list.room_info.player_info}
    -- 其它玩家信息
    for i, v in ipairs(param_list.room_info.other) do
        playerinfo_list[i+1] = v
    end

    PlayerData.updatePlayerInfo(playerinfo_list,param_list.room_info)

    self:initHeadPos()
    -- 重设手牌坐标
    self:initHandCardPos()
    -- 人数变化重设出牌位置
    self:initOutCardPos()

    self:createLayerMenu(param_list.room_info)

    local starttime = os.clock()

    AudioManager:stopPubBgMusic()
    AudioManager:playDWCBgMusic("sound/bgGame.mp3")

    local endtime = os.clock()
    print(string.format("播放音乐 cost time  : %.4f", endtime - starttime))

    local starttime = os.clock()
    self:enableNodeEvents()
    local endtime = os.clock()
    print(string.format("开启事件 cost time  : %.4f", endtime - starttime))

    -- print('桌子号',self.desk)
    -- dump(param_list)
    -- local function startTimeCallBack()
    --     if self.desk then
    --         local net_msg = {
    --             cmd =NetCmd.C2S_JOIN_ROOM_AGAIN,
    --             room_id=self.desk,
    --         }
    --         ymkj.SendData:send(json.encode(net_msg))
    --     end
    --     -- cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.buttonClickTimeSchedule)
    -- end
    -- self.buttonClickTimeSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(startTimeCallBack, 1, false)
    --注册网络消息
    self:registerEventListener()
end

function MJBaseScene:onEnter()
    gt.refreshSignal(self.signalImg)
    gt.listenBatterySignal()
    gt.updateBatterySignal(self)

    MJBaseScene.removeUnusedRes()
    -- print(cc.Director:getInstance():getTextureCache():getCachedTextureInfo())

    local SpeekNode = require("scene.SpeekNode")
    self.speekNode = SpeekNode:create(self)
    self:addChild(self.speekNode,999)

    GameGlobal.MjSceneReplaceMJScene = nil

    local RedBagLaba = require("modules.view.RedBagLaba")
    local laba = RedBagLaba:create(self)
    self:addChild(laba,999)

    --红包消息分发注册 EventBus
    self:registerEvent()
end

function MJBaseScene:clearTextureCache()
    -- if GameGlobal.MjSceneReplaceMJScene then
    --     return
    -- end
    -- local plistTable = {
    --     'ui/qj_mj/2D/MJ/bottom/Z_bottom.plist',
    --     'ui/qj_mj/2D/MJ/left/Z_left.plist',
    --     'ui/qj_mj/2D/MJ/right/Z_right.plist',
    --     'ui/qj_mj/2D/MJ/up/Z_up.plist',
    --     'ui/qj_mj/2D/MJ/mjEmpty.plist',
    --     'ui/qj_mj/2D/MJ/my/Z_my.plist',

    --     'ui/qj_mj/2Dbig/MJ/bottom/Z_bottom.plist',
    --     'ui/qj_mj/2Dbig/MJ/left/Z_left.plist',
    --     'ui/qj_mj/2Dbig/MJ/right/Z_right.plist',
    --     'ui/qj_mj/2Dbig/MJ/up/Z_up.plist',
    --     'ui/qj_mj/2Dbig/MJ/mjEmpty.plist',
    --     'ui/qj_mj/2Dbig/MJ/my/Z_my.plist',

    --     'ui/qj_mj/majiangshandiandonghua/datangmajiangtexiaozidonghua0.plist',
    -- }


    -- for i , v in ipairs(plistTable) do
    --     cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(v)
    -- end

    -- MJBaseScene.removeUnusedRes()
end

function MJBaseScene:onExit()
    self:disableNodeEvents()
    self:clearTextureCache()
    --红包消息分发注销 EventBus
    self:unregisterEvent()

    gt.setRoomID(nil)
end

function MJBaseScene:onReconnect()

end

function MJBaseScene:registerEvent()
    local events = {
        -- {
        --     eType = EventEnum.onReconnect,
        --     func = handler(self,self.onReconnect),
        -- },
        {
            -- eType = EventEnum.S2C_RB_VALID,
            eType = EventEnum.S2C_RB_INFO,
            func = handler(self,self.onRbIsValid),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function MJBaseScene:unregisterEvent()
    for i,v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function MJBaseScene:onRbIsValid(rtn_msg)
    --应急处理，防止未收到20002消息 没有显示红包按钮
    if rtn_msg and nil ~= next(rtn_msg) then
        self.btnRedBag:setVisible(true)
    end

end

function MJBaseScene:addEffectPlist()
    cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/majiangshandiandonghua/datangmajiangtexiaozidonghua0.plist')
end

function MJBaseScene:addPlist()
    self:addCardPlist()
    self:addEffectPlist()
end

function MJBaseScene:loadMjLogic()
    ERROR('子类必须重载此函数')
end

function MJBaseScene:setMjSpecialData()

end

function MJBaseScene:keypadEvent()

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
        elseif keyCode == cc.KeyCode.KEY_MENU  then
            print("key menu exit touch")
        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    self.listenerKeyboard = listener
end

function MJBaseScene:registerEventListener()
    self:registerNetCmd()

    self:keypadEvent()
    ymkj.GlobalData:getInstance():clear()
    ymkj.setHeartInter(3000)

    if self.is_playback then
        local oper_node = tolua.cast(cc.CSLoader:createNode("ui/OperHF.csb"), "ccui.Widget")
        self:addChild(oper_node, 2000)
        oper_node:setContentSize(g_visible_size)
        ccui.Helper:doLayout(oper_node)
        self.oper_list = {}
        for ii=1, 4 do
            self.oper_list[ii] = ccui.Helper:seekWidgetByName(oper_node, "Panel"..ii)
            if (self.is_pmmj or self.is_pmmjyellow) and ii==3 then
                self.oper_list[ii]:setPosition(cc.p(self.open_card_pos_list[ii].x, self.open_card_pos_list[ii].y-32))
            else
                self.oper_list[ii]:setPosition(cc.p(self.open_card_pos_list[ii].x, self.open_card_pos_list[ii].y))
            end
            self.oper_list[ii]:setVisible(false)
            self.oper_list[ii].chi = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-chi")
            self.oper_list[ii].peng = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-peng")
            self.oper_list[ii].gang = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-gang")
            self.oper_list[ii].ting = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-ting")
            self.oper_list[ii].guo = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-guo")
            self.oper_list[ii].yao = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-yao")
            self.oper_list[ii].hu = ccui.Helper:seekWidgetByName(self.oper_list[ii], "btn-hu")
            if self.mjGameName == '丰宁' then
                self.oper_list[ii].yao:loadTextureNormal("ui/kaigang/hf_hua.png")
                self.oper_list[ii].ting:loadTextureNormal("ui/kaigang/hf_tui.png")
                self.oper_list[ii].chi:loadTextureNormal("ui/kaigang/hf_ke.png")
                self.oper_list[ii].yao:setScale(0.9)
                self.oper_list[ii].ting:setScale(0.9)
                self.oper_list[ii].chi:setScale(0.9)
            end
        end

        local function roundCheck()
            if self.order_list[1] then
                local has_oper_show = nil
                if self.order_list[1].cddm == NetCmd.S2C_MJ_COOL_DOWN or self.order_list[1].cddm == NetCmd.S2C_MJ_NEED_HAIDI then
                    local index = self.order_list[1].index or self.my_index
                    local recv_id = self.order_list[1].recv_id or self.my_index
                    while self.order_list[1] and (self.order_list[1].cddm == NetCmd.S2C_MJ_COOL_DOWN or self.order_list[1].cddm == NetCmd.S2C_MJ_NEED_HAIDI) do
                        if self.order_list[1].cddm == NetCmd.S2C_MJ_NEED_HAIDI then
                            self.order_list[1].actions = {100}
                        end
                        if self.order_list[1].kg_actions then
                            self.order_list[1].actions = self.order_list[1].actions or {}
                            for __, ac_list in ipairs(self.order_list[1].kg_actions) do
                                for __, ac in ipairs(ac_list) do
                                    self.order_list[1].actions[#self.order_list[1].actions+1] = ac
                                end
                            end
                        end
                        if self.order_list[1].actions and #self.order_list[1].actions > 0 then
                            local direct = self:indexTrans(self.order_list[1].index)
                            local oper_list = {chi=0,peng=0,gang=0,ting=0,hu=0,hd=0, hua = 0, ke = 0, tui = 0,guo=1}
                            local has_oper = nil
                            local can_opt = nil
                            for __, v in ipairs(self.order_list[1].actions) do
                                if v >= 5 and v <= 7 then
                                    oper_list.hu = 1
                                    has_oper = true
                                elseif v == 101 then
                                    oper_list.hu = 1
                                    oper_list.guo = 0
                                    has_oper = true
                                elseif v == 2 then
                                    oper_list.peng = 1
                                    has_oper = true
                                elseif v == 4 then
                                    oper_list.chi = 1
                                    has_oper = true
                                elseif v == 3 then
                                    oper_list.gang = 1
                                    has_oper = true
                                elseif v == 1 then
                                    can_opt = true
                                elseif v == 100 then
                                    oper_list.hd = 1
                                    has_oper = true
                                elseif v == 9 then
                                    oper_list.gang = 1
                                    has_oper = true
                                elseif v == 12 then
                                    oper_list.ting = 1
                                    has_oper = true
                                elseif v == 21 then
                                    oper_list.hua = 1
                                    has_oper = true
                                elseif v == 22 then
                                    oper_list.ke = 1
                                    has_oper = true
                                elseif v == 23 then
                                    oper_list.tui = 1
                                    has_oper = true
                                end
                            end
                            local pre_is_wang = nil
                            if self.pre_out_direct and self.out_card_list[self.pre_out_direct] then
                                local card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
                                if card then
                                    pre_is_wang = (card.card_id==self.wang_cards[2]) or (card.card_id==self.wang_cards[3])
                                end
                            end
                            local no_wang_count = self:checkNoWangCard()

                            if oper_list.hu==1 then
                                self.oper_list[direct].hu:setTouchEnabled(true)
                                self.oper_list[direct].hu:setBright(true)
                                if can_opt and no_wang_count <= 0 then
                                    oper_list.guo = 0
                                    can_opt = nil
                                end
                            else
                                self.oper_list[direct].hu:setTouchEnabled(false)
                                self.oper_list[direct].hu:setBright(false)
                            end

                            self.oper_list[direct].guo:setTouchEnabled(oper_list.guo==1 and has_oper )
                            self.oper_list[direct].guo:setBright(oper_list.guo==1 and has_oper )
                            if oper_list.peng==1 and ((pre_is_wang and no_wang_count > 0) or (not pre_is_wang and no_wang_count > 2)) then
                                self.oper_list[direct].peng:setTouchEnabled(true)
                                self.oper_list[direct].peng:setBright(true)
                            else
                                self.oper_list[direct].peng:setTouchEnabled(false)
                                self.oper_list[direct].peng:setBright(false)
                            end
                            self.oper_list[direct].chi:setTouchEnabled(oper_list.chi==1 or oper_list.ke==1)
                            self.oper_list[direct].chi:setBright(oper_list.chi==1 or oper_list.ke==1)
                            self.oper_list[direct].gang:setTouchEnabled(oper_list.gang==1)
                            self.oper_list[direct].gang:setBright(oper_list.gang==1)
                            self.oper_list[direct].ting:setTouchEnabled(oper_list.ting==1 or oper_list.tui==1)
                            self.oper_list[direct].ting:setBright(oper_list.ting==1 or oper_list.tui==1)
                            self.oper_list[direct].yao:setTouchEnabled(oper_list.hua==1)
                            self.oper_list[direct].yao:setBright(oper_list.hua==1)
                            if oper_list.guo==1 and has_oper then
                                self.oper_list[direct]:setVisible(true)
                                has_oper_show = true
                            end
                        end
                        table.remove(self.order_list, 1)
                    end
                    table.insert(self.order_list,1, {cddm=NetCmd.S2C_MJ_COOL_DOWN, index = index, recv_id = recv_id, actions = {}, time = 15})
                elseif self.order_list[1].cddm == NetCmd.S2C_MJ_NIAO then
                    if self.order_list[1].index and self.order_list[1].index ~= self.my_index then
                        table.remove(self.order_list, 1)
                        roundCheck()
                        return
                    end
                end
                self.order_list[1].cmd = self.order_list[1].cddm
                if self.order_list[1].cmd == NetCmd.S2C_MJ_COOL_DOWN or self.order_list[1].cmd == NetCmd.S2C_MJ_DRAW_CARD or self.order_list[1].cmd == NetCmd.S2C_NO_ACTION then
                    local treat = nil
                    local treat_list = {}
                    if not has_oper_show then
                        for ii, vv in ipairs(self.oper_list) do
                            if vv:isVisible() then
                                treat_list[ii] = vv
                                treat = true
                            end
                        end
                    end
                    if treat then
                        for ii, vv in pairs(treat_list) do
                            local sp = cc.Sprite:create("ui/qj_mj/hf_hand.png")
                            sp:setAnchorPoint(0.2, 0.5)
                            sp:setScale(0.8)
                            local sp_pos = commonlib.worldPos(self.oper_list[ii].guo)
                            sp:setPosition(cc.p(sp_pos.x, sp_pos.y-60))
                            self:addChild(sp, 2001)
                            sp:runAction(cc.Sequence:create(cc.MoveTo:create(0.2, cc.p(sp_pos.x, sp_pos.y-20)), cc.CallFunc:create(function()
                                sp:removeFromParent(true)
                                vv:setVisible(false)
                                if treat then
                                    if self.order_list[1].cmd == NetCmd.S2C_MJ_COOL_DOWN then
                                        self:onRcvMjCoolDown(self.order_list[1])
                                    elseif self.order_list[1].cmd == NetCmd.S2C_MJ_DRAW_CARD then
                                        self:onRcvMjDrawCard(self.order_list[1])
                                    end
                                    table.remove(self.order_list, 1)
                                    roundCheck()
                                    treat = nil
                                end
                            end)))
                        end
                    else
                        if self.order_list[1].cmd == NetCmd.S2C_MJ_COOL_DOWN then
                            self:onRcvMjCoolDown(self.order_list[1])
                        elseif self.order_list[1].cmd == NetCmd.S2C_MJ_DRAW_CARD then
                            self:onRcvMjDrawCard(self.order_list[1])
                        end
                        table.remove(self.order_list, 1)
                        roundCheck()
                    end
                else
                    local speed = 2
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(speed), cc.CallFunc:create(function()
                        commonlib.echo(self.order_list[1])
                        local cur_cmd = self.order_list[1].cmd
                        if cur_cmd == NetCmd.S2C_MJ_OUT_CARD or cur_cmd == NetCmd.S2C_MJ_KAIGANG or cur_cmd == NetCmd.S2C_MJ_GANG or cur_cmd == NetCmd.S2C_OPER_OTHER then
                            self:backOpenCard()
                        end
                        local op_cmd_list = {[NetCmd.S2C_MJ_CHI_CARD]="chi",[NetCmd.S2C_MJ_PENG]="peng",[NetCmd.S2C_MJ_TINGPAI]="ting",
                                             [NetCmd.S2C_MJ_KAIGANG]="gang",[NetCmd.S2C_MJ_CHI_HU]="hu", [NetCmd.S2C_MJ_HU]="hu", [NetCmd.S2C_MJ_HAIDI]="yao"}
                        op_cmd_list[NetCmd.S2C_MJ_GANG] = "gang"
                        -- TODO
                        op_cmd_list[NetCmd.S2C_OPER_OTHER] = "chi"
                        --
                        if op_cmd_list[cur_cmd] then
                            local direct = self:indexTrans(self.order_list[1].index)
                            local sp = cc.Sprite:create("ui/qj_mj/hf_hand.png")
                            sp:setAnchorPoint(0.2, 0.5)
                            sp:setScale(0.8)
                            local sp_pos = nil
                            if cur_cmd == NetCmd.S2C_OPER_OTHER then
                                if self.order_list[1].typ == 21 then -- 花
                                    sp_pos = commonlib.worldPos(self.oper_list[direct]["yao"])
                                elseif self.order_list[1].typ == 22 then -- 刻
                                    sp_pos = commonlib.worldPos(self.oper_list[direct]["chi"])
                                elseif self.order_list[1].typ == 23 then -- 推
                                    sp_pos = commonlib.worldPos(self.oper_list[direct]["ting"])
                                end
                            else
                                sp_pos = commonlib.worldPos(self.oper_list[direct][op_cmd_list[cur_cmd]])
                            end
                            sp:setPosition(cc.p(sp_pos.x, sp_pos.y-60))
                            self:addChild(sp, 2001)
                            sp:runAction(cc.Sequence:create(cc.MoveTo:create(0.2, cc.p(sp_pos.x, sp_pos.y-20)), cc.CallFunc:create(function()
                                sp:removeFromParent(true)
                                for ii=1, 4 do
                                    self.oper_list[ii]:setVisible(false)
                                end
                                if cur_cmd == NetCmd.S2C_MJ_TINGPAI then
                                    self.soundTing = true
                                    if direct == 1 then
                                        self.ting_status = true
                                    end
                                end
                                if self.order_list[1].cmd == NetCmd.S2C_MJ_HU or self.order_list[1].cmd == NetCmd.S2C_MJ_CHI_HU then
                                    self:onRcvHu(self.order_list[1])
                                end
                                if self.order_list[1].cmd == NetCmd.S2C_OPER_OTHER then
                                    self:onRcvMjOperOther(self.order_list[1])
                                end
                                if cur_cmd == NetCmd.S2C_MJ_PENG and self.order_list[1].cardsInLiPai and #self.order_list[1].cardsInLiPai > 0 then
                                    if #self.order_list[1].cardsInLiPai == 1 then
                                        for __,v in ipairs(self.hand_card_list[direct]) do
                                            if v.card_id == self.order_list[1].cardsInLiPai[1] and v.sort == 1 then
                                                v.sort = -1
                                                break
                                            end
                                        end
                                    else
                                        local count = 0
                                        for __,v in ipairs(self.hand_card_list[direct]) do
                                            if v.card_id == self.order_list[1].cardsInLiPai[1] and v.sort == 1 then
                                                v.sort = -1
                                                count = count + 1
                                                if count >= 2 then
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if cur_cmd == NetCmd.S2C_MJ_GANG and self.order_list[1].cardsInLiPai and #self.order_list[1].cardsInLiPai > 0 then
                                    for __,v in ipairs(self.hand_card_list[direct]) do
                                        if v.card_id == self.order_list[1].cardsInLiPai[1] and v.sort == 1 then
                                            v.sort = -1
                                        end
                                    end
                                end
                                if cur_cmd == NetCmd.S2C_MJ_PENG and self.order_list[1].KouPai and #self.order_list[1].KouPai > 0 then
                                    if #self.order_list[1].KouPai == 1 then
                                        for __,v in ipairs(self.hand_card_list[direct]) do
                                            if v.card_id == self.order_list[1].KouPai[1] and v.sort == 1 then
                                                v.sort = -1
                                                break
                                            end
                                        end
                                    else
                                        local count = 0
                                        for __,v in ipairs(self.hand_card_list[direct]) do
                                            if v.card_id == self.order_list[1].KouPai[1] and v.sort == 1 then
                                                v.sort = -1
                                                count = count + 1
                                                if count >= 2 then
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if cur_cmd == NetCmd.S2C_MJ_GANG and self.order_list[1].KouPai and #self.order_list[1].KouPai > 0 then
                                    for __,v in ipairs(self.hand_card_list[direct]) do
                                        if v.card_id == self.order_list[1].KouPai[1] and v.sort == 1 then
                                            v.sort = -1
                                        end
                                    end
                                end
                                self:onRcvMjOutCard(self.order_list[1])
                                if cur_cmd == NetCmd.S2C_RESULT then
                                    self.order_list = {}
                                else
                                    table.remove(self.order_list, 1)
                                end
                                if cur_cmd == NetCmd.S2C_MJ_KAIGANG then
                                    self:runAction(cc.Sequence:create(cc.DelayTime:create(4), cc.CallFunc:create(function()
                                        roundCheck()
                                    end)))
                                elseif cur_cmd == NetCmd.S2C_MJ_BBHU then
                                    self:runAction(cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
                                        roundCheck()
                                    end)))
                                else
                                    roundCheck()
                                end

                            end)))
                        else
                            if self.order_list[1].cmd == NetCmd.S2C_MJ_OUT_CARD then
                                local direct = self:indexTrans(self.order_list[1].index)
                                if self.order_list[1].isLiPai then
                                    for __,v in ipairs(self.hand_card_list[direct]) do
                                        if v.card_id == self.order_list[1].cards[1]- 0x80 and v.sort == 1 then
                                            v.sort = -1
                                        end
                                    end
                                end
                                self:onRcvMjOutCard(self.order_list[1])
                            elseif self.order_list[1].cmd == NetCmd.S2C_RESULT then
                                self:onRcvReault(self.order_list[1])
                            end
                            if cur_cmd == NetCmd.S2C_RESULT then
                                self.order_list = {}
                            else
                                table.remove(self.order_list, 1)
                            end
                            if cur_cmd == NetCmd.S2C_MJ_KAIGANG then
                                self:runAction(cc.Sequence:create(cc.DelayTime:create(4), cc.CallFunc:create(function()
                                    roundCheck()
                                end)))
                            elseif cur_cmd == NetCmd.S2C_MJ_BBHU then
                                self:runAction(cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
                                    roundCheck()
                                end)))
                            else
                                roundCheck()
                            end
                        end
                    end)))
                end
            end
        end
        roundCheck()
        self:showAction()

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
                local scene = require("scene.MainScene")
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
                    self.watcher_lab:pause()
                    self.tTimeCout:pause()
                    pb_node.pause_btn:loadTextureNormal("ui/qj_replay/dt_replay_play_btn_0.png")
                    pb_node.pause_btn:loadTexturePressed("ui/qj_replay/dt_replay_play_btn_1.png")
                else
                    self:resume()
                    self.watcher_lab:resume()
                    self.tTimeCout:resume()
                    pb_node.pause_btn:loadTextureNormal("ui/qj_replay/dt_replay_stop_btn_0.png")
                    pb_node.pause_btn:loadTexturePressed("ui/qj_replay/dt_replay_stop_btn_1.png")
                end
                pb_node.is_pause = not pb_node.is_pause
            end
        end)

    end
end

function MJBaseScene:backOpenCard()
    if not self.is_back_open_card then
        for direct, player in ipairs(self.hand_card_list or {}) do
            if direct ~= 1 then
                for ii, cid in ipairs(player) do
                    if self.mjGameName == '丰宁' and cid.card_id < 1000 then
                        cid.card_id = cid.card_id + 1000
                    end
                    local pai = self:getCardById(direct, cid.card_id-1000, "_stand")
                    pai.card_id = cid.card_id-1000
                    pai.sort = -1
                    if direct == 4 then
                        self.node:addChild(pai, 14-ii)
                    else
                        self.node:addChild(pai, 1)
                    end
                    cid:removeFromParent(true)
                    self.hand_card_list[direct][ii] = pai
                end
                self:placeHandCard(direct)
                self:sortHandCardEx(direct)
            end
        end
        self.is_back_open_card = true
    end
end

function MJBaseScene:save_new_record(rtn_msg)
    local Record = require('scene.Record')
    Record.mj_save_new_record(self,rtn_msg, self.RecordGameType)
end

function MJBaseScene:unregisterEventListener()
    self:stopSouthAction()

    self:stopCountdownWaitOverTime()

    self:unregisterNetCmd()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    ymkj.setHeartInter(0)
end

function MJBaseScene:sendReady(score)
    logUp('游戏发送准备')
    if self.is_playback then
        return
    end
    if not score then
        local input_msg = {
            cmd   = NetCmd.C2S_READY,
            index = self.my_index,
        }
        ymkj.SendData:send(json.encode(input_msg))
    else
        if self.mjGameName == '推倒胡' then
            local input_msg = {
                cmd      = NetCmd.C2S_READY,
                piao_fen = score,
                index    = self.my_index,
            }
            ymkj.SendData:send(json.encode(input_msg))
        else
            local input_msg = {
                cmd   = NetCmd.C2S_READY,
                paozi = score,
                index = self.my_index,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end
end

function MJBaseScene:peopleNumErroJoinRoomAgain()
    gt.uploadErr('mj peopleNumErroJoinRoomAgain')
    local net_msg = {
        cmd =NetCmd.C2S_JOIN_ROOM_AGAIN,
        room_id=self.desk,
    }
    ymkj.SendData:send(json.encode(net_msg))
end

function MJBaseScene:send_join_room_again()
    local errStr = string.format("game error desk = %s mjTypeWanFa = %s",tostring(self.desk),tostring(self.mjTypeWanFa))
    gt.uploadErr(errStr)
    local net_msg = {
        cmd =NetCmd.C2S_JOIN_ROOM_AGAIN,
        room_id=self.desk,
    }
    ymkj.SendData:send(json.encode(net_msg))
end


function MJBaseScene:showAction()
    if AUTO_PLAY then
        if #self.hand_card_list[1] == 14 then
            self.can_opt = true
        end
    end
    logUp('[[[[[[[[[[self.action_msg',self.action_msg)
    log('[[[[[[[[[[self.action_msg',self.action_msg)
    if self.action_msg then
        local index = self:indexTrans(self.action_msg.recv_id)
        if self.action_msg.actions and #self.action_msg.actions > 0 then
            self:resetOperPanel(self.action_msg.actions, nil, self.action_msg.oper_card or self.last_draw_card_id, self.action_msg.msgid, nil, self.action_msg.isMustHu, self.action_msg)
            self.last_draw_card_id = nil
        else
            self.oper_panel.no_reply = true
        end
        self.action_msg = nil
    else
        self.oper_panel.no_reply = true
    end
end

function MJBaseScene:removeAllHandCard()
    if self.hand_card_list then
        for i, v in ipairs(self.hand_card_list) do
            if v then
                for ii, vv in ipairs(v) do
                    vv:removeFromParent(true)
                end
            end
            self.hand_card_list[i] = {}
        end
    end
end

function MJBaseScene:firstTurnAnimation(rtn_msg)
    -- 第一局设置
    if rtn_msg.cur_ju == 1 then
        self:playhuSpine(self,'kaiju','animation')
        AudioManager:playDWCSound("sound/mj/mj_start.mp3")
    end
end

function MJBaseScene:playKaiWang(rtn_msg)

    local function initCard()
        -- 加入手牌
        for i, v in ipairs(rtn_msg.cards) do
            local pai = self:getCardById(1, v)
            pai.card_id = v
            pai.sort = 0
            self.hand_card_list[1][#self.hand_card_list[1]+1] = pai
        end
        -- 加入到桌面
        for i, v in ipairs(self.hand_card_list[1]) do
            self.node:addChild(v)
        end
        -- 排序手牌
        self:sortHandCard(1)

        self:placeHandCard(1)

        local direct_list = {2,3,4}
        if self.people_num == 3 then
            direct_list = {2, 4}
        elseif self.people_num == 2 then
            direct_list = {3}
        end

        -- 设置其它玩家的手牌背面
        for __, direct in ipairs(direct_list) do
            local count = 13
            if direct == self.banker and self.mjTypeWanFa ~= 'fnmj' then
                count = 14
            end
            for i=1, count do
                local pai = self:getBackCard(direct)
                pai.sort = 0
                pai.card_id = 1000
                pai.ssort = i
                pai:setPosition(cc.p(self.hand_card_pos_list[direct].init_pos.x+self.hand_card_pos_list[direct].space.x*i, self.hand_card_pos_list[direct].init_pos.y+self.hand_card_pos_list[direct].space.y*i))
                self.node:addChild(pai)
                self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
            end
            self:sortHandCard(direct)
            self:placeHandCard(direct)
        end

        -- 剩于牌张数
        self.left_card_num = rtn_msg.left_card_num
        self.left_lbl:setVisible(true)
        self.left_lbl:setString(self.left_card_num)

        self:showAction()
    end

    self:setLaZiRunAction(rtn_msg)
    initCard()
end

function MJBaseScene:sortHandCard(direct, no_comp_id)
    local wang_cards = {}
    if self.wang_cards and #self.wang_cards > 0 then
        if #self.wang_cards == 3 then
            wang_cards = {self.wang_cards[2], self.wang_cards[3]}
        else
            wang_cards = self.wang_cards
        end
    end
    for i, v in ipairs(self.hand_card_list[direct]) do
        local j = i
        for ii, vv in ipairs(self.hand_card_list[direct]) do
            if ii > i then
                if vv.sort == self.hand_card_list[direct][j].sort then
                    if vv.ssort and self.hand_card_list[direct][j].ssort and vv.ssort < self.hand_card_list[direct][j].ssort then
                        j = ii
                    elseif vv.card_id ~= self.hand_card_list[direct][j].card_id then
                        if vv.sort == 0 or vv.sort == -1 then
                            if #wang_cards > 0 then
                                local j_w = 0
                                local v_w = 0
                                for w_i, w_c in ipairs(wang_cards) do
                                    if w_c == vv.card_id then
                                        v_w = w_i
                                    end
                                    if w_c == self.hand_card_list[direct][j].card_id then
                                        j_w = w_i
                                    end
                                end
                                if j_w == 0 then
                                    if v_w ~= 0 then
                                        j = ii
                                    else
                                        if vv.card_id < self.hand_card_list[direct][j].card_id then
                                            j = ii
                                        end
                                    end
                                elseif j_w ~= 1 then
                                    if v_w == 1 then
                                        j = ii
                                    elseif v_w ~= 0 then
                                        if vv.card_id < self.hand_card_list[direct][j].card_id then
                                            j = ii
                                        end
                                    end
                                end

                            elseif not no_comp_id and vv.card_id < self.hand_card_list[direct][j].card_id then
                                j = ii
                            end
                        end
                    end
                elseif vv.sort > self.hand_card_list[direct][j].sort then
                    j = ii
                end
            end
        end
        if j ~= i then
            local temp = self.hand_card_list[direct][i]
            self.hand_card_list[direct][i] = self.hand_card_list[direct][j]
            self.hand_card_list[direct][j] = temp
        end
    end

    self:sortHandCardEx(direct)
end

function MJBaseScene:sortHandCardExByIndex(direct,v,i)
    if direct == 1  then
        v:setLocalZOrder(self.ZOrder.HAND_CARD_ZORDER_1)
    elseif direct == 2 then
        v:setLocalZOrder(self.ZOrder.HAND_CARD_ZORDER_2-i)
    elseif direct == 4 then
        v:setLocalZOrder(self.ZOrder.HAND_CARD_ZORDER_4+i)
    elseif direct == 3 then
        v:setLocalZOrder(self.ZOrder.HAND_CARD_ZORDER_3)
    end
end

function MJBaseScene:sortHandCardEx(direct)
    for i, v in ipairs(self.hand_card_list[direct]) do
        self:sortHandCardExByIndex(direct,v,i)
    end
end

function MJBaseScene:placeHandCardWithCanOut(direct,com_space,vv,ii)
    com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y

    if direct == 1 then
        -- self.my_sel_index = 1
        if self.my_sel_index and self.my_sel_index == 1 and self.my_sel_index == ii then
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x
            local y = (vv:getContentSize().height*vv:getAnchorPoint().y * (self.card_scale * self.card_scale_init_y - self.card_scale_init_y))
            vv:setPositionY(y  + com_space.y)
            vv:setScaleX(self.card_scale * self.card_scale_init_x)
            vv:setScaleY(self.card_scale * self.card_scale_init_y)
        elseif self.my_sel_index and self.my_sel_index == ii then
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.card_scale/2 + self.hand_card_pos_list[direct].space.x/2

            local y = (vv:getContentSize().height*vv:getAnchorPoint().y * (self.card_scale * self.card_scale_init_y - self.card_scale_init_y))
            vv:setPositionY(y  + com_space.y)
            vv:setScaleX(self.card_scale * self.card_scale_init_x)
            vv:setScaleY(self.card_scale * self.card_scale_init_y)
        elseif self.my_sel_index and self.my_sel_index == ii-1 then
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.card_scale/2 + self.hand_card_pos_list[direct].space.x/2

            vv:setPositionY(com_space.y)

            vv:setScaleX(self.card_scale_init_x or vv:getScaleX())
            vv:setScaleY(self.card_scale_init_y or vv:getScaleY())
        else
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x
            vv:setPositionY(com_space.y)
            vv:setScaleX(self.card_scale_init_x or vv:getScaleX())
            vv:setScaleY(self.card_scale_init_y or vv:getScaleY())
        end
        vv:setPositionX(com_space.x)
    else
        com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x
        vv:setPositionY(com_space.y)
        vv:setPositionX(com_space.x)
    end
end

-- 设置位置
function MJBaseScene:placeHandCard(direct, first_pos)
    -- logUp('        设置位置            ')
    local com_space = first_pos or cc.p(self.hand_card_pos_list[direct].init_pos.x, self.hand_card_pos_list[direct].init_pos.y)
    local first_hand = nil
    for ii, vv in ipairs(self.hand_card_list[direct]) do
        -- 设置手牌
        vv:stopAllActions()
        if vv.sort == -1 then
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space_replay.x
            com_space.y = com_space.y + self.hand_card_pos_list[direct].space_replay.y

            vv:setPosition(cc.p(com_space.x, com_space.y))
        elseif vv.sort == 0 then
            self:placeHandCardWithCanOut(direct,com_space,vv,ii)
        else
            -- 设置下坎后的牌
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.scard_space_scale[direct]
            com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y*self.scard_space_scale[direct]

            vv:setPosition(cc.p(com_space.x, com_space.y))

            if first_pos then
                local pai = self.hand_card_list[direct][13]
                if pai and pai.sort == 0 then
                    if direct == 2 then
                        local pos = com_space.x
                        local starPosX = pos + pai:getContentSize().width/2
                        vv:setPositionX(starPosX - vv:getContentSize().width/2)
                    elseif direct == 4 then
                        local pos = com_space.x
                        local starPosX = pos - pai:getContentSize().width/2
                        vv:setPositionX(starPosX + vv:getContentSize().width/2)
                    elseif direct == 3 then
                        local pos = com_space.y
                        local starPosY = pos - pai:getContentSize().height/2
                        vv:setPositionY(starPosY + vv:getContentSize().height/2*vv:getScaleY())
                    elseif direct == 1 then
                        local pos = com_space.y
                        local starPosY = pos - pai:getContentSize().height/2 + 0.1 * pai:getContentSize().height/2
                        vv:setPositionY(starPosY + vv:getContentSize().height/2)
                    end
                end
            end

            local next_card = self.hand_card_list[direct][ii+1]
            if next_card and (not next_card.cardType or next_card.cardType and next_card.cardType ~= vv.cardType) then
                com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
                com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
            end
        end
    end

    if first_pos then
        self:set14thCardPosition(direct)
        return
    end

    if not self.hand_card_list[direct] or not self.hand_card_list[direct][1] or not self.hand_card_list[direct][13] then
        return
    end
    local first_pos_x,first_pos_y = self.hand_card_list[direct][1]:getPosition()
    local end_pos_x,end_pos_y = self.hand_card_list[direct][13]:getPosition()

    if direct == 1 then
        first_pos_y = self.hand_card_pos_list[direct].init_pos.y

        end_pos_y = self.hand_card_pos_list[direct].init_pos.y
    end

    if self.hand_card_list[direct][13].sort == -1 then
        end_pos_x = end_pos_x + self.hand_card_pos_list[direct].space_replay.x + self.hand_card_pos_list[direct].space_replay.x*self.z_p_s[direct]
        end_pos_y = end_pos_y + self.hand_card_pos_list[direct].space_replay.y + self.hand_card_pos_list[direct].space_replay.y*self.z_p_s[direct]
    else
        end_pos_x = end_pos_x + self.hand_card_pos_list[direct].space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
        end_pos_y = end_pos_y + self.hand_card_pos_list[direct].space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
    end

    local function restpos(direct)
        if direct == 1 or direct == 3 then
            first_pos_x = (g_visible_size.width - (end_pos_x - first_pos_x))/2
        elseif direct == 2 or direct == 4 then
            first_pos_y = (g_visible_size.height - (end_pos_y - first_pos_y))/2
        end
    end
    restpos(direct)

    if direct == 1 then
        first_pos_x = self:adjustFirstCardPos(first_pos_x,self.hand_card_list[direct][1])
    end
    if self.hand_card_list[direct][13].sort == -1 then
        first_pos_x = first_pos_x - self.hand_card_pos_list[direct].space_replay.x
        first_pos_y = first_pos_y - self.hand_card_pos_list[direct].space_replay.y
    else
        first_pos_x = first_pos_x - self.hand_card_pos_list[direct].space.x
        first_pos_y = first_pos_y - self.hand_card_pos_list[direct].space.y
    end
    self:placeHandCard(direct,cc.p(first_pos_x,first_pos_y))
end

function MJBaseScene:adjustFirstCardPos(first_pos_x,card)
    local iSize = card:getContentSize()
    local iAnchor = card:getAnchorPoint()
    local nScaleX = card:getScaleX()
    local realWidht = iSize.width * nScaleX
    local posX = first_pos_x - iAnchor.x*realWidht
    if posX < 0 then
        first_pos_x = (iAnchor.x*realWidht)
    end
    return first_pos_x
end

function MJBaseScene:adjustLastCardPos(end_pos_x,card)
    local windowSize = cc.Director:getInstance():getWinSize()
    local iSize = card:getContentSize()
    local iAnchor = card:getAnchorPoint()
    local nScaleX = card:getScaleX()
    local realWidht = iSize.width * nScaleX
    local posX = end_pos_x + realWidht - iAnchor.x*realWidht
    if posX > windowSize.width then
        end_pos_x = windowSize.width - (realWidht - iAnchor.x*realWidht)
    end
    return end_pos_x
end

function MJBaseScene:treatPlayback(rtn_msg)
    self.direct_img_cur = nil
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i+1] = v
    end

    local function setWangCard()
        if not self.haoZiDi then
            return
        end
        local haoziSprite = cc.Sprite:create(self.haoZiDi)
        haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-150))
        self.node:addChild(haoziSprite)

        self.wang_cards = {rtn_msg.wang, rtn_msg.wang1, rtn_msg.wang2}
        self.wang_card_list = {}
        for i, v in ipairs(self.wang_cards) do
            local pai = self:getOpenCardById(1, v, true)
            pai.card_id = v
            pai:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
            self.node:addChild(pai)

            haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-165))
            pai:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(g_visible_size.width-80, g_visible_size.height-150))))
            self.wang_card_list[i] = pai
        end
        if 0 == #self.wang_card_list then
            haoziSprite:setVisible(false)
        end
    end

    setWangCard()
    for __, player in ipairs(playerinfo_list) do
        commonlib.echo(player)
        local direct = self:indexTrans(player.index)
        table.sort(player.cards)
        for ii, cid in ipairs(player.cards) do
            local pai = nil
            if direct == 1 then
                pai = self:getCardById(direct, cid)
                pai.sort = 0
                pai.card_id = cid
            else
                pai = self:getBackCard(direct)
                pai.card_id = 1000+cid
                pai.sort = 0
                pai.ssort = ii
            end
            self.node:addChild(pai)
            self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
        end
        self:sortHandCardEx(direct)
        self:placeHandCard(direct)
    end
    self.left_card_num = rtn_msg.left_card_num
    self.left_lbl:setString(self.left_card_num)
    self.left_lbl:setVisible(true)

    if self.treatPlaybackMJOwner then
        self:treatPlaybackMJOwner()
    end
end

function MJBaseScene:treatResumeLastOutCard(rtn_msg,playerinfo_list)
    if rtn_msg.last_id then
        local last_id = self:indexTrans(rtn_msg.last_id)
        for i , v in ipairs(playerinfo_list) do
            local direct = self:indexTrans(v.index)
            if direct == last_id then
                self.last_out_card = v.out_card[#v.out_card]
                break
            end
        end
    end
end

function MJBaseScene:treatResumeSaveRecord(rtn_msg)
    self:save_new_record(rtn_msg,self.RecordGameType)
end

function MJBaseScene:setLaZiRunAction(rtn_msg)
    if not self.haoZiDi then
        return
    end
    local haoziSprite = cc.Sprite:create(self.haoZiDi)
    haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-150))
    self.node:addChild(haoziSprite)
    haoziSprite:setName('haoziSprite')
    self.wang_cards = {rtn_msg.wang, rtn_msg.wang1, rtn_msg.wang2}
    self.wang_card_list = {}
    for i, v in ipairs(self.wang_cards) do
        local pai = self:getOpenCardById(1, v, true)
        pai.card_id = v
        pai:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
        self.node:addChild(pai)

        haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-165))
        pai:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(g_visible_size.width-80, g_visible_size.height-150))))
        pai:setName('haoziPai')
        self.wang_card_list[i] = pai
    end
    if 0 == #self.wang_card_list then
        haoziSprite:setVisible(false)
    end
end

function MJBaseScene:setLaZi(rtn_msg)
    self.wang_card_list = {}
    self.wang_cards = {rtn_msg.wang, rtn_msg.wang1, rtn_msg.wang2}
    if self.wang_cards[1] == nil then
        self.wang_cards = {rtn_msg.wang1}
    else
        local haoziSprite = cc.Sprite:create(self.haoZiDi)
        haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-150))
        self.node:addChild(haoziSprite)
        haoziSprite:setName('haoziSprite')
        if rtn_msg.player_info.hand_card and #rtn_msg.player_info.hand_card > 0 then
            for i, v in ipairs(self.wang_cards) do
                local pai = self:getOpenCardById(1, v)
                haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-165))
                pai:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-150))
                pai.card_id = v
                self.node:addChild(pai)
                pai:setName('haoziPai')
                self.wang_card_list[i] = pai
            end
        end
        if 0 == #self.wang_card_list then
            haoziSprite:setVisible(false)
        end
    end
end

function MJBaseScene:treatResume(rtn_msg)

    self:resetOperBtnTag()

    -- 断线重连
    if self.is_playback then
        self:addPlist()
        self:treatPlayback(rtn_msg)
        return
    end

    if rtn_msg.result_packet then
        self:treatResumeSaveRecord(rtn_msg.result_packet)
    end

    self.quan_lbl:setVisible(true)

    self.PassTing_count = 0
    self.direct_img_cur = nil
    self.is_treatResume = true
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))
    local is_start = rtn_msg.cur_id and #rtn_msg.player_info.hand_card > 0
    if is_start then
        self:addPlist()
    end

    if rtn_msg.player_info.ready == false and not rtn_msg.result_packet and (not rtn_msg.isPiaoFen or (rtn_msg.isPiaoFen >= 0 and rtn_msg.isPiaoFen <= 10)) then
        self:sendReady()
    end

    if is_start and rtn_msg.cur_id > 0 and rtn_msg.cur_id <= 4 then
        local play_index = self:indexTrans(rtn_msg.cur_id)
        self:showWatcher(play_index, rtn_msg.time or 15)
    end

    local playerinfo_list = {rtn_msg.player_info}

    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i+1] = v
    end

    self:treatResumeLastOutCard(rtn_msg,playerinfo_list)

    self:setLaZi(rtn_msg)

    if rtn_msg.result_packet then
        if g_channel_id == 800002 then
            AudioManager:stopPubBgMusic()
        end
        self:initResultUI(rtn_msg.result_packet)
        return
    end

    self.ting_status = rtn_msg.player_info.is_ting
    if self.ting_status then
        self.ting_list = {}
    end

    local windowSize = cc.Director:getInstance():getWinSize()

    for __, player in ipairs(playerinfo_list) do
        local direct = self:indexTrans(player.index)
        if player.buhua_group then
            self.huaCount[direct] = #player.buhua_group
        end
        -- 已出的牌
        self:treatResumeOutCard(direct,player.out_card)
        -- 下坎的牌
        self:treatResumeGroupCard(direct,player.group_card)
        -- 托管状态
        if player.isTuoGuan then
            self:tuoGuanStatus(direct, player.isTuoGuan)
        end
    end

    if rtn_msg.last_id then
        self.pre_out_direct = self:indexTrans(rtn_msg.last_id)
        self:showCursor()
    end

    for __, player in ipairs(playerinfo_list) do
        local direct = self:indexTrans(player.index)
        if direct == 1 then
            local len = 14 - (#player.group_card*3)
            -- 设置手牌

            for ci, cid in ipairs(player.hand_card) do
                if ci <= len then
                    local pai = self:getCardById(direct, cid)
                    pai.card_id = cid
                    pai.sort = 0
                    self.node:addChild(pai)
                    self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                end
            end

            -- 设置
            if player.actions and #player.actions > 0 then
                self:resetOperPanel(player.actions, nil, player.oper_card, player.msgid, player.kg_cards,rtn_msg, player)
            end
            self:setImgGuoHuIndexVisible(1,player.is_louhu)
        elseif is_start then
            local len = 13 - (#player.group_card*3)
            if rtn_msg.cur_id ~= rtn_msg.last_id and rtn_msg.cur_id == player.index then
                len = len+1
            end
            if player.hand_card and #player.hand_card ~= 0 then
                for ci, cid in ipairs(player.hand_card) do
                    if ci <= len then
                        local pai = self:getCardById(direct, cid)
                        pai.card_id = cid
                        pai.sort = -1
                        self.node:addChild(pai)
                        self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                    end
                end
            else
                for ii=1, len  do
                    local pai = self:getBackCard(direct)
                    pai.card_id = 1000
                    pai.sort = 0
                    pai.ssort = ii
                    self.node:addChild(pai)
                    self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                end
            end
        end

        self:sortHandCard(direct, true)

        local b14Card = self:treatResume14thCard(direct,player)

        self:placeHandCard(direct,nil)

        -- 加阴影
        if player.is_ting and direct == 1 then
            self:addCardShadow()
        end

        -- 听牌
        if player.is_ting then
            self:addTingTag(direct)
            if self.mjGameName == '丰宁' then
                self:getTingCards(direct)
            end
        end
    end

    if rtn_msg.left_card_num and self.is_game_start then
        self.left_card_num = rtn_msg.left_card_num
        self.left_lbl:setString(self.left_card_num)
        self.left_lbl:setVisible(true)
    end
end

function MJBaseScene:treatResume14thCard(direct,player)
    local b14Card = (direct == 1 and player.last_draw_card and #self.hand_card_list[1]%3 == 2)
    if b14Card then
        local last_draw_card = player.last_draw_card
        local hand_card_index = #player.group_card*3+1
        local last_index = 14
        for i = 14, hand_card_index , -1 do
            local card = self.hand_card_list[1][i]
            if card and card.card_id == last_draw_card then
                last_index = i
                break
            end
        end
        for i = last_index , 13 do
            local card = self.hand_card_list[1][i]
            if card and card.card_id == last_draw_card then
                self.hand_card_list[1][i], self.hand_card_list[1][i+1] = self.hand_card_list[1][i+1], self.hand_card_list[1][i]
            end
        end
    end
    return b14Card
end

-- @服务端位置转换到客户端位置
-- @index服务端位置
-- @人数
-- @my_index自己的服务端位置
-- @return index对应的客户端位置
function MJBaseScene:indexTrans(index)
    local client_index = PlayerData.getPlayerClientIDByServerID(index)
    return client_index
end

function MJBaseScene:resetCard()
    self.MJClickAction.resetCard(self)
    if self.ting_tip_layer then
        self.ting_tip_layer:setVisible(false)
    end
end

function MJBaseScene:PassHu(value)
    if self.hasHu and not self.bMustHu and not self.isTuoGuan then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_DO_PASS_HU},
            {index=self.my_index},
        }
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))

        if AUTO_PLAY then
            self.my_sel_index = nil
            if self.show_pai then
                self.show_pai:removeFromParent(true)
                self.show_pai = nil
            end
            self:resetCard()
        else
            commonlib.showTipDlg("您确定过胡吗？", function(ok)
                if ok then
                    self.my_sel_index = nil
                    self:sendOperate(nil, 0)

                    self.IngoreOpr = true

                    self.hasHu = false
                    if not self.can_opt then
                        if self.is_pass_long then
                            self:setImgGuoLongIndexVisible(1, true)
                        else
                            self:setImgGuoHuIndexVisible(1, true)
                        end
                    end
                    self:sendOutCards(value)
                else
                    self.my_sel_index = nil
                    if self.show_pai then
                        self.show_pai:removeFromParent(true)
                        self.show_pai = nil
                    end
                    self:resetCard()
                end
            end)
        end
        self:placeHandCard(1)
        return true
    end
    return false
end

function MJBaseScene:PassTing(value)
    if self.hasTing then
        if self.PassTing_count and self.PassTing_count == 0 and not AUTO_PLAY then
            commonlib.showTipDlg("您确定过听吗？", function(ok)
                if ok then
                    self.PassTing_count = self.PassTing_count + 1
                    self.my_sel_index = nil
                    self:sendOperate(nil, 0)

                    self.IngoreOpr = true

                    self.hasTing = false
                    self:sendOutCards(value)
                else
                    self.my_sel_index = nil
                    if self.show_pai then
                        self.show_pai:removeFromParent(true)
                        self.show_pai = nil
                    end
                    self:resetCard()
                end
            end)
        else
            self.my_sel_index = nil
            self:sendOperate(nil, 0)

            self.IngoreOpr = true

            self.hasTing = false
            self:sendOutCards(value)
        end
        return true
    end
    return false
end

function MJBaseScene:PassGang(value)
    local tGangPai = self:GetGangPai()
    local bOutCardPai = false
    for i , v in pairs(tGangPai) do
        if value == v then
            bOutCardPai = true
            break
        end
    end

    if self.hasGang and bOutCardPai and not AUTO_PLAY then
        commonlib.showTipDlg("您确定过杠吗？", function(ok)
            if ok then
                self.my_sel_index = nil
                self:sendOperate(nil, 0)

                self.IngoreOpr = true

                self.hasGang = false
                self:sendOutCards(value)
            else
                self.my_sel_index = nil
                if self.show_pai then
                    self.show_pai:removeFromParent(true)
                    self.show_pai = nil
                end
                self:resetCard()
            end
        end)
        return true
    end
    return false
end

function MJBaseScene:PassHua(value)
    if self.hasHua and not AUTO_PLAY then
        commonlib.showTipDlg("您确定过起手花吗？", function(ok)
            if ok then
                self.my_sel_index = nil
                self:sendOperate(nil, 0)

                self.IngoreOpr = true

                self.hasHua = false
                self:sendOutCards(value)
            else
                self.my_sel_index = nil
                if self.show_pai then
                    self.show_pai:removeFromParent(true)
                    self.show_pai = nil
                end
                self:resetCard()
            end
        end)
        return true
    end
    return false
end

function MJBaseScene:PassTui(value)
    if self.hasTui and not AUTO_PLAY then
        commonlib.showTipDlg("您确定过推吗？", function(ok)
            if ok then
                self.my_sel_index = nil
                self:sendOperate(nil, 0)

                self.IngoreOpr = true

                self.hasTui = false
                self:sendOutCards(value)
            else
                self.my_sel_index = nil
                if self.show_pai then
                    self.show_pai:removeFromParent(true)
                    self.show_pai = nil
                end
                self:resetCard()
            end
        end)
        return true
    end
    return false
end

function MJBaseScene:PassOtherOper()
    if self.hasGang or self.hasPeng or self.hasTing then
        self:sendOperate(nil, 0)

        self.IngoreOpr = true

        self.hasTing = false
        self.hasPeng = false
        self.hasGang = false
        self.hasHua  = false
        self.hasTui  = false
    end
end

function MJBaseScene:ResetPassData()
    self.hasPeng = false
    self.hasGang = false
    self.hasTing = false
    self.hasHu = false
    self.hasHua  = false
    self.hasTui  = false
end

function MJBaseScene:clientPreOutCard(value)
    local client_pre_out_card_msg = {}
    client_pre_out_card_msg.cards = {}
    client_pre_out_card_msg.cmd = NetCmd.S2C_MJ_OUT_CARD
    client_pre_out_card_msg.index = self.my_index

    table.insert(client_pre_out_card_msg.cards,value)

    self.out_from_client = true
    self:onRcvMjOutCard(client_pre_out_card_msg)
    self.out_from_client = false

    if self.show_pai then
        if self.show_pai.card then
            self.show_pai.card:setVisible(true)
            self.show_pai.card = nil
        end
        self.show_pai:removeFromParent(true)
        self.show_pai = nil
    end
end

function MJBaseScene:checkCardNum(value)
    if not self.hand_card_list or not self.hand_card_list[1] then
        self:send_join_room_again()
        return
    end
    local num = 0
    for direct = 1 , 4 do
        local out_card_list = self.out_card_list[direct]
        for i ,v in ipairs(out_card_list or {}) do
            if v and v.card_id and v.card_id == value then
                num = num + 1
            end
        end
    end
    for i = 1,14 do
        local hand_card = self.hand_card_list[1][i]
        if hand_card and hand_card.card_id and hand_card.card_id == value then
            num = num +1
        end
    end
    if num > 4 then
        self:send_join_room_again()
    end
end

function MJBaseScene:sendOutCards(value)
    if self:PassHu(value) then
        log('MJBaseScene:sendOutCards PassHu return')
        return
    end

    if self:PassGang(value) then
        log('MJBaseScene:sendOutCards PassGang return')
        return
    end

    if self:PassTing(value) then
        log('MJBaseScene:sendOutCards PassTing return')
        return
    end

    if self:PassHua(value) then
        log('MJBaseScene:sendOutCards PassHua return')
        return
    end

    if self:PassTui(value) then
        log('MJBaseScene:sendOutCards PassTui return')
        return
    end

    self:PassOtherOper()

    self:ResetPassData()

    if self.ting_tip_layer then
        self.ting_tip_layer:setVisible(false)
    end

    self.can_opt = nil

    self.ting_list = {}
    self:removeTingArrow()

    self:resetHightCard()

    self:clientPreOutCard(value)

    self:checkCardNum()

    -- value = 1
    if type(value) == "table" then
        local input_msg = {
            cmd =NetCmd.C2S_MJ_OUT_CARD,
            card_data=value,
            index=self.my_index,
        }
        ymkj.SendData:send(json.encode(input_msg))
    else
        local input_msg = {
            cmd =NetCmd.C2S_MJ_OUT_CARD,
            card_data={value or 0},
            index=self.my_index,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end

    self.oper_panel.msgid = nil

    self.my_sel_index = nil
    self:placeHandCard(1)

    self:dongZhangCleanGuoHu()
    self:setImgGuoPengIndexVisible(1,false)

    self.can_opt = nil

    self.last_draw_card_id = nil
end

function MJBaseScene:dongZhangCleanGuoHu()
    self:setImgGuoHuIndexVisible(1,false)
end

function MJBaseScene:sendOperate(value, opt, target_value)
    if opt == 3 then
        opt = 4
    end
    if self.oper_pai_bg then
        self.oper_pai_bg:removeFromParent(true)
        self.oper_pai_bg = nil
    end
    if opt == 2 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_PENG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 3 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_KAIGANG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 4 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_GANG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 1 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_CHI_CARD},
            {cards=value},
            {index=self.my_index},
        }
        if target_value then
            input_msg[4] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 5 then
        if self.hu_type == 101 then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_BBHU},
                {typ =self.bbh_data[1].typ},
                {index=self.my_index},
            }
            ymkj.SendData:send(json.encode2(input_msg))
        elseif self.hu_type == 7 then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_BBHU},
                {index=self.my_index},
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        elseif self.hu_type == 5 then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_CHI_HU},
                {index=self.my_index},
            }
            if target_value then
                input_msg[3] = {card=target_value}
            end
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        else
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_HU},
                {index=self.my_index},
            }
            if target_value then
                input_msg[3] = {card=target_value}
            end
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        end
    elseif opt == 6 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_HAIDI},
            {need =1},
            {index=self.my_index},
        }
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 0 then
        -- if not self.oper_panel.time_out_flag then
        local input_msg = {
            {cmd =NetCmd.C2S_PASS},
            {index=self.my_index},
        }
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == self.TING_OPERATOR then
        self.ting_list = {}
        self:removeTingArrow()
        self.soundTing = true
        self:clientPreOutCard(0x80 + target_value)

        local input_msg = {
            {cmd =NetCmd.C2S_MJ_TINGPAI},
            {index=self.my_index},
            {card = target_value},
        }
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 21 then
        local input_msg = {
            {cmd   = NetCmd.C2S_OPER_OTHER},
            {index = self.my_index},
            {card  = target_value},
            {typ   = opt},
        }
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 22 then
        local input_msg = {
            {cmd   = NetCmd.C2S_OPER_OTHER},
            {index = self.my_index},
            {card  = target_value},
            {typ   = opt},
        }
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 23 then
        self.ting_list = {}
        self:removeTingArrow()
        if target_value then
            self:clientPreOutCard(target_value)
        end

        local input_msg = {
            {cmd   = NetCmd.C2S_OPER_OTHER},
            {index = self.my_index},
            {typ   = opt},
        }
        if target_value then
            input_msg[#input_msg + 1] = {card  = target_value}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    end

    self.oper_panel.msgid = nil

    self.last_draw_card_id = nil
end

function MJBaseScene:playCardSound(paramPokerId, open_card_index)
    local color = math.floor(paramPokerId/16)+1
    local value = paramPokerId%16

    local prefix = self:getSoundPrefix(open_card_index)
    if self.soundTing then
        AudioManager:playDWCSound("sound/"..prefix.."/ting.mp3")
        self.soundTing = false
        return
    end
    if color==1 then
        AudioManager:playDWCSound("sound/"..prefix.."/"..value.."wan.mp3")
    elseif color==2 then
        AudioManager:playDWCSound("sound/"..prefix.."/"..value.."tong.mp3")
    elseif color==3 then
        AudioManager:playDWCSound("sound/"..prefix.."/"..value.."tiao.mp3")
    elseif paramPokerId == 49 then
        AudioManager:playDWCSound("sound/"..prefix.."/41.mp3")
    elseif paramPokerId == 50 then
        AudioManager:playDWCSound("sound/"..prefix.."/42.mp3")
    elseif paramPokerId == 51 then
        AudioManager:playDWCSound("sound/"..prefix.."/43.mp3")
    elseif paramPokerId == 52 then
        AudioManager:playDWCSound("sound/"..prefix.."/44.mp3")
    elseif paramPokerId == 65 then
        AudioManager:playDWCSound("sound/"..prefix.."/51.mp3")
    elseif paramPokerId == 66 then
        AudioManager:playDWCSound("sound/"..prefix.."/52.mp3")
    elseif paramPokerId == 67 then
        AudioManager:playDWCSound("sound/"..prefix.."/53.mp3")
    end
end

function MJBaseScene:getCardById(direct, paramPokerId, status, bOpenCard, scale)
    if 0 == paramPokerId or paramPokerId > 0x80 then

        if self.is_pmmj or self.is_pmmjyellow then
            local szTingBack = {}
            local szDirectPre = {}
            if self.is_pmmj then
                szTingBack = {  'ee_mj_b_up.png',
                                'ee_mj_b_right.png',
                                'ee_mj_b_up.png',
                                'ee_mj_b_left.png',
                                }
                szDirectPre = {'BB','RR','UU','LL'}
            else
                szTingBack = {'e_mj_b_up.png',
                                'e_mj_b_right.png',
                                'e_mj_b_up.png',
                                'e_mj_b_left.png',
                                }
                szDirectPre = {'B','R','U','L'}
            end
            local str = szTingBack[direct]
            local card = self:createCardWithSpriteFrameName(str)

            local normal_direct_size = direct
            local width = 43
            local height = 52

            local scalearg

            if self.is_pmmjyellow then
                if direct == 1 or direct == 3 then
                    if not scale then
                        scalearg = 38/card:getContentSize().width
                    else
                        if direct == 1 then
                            scalearg = 1.8
                        else
                            scalearg = 1.1
                        end
                    end
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                elseif direct == 2 or direct == 4 then
                    scalearg = 42/card:getContentSize().height
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                end
            else
                if direct == 1 or direct == 3 then
                    if not scale then
                        scalearg = 43/card:getContentSize().width
                    else
                        if direct == 1 then
                            scalearg = 1.23
                        else
                            scalearg = 0.68
                        end
                    end
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                elseif direct == 2 or direct == 4 then
                    scalearg = 52/card:getContentSize().height
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                end
            end
            return card
        else
            local card = nil
            local colNum = self.out_row_nums
            local col = #self.out_card_list[direct]
            local row = math.floor(col/colNum)+1
            row = math.min(row, 3)

            if direct == 2 then
                col = math.min(col%colNum+1, colNum-1)

                if not scale then
                    card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backtingyou/Frame_youjia_' .. row..'_'..col..'.png')
                    card:setScale(0.6*self.single_scale)
                else
                    card = cc.Sprite:create('ui/qj_mj/3d/ting_back/you/Frame_youjia_' .. row..'_'..col..'.png')
                    card:setScale(0.46*self.single_scale)
                    --card:setRotation(-5.5)
                end
                local add_row = 0
                if row == 2 then
                    card:setAnchorPoint(0.5+col*0.01, 0.5)
                elseif row == 3 then
                    add_row = -0.03
                end
            elseif direct == 4 then
                col =math.min(colNum-col%colNum, colNum-1)
                if not scale then
                    card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backtingzou/Frame_zuojia_'..row.."_"..col..".png")
                    card:setScale(0.6*self.single_scale)
                else
                    card = cc.Sprite:create('ui/qj_mj/3d/ting_back/zuo/Frame_zuojia_'..row.."_"..col..".png")
                    card:setScale(0.46*self.single_scale)
                    --card:setRotation(5.5)
                end
                if row == 2 then
                    card:setAnchorPoint(0.5+(colNum-col)*0.014, 0.5)
                end
            elseif direct == 3 then
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backting3.png')
                if not scale or self.mjTypeWanFa == 'fnmj' then
                    card:setScaleX(86/74*0.6*self.single_scale)
                    card:setScaleY(119/94*0.6*self.single_scale)
                else
                    card:setScaleX(86/74*0.5*self.single_scale)
                    card:setScaleY(119/94*0.5*self.single_scale)
                end
            else
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backting1.png')
                if not scale then
                    card:setScale(0.52*self.single_scale)
                else
                    card:setScale(0.67*self.single_scale)
                end
            end
            return card
        end
    end

    local color = math.floor(paramPokerId/16)
    color = math.min(color, 4)
    if color > 4 or color < 0 then
        commonlib.showLocalTip("花色不正确")
        return
    end
    local value = paramPokerId%16
    if value > 9 or value <=0 then
        commonlib.showLocalTip("牌值不正确")
        return
    end

    if color == 0 then
        color = ""
    elseif color == 4 then
        value = value+4
        color = 3
    end

    local card = nil
    if self.is_pmmj or self.is_pmmjyellow then
        local szFengStr = {
                            '_wind_east.png',
                            '_wind_south.png',
                            '_wind_west.png',
                            '_wind_north.png',
                            '_red.png',
                            '_green.png',
                            '_white.png',
                        }
        local str =''
        if color == '' then
            str = '_character_' .. value .. '.png'
        elseif color == 2 then
            str = '_bamboo_' .. value .. '.png'
        elseif color == 1 then
            str = '_dot_' .. value .. '.png'
        elseif color == 3 then
            str = szFengStr[value]
        end
        local szDirect = {}
        if self.is_pmmj then
            szDirect = {'BB','RR','UU','LL'}
        else
            szDirect = {'B','R','B','L'}
        end
        if direct == 1 then
            if status == nil then
                if self.is_pmmj then
                    str = 'MM' .. str
                else
                    str = 'M' .. str
                end
            elseif status == "_stand" then
                str = szDirect[direct] .. str
            end
        else
            str = szDirect[direct] .. str
        end
        card = self:createCardWithSpriteFrameName(str)
        --print(card:getContentSize().width)
        --print(card:getContentSize().height)
        if direct == 1 then
            if self.is_pmmj then
                card:setScale(card:getScale()*MJCardPosition.hand_card_2dbig_scale)
            else
                card:setScale(card:getScale()*MJCardPosition.hand_card_2d_scale)
            end
        elseif direct == 3 and status == "_stand" then
            if self.is_pmmjyellow then
                local scalearg = 38/card:getContentSize().width
                card:setScaleX(scalearg)
                card:setScaleY(scalearg)
            end
        end
    else
        if direct == 1 then
            if status == nil then
                card = cc.Sprite:create(self.res3DPath.."/img_normal_card.png")
                card:setScale(0.55*self.single_scale)

                local img_value = cc.Sprite:create(self.res3DPath.."/img_cardvalue"..color..value..".png")
                img_value:setAnchorPoint(-0.1, -0.1)
                card:addChild(img_value)

                --print(card:getContentSize().width)
                --print(card:getContentSize().height)
            elseif status == "_stand" then
                card = cc.Sprite:create(self.res3DPath.."/Frame_ziji_pingpaizheng_11.png")
                card:setScale(0.7*self.single_scale)
                local img_value = cc.Sprite:create(self.res3DPath.."/img_cardvalue"..color..value..".png")
                img_value:setAnchorPoint(-0.2, -0.45)
                img_value:setScale(0.6)
                card:addChild(img_value)

                --print(card:getContentSize().width)
                --print(card:getContentSize().height)
            end
        elseif direct == 2 then
            card = cc.Sprite:create(self.res3DPath.."/righthand/Frame_youjia_pingpai_zheng_14.png")
            card:setScale(0.53*self.single_scale)

            local img_value = cc.Sprite:create(self.res3DPath.."/righthand/ing_youjia_y_"..color..value..".png")
            img_value:setAnchorPoint(-0.2, -0.98)
            img_value:setScale(0.85)
            img_value:setSkewX(5)
            card:addChild(img_value)
        elseif direct == 4 then
            card = cc.Sprite:create(self.res3DPath.."/lefthand/Frame_zuojia_pingpai_zheng_14.png")
            card:setScale(0.53*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/lefthand/ing_zuojia_z_"..color..value..".png")
            img_value:setAnchorPoint(-0.14, -0.98)
            img_value:setScale(0.85)
            img_value:setSkewX(-5)
            card:addChild(img_value)
        else
            card = cc.Sprite:create(self.res3DPath.."/uphand/Frame_shangjia_pingpai_zheng_11.png")
            card:setScale(0.7*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/img_cardvalue"..color..value..".png")
            img_value:setAnchorPoint(-0.34, -0.74)
            img_value:setScale(0.35)
            img_value:setFlippedY(true)
            img_value:setFlippedX(true)
            card:addChild(img_value)
        end
        if direct == 1 then
            card:setScale(card:getScale()*MJCardPosition.hand_card_3d_scale)
        end
    end

    if not bOpenCard then
        for k, v in ipairs(self.wang_cards) do
            if v == paramPokerId then
                local wang = cc.Sprite:create(self.haoZi)
                if self.is_pmmj or self.is_pmmjyellow then
                    if direct == 1 then
                        if status == nil then
                            wang:setAnchorPoint(0, 0)
                            wang:setScaleX(card:getContentSize().width/wang:getContentSize().width)
                            wang:setScaleY(card:getContentSize().height/wang:getContentSize().height)
                            wang:setPosition(0,0)
                        elseif status == "_stand" then
                            local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                            wang:setScale(lnMaxScale)
                            wang:setAnchorPoint(1, 1)
                            wang:setPosition(card:getContentSize().width - 6*lnMaxScale,card:getContentSize().height+19*lnMaxScale)
                        end
                    elseif direct == 2 then

                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(270)
                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2 - 6*lnMaxScale, card:getContentSize().height/2 - 6*lnMaxScale)

                    elseif direct == 3 then
                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(180)
                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2, card:getContentSize().height/2)

                    elseif direct == 4 then
                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(90)
                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2 + 6*lnMaxScale, card:getContentSize().height/2+28*lnMaxScale)
                    end
                else
                    wang:setScale(1.5)
                    if direct == 1 then
                        if status == nil then
                            wang:setAnchorPoint(0,0)
                            wang:setScaleX(card:getContentSize().width/wang:getContentSize().width)
                            wang:setScaleY(card:getContentSize().height/wang:getContentSize().height)
                            wang:setPosition(0,10)
                        elseif status == "_stand" then
                            wang:setAnchorPoint(0,0)
                            wang:setScaleX(card:getContentSize().width/wang:getContentSize().width)
                            wang:setScaleY(card:getContentSize().height/wang:getContentSize().height)
                            wang:setPosition(-10,20)
                        end
                    elseif direct == 2 then
                        wang:setAnchorPoint(-0.46, -0.54)
                        if self.mjGameName == '丰宁' then
                            wang:setRotation(-90)
                            wang:setPosition(175, -20)
                            wang:setScale(1)
                        end
                    elseif direct == 3 then
                        wang:setAnchorPoint(-0.15,-2.1)
                        wang:setFlippedX(true)
                        wang:setFlippedY(true)
                        if self.mjGameName == '丰宁' then
                            wang:setScale(1)
                            wang:setPosition(-3, -220)
                        end
                    elseif direct == 4 then
                        wang:setAnchorPoint(-1.26,-0.54)
                        if self.mjGameName == '丰宁' then
                            wang:setScale(1)
                            wang:setPosition(-80, -60)
                        end
                    end
                end
                card:addChild(wang)
                break
            end
        end
    end
    return card
end

function MJBaseScene:getBackCard(direct)
    local card = nil
    local szBack = {}
    local str = ""
    if self.is_pmmj then
        szBack = {nil,
                    'ee_mj_right.png',
                    'ee_mj_up.png',
                    'ee_mj_left.png',
                    }
        str = szBack[direct]
        card = self:createCardWithSpriteFrameName(str)
    elseif self.is_pmmjyellow then
        szBack = {nil,
                    'e_mj_right.png',
                    'e_mj_up.png',
                    'e_mj_left.png',
                    }
        str = szBack[direct]
        card = self:createCardWithSpriteFrameName(str)
    else
        if direct == 2 then
            card = cc.Sprite:create(self.res3DPath.."/righthand/Frame_youjia_shupai_14.png")
            card:setScale(0.45)
            card:setRotation(2)
        elseif direct == 4 then
            card = cc.Sprite:create(self.res3DPath.."/lefthand/Frame_zuojia_shupai_14.png")
            card:setScale(0.45)
            card:setRotation(-2)
        else
            card = cc.Sprite:create(self.res3DPath.."/uphand/Frame_shangjia_shupai_9.png")
            card:setScale(0.61)
        end
    end
    return card
end

function MJBaseScene:getOpenCardById(direct, paramPokerId, bOpenCard)
    -- 报听打出的牌，其它玩家收到是0，自己收到的是减去0x80得真实值
    if 0 == paramPokerId or paramPokerId > 0x80 then
        if self.is_pmmj or self.is_pmmjyellow then
            local szTingBack = {}
            if self.is_pmmj then
                szTingBack = {'ee_mj_b_up.png',
                                'ee_mj_b_right.png',
                                'ee_mj_b_up.png',
                                'ee_mj_b_left.png',
                                    }
                szDirectPre = {'BB','RR','UU','LL'}
            else
                szTingBack = {'e_mj_b_up.png',
                                    'e_mj_b_right.png',
                                    'e_mj_b_up.png',
                                    'e_mj_b_left.png',
                                }
                szDirectPre = {'B','R','U','L'}
            end
            local str = szTingBack[direct]
            local card = self:createCardWithSpriteFrameName(str)
            local normal_direct_size = direct
            if direct == 1 then
                normal_direct_size = 3
            end

            local width = 43
            local height = 52
            -- 经典
            -- 上下宽度：38
            -- 左右长度：42
            -- 大牌：
            -- 上下宽度：43
            -- 左右长度：58
            -- 16:35:09
            -- 中草药 2018/8/8 16:35:09
            -- 大牌的左右算错了 是52
            local scalearg
            if self.is_pmmjyellow then
                if direct == 1 or direct == 3 then
                    scalearg = 38/card:getContentSize().width
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                elseif direct == 2 or direct == 4 then
                    scalearg = 42/card:getContentSize().height
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                end
            else
                if direct == 1 or direct == 3 then
                    scalearg = 43/card:getContentSize().width
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                elseif direct == 2 or direct == 4 then
                    scalearg = 52/card:getContentSize().height
                    card:setScaleX(scalearg)
                    card:setScaleY(scalearg)
                end
            end
            return card
        else
            local card = nil
            local col = #self.out_card_list[direct]
            local colNum = self.out_row_nums
            local row = math.floor(col/colNum)+1
            row = math.min(row, 3)

            if direct == 2 then
                col = math.min(col%colNum+1, colNum-1)
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backtingyou/Frame_youjia_' .. row..'_'..col..'.png')
                card:setScale(0.6*self.single_scale)
                local add_row = 0
                if row == 2 then
                    card:setAnchorPoint(0.5+col*0.01, 0.5)
                elseif row == 3 then
                    add_row = -0.03
                end
            elseif direct == 4 then
                col =math.min(colNum-col%colNum, colNum-1)
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backtingzou/Frame_zuojia_'..row.."_"..col..".png")
                card:setScale(0.6*self.single_scale)
                if row == 2 then
                    card:setAnchorPoint(0.5+(colNum-col)*0.014, 0.5)
                end
            elseif direct == 3 then
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backting3.png')
                card:setScaleX(86/74*0.6*self.single_scale)
                card:setScaleY(119/94*0.6*self.single_scale)
            else
                card = cc.Sprite:create('ui/qj_mj/3d/ting_back/backting1.png')
                card:setScale(0.52*self.single_scale)
            end
            local cardScaleX = card:getScaleX()
            local cardScaleY = card:getScaleY()
            card:setScaleX(cardScaleX*MJCardPosition.out_card_3d_scale)
            card:setScaleY(cardScaleY*MJCardPosition.out_card_3d_scale)
            return card
        end
    end

    local color = math.floor(paramPokerId/16)
    color = math.min(color, 4)
    if color > 4 or color < 0 then
        commonlib.showLocalTip("花色不正确")
        return
    end
    local value = paramPokerId%16
    if value > 9 or value <=0 then
        commonlib.showLocalTip("牌值不正确")
        return
    end

    if color == 0 then
        color = ""
    elseif color == 4 then
        value = value + 4
        color = 3
    end

    local card = nil
    if self.is_pmmj or self.is_pmmjyellow then
        -- 条 M_bamboo_
        -- 万 M_character_
        -- 筒 M_dot_
        -- 东M_wind_east 南M_wind_south  西M_wind_west 北M_wind_north 中 M_red 发 M_green  白 M_white
        local szFengStr = {
                            '_wind_east.png',
                            '_wind_south.png',
                            '_wind_west.png',
                            '_wind_north.png',
                            '_red.png',
                            '_green.png',
                            '_white.png',
                        }
        local str =''
        if color == '' then
            str = '_character_' .. value .. '.png'
        elseif color == 2 then
            str = '_bamboo_' .. value .. '.png'
        elseif color == 1 then
            str = '_dot_' .. value .. '.png'
        elseif color == 3 then
            str = szFengStr[value]
        end
        local szDirect = {}
        if self.is_pmmj then
            szDirect = {'BB','RR','BB','LL'}
        else
            szDirect = {'B','R','B','L'}
        end
        str = szDirect[direct] .. str

        card = self:createCardWithSpriteFrameName(str)

        local normal_direct_size = direct
        if direct == 1 then
            normal_direct_size = 3
        end
        local width = 43
        local height = 52
        -- 经典
        -- 上下宽度：38
        -- 左右长度：42
        -- 大牌：
        -- 上下宽度：43
        -- 左右长度：58
        -- 16:35:09
        -- 中草药 2018/8/8 16:35:09
        -- 大牌的左右算错了 是52
        --
        local scalearg
        if self.is_pmmjyellow then
            if direct == 1 or direct == 3 then
                scalearg = 38/card:getContentSize().width
                card:setScaleX(scalearg)
                card:setScaleY(scalearg)
            elseif direct == 2 or direct == 4 then
                if card == nil then
                    local errStr = string.format("createWithSpriteFrameName = %s",tostring(str))
                    gt.uploadErr(errStr)
                end
                scalearg = 42/card:getContentSize().height
                card:setScaleX(scalearg)
                card:setScaleY(scalearg)
            end
        else
            if direct == 1 or direct == 3 then
                scalearg = 43/card:getContentSize().width
                card:setScaleX(scalearg)
                card:setScaleY(scalearg)
            elseif direct == 2 or direct == 4 then
                card:setScaleX(61/card:getContentSize().width)
                card:setScaleY(48/card:getContentSize().height)
            end
        end
    else
        local col = #self.out_card_list[direct]
        local colNum = self.out_row_nums
        local row = math.floor(col/colNum)+1
        row = math.min(row, 3)

        if direct == 2 then
            col = math.min(col%colNum+1, colNum-1)
            card = cc.Sprite:create(self.res3DPath.."/righthand/dachupai/Frame_youjia_"..row.."_"..col..".png")
            card:setScale(0.6*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/righthand/dachupai/ing_youjia_"..row.."_"..color..value..".png")
            card:addChild(img_value)
            local add_row = 0
            if row == 2 then
                card:setAnchorPoint(0.5+col*0.01, 0.5)
            elseif row == 3 then
                add_row = -0.03
            end
            -- if self.desk_ys  == "card" then
            if col >=5 then
                img_value:setAnchorPoint(-0.07+add_row, -0.74)
            else
                img_value:setAnchorPoint(-0.07+add_row, -0.82)
            end
            -- else
            --     if col >=5 then
            --         img_value:setAnchorPoint(-0.1+add_row, -0.74)
            --     else
            --         img_value:setAnchorPoint(-0.1+add_row, -0.82)
            --     end
            -- end
        elseif direct == 4 then
            col =math.min(colNum-col%colNum, colNum-1)
            card = cc.Sprite:create(self.res3DPath.."/lefthand/dachupai/Frame_zuojia_"..row.."_"..col..".png")
            card:setScale(0.6*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/lefthand/dachupai/ing_zuojia_"..row.."_"..color..value..".png")
            card:addChild(img_value)
            if row == 2 then
                card:setAnchorPoint(0.5+(colNum-col)*0.014, 0.5)
            end
            -- if col >=5 and self.desk_ys == "card2" then
            --     img_value:setAnchorPoint(-0.07, -0.74)
            -- else
            img_value:setAnchorPoint(-0.07, -0.82)
            -- end
        elseif direct == 3 then
            card = cc.Sprite:create(self.res3DPath.."/img_spe_backcard.png")
            card:setScale(0.57*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/img_cardvalue"..color..value..".png")
            img_value:setAnchorPoint(-0.29, -0.61)
            img_value:setScale(0.45)
            img_value:setFlippedY(true)
            img_value:setFlippedX(true)
            card:addChild(img_value)
        else
            card = cc.Sprite:create(self.res3DPath.."/Frame_ziji_pingpaizheng_11.png")
            card:setScale(0.52*self.single_scale)
            local img_value = cc.Sprite:create(self.res3DPath.."/img_cardvalue"..color..value..".png")
            img_value:setAnchorPoint(-0.2, -0.45)
            img_value:setScale(0.6)
            card:addChild(img_value)
        end
        card:setScale(card:getScale()*MJCardPosition.out_card_3d_scale)
    end

    if not bOpenCard then
        for k, v in ipairs(self.wang_cards) do
            if v == paramPokerId then
                local wang = cc.Sprite:create(self.haoZi)
                local card_size  = card:getContentSize()
            if self.is_pmmj or self.is_pmmjyellow then
                if direct == 1 then
                    local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)

                        wang:setAnchorPoint(1, 1)
                        wang:setPosition(card_size.width-8*lnMaxScale,card_size.height+16*0.81*self.single_scale)
                    elseif direct == 2 then
                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(270)
                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.78*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.78*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2 - 6*lnMaxScale, card:getContentSize().height/2-6*lnMaxScale)
                    elseif direct == 3 then
                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(180)

                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2 , card:getContentSize().height/2)
                    elseif direct == 4 then
                        wang:setAnchorPoint(0.5, 0.5)
                        wang:setRotation(90)

                        local lnMaxScale = math.max(card:getContentSize().width/wang:getContentSize().width*0.81*self.single_scale,
                                            card:getContentSize().height/wang:getContentSize().height*0.81*self.single_scale)
                        wang:setScale(lnMaxScale)
                        wang:setPosition(card:getContentSize().width/2 + 8*lnMaxScale, card:getContentSize().height/2+24*0.81*self.single_scale)
                    end
                else
                    if direct == 1 then
                        wang:setAnchorPoint(1, 0.78)
                        wang:setPosition(card_size.width-2, card_size.height-2)
                    elseif direct == 2 then
                        wang:setRotation(270)
                        wang:setAnchorPoint(1, 0.78)
                        wang:setPosition(cc.p(10, card_size.height+2))
                    elseif direct == 3 then
                        wang:setFlippedX(true)
                        wang:setFlippedY(true)
                        wang:setAnchorPoint(1, 0.78)
                        wang:setPosition(cc.p(card_size.width-6, card_size.height-20))
                    elseif direct == 4 then
                        wang:setRotation(90)
                        wang:setAnchorPoint(1, 0.78)
                        wang:setPosition(cc.p(card_size.width-10, 40))
                    end
                end
                card:addChild(wang)
                break
            end
        end
    end
    card:setColor(cc.c3b(226,226,226))
    return card
end

function MJBaseScene:showWatcher(direct, time)
    if not direct then
        return
    end
    direct = tonumber(direct)
    time = time or 15
    ccui.Helper:seekWidgetByName(self.node,'ImgTime'):setVisible(self.is_pmmjyellow or false)
    ccui.Helper:seekWidgetByName(self.node,'Img-zj'):setVisible(self.is_pmmj or false)
    ccui.Helper:seekWidgetByName(self.node,'Img-zj_3d'):setVisible(self.is_3dmj or false)
    self.watcher_lab:setVisible(self.is_pmmj or self.is_3dmj or false)
    if self.is_pmmjyellow then
        self.direct_img_cur = direct
        for i = 1 , 4 do
            ccui.Helper:seekWidgetByName(self.node,'ImgArrow' .. i):setVisible(i == direct)
        end
        time = math.min(time, 15)
        self.tTimeCout:stopAllActions()
        self.tTimeCout:setColor(cc.c3b(255, 255, 255))
        self.tTimeCout:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
            self.tTimeCout:setString(string.format("%02d", time))
            if time == 5 then
                self.tTimeCout:setColor(cc.c3b(255, 0, 0))
            end
            if time <= 5 and time%2==0 then
                AudioManager:playDWCSound("sound/mj/act_timer_laster.mp3")
            end
            if time <= 0 then
                self.tTimeCout:stopAllActions()
            end
            time = time-1
        end), cc.DelayTime:create(1))))
        return
    elseif self.is_pmmj or self.is_3dmj then
        self:stopSouthAction()

        self.direct_img_cur = direct
        for i = 1 , 4 do
            self.direct_list[i]:setVisible(i == self.direct_img_cur)
        end

        self.direct_list[self.direct_img_cur]:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.DelayTime:create(2), cc.FadeTo:create(0.5, 100))))
        time = math.min(time, 15)
        self.watcher_lab:stopAllActions()
        self.watcher_lab:setColor(cc.c3b(255, 255, 255))
        self.watcher_lab:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
            self.watcher_lab:setString(string.format("%02d", time))
            if time == 5 then
                self.watcher_lab:setColor(cc.c3b(255, 0, 0))
            end
            if time <= 5 and time%2==0 then
                AudioManager:playDWCSound("sound/mj/act_timer_laster.mp3")
            end
            if time <= 0 then
                self.watcher_lab:stopAllActions()
            end
            time = time-1
        end), cc.DelayTime:create(1))))
    end
end

function MJBaseScene:discoreCursor()
    self.cursor:stopAllActions()
    self.pre_out_direct = nil
    self.pos = nil
    self.cursor:setVisible(false)
    self.cursor:setPositionY(0)
end

function MJBaseScene:showCursor()
    self.cursor:stopAllActions()
    if self.pre_out_direct and self.pos then
        local card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
        if card then
            self.cursor:runAction(
                cc.Sequence:create(cc.DelayTime:create(0.15),
                    cc.CallFunc:create(
                        function()
                            self.cursor:setVisible(true)
                            self.cursor:setPosition(self.pos)
                            self.cursor:runAction(
                                cc.RepeatForever:create(
                                    cc.Sequence:create(
                                        cc.MoveBy:create(1.2, cc.p(0, -10)),
                                        cc.MoveBy:create(1.2, cc.p(0, 10))
                                        )
                                    )
                                )
                        end
                    )
                )
            )
        else
            self.cursor:setVisible(false)
            self.cursor:setPositionY(0)
        end
    else
        self.cursor:setVisible(false)
        self.cursor:setPositionY(0)
    end
end

function MJBaseScene:chiOptTreat(open_value, target_value)

end

function MJBaseScene:stenHead(head_node, scale)
    local scale = scale or 0.5
    local size = head_node:getContentSize()

    local img_head = cc.Sprite:create("ui/qj_mj/img_head.png")
    img_head:setAnchorPoint(cc.p(0.5, 0.5))
    img_head:setScale(scale)
    head_node:addChild(img_head)
    img_head:setPosition(cc.p(size.width*0.5, size.height*0.5))
    return img_head
end

function MJBaseScene:initSouthPan()
    -- 东 北 西 南
    local dir_name_list = {"dong", "bei", "xi", "nan"}
    local dir_3d_name_list = {'3dbottom','3dright','3dup','3dleft'}
    local dir_3d_texture = {'east','north','west','south'}
    self.direct_list = {}
    local people_num = 4
    for i=1, people_num do
        local dir_index = i-self.banker+1
        if dir_index <= 0 then
            dir_index = dir_index+people_num
        end

        if self.is_3dmj then
            local dir_img = ccui.Helper:seekWidgetByName(self.southPan3d,"Img-"..dir_3d_name_list[i])
            table.insert(self.direct_list,dir_img)
            dir_img:setVisible(false)

            local Img_direct = tolua.cast(ccui.Helper:seekWidgetByName(self.southPan3d,"Img_direct"..i), "ccui.ImageView")
            Img_direct:loadTexture('ui/qj_mj/3d/pan/'.. dir_3d_texture[dir_index] .. i ..'.png')
        else
            local dir_img = ccui.Helper:seekWidgetByName(self.southPan,"Img-"..dir_name_list[dir_index])
            table.insert(self.direct_list,dir_img)
            dir_img:setVisible(false)
        end
    end

    print('庄家 ',self.banker)
    if self.banker == 1 then
        self.southPan:setRotation(270)
    elseif self.banker == 2 then
        self.southPan:setRotation(180)
    elseif self.banker == 3 then
        self.southPan:setRotation(90)
    elseif self.banker == 4 then
        self.southPan:setRotation(0)
    end

    print('翻转',self.southPan:getRotation())
end

function MJBaseScene:isAnyHu(card_id)
    local hu_list = self.ting_list and self.ting_list[card_id]
    if hu_list and table.maxn(hu_list) >= 27 then
        self.ting_tip_layer:setVisible(true)
        self.ting_tip_layer:getChildByName('ImgAnyHu'):setVisible(true)


        for i=1, 10  do
            local ting_item = self.ting_tip_layer.pai_list[i]

            if ting_item.pai then
                ting_item.pai:removeFromParent(true)
                ting_item.pai = nil
            end
            ting_item.ori_pai:setVisible(false)
        end
        return true
    end
    self.ting_tip_layer:getChildByName('ImgAnyHu'):setVisible(false)
    return false
end

function MJBaseScene:resetHightCard()
    for i, v in ipairs(self.light_list or {}) do
        for __, vv in ipairs(v) do
            if i == 1 then
                vv:setColor(cc.c3b(255, 255, 255))
            else
                vv:setColor(cc.c3b(226, 226, 226))
            end
        end
    end
    self.light_list = {{},{}}
end

function MJBaseScene:checkTingTip(card_id)
    if GameGlobal.MjSceneReplaceMJScene then
        return
    end

    self:resetHightCard()

    if not card_id then
        if self.ting_tip_layer then
            self.ting_tip_layer:setVisible(false)
        end
        return
    end

    if self:isAnyHu(card_id) then
        return
    end

    for k=1, 4 do
        if self.hand_card_list[k] and #self.hand_card_list[k] > 0 then
            for __, v in ipairs(self.hand_card_list[k]) do
                if v.sort ~= 0 and v.card_id and v.card_id == card_id and not v.isKe then
                    self.light_list[1][#self.light_list[1]+1] = v
                    v:setColor(cc.c3b(96, 96, 96))
                end
            end
        end
        if self.out_card_list[k] and #self.out_card_list[k] > 0 then
            for __, v in ipairs(self.out_card_list[k]) do
                if v.card_id and v.card_id == card_id then
                    self.light_list[2][#self.light_list[2]+1] = v
                    v:setColor(cc.c3b(96, 96, 96))
                end
            end
        end
    end

    if not self.ting_tip_layer then
        return
    end

    local hu_list = self.ting_list[card_id]
    if hu_list and #hu_list > 0 then
        self.ting_tip_layer:setVisible(true)
        -- 听字
        self:setTingTitleVisible(self.tdh_need_bTing)

        for i=1, 10  do
            local ting_item = self.ting_tip_layer.pai_list[i]

            if ting_item.pai then
                ting_item.pai:removeFromParent(true)
                ting_item.pai = nil
            end

            if not hu_list[i] then
                ting_item.ori_pai:setVisible(false)
            else
                ting_item.ori_pai:setVisible(true)
                ting_item.pai = self:getCardById(1, hu_list[i][1], "_stand")
                if self.is_pmmj or self.is_pmmjyellow then
                    ting_item.pai:setScale(0.8)
                else
                    ting_item.pai:setScale(0.45)
                end
                ting_item.pai:setPosition(ting_item.pos)
                self.ting_tip_layer:addChild(ting_item.pai, 1)
                ting_item.num:setString(hu_list[i][2].."张")
            end
        end
    else
        self.ting_tip_layer:setVisible(false)
    end
end

function MJBaseScene:handCardBaseIndex(direct)
    local base_index = 0
    for __, h_c in ipairs(self.hand_card_list[direct]) do
        if h_c.sort ~= 0 then
            base_index = base_index+1
        end
    end
    return base_index
end

function MJBaseScene:removeShowPai()
    local ShowPai = self.node:getChildByName('ShowPai')
    if ShowPai then
        ShowPai:stopAllActions()
        ShowPai:removeFromParent(true)
        ShowPai = nil
        self.show_pai = nil
        self.show_pai_out = nil
    end
end

function MJBaseScene:openCard(direct, card_ids, opt_type, check_ac, lnLastUser)
    logUp('MJBaseScene:openCard')

    log('direct ' .. tostring(direct))
    local str = ''
    for i = 1,#card_ids do
        str = str .. tonumber(card_ids[i]) .. '-'
    end
    log('card_ids ' .. str)

    log('opt_type ' .. tostring(opt_type))

    log('check_ac ' .. tostring(check_ac))

    log('lnLastUser ' .. tostring(lnLastUser))

    self:removeShowPai()

    if not card_ids then
    elseif #card_ids == 1 and opt_type < 10 then
        local card_value = card_ids[1]
        if card_value > 0x80 then
            card_ids[1] = card_ids[1] - 0x80
            card_value = 0
        end
        local card = nil
        if direct == 1 then
            for i=#self.hand_card_list[direct], 1, -1 do
                local v = self.hand_card_list[direct][i]
                if v.sort == 0 and v.card_id == card_ids[1] then
                    card = v
                    break
                end
            end
        elseif self.is_playback then
            for i=#self.hand_card_list[direct], 1, -1 do
                local v = self.hand_card_list[direct][i]
                if v.sort == -1 and v.card_id == card_ids[1] then
                    card = v
                    break
                end
            end
        else
            if not direct or not self.hand_card_list[direct] or not self.hand_card_list[direct][#self.hand_card_list[direct]] then
                local errStr = self:mjUploadError('openCard',tostring(self.open_card_server_index),tostring(direct))
                gt.uploadErr(errStr)
                log(errStr)
                local errStr = getPlayerDataDebugStr()
                gt.uploadErr(errStr)
                log(errStr)
            end
            card = self.hand_card_list[direct][#self.hand_card_list[direct]]  -- need
        end

        if self.show_pai then
            if self.show_pai.card then
                self.show_pai.card:setVisible(true)
                self.show_pai.card = nil
            end
            self.show_pai:removeFromParent(true)
            self.show_pai = nil
        end

        if card then
            if 14 == #self.hand_card_list[direct] then
                local startPosX,startPosY = nil
                for ii, cc in ipairs(self.hand_card_list[direct]) do
                    if cc == card then
                        table.remove(self.hand_card_list[direct], ii)
                        startPosX, startPosY = card:getPosition()
                        card:removeFromParent(true)
                        card = nil
                        break
                    end
                end
            else
                print('Unknown error open card')
            end

            if direct == 1 or self.is_playback then
                self:sortHandCard(direct)
                self:placeHandCard(direct)
            end
                local show_pai = self.show_pai
                local bigger_scale = 1
                if direct ~= 3 or direct ~= 1 then
                    bigger_scale = 1.25
                end
                local show_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_chupai_img.png")
                if not show_pai then
                    show_pai = self:getCardById(1, card_value, "_stand", true)
                    if show_pai == nil then
                        local errStr = string.format("card_value = %s",tostring(card_value))
                        gt.uploadErr(errStr)
                    end
                    show_pai:setPosition(self.open_card_pos_list[direct])
                    self.node:addChild(show_pai, 150)
                    show_pai:setName('ShowPai')

                    if self.is_pmmj or self.is_pmmjyellow then
                        show_pai_bg:setScale(0.8)
                        show_pai_bg:setAnchorPoint(0.05, 0.02)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-12,show_pai_bg:getPositionY()-10))
                    else
                        show_pai_bg:setScale(1.3)
                        show_pai_bg:setAnchorPoint(0.02, 0.03)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-17.5,show_pai_bg:getPositionY()-10))
                    end
                else
                    if self.is_pmmj or self.is_pmmjyellow then
                        show_pai_bg:setScale(0.8)
                        show_pai_bg:setAnchorPoint(0.05, 0.02)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-12,show_pai_bg:getPositionY()-10))
                    else
                        show_pai_bg:setScale(1.3)
                        show_pai_bg:setAnchorPoint(0.06, 0.08)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-17.5,show_pai_bg:getPositionY()-10))
                    end
                end
                if card_value ~= 0 then
                    show_pai:addChild(show_pai_bg,-1)
                end

                local nMaxScale = math.max(show_pai:getScaleX(),show_pai:getScaleY())

                if 0 ~= card_value then
                    show_pai_bg:setOpacity(0)
                    show_pai_bg:runAction(cc.FadeTo:create(0.2, 255))
                end

                show_pai:runAction(cc.Spawn:create(cc.ScaleTo:create(0.07, nMaxScale*bigger_scale), cc.MoveTo:create(0.07, self.open_card_pos_list[direct])))

                self.show_pai_out = show_pai
            local is_tingpai_inrecord = nil
            if self.soundTing and self.is_playback and card_value == 0 then
                card_value = card_ids[1]
                is_tingpai_inrecord = true
            end
            local pai = self:getOpenCardById(direct, card_value, true)
            pai.card_id = card_value
            if is_tingpai_inrecord then
                pai:setColor(cc.c3b(96,96,96))
                is_tingpai_inrecord = nil
            end
            local nRow = math.floor((#self.out_card_list[direct]) / (self.out_row_nums))
            local nCow = (#self.out_card_list[direct]) % (self.out_row_nums)

            local pos = self:getOutCardPosition(direct,nRow,nCow)

            self.pos = pos
            local poshand = cc.p(self.hand_card_pos_list[direct].init_pos.x, self.hand_card_pos_list[direct].init_pos.y)
            if startPosX and startPosY then
                poshand = cc.p(startPosX,startPosY)
            end
            if direct == 1 and self.selected_card_posx and self.selected_card_posy then
                pai:setPosition(self.selected_card_posx,self.selected_card_posy)
            else
                pai:setPosition(poshand)
            end
            local action = cc.MoveTo:create(0.1,self.pos)
            pai:runAction(action)
            pai:setLocalZOrder(self:getOutCardZOrder(direct,nRow,nCow))

            self.node:addChild(pai)

            self.out_card_list[direct][#self.out_card_list[direct]+1] = pai

            self:showCursor()

            self:showAction()

            AudioManager:playDWCSound("sound/mj/card_send_effect.mp3")

            print("open  ", pai.card_id)
        end
    else
        if (opt_type >=1 and opt_type < 4) or (opt_type >= 10) then
            self:openMultCard(direct, card_ids, opt_type, lnLastUser)
        end
    end

    self:playOpenCardAnimation(direct,opt_type)

    self:playOpenCardSound(direct,opt_type)
end

function MJBaseScene:penGangCard(param)
    local direct   = param.direct
    local card_ids = param.card_ids
    local bu_gang  = param.bu_gang
    local sort_max = param.sort_max
    local last_i   = param.last_i
    local opt_type = param.opt_type
    local hua_pai4 = param.hua_pai4

    for i, v_id in ipairs(card_ids) do
        for ii, v in ipairs(self.hand_card_list[direct]) do
            if v.card_id == v_id and (v.sort == 0 or ((bu_gang or hua_pai4) and v.sort ~= sort_max)) then
                v.card_id = v_id
                v.sort = sort_max
                last_i = ii
                if opt_type == 21 then
                    if #card_ids > 3 or #card_ids == 1 then
                        if i == #card_ids then
                            table.remove(self.hand_card_list[direct], ii)
                            v:removeFromParent(true)
                        end
                    end
                    break
                else
                    if #card_ids >= 3 and opt_type ~= 14 and opt_type ~= 22 then
                        if i == #card_ids then
                            table.remove(self.hand_card_list[direct], ii)
                            v:removeFromParent(true)
                        end
                    end
                    break
                end
            end
        end
    end
    return last_i
end


function MJBaseScene:pengGangReplayCard(param)
    local direct   = param.direct
    local card_ids = param.card_ids
    local bu_gang  = param.bu_gang
    local sort_max = param.sort_max
    local last_i   = param.last_i
    local opt_type = param.opt_type
    local hua_pai4  = param.hua_pai4
    for i, v_id in ipairs(card_ids) do
        for ii, v in ipairs(self.hand_card_list[direct]) do
            if v.card_id == v_id and (v.sort == -1 or ((bu_gang) and v.sort ~= sort_max)) then
                v.card_id = v_id
                v.sort = sort_max
                last_i = ii
                if opt_type == 21 then
                    if #card_ids > 3 or #card_ids == 1 then
                        if i == #card_ids then
                            table.remove(self.hand_card_list[direct], ii)
                            v:removeFromParent(true)
                        end
                    end
                    break
                else
                    if #card_ids >= 3 and opt_type ~= 14 and opt_type ~= 22 then
                        if i == #card_ids then
                            table.remove(self.hand_card_list[direct], ii)
                            v:removeFromParent(true)
                        end
                    end
                    break
                end
            end
        end
    end
    return last_i
end

function MJBaseScene:openMultCard(direct, card_ids, opt_type, lnLastUser)
    local CHI_OPT_TYPE = 1
    local PENG_OPT_TYPE = 2
    print('MJBaseScene:openMultCard')
    print('direct ' .. tostring(direct))
    local str = ''
    for i = 1,#card_ids do
        str = str .. card_ids[i] .. '-'
    end
    print('card_ids ' .. str)
    print('opt_type ' .. tostring(opt_type))
    local sort_max = 0
    if self.isKouPai then
        sort_max = 1
    end
    for ii, cc in ipairs(self.hand_card_list[direct]) do
        sort_max = math.max(cc.sort, sort_max)
    end
    sort_max       = sort_max+1
    local bu_gang  = (opt_type >= 10 and opt_type < 21)
    local hua_pai4 = (opt_type == 21 and #card_ids == 4)
    local bu_hua   = (opt_type == 21 and #card_ids == 1)
    if bu_hua then
        self.huaCount[direct] = self.huaCount[direct] + 1
    end
    local last_i   = 2
    -- 吃
    if opt_type == CHI_OPT_TYPE then
        card_ids[3] = nil
    end
    -- 清除手中下砍的牌
    if direct == 1 then
        local param = {
            direct   = direct,
            card_ids = card_ids,
            bu_gang  = bu_gang,
            sort_max = sort_max,
            last_i   = last_i,
            opt_type = opt_type,
            hua_pai4 = false,
        }
        last_i = self:penGangCard(param)
    elseif self.is_playback then
        local param = {}
        param.direct   = direct
        param.card_ids = card_ids
        param.bu_gang  = bu_gang
        param.sort_max = sort_max
        param.last_i   = last_i
        param.opt_type = opt_type
        param.hua_pai4  = false
        last_i = self:pengGangReplayCard(param)
    else
        for i, v_id in ipairs(card_ids) do
            local treat = false
            if bu_gang then
                for ii, v in ipairs(self.hand_card_list[direct]) do
                    if v.sort ~= sort_max and v.card_id == v_id then
                        v.card_id = v_id
                        v.sort = sort_max
                        last_i = ii
                        if #card_ids >= 3 and opt_type ~= 14 then
                            if i == #card_ids then
                                table.remove(self.hand_card_list[direct], ii)
                                v:removeFromParent(true)
                            end
                        end
                        treat = true
                        break
                    end
                end
            end
            if not treat then
                for ii, v in ipairs(self.hand_card_list[direct]) do
                    if v.sort == 0 then
                        v.card_id = v_id
                        v.sort = sort_max
                        last_i = ii
                        if opt_type == 21 then
                            if #card_ids > 3 or #card_ids == 1 then
                                if i == #card_ids then
                                    table.remove(self.hand_card_list[direct], ii)
                                    v:removeFromParent(true)
                                end
                            end
                            break
                        else
                            if #card_ids >= 3 and opt_type ~=14 and opt_type ~= 22 then
                                if i == #card_ids then
                                    table.remove(self.hand_card_list[direct], ii)
                                    v:removeFromParent(true)
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    -- 删除桌上的牌成为自己的手牌(下砍的牌)
    if #card_ids ~= 4 and self.pre_out_direct and opt_type ~= 21 and opt_type ~= 22 then
        local last_index = #self.out_card_list[self.pre_out_direct]
        local remove_index = last_index
        local out_card = self.out_card_list[self.pre_out_direct][last_index]
        if out_card and (opt_type ~= 14 or out_card.card_id == card_ids[1]) then
            local pai = nil
            if direct == 1 then
                pai = self:getCardById(direct, out_card.card_id, nil, true)
            else
                pai = self:getBackCard(direct)
            end
            pai.card_id = out_card.card_id
            pai.sort = sort_max
            self:liSiSpecialCardType(pai)
            local i = (#self.hand_card_list[direct])+1
            local pos  = cc.p(self.hand_card_list[direct][i-1]:getPosition())
            pai:setPosition(cc.p(pos.x+self.hand_card_pos_list[direct].space.x, pos.y+self.hand_card_pos_list[direct].space.y))
            self.node:addChild(pai, 1)
            table.insert(self.hand_card_list[direct], last_i, pai)
            if remove_index ~= last_index then
                self.out_card_list[self.pre_out_direct][last_index]:setPosition(cc.p(self.out_card_list[self.pre_out_direct][remove_index]:getPosition()))
            end
            table.remove(self.out_card_list[self.pre_out_direct], remove_index)
            out_card:removeFromParent(true)
            self.pre_out_direct = nil
            self:showCursor()
        end
    end
    local nIndexCard = 1
    -- 设置下砍的牌
    for ii, vv in ipairs(self.hand_card_list[direct]) do
        if vv.sort == sort_max then
            local showpai = nil
            local pai = nil
            local pscale = nil
            local add_card = nil
            local sadd_card = nil
            if opt_type == 22 then
                pai = self:getCardById(direct, 0, nil, nil, true)
                pai.isKe = true
            else
                pai = self:getCardById(direct, vv.card_id, "_stand",true)
            end
            pai.cardType = opt_type
            if opt_type == 1 then
                pai.cardType = 2
            end
            if nIndexCard == 2 and opt_type ~= 22 then
                self:addOpenCardArrow(pai, direct, lnLastUser)
                if opt_type == 21 then
                    self:addHuaCount(pai, direct, lnLastUser)
                end
            end
            showpai = self:getCardById(1, vv.card_id, "_stand",true)
            if not bu_gang or opt_type%2~=0 or opt_type == 14 then
                add_card = self:getCardById(direct, vv.card_id, "_stand",true)
                add_card:setScale(1)
                sadd_card = self:getCardById(1, vv.card_id, "_stand",true)
                sadd_card:setScale(1)
            else
                if self.is_pmmj or self.is_pmmjyellow then
                    local szGangBack = {}
                    local str = ""
                    local szDirectPre = {}
                    if self.is_pmmj then
                        szGangBack = {'ee_mj_b_up.png',
                                        'ee_mj_b_right.png',
                                        'ee_mj_b_up.png',
                                        'ee_mj_b_left.png',}
                        str = szGangBack[direct]
                        szDirectPre = {'BB','RR','UU','LL'}
                    else
                        szGangBack = {'e_mj_b_up.png',
                                        'e_mj_b_right.png',
                                        'e_mj_b_up.png',
                                        'e_mj_b_left.png',}
                        str = szGangBack[direct]
                        szDirectPre = {'B','R','B','L'}
                    end
                    local szNormal = self:createCardWithSpriteFrameName(szDirectPre[direct] .. '_wind_east.png')

                    add_card = self:createCardWithSpriteFrameName(str)
                    add_card:setScaleX(szNormal:getContentSize().width/add_card:getContentSize().width)
                    add_card:setScaleY(szNormal:getContentSize().height/add_card:getContentSize().height)

                    sadd_card = self:createCardWithSpriteFrameName(szGangBack[1])
                    sadd_card:setScaleX(showpai:getContentSize().width/sadd_card:getContentSize().width)
                    sadd_card:setScaleY(showpai:getContentSize().height/sadd_card:getContentSize().height)
                else
                    add_card = cc.Sprite:create(self.res3DPath.."/back"..direct..".png")
                    sadd_card = cc.Sprite:create(self.res3DPath.."/back1.png")
                    if direct%2 ~= 0 then
                        add_card:setScale(1.4)
                        sadd_card:setScale(1.4)
                    else
                        add_card:setScale(1.8)
                        sadd_card:setScaleX(1.4)
                        sadd_card:setScaleY(1.2)
                    end
                end
            end
            if (bu_gang or hua_pai4) and nIndexCard == 2 and opt_type ~= 14 then
                if self.is_pmmj or self.is_pmmjyellow then
                    if direct%2 == 0 then
                        add_card:setAnchorPoint(0, -0.32)
                    else
                        add_card:setAnchorPoint(0, -0.24)
                    end
                else
                    add_card:setAnchorPoint(0, -0.25)
                end
                self:removeOpenCardArrow(pai, direct)
                pai:addChild(add_card)
                self:addOpenCardArrow(add_card, direct, lnLastUser, true)

                pai.is_gang = add_card

                if self.is_pmmj or self.is_pmmjyellow then
                    if direct%2 == 0 then
                        sadd_card:setAnchorPoint(0, -0.32)
                    else
                        sadd_card:setAnchorPoint(0, -0.24)
                    end
                else
                    sadd_card:setAnchorPoint(0, -0.25)
                end
                showpai:addChild(sadd_card)
            end
            if showpai and opt_type ~= 22 then
                local pp = nIndexCard%3
                local pos = cc.p(self.open_card_ani_pos_list[direct].x, self.open_card_ani_pos_list[direct].y)
                if direct == 1 then
                    pos.y = pos.y + 75
                elseif direct == 2 then
                    pos.x = pos.x - 120
                    pos.y = pos.y - 20
                elseif direct == 3 then
                    pos.y = pos.y -75
                else
                    pos.x = pos.x + 120
                    pos.y = pos.y - 25
                end
                if pp == 2 then
                    showpai:setPosition(pos)
                elseif pp == 1 then
                    showpai:setPosition(cc.p(pos.x-120, pos.y))
                    showpai:runAction(cc.MoveTo:create(0.1,cc.p(pos.x-self.hand_card_pos_list[1].space.x*self.scard_space_scale[1],pos.y)))
                else
                    showpai:setPosition(cc.p(pos.x+120, pos.y))
                    showpai:runAction(cc.MoveTo:create(0.1,cc.p(pos.x+self.hand_card_pos_list[1].space.x*self.scard_space_scale[1],pos.y)))
                end
                self.node:addChild(showpai, 9999)
                showpai:runAction(cc.Sequence:create(cc.DelayTime:create(1.2), cc.RemoveSelf:create()))

                if pp == 1 then
                    local zhezhao = cc.Sprite:create(self.res3DPath.."/Frame_ziji_shoupai-zhezhao.png")
                    if self.is_pmmj or self.is_pmmjyellow then
                        zhezhao:setScale(1.3, 0.5)
                    else
                        zhezhao:setScale(1.4, 0.5)
                    end
                    zhezhao:setAnchorPoint(0.5, 0.5)
                    zhezhao:setPosition(pos)
                    self.node:addChild(zhezhao,9998)
                    zhezhao:runAction(cc.Sequence:create(cc.DelayTime:create(1.2), cc.RemoveSelf:create()))
                end
            end
            if pai then
                pai.sort = sort_max
                print(vv.card_id, pai.sort)
                pai.card_id = vv.card_id
                if direct == 4 then
                    pai.ssort = (nIndexCard-1)%3+1
                else
                    pai.ssort = (nIndexCard-1)%3+1
                end
                self.hand_card_list[direct][ii] = pai
                self.node:addChild(pai)
                vv:removeFromParent(true)
            else
                print('Unknown errno open mutil card')
                vv:removeFromParent(true)
            end
            nIndexCard = nIndexCard + 1
        end
        self:liSiSpecialCardTypeSort(vv)
    end
    -- for i = 1, 13 do
    --     print(i,self.hand_card_list[direct][i].card_id,self.hand_card_list[direct][i].sort) -- need
    -- end
    if bu_hua then
        self.huapArrow[direct]:setString("X" .. self.huaCount[direct])
    end
    self:sortHandCard(direct)
    self:placeHandCard(direct,nil,true)
end

function MJBaseScene:liSiSpecialCardType()

end

function MJBaseScene:liSiSpecialCardTypeSort()

end

function MJBaseScene:getSoundPrefix(index)
    if not index then
        return "mj/"..lg.."/man"
    end
    local lg =  cc.UserDefault:getInstance():getStringForKey("language", "gy")
    local userData = PlayerData.getPlayerDataByClientID(index)
    if not userData then
        return "mj/"..lg.."/man"
    end

    local sex = userData.sex
    if not sex then
        return "mj/"..lg.."/man"
    end
    if sex ~= 2 then
        return "mj/"..lg.."/man"
    else
        return "mj/"..lg.."/female"
    end
end

function MJBaseScene:isWangCard(card_id)
    if not self.wang_cards then
        return false
    end
    if not self.wang_cards[1] then
        return false
    end

    if card_id == self.wang_cards[1] then
        return true
    end

    return false
end

function MJBaseScene:resetOperPanel(oper, haidi_ting, last_card_id, msgid, kg_cards)
    if self.isTuoGuan then
        return
    end
    logUp('最后一张牌',last_card_id)
    log('最后一张牌',last_card_id)
    local OPER_EMPTY     = 0  -- 无操作
    local OPER_OUT_CARD  = 1  -- 出牌
    local OPER_PENG      = 2  -- 碰
    local OPER_GANG      = 3  -- 杠
    local OPER_CHI_CARD  = 4  -- 吃牌
    local OPER_CHI_HU    = 5  -- 吃胡
    local OPER_HU        = 6  -- 胡牌
    local OPER_BBHU      = 7  -- 板板胡
    local OPER_HAIDI     = 8  -- 海底
    local OPER_KAIGANG   = 9  -- 开杠
    local OPER_PENG_TING = 10 -- 碰听
    local OPER_CHI_TING  = 11 -- 吃听
    local OPER_TING      = 12 -- 听

    self.oper_panel:setVisible(true)

    self.oper_panel.no_reply = true
    self.only_bu = true
    local oper_list = {chi=0,peng=0,gang=0,bu=0,hu=0,hd=0,guo=1}
    local has_oper = nil
    local max_oper = 0
    local is_chupai = nil
    for __, v in ipairs(oper) do
        if v == 1 then
            is_chupai = true
        end
        if v > max_oper then
            max_oper = v
        end
        if v >= 5 and v <= 7 then
            oper_list.hu = 1
            self.hu_type = v
            has_oper = true
            self.hasHu = true
        elseif v == 101 then
            oper_list.hu = 1
            self.hu_type = 101
            oper_list.guo = 0
            has_oper = true
        elseif v == OPER_PENG then
            oper_list.peng = 1
            has_oper = true
            self.hasPeng = true
        elseif v == OPER_CHI_CARD then
            oper_list.chi = 1
            has_oper = true
        elseif v == OPER_GANG then
            oper_list.gang = 1
            has_oper = true
            self.hasGang = true
        elseif v == OPER_OUT_CARD then
            self.can_opt = true
        elseif v == 100 then
            oper_list.hd = 1
            has_oper = true
        elseif v == 9 then
            oper_list.gang = 1
            has_oper = true
        elseif v == OPER_TING then
            oper_list.ting = 1
            has_oper = true
            self.hasTing = true
        end

        if v ~= 1 or v ~= 3 then
            self.only_bu = nil
        end
    end
    local oper_btn_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-guo"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-hu"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-peng"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-chi"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-gang"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-ting"), "ccui.Button"),
    }

    local oper_pai = nil
    -- 上次出牌是不是王
    -- local pre_is_wang = self:isWangCard(self.last_out_card)
    -- if self.pre_out_direct and self.out_card_list[self.pre_out_direct] then
    --     -- 得到最后打出的一次牌
    --     local card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
    --     if card then
    --         pre_is_wang = (card.card_id==self.wang_cards[2]) or (card.card_id==self.wang_cards[3])
    --     end
    -- end
    local no_wang_count = self:checkNoWangCard()
    -- print('不是王的张牌')
    -- print(no_wang_count)
    -- print('不是王的张牌')

    -- 如果有消息或者是断线重连 并且最大的操作码大于1（除了出牌还有其它操作）
    if (self.action_msg or self.is_treatResume) and max_oper > OPER_OUT_CARD then
        if #self.hand_card_list[1] == 14 then
            self.oper_pai_id = self.hand_card_list[1][14].card_id
        else
            if last_card_id then
                self.oper_pai_id = last_card_id
            else
                self.oper_pai_id = self.last_out_card
            end
        end
        oper_pai = self:getCardById(1,self.oper_pai_id, "_stand")
        oper_pai:setPosition(cc.p(oper_pai:getPositionX()+90, oper_pai:getPositionY()+30))
        self.is_treatResume = false
    end

    if oper_list.guo==1 and has_oper then
        if oper_list.hu == 1 then
            oper_btn_list[1].opt_type = "guo_hu"
        else
            oper_btn_list[1].opt_type = "guo"
        end
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_guo_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end

    -- 上张是王 并且不是王的张数大于0 或者  上张不是王 并且不是王的手牌大于2 为了验证手牌数
    -- if oper_list.peng==1 and ((pre_is_wang and no_wang_count > 0) or (not pre_is_wang and no_wang_count > 2)) then
    if oper_list.peng==1 then
        oper_btn_list[1].opt_type = "peng"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_peng_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == OPER_PENG then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            if self.is_3dmj then
                oper_pai:setScale(0.6)
            end
            oper_pai:setPositionY(40)
            self.oper_pai_bg:addChild(oper_pai, 1)
        end
        table.remove(oper_btn_list, 1)
    end

    if oper_list.chi==1 then
        oper_btn_list[1].opt_type = "chi"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_chi_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end

    if oper_list.gang==1 then
        if self.can_opt then
            kg_cards = self:GetGangPai()
        else
            kg_cards = {}
        end
        oper_btn_list[1].opt_type = kg_cards or {}
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_gang_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == OPER_GANG then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            local gang_pai = {}
            if #kg_cards == 0 then
                kg_cards[1] = self.oper_pai_id
            end
            for i,v in ipairs(kg_cards) do
                gang_pai[i] = self:getCardById(1,kg_cards[i], "_stand")
                gang_pai[i]:setPosition(cc.p(gang_pai[i]:getPositionX()+150-(i*60), gang_pai[i]:getPositionY()+30))
                if self.is_3dmj then
                    gang_pai[i]:setScale(0.6)
                end
                gang_pai[i]:setPositionY(40)
                self.oper_pai_bg:addChild(gang_pai[i], 1)
            end
        end
        table.remove(oper_btn_list, 1)
    end
    if oper_list.hu==1 then
        oper_btn_list[1].opt_type = "hu"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_hu_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if #oper_btn_list >= 6 then
            oper_btn_list[1]:setScale(1.3)
        end
        if max_oper == OPER_HU or max_oper == OPER_CHI_HU then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            if self.is_3dmj then
                oper_pai:setScale(0.6)
            end
            oper_pai:setPositionY(40)
            self.oper_pai_bg:addChild(oper_pai, 1)
        end
        table.remove(oper_btn_list, 1)
        if self.can_opt and no_wang_count <= 0 then
            oper_list.guo = 0
            self.can_opt = nil
        end
    end

    if oper_list.ting==1 then
        oper_btn_list[1].opt_type = 'ting'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_ting_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        self.btnTing = oper_btn_list[1]
        table.remove(oper_btn_list, 1)
    end
    local total = 0
    if #oper_btn_list >= 6 then
        self.oper_panel:setVisible(false)
        self.oper_panel.no_reply = nil
        self.only_bu = nil
        if self.can_opt then
            self.oper_panel.msgid = msgid
            if not self.hand_card_list[1] or #self.hand_card_list[1] ~= 14 then
                total = -1
                return
            end
        else
            self.oper_panel.msgid = nil
        end
        if self.can_opt and self.ting_status then
            self.can_opt = nil
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(self.TingAutoOutCard),
                cc.CallFunc:create(function()
                    if last_card_id then
                        print('出牌A',last_card_id)
                        self:sendOutCards(last_card_id)
                        self:setImgGuoHuIndexVisible(1, false)
                    else
                        local card = self.hand_card_list[1][#self.hand_card_list[1]]
                        if card and card.card_id and ((self.for_draw_card == card.card_id) or (not self.for_draw_card)) then
                            print('出牌B', card.card_id)
                            self:sendOutCards(card.card_id)
                            self:setImgGuoHuIndexVisible(1, false)
                        end
                    end
                end)))
        end
    else
        for __, v in ipairs(oper_btn_list) do
            v:setVisible(false)
            v:setTouchEnabled(false)
            v.opt_type = nil
        end
        self.oper_panel.msgid = msgid
    end
    total = self:caculateScore(total)

    log('AAAAAAAAAAAAAAAAAAAAAAAAAA')
    if AUTO_PLAY then
        local oper = false
        if has_oper then
            oper = true
            -- log('has_oper has_oper has_oper has_oper has_oper')
            -- if oper_list.hu == 1 then
            --     log('hu hu hu hu hu hu hu hu')
            --     self.operCallback('hu')
            -- elseif oper_list.peng == 1 then
            --     log('peng peng peng peng peng peng peng peng')
            --     self.operCallback('peng')
            -- elseif oper_list.ting == 1 then
            --     log('ting ting ting ting ting ting ting ting')
            --     self.operCallback('ting')
            -- else
            --     log('guo guo guo guo guo guo guo guo')
            --     self:sendOperate(nil,0)
            --     oper = false
            -- end
            self:sendOperate(nil,0)
            oper = false
        end
        if self.can_opt and not oper then
            if 14 > #self.hand_card_list[1] then
                return
            end
            self.card_index = self.card_index or 13
            self:sendOutCards(self.hand_card_list[1][self.card_index].card_id)
            self.card_index = self.card_index - 1
            if self.card_index <= 0 then
                self.card_index = 13
            end
        end
        return
    end
    if total ~= 0 then
        self:send_join_room_again()
    end
    if self.can_opt and self.ting_tip_layer and oper_list.hu ~= 1 and not self.ting_status then
        if self.isBaoTing and oper_list.ting ~= 1 then
            return
        end
        local hand_list = {}
        local group_list = {}
        local j = 1
        while j <= #self.hand_card_list[1] do
            local v = self.hand_card_list[1][j]
            if v then
                if v.sort == 0 then
                    hand_list[#hand_list+1] = v.card_id
                    j = j+1
                else
                    local list = {}
                    local k =0
                    while k < 3 do
                        list[#list+1] = self.hand_card_list[1][k+j].card_id
                        k = k+1
                    end
                    j = j+k
                    table.sort(list)
                    group_list[#group_list+1] = list
                end
            end
        end
        local out_list = {}
        for k=1, 4 do
            if self.hand_card_list[k] and #self.hand_card_list[k] > 0 then
                for __, v in ipairs(self.hand_card_list[k]) do
                    if v.card_id and v.card_id >=1 and v.card_id <= 81 then
                        out_list[#out_list+1] = v.card_id
                        if v.is_gang then
                            out_list[#out_list+1] = v.card_id
                        end
                    end
                end
            end
            if self.out_card_list[k] and #self.out_card_list[k] > 0 then
                for __, v in ipairs(self.out_card_list[k]) do
                    if v.card_id and v.card_id >=1 and v.card_id <= 81 then
                        out_list[#out_list+1] = v.card_id
                    end
                end
            end
        end
        self.ting_list = {}
        local bCanOutToTing = self.MJLogic.CanOutToTing(hand_list, group_list, self.wang_cards[1], self.isHPBXQM)
        if not bCanOutToTing then
            return
        end
        local left_cards = self.MJLogic.copyArray(MJBaseScene.CardNum)
        for i,v in ipairs(out_list) do
            left_cards[v] = left_cards[v] or 4
            left_cards[v] = left_cards[v]  - 1
        end
        for i, v in ipairs(hand_list) do
            if not self.ting_list[v] then
                local hands = clone(hand_list)
                table.remove(hands, i)

                local hu_list = {}
                local ting_list = self.MJLogic.CetTingCards(hands, group_list, self.wang_cards[1], self.isHPBXQM)
                if ting_list and #ting_list > 0 then
                    for i ,v in pairs(ting_list) do
                        hu_list[#hu_list+1] = {v,left_cards[v]}
                    end
                end
                if hu_list and #hu_list > 0 then
                    local wang = self.wang_cards[1]
                    if wang then
                        local bHasWang = false
                        for i , v in ipairs(hu_list) do
                            if wang == v[1] then
                                bHasWang = true
                                break
                            end
                        end
                        if not bHasWang then
                            table.insert(hu_list,1,{wang,left_cards[wang]})
                        end
                    end
                    self.ting_list[v] = hu_list
                end
            end
        end

        self:removeTingArrow()
        if not self.hand_card_list[1] or not self.hand_card_list[1][14] then
            return
        end
        local card_size = self.hand_card_list[1][14]:getContentSize()
        for k, __ in pairs(self.ting_list) do
            for __, v in ipairs(self.hand_card_list[1]) do
                if  v.sort == 0 and v.card_id == k and not v.ting_ar then
                    local sp = cc.Sprite:create("ui/qj_mj/ting_arrow.png")
                    if self.is_pmmj or self.is_pmmjyellow then
                        sp:setScale(1.1)
                    else
                        sp:setScale(2)
                    end
                    sp:setAnchorPoint(0.5, 0)
                    sp:setPosition(card_size.width/2, card_size.height)
                    v:addChild(sp)
                    v.ting_ar = sp
                end
            end
        end
    end
end

function MJBaseScene:checkNoWangCard()
    local count = 0
    for __, v in ipairs(self.hand_card_list[1]) do
        if v.sort == 0 and v.card_id ~= self.wang_cards[1] then
            count = count + 1
        end
    end
    return count
end

function MJBaseScene:checkIpWarn(is_click_see)
    if self.is_playback then return end

    self:runAction(
        cc.CallFunc:create(
            function()
                -- GPS地址
                local tips = cc.Director:getInstance():getRunningScene():getChildByTag(85001)
                if tips then
                    tips:removeFromParent(true)
                end

                -- 统计人数
                local count = RoomInfo.getCurPeopleNum()

                -- 人数未满
                local people_num = RoomInfo.getTotalPeopleNum()
                if count < people_num then
                    if is_click_see then
                        commonlib.showLocalTip("房间满人可查看")
                    end
                    return
                end

                log('people_num ' .. tostring(people_num) .. ' is_click_see ' .. tostring(is_click_see) .. ' self.piaoniao_mode ' .. tostring(self.piaoniao_mode))

                 if (people_num == 2 or people_num == 3 or people_num == 4) and not is_click_see then
                    return
                end

                self:disapperClubInvite(true)

                -- GPS
                local GpsMap = require('scene.GpsMap')
                GpsMap.mjShowMap(self,people_num,is_click_see)
            end
        )
    )
end

function MJBaseScene:hasCardShadow(card)
    local card_shadow = card:getChildByName('card_shadow')
    return card_shadow
end

function MJBaseScene:createCardShadow(parent, is_pm)
    local card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
    card_shadow:setName('card_shadow')
    if is_pm then
        card_shadow:setAnchorPoint(0, 0)
        local iCardSize = parent:getContentSize()
        local iCardShadowSize = card_shadow:getContentSize()
        card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width)
        card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height)
    else
        card_shadow:setAnchorPoint(0.1, 0.2)
        local iCardSize = parent:getContentSize()
        local iCardShadowSize = card_shadow:getContentSize()
        card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width+0.15)
        card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height+0.2)
    end
    return card_shadow
end

function MJBaseScene:addCardShadow(bIngore14)
    for i , card in pairs(self.hand_card_list[1]) do
        local card_shadow = card:getChildByName('card_shadow')
        if not card_shadow and card.sort == 0 and (i ~= 14 or bIngore14) then
            card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
            card_shadow:setAnchorPoint(0.05, 0.05)
            card_shadow:setName('card_shadow')
            if self.is_pmmj or self.is_pmmjyellow then
                card_shadow:setAnchorPoint(0, 0)
                local iCardSize = card:getContentSize()
                local iCardShadowSize = card_shadow:getContentSize()
                card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width)
                card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height)
            end
            self.hand_card_list[1][i]:addChild(card_shadow)
        end
    end
end

function MJBaseScene:removeCardShadow()
    if self.ting_status then
        return
    end
    for i , v in pairs(self.hand_card_list[1]) do
        local card_shadow = v:getChildByName('card_shadow')
        if not v.type or v.type ~= "lipai" then
            if card_shadow then
                card_shadow:removeFromParent(true)
            end
        end
    end
end

function MJBaseScene:addTingTag(nIndex)
    if not self.player_ui[nIndex] then
        return
    end
    local imgTing = self.player_ui[nIndex]:getChildByName('TING_PAI')
    if not imgTing then
        imgTing = cc.Sprite:create("ui/qj_mj/room/ting-fs8.png")
        imgTing:setScale(1.1)
        imgTing:setPosition(78,60)
        imgTing:setName('TING_PAI')
        self.player_ui[nIndex]:addChild(imgTing)
    end
end

function MJBaseScene:removeAllTingTag()
    for i = 1 , 4 do
        self:removeTingTag(i)
    end
end

function MJBaseScene:removeTingTag(nIndex)
    if not self.player_ui[nIndex] then
        return
    end
    local imgTing = self.player_ui[nIndex]:getChildByName('TING_PAI')
    if not imgTing then
        return
    end
    imgTing:removeFromParent(true)
end

function MJBaseScene:setTingTitleVisible(bVisible)
    if self.ting_tip_layer then
        local title = ccui.Helper:seekWidgetByName(self.ting_tip_layer, "title")
        if title then
            title:setVisible(bVisible)
        end
    end
end

function MJBaseScene:initImgGuoHuIndex()
    for i = 1, 4 do
        self:setImgGuoHuIndexVisible(i, false)
    end
    local imgGuoHuIndex = ccui.Helper:seekWidgetByName(self.node, 'imgGuoHuIndex1')
    if not imgGuoHuIndex then
        return
    end
    imgGuoHuIndex:setVisible(false)
end

function MJBaseScene:initImgGuoPengIndex()
    self:setImgGuoPengIndexVisible(1,false)
end

function MJBaseScene:setImgGuoHuIndexVisible(lnIndex, bVisible)
    local imgGuoHu = self:getChildByName('imgGuoHu')
    if not imgGuoHu then
        imgGuoHu = cc.Sprite:create("ui/qj_mj/guohu1-fs8.png")
        imgGuoHu:setName('imgGuoHu')
        imgGuoHu:setPosition(g_visible_size.width/2, 155)
        self:addChild(imgGuoHu,self.ZOrder.GUO_HU_TAG_ZOREDER)
    end

    imgGuoHu:setVisible(bVisible)

    local imgGuoPeng = self:getChildByName('imgGuoPeng')
    if imgGuoHu and imgGuoHu:isVisible() and imgGuoPeng and imgGuoPeng:isVisible() then
        imgGuoHu:setPosition(g_visible_size.width/2-100, 155)
        imgGuoPeng:setPosition(g_visible_size.width/2+100, 155)
    end
end

function MJBaseScene:setImgGuoPengIndexVisible(lnIndex, bVisible)
    local imgGuoPeng = self:getChildByName('imgGuoPeng')
    if not imgGuoPeng then
        imgGuoPeng = cc.Sprite:create("ui/qj_mj/guopeng.png")
        imgGuoPeng:setName('imgGuoPeng')
        imgGuoPeng:setPosition(g_visible_size.width/2, 155)
        self:addChild(imgGuoPeng,self.ZOrder.GUO_HU_TAG_ZOREDER)
    end

    imgGuoPeng:setVisible(bVisible)

    local imgGuoHu = self:getChildByName('imgGuoHu')
    if imgGuoPeng and imgGuoPeng:isVisible() and imgGuoHu and imgGuoHu:isVisible() then
        imgGuoHu:setPosition(g_visible_size.width/2-100, 155)
        imgGuoPeng:setPosition(g_visible_size.width/2+100, 155)
    end
end

function MJBaseScene:setImgGuoLongIndexVisible(lnIndex, bVisible)
    local imgGuoLong = self:getChildByName('imgGuoLong')
    if not imgGuoLong then
        imgGuoLong = cc.Sprite:create("ui/qj_mj/guolong.png")
        imgGuoLong:setName('imgGuoLong')
        imgGuoLong:setPosition(g_visible_size.width/2, 155)
        self:addChild(imgGuoLong,self.ZOrder.GUO_HU_TAG_ZOREDER)
    end
    if self.is_pass_long then
        self.is_pass_long = false
    end
    imgGuoLong:setVisible(bVisible)
end

function MJBaseScene:removeTingArrow()
    for __, v in ipairs(self.hand_card_list[1]) do
        if  v.ting_ar then
            v.ting_ar:removeFromParent(true)
            v.ting_ar = nil
        end
    end
end

function MJBaseScene:playhuSpine(_prt,_name,animation1)
    -- if g_os == "win" then return end
    local spineFile = nil
    local time = 1
    if _name == "skeleton" then
        spineFile = "ui/qj_mj/huSpine/skeleton"
        time = 5
    elseif _name == 'kaiju' then
        spineFile = 'ui/qj_mj/huSpine/kaiju'
        time = 1
    end
    if not spineFile then return end
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setScale(1)
    skeletonNode:setAnimation(0, animation1, false)

    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width/2, windowSize.height/2))
    _prt:addChild(skeletonNode,100)

    -- skeletonNode:registerSpineEventHandler(function (event)
    --     if event.loopCount == 1 then
    --         skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.RemoveSelf:create()))
    --     end
    -- end, 2)
    skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.RemoveSelf:create()))
end

function MJBaseScene:initTimeArrow()
    self.ImgTime = ccui.Helper:seekWidgetByName(self.node,'ImgTime')
    self.ImgTime:setVisible(self.is_game_start)

    self.tTimeCout = ccui.Helper:seekWidgetByName(self.node,'tTimeCout')

    for i = 1, 4 do
        ccui.Helper:seekWidgetByName(self.node,'ImgArrow' .. i):setVisible(false)
    end
end

function MJBaseScene:setLastJuPackget(rtn_msg)
    -- 设置当前局数
    if self.is_playback then
        self.quan_lbl:setVisible(true)
        self:setLastJu(self.total_ju, rtn_msg.cur_ju or 0)
    else
        if self.total_ju > 100 then
            self:setLastJu(self.total_ju, rtn_msg.cur_quan or 0)
        else
            self:setLastJu(self.total_ju, rtn_msg.cur_ju or 0)
        end
    end
end

function MJBaseScene:setLastJu(lnTotal, lnCur)
    if self.is_playback then
        self.quan_lbl:setVisible(true)
        self.quan_lbl:setString("第"..lnCur.."局")
    else
        if lnTotal >= 100 then
            self.quan_lbl:setString('剩余 ' .. tostring(lnTotal - lnCur - 100) .. ' 圈')
        else
            self.quan_lbl:setString('剩余 ' .. tostring(lnTotal - lnCur) .. '局')
        end
    end
end

function MJBaseScene:addOpenCardArrow(pParent, nSrcIndex, nDesIndex)
    if 0 == nDesIndex then
        return
    end
    local lnDistance = 20

    local pArrow = nil
    local offset = 0
    if nSrcIndex == nDesIndex then
        pArrow = cc.Sprite:create('ui/qj_mj/dt_play_gang.png')
        if nDesIndex == 1 then
            pArrow:setRotation(0)
        elseif nDesIndex == 2 then
            pArrow:setRotation(270)
        elseif nDesIndex == 4 then
            pArrow:setRotation(90)
        elseif nDesIndex == 3 then
            pArrow:setRotation(180)
        end
    else
        pArrow = cc.Sprite:create('ui/qj_mj/dt_play_peng.png')
        if nDesIndex == 1 then
            pArrow:setRotation(180)
        elseif nDesIndex == 2 then
            pArrow:setRotation(90)
        elseif nDesIndex == 4 then
            pArrow:setRotation(270)
        elseif nDesIndex == 3 then

        end
    end

    if self.is_pmmjyellow then
        pArrow:setScale(0.7)
        offset = 7
    end
    if nSrcIndex == 1 then
        pArrow:setPosition(pParent:getContentSize().width/2,pParent:getContentSize().height+lnDistance-offset)
    elseif nSrcIndex == 2 then
        pArrow:setPosition(-lnDistance,pParent:getContentSize().height/2)
    elseif nSrcIndex == 3 then
        pArrow:setPosition(pParent:getContentSize().width/2,-lnDistance)
    elseif nSrcIndex == 4 then
        pArrow:setPosition(pParent:getContentSize().width+lnDistance,pParent:getContentSize().height/2)
    end
    pArrow:setName('CardArrow')
    pParent:setLocalZOrder(110)
    pParent:addChild(pArrow)
end

function MJBaseScene:addHuaCount(pParent, nSrcIndex, nDesIndex)
    if 0 == nDesIndex then
        return
    end
    if self.huapArrow[nSrcIndex] then
        return
    end
    local lnDistance = 20

    local pArrow = nil
    local offset = 0

    pArrow = ccui.Text:create()
    pArrow:setFontSize(36)
    pArrow:setColor(cc.c3b(255, 255, 255))
    pArrow:setString("")
    if nDesIndex == 1 then
        pArrow:setRotation(0)
    elseif nDesIndex == 2 then
        pArrow:setRotation(270)
    elseif nDesIndex == 4 then
        pArrow:setRotation(90)
    elseif nDesIndex == 3 then
        pArrow:setRotation(180)
    end

    if self.is_pmmjyellow then
        pArrow:setScale(0.7)
        offset = 7
    end
    if nSrcIndex == 1 then
        pArrow:setPosition(pParent:getContentSize().width + 25, pParent:getContentSize().height + lnDistance - offset)
    elseif nSrcIndex == 2 then
        pArrow:setPosition(-lnDistance, pParent:getContentSize().height / 2 - 25)
    elseif nSrcIndex == 3 then
        pArrow:setPosition(pParent:getContentSize().width + 25, -lnDistance)
    elseif nSrcIndex == 4 then
        pArrow:setPosition(pParent:getContentSize().width + lnDistance, pParent:getContentSize().height / 2 - 25)
    end
    pParent:setLocalZOrder(120)
    pParent:addChild(pArrow)
    self.huapArrow[nSrcIndex] = pArrow
end

function MJBaseScene:removeOpenCardArrow(pParent)
    local pArrow = pParent:getChildByName('CardArrow')
    if not pArrow then
        return
    end
    pArrow:removeFromParent(true)
end

function MJBaseScene:setClubInvite()
    local btnClubInvite = ccui.Helper:seekWidgetByName(self.node,"btn-clubinvite")
    self.btnClubInvite = btnClubInvite
    if btnClubInvite then
        btnClubInvite:setVisible(not self.is_game_start and self.qunzhu == 1)
        if self.qunzhu == 1 then
            -- 邀请亲友圈成员
            btnClubInvite:addTouchEventListener(
                function(sender,eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        local ClubInviteLayer = require('club.ClubInviteLayer')
                        local layer = ClubInviteLayer:create({
                            club_name = self.club_name,
                            club_id = self.club_id,
                            room_id = self.room_id,
                            room_info = self.room_info,
                            parent = self.node,
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

function MJBaseScene:disapperClubInvite(bForceDiscover)
    --------------------------------------------------------
    local btnClubInvite = ccui.Helper:seekWidgetByName(self.node,"btn-clubinvite")
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

MJBaseScene.CardNum = {
    [0x01] = 4,
    [0x02] = 4,
    [0x03] = 4,
    [0x04] = 4,
    [0x05] = 4,
    [0x06] = 4,
    [0x07] = 4,
    [0x08] = 4,
    [0x09] = 4,
    [0x11] = 4,
    [0x12] = 4,
    [0x13] = 4,
    [0x14] = 4,
    [0x15] = 4,
    [0x16] = 4,
    [0x17] = 4,
    [0x18] = 4,
    [0x19] = 4,
    [0x21] = 4,
    [0x22] = 4,
    [0x23] = 4,
    [0x24] = 4,
    [0x25] = 4,
    [0x26] = 4,
    [0x27] = 4,
    [0x28] = 4,
    [0x29] = 4,
    [0x31] = 4,
    [0x32] = 4,
    [0x33] = 4,
    [0x34] = 4,
    [0x41] = 4,
    [0x42] = 4,
    [0x43] = 4
}

function MJBaseScene.showSysTime(label, time)
    local time = time or os.time()
    label:setString(os.date("%H:%M:%S",time))
    label:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        time = time+1
        label:setString(os.date("%H:%M:%S",time))
    end))))
end

function MJBaseScene:setRoomData()
    -- 房号
    -- log('亲友圈名字 ' .. self.club_name)
    -- log('亲友圈桌号 ' .. self.club_index)
    if self.club_name and self.club_index then
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "fanghao"), "ccui.Text"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setVisible(true)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qyqfanghao"), "ccui.Text"):setVisible(true)
        if pcall(commonlib.GetMaxLenString, self.club_name, 6) then
            tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setString(commonlib.GetMaxLenString(self.club_name,6) .. self.club_index .. "号")
        else
            tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setString(self.club_name .. self.club_index .. "号[" .. self.desk.. "]")
        end
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qyqfanghao"),"ccui.Text"):setString("[" .. self.desk.. "]")
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setFontSize(17)
    else
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "fanghao"), "ccui.Text"):setString(self.desk)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "fanghao"), "ccui.Text"):setVisible(true)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qingyouquanfanghao"), "ccui.Text"):setVisible(false)
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "qyqfanghao"), "ccui.Text"):setVisible(false)
    end
end

function MJBaseScene:setSysTime()
    -- 系统时间
    if self.is_playback then
        MJBaseScene.showSysTime(tolua.cast(ccui.Helper:seekWidgetByName(self.node, "time"), "ccui.Text"),self.create_time)
    else
        MJBaseScene.showSysTime(tolua.cast(ccui.Helper:seekWidgetByName(self.node, "time"), "ccui.Text"))
    end
end

local severToClient={
    [0x1]   = 11,
    [0x2]   = 12,
    [0x3]   = 13,
    [0x4]   = 14,
    [0x5]   = 15,
    [0x6]   = 16,
    [0x7]   = 17,
    [0x8]   = 18,
    [0x9]   = 19,
    [0x11]  = 21,
    [0x12]  = 22,
    [0x13]  = 23,
    [0x14]  = 24,
    [0x15]  = 25,
    [0x16]  = 26,
    [0x17]  = 27,
    [0x18]  = 28,
    [0x19]  = 29,
    [0x21]  = 1,
    [0x22]  = 2,
    [0x23]  = 3,
    [0x24]  = 4,
    [0x25]  = 5,
    [0x26]  = 6,
    [0x27]  = 7,
    [0x28]  = 8,
    [0x29]  = 9,
    -- 东
    [0x31]  = 31,
    -- 南
    [0x32]  = 51,
    -- 西
    [0x33]  = 41,
    -- 北
    [0x34]  = 61,
    -- 中
    [0x41]  = 71,
    -- 发
    [0x42]  = 81,
    -- 白
    [0x43]  = 91,
}

function MJBaseScene:playzimo(value)
    local function addHuCard(value)
        local strCard = string.format('ui/qj_mj/aniCards/ani_my_%d.png',severToClient[value])
        local card = cc.Sprite:create(strCard)

        card:setPositionY(-220)
        card:setLocalZOrder(100)

        return card
    end
    local function playZimoHand()
        local fileJson = "ui/qj_mj/SXzimotexiaoDH_fen/SXzimotexiaoDH_fen.ExportJson"
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
        local armature = ccs.Armature:create('SXzimotexiaoDH_fen')
        local function animationEvent(armatureBack,movementType,movementID)
            print('movementID' .. movementID)
            if movementType == 1 then
                armature:removeFromParent(true)
            end
        end
        armature:getAnimation():setMovementEventCallFunc(animationEvent)

        armature:getAnimation():play('zimohupai_01',0,0)
        armature:setPosition(g_visible_size.width/2,g_visible_size.height/2.2)
        armature:setLocalZOrder(self.ZOrder.DIAN_PAO_ZOREDER or 99)

        -- armature:addChild(addHuCard(value))

        self:addChild(armature)

        return armature
    end

    local function playZimoBg()
        local fileJson = "ui/qj_mj/SXzimotexiaoDH_fen/SXzimotexiaoDH_fen.ExportJson"
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
        local armature = ccs.Armature:create('SXzimotexiaoDH_fen')
        local function animationEvent(armatureBack,movementType,movementID)
            print('movementID' .. movementID)
            if movementType == 1 then
                -- armature:getAnimation():play('zimohupai_02',0,0)
                armature:removeFromParent(true)
            end
        end
        armature:getAnimation():setMovementEventCallFunc(animationEvent)

        armature:getAnimation():play('zimohupai_02',0,0)
        armature:setPosition(g_visible_size.width/2,g_visible_size.height/2.2)
        armature:setLocalZOrder(self.ZOrder.DIAN_PAO_ZOREDER or 99)

        self:addChild(armature)

        return armature
    end

    local armatureBg = playZimoBg()
    local armatureHand = playZimoHand()

    armatureBg:addChild(addHuCard(value))
end

function MJBaseScene:playdianpao(pos)
    local fileJson = "ui/qj_mj/majiangshandiandonghua/majiangshandiandonghua.ExportJson"
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
    local armature = ccs.Armature:create('majiangshandiandonghua')
    local function animationEvent(armatureBack,movementType,movementID)
        if movementType == 1 then
            armature:removeFromParent(true)
        end
    end
    armature:getAnimation():setMovementEventCallFunc(animationEvent)
    armature:getAnimation():play('Animation1',0,0)
    armature:setPosition(pos)
    armature:setLocalZOrder(self.ZOrder.DIAN_PAO_ZOREDER or 99)
    self:addChild(armature)
end

function MJBaseScene:initOutCardPos()
    if self.people_num == 2 then
        self.out_row_nums = 16
        if self.is_pmmjyellow then
            self.out_row_nums = 20
        end
        self.out_card_pos_list[1].init_pos.x = self.ori_out_card_pos_list[1].x
        self.out_card_pos_list[3].init_pos.x = self.ori_out_card_pos_list[3].x
    else
        if self.is_pmmjyellow then
            self.out_row_nums = 11
        elseif self.is_pmmj then
            self.out_row_nums = 7
        elseif self.is_3dmj then
            self.out_row_nums = 6
        end
        self.out_card_pos_list[1].init_pos.x = self.ori_out_card_pos_list_34r[1].x
        self.out_card_pos_list[3].init_pos.x = self.ori_out_card_pos_list_34r[3].x
    end
    self.out_card_pos_list[1].init_pos.y = self.ori_out_card_pos_list[1].y
    self.out_card_pos_list[3].init_pos.y = self.ori_out_card_pos_list[3].y
    -- if self.people_num ~= 4 then
    -- else
    --     if not self.is_pmmj and not self.is_pmmjyellow then
    --         self.player_ui[3]:setPosition(cc.p(self.wenhao_list[3]:getPosition()))
    --     else
    --         self.player_ui[3]:setPosition(cc.p(self.wenhao_list[3]:getPosition()))
    --     end
    -- end
end

-- @得到上家位置
-- @index服务端位置
-- @return index上家的客户端位置
function MJBaseScene:findPreUser(index)
    if not self.people_num then
        print('findPreUserByClient数据不全')
        return
    end

    print('index',index)
    local last_user = index - 1 > 0 and index - 1 or self.people_num
    print('last_user',last_user)
    -- 上家玩家位置
    local user = self:indexTrans(last_user)
    print('user',user)
    return user
end

function MJBaseScene:treatResumeGroupCard(direct,tCard,preUser,sort)
    -- dump(tCard)
    local isKeCards = false
    local cur_sort  = sort or 0
    if self.isKouPai then
        cur_sort = sort or 1
    end
    for __, cards_hash in ipairs(tCard) do
        local nCardIndex = 1
        cur_sort = cur_sort+1
        -- 包杠大于10
        if cards_hash.last_user and cards_hash.last_user > 10 then
            cards_hash.last_user = cards_hash.last_user -10
        end

        print('cards_hash.last_user',tostring(cards_hash.last_user))
        local lnLastUser = cards_hash.last_user and self:indexTrans(cards_hash.last_user) or 0
        -- 叫牌找上家
        if 0 == lnLastUser and preUser then
            lnLastUser = preUser
        end
        local cards = {}
        for i ,v in pairs(cards_hash) do
            if i ~= 'last_user' then
                cards[tonumber(i)] = v
            end
        end
        -- 下坎的牌有东南西北起手花牌型 时 加入cards[5],设置为101
        if self.mjGameName == '丰宁' and cards[4] and #self.MJLogic.GetHuaList(cards) ~= 0 then
            cards[5] = 101
        end
        -- 下坎的牌为3张且last_user为自己，除掉花牌后剩下的牌（刻牌）
        if self.mjGameName == '丰宁' and #cards == 3 and #self.MJLogic.GetHuaList(cards) == 0 then
            if lnLastUser == direct then
                isKeCards = true
            end
        end
        if not cards[5] then
            for ii, cid in ipairs(cards) do
                local pai = nil
                if isKeCards then
                    pai      = self:getCardById(direct, 0, nil, nil, true)
                    pai.isKe = true
                    pai.cardType = 22
                else
                    pai = self:getCardById(direct, cid, "_stand", true)
                    if self.mjGameName == '丰宁' and #cards == 3 and #self.MJLogic.GetHuaList(cards) ~= 0 then
                        pai.cardType = 21
                    else
                        pai.cardType = 2
                    end
                end
                pai.sort = cur_sort
                pai.card_id = cid
                if direct == 4 then
                    pai.ssort = ii
                    self.node:addChild(pai, 4-pai.ssort)
                else
                    pai.ssort = ii
                    self.node:addChild(pai, 1)
                end
                if nCardIndex == 2 and not isKeCards then
                    self:addOpenCardArrow(pai, direct, lnLastUser)
                end
                nCardIndex = nCardIndex + 1
                self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai


            end
        else
            for k=1, 3 do
                local pai = nil
                local add_card = nil
                local pai_scale = self.single_scale
                if cards[5] == 101 then
                    pai = self:getCardById(direct, cards[k], "_stand",true)
                else
                    pai = self:getCardById(direct, cards[1], "_stand",true)
                end
                if cards[5] == 2 then
                    pai.cardType = 10

                    local szGangBack = nil
                    if self.is_pmmj or self.is_pmmjyellow then
                        local szGangBack = {}
                        local szDirectPre = {}
                        if self.is_pmmj then
                            szGangBack = {'ee_mj_b_up.png',
                                            'ee_mj_b_right.png',
                                            'ee_mj_b_up.png',
                                            'ee_mj_b_left.png',}
                            szDirectPre = {'BB','RR','UU','LL'}
                        else
                            szGangBack = {'e_mj_b_up.png',
                                            'e_mj_b_right.png',
                                            'e_mj_b_up.png',
                                            'e_mj_b_left.png',}
                            szDirectPre = {'B','R','B','L'}
                        end
                        local str = szGangBack[direct]
                        add_card = self:createCardWithSpriteFrameName(str)
                        local szNormal = self:createCardWithSpriteFrameName(szDirectPre[direct] .. '_wind_east.png')
                        add_card:setScaleX(szNormal:getContentSize().width/add_card:getContentSize().width)
                        add_card:setScaleY(szNormal:getContentSize().height/add_card:getContentSize().height)
                    else
                        add_card = cc.Sprite:create(self.res3DPath.."/back"..direct..".png")
                        if direct%2 ~= 0 then
                            add_card:setScale(1.4)
                        else
                            add_card:setScale(1.8)
                        end
                    end
                    add_card.an = true
                else

                    if cards[5] == 101 then
                        add_card = self:getCardById(direct, cards[k], "_stand",true)
                        pai.cardType = 21
                    else
                        add_card = self:getCardById(direct, cards[1], "_stand",true)
                        pai.cardType = 11
                    end
                    add_card:setScale(1)
                end
                if k == 2 then
                    if self.is_pmmj or self.is_pmmjyellow then
                        if direct%2 == 0 then
                            add_card:setAnchorPoint(0, -0.32)
                        else
                            add_card:setAnchorPoint(0, -0.24)
                        end
                    else
                        add_card:setAnchorPoint(0, -0.25)
                    end
                    pai:addChild(add_card)
                    self:addOpenCardArrow(add_card ,direct, lnLastUser, true)
                    if pai.cardType == 21 then
                        self:addHuaCount(add_card, direct, lnLastUser)
                        if self.huaCount[direct] and self.huaCount[direct] ~= 0 then
                            self.huapArrow[direct]:setString("X" .. self.huaCount[direct])
                        end
                    end
                    pai.is_gang = true
                end
                if pai then
                    pai.sort = cur_sort
                    if cards[5] == 101 then
                        pai.card_id = cards[k]
                    else
                        pai.card_id = cards[1]
                    end
                    if direct == 4 then
                        pai.ssort = k
                        self.node:addChild(pai, 4-pai.ssort)
                    else
                        pai.ssort = k
                        self.node:addChild(pai, 1)
                    end
                    self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                end
            end
        end
    end
end

function MJBaseScene:treatResumeOutCard(direct,tCard)
    for i, cid in ipairs(tCard) do
        local pai = self:getOpenCardById(direct, cid, true)
        pai.card_id = cid
        local zorder = nil

        local nRow = math.floor((i-1) / (self.out_row_nums))
        local nCow = (i-1) % (self.out_row_nums)

        pai:setPosition(self:getOutCardPosition(direct,nRow,nCow))
        pai:setLocalZOrder(self:getOutCardZOrder(direct,nRow,nCow))

        self.node:addChild(pai)

        self.out_card_list[direct][#self.out_card_list[direct]+1] = pai
    end
end

function MJBaseScene:getOutCardZOrder(direct,nRow,nCow)
    local ZOrder = nil

    local nBeyondNum = nil
    if self.is_3dmj then
        if nRow >= 4 and (direct == 1 or direct == 3) then
            nCow = self.out_row_nums

            nBeyondNum = 4 * nCow
        elseif nRow >= 5 and (direct == 2 or direct == 4) then

            nCow = self.out_row_nums

            nBeyondNum = 5 * nCow
        end
    elseif self.is_pmmj then
        if nRow >= 3 and (direct == 1 or direct == 3) then

            nCow = self.out_row_nums

            nBeyondNum = 3 * nCow
        elseif nRow >= 4 and (direct == 2 or direct == 4) then

            nCow = self.out_row_nums

            nBeyondNum = 4 * nCow
        end
    end

    if self.is_pmmjyellow then
        if direct == 2 then
            ZOrder = ((self.ZOrder.OUT_CARD_ZORDER)- #self.out_card_list[direct])
        elseif direct == 1 then
            ZOrder = ((self.ZOrder.OUT_CARD_ZORDER - math.floor(#self.out_card_list[direct]/self.out_row_nums)))
        else
            ZOrder = (self.ZOrder.OUT_CARD_ZORDER)
        end
    else
        if direct == 2 then
            ZOrder = ((self.ZOrder.OUT_CARD_ZORDER)- #self.out_card_list[direct])
        elseif direct == 1 then
            ZOrder = (self.ZOrder.OUT_CARD_ZORDER)
        else
            ZOrder = ((self.ZOrder.OUT_CARD_ZORDER - math.floor(#self.out_card_list[direct]/self.out_row_nums)))
        end
    end
    if nBeyondNum then
        ZOrder = ZOrder + nBeyondNum
    end
    return ZOrder
end

function MJBaseScene:getOutCardPosition(direct,nRow,nCow)
    local a_scale = 1
    local nFullCow = nil
    local nFullRow = nil
    if self.is_3dmj then
        if nRow >= 4 and (direct == 1 or direct == 3) then
            nFullCow = nCow
            nFullRow = nRow - 3

            nRow = 3
            nCow = self.out_row_nums
        elseif nRow >= 5 and (direct == 2 or direct == 4) then
            nFullCow = nCow
            nFullRow = nRow - 4

            nRow = 4
            nCow = self.out_row_nums
        end
        if direct == 2 then
            a_scale = 0.99-(#self.out_card_list[direct]-self.out_row_nums*nRow)*0.01
        elseif direct == 4 then
            a_scale = 1.02+(#self.out_card_list[direct]-self.out_row_nums*nRow)*0.01
        end
        if nFullRow then
            a_scale = 1
        end
    elseif self.is_pmmjyellow then
        if nRow >= 3 and (direct == 1 or direct == 3) then
            nFullCow = nCow

            nRow = 2
            nCow = self.out_row_nums
        elseif nRow >= 3 and (direct == 2 or direct == 4) then
            nFullCow = nCow

            nRow = 2
            nCow = self.out_row_nums
        end
    else
        if nRow >= 3 and (direct == 1 or direct == 3) then
            nFullCow = nCow
            nFullRow = nRow - 2

            nRow = 2
            nCow = self.out_row_nums
        elseif nRow >= 4 and (direct == 2 or direct == 4) then
            nFullCow = nCow
            nFullRow = nRow - 3

            nRow = 3
            nCow = self.out_row_nums
        end
    end
    if nFullCow and nFullRow and (self.is_pmmj or self.is_3dmj) then
        if self.is_pmmj then
            return cc.p(
                self.out_card_pos_list[direct].init_pos.x+self.out_card_pos_list[direct].space.x*nFullCow+self.out_card_pos_list[direct].two_hei.x * nFullRow * a_scale + MJCardPosition.mj2dBigLastLineDistance[direct].x * a_scale,
                self.out_card_pos_list[direct].init_pos.y+self.out_card_pos_list[direct].space.y*nFullCow+self.out_card_pos_list[direct].two_hei.y * nFullRow * a_scale + MJCardPosition.mj2dBigLastLineDistance[direct].y * a_scale
                )
        elseif self.is_3dmj then
            return cc.p(
                self.out_card_pos_list[direct].init_pos.x+self.out_card_pos_list[direct].space.x*nFullCow+self.out_card_pos_list[direct].two_hei.x * nFullRow * a_scale + MJCardPosition.mj2dBigLastLineDistance[direct].x * a_scale,
                self.out_card_pos_list[direct].init_pos.y+self.out_card_pos_list[direct].space.y*nFullCow+self.out_card_pos_list[direct].two_hei.y * nFullRow * a_scale + MJCardPosition.mj2dBigLastLineDistance[direct].y * a_scale
                )
        end
    else
        return cc.p(
            self.out_card_pos_list[direct].init_pos.x+self.out_card_pos_list[direct].space.x*nCow+self.out_card_pos_list[direct].two_hei.x * nRow * a_scale,
            self.out_card_pos_list[direct].init_pos.y+self.out_card_pos_list[direct].space.y*nCow+self.out_card_pos_list[direct].two_hei.y * nRow * a_scale
            )
    end
end

function MJBaseScene:clubRename(rtn_msg)
    if rtn_msg and self.club_id == rtn_msg.club_id then
        self.club_name = rtn_msg.club_name or self.club_name

        local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
        if ClubInviteLayer then
            ClubInviteLayer:refreshInviteClubName(self.club_name)
        end
    end
end

function MJBaseScene:getHuImg()
    local hu_img={}
    hu_img[self.MJLogic.HU_NORMAL] = 5       --平胡
    hu_img[self.MJLogic.HU_QIXIAODUI] = 6    --七小对
    hu_img[self.MJLogic.HU_YITIAOLONG] = 23  --一条龙''
    hu_img[self.MJLogic.HU_QINGYISE] = 7     --清一色
    hu_img[self.MJLogic.HU_HAOQIXIAODUI] = 11--豪七对
    hu_img[self.MJLogic.HU_SHISANYAO] = 22   --十三妖''
    hu_img[30] = 30                     --自摸
    return hu_img
end

GameGlobal.MJWaitOverTimeSchedule = nil

function stopMJWaitOverTimeSchedule()
    if GameGlobal.MJWaitOverTimeSchedule then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(GameGlobal.MJWaitOverTimeSchedule)
        GameGlobal.MJWaitOverTimeSchedule = nil
    end
end

function MJBaseScene:stopCountdownWaitOverTime()
    stopMJWaitOverTimeSchedule()
end

function MJBaseScene:countdownWaitOverTime()
    stopMJWaitOverTimeSchedule()
    local function waitOverCallBack()
        if self and self.wait_over then
            self.wait_over = self.wait_over - 1
            if self.wait_over <= 0 then
                self.wait_over = 0
                stopMJWaitOverTimeSchedule()
            end
        else
            stopMJWaitOverTimeSchedule()
        end
    end
    GameGlobal.MJWaitOverTimeSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(waitOverCallBack, 1, false)
end

-- 重置胡牌类型，砍胡算成平胡
function MJBaseScene:setHuData(hu_types)
    return hu_types
end

-- 得到胡牌分最高的两种类型
-- 自己自摸 显示自摸 别人显示自摸
-- 自己接炮 抢杠胡 没有番只显示胡，别人只显示胡，有番，所以人显示番型图片，
-- 如果多个番同时存在，只显示最大的两个番
-- by 严茂
function MJBaseScene:getHuTye()

end

function MJBaseScene:playHuAni(rtn_msg)
    -- print('MJScene:playHuAni')
    -- dump(rtn_msg)
    -- print('MJScene:playHuAni END')
    local old_ui = self:getChildByTag(1369)
    if old_ui then
        old_ui:removeFromParent(true)
    end

    -- local play_sound = true
    local hu_Ani = {}
    for __, player in ipairs(rtn_msg.players) do
        local hu_type = nil
        if player.hu_types and #player.hu_types >0 then
            player.hu_types = self:setHuData(player.hu_types)
            table.sort(player.hu_types)
            for i , v in pairs(player.hu_types) do
                if not hu_type or v > hu_type then
                    hu_type = v
                end
            end
            for i=#player.hu_types,1,-1 do
                if player.hu_types[i] == 4 then
                    hu_Ani[1] = 7
                    for __,v in pairs(player.hu_types) do
                        if v == 2 or v == 3 or v == 5 then
                            hu_Ani[2] = v
                        end
                    end
                end
            end
        else
            hu_type = self.MJLogic.HU_NORMAL
        end

        -- print('胡牌 ')
        -- dump(player.hu_types)
        -- print('单胡')
        -- dump(hu_type)
        -- print('胡牌 END')

        if player.is_zimo == 1 then
            hu_type = 30
        end

        local hu_img = self:getHuImg()

        hu_type = hu_img[hu_type]
        hu_Ani[2] = hu_img[hu_Ani[2]]


        local function playsound(index)
            local prefix = self:getSoundPrefix(index)
            if hu_type == 30 then
                AudioManager:playDWCSound("sound/"..prefix.."/zimo.mp3")
            elseif hu_type == 5 then
                AudioManager:playDWCSound("sound/"..prefix.."/hu.mp3")
            else
                AudioManager:playDWCSound("sound/mj/act_hu.mp3")
            end
            play_sound = nil
        end
        local index = self:indexTrans(player.index)

        if hu_type == 30 and index == 1 and player.hu_cards[1] then
            -- 自摸
            self:playzimo(player.hu_cards[1])
            self.wait_over = 2

            playsound(index)
            break
        elseif hu_type ~= 30 and rtn_msg.last_user then
            print(' 点炮玩家S ' .. rtn_msg.last_user)
            local last_user = self:indexTrans(rtn_msg.last_user)
            print(' 点炮玩家C ' .. last_user)
            local card = self.out_card_list[last_user][#self.out_card_list[last_user]]
            print(' 点炮 ')
            local posX,posY = card:getPosition()
            local pos = cc.p(posX,posY)
            -- 点炮
            self:playdianpao(pos)
            self.wait_over = 2
        end

        if hu_type and player.hu_cards and #player.hu_cards > 0 then
            local index = self:indexTrans(player.index)
            local old_card_list = {}
            local is_zimo = nil
            local sp = cc.Sprite:create("ui/qj_mj/hn"..hu_type..".png")
            sp = sp or cc.Sprite:create("ui/qj_mj/hn5.png")
            local sp_size = sp:getContentSize()
            local sp_scale = 1
            if index ~= 1 then
                sp_scale = 0.8
                sp_size.width = sp_size.width*sp_scale
                sp_size.height = sp_size.height*sp_scale
            end
            AudioManager:playDWCSound("sound/mj/mj_op.mp3")
            if hu_Ani and #hu_Ani == 2 then
                local ani1 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[1]..".png")
                local sp_size = ani1:getContentSize()
                local sp_scale = 1
                if index ~= 1 then
                    sp_scale = 0.8
                    sp_size.width = sp_size.width*sp_scale
                    sp_size.height = sp_size.height*sp_scale
                end
                local hu_pos = cc.p(self.open_card_ani_pos_list[index].x, self.open_card_ani_pos_list[index].y)
                ani1:setPosition(hu_pos)
                ani1:setScale(3.5)
                self:addChild(ani1, 10000)
                ani1:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)),
                    cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(0.5),
                    cc.CallFunc:create(function()
                        ani1:removeFromParent(true)
                    end),
                    cc.CallFunc:create(function()
                        local ani2 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[2]..".png")
                        ani2:setPosition(hu_pos)
                        ani2:setScale(3.5)
                        self:addChild(ani2,10000)
                        ani2:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)),
                            cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(1),
                        cc.RemoveSelf:create()))
                    end)
                    ))
            else
                if hu_type then
                    local hu_pos = cc.p(self.open_card_ani_pos_list[index].x, self.open_card_ani_pos_list[index].y) -- need
                    sp:setPosition(hu_pos)
                    sp:setScale(3.5)
                    self:addChild(sp, 10000)
                    sp:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)), cc.CallFunc:create(function()
                        local circle = cc.Sprite:create("ui/qj_mj/room/ani_special_circle.png")
                        circle:setPosition(hu_pos)
                        circle:setAnchorPoint(0.5, 0.55)
                        circle:setScale(0)
                        circle:setOpacity(0)
                        self:addChild(circle, 9999)
                        circle:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeIn:create(0.15), cc.ScaleTo:create(0.15, 1.3)),
                            cc.Spawn:create(cc.FadeTo:create(0.1, 127), cc.ScaleTo:create(0.1, 1.25)), cc.DelayTime:create(0.3), cc.RemoveSelf:create()))
                    end),cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(1.6), cc.CallFunc:create(function()
                        sp:removeFromParent(true)
                    end)))
                end
            end
            playsound(index)
            self.wait_over = 2
            break
        end
    end
end

function MJBaseScene:getCardTexture(vv)
    local szFengStr = {
                        '_wind_east.png',
                        '_wind_south.png',
                        '_wind_west.png',
                        '_wind_north.png',
                        '_red.png',
                        '_green.png',
                        '_white.png',
                    }
    local str =''
    local color = math.floor(vv/16)
    if color == 0 then
        color = ""
    end
    local value = vv %16
    local direct = 1
    if color == '' then
        str = '_character_' .. value .. '.png'
    elseif color == 2 then
        str = '_bamboo_' .. value .. '.png'
    elseif color == 1 then
        str = '_dot_' .. value .. '.png'
    elseif color == 3 then
        str = szFengStr[value]
    end
    if self.is_pmmjyellow then
        str = 'B' .. str
    elseif self.is_pmmj then
        str = 'BB' .. str
    end
    return str
end

function MJBaseScene:onRcvKouPai(rtn_msg)
    self.btn_kou:setVisible(false)
    self.btn_bukou:setVisible(false)
    self.t_wait:setVisible(true)
end

function MJBaseScene:onRcvBroad(rtn_msg)
    if not rtn_msg.typ then
        commonlib.showTipDlg(rtn_msg.content or "系统提示")
    end
end

function MJBaseScene:setSinglePlayerHead(index)
    local userData = PlayerData.getPlayerDataByClientID(index)
    if userData and self.player_ui[index] then
        local head = commonlib.wxHead(userData.head)
        self.player_ui[index]:setVisible(true)

        if pcall(commonlib.GetMaxLenString, userData.name, 12) then
            tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(userData.name, 12))
        else
            tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(userData.name)
        end

        print('设置单独头像',userData.score)
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index],"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(userData.score+1000))
        self.player_ui[index]:getChildByName("PJN"):setVisible(false)
        --if index ~= 1 then
            commonlib.lixian(self.player_ui[index])
            self.player_ui[index]:getChildByName("zhunbei"):setVisible(false)
        --end
        -- if head ~= "" then
        self.player_ui[index].head_sp:setVisible(true)
        self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
        -- else
        --     self.player_ui[index].head_sp:setVisible(false)
        -- end
        self:checkIpWarn()
    end
end

function MJBaseScene:onRcvMjTableUserInfo(rtn_msg)
    self:setRoomCurPeopleNumByTableUserInfo(rtn_msg)
    local people_num = RoomInfo.getCurPeopleNum()
    self:setQuickStartPeople(people_num)

    PlayerData.updatePlayerInfoByTableUserInfo(rtn_msg)
    local v = rtn_msg
    local index = PlayerData.getPlayerClientIDByServerID(v.index)

    self:setSinglePlayerHead(index)

    if RoomInfo.getTotalPeopleNum() == RoomInfo.getCurPeopleNum() then
        commonlib.closeQuickStart(self)
    else
        commonlib.interQuickStart(self)
    end
    RoomController:getModel():addPlayer(rtn_msg)
end

function MJBaseScene:removeResultNode()
    -- 移除结算界面
    local result_node = self:getChildByTag(10109)
    if result_node then
        result_node:removeFromParent(true)
    end
end

function MJBaseScene:invisibleZhuBei()
    for i_ui, v_ui in ipairs(self.player_ui) do
        --if i_ui ~= 1 then
            -- 隐藏准备手势
            v_ui:getChildByName("zhunbei"):setVisible(false)
        --end
        -- 隐藏庄家图标
        v_ui:getChildByName("Zhang"):setVisible(false)
    end
end

function MJBaseScene:setHeadPos()
    -- print('3d位置')
    -- for i , v in ipairs(self.headPos3d) do
    --     print(i, '位置',v.x,v.y)
    -- end
    -- print('2d位置')
    -- for i, v in  ipairs(self.headPos) do
    --     print(i, '位置',v.x,v.y)
    -- end
    for play_index =1 ,4 do
        if self.is_3dmj then
            self.player_ui[play_index]:setPosition(self.headPos3d[play_index])
        else
            self.player_ui[play_index]:setPosition(self.headPos[play_index])
        end
    end
end

function MJBaseScene:initHeadPos()
    self.headPos3d = MJHeadPos.headPos3d
    self.headPos = MJHeadPos.headPos
end

function MJBaseScene:runHeadAction(rtn_msg)

    self:initHeadPos()

    local windowSize = cc.Director:getInstance():getWinSize()
    for i,v in ipairs(self.wenhao_list) do
        v:setVisible(false)
    end
    for play_index =1 ,4 do
        if self.is_3dmj then
            self.player_ui[play_index]:runAction(cc.MoveTo:create(0.3,self.headPos3d[play_index]))
        else
            self.player_ui[play_index]:runAction(cc.MoveTo:create(0.3,self.headPos[play_index]))
        end
    end
end

function MJBaseScene:resetClickSelected()
    MJClickAction.resetClickSelected(self)
end

function MJBaseScene:initHandCardPos()
end

function MJBaseScene:onRcvMjGameStart(rtn_msg)
    -- print('麻将游戏开始')
    -- print('MJBaseScene:onRcvMjGameStart')
    dump(rtn_msg)
    self.huaCount  = {0, 0, 0, 0}
    self.huapArrow = {}
    if self:getChildByTag(10099) then
        self:getChildByTag(10099):removeFromParent(true)
    end
    self.for_draw_card = nil

    self.is_game_start = true

    self:setBtnGameStartVisible()

    -- 记录变更前的桌位号
    self.OldClientIndex = {}
    for i , v in pairs(PlayerData.IDToUserData) do
        local client_index = PlayerData.getPlayerClientIDByServerID(v.index)
        self.OldClientIndex[v.uid] = client_index
    end
    if rtn_msg.people_num ~= self.people_num and rtn_msg.is4To32 then
        -- print('游戏人数')
        self.people_num = rtn_msg.people_num
        local people_num = rtn_msg.people_num
        RoomInfo.updateCurPeopleNum(people_num)
        RoomInfo.updateTotalPeopleNum(people_num)
        -- 重置头像位置
        self:gameStartPeopleChange(rtn_msg)

        self.wanfa_str = self:getWanFaStr()
        self:setShuoMing(self.wanfa_str)
    end

    local num = 0
    for i , v in pairs(PlayerData.IDToUserData) do
        num = num + 1
    end
    INFO('实际玩家人数',num,'应到玩家人数',RoomInfo.getTotalPeopleNum())
    if num ~= RoomInfo.getTotalPeopleNum() then
        gt.uploadErr('mj start peopleNumErroJoinRoomAgain')
        self:peopleNumErroJoinRoomAgain()
        return
    end

    self:setBtnGameWithPeopleNum()

    -- 重设手牌坐标
    self:initHandCardPos()
    -- 人数变化重设出牌位置
    self:initOutCardPos()
    commonlib.closeQuickStart(self)

    self:resetOperBtnTag()

    self:resetClickSelected()

    self:ResetPassData()

    self:removeResultNode()

    self.quan_lbl:setVisible(true)

    self:initImgGuoHuIndex()

    self:initImgGuoPengIndex()

    self:invisibleZhuBei()
    self.PassTing_count = 0
    -- 庄家ID
    self.banker =  self:indexTrans(rtn_msg.host_id) -- need
    if not self.banker or self.banker < 1 or self.banker > 4 then
        local errStr = self:mjUploadError('onRcvMjGameStart ',tostring(rtn_msg.host_id),tostring(self.banker))
        gt.uploadErr(errStr)
        log(errStr)
        local errStr = getPlayerDataDebugStr()
        gt.uploadErr(errStr)
        log(errStr)
    end
    -- print('DDDDDDDDDDDDDDDD')
    -- 根据庄家初始化 东南西北位置
    self:initSouthPan()
    -- print('CCCCCCCCCCCCCC')
    -- 显示庄家图标
    self.player_ui[self.banker]:getChildByName("Zhang"):setVisible(true)

    self:showWatcher(self.banker)
    -- 关闭了分享按钮
    commonlib.showShareBtn(self.share_list)
    self.wanfa:setVisible(true)
    self.btnjiesan:setVisible(false)
    commonlib.showbtn(self.jiesanroom)
    -- print('111111111111111111111111111111')
    if not self.is_playback then
        ymkj.setHeartInter(0)
    end
    -- print('22222222222222222')
    self:setLastJuPackget(rtn_msg)

    self.is_game_start = (rtn_msg.status ~= 0)
    --------------------------------------------------------
    self:disapperClubInvite()
    --------------------------------------------------------
    -- print('333333333333333333333333')
    self:runHeadAction(rtn_msg)
    -- print('AAAAAAAAAAAAAA')
    self:firstTurnAnimation(rtn_msg)

    self:addPlist()
    self:removeAllHandCard()

    self:removeAllTingTag()

    if self.onRcvMjGameStartOwnerData then
        self:onRcvMjGameStartOwnerData()
    end
    -- print('BBBBBBBBBBBBBBB')
    if not self.isKouPai then
        self:playKaiWang(rtn_msg)
    else
        self.left_card_num = rtn_msg.left_card_num
    end

    -- 战绩数据
    if self.total_ju == 1 and rtn_msg.log_ju_id then
        gt.addMissJuId(rtn_msg.log_ju_id)
    end
end

function MJBaseScene:onRcvReady(rtn_msg)
    -- 游戏准备
    local server_index = rtn_msg.index
    if not server_index then
        return
    end
    local index = PlayerData.getPlayerClientIDByServerID(server_index)
    if not index then
        return
    end
    local userData = PlayerData.getPlayerDataByServerID(server_index)
    if not userData then
        return
    end
    userData.score = rtn_msg.score
    if self.player_ui[index] then

        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
        -- 设置分数
        print('准备后设置分数')
        print(userData.score)
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index],"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(rtn_msg.score+1000))
        if not rtn_msg.piaoniao or rtn_msg.piaoniao == 0 then
            self.player_ui[index]:getChildByName("PJN"):setVisible(false)
        else
            self.player_ui[index]:getChildByName("PJN"):setVisible(true)
            tolua.cast(self.player_ui[index]:getChildByName("PJN"), "ccui.ImageView"):loadTexture("ui/qj_mj/"..rtn_msg.piaoniao..".png")
        end
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function MJBaseScene:updateIndexInReady(rtn_msg)
    if rtn_msg.players and #rtn_msg.players > 0 then
        PlayerData.updatePlayerInfoByReady(rtn_msg.players)
        RoomInfo.updateTotalPeopleNum(#rtn_msg.players)
    end
end

function MJBaseScene:onRcvMjCoolDown(rtn_msg)
    WARN('#############onRcvMjCoolDown')
    dump(rtn_msg)
    WARN('#############onRcvMjCoolDown')
    if self.IngoreOpr then
        self.IngoreOpr = false
        return
    end
    self.action_msg = rtn_msg
    if self.oper_pai_bg then
        self.oper_pai_bg:removeFromParent(true)
        self.oper_pai_bg = nil
    end
    local is_action = true
    if not self.action_msg.actions then
        is_action = false
    elseif #self.action_msg.actions == 0 then
        is_action = false
    else
        for __,v in ipairs(self.action_msg.actions) do
            if v == 1 or v == 0 then
                is_action = false
            end
        end
    end
    if self.action_msg.has_action == true then
        is_action = true
    end
    if not is_action and self.show_pai_out then
        self:removeShowPai()
    end
    self:showAction()
end

function MJBaseScene:onRcvMjDrawCard(rtn_msg)
    WARN('#############onRcvMjDrawCard')
    dump(rtn_msg)
    WARN('#############onRcvMjDrawCard')

    self.draw_card_server_index = rtn_msg.index
    local index = self:indexTrans(rtn_msg.index)
    if not index or index < 1 or index > 4 then
        local errStr = self:mjUploadError('onRcvMjDrawCard',tostring(rtn_msg.index),tostring(index))
        gt.uploadErr(errStr)
        log(errStr)
        local errStr = getPlayerDataDebugStr()
        gt.uploadErr(errStr)
        log(errStr)
    end
    self:removeShowPai()
    self.draw_card_msg = rtn_msg

    self.for_draw_card = rtn_msg.card
    if index == 1 then
        self:dongZhangCleanGuoHu()
        self:setImgGuoPengIndexVisible(1, false)
    end
    self:showWatcher(index)

    self.last_draw_card_id = self.draw_card_msg.card

    self:draw_card()
end

function MJBaseScene:draw_card()
    AudioManager:playDWCSound("sound/mj/card_click_effect.mp3")
    if not self.draw_card_msg and not self.is_playback then
        self:send_join_room_again()
        return
    end
    self.left_card_num = self.draw_card_msg.left_card_num
    self.left_lbl:setString(self.left_card_num)

    local index = self:indexTrans(self.draw_card_msg.index)
    local pai = nil
    if index == 1 then
        pai = self:getCardById(index, self.draw_card_msg.card)
        pai.card_id = self.draw_card_msg.card
        pai.sort = 0
    elseif self.is_playback then
        pai = self:getCardById(index, self.draw_card_msg.card, "_stand")
        pai.card_id = self.draw_card_msg.card
        pai.sort = -1
    else
        pai = self:getBackCard(index)
        pai.card_id = 1000
        pai.sort = 0
    end

    -- 摸牌必须是第十四张
    local i = 14

    -- 少于十三张，牌数不对
    if not index or not self.hand_card_list[index] or not self.hand_card_list[index][i-1] then
        local errStr = self:mjUploadError('draw_card',tostring(self.draw_card_server_index),tostring(index))
        gt.uploadErr(errStr)
        log(errStr)
        local errStr = getPlayerDataDebugStr()
        gt.uploadErr(errStr)
        log(errStr)
    end

    if self.is_playback then
        local pos  = self:getReplay14thCardPosition(index)

        pai:setPosition(cc.p(pos.x, pos.y+80))
        pai:runAction(cc.MoveTo:create(0.07, pos))

        self.node:addChild(pai)
        self:sortHandCardExByIndex(index,pai,i)
    else
        self:placeHandCard(index)

        self.node:addChild(pai)

        local pos = self:get14thCardPosition(index)
        pai:setPosition(cc.p(pos.x, pos.y+80)) -- need

        local action = cc.MoveTo:create(self.drawCardActionTime, pos)
        pai:runAction(action)

        self:sortHandCardExByIndex(index,pai,i)
    end
    self.hand_card_list[index][i] = pai

    self.draw_card_msg = nil

    self:showAction()
end

function MJBaseScene:clientOutCardRollBack(rtn_msg)
    local open_card_index = self:indexTrans(rtn_msg.index)
    -- 发生错误，重连
    if rtn_msg.errno and rtn_msg.errno ~= 0 then
        if open_card_index == 1 then
            if rtn_msg.errno == 1006 then
                commonlib.showLocalTip("不能出牌，等待起手胡")
            elseif rtn_msg.errno == 1007 then
                commonlib.showLocalTip("王不能打出")
            elseif rtn_msg.errno == 1012 then
                commonlib.showLocalTip("不能出牌，等待玩家选择胡牌")
            elseif rtn_msg.errno == 1 then
                commonlib.showLocalTip('不能出牌，必须胡牌')
            else
                commonlib.showLocalTip('重连!')
            end
            self:removeShowPai()
            self:discoreCursor()
            local last_out_card = self.out_card_list[1][#self.out_card_list[1]]
            if last_out_card then
                local card_id = last_out_card.card_id
                local hand_card = self:getCardById(1, card_id)
                hand_card.card_id = card_id
                hand_card.sort = 0
                self.hand_card_list[1][#self.hand_card_list[1]+1] = hand_card
                self.node:addChild(hand_card)
                self:placeHandCard(1)


                last_out_card:removeFromParent(true)
            end
        end
    end
end

function MJBaseScene:onRcvMjOutCard(rtn_msg)
    if self.isTuoGuan then
        self:removeTingArrow()
    end
    if not self.out_from_client then
        dump(rtn_msg)
    end
    self.open_card_server_index = rtn_msg.index
    local open_card_index = self:indexTrans(rtn_msg.index) -- need

    if not open_card_index or open_card_index < 1 or open_card_index > 4 then
        if self.out_from_client then
            local errStr = self:mjUploadError('onRcvMjOutCard fc',tostring(rtn_msg.index),tostring(open_card_index))
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
        else
            local errStr = self:mjUploadError('onRcvMjOutCard fs',tostring(rtn_msg.index),tostring(open_card_index))
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
        end
    end

    -- 跟庄显示动画
    if rtn_msg.gen_zhuang then
        local sp = cc.Sprite:create("ui/qj_mj/gz-fs8.png")
        sp:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
        self:addChild(sp, 10000)
        sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(0.3), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
            sp:removeFromParent(true)
        end)))
    end

    local bForceRunServer = false
    if open_card_index == 1 and 14 == #self.hand_card_list[open_card_index] then
        bForceRunServer = true
    end
    if not bForceRunServer then
        if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD and open_card_index == 1 and not self.out_from_client and not self.is_playback then
            self:clientOutCardRollBack(rtn_msg)
            return
        end
    end

    self:showWatcher(open_card_index)

    if rtn_msg.index >=1 and rtn_msg.index <= 4 then
        local open_card_index = self:indexTrans(rtn_msg.index)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            self.oper_panel:setVisible(false)
            self.chi_panel:setVisible(false)
            local old_ui = self:getChildByTag(1369)
            if old_ui then
                old_ui:removeFromParent(true)
            end

            self.can_opt = nil
            self.oper_panel.no_reply = nil
        end
        if rtn_msg.cards and rtn_msg.cards[1] then
            print('出牌')
            dump(rtn_msg.cards)
            print('出牌')
            self.last_out_card = rtn_msg.cards[1]
        end
        -- 出牌
        if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD then
            if rtn_msg.errno and rtn_msg.errno ~= 0 then
                if open_card_index == 1 then
                    self.can_opt = true
                     if self.show_pai then
                        if self.show_pai.card then
                            self.show_pai.card:setVisible(true)
                            self.show_pai.card = nil
                        end
                        self.show_pai:removeFromParent(true)
                        self.show_pai = nil
                    end
                    self:placeHandCard(open_card_index)
                    if rtn_msg.errno == 1006 then
                        commonlib.showLocalTip("不能出牌，等待起手胡")
                    elseif rtn_msg.errno == 1007 then
                        commonlib.showLocalTip("王不能打出")
                    elseif rtn_msg.errno == 1012 then
                        commonlib.showLocalTip("不能出牌，等待玩家选择胡牌")
                    elseif rtn_msg.errno == 1 then
                        commonlib.showLocalTip('不能出牌，必须胡牌')
                    end
                end
            else
                if self.oper_pai_bg then
                    self.oper_pai_bg:removeFromParent(true)
                    self.oper_pai_bg = nil
                end
                if self.oper_pai_id then
                    self.oper_pai_id = 0
                end
                if self.is_playback and self.soundTing then
                    self:playTingAct(self,open_card_index)
                end
                self.pre_out_direct = open_card_index

                self:openCard(open_card_index, rtn_msg.cards, 0)
                self:playCardSound(rtn_msg.cards[1], open_card_index)
                if self.ting_status then
                    self:addCardShadow()
                end
            end
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_CHI_CARD then
        -- 吃牌
            local groups = rtn_msg.group or rtn_msg.cards
            for __, v in ipairs(groups) do
                if v ~= rtn_msg.cards[1] and v ~= rtn_msg.cards[2] then
                    rtn_msg.cards[3]= v
                    break
                end
            end
            local preUser = self:findPreUser(rtn_msg.index)
            self:openCard(open_card_index, rtn_msg.cards, 1, nil, preUser)
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_PENG then
        -- 碰牌
            self:removeShowPai()
            local last_card_index = rtn_msg.last_user and self:indexTrans(rtn_msg.last_user) or 0
            self:openCard(open_card_index, rtn_msg.cards, 2, nil, last_card_index)
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_GANG then
        -- 杠牌
            if rtn_msg.last_user >10 then
                rtn_msg.last_user = rtn_msg.last_user -10
            end
            local last_card_index = rtn_msg.last_user and self:indexTrans(rtn_msg.last_user) or 0
            if rtn_msg.typ ~= 1 then
                rtn_msg.cards[4] = rtn_msg.cards[1]
            end
            if rtn_msg.typ == 3 or rtn_msg.typ == 1 then
                self:openCard(open_card_index, rtn_msg.cards, 11, nil, last_card_index)
            else
                self:openCard(open_card_index, rtn_msg.cards, 10, nil, last_card_index)
            end
            if self.ting_status then
                self:addCardShadow()
            end
        end
    end
end
function MJBaseScene:resetPlayerHandCards(rtn_msg)
    if self.is_playback then return end

    local index = self:indexTrans(rtn_msg.index)

    if index == 1 then return end

    for ii = 1,#self.hand_card_list[index] do
        if self.hand_card_list[index][ii].sort == 0 then
            self.hand_card_list[index][ii]:removeFromParent(true)
            self.hand_card_list[index][ii] = nil
        end
    end
    for i,v in ipairs(self.hand_card_list[index]) do
        if v.sort == 0 then
            v:removeFromParent(true)
            v = nil
        end
    end

    for i, v in ipairs(rtn_msg.cards) do
        local pai   =  self:getCardById(index, v, "_stand")
        pai.card_id = v
        pai.sort    = -1
        self.node:addChild(pai)
        self.hand_card_list[index][#self.hand_card_list[index]+1] = pai
    end
    self:sortHandCard(index)
    self:placeHandCard(index)
end

function MJBaseScene:onRcvMjOperOther(rtn_msg)
    local open_card_index = self:indexTrans(rtn_msg.index) -- need
    self.oper_panel:setVisible(false)
    if rtn_msg.typ == 23 then -- 推
        self:onRcvMjTingPai(rtn_msg)
        if not rtn_msg.canKe then
            self:resetPlayerHandCards(rtn_msg)
            self:getTingCards(open_card_index)
        end
    elseif rtn_msg.typ == 22 then -- 刻
        local cards   = rtn_msg.KeCard
        local keCards = nil

        if cards and #cards ~= 0 then
            for i, v in ipairs(cards) do
                keCards = {v, v, v}
                self:openCard(open_card_index, keCards, rtn_msg.typ, nil, open_card_index)
            end
        end
        self:resetPlayerHandCards(rtn_msg)
        self:getTingCards(open_card_index)
    elseif rtn_msg.typ == 21 then -- 起手花
        self:openCard(open_card_index, rtn_msg.cards, rtn_msg.typ, nil, open_card_index)
    end
end

function MJBaseScene:onRcvHu(rtn_msg)
    self.oper_panel:setVisible(false)
    self.chi_panel:setVisible(false)
    if self.ting_tip_layer then
        self.ting_tip_layer:setVisible(false)
    end
    for index = 2, 4 do
        if self.ting_tip_card and self.ting_tip_card[index] then
           self.ting_tip_card[index]:setVisible(false)
        end
    end

    self.ting_list = {}
    self:removeTingArrow()

    self:resetHightCard()

    self.can_opt = nil

    self:stopCountdownWaitOverTime()
    self:playHuAni(rtn_msg)
    self:countdownWaitOverTime()
end

function MJBaseScene:onRcvReault(rtn_msg)
    if rtn_msg.log_data_id ~= 0 then
        self:save_new_record(rtn_msg,self.RecordGameType)
    end

    self:addPlist()
    -- self:removeAllTingTag()
    self:stopSouthAction()

    self:stopCountdownWaitOverTime()

    if self.js_node and rtn_msg.jiesan_detail then
        self.js_node:removeFromParent(true)
        self.js_node = nil
    end

    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))

    if not self.wait_over then

        AudioManager:playDWCSound("sound/mj/liuju.mp3")

        local sp = cc.Sprite:create("ui/qj_mj/hn0.png")
        sp:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
        self:addChild(sp, 10000)
        sp:setOpacity(0)
        local tt = 0
        if self.left_card_num == 0 then
            tt = 1.5
        end
        sp:runAction(cc.Sequence:create(cc.DelayTime:create(tt), cc.FadeIn:create(0.3), cc.DelayTime:create(1.2), cc.CallFunc:create(function()
            sp:removeFromParent(true)
        end)))

        self.wait_over = tt+1.5
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(self.wait_over), cc.CallFunc:create(function()
        if g_channel_id == 800002 then
            AudioManager:stopPubBgMusic()
        end
        self:initResultUI(rtn_msg)
        self.wait_over = nil
    end)))
end

function MJBaseScene:onRcvJiesan(rtn_msg)
    self:unregisterEventListener()
    AudioManager:stopPubBgMusic()
    if self.is_fangzhu then
        commonlib.showTipDlg("游戏未开始,解散包厢将不会扣除房卡", function(is_ok)
            if is_ok then
                local scene = require("scene.MainScene")
                local gameScene = scene.create()
                if cc.Director:getInstance():getRunningScene() then
                    cc.Director:getInstance():replaceScene(gameScene)
                else
                    cc.Director:getInstance():runWithScene(gameScene)
                end
            end
        end,1)
    else
        if self.ownername then
            commonlib.showTipDlg("房间已被 ".. self.ownername .." 解散,请重新加入游戏", function(is_ok)
                if is_ok then
                    local scene = require("scene.MainScene")
                    local gameScene = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                end
            end,1)
        else
            local scene = require("scene.MainScene")
            local gameScene = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end
end

function MJBaseScene:onRcvApplyJieSan(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index = (rtn_msg.index)

    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid = userData.uid
    log(PlayerData.MyServerIndex)
    rtn_msg.self = (rtn_msg.index == PlayerData.MyServerIndex)
    commonlib.showJiesan(self, rtn_msg, RoomInfo.people_total_num)
end

function MJBaseScene:onRcvApplyJieSanAgree(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index = (rtn_msg.index)

    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid = userData.uid
    rtn_msg.self = (rtn_msg.index == PlayerData.MyServerIndex)
    commonlib.showJiesan(self, rtn_msg, RoomInfo.people_total_num)
end


function MJBaseScene:getQuickStartWanFaStr()
    local wanfa = commonlib.split(self.wanfa_str,'\n')
    local str = ''
    for i , v in ipairs(wanfa) do
        str = str .. v .. '.'
    end

    print (str)
    return str
end

function MJBaseScene:onRcvApplyStart(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index = (rtn_msg.index)

    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid = userData.uid
    rtn_msg.self = (rtn_msg.index == PlayerData.MyServerIndex)

    local str = self:getQuickStartWanFaStr()

    commonlib.showQuickStart(self, rtn_msg, RoomInfo.people_total_num,str)
end

function MJBaseScene:onRcvApplyStartAgree(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index = (rtn_msg.index)

    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid = userData.uid
    rtn_msg.self = (rtn_msg.index == PlayerData.MyServerIndex)

    local str = self:getQuickStartWanFaStr()

    commonlib.showQuickStart(self, rtn_msg, RoomInfo.people_total_num,str)
end

function MJBaseScene:onRcvRoomChat(rtn_msg)
    if rtn_msg.msg_type == 3 then
        EventBus:dispatchEvent(EventEnum.onRcvSpeek,rtn_msg)
    else
        EventBus:dispatchEvent(EventEnum.onMjSound,rtn_msg)
    end
end

function MJBaseScene:onRcvRoomChatBQ(rtn_msg)
    if (not rtn_msg.index) or (not rtn_msg.to_index) then return end
    local index = self:indexTrans(rtn_msg.index)
    local toindex = self:indexTrans(rtn_msg.to_index)
    if (not self.player_ui[index]) or (not self.player_ui[toindex]) then return end
    if self.my_index ~= rtn_msg.index and (self.ignoreArr[self.my_index] or self.ignoreArr[rtn_msg.index]) then return end
    commonlib.runInteractiveEffect(self, self.player_ui[index], self.player_ui[toindex], rtn_msg.msg_id ,index,toindex)
end

function MJBaseScene:onRcvTuoGuan(rtn_msg)
    local player_index = self:indexTrans(rtn_msg.index)
    self:tuoGuanStatus(player_index, rtn_msg.isTuoGuan)
end

function MJBaseScene:tuoGuanStatus(player_index, isTuoGuan)
    if player_index == 1 then
        self.isTuoGuan = isTuoGuan
        if self.tdh_need_bTing then
            self.tdh_need_bTing = false
            self:removeCardShadow()
        end
        self:ResetPassData()
        self.panTuoguan:setVisible(isTuoGuan)
    else
       -- commonlib.showLocalTip(isTuoGuan and (player_index .. "号位玩家已开启托管~~~~~~~") or (player_index .. "号位玩家已取消托管！!!!!"))
    end
    self.player_ui[player_index]:getChildByName("tuoguan"):setVisible(isTuoGuan)
end

function MJBaseScene:removeAllOutCard()
    for i, v in ipairs(self.out_card_list) do
        for __, vv in ipairs(v) do
            vv:removeFromParent(true)
        end
        self.out_card_list[i] = {}
    end
end

function MJBaseScene:resetPlayerStauts()

end

function MJBaseScene:removeLaZiCard()
    self.wang_card_list = {}
    self.wang_cards = {}
    local haoziSprite = self.node:getChildByName('haoziSprite')
    if haoziSprite then
        haoziSprite:stopAllActions()
        haoziSprite:removeFromParent(true)
    end
    local haoziPai = self.node:getChildByName('haoziPai')
    if haoziPai then
        haoziPai:stopAllActions()
        haoziPai:removeFromParent(true)
    end
end

function MJBaseScene:resetData()
    self:resetOperBtnTag()

    self.tdh_need_bTing = false

    self:removeResultNode()

    self:removeLaZiCard()

    if self.niao_node then
        self.niao_node:removeFromParent(true)
        self.niao_node = nil
    end
    self:setImgGuoPengIndexVisible(1,false)
    self:setImgGuoHuIndexVisible(1,false)
    self:setImgGuoLongIndexVisible(1,false)

    self:stopCountdownWaitOverTime()

    self:stopSouthAction()

    self:removeAllTingTag()

    self.oper_panel:setVisible(false)

    for i, v in ipairs(self.wang_card_list or {}) do
        if v then
            v:removeFromParent(true)
        end
    end
    self.wang_card_list = {}
    self:initImgGuoHuIndex()

    self:removeShowPai()

    if self.is_pmmj or self.is_pmmjyellow then
        self.left_lbl:setString("-")
    else
        self.left_lbl:setVisible(false)
    end

    self.ting_status = nil
    self.oper_panel.time_out_flag = nil
    self.oper_panel.no_reply = nil
    self.can_opt = nil
    self.action_msg = nil
    self.draw_card_msg = nil


    self:discoreCursor()
    self:removeAllHandCard()
    self:removeAllOutCard()
    self:removeAllTingTag()
    self:removeShowPai()
    self:ResetPassData()
    self:cancleSelectCard()
end

function MJBaseScene:onRcvMjJoinRoomAgain(rtn_msg)
    if not self.curLuaFile then
        return
    end
    self:unregisterEventListener()
    if (not rtn_msg.errno or rtn_msg.errno == 0) and rtn_msg.room_id ~= 0 then
        GameGlobal.MjSceneReplaceMJScene = true
        local MJScene = require(self.curLuaFile)
        cc.Director:getInstance():replaceScene(MJScene.create(rtn_msg))
    else
        AudioManager:stopPubBgMusic()
        local scene = require("scene.MainScene")
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

function MJBaseScene:onRcvLeaveRoom(rtn_msg)
    self:setClubInvite()
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 then

        PlayerData.updatePlayerInfoByLeaveRoom(rtn_msg)

        self:setRoomCurPeopleNumByLeaveRoom(rtn_msg)
        local people_num = RoomInfo.getCurPeopleNum()
        self:setQuickStartPeople(people_num)

        if self.player_ui[index] then
            commonlib.lixian(self.player_ui[index])
            self.player_ui[index]:setVisible(false)
            -- self.player_ui[index].coin = nil
            -- self.player_ui[index].user = nil
            -- self.player_ui[index].ver = nil
            local ipui = self:getChildByTag(81000+index)
            if ipui then
                ipui:removeFromParent(true)
            end
            self:checkIpWarn()
        end
        self:setBtnsAfterLeave()
        commonlib.interQuickStart(self)
    else
        self:unregisterEventListener()
        AudioManager:stopPubBgMusic()
        local scene = require("scene.MainScene")
        local gameScene = scene.create({operType = rtn_msg.operType})
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end
    end
end

function MJBaseScene:setBtnsAfterLeave()

end

function MJBaseScene:onRcvInLine(rtn_msg)
    -- print('------------------------------上线------------------------------')
    -- dump(rtn_msg)
    -- print('------------------------------上线------------------------------')
    if not self.indexTrans or
        not self.player_ui
        then
        return
    end
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index])
    end
end

function MJBaseScene:onRcvOutLine(rtn_msg)
    -- print('------------------------------离线------------------------------')
    -- dump(rtn_msg)
    -- print('------------------------------离线------------------------------')
    if not self.indexTrans or
        not self.player_ui
        then
        return
    end
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index], "PJN")
    end
end

function MJBaseScene:onRcvSyncUserData(rtn_msg)
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

function MJBaseScene:onRcvSyncClubNotify(rtn_msg)
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

function MJBaseScene:onRcvMjTingPai(rtn_msg)
    log('XXXXXX 听牌了 XXXXXX')
    local nLocalIndex = self:indexTrans(rtn_msg.index)
    if rtn_msg.is_ting and 1 == nLocalIndex then
        self.ting_status = true
        self.ting_list = {}
        self:addCardShadow()
    end
    self:addTingTag(nLocalIndex)

    if not rtn_msg.is_ting then
        self.soundTing = true
    end

    self:playTingAct(self, nLocalIndex)
end

function MJBaseScene:playTingAct(root, nLocalIndex)
    local pos = cc.p(self.open_card_ani_pos_list[nLocalIndex].x, self.open_card_ani_pos_list[nLocalIndex].y)

    local fileJson = "ui/qj_mj/majiangshandiandonghua/datangmajiangtexiaozidonghua.ExportJson"
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
    local armature = ccs.Armature:create('datangmajiangtexiaozidonghua')
    local function animationEvent(armatureBack,movementType,movementID)
        if movementType == 1 then
            armature:removeFromParent(true)
        end
    end
    armature:getAnimation():setMovementEventCallFunc(animationEvent)
    armature:getAnimation():play('05texiaodonghuatingtexiaodonghua',0,0)
    armature:setPosition(pos)
    armature:setLocalZOrder(self.ZOrder.DIAN_PAO_ZOREDER or 99)
    self:addChild(armature)
end

function MJBaseScene:onRcvClubModify(rtn_msg)
    self:clubRename(rtn_msg)
end

function MJBaseScene:onRcvPassHu(rtn_msg)
    if rtn_msg.is_pass_long then
        self.is_pass_long = rtn_msg.is_pass_long
    end
end

function MJBaseScene:getBackUpPos(direct)
    local pos = clone(self.hand_card_pos_list[direct].init_pos)
    if direct%2 ~= 0 then
        pos.x = pos.x + 13*self.hand_card_pos_list[direct].space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
        pos.y = pos.y + 13*self.hand_card_pos_list[direct].space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
    else
        pos.x = pos.x + 13*self.hand_card_pos_list[direct].space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]*0.5
        pos.y = pos.y + 13*self.hand_card_pos_list[direct].space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]*0.5
    end
    return pos
end

function MJBaseScene:getReplay14thCardPosition(direct)
    -- 为什么取不到位置了 ????
    if direct == 1 and (not self.hand_card_list or not self.hand_card_list[direct]) then
        return self:getBackUpPos(direct)
    end
    local pos = cc.p(self.hand_card_list[direct][#self.hand_card_list[direct]]:getPosition())
    if not pos then
        return self:getBackUpPos(direct)
    end
    if direct%2 == 0 then
        pos.x = pos.x+self.hand_card_pos_list[direct].space_replay.x + self.hand_card_pos_list[direct].space_replay.x*self.z_p_s[direct]/2
        pos.y = pos.y+self.hand_card_pos_list[direct].space_replay.y + self.hand_card_pos_list[direct].space_replay.y*self.z_p_s[direct]/2
    elseif direct == 3 then
        pos.x = pos.x+self.hand_card_pos_list[direct].space_replay.x + self.hand_card_pos_list[direct].space_replay.x*self.z_p_s[direct]
        pos.y = pos.y+self.hand_card_pos_list[direct].space_replay.y + self.hand_card_pos_list[direct].space_replay.y*self.z_p_s[direct]
    elseif direct == 1 then
        pos.x = pos.x + self.hand_card_pos_list[direct].space.x+self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
        pos.y = pos.y + self.hand_card_pos_list[direct].space.y+self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
    end
    if not pos then
        return self:getBackUpPos(direct)
    end
    return pos
end

function MJBaseScene:get14thCardPosition(direct)
    -- 为什么取不到位置了 ????
    if not self.hand_card_list or not self.hand_card_list[direct] then
        return self:getBackUpPos(direct)
    end
    local pos = cc.p(self.hand_card_list[direct][#self.hand_card_list[direct]]:getPosition())
    if not pos then
        return self:getBackUpPos(direct)
    end
    if direct%2 ~= 0 then
        pos.x = pos.x+self.hand_card_pos_list[direct].space.x+self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
        pos.y = pos.y+self.hand_card_pos_list[direct].space.y+self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
    else
        pos.x = pos.x+self.hand_card_pos_list[direct].space.x+self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]*0.5
        pos.y = pos.y+self.hand_card_pos_list[direct].space.y+self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]*0.5
    end
    if not pos then
        return self:getBackUpPos(direct)
    end
    return pos
end

function MJBaseScene:set14thCardPosition(direct)
    -- 设置第十四张牌
    if #self.hand_card_list[direct] == 14 then
        local pos = cc.p(self.hand_card_list[direct][14]:getPosition())
        if direct%2 ~= 0 then
            pos.x = pos.x+self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
            pos.y = pos.y+self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
        else
            pos.x = pos.x+self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]*0.5
            pos.y = pos.y+self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]*0.5
        end

        if direct == 1 then
            pos.x = self:adjustLastCardPos(pos.x,self.hand_card_list[direct][14])
        end

        self.hand_card_list[direct][#self.hand_card_list[direct]]:setPosition(pos)
    end
end

function MJBaseScene:setShuoMing(str)
    local shuoming = true
    local btn_shuoming = ccui.Helper:seekWidgetByName(self.node, "btn-shuoming")
    local shuoming_lbl = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "shuomingBg"), "ccui.ImageView")
    shuoming_lbl:setLocalZOrder(self.ZOrder.WANGFA_ZOREDER)
    shuoming_lbl:setVisible(false)
    local shuoming_txt = ccui.Helper:seekWidgetByName(self.node, "shuoming")
    shuoming_txt:setString(str)
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
        shuoming_lbl:setContentSize(cc.size(shuoming_lbl_size.width,shuoming_txt_size.height + 20))
        shuoming_txt:setPositionY(shuoming_txt_size.height + 10)
    end
end

function MJBaseScene:stopSouthAction()
    for i = 1 , 4 do
        if self.direct_list[i] then
            self.direct_list[i]:stopAllActions()
            self.direct_list[i]:setVisible(false)
        end
    end
    self.direct_img_cur = nil
end

function MJBaseScene:setOwnerName(room_info)
    if room_info.index~=1 and room_info.other and room_info.other[1] then
        self.ownername =  room_info.other[1].name
    end
end

function MJBaseScene:setClubEnterMsg()
    if self.club_id and self.club_name and self.club_index then
        print('```````````````````````````')
        GameGlobal.is_los_club = true
        GameGlobal.is_los_club_id = self.club_id
    end
end

function MJBaseScene:setRoomNumber(parent)
    if not self.club_name then
        parent:setString("房间号:"..self.desk)
    else
        if pcall(commonlib.GetMaxLenString, self.club_name, 12) then
            parent:setString(commonlib.GetMaxLenString(self.club_name, 12) .. "的亲友圈")
        else
            parent:setString(self.club_name .. "的亲友圈")
        end
        if self.club_index then
            if pcall(commonlib.GetMaxLenString, self.club_name, 12) then
                parent:setString(commonlib.GetMaxLenString(self.club_name, 12) .. "亲友圈" .. self.club_index ..'号')
            else
                parent:setString(self.club_name .. "亲友圈" .. self.club_index ..'号')
            end
        end
    end
end

function MJBaseScene:continueGame(node, jxyx, rtn_msg)
    local function countinue(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            print("open continue")
            node:removeFromParent(true)

            if self.niao_node then
                self.niao_node:removeFromParent(true)
                self.niao_node = nil
            end
            for play_index = 1, 4 do
                self.player_ui[play_index]:setPosition(cc.p(self.wenhao_list[play_index]:getPosition()))
            end
            self:setImgGuoPengIndexVisible(1,false)
            self:setImgGuoHuIndexVisible(1,false)
            self:setImgGuoLongIndexVisible(1,false)

            self:stopCountdownWaitOverTime()

            self:stopSouthAction()

            self:removeAllTingTag()

            self.oper_panel:setVisible(false)

            for i, v in ipairs(self.wang_card_list or {}) do
                if v then
                    v:removeFromParent(true)
                end
            end
            self.wang_card_list = {}
            self:initImgGuoHuIndex()

            self:removeAllHandCard()

            self:removeAllOutCard()

            self:removeShowPai()

            if self.is_pmmj or self.is_pmmjyellow then
                self.left_lbl:setString("-")
            else
                self.left_lbl:setVisible(false)
            end

            self.ting_status = nil
            self.oper_panel.time_out_flag = nil
            self.oper_panel.no_reply = nil
            self.can_opt = nil
            self.action_msg = nil
            self.draw_card_msg = nil

            self.pre_out_direct = nil
            self:showCursor()

            for index, v in ipairs(self.player_ui) do
                local userData = PlayerData.getPlayerDataByClientID(index)
                if userData and userData.score then
                    print('继续游戏设置分数',userData.score)
                    tolua.cast(ccui.Helper:seekWidgetByName(v,"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(userData.score+1000))
                end
                v:getChildByName("Zhang"):setVisible(false)
            end

            if not self.is_playback then
                if not rtn_msg.results then
                    if self.total_ju > 100 then
                        self:setLastJu(self.total_ju, rtn_msg.cur_quan or 0)
                    else
                        self:setLastJu(self.total_ju, rtn_msg.cur_ju or 0)
                    end
                    if self.piaoFen and self.piaoFen > 100 then
                        self.pnPiaoFen:setVisible(true)
                        self.pnPiaoFen:setEnabled(true)
                    else
                        self:sendReady()
                    end
                    if g_channel_id == 800002 then
                        AudioManager:playDWCBgMusic("sound/bgGame.mp3")
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, rtn_msg.log_ju_id, rtn_msg.gmId)
                end
            else
                if not rtn_msg.results then
                    self:unregisterEventListener()
                    AudioManager:stopPubBgMusic()
                    local scene = require("scene.MainScene")
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
    end
    jxyx:addTouchEventListener(countinue)
    if AUTO_PLAY then
        countinue(nil,ccui.TouchEventType.ended)
    end
end

function MJBaseScene:setBtnWanFa()
    --  玩法按钮
    self.wanfa =ccui.Helper:seekWidgetByName(self.node, "btn-wanfa")
    self.wanfa:setVisible(false)
    self.wanfa:addTouchEventListener(  function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local HelpLayer = require("scene.kit.HelpDialog")
                    local help = HelpLayer.create(self, self.mjTypeWanFa)
                    help.is_in_main = true
                    self:addChild(help, 100000)
                end
            end)
end

function MJBaseScene:resultCard(v,node,pos,jiashuju)
    local index = self:indexTrans(v.index)
    local cards = v.groups

    if #v.hands >= 14-(#v.groups*3) then
        v.hands[14-(#v.groups*3)] = v.hands[#v.hands]
        v.hands[15-(#v.groups*3)]= nil
    end

    local hand_koupai = nil
    if v.koupai then
        table.sort( v.koupai)
        hand_koupai =#cards +1
        cards[hand_koupai] = v.koupai
    end

    -- 打八张扣牌流程时解散未发数据,小结算显示手牌
    -- 自己手上已发的牌正常显示，未发的和其余玩家随机取值
    if #v.hands == 0 then
        if v.koupai and #v.koupai == 0 and jiashuju and #jiashuju >0 then
            local paibymyself ={}
            if index == 1 then
                for i,vv in ipairs(self.hand_card_list[1]) do
                    paibymyself[#paibymyself+1] = vv.card_id
                end

                for i = 1,13 - #self.hand_card_list[1] do
                    local num = math.random(1,#jiashuju)
                    paibymyself[#paibymyself+1] = jiashuju[num]
                    table.remove(jiashuju,num)
                end
            else
                for i = 1,13 do
                    local num = math.random(1,#jiashuju)
                    paibymyself[i] = jiashuju[num]
                    table.remove(jiashuju,num)
                end
            end
            v.hands = paibymyself
            table.sort(v.hands)
        end
    end
    --------------------------------

    if #v.hands%3 == 2 then
        for i = 1 , #v.hands do
            if v.hands[i] == v.hu_cards[1] then
                table.remove(v.hands,i)
                break
            end
        end
    end
    local hand_z = #cards+1
    cards[hand_z] = v.hands

    local pao_z = nil
    if v.hu_cards then
        cards[#cards+1] = v.hu_cards
        pao_z = #cards
    end

    local atch_scale = 0.7
    if g_visible_size.width/g_visible_size.height >= 2 then
        atch_scale = 1136/g_visible_size.width
    end
    local scale = 0.55*atch_scale
    if self.is_pmmj or self.is_pmmjyellow then
        scale = 0.83*atch_scale
    end
    -- print('1111111111111111111')
    for i, v in ipairs(cards or {}) do
        local cards_hash = {}
        for ii ,vv in pairs(v) do
            if ii ~= 'last_user' then
                cards_hash[tonumber(ii)] = vv
            end
            -- print('1111111111111 ' .. i .. ' ' .. cards_hash[i])
        end
        v = cards_hash
        if v and #v > 0 then
            local bu_gang = nil
            if #v == 5 and i ~= niao_z and i ~= hand_z and i ~= hand_koupai then
                bu_gang = v[5]
                v[5]=nil
                v[4]=nil
            end
            for ii, vv in ipairs(cards_hash) do
                if vv ~= 0 then
                    local pai = nil
                    local pscale = nil
                    local add_card = nil
                    pai = self:getCardById(1, vv, "_stand", i < hand_z)
                    pai:setScale(scale*self.scard_size_scale[1]*self.single_scale)
                    ---添加阴影
                    if i == hand_koupai then
                        local card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
                        --card_shadow:setName('card_shadow')
                        card_shadow:setAnchorPoint(0, 0)
                        local iCardSize = pai:getContentSize()
                        local iCardShadowSize = card_shadow:getContentSize()
                        card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width)
                        card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height)
                        pai:addChild(card_shadow)
                    end
                    if not bu_gang or bu_gang ~= 2 then
                        add_card = self:getCardById(1, vv, "_stand", true)
                        add_card:setScale(1)
                    else
                        if self.is_pmmj then
                            add_card = self:createCardWithSpriteFrameName('ee_mj_b_up.png')
                        elseif self.is_pmmjyellow then
                            add_card = self:createCardWithSpriteFrameName('e_mj_b_up.png')
                        else
                            add_card = cc.Sprite:create(self.res3DPath.."/back1.png")
                        end
                    end
                    -- print('44444444444444444')
                    if bu_gang and ii==2 then
                        add_card:setScaleX(pai:getContentSize().width/add_card:getContentSize().width)
                        add_card:setScaleY(pai:getContentSize().height/add_card:getContentSize().height)
                        if self.is_pmmj or self.is_pmmjyellow then
                            add_card:setAnchorPoint(0, -0.17)
                        else
                            add_card:setAnchorPoint(0, -0.25)
                        end
                        pai.sp_order = 2
                        pai:addChild(add_card)
                    elseif pao_z == i then
                        local wang = cc.Sprite:create("ui/qj_mj/hu.png")
                        if self.is_pmmj or self.is_pmmjyellow then
                            wang:setScale(0.8)
                            wang:setAnchorPoint(-0.2, -1.8)
                        else
                            wang:setScale(1.3)
                            wang:setAnchorPoint(-0.25, -1.8)
                        end
                        pai:addChild(wang)
                    elseif niao_z == i and ii == 1 then
                        -- local wang = cc.Sprite:create("poker/mj/niao.png")
                        -- if self.is_pmmj then
                        --     wang:setScale(0.85)
                        --     wang:setAnchorPoint(-0.1, -2.1)
                        -- else
                        --     wang:setScale(1.25)
                        --     wang:setAnchorPoint(-0.25, -2.3)
                        -- end
                        -- pai:addChild(wang)
                    end
                    -- print('22222222222222222222')
                    pai:setPosition(cc.p(pos.x, pos.y))
                    node:addChild(pai, pai.sp_order or 1)
                    if self.is_3dmj then
                        pos.x = pos.x + self.hand_card_pos_list[1].space_result.x*self.scard_space_scale[1]*0.7*self.single_scale*atch_scale
                    else
                        pos.x = pos.x + self.hand_card_pos_list[1].space_result.x*self.scard_space_scale[1]*0.82*self.single_scale*atch_scale
                    end
                end
            end
            -- print('3333333333333333333333')
            if self.is_3dmj then
                pos.x = pos.x+self.hand_card_pos_list[1].space_result.x*self.z_p_s[1]*0.7*self.single_scale*atch_scale
            else
                pos.x = pos.x+self.hand_card_pos_list[1].space_result.x*self.z_p_s[1]*0.85*self.single_scale*atch_scale
            end
        end
    end
end

function MJBaseScene:btnRoomSetingLayerCallBack()
    local function callbackSpeed(param)
        self.TingAutoOutCard = param
        print('TingAutoOutCard',self.TingAutoOutCard)
    end

    local function callbackBg(ys)
        if not self.is_3dmj then
            self.img_bg:loadTexture(self.img_2d[ys])
        else
            self.img_bg:loadTexture(self.img_3d[ys])
        end
    end

    if self.is_playback then
        local SetLayer = require("scene.RoomSetingLayer")
        self:addChild(SetLayer.create(self.is_game_start,self.is_fangzhu,true), 100000)
    else

        local SetLayer = require("scene.kit.SetDialog")
        local shezhi = SetLayer.create(self,self.is_game_start,true,callbackBg,callbackSpeed)
        --shezhi.is_in_main = true
        self:addChild(shezhi, 100000)
    end
end

function MJBaseScene:addCardPlist()
    -- log('重新加载资源')
    if self.is_pmmjyellow then
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/bottom/Z_bottom.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/left/Z_left.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/right/Z_right.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/up/Z_up.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/mjEmpty.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2D/MJ/my/Z_my.plist')
    elseif self.is_pmmj then
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/bottom/Z_bottom.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/left/Z_left.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/right/Z_right.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/up/Z_up.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/mjEmpty.plist')
        cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/qj_mj/2Dbig/MJ/my/Z_my.plist')
    end
    -- log('重新加载资源')
end

function MJBaseScene:createCardWithSpriteFrameName(str)
    local cardCache = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
    local card = nil
    local function cardNilUploadError(str)
        local gametype = ''
        if self.is_pmmj then
            gametype = '2dbig'
        elseif self.is_pmmjyellow then
            gametype = '2d'
        elseif self.is_3dmj then
            gametype = '3d'
        end
        gt.uploadErr('a l card v ' .. str .. ' card t ' .. gametype) -- need
    end
    if not cardCache then
        -- log('资源被释放')
        self:addCardPlist()
        card = cc.Sprite:createWithSpriteFrameName(str)
        if not card then
            cardNilUploadError(str)
        end
    else
        card = cc.Sprite:createWithSpriteFrameName(str)
    end
    if not card then
        cardNilUploadError(str)
    end
    return card
end

function MJBaseScene:setBtnExit(node)
    ccui.Helper:seekWidgetByName(node, "btn-exit"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node:removeFromParent(true)
            self:unregisterEventListener()
            AudioManager:stopPubBgMusic()
            local scene = require("scene.MainScene")
            local gameScene = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end)
end

function MJBaseScene:setBtnJieSan()
    -- 返回大厅
    self.btnjiesan = ccui.Helper:seekWidgetByName(self.node, "btn-jiesan")
    self.btnjiesan:setVisible(not ios_checking)
    self.btnjiesan:addTouchEventListener(  function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.is_fangzhu then
                commonlib.showTipDlg("返回大厅包厢仍然保留，赶紧去邀请好友吧", function(is_ok)
                    if is_ok then
                        self:unregisterEventListener()
                        cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "true")
                        cc.UserDefault:getInstance():flush()
                        local scene = require("scene.MainScene")
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
                            cmd =NetCmd.C2S_LEAVE_ROOM,
                            }
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end)
            end
        end
    end)
end

function MJBaseScene:setResultIndex(index, people_num)
    local peopleNum = people_num or RoomInfo.getTotalPeopleNum()
    if peopleNum == 2 then
        if index == 3 then
           index = 2
        end
    elseif peopleNum == 3 then
        if index == 4 then
            index = 3
        end
    end
    return index
end

-- function MJBaseScene:getLastHostID(rtn_msg)
--     local last_host_id = rtn_msg.last_host_id
--     local banker = self.banker
--     if last_host_id then
--         banker = self:indexTrans(rtn_msg.last_host_id)
--     end
--     return banker
-- end

function MJBaseScene:setShareBtn(rtn_msg,node)
    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time())..(self.game_name or "")..self.desk.."房第"..rtn_msg.cur_ju.."局切磋详情:\n"
    for i, v in ipairs(rtn_msg.players) do
        if v.index then
            local userData = PlayerData.getPlayerDataByServerID(v.index)
            if userData then
                copy_str = copy_str.."选手号:"..userData.uid.."  名字:"
                copy_str = copy_str..userData.name.."  成绩:"..v.score.."\n"
            else
                local errStr = string.format("desk = %s mjTypeWanFa = %s log_data_id = %s",tostring(self.desk),tostring(self.mjTypeWanFa),tostring(rtn_msg.log_data_id))
                gt.uploadErr(errStr)
                logUp(errStr)
            end
        end
    end
    commonlib.shareResult(node, copy_str,  g_game_name.."房号:"..self.desk, self.desk,self.copy)
    logUp(copy_str)
end

function MJBaseScene:caculateScore(total)
    if total == 0 then
        for index = 1 , 4 do
            local userData = PlayerData.getPlayerDataByClientID(index)
            if userData and userData.score then
                total = total+tonumber(userData.score)
            end
        end
    end
    return total
end

function MJBaseScene:cancleSelectCard()
    self.MJClickAction.resetCard(self)
    self.MJClickAction.resetClickSelected(self)
end

function MJBaseScene:resetOperBtnTag()
    self.global_btn_tag = self.global_btn_tag or {}
    local btnTable = {'btn-peng','btn-ting','btn-gang','btn-chi','btn-guo','btn-hu'}
    for i = 1, #btnTable do
        self.global_btn_tag[btnTable[i]] = false
    end
end

function MJBaseScene:setOperBtn(operCallback)
    if AUTO_PLAY then
        self.operCallback = operCallback
    end

    self.global_btn_tag = self.global_btn_tag or {}
    local btnTable = {'btn-peng','btn-ting','btn-gang','btn-chi','btn-guo','btn-hu'}

    local function btnCallback(sender, eventType)
        self.cancleSelectCardStatus = true
        self:resetHightCard()
        self:cancleSelectCard()
        if eventType == ccui.TouchEventType.began then
            local szName = sender:getName()
            self.global_btn_tag[szName] = true
        elseif eventType == ccui.TouchEventType.ended then
            local szName = sender:getName()
            for i , v in pairs(self.global_btn_tag) do
                if v and i ~= szName then
                    self.global_btn_tag[szName] = false
                    return
                end
            end
            self.global_btn_tag[szName] = false
            operCallback(sender.opt_type,sender.opt_card)

            self.cancleSelectCardStatus = false
        elseif eventType == ccui.TouchEventType.canceled then
            self.cancleSelectCardStatus = false
            local szName = sender:getName()
            self.global_btn_tag[szName] = false
        end
    end
    local node = self.oper_panel
    for i = 1, #btnTable do
        self.global_btn_tag[btnTable[i]] = false
        local btn = ccui.Helper:seekWidgetByName(node, btnTable[i])
        btn:addTouchEventListener(btnCallback)
    end
end

function MJBaseScene:setBtnSheZhi()
    -- 设置按钮
    local szBtn = tolua.cast(ccui.Helper:seekWidgetByName(self.node,"btn-shezhi"), "ccui.Widget")
    if szBtn then
        szBtn:addTouchEventListener(
            function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    self:btnRoomSetingLayerCallBack()
                end
            end
        )
    end
end

function MJBaseScene:setBtnRedBag()
    -- 红包按钮
    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
    local XQLayer = RedBagXQLayer:create({_scene = self,isMJ = true})
    self:addChild(XQLayer,999)

    --红包按钮延时出现 防止收到消息未处理
    self.btnRedBag = ccui.Helper:seekWidgetByName(self.node,"btn_redbag")
    self.btnRedBag:setVisible(false)
    gt.performWithDelay(self.btnRedBag,function()
        self.btnRedBag:setVisible(RedBagController:getModel():getIsValid())
    end,1.0)
    -- self.btnRedBag:setVisible(RedBagController:getModel():getIsValid())
    self.btnRedBag:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if nil == XQLayer then
                    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
                    local XQLayer = RedBagXQLayer:create({_scene = self,isMJ = true})
                    self:addChild(XQLayer,999)
                end
                XQLayer:setHbVisibale(true)
                XQLayer:reFreshHB()
            end
        end
    )
end

function MJBaseScene:setBtnGps()
    -- GPS按钮
    self.btnGps = ccui.Helper:seekWidgetByName(self.node,"btn-gps")
    self.btnGps:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:checkIpWarn(true)
            end
        end
    )
    self.btnGps:setPositionY(self.wanfa:getPositionY())
end

function MJBaseScene:setBtnFaYan()
    self.btnFaYan = ccui.Helper:seekWidgetByName(self.node, "btn-fayan")
    self.btnFaYan:addTouchEventListener(  function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local RoomMsgLayer = require("scene.RoomMsgLayer")
                self:addChild(RoomMsgLayer.create(self.game_name == "宁乡麻将",function()
                end), 100000)
            end
        end
    )
end

function MJBaseScene:setBtnLiaoTian()
    -- 语音
    self.btnLiaoTian = ccui.Helper:seekWidgetByName(self.node, "btn-liaotian")
    self.btnLiaoTian:addTouchEventListener(function(sender,eventType)
            self.speekNode:touchEvent(sender,eventType)
        end
    )
end

function MJBaseScene:setBtnBQs()
    self.bigbq = tolua.cast(ccui.Helper:seekWidgetByName(self.node,"Panel_3"), "ccui.Widget")
    self.bigbq:setVisible(false)
    local btnWang = ccui.Helper:seekWidgetByName(self.node, "btn_wang")
    self.btnWang = btnWang
    btnWang:addTouchEventListener(  function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.bigbq:setVisible(not self.bigbq:isVisible())
            end
        end
    )
    btnWang:setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)

    local btnXiShou = ccui.Helper:seekWidgetByName(self.bigbq, "btn_xishou")
    btnXiShou:addTouchEventListener(  function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.bigbq:setVisible(false)
                gt.playInteractiveSpine(self,"xishou")
                btnWang:setTouchEnabled(false)
                btnWang:setBright(false)
                self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3),cc.CallFunc:create(function()
                    btnWang:setTouchEnabled(true)
                    btnWang:setBright(true)
                end)))
            end
        end
    )

    local btnShaoXiang = ccui.Helper:seekWidgetByName(self.bigbq, "btn_shaoxiang")
    btnShaoXiang:addTouchEventListener(  function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.bigbq:setVisible(false)
                gt.playInteractiveSpine(self,"shaoxiang")
                btnWang:setTouchEnabled(false)
                btnWang:setBright(false)
                self.bigbq:runAction(cc.Sequence:create(cc.DelayTime:create(3),cc.CallFunc:create(function()
                    btnWang:setTouchEnabled(true)
                    btnWang:setBright(true)
                end)))
            end
        end
    )
end

function MJBaseScene:setBtnJieSanRoom()
    -- 解散房间
    self.jiesanroom = ccui.Helper:seekWidgetByName(self.node, "btn-jiesanroom")
    self.jiesanroom:addTouchEventListener(  function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
            cc.UserDefault:getInstance():flush()

            commonlib.sendJiesan(self.is_game_start, self.is_fangzhu)
        end
    end)
end

function MJBaseScene:setBtnQuickStart()
    -- 立即开始
    self.btnQuick = ccui.Helper:seekWidgetByName(self.node, "btn-kaiju")
    self.btnQuick:addTouchEventListener(  function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            commonlib.sendQuckStart(self.is_game_start, self.is_fangzhu)
        end
    end)

    self.btnQuick:setVisible(RoomInfo.isA4To32 == 1 and RoomInfo.people_total_num ~= 2)

    local people_num = RoomInfo.getCurPeopleNum()
    self:setQuickStartPeople(people_num)
end

function MJBaseScene:setQuickStartPeople(cur,total_num)
    -- 游戏模式人数 2/3模式
    local btnQuickLabel = self.btnQuick:getChildByName('number')
    -- 当前人数/总人数 模式
    local curNUm = cur or 1

    local total = RoomInfo.getTotalPeopleNum()
    local str = nil
    if total == 4 then
        str = string.format("2-3人模式")
    elseif total == 3 then
        str = string.format("2人模式")
    end
    -- str:ignoreContentAdaptWithSize(false)
    -- str:setTextAreaSize(cc.size(400, 250))
    -- logUp('快速开始设置人数 ', tostring(total))

    btnQuickLabel:setString(str)

    if curNUm == 1 then
        self.btnQuick:setTouchEnabled(false)
        self.btnQuick:setBright(false)

        local ImgHightLight = self.btnQuick:getChildByName('ImgHightLight')
        ImgHightLight:setVisible(false)

        local ImgGray = self.btnQuick:getChildByName('ImgGray')
        ImgGray:setVisible(true)
    else
        self.btnQuick:setTouchEnabled(true)
        self.btnQuick:setBright(true)

        local ImgHightLight = self.btnQuick:getChildByName('ImgHightLight')
        ImgHightLight:setVisible(true)

        local ImgGray = self.btnQuick:getChildByName('ImgGray')
        ImgGray:setVisible(false)
    end
end

function MJBaseScene:setBtnCancelTuoGuan()
    -- 托管
    self.panTuoguan = ccui.Helper:seekWidgetByName(self.node, "panTuoguan")
    self.panTuoguan:setLocalZOrder(200)
    self.cancelTuoguan = ccui.Helper:seekWidgetByName(self.node, "cancelTuoguan")
    self.cancelTuoguan:addTouchEventListener(  function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local input_msg = {
                cmd       = NetCmd.C2S_TUOGUAN,
                index     = self.my_index,
                isTuoGuan = false
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)
end

function MJBaseScene:setBtns()
    -- 设置按扭
    self:setBtnSheZhi()
    -- 玩法按钮
    self:setBtnWanFa()
    -- GPS
    self:setBtnGps()
    -- 发言
    self:setBtnFaYan()
    -- 语音
    self:setBtnLiaoTian()
    -- 解散房间
    self:setBtnJieSanRoom()
    -- 返回大厅
    self:setBtnJieSan()
    -- 财神
    self:setBtnBQs()
    -- 立即开始
    self:setBtnQuickStart()
    --红包按钮
    self:setBtnRedBag()
    -- 取消托管按钮
    self:setBtnCancelTuoGuan()
end

function MJBaseScene:setBtnsVisible()
    self:setBtnsReplayVisible()
    self:setIosCheckingVisible()
    self:setBtnGameStartVisible()
    self:setBtnGameWithPeopleNum()
end

function MJBaseScene:setWenHaoListVisible()
    if self.is_game_start then
        local windowSize = cc.Director:getInstance():getWinSize()
        for i,v in ipairs(self.wenhao_list) do
            v:setVisible(false)
        end
    end
end

function MJBaseScene:setGameStartHeadPos()
    if self.is_game_start then
        local count = 0
        for __, v in pairs(PlayerData.IDToUserData) do
            if v.ready then
                count = count + 1
            end
        end

        if count == RoomInfo.people_total_num or self.is_playback then
            self:setHeadPos()
        else
            for __, v in pairs(PlayerData.IDToUserData) do

                local index = PlayerData.getPlayerClientIDByServerID(v.index)
                if v.ready then
                    self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
                end
            end
        end
    end
end

function MJBaseScene:setBtnsReplayVisible()
    if self.is_playback then
        self.btnGps:setVisible(false)
        self.btnFaYan:setVisible(false)
        self.btnWang:setVisible(false)
        self.btnLiaoTian:setVisible(false)
    end
end

function MJBaseScene:setIosCheckingVisible()
    if ios_checking then
        self.btnLiaoTian:setVisible(false)
    end
end

--  游戏开始要变更的按钮
function MJBaseScene:setBtnGameStartVisible()
    if self.is_game_start then
        self.btnQuick:setVisible(false)

        commonlib.showShareBtn(self.share_list)
        self.btnjiesan:setVisible(false)
        self.wanfa:setVisible(true)
        commonlib.showbtn(self.jiesanroom)

        self:setWenHaoListVisible()
    end
end

function MJBaseScene:setBtnGameWithPeopleNum()
    if RoomInfo.people_total_num == 2 then
        self.btnQuick:setVisible(false)
    end
end

function MJBaseScene:setRoomCurPeopleNumByRoomInfo(room_info)
    -- 总人数
    self.people_num = room_info.people_num or 4

    -- 当前人数
    local people_num = 1
    if not room_info then
        return people_num
    end
    if not room_info.other then
        return people_num
    end
    local other = room_info.other
    for i , v in pairs(other) do
        people_num = people_num + 1
    end

    return people_num
end

function MJBaseScene:setRoomCurPeopleNumByTableUserInfo(rtn_msg)
    local people_num = RoomInfo.getCurPeopleNum()
    people_num = people_num + 1
    RoomInfo.updateCurPeopleNum(people_num)
end

function MJBaseScene:setRoomCurPeopleNumByLeaveRoom(rtn_msg)
    local people_num = RoomInfo.getCurPeopleNum()
    people_num = people_num - 1
    RoomInfo.updateCurPeopleNum(people_num)
end

function MJBaseScene:setDirtyHeadDefaultTexture()
    for i, v in pairs(PlayerData.IDToUserData) do
        local uid = v.uid
        local index = v.index
        local new_client_index = PlayerData.getPlayerClientIDByServerID(index)
        local old_client_index = self.OldClientIndex[uid]
        if new_client_index ~= old_client_index then
            print('还原默认头像')
            print('新头像ID ',new_client_index,'原来位置',old_client_index)
            self.player_ui[old_client_index].head_sp:removeFromParent()
            self.player_ui[old_client_index].head_sp = self:stenHead(ccui.Helper:seekWidgetByName(self.player_ui[old_client_index],"Img-touxiang"))
        end
    end
    -- for i , v in ipairs(self.player_ui) do
    --     local userData = PlayerData.getPlayerDataByClientID(i)
    --     if userData and userData.dirty then
    --         local dirty_index = userData.dirty
    --         if self.player_ui[dirty_index] and self.player_ui[dirty_index].head_sp then
    --             -- 还原默认头像
    --             print('还原默认头像')
    --             print('新头像ID ',i,'原来位置',dirty_index)
    --             self.player_ui[dirty_index].head_sp:removeFromParent()
    --             self.player_ui[dirty_index].head_sp = self:stenHead(ccui.Helper:seekWidgetByName(self.player_ui[dirty_index],"Img-touxiang"))
    --         end
    --     end
    -- end
end

function MJBaseScene:updateplayerIndex(rtn_msg)
    self:setDirtyHeadDefaultTexture()
    for i , v in ipairs(self.player_ui) do
        local userData = PlayerData.getPlayerDataByClientID(i)
        -- dump(userData)
        v:setVisible(userData ~= nil)
    end
    for i ,v in pairs(PlayerData.IDToUserData) do
        local uid = v.uid
        local index = v.index
        local new_client_index = PlayerData.getPlayerClientIDByServerID(index)
        local old_client_index = self.OldClientIndex[uid]
        if new_client_index ~= old_client_index then
            self:setSinglePlayerHead(new_client_index)
            self.player_ui[new_client_index]:setPosition(self.player_ui[old_client_index]:getPosition())

            self:addPlayerTouchLister(self.player_ui[new_client_index],new_client_index)
        end
    end
    -- for i , v in ipairs(self.player_ui) do
    --     local userData = PlayerData.getPlayerDataByClientID(i)
    --     -- dump(userData)
    --     v:setVisible(userData ~= nil)
    --     if userData and userData.dirty then
    --         self:setSinglePlayerHead(i)
    --         self.player_ui[i]:setPosition(self.player_ui[userData.dirty]:getPosition())

    --         userData.dirty = nil
    --         self:addPlayerTouchLister(self.player_ui[i],i)
    --     end
    -- end
end

function MJBaseScene:gameStartPeopleChange(rtn_msg)
    PlayerData.updateIndexByGameStart(rtn_msg)

    self.my_index = PlayerData.MyServerIndex
    -- 人数变化重设playerUI
    self:updateplayerIndex(rtn_msg)
end

function MJBaseScene:setNonePeopleChair()
    self.wenhao_list={
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "Panel_4"), "ccui.Widget"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "Panel_5"), "ccui.Widget"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "Panel_6"), "ccui.Widget"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.node, "Panel_7"), "ccui.Widget"),
         }
    if self.people_num ==3 then
        self.wenhao_list[3]:setVisible(false)
    elseif self.people_num == 2 then
        self.wenhao_list[2]:setVisible(false)
        self.wenhao_list[4]:setVisible(false)
    end
end

function MJBaseScene:setPlayerHead()
    self.player_ui = {}

    for play_index = 1, 4 do
        -- 用户面板
        local play = tolua.cast(ccui.Helper:seekWidgetByName(self.node,"play"..play_index), "ccui.ImageView")
        play:setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)
        self.player_ui[play_index] = play

        if play_index == 1 then
            play:setPosition(cc.p(self.wenhao_list[1]:getPosition()))
        elseif play_index ==2 then
            play:setPosition(cc.p(self.wenhao_list[2]:getPosition()))
        elseif play_index ==3 then
            play:setPosition(cc.p(self.wenhao_list[3]:getPosition()))
        elseif play_index ==4 then
            play:setPosition(cc.p(self.wenhao_list[4]:getPosition()))
        end
        -- 头像框
        self.player_ui[play_index].head_sp = self:stenHead(ccui.Helper:seekWidgetByName(play,"Img-touxiang"))--commonlib.stenHead(play)

        play:setVisible(false)
        -- play:getChildByName("Ting"):setVisible(false)
        play:getChildByName("Zhang"):setVisible(false)
        play:getChildByName("lixian"):setVisible(false)
        play:getChildByName("zhunbei"):setVisible(false)
        play:getChildByName("fangzhu"):setVisible(false)

        local paozifen = play:getChildByName("paozifen")
        if paozifen then
            play:getChildByName("paozifen"):setVisible(false)
        end
        -- 点击头像，进入个人头像面板
        self:addPlayerTouchLister(play, play_index)
    end
end

function MJBaseScene:addPlayerTouchLister(play,play_index)
    play:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local userData = PlayerData.getPlayerDataByClientID(play_index)
            if userData then
                local PlayerInfo = require("scene.PlayerInfo")
                self:addChild(PlayerInfo.create(userData, svr_index, play_index==1,self.ignoreArr,self,true), 100000)
            end
        end
    end)
end

function MJBaseScene:initPlayerHead()
    local MyUserData = PlayerData.getPlayerDataByClientID(1)
    if not MyUserData then
        return
    end

    local need_ready = (not MyUserData.hand_card or #MyUserData.hand_card <= 0)

    for index , player_ui_item in ipairs(self.player_ui) do
        local userData = PlayerData.getPlayerDataByClientID(index)
        local v = userData
        -- 服务端座位号转本地座位号
        if userData then
            -- 微信头像地址
            local head = commonlib.wxHead(v.head)
            self.player_ui[index]:setVisible(true)
            -- 昵称
            if pcall(commonlib.GetMaxLenString, v.name, 12) then
                tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name, 12))
            else
                tolua.cast(self.player_ui[index]:getChildByName("Text_2"), "ccui.Text"):setString(v.name)
            end
            -- 分数
            print('初始化设置分数',userData.score)
            tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index],"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.score+1000))
            -- 漂鸟
            if not v.piaoniao or v.piaoniao == 0 then
                self.player_ui[index]:getChildByName("PJN"):setVisible(false)
            else
                tolua.cast(self.player_ui[index]:getChildByName("PJN"), "ccui.ImageView"):loadTexture("ui/qj_mj/"..v.piaoniao..".png")
            end
            -- 离线
            if index ~=1 and v.out_line then
                if type(v.out_line) == "boolean" then
                    v.out_line = 0
                end
                commonlib.lixian(self.player_ui[index], "PJN", v.out_line)
            end
            -- 下载微信头像
            if head ~= "" then
                self.player_ui[index].head_sp:setVisible(true)
                self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
            else
                self.player_ui[index].head_sp:setVisible(false)
            end
            -- 准备手势
            if need_ready and v.ready then
                self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
            end
        end
    end
end

function MJBaseScene:setPlayerReadyVisible()

end

function MJBaseScene:setBtnDeskShare()
    local share_title = self.desk..g_game_name
    commonlib.showShareBtn(self.share_list, (string.gsub(self.wanfa_str, "[.\n]+", ",")), share_title, self.desk, self.copy, function()
        -- 得到当前人数
        local cur_num = RoomInfo.getCurPeopleNum()
        -- 得到总人数
        local total_num = RoomInfo.getTotalPeopleNum()
        local str = string.format("%d缺%d",total_num,total_num - cur_num)
        return str

    end)
end

function MJBaseScene:initVIPResultUI(rtn_msg, jiesan_detail,club_name,log_ju_id,gmId)
    dump(rtn_msg)
    self:removeResultNode()

    local node = tolua.cast(cc.CSLoader:createNode("ui/JiesuanVip.csb"), "ccui.Widget")
    self:addChild(node, 100000)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    local max_score = 0
    local min_score = 0
    for __, v in ipairs(rtn_msg) do
        if v.total_score > max_score then
            max_score = v.total_score
        end
        if v.total_score < min_score then
            min_score = v.total_score
        end
    end

    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()).. self.mjGameName .. "切磋详情:\n"

    table.sort( rtn_msg, function(x,y)
        return x.total_score > y.total_score
    end )

    for i, v in ipairs(rtn_msg) do
        local userData = PlayerData.getPlayerDataByServerID(v.index)
        if userData then
            copy_str = copy_str.."选手号:"..userData.uid.."  名字:"     -- need
            copy_str = copy_str..userData.name.."  成绩:"..v.total_score.."\n"
        else
            gt.uploadErr('mj vipresult peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end
    end

    local params = {log_ju_id = log_ju_id,players = {}}
    for i, v in ipairs(rtn_msg) do
        local userData = PlayerData.getPlayerDataByServerID(v.index)
        if userData then
            params.players[#params.players+1] = {
                nickname = userData.name,
            }
        else
            gt.uploadErr('mj vipresult peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end
    end
    local title = ""

    if not club_name then
        title = "擂台:"..self.desk
    else
        title = "亲友:"..self.desk
    end

    commonlib.shareResult(node, copy_str,  title, self.desk,self.copy,params)

    self:setBtnExit(node)

    if self.is_playback then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分",self.create_time))
    else
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分",os.time()))
    end

    self:setRoomNumber(tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"))

    local index_list = {1,2,3,4}
    table.sort( rtn_msg, function(x,y)
        local xIndex = PlayerData.getPlayerClientIDByServerID(x.index)
        local yIndex = PlayerData.getPlayerClientIDByServerID(y.index)
        if not xIndex then
            gt.uploadErr('mj vipresult peopleNumErroJoinRoomAgain')
        end
        if not yIndex then
            gt.uploadErr('mj vipresult peopleNumErroJoinRoomAgain')
        end
        return xIndex < yIndex  -- need
    end)
    for i, v in ipairs(rtn_msg) do
        local play_index = self:indexTrans(v.index)
        local sortIndex = self:setResultIndex(play_index)
        index_list[sortIndex] = nil
        local play = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")

        local userData = PlayerData.getPlayerDataByClientID(play_index)
        if not userData then
            gt.uploadErr('mj vipresult peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end
        local head = userData and userData.head or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(head), g_wxhead_addr)
        local uid = userData and userData.uid or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-id"), "ccui.Text"):setString(uid)
        local name = userData and userData.name or ''
        if pcall(commonlib.GetMaxLenString, name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-nick"), "ccui.Text"):setString(commonlib.GetMaxLenString(name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-nick"), "ccui.Text"):setString(name)
        end

        ccui.Helper:seekWidgetByName(play, "fangzhu"):setVisible(false)
        if not self.club_name then
            ccui.Helper:seekWidgetByName(play, "fangzhu"):setVisible(v.index==1)
        end

        local total_text = tolua.cast(ccui.Helper:seekWidgetByName(play, "zongfen"), "ccui.Text")
        if total_text then
            total_text:setString(v.total_score)
            total_text:setColor(cc.c3b(0x61, 0x42, 0x28))
        end
        if v.total_score ~= max_score or max_score == 0 then
            ccui.Helper:seekWidgetByName(play, "Win"):setVisible(false)
        end
        if v.total_score <= 0 then
            ccui.Helper:seekWidgetByName(play, "bg"):setVisible(false)
        end
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node,"play"..v):setVisible(false)
        end
    end

    local btn_jiesan = ccui.Helper:seekWidgetByName(node, "btn-jsxq")
    if jiesan_detail then
        btn_jiesan:setVisible(true)
        btn_jiesan:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local JiesanLayer = require("scene.JiesanLayer")
                local jiesan = JiesanLayer:create(jiesan_detail, self.desk, gmId)
                self:addChild(jiesan,100001)
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
end

function MJBaseScene:setEnterRoomIsStartStartHeadPos()
    self:setGameStartHeadPos()
end

function MJBaseScene:onRcvGameInfo()
end

function MJBaseScene:mjUploadError(funcName,server_index,client_index)
    local errStr = string.format("%s si = %s ci = %s pn = %s",
        funcName,tostring(server_index),tostring(client_index),tostring(RoomInfo and RoomInfo.getTotalPeopleNum()))
    errStr = getDebugStr(errStr)
    return errStr
end

function MJBaseScene:mjUploadErrorWithCard(funcName)
    local errStr = string.format("%s",
        funcName
        )
    errStr = getDebugStr(errStr)
    return errStr
end

function MJBaseScene:initResultUIPlayer(player,node,index_list,rtn_msg)
    local v = player

    local play_index = self:indexTrans(v.index)
    local sortIndex = self:setResultIndex(play_index)
    index_list[sortIndex] = nil
    local play = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")

    local userData = PlayerData.getPlayerDataByServerID(v.index)
    if not userData then
        gt.uploadErr('mj result peopleNumErroJoinRoomAgain')
        self:peopleNumErroJoinRoomAgain()
        return
    end

    local pTouXiang = tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView")
    local head = userData and userData.head or ''
    pTouXiang:downloadImg(commonlib.wxHead(head), g_wxhead_addr)

    local name = userData and userData.name or ''
    if pcall(commonlib.GetMaxLenString, name, 14) then
        tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(name, 14))
    else
        tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setString(name)
    end
    if v.index ~= rtn_msg.host_id then
        play:getChildByName("zhuang_icon"):setVisible(false)
    end
    ccui.Helper:seekWidgetByName(play, "paozifen"):setVisible(false)

    local uid = userData and userData.uid or ''
    tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_3"), "ccui.Text"):setString('ID:'..uid)

    if v.score > 0 then
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setString("+"..v.score)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(0xff, 0xd6, 0x59))
    else
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setString(v.score)
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(0x61, 0x42, 0x28))
    end

    if userData then
        userData.score = v.total_score
    end

    local str = nil
    local dh_lbl = tolua.cast(ccui.Helper:seekWidgetByName(play, "dianpao"), "ccui.Text")

    --ccui.Helper:seekWidgetByName(play, "fanshu"):setVisible(false)

    if v.score <= 0 then
        ccui.Helper:seekWidgetByName(play, "shuying"):setVisible(false)
    else
        play:loadTexture("ui/qj_end_one/dt_end_one_ying_item_bg.png")
    end

    if v.is_zimo == 1 or v.is_jiepao == 1 then
        dh_lbl:setColor(cc.c3b(238,238,12))
        tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setColor(cc.c3b(238,238,12))
        tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_3"), "ccui.Text"):setColor(cc.c3b(238,238,12))
       -- tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(238,238,12))
    end

    if play_index == 1 then
        if v.is_zimo == 1 or v.is_jiepao == 1 then
            AudioManager:playDWCSound("sound/mj/win.mp3")
        else
            AudioManager:playDWCSound("sound/mj/lose.mp3")
        end
    end
end

function MJBaseScene:initResultAnQuanMa(node,rtn_msg)
    if self.is_playback then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "huifangma"), "ccui.Text"):setString("安全码:"..self.log_data_id)
    else
        if not rtn_msg.log_data_id then
            local errStr = self:mjUploadErrorWithCard('initResultAnQuanMa log_data_id nil ' .. tostring(self.mjTypeWanFa)) -- need
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
        end
        tolua.cast(ccui.Helper:seekWidgetByName(node, "huifangma"), "ccui.Text"):setString("安全码:".. (rtn_msg.log_data_id or ''))
    end
end

function MJBaseScene:initResultTime(node,rtn_msg)
    if self.is_playback then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分",self.create_time))
    else
        tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-shijian"), "ccui.Text"):setString(os.date("%m月%d日 %H时%M分",os.time()))
    end
end

function MJBaseScene:initResultRoomID(node,rtn_msg)
    if not rtn_msg.club_name then
        tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString("房间号:"..self.desk)
    else
        if pcall(commonlib.GetMaxLenString, rtn_msg.club_name, 12) then
            tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString(commonlib.GetMaxLenString(rtn_msg.club_name, 12) .. "的亲友圈")
        else
            tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString(rtn_msg.club_name .. "的亲友圈")
        end
        if self.club_index then
            if pcall(commonlib.GetMaxLenString, rtn_msg.club_name, 12) then
                tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString(commonlib.GetMaxLenString(rtn_msg.club_name, 12) .. "亲友圈" .. self.club_index ..'号')
            else
                tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"):setString(rtn_msg.club_name .. "亲友圈" .. self.club_index ..'号')
            end
        end
    end
end

function MJBaseScene:initResultWangFa(node)
    tolua.cast(ccui.Helper:seekWidgetByName(node, "wanfa"), "ccui.Text"):setString((string.gsub(self.wanfa_str, "[.\n]+", " ")))
end

-- 0 出牌 听牌出牌
-- 1 吃
-- 2 碰
-- 10 暗杠
-- 11 明杠
function MJBaseScene:playOpenCardAnimation(direct,opt_type)
    local pos = cc.p(self.open_card_ani_pos_list[direct].x, self.open_card_ani_pos_list[direct].y)
    local ani_type = opt_type
    if opt_type == 10 or opt_type == 11 then
        ani_type = 3
        check_ac = true
    elseif opt_type == 12 or opt_type == 13 or opt_type == 14 then
        ani_type = 3
    end
    -- -- 吃 -- 碰 -- 杠
    if ani_type >=1 and ani_type <= 7 then
        if ani_type ~= 1 then
            AudioManager:playDWCSound("sound/mj/mj_op.mp3")
        end
        local fileJson = "ui/qj_mj/majiangshandiandonghua/datangmajiangtexiaozidonghua.ExportJson"
        local aniName  = '01texiaodonghuapengdonghua'
        if ani_type == 1 then
            aniName = '02texiaodonghuachidonghua'
        elseif ani_type == 3 then
            aniName = '03texiaodonghuagengdonghua'
        end
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(fileJson)
        local armature = ccs.Armature:create('datangmajiangtexiaozidonghua')
        local function animationEvent(armatureBack,movementType,movementID)
            if movementType == 1 then
                armature:removeFromParent(true)
            end
        end
        armature:getAnimation():setMovementEventCallFunc(animationEvent)
        armature:getAnimation():play(aniName,0,0)
        armature:setPosition(pos)
        armature:setLocalZOrder(self.ZOrder.DIAN_PAO_ZOREDER or 99)
        self:addChild(armature)
    end
end

-- 0 出牌 听牌出牌
-- 1 吃
-- 2 碰
-- 10 暗杠
-- 11 明杠
function MJBaseScene:playOpenCardSound(direct,opt_type)
    local ani_type = opt_type
    if opt_type == 10 or opt_type == 11 then
        ani_type = 3
        check_ac = true
    elseif opt_type == 12 or opt_type == 13 or opt_type == 14 then
        ani_type = 3
    end
    local prefix = self:getSoundPrefix(direct)
    if ani_type == 1 then
        AudioManager:playDWCSound("sound/"..prefix.."/chi.mp3")
    elseif ani_type == 2 then
        AudioManager:playDWCSound("sound/"..prefix.."/peng.mp3")
    elseif ani_type == 3 then
        AudioManager:playDWCSound("sound/"..prefix.."/gang.mp3")
    elseif ani_type == 4 then
        AudioManager:playDWCSound("sound/"..prefix.."/ting.mp3")
    elseif ani_type == 5 then
        AudioManager:playDWCSound("sound/"..prefix.."/hu.mp3")
    end
end


function MJBaseScene:setOpt(opt_btn, is_quan, is_on, font_yanse, name)
    if not is_on then
        tolua.cast(opt_btn:getChildByName("xuan"), "ccui.ImageView"):loadTexture("ui/qj_createroom/cj_0001_quan-fs8.png")
    else
        tolua.cast(opt_btn:getChildByName("xuan"), "ccui.ImageView"):loadTexture("ui/qj_createroom/cj_0000_gou-fs8.png")
    end
    if is_on then
        opt_btn:setTitleColor(cc.c3b(144, 3, 3))
    else
        opt_btn:setTitleColor(cc.c3b(91, 51, 0))
    end
end

return MJBaseScene