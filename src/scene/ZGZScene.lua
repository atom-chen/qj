-- 0x01,0x02,0x03,0x04,0x05,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,   -- 方块 A - K
-- --17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
-- 0x11,0x12,0x13,0x14,0x15,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,   -- 梅花 A - K
-- --33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,
-- 0x21,0x22,0x23,0x24,0x25,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,   -- 红桃 A - K
-- --49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,
-- 0x31,0x32,0x33,0x34,0x35,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,   -- 黑桃 A - K
-- 0x4E,0x4F,

local ErrStrToClient = require('common.ErrStrToClient')

local ErrNo = require('common.ErrNo')

RecordGameType = require('scene.RecordGameType')

require('scene.RoomInfo')

require('scene.PlayerData')

PKCommond = require('scene.PKCommond')

-- 认输
local SERVER_Surrender = 1
-- 亮2
local SERVER_Show3     = 2
-- 扎股
local SERVER_ZhaGu     = 3
-- 没话
local SERVER_Silence   = 4

local DIAMOND3 = 0x03
local CLUB3    = 0x13
local HEART3   = 0x23
local SPADE3   = 0x33

local ThreeTeam   = 1
local GuTeam      = 2
local UnknownTeam = 3
local player_tag_texture_path = {
    [ThreeTeam]   = 'ui/qj_zgz/player_3.png',
    [GuTeam]      = 'ui/qj_zgz/player_gu.png',
    [UnknownTeam] = 'ui/qj_zgz/player_unknow.png',
}

local STATUS_FREE   = 0     --等待开始
local STATUS_CALL   = 100   --说话状态 亮三 扎股 没话
local STATUS_PLAY   = 101   --游戏状态
local STATUS_RESULT = 102   --结算
local STATUS_JIABEI = 103   --加倍

local ZGZLogic = require('logic.pkzgz_logic')

local ZGZScene = class("ZGZScene",function()
    return cc.Layer:create()
end)

function ZGZScene:registerNetCmd()
    local NETMSG_LISTENERS = {
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvMsg),
        [NetCmd.S2C_DDZ_TABLE_USER_INFO] = handler(self, self.onRcvMsg), -- S2C_TABLE_USER_INFO
        [NetCmd.S2C_ZGZ_GAME_START]      = handler(self, self.onRcvMsg),
        [NetCmd.S2C_ZGZ_SHUO_HUA]        = handler(self, self.onRcvMsg),
        [NetCmd.S2C_READY]               = handler(self, self.onRcvMsg),
        [NetCmd.S2C_DDZ_OUT_CARD]        = handler(self, self.onRcvMsg), -- OUT_card
        [NetCmd.S2C_PASS  ]              = handler(self, self.onRcvMsg),
        [NetCmd.S2C_DDZ_RESULT]          = handler(self, self.onRcvMsg),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvMsg),
        [NetCmd.S2C_APPLY_JIESAN]        = handler(self, self.onRcvMsg),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]  = handler(self, self.onRcvMsg),
        [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvMsg),
        [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvMsg),
        [NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN] = handler(self, self.onRcvMsg),
        [NetCmd.S2C_LEAVE_ROOM]          = handler(self, self.onRcvMsg),
        [NetCmd.S2C_IN_LINE]             = handler(self, self.onRcvMsg),
        [NetCmd.S2C_OUT_LINE]            = handler(self, self.onRcvMsg),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvMsg),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_MODIFY]         = handler(self, self.onRcvMsg),
        [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvMsg),
        [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvMsg),
        [NetCmd.S2C_LOGIN_OTHER]         = handler(self, self.onRcvMsg),
    }
    for k, v in pairs(NETMSG_LISTENERS) do
        gt.addNetMsgListener(k, v)
    end
    local CUSTOM_LISTENERS = {
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function ZGZScene:onRcvMsg(rtn_msg)
    local NETMSG_LISTENERS = {
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_DDZ_TABLE_USER_INFO] = handler(self, self.onRcvTableUserInfo),
        [NetCmd.S2C_ZGZ_GAME_START]      = handler(self, self.onRcvGameStart),
        [NetCmd.S2C_ZGZ_SHUO_HUA]        = handler(self, self.onRcvShuoHua),
        [NetCmd.S2C_READY]               = handler(self, self.onRcvReady),
        [NetCmd.S2C_DDZ_OUT_CARD]        = handler(self, self.onRcvOutCard), -- OUT_card
        [NetCmd.S2C_PASS  ]              = handler(self, self.onRcvPass),
        [NetCmd.S2C_DDZ_RESULT]          = handler(self, self.onRcvReault),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_APPLY_JIESAN]        = handler(self, self.onRcvApplyJieSan),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]  = handler(self, self.onRcvApplyJieSanAgree),
        [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvRoomChat),
        [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvRoomChatBQ),
        [NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN] = handler(self, self.onRcvZgzJoinRoomAgain),
        [NetCmd.S2C_LEAVE_ROOM]          = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_IN_LINE]             = handler(self, self.onRcvInLine),
        [NetCmd.S2C_OUT_LINE]            = handler(self, self.onRcvOutLine),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSyncUserData),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_MODIFY]         = handler(self, self.onRcvClubModify),
        [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvApplyStart),
        [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvApplyStartAgree),
    }
    if NETMSG_LISTENERS[rtn_msg.cmd] then
        if rtn_msg.errno and rtn_msg.errno ~= 0 then
            commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or 'Unknown Error ' .. rtn_msg.errno)
            if ErrNo.APPLY_JIESAN_TIME == rtn_msg.errno or ErrNo.APPLY_JIESAN_STATUS == rtn_msg.errno then
                commonlib.closeJiesan(self)
            end
        else
            NETMSG_LISTENERS[rtn_msg.cmd](rtn_msg)
        end
    end
end

function ZGZScene:unregisterNetCmd()
    local LISTENER_NAMES = {
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_DDZ_TABLE_USER_INFO] = handler(self, self.onRcvTableUserInfo),
        [NetCmd.S2C_ZGZ_GAME_START]      = handler(self, self.onRcvGameStart),
        [NetCmd.S2C_ZGZ_SHUO_HUA]        = handler(self, self.onRcvShuoHua),
        [NetCmd.S2C_READY]               = handler(self, self.onRcvReady),
        [NetCmd.S2C_DDZ_OUT_CARD]        = handler(self, self.onRcvOutCard), -- OUT_card
        [NetCmd.S2C_DDZ_RESULT]          = handler(self, self.onRcvReault),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_APPLY_JIESAN]        = handler(self, self.onRcvApplyJieSan),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]  = handler(self, self.onRcvApplyJieSanAgree),
        [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvRoomChat),
        [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvRoomChatBQ),
        [NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN] = handler(self, self.onRcvZgzJoinRoomAgain),
        [NetCmd.S2C_LEAVE_ROOM]          = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_IN_LINE]             = handler(self, self.onRcvInLine),
        [NetCmd.S2C_OUT_LINE]            = handler(self, self.onRcvOutLine),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSyncUserData),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_MODIFY]         = handler(self, self.onRcvClubModify),
        [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvApplyStart),
        [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvApplyStartAgree),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end


function ZGZScene:createLayerMenu(room_info)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end
    self.people_num = room_info.people_num or 5
    -- 玩家的方位
    self.direct_list = {1, 2, 3, 4, 5, 6}

    if self.people_num == 5 then
        self.direct_list = {1, 2, 4, 5, 6}
    end
    self.copy = (room_info.copy == 1)

    self:setOwnerName(room_info)

    local starttime = os.clock()
    local node
    if self.isStyle2 then
        node = tolua.cast(cc.CSLoader:createNode("ui/zgzroom_new.csb"), "ccui.Widget")
    else
        node = tolua.cast(cc.CSLoader:createNode("ui/zgzroom.csb"), "ccui.Widget")
    end
    if self.isRetroCard then
        PKCommond.handMarginX = 70
        PKCommond.outMarginX  = 43
    else
        PKCommond.handMarginX = 55
        PKCommond.outMarginX  = 30
    end
    self:addChild(node)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node

    if self.isStyle2 then
        player_tag_texture_path = {
            [ThreeTeam]   = 'ui/qj_zgz/player_32.png',
            [GuTeam]      = 'ui/qj_zgz/player_gu2.png',
            [UnknownTeam] = 'ui/qj_zgz/player_unknow2.png',
        }
        self.imgBottomBg = ccui.Helper:seekWidgetByName(node, "ImgMybg")
        self.FntBeiShu   = ccui.Helper:seekWidgetByName(self.imgBottomBg, 'fnt_beilv')
        self.FntBeiShu:setString(0)
    else
        player_tag_texture_path = {
            [ThreeTeam]   = 'ui/qj_zgz/player_3.png',
            [GuTeam]      = 'ui/qj_zgz/player_gu.png',
            [UnknownTeam] = 'ui/qj_zgz/player_unknow.png',
        }
    end

    self.batteryProgress = ccui.Helper:seekWidgetByName(node, "battery")
    gt.refreshBattery(self.batteryProgress)
    self.signalImg = ccui.Helper:seekWidgetByName(node, "img_xinhao")

    PKCommond.setZhuoBu(ccui.Helper:seekWidgetByName(node, "Image_2"))

    local panel = ccui.Helper:seekWidgetByName(node, "Panel_2")
    panel:setLocalZOrder(self.ZOrder.PLAYER_ZOREDER)

    self:setNonePeopleChair()

    self:setPlayerHead()

    self:setSysTime()

    self:setRoomData()

    if room_info.result_packet then
        room_info.cur_ju = room_info.result_packet.cur_ju or room_info.cur_ju or 1
    else
        room_info.cur_ju = room_info.cur_ju or 1
    end

    self.hand_card_list    = {}
    self.hand_card_list[1] = {}
    self.hand_card_list[2] = {}
    self.hand_card_list[3] = {}
    self.hand_card_list[4] = {}
    self.hand_card_list[5] = {}
    self.hand_card_list[6] = {}

    self.paiShape = cc.UserDefault:getInstance():getStringForKey("pai_change", "normal")

    -- 局数
    self.TextJuShu   = tolua.cast(ccui.Helper:seekWidgetByName(node, "TextJuShu"), "ccui.Text")
    self.total_ju    = room_info.total_ju
    self.NodePlayer1 = self:seekNode("NodePlayer1")
    self:setTextJuShu(self.total_ju, room_info.cur_ju)

    self.is_game_start = (room_info.status~=0 or room_info.cur_ju ~= 1)
    self.is_fangzhu    = (room_info.qunzhu ~= 1 and self.my_index == 1)
    self.zhuo_hong_san = room_info.zhuo_hong_san or false
    self.sheng_pai     =room_info.sheng_pai or false
    self.isHSPR        = room_info.isHSPR
    self.isBLFKS       = room_info.isBLFKS or false
    self.isZHYGBD      = room_info.isZHYGBD or false

    self.share_list = {
                        -- 微信邀请
                        ccui.Helper:seekWidgetByName(node, "WxShare"),
                        -- 复制房号
                        ccui.Helper:seekWidgetByName(node, "btn-copyroom"),
                        ccui.Helper:seekWidgetByName(node, "DdShare"),
                        ccui.Helper:seekWidgetByName(node, "YxShare"),
                      }

    ccui.Helper:seekWidgetByName(node, "btn-copyroom"):setPositionY(ccui.Helper:seekWidgetByName(node, "WxShare"):getPositionY())
    self.NodePlayer1:getChildByName("tWait"):setVisible(false)
    -- 庄家
    self.banker    = self:indexTrans(room_info.host_id)
    self.wanfa_str = self:getWanFaStr()
    self:setShuoMing(self.wanfa_str)
    self:InitBtns()

    self:setAllImgReadyVisible(false)
    self:setAllFntScoreVisible(true)
    self:setAllImgLastCardVisible(false)

    self:initPlayerHead()

	self:resetStatus()

    if self.sheng_pai then
        self:setAllFntLastCardNumVisible(true)
    else
        self:setAllFntLastCardNumVisible(false)
    end
    self:setAllImgMhVisible(false)
    self:setAllImgZgVisible(false)
    self:setAllImgBuChuVisible(false)

    self.TextBeiShu = ccui.Helper:seekWidgetByName(self.node, 'TextBeiShu')
    self.TextBeiShu:setString('倍数：0')

    if self.isStyle2 then
        self.TextBeiShu:setVisible(false)
    end

    self.Biao = tolua.cast(cc.CSLoader:createNode("ui/Biao.csb"), "ccui.Widget")
    ccui.Helper:seekWidgetByName(self.Biao, "biao"):setPosition(0,0)
    self.node:addChild(self.Biao, self.ZOrder.BIAO)
    self.Biao:setVisible(false)
    self.Biao.lab = tolua.cast(ccui.Helper:seekWidgetByName(self.Biao, "Text_1"), "ccui.Text")
    self.Biao.lab:setString("")

    self:InitNodeTimes()

    self:InitOutCardPos()

    self:registerCardTouch()

    -- 上家出的牌
    self.last_out_card = {0, 0, 0, 0, 0, 0}

    -- 亮三出来的牌
    self.show_liangsan = {0, 0, 0, 0, 0, 0}
    if self.paiShape == "normal" then
        self.paiChange:loadTextureNormal("ui/qj_zgz/ping-pk.png")
    else
        self.paiChange:loadTextureNormal("ui/qj_zgz/hu-pk.png")
    end
    if room_info.player_info and (room_info.player_info.hand) then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:treatResume(room_info)
        end
    end

    if self.is_playback then
        self:treatPlayback(room_info)
    end
    --游戏开始开心跳
    if self.is_game_start then
        if not self.is_playback then
            ymkj.setHeartInter(0)
        end
    end

    -- GPS
    if (not room_info.player_info or not room_info.player_info.ready) and (not room_info.result_packet) and (not self.is_playback) then
        self:checkIpWarn()
    end

    self.qunzhu = room_info.qunzhu
    self:setClubInvite()

    self:setBtnsVisible()
end


function ZGZScene.removeUnusedRes()
    if GameGlobal.MjSceneReplaceMJScene then
        return
    end
    gt.removeUnusedRes()
end

function ZGZScene.create(param_list)

    ZGZScene.removeUnusedRes()

    local mj    = ZGZScene.new(param_list)
    local scene = cc.Scene:create()
    scene:addChild(mj)

    return scene
end

function ZGZScene:ctor(param_list)

    self.ZOrder                     = {}
    self.ZOrder.BEYOND_CARD_ZOREDER = 200
    self.ZOrder.PLAYER_ZOREDER      = 1000
    self.ZOrder.BIAO                = 1001
    self.ZOrder.WANGFA_ZOREDER      = 1002
    self.my_index                   = param_list.room_info.index
    self.desk                       = param_list.room_id
    self.club_id                    = param_list.club_id
    self.is_ningxiang               = param_list.room_info.is_ningxiang
    --屏蔽互动表情的方位
    self.ignoreArr = {}

    if param_list.is_playback then
        self.is_playback = param_list.is_playback
        self.order_list  = param_list.order
        self.log_data_id = param_list.log_data_id
        self.create_time = param_list.create_time
    end

    self.drawCardActionTime = 0.1

    local pingmian  = gt.getLocal("int","pingmian", 2)
    self.zhuobu     = gt.getLocal("int", "zhuobu", 1)
    self.club_id    = param_list.room_info.club_id
    self.room_id    = param_list.room_id
    gt.setRoomID(self.room_id)
    self.club_name  = param_list.room_info.club_name
    self.room_info  = param_list.room_info
    self.club_index = param_list.room_info.club_index
    self.isJZBQ     = param_list.room_info.isJZBQ
    self.isStyle2   = param_list.room_info.isJDFG or false

    RoomInfo.setRoomInfo(param_list.room_info)

    -- 牌的类型 1 为经典模式， 2 为复古模式
    local cardType = gt.getLocalString("cardType", "classic")
    if cardType == "retro" then
        self.isRetroCard = true
    end
    if self.club_id and self.club_name and self.club_index then
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = self.club_id
        gt.setRoomID(self.club_id)
    end
    self:setClubEnterMsg()

    local people_num = self:setRoomCurPeopleNumByRoomInfo(param_list.room_info)
    RoomInfo.updateCurPeopleNum(people_num)

    self.people_num = param_list.room_info.people_num or 5
    RoomInfo.updateTotalPeopleNum(self.people_num)

    local function server_index_to_client_index(server_index)
       -- log('转换位置')
        if server_index == PlayerData.MyServerIndex then
            return 1
        end
        if self.people_num == 5 then
            if self.isStyle2 then
                if PlayerData.MyServerIndex == 1 then
                    if server_index == 2 or server_index == 3 then
                        return server_index
                    else
                        return server_index + 1
                    end
                elseif PlayerData.MyServerIndex == 2 then

                    if server_index == 1 then
                        return 6
                    elseif server_index == 3 or server_index == 4 then
                        return server_index - 1
                    else
                        return server_index
                    end
                elseif PlayerData.MyServerIndex == 3 then
                    if server_index == 1 then
                        return 5
                    elseif server_index == 2 then
                        return 6
                    elseif server_index == 4 then
                        return 2
                    elseif server_index == 5 then
                        return 3
                    end
                elseif PlayerData.MyServerIndex == 4 then
                    if server_index == 1 then
                        return 3
                    elseif server_index == 2 then
                        return 5
                    elseif server_index == 3 then
                        return 6
                    elseif server_index == 5 then
                        return 2
                    end
                else
                    if server_index == 1 then
                        return 2
                    elseif server_index == 2 then
                        return 3
                    elseif server_index == 3 then
                        return 5
                    elseif server_index == 4 then
                        return 6
                    end
                end
            else
                if PlayerData.MyServerIndex == 1 then
                    if server_index == 2 then
                        return 2
                    else
                        return server_index +1
                    end
                elseif PlayerData.MyServerIndex == 2 then
                    if server_index == 1 then
                        return 6
                    elseif server_index == 3 then
                        return 2
                    else
                        return server_index
                    end
                elseif PlayerData.MyServerIndex == 3 then
                    if server_index == 1 then
                        return 5
                    elseif server_index == 2 then
                        return 6
                    elseif server_index == 4 then
                        return 2
                    elseif server_index == 5 then
                        return 4
                    end
                elseif PlayerData.MyServerIndex == 4 then
                    if server_index == 1 then
                        return 4
                    elseif server_index == 2 then
                        return 5
                    elseif server_index == 3 then
                        return 6
                    elseif server_index == 5 then
                        return 2
                    end
                else
                    if server_index == 1 then
                        return 2
                    elseif server_index == 2 then
                        return 4
                    elseif server_index == 3 then
                        return 5
                    elseif server_index == 4 then
                        return 6
                    end
                end
            end
        else
            if server_index > PlayerData.MyServerIndex then
                return server_index - PlayerData.MyServerIndex + 1
            end
            if server_index < PlayerData.MyServerIndex then
                return server_index - PlayerData.MyServerIndex + self.people_num + 1
            end
        end
        --log('转换位置')
    end
    PlayerData.setServerIDToClientIDDelegate(server_index_to_client_index)

    -- 自己信息
    local playerinfo_list = {param_list.room_info.player_info}
    -- 其它玩家信息
    for i, v in ipairs(param_list.room_info.other) do
        playerinfo_list[i+1] = v
    end

    PlayerData.updatePlayerInfo(playerinfo_list,param_list.room_info)

    --self:initHeadPos()

    self:createLayerMenu(param_list.room_info)

    AudioManager:stopPubBgMusic()
    AudioManager:playDWCBgMusic("sound/bgGame.mp3")

    --注册网络消息
    self:registerEventListener()
    self:enableNodeEvents()
end

function ZGZScene:setGameStartBtnStatus()
    if self.is_game_start then
        -- 邀请好友
        ccui.Helper:seekWidgetByName(self.node,"WxShare"):setVisible(false)
        -- 解散房间
        ccui.Helper:seekWidgetByName(self.node,"btn-jiesanroom"):setVisible(false)
        -- 复制房间
        ccui.Helper:seekWidgetByName(self.node,"btn-copyroom"):setVisible(false)
    end
end

function ZGZScene:onEnter()
    gt.refreshSignal(self.signalImg)
    gt.listenBatterySignal()
    gt.updateBatterySignal(self)

    gt.removeUnusedRes()

    local SpeekNode = require("scene.SpeekNode")
    self.speekNode  = SpeekNode:create(self)
    self:addChild(self.speekNode,999)

    GameGlobal.MjSceneReplaceMJScene = nil
    --红包消息分发注册 EventBus
    self:registerEvent()
end

function ZGZScene:registerEvent()
    local events = {
        {
            eType = EventEnum.S2C_RB_INFO,
            func  = handler(self,self.onRbIsValid),
        },
    }
    for i, v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function ZGZScene:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function ZGZScene:onRbIsValid(rtn_msg)
    --应急处理，防止未收到20002消息 没有显示红包按钮
    if rtn_msg and nil ~= next(rtn_msg) then
        self.btnRedBag:setVisible(true)
    end
end

function ZGZScene:clearTextureCache()
    if GameGlobal.MjSceneReplaceMJScene then
        return
    end
    local plistTable = {
    }

    for i, v in ipairs(plistTable) do
        cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(v)
    end

    ZGZScene.removeUnusedRes()
end

function ZGZScene:onExit()
    self:disableNodeEvents()
    self:clearTextureCache()
    --红包消息分发注销 EventBus
    self:unregisterEvent()

    gt.setRoomID(nil)
end

function ZGZScene:keypadEvent()
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

function ZGZScene:registerEventListener()
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
            PKCommond.Bezier = {}
            local scene      = require("scene.MainScene")
            local gameScene  = scene.create()
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
            pb_node.add_btn:loadTextureNormal("ui/qj_replay/speed" .. pb_node.play_speed..".png")
            pb_node.add_btn:loadTexturePressed("ui/qj_replay/speed" .. pb_node.play_speed..".png")
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

function ZGZScene:save_new_record(rtn_msg)
    local Record = require('scene.Record')
    Record.mj_save_new_record(self,rtn_msg, RecordGameType.ZGZ)
end

function ZGZScene:unregisterEventListener()
    self:unregisterNetCmd()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    ymkj.setHeartInter(0)
end

function ZGZScene:sendReady(score)
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
        local input_msg = {
            cmd   = NetCmd.C2S_READY,
            paozi = score,
            index = self.my_index,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
end

function ZGZScene:firstTurnAnimation(rtn_msg)
    -- 第一局设置
    if rtn_msg.cur_ju == 1 then
        self:playhuSpine(self, 'kaiju','animation')
        AudioManager:playDWCSound("sound/mj/mj_start.mp3")
    end
end


function ZGZScene:treatPlayback(rtn_msg)
    if self.is_game_start then
        self:setAllImgReadyVisible(false)
        self:setAllImgLastCardVisible(true)
    end

    self:setAllImgLiangCardTagVisible(true)
    self:setAllImg3Visible(false)
    self:setAllImgGroupVisible(true)
    for client_index = 1, 6 do
        self:setImgGroupTexture(client_index,player_tag_texture_path[UnknownTeam])
    end
    self:resetOperPanel()
    local hand = rtn_msg.player_info.cards

    ZGZLogic:sortDESC(hand)
    self:setPlayerHandCard(hand, 1)

end

function ZGZScene:treatResumeSaveRecord(rtn_msg)
    self:save_new_record(rtn_msg,RecordGameType.ZGZ)
end

function ZGZScene:printHandCardListPos(index)
    if 1 then
        return
    end
    if index then
        local posX,posY = self.hand_card_list[1][index]:getPosition()
        print(index, posX, posY)
        return
    end
    for index , v in ipairs(self.hand_card_list[1]) do
        local posX,posY = v:getPosition()
        print(index, posX, posY)
    end
end

function ZGZScene:treatResumeSetHandCard(rtn_msg)
    if self.is_game_start then
        self:setAllImgReadyVisible(false)
        self:setAllImgLastCardVisible(true)
    end
    local userData = PlayerData.getPlayerDataByClientID(1)
    local hand     = userData.hand
    ZGZLogic:sortDESC(hand)
    self:setPlayerHandCard(hand,1)
end

function ZGZScene:treatResumeCall(rtn_msg)
    self:treatResumeSetHandCard(rtn_msg)
    if rtn_msg.cur_id == PlayerData.MyServerIndex then
        self.NodePlayer1:getChildByName("tWait"):setVisible(false)
        local hand = self:getSelfHandCard()
        if self.zhuo_hong_san then
            if not self:hasHeart3(hand) and not self:hasDiamond3(hand) then
            -- 没有红三 默认发送没话
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self:btnSilenceCallBack()
                end)))
            elseif self:hasDiamond3(hand) and not self:hasHeart3(hand) then
            -- 只有方三 默认发送亮方三
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self.selectedCard           = self.selectedCard or {}
                    self.selectedCard[DIAMOND3] = true
                    self:btnShow3CallBack()
                end)))
            else
                self:setShuoHuaBtn(hand)
            end
        else
            self:setShuoHuaBtn(hand)
        end
    else
        self.NodePlayer1:getChildByName("tWait"):setVisible(true)
    end
end

function ZGZScene:treatResumePlay(rtn_msg)
    self:treatResumeSetHandCard(rtn_msg)
    local last_id                   = rtn_msg.last_id
    local cur_id                    = rtn_msg.cur_id
    local next_index                = PlayerData.getPlayerClientIDByServerID(cur_id)
    local last_out_card             = rtn_msg.last_out_card
    self.last_out_card_client_index = PlayerData.getPlayerClientIDByServerID(last_id)

    if last_id and last_out_card and last_id ~= cur_id then
        local last_client_index = PlayerData.getPlayerClientIDByServerID(last_id)
        self:setOutCardToDesk(last_client_index, last_out_card)
    end
    -- @ 0:玩家未表面身份
    -- @ 1:玩家为股家
    -- @ 2:玩家通过亮三或者出红色三确定的三家身份
    -- @ 3:未选择黑三骗人,且本局未亮过三,通过出黑三未出红三确定的三家
    if rtn_msg.all_gu_jia and #rtn_msg.all_gu_jia > 0 then
        for i, v in ipairs(rtn_msg.all_gu_jia) do
            local client_index = PlayerData.getPlayerClientIDByServerID(i)
            if v == 0 then
                self:setImgGroupVisible(client_index, true)
                self:setImgGroupTexture(client_index, player_tag_texture_path[UnknownTeam])
            elseif v == 1 then
                self:setImgGroupVisible(client_index, true)
                self:setImgGroupTexture(client_index, player_tag_texture_path[GuTeam])
            elseif v == 2 or v == 3 then
                self:setImgGroupVisible(client_index, true)
                self.sanjia_num[#self.sanjia_num + 1]= client_index
                self:setImgGroupTexture(client_index, player_tag_texture_path[ThreeTeam])
            end
        end
        if #self.sanjia == 0 then
            for i,v in ipairs(rtn_msg.all_gu_jia) do
                local client_index = PlayerData.getPlayerClientIDByServerID(i)
                if v == 2 then
                    self.sanjia[#self.sanjia +1] = {index = client_index, card = -1}
                end
            end
        end
    end

    if cur_id == PlayerData.MyServerIndex then
        log('重连可以出牌了')
        self.can_opt = true
    end
    if next_index == 1 then
        local ht5 = nil
        local num = 10
        if self.people_num == 6 then
            num = 9
        end

        if rtn_msg.player_info.hand and #rtn_msg.player_info.hand >= num then
            local target = 37
            for __, v in ipairs(rtn_msg.player_info.hand) do
                if v == target then
                    ht5 = v
                    break
                end
            end
            self.target = target
        end
        if ht5 then
            self.mustChuWu = true
        end
        if next_index ~= self.last_out_card_client_index then
            self:updateHintList()
            self:resetOperPanel(101)
        else
            self:resetOperPanel(100)
        end
    end
    -- 需要清除上家打的除

    -- 需要知道自己是不是最后一手牌，其它不要，再到自己时，不需要提示
end

function ZGZScene:treatResume(rtn_msg)
    self:setWenHaoListVisible()
    self:setAllImgLiangCardTagVisible(true)
    self:setAllImg3Visible(false)

    self:setAllImgGroupVisible(true)
    for client_index = 1, 6 do
        self:setImgGroupTexture(client_index, player_tag_texture_path[UnknownTeam])
    end
        if self.is_game_start then
        if self:hasHeart3(rtn_msg.player_info.hand) or self:hasDiamond3(rtn_msg.player_info.hand) then
            self:setImgGroupTexture(1, player_tag_texture_path[ThreeTeam])
        else
            self:setImgGroupTexture(1, player_tag_texture_path[GuTeam])
        end
    end

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i + 1] = v
    end

    if self.sheng_pai then
        self:setFntLastCardNum(1, #rtn_msg.player_info.hand)
        for i =1, 5 do
            if rtn_msg.other[i] then
                local client_index = PlayerData.getPlayerClientIDByServerID(rtn_msg.other[i].index)
                self:setFntLastCardNum(client_index, rtn_msg.other[i].left_num)
            end
        end
    end

    for i =1, 5 do
        if rtn_msg.other[i] and rtn_msg.other[i].left_num and rtn_msg.other[i].left_num <=2 then
            local client_index = PlayerData.getPlayerClientIDByServerID(rtn_msg.other[i].index)
            ccui.Helper:seekWidgetByName(self.player_ui[client_index], "FntLastCardNum"):setVisible(true)
            self:setFntLastCardNum(client_index, rtn_msg.other[i].left_num)
        end
    end
    local bei_shu = rtn_msg.bei_shu
    self:setBeiShu(bei_shu)
    self.lastSpeekPeople = self:getLastSpeekIndex(rtn_msg.tou_you)

    local shuo_hua = rtn_msg.shuo_hua
    for i, v in pairs(shuo_hua or {}) do
        local client_index = PlayerData.getPlayerClientIDByServerID(i)
        if type(v) == 'number' then
            if v == SERVER_Surrender then
                self:setImgGroupVisible(client_index, true)
                self:setImgGroupTexture(client_index, player_tag_texture_path[ThreeTeam])
            elseif v == SERVER_ZhaGu then
                self.GuJia[#self.GuJia + 1] = client_index
                self:setImgGroupVisible(client_index, true)
                self:setImgGroupTexture(client_index, player_tag_texture_path[GuTeam])
            elseif v == SERVER_Silence then
                self:setImgGroupVisible(client_index, true)
                self:setImgGroupTexture(client_index, player_tag_texture_path[UnknownTeam])
                self.silenceCount = self.silenceCount + 1
            end
        elseif type(v) == 'table' then
            self:setImgGroupVisible(client_index, true)
            local bHasHeart3   = self:hasHeart3(v)
            local bHasDiamond3 = self:hasDiamond3(v)
            local bHasClub3    = self:hasClub3(v)
            local bHasSpade3   = self:hasSpade3(v)

            if bHasDiamond3 then
                self.bShowDiamond3 = true
            end

            self:setImg3Visible(client_index, 'ImgHeart', bHasHeart3)
            self:setImg3Visible(client_index, 'ImgClub', bHasClub3)
            self:setImg3Visible(client_index, 'ImgDiamond', bHasDiamond3)
            self:setImg3Visible(client_index, 'ImgSpade', bHasSpade3)

            if bHasHeart3 then
                self.sanjia[#self.sanjia + 1] = {index = client_index, card = HEART3}
            end

            if bHasDiamond3 then
                self.sanjia[#self.sanjia + 1] = {index = client_index, card = DIAMOND3}
            end

            if bHasHeart3 or bHasDiamond3 then
                self:setImgGroupTexture(client_index, player_tag_texture_path[ThreeTeam])
            else
                self:setImgGroupTexture(client_index, player_tag_texture_path[GuTeam])
            end
        end
    end

    for _, v in ipairs(playerinfo_list) do
        local index = self:indexTrans(v.index)
        for _, vv in ipairs(v.chu_san or {}) do
            if vv == DIAMOND3 then
                self:setImg3Visible(index, 'ImgDiamond', true)
            elseif vv == HEART3 then
                self:setImg3Visible(index, 'ImgHeart', true)
            elseif vv == CLUB3 then
                self:setImg3Visible(index, 'ImgClub', true)
            elseif vv == SPADE3 then
                self:setImg3Visible(index, 'ImgSpade', true)
            end
        end
    end

    local cur_id = rtn_msg.cur_id
    if cur_id and cur_id ~= 65535 then
        local client_index = PlayerData.getPlayerClientIDByServerID(cur_id)
        self:setBiaoVisible(client_index,true)
    end

    if rtn_msg.you_shu then
        for i,v in ipairs(rtn_msg.you_shu) do
            local rank_index = PlayerData.getPlayerClientIDByServerID(v)
            self:setRankVisible(rank_index, i)
            self.rank_num = self.rank_num + 1
        end
    end
    if rtn_msg.all_zha_gu then
       for i,v in ipairs(rtn_msg.all_zha_gu) do
            local client_index = PlayerData.getPlayerClientIDByServerID(v)
            self:setGuVisible(client_index, i)
            self.gu_num = self.gu_num + 1
        end
    end
    if rtn_msg.status == STATUS_CALL then
        self:treatResumeCall(rtn_msg)
    elseif rtn_msg.status == STATUS_PLAY then
        self:treatResumePlay(rtn_msg)
    end

    if rtn_msg.result_packet then
        local msg_result = {}
        for i, v in ipairs(rtn_msg.result_packet.players) do
            local index = self:indexTrans(v.index)
            msg_result[index] = v.hands or {}
        end

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            for __, v in ipairs(playerinfo_list) do
                local index = self:indexTrans(v.index)
                if self.player_ui[index] then
                    if v.ready then
                        self.player_ui[index]:getChildByName("ImgReady"):setVisible(true)
                    end
                end
            end

            AudioManager:stopPubBgMusic()
            self:initResultUI(rtn_msg.result_packet, rtn_msg.shuo_hua)
        end)))
    end
end

-- @服务端位置转换到客户端位置
-- @index服务端位置
-- @人数
-- @my_index自己的服务端位置
-- @return index对应的客户端位置
function ZGZScene:indexTrans(index, people_num, my_index)
    if not index then
        print('indexTrans数据不全')
        return
    end

    my_index = my_index or self.my_index
    if index == my_index then
        return 1
    end
    local pp = people_num or self.people_num
    if pp == 5 then
        if self.isStyle2 then
            if my_index == 1 then
                if index == 2 or index == 3 then
                    return index
                else
                    return index + 1
                end
            elseif my_index == 2 then
                if index == 1 then
                    return 6
                elseif index == 3 or index == 4 then
                    return index - 1
                else
                    return index
                end
            elseif my_index == 3 then
                if index == 1 then
                    return 5
                elseif index == 2 then
                    return 6
                elseif index == 4 then
                    return 2
                elseif index == 5 then
                    return 3
                end
            elseif my_index == 4 then
                if index == 1 then
                    return 3
                elseif index == 2 then
                    return 5
                elseif index == 3 then
                    return 6
                elseif index == 5 then
                    return 2
                end
            else
                if index == 1 then
                    return 2
                elseif index == 2 then
                    return 3
                elseif index == 3 then
                    return 5
                elseif index == 4 then
                    return 6
                end
            end
        else
            if my_index == 1 then
                if index == 2 then
                    return 2
                else
                    return index +1
                end
            elseif my_index == 2 then
                if index == 1 then
                    return 6
                elseif index == 3 then
                    return 2
                else
                    return index
                end
            elseif my_index == 3 then
                if index == 1 then
                    return 5
                elseif index == 2 then
                    return 6
                elseif index == 4 then
                    return 2
                elseif index == 5 then
                    return 4
                end
            elseif my_index == 4 then
                if index == 1 then
                    return 4
                elseif index == 2 then
                    return 5
                elseif index == 3 then
                    return 6
                elseif index == 5 then
                    return 2
                end
            else
                if index == 1 then
                    return 2
                elseif index == 2 then
                    return 4
                elseif index == 3 then
                    return 5
                elseif index == 4 then
                    return 6
                end
            end
        end
    else
        if index > my_index then
            return index - my_index + 1
        end
        if index < my_index then
            return index - my_index + self.people_num + 1
        end
    end
end

function ZGZScene:getSoundPrefix(index)
    print('放声音')
    if not index then
        return "male"
    end
    local lg       =  cc.UserDefault:getInstance():getStringForKey("language", "gy")
    local userData = PlayerData.getPlayerDataByClientID(index)
    if not userData then
        return "male"
    end

    local sex = userData.sex
    if not sex then
        return "male"
    end
    if sex ~= 2 then
        return "male"
    else
        return "female"
    end
end

function ZGZScene:setRoomData()
    -- 房号
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

function ZGZScene:setSysTime()
    -- 系统时间
    if self.is_playback then
        ZGZScene.showSysTime(tolua.cast(ccui.Helper:seekWidgetByName(self.node, "time"), "ccui.Text"), self.create_time)
    else
        ZGZScene.showSysTime(tolua.cast(ccui.Helper:seekWidgetByName(self.node, "time"), "ccui.Text"))
    end
end

function ZGZScene.showSysTime(label, time)
    local time = time or os.time()
    label:setString(os.date("%H:%M", time))
    label:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        time = time+1
        label:setString(os.date("%H:%M", time))
    end))))
end


function ZGZScene:treatResumeOutCard(direct,tCard)
end

function ZGZScene:clubRename(rtn_msg)
    if rtn_msg and self.club_id == rtn_msg.club_id then
        self.club_name        = rtn_msg.club_name or self.club_name
        local ClubInviteLayer = self:getChildByName('ClubInviteLayer')
        if ClubInviteLayer then
            ClubInviteLayer:refreshInviteClubName(self.club_name)
        end
    end
end

function ZGZScene:onRcvBroad(rtn_msg)
    if not rtn_msg.typ then
        commonlib.showTipDlg(rtn_msg.content or "系统提示")
    end
end

function ZGZScene:setSinglePlayerHead(index)
    local userData = PlayerData.getPlayerDataByClientID(index)
    if userData and self.player_ui[index] then
        local head = commonlib.wxHead(userData.head)
        self.player_ui[index]:setVisible(true)

        if pcall(commonlib.GetMaxLenString, userData.name, 12) then
            if index == 1 and self.imgBottomBg then
                tolua.cast(ccui.Helper:seekWidgetByName(self.imgBottomBg, "TextName"), "ccui.Text"):setString(commonlib.GetMaxLenString(userData.name, 12))
            else
                tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "TextName"), "ccui.Text"):setString(commonlib.GetMaxLenString(userData.name, 12))
            end
        else
            if index == 1 and self.imgBottomBg then
                tolua.cast(ccui.Helper:seekWidgetByName(self.imgBottomBg, "TextName"), "ccui.Text"):setString(userData.name)
            else
                tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "TextName"), "ccui.Text"):setString(userData.name)
            end
        end
        self:setFntScore(index,userData.score)

        self.player_ui[index]:getChildByName("PJN"):setVisible(false)

        commonlib.lixian(self.player_ui[index])
        self.player_ui[index]:getChildByName("ImgReady"):setVisible(false)

        self.player_ui[index].head_sp:setVisible(true)
        self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
        self:checkIpWarn()
    end
end

function ZGZScene:onRcvTableUserInfo(rtn_msg)
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

function ZGZScene:removeResultNode()
    -- 移除结算界面
    local result_node = self:getChildByTag(10109)
    if result_node then
        result_node:removeFromParent(true)
    end
end

function ZGZScene:setPlayerHandCard(cards, index)
    local k    = index
    local scal = PKCommond.hand_card_scale[k]
    if self.isRetroCard then
        scal = 1.1
    end
    self.isSetHands = true
    self.hand_card_list    = self.hand_card_list or {}
    self.hand_card_list[1] = self.hand_card_list[1] or {}
    self.paiChange:setTouchEnabled(false)
    for i=1, #cards do
        self.hand_card_list[k][i] = PKCommond.getCardById(1, true, self.isRetroCard)
        if self.isRetroCard then
            self.hand_card_list[k][i]:setScale(1)
        else
            self.hand_card_list[k][i]:setScale(2)
        end
        if k==1 and cards and cards[i] then
            self.hand_card_list[k][i].card_id = cards[i]
        end
        self.hand_card_list[k][i]:setPosition(cc.p(g_visible_size.width*0.5, g_visible_size.height*0.5))
        self.node:addChild(self.hand_card_list[k][i], 999)
        local desPos,r = PKCommond.calHandCardPos(k, #cards, i, self.paiShape, self.isStyle2)
        self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.075), cc.Show:create(), cc.CallFunc:create(function()
            AudioManager:playDWCSound("sound/m_sendcard.mp3")
            self.hand_card_list[k][i]:setRotation(r)
        end), cc.Spawn:create(cc.ScaleTo:create(0.075, scal), cc.MoveTo:create(0.075, desPos)),cc.CallFunc:create(function()
            if k==1 and cards and cards[i] then
                self.hand_card_list[k][i].card = PKCommond.getCardById(cards[i], nil, self.isRetroCard)
                if self.isRetroCard then
                    self.hand_card_list[k][i].card:setScale(1.1)
                else
                    self.hand_card_list[k][i].card:setScaleX(1)
                end
                self.hand_card_list[k][i].card:setPosition(cc.p(self.hand_card_list[k][i]:getContentSize().width / 2,self.hand_card_list[k][i]:getContentSize().height / 2))
                self.hand_card_list[k][i]:addChild(self.hand_card_list[k][i].card)
                self.hand_card_list[k][i].card:setVisible(false)

                self:printHandCardListPos(i)

                self.hand_card_list[k][i]:runAction(cc.Sequence:create(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0), cc.CallFunc:create(function()
                    self.hand_card_list[k][i].card:setVisible(true)
                end), cc.OrbitCamera:create(0, 1, 0, 0, 0, 0, 0)))
                AudioManager:playDWCSound("sound/m_turncard.mp3")
            end
        end)))
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
        self.paiChange:setTouchEnabled(true)
        self.isSetHands = false
    end)))
end

function ZGZScene:onRcvGameStart(rtn_msg)

    self.bShowDiamond3 = false
    if self.sheng_pai then
        self:setAllFntLastCardNumVisible(true)
    else
        self:setAllFntLastCardNumVisible(false)
    end

    self.is_game_start = true

    self:resetStatus()

    self:setAllImgMhVisible(false)
    self:setAllImgZgVisible(false)
    self:setAllImgReadyVisible(false)
    self:setAllImgLastCardVisible(true)
    -- 设置局数
    if rtn_msg.cur_ju then
        self:setTextJuShu(self.total_ju, rtn_msg.cur_ju)
    end

    -- 第一局展示开局动画
    if not self.jushu then
        self:playKaiju()
    end

    if rtn_msg.people_num ~= self.people_num and rtn_msg.is4To32 then
        -- print('游戏人数')
        self.people_num  = rtn_msg.people_num
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
        gt.uploadErr('zgz start peopleNumErroJoinRoomAgain')
        self:peopleNumErroJoinRoomAgain()
        return
    end

    -- 游戏开始清除自己上一局的手牌
    for __, vv in ipairs(self.hand_card_list[1]) do
        if vv then
            vv:removeFromParent(true)
        end
    end
    self.hand_card_list[1] = {}

    commonlib.closeQuickStart(self)

    self:setBtnGameStartVisible()
    self:disapperClubInvite(true)

    -- 显示剩牌
    if self.sheng_pai then
        for i =1, 6 do
            if self.people_num == 5 then
                self:setFntLastCardNum(i, 10)
            else
                self:setFntLastCardNum(i, 9)
            end
        end
    end
    -- 战绩数据
    if self.total_ju == 1 and rtn_msg.log_ju_id then
        gt.addMissJuId(rtn_msg.log_ju_id)
    end

    local cards = rtn_msg.cards
    ZGZLogic:sortDESC(cards)

    -- 设置这一局自己的手牌
    self:setPlayerHandCard(cards, 1)

    -- 设置最后一个说话的玩家
    self.lastSpeekPeople = self:getLastSpeekIndex(rtn_msg.cur_user)

    -- 设置说话
    local client_index = PlayerData.getPlayerClientIDByServerID(rtn_msg.cur_user)
    if client_index == 1 then
        self.NodePlayer1:getChildByName("tWait"):setVisible(false)
        if self.zhuo_hong_san then
            if not self:hasHeart3(cards) and not self:hasDiamond3(cards) then
            -- 没有红三 默认发送没话
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self:btnSilenceCallBack()
                end)))
            elseif self:hasDiamond3(cards) and not self:hasHeart3(cards) then
            -- 只有方三 默认发送亮方三
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self.selectedCard           = self.selectedCard or {}
                    self.selectedCard[DIAMOND3] = true
                    self:btnShow3CallBack()
                end)))
            else
            -- 有红三时 玩家自己选择是否亮三
                self:setShuoHuaBtn(cards)
            end
        else
            self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                self:setShuoHuaBtn(cards)
            end)))
        end
    else
        self.NodePlayer1:getChildByName("tWait"):setVisible(true)
    end

    -- 捉红三说话阶段不用时钟指示是哪个玩家在操作
    if not self.zhuo_hong_san then
        self:setBiaoVisible(client_index, true)
    end

    if self:hasHeart3(cards) or self:hasDiamond3(cards) then
        self:setImgGroupTexture(1, player_tag_texture_path[ThreeTeam])
    else
        self:setImgGroupTexture(1, player_tag_texture_path[GuTeam])
    end
end

function ZGZScene:onRcvReady(rtn_msg)
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

        self.player_ui[index]:getChildByName("ImgReady"):setVisible(true)
        -- 设置分数
        self:setFntScore(index,userData.score)
        if not rtn_msg.piaoniao or rtn_msg.piaoniao == 0 then
            self.player_ui[index]:getChildByName("PJN"):setVisible(false)
        else
            self.player_ui[index]:getChildByName("PJN"):setVisible(true)
            tolua.cast(self.player_ui[index]:getChildByName("PJN"), "ccui.ImageView"):loadTexture("ui/qj_mj/" .. rtn_msg.piaoniao .. ".png")
        end
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function ZGZScene:onRcvReault(rtn_msg)
    self:save_new_record(rtn_msg, self.RecordGameType)

    --self:addPlist()
    if self.js_node and rtn_msg.jiesan_detail then
        self.js_node:removeFromParent(true)
        self.js_node = nil
    end

    self:setAllImgMhVisible(false)
    self:setAllImgZgVisible(false)
    self:setAllImgBuChuVisible(false)
    for ii, vv in ipairs(self.show_liangsan) do
        if vv ~= 0 then
            for __, v in ipairs(vv) do
                v:removeFromParent(true)
            end
            self.show_liangsan[ii] = 0
        end
    end

    self:setLiangSanVisible(false)

    self.panOprCard:setVisible(false)

    self.Biao:stopAllActions()
    self.Biao:setVisible(false)

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

    self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            for ii, vv in ipairs(self.last_out_card) do
                if vv ~= 0 then
                    for __, v in ipairs(vv) do
                        v:removeFromParent(true)
                    end
                    self.last_out_card[ii] = 0
                end
            end
            self:showLeftHandCard(msg)
        end),cc.DelayTime:create(0.75), cc.CallFunc:create(function()
            self:initResultUI(rtn_msg)
    end)))
end

function ZGZScene:onRcvJiesan(rtn_msg)
    self:unregisterEventListener()
    AudioManager:stopPubBgMusic()
    if self.is_fangzhu then
        commonlib.showTipDlg("游戏未开始,解散包厢将不会扣除房卡", function(is_ok)
            if is_ok then
                local scene     = require("scene.MainScene")
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
                    local scene     = require("scene.MainScene")
                    local gameScene = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                end
            end,1)
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

function ZGZScene:onRcvApplyJieSan(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index    = (rtn_msg.index)
    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid      = userData.uid
    rtn_msg.self     = (rtn_msg.index == PlayerData.MyServerIndex)
    commonlib.showJiesan(self, rtn_msg, RoomInfo.people_total_num)
end

function ZGZScene:onRcvApplyJieSanAgree(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index    = (rtn_msg.index)
    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid      = userData.uid
    rtn_msg.self     = (rtn_msg.index == PlayerData.MyServerIndex)
    commonlib.showJiesan(self, rtn_msg, RoomInfo.people_total_num)
end


function ZGZScene:getQuickStartWanFaStr()
    local wanfa = commonlib.split(self.wanfa_str,'\n')
    local str = ''
    for i, v in ipairs(wanfa) do
        str = str .. v .. '.'
    end
    print (str)
    return str
end

function ZGZScene:onRcvApplyStart(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index    = (rtn_msg.index)
    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid      = userData.uid
    rtn_msg.self     = (rtn_msg.index == PlayerData.MyServerIndex)
    local str        = self:getQuickStartWanFaStr()

    commonlib.showQuickStart(self, rtn_msg, RoomInfo.people_total_num, str)
end

function ZGZScene:onRcvApplyStartAgree(rtn_msg)
    if not rtn_msg.index then
        printErrorMsg('rtn_msg.index')
        return
    end
    local index    = (rtn_msg.index)
    local userData = PlayerData.getPlayerDataByServerID(index)
    if not userData then
        return
    end
    rtn_msg.nickname = userData.name
    rtn_msg.uid      = userData.uid
    rtn_msg.self     = (rtn_msg.index == PlayerData.MyServerIndex)
    local str        = self:getQuickStartWanFaStr()

    commonlib.showQuickStart(self, rtn_msg, RoomInfo.people_total_num, str)
end

function ZGZScene:onRcvRoomChat(rtn_msg)
    if rtn_msg.msg_type == 3 then
        EventBus:dispatchEvent(EventEnum.onRcvSpeek, rtn_msg)
    else
        rtn_msg.is_zgz = true
        EventBus:dispatchEvent(EventEnum.onMjSound, rtn_msg)
    end
end

function ZGZScene:onRcvRoomChatBQ(rtn_msg)
    if (not rtn_msg.index) or (not rtn_msg.to_index) then return end
    local index   = self:indexTrans(rtn_msg.index)
    local toindex = self:indexTrans(rtn_msg.to_index)
    if (not self.player_ui[index]) or (not self.player_ui[toindex]) then return end
    if self.my_index ~= rtn_msg.index and (self.ignoreArr[self.my_index] or self.ignoreArr[rtn_msg.index]) then return end
    commonlib.runInteractiveEffect(self, self.player_ui[index], self.player_ui[toindex], rtn_msg.msg_id, index,toindex, true)
end

function ZGZScene:onRcvZgzJoinRoomAgain(rtn_msg)
    self:unregisterEventListener()
    if (not rtn_msg.errno or rtn_msg.errno == 0) and rtn_msg.room_id ~= 0 then

        GameGlobal.MjSceneReplaceMJScene = true

        local MJScene = require("scene.ZGZScene")
        cc.Director:getInstance():replaceScene(MJScene.create(rtn_msg))
    else
        AudioManager:stopPubBgMusic()
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

function ZGZScene:onRcvLeaveRoom(rtn_msg)
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
            local ipui = self:getChildByTag(81000+index)
            if ipui then
                ipui:removeFromParent(true)
            end
            self:checkIpWarn()
        end

        commonlib.interQuickStart(self)
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

function ZGZScene:onRcvInLine(rtn_msg)
    -- print('------------------------------上线------------------------------')
    -- dump(rtn_msg)
    -- print('------------------------------上线------------------------------')
    if not self.indexTrans or
        not self.player_ui then
        return
    end
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        commonlib.lixian(self.player_ui[index])
    end
end

function ZGZScene:onRcvOutLine(rtn_msg)
    -- print('------------------------------离线------------------------------')
    -- dump(rtn_msg)
    -- print('------------------------------离线------------------------------')
    if not self.indexTrans or
        not self.player_ui then
        return
    end
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 and self.player_ui[index] then
        self.player_ui[index]:getChildByName("lixian"):setVisible(true)
    end
end

function ZGZScene:onRcvSyncUserData(rtn_msg)
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

function ZGZScene:onRcvSyncClubNotify(rtn_msg)
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

function ZGZScene:onRcvClubModify(rtn_msg)
    self:clubRename(rtn_msg)
end


function ZGZScene:setShuoMing(str)
    local shuoming     = true
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
        shuoming_lbl:setContentSize(cc.size(shuoming_lbl_size.width, shuoming_txt_size.height + 20))
        shuoming_txt:setPositionY(shuoming_txt_size.height + 10)
    end
end

function ZGZScene:setOwnerName(room_info)
    if room_info.index~=1 and room_info.other and room_info.other[1] then
        self.ownername =  room_info.other[1].name
    end
end

function ZGZScene:setClubEnterMsg()
    if self.club_id and self.club_name and self.club_index then
        GameGlobal.is_los_club    = true
        GameGlobal.is_los_club_id = self.club_id
    end
end

function ZGZScene:setRoomNumber(parent)
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

function ZGZScene:setBtnWanFa()
    --  玩法按钮
    self.wanfa =ccui.Helper:seekWidgetByName(self.node, "btn-wanfa")
    self.wanfa:setVisible(false)
    self.wanfa:addTouchEventListener(  function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local HelpLayer = require("scene.kit.HelpDialog")
                    local help      = HelpLayer.create(self, 'zgz')
                    help.is_in_main = true
                    self:addChild(help, 100000)
                end
            end)
end

function ZGZScene:btnRoomSetingLayerCallBack()
    local function callbackSpeed(param)
        self.TingAutoOutCard = param
        print('TingAutoOutCard',self.TingAutoOutCard)
    end

    local function callbackBg(ys)
        PKCommond.setZhuoBu(ccui.Helper:seekWidgetByName(self.node, "Image_2"),ys- 10)
    end

    local function callbackPkCard(ys)
        if ys then
            local net_msg = {
                cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
                room_id = self.desk,
            }
            ymkj.SendData:send(json.encode(net_msg))
        end
    end
    if self.is_playback then
        local SetLayer = require("scene.RoomSetingLayer")
        self:addChild(SetLayer.create(self.is_game_start, self.is_fangzhu, true), 100000)
    else

        local SetLayer = require("scene.kit.SetDialog")
        local shezhi   = SetLayer.create(self, self.is_game_start, "zgz", callbackBg, callbackSpeed, callbackPkCard)
        --shezhi.is_in_main = true
        self:addChild(shezhi, 100000)
    end
end
function ZGZScene:setBtnExit(node)
    ccui.Helper:seekWidgetByName(node, "exit"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            node:removeFromParent(true)
            self:unregisterEventListener()
            AudioManager:stopPubBgMusic()
            PKCommond.Bezier = {}
            local scene      = require("scene.MainScene")
            local gameScene  = scene.create()
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
            PKCommond.Bezier = {}
            local scene      = require("scene.MainScene")
            local gameScene  = scene.create()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    end)
end

function ZGZScene:setBtnJieSan()
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
end

function ZGZScene:setResultIndex(index)
    if self.people_num == 5 then
        if index == 6 then
            index = 5
        elseif index == 5 then
            index = 4
        elseif index == 4 then
            index = 3
        end
    end
    return index
end

function ZGZScene:setShareBtn(rtn_msg,node)
    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()) .. (self.game_name or "") .. self.desk .. "房第"..rtn_msg.cur_ju .. "局切磋详情:\n"
    for i, v in ipairs(rtn_msg.players) do
        if v.index then
            local userData = PlayerData.getPlayerDataByServerID(v.index)
            if userData then
                copy_str = copy_str .. "选手号:" .. userData.uid .. "  名字:"
                copy_str = copy_str .. userData.name .. "  成绩:" .. v.score .. "\n"
            else
                local errStr = string.format("desk = %s mjTypeWanFa = %s log_data_id = %s",tostring(self.desk),tostring('zgz'),tostring(rtn_msg.log_data_id))
                gt.uploadErr(errStr)
                logUp(errStr)
            end
        end
    end
    commonlib.shareResult(node, copy_str, g_game_name .. "房号:" .. self.desk, self.desk, self.copy)
    logUp(copy_str)
end


function ZGZScene:setBtnSheZhi()
    -- 设置按钮
    local szBtn = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "btn-shezhi"), "ccui.Widget")
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

function ZGZScene:setBtnGps()
    -- GPS按钮
    self.btnGps = ccui.Helper:seekWidgetByName(self.node,"btn-gps")
    self.btnGps:setVisible(false)
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

function ZGZScene:setBtnFaYan()
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

function ZGZScene:setBtnLiaoTian()
    -- 语音
    self.btnLiaoTian = ccui.Helper:seekWidgetByName(self.node, "btn-liaotian")
    self.btnLiaoTian:addTouchEventListener(function(sender,eventType)
            self.speekNode:touchEvent(sender,eventType)
        end
    )
end

function ZGZScene:setBtnBQs()
    self.bigbq = tolua.cast(ccui.Helper:seekWidgetByName(self.node,"Panel_3"), "ccui.Widget")
    self.bigbq:setVisible(false)
    local btnWang = ccui.Helper:seekWidgetByName(self.node, "btn_wang")
    self.btnWang  = btnWang
    btnWang:addTouchEventListener(  function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.bigbq:setVisible(not self.bigbq:isVisible())
            end
        end
    )
    btnWang:setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)

    local btnXiShou = ccui.Helper:seekWidgetByName(self.bigbq, "btn_xishou")
    btnXiShou:addTouchEventListener(function(sender,eventType)
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
    btnShaoXiang:addTouchEventListener(function(sender,eventType)
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
end

function ZGZScene:setBtnJieSanRoom()
    -- 解散房间
    self.jiesanroom = ccui.Helper:seekWidgetByName(self.node, "btn-jiesanroom")
    self.jiesanroom:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
            cc.UserDefault:getInstance():flush()

            commonlib.sendJiesan(self.is_game_start, self.is_fangzhu)
        end
    end)
end

function ZGZScene:setBtnRedBag()
    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
    local XQLayer       = RedBagXQLayer:create({_scene = self,isMJ = false})
    self:addChild(XQLayer,999)
    --红包按钮延时出现 防止收到消息未处理
    self.btnRedBag = ccui.Helper:seekWidgetByName(self.node,"btn_redbag")
    self.btnRedBag:setVisible(false)
    gt.performWithDelay(self.btnRedBag,function()
        self.btnRedBag:setVisible(RedBagController:getModel():getIsValid())
    end, 1.0)
    self.btnRedBag:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if nil == XQLayer then
                    local RedBagXQLayer = require("modules.view.RedBagXQLayer")
                    local XQLayer       = RedBagXQLayer:create({_scene = self,isMJ = true})
                    self:addChild(XQLayer, 999)
                end
                XQLayer:setHbVisibale(true)
                XQLayer:reFreshHB()
            end
        end
    )
end
function ZGZScene:resetStatus()
    -- 出完牌的人数，用来确定头游，二游等
    self.rank_num     = 0
    -- 说话流程选择扎股的数量，用来确定头股，二股等
    self.gu_num       = 0
    -- 通过扎股或亮黑三确定的股家，index
    self.GuJia        = {}
    -- 通过亮三或出红三确定的三家，index，card
    self.sanjia       = {}
    -- 场中已经展示出来的三家，index
    self.sanjia_num   = {}
    -- 所选中的牌
    self.sel_list     = {}
    -- 选择没话玩家的数量
    self.silenceCount = 0

    self.is_shuohua = false

    self.selectedCard = nil
    self.btnDiamond3:getChildByName('ImgSelected'):setVisible(false)
    self.btnClub3:getChildByName('ImgSelected'):setVisible(false)
    self.btnHeart3:getChildByName('ImgSelected'):setVisible(false)
    self.btnSpade3:getChildByName('ImgSelected'):setVisible(false)
    self:setAllImg3Visible(false)
    self:setAllImgLiangCardTagVisible(true)
    self:setAllImgGroupVisible(true)

    for client_index = 1, 6 do
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgGujia"):setVisible(false)
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgRank"):setVisible(false)
        self:setImgGroupTexture(client_index,player_tag_texture_path[UnknownTeam], true)
    end
end

function ZGZScene:setBtnQuickStart()

end

function ZGZScene:setQuickStartPeople(cur,total_num)

end

function ZGZScene:setPaiChange()
    -- 更换手牌形状
    self.paiChange = ccui.Helper:seekWidgetByName(self.node, "btn-changepai")
    self.paiChange:setVisible(false)
    self.paiChange:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.paiShape == "normal" then
                cc.UserDefault:getInstance():setStringForKey("pai_change", "arc")
                cc.UserDefault:getInstance():flush()
                self.paiChange:loadTextureNormal("ui/qj_zgz/hu-pk.png")
            else
                cc.UserDefault:getInstance():setStringForKey("pai_change", "normal")
                cc.UserDefault:getInstance():flush()
                self.paiChange:loadTextureNormal("ui/qj_zgz/ping-pk.png")
            end
            self.paiShape = cc.UserDefault:getInstance():getStringForKey("pai_change", "normal")
            for i, v in ipairs(self.hand_card_list[1]) do
                local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i, self.paiShape, self.isStyle2)
                v:setPosition(pos)
                v:setRotation(r)
            end
            self.sel_list = {}
            self.btnChuPai:setTouchEnabled(false)
            self.btnChuPai:setBright(false)
        end
    end)
end

function ZGZScene:InitBtns()
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
    -- 桌子分享
    self:setBtnDeskShare()
    -- 更换手牌
    self:setPaiChange()
    -- 红包详情
    self:setBtnRedBag()

    local function btnCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local szName = sender:getName()
            if szName == 'btnSurrender' then
                self:btnSurrenderCallBack()
            elseif szName == 'btnSilence' then
                self:btnSilenceCallBack()
            elseif szName == 'btnShow3' then
                self:btnShow3CallBack()
            elseif szName == 'btnZhaGu' then
                self:btnZhaGuCallBack()
            elseif szName == 'btnDiamond3' then
                self:btnDiamond3CallBack()
            elseif szName == 'btnClub3' then
                self:btnClub3CallBack()
            elseif szName == 'btnHeart3' then
                self:btnHeart3CallBack()
            elseif szName == 'btnSpade3' then
                self:btnSpade3CallBack()
            elseif szName == 'btnChuPai' then
                self:btnChuPaiCallBack()
            elseif szName == 'btnTiShi' then
                self:btnTiShiCallBack()
            elseif szName == 'btnBuChu' then
                self:btnBuChuCallBack()
            end
        end
    end
    self.panOprCard = ccui.Helper:seekWidgetByName(self.node, "panOprCard")
    self.panOprCard:setLocalZOrder(10)
    self.panOprCard:setVisible(false)
    -- 不出
    self.btnBuChu = ccui.Helper:seekWidgetByName(self.node, "btnBuChu")
    self.btnBuChu:setVisible(false)
    self.btnBuChu:addTouchEventListener(btnCallback)
    -- 提示
    self.btnTiShi = ccui.Helper:seekWidgetByName(self.node, "btnTiShi")
    self.btnTiShi:setVisible(false)
    self.btnTiShi:addTouchEventListener(btnCallback)
    -- 出牌
    self.btnChuPai = ccui.Helper:seekWidgetByName(self.node, "btnChuPai")
    self.btnChuPai:setVisible(false)
    self.btnChuPai:addTouchEventListener(btnCallback)
    -- 认输
    self.btnSurrender = self:seekNode("btnSurrender")
    self.btnSurrender:setVisible(false)
    self.btnSurrender:addTouchEventListener(btnCallback)
    -- 没话
    self.btnSilence = self:seekNode("btnSilence")
    self.btnSilence:setVisible(false)
    self.btnSilence:addTouchEventListener(btnCallback)
    -- 亮3
    self.btnShow3 = self:seekNode("btnShow3")
    self.btnShow3:setVisible(false)
    self.btnShow3:addTouchEventListener(btnCallback)
    -- 扎股
    self.btnZhaGu = self:seekNode("btnZhaGu")
    self.btnZhaGu:setVisible(false)
    self.btnZhaGu:addTouchEventListener(btnCallback)
    -- 方块三
    self.btnDiamond3 = ccui.Helper:seekWidgetByName(self.node, "btnDiamond3")
    self.btnDiamond3:addTouchEventListener(btnCallback)
    -- 梅花三
    self.btnClub3 = ccui.Helper:seekWidgetByName(self.node, "btnClub3")
    self.btnClub3:addTouchEventListener(btnCallback)
    -- 红桃三
    self.btnHeart3 = ccui.Helper:seekWidgetByName(self.node,'btnHeart3')
    self.btnHeart3:addTouchEventListener(btnCallback)
    -- 黑桃三
    self.btnSpade3 = ccui.Helper:seekWidgetByName(self.node,'btnSpade3')
    self.btnSpade3:addTouchEventListener(btnCallback)

    self.ImgKK = ccui.Helper:seekWidgetByName(self.node,'ImgKK')
    self.ImgKK:setVisible(false)
    self.ImgKK:setLocalZOrder(1002)

    local pnbtn = self:seekNode("pnbtn")
    pnbtn:setLocalZOrder(1001)
    -- 打不起
    self.ImgDaBuQi = ccui.Helper:seekWidgetByName(self.node, "ImgDaBuQi")
    self.ImgDaBuQi:setVisible(false)
    self.ImgDaBuQi:setLocalZOrder(9999)

    if not self.btnLeftPosX then
        self.btnLeftPosX,self.btnLeftPosY   = self.btnSurrender:getPosition()
        self.btnMidPosX,self.btnMidPosY     = self.btnSilence:getPosition()
        self.btnRightPosX,self.btnRightPosY = self.btnShow3:getPosition()
    end
end

function ZGZScene:setBtnsVisible()
    self:setBtnsReplayVisible()
    self:setIosCheckingVisible()
    self:setBtnGameStartVisible()
end

function ZGZScene:setWenHaoListVisible()
    if self.is_game_start then
        local windowSize = cc.Director:getInstance():getWinSize()
        for i, v in ipairs(self.wenhao_list) do
            v:setVisible(false)
        end
    end
end

function ZGZScene:setBtnsReplayVisible()
    if self.is_playback then
        self.btnGps:setVisible(false)
        self.btnFaYan:setVisible(false)
        self.btnWang:setVisible(false)
        self.btnLiaoTian:setVisible(false)
    end
end

function ZGZScene:setIosCheckingVisible()
    if ios_checking then
        self.btnLiaoTian:setVisible(false)
    end
end

--  游戏开始要变更的按钮
function ZGZScene:setBtnGameStartVisible()
    if self.is_game_start then
        self.btnjiesan:setVisible(false)
        self.wanfa:setVisible(true)
        self.paiChange:setVisible(true)
        self:setWenHaoListVisible()
    end
    self:setGameStartBtnStatus()
end

function ZGZScene:setRoomCurPeopleNumByRoomInfo(room_info)
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
    for i, v in pairs(other) do
        people_num = people_num + 1
    end

    return people_num
end

function ZGZScene:setRoomCurPeopleNumByTableUserInfo(rtn_msg)

    local people_num = RoomInfo.getCurPeopleNum()
    people_num       = people_num + 1
    RoomInfo.updateCurPeopleNum(people_num)
end

function ZGZScene:setRoomCurPeopleNumByLeaveRoom(rtn_msg)
    local people_num = RoomInfo.getCurPeopleNum()
    people_num       = people_num - 1
    RoomInfo.updateCurPeopleNum(people_num)
end

function ZGZScene:setDirtyHeadDefaultTexture()
    for i , v in ipairs(self.player_ui) do
        local userData = PlayerData.getPlayerDataByClientID(i)
        if userData and userData.dirty then
            local dirty_index = userData.dirty
            if self.player_ui[dirty_index] and self.player_ui[dirty_index].head_sp then
                -- 还原默认头像
                print('还原默认头像')
                print('新头像ID ',i,'原来位置',dirty_index)
                self.player_ui[dirty_index].head_sp:removeFromParent()
                self.player_ui[dirty_index].head_sp = self:stenHead(ccui.Helper:seekWidgetByName(self.player_ui[dirty_index],"Img-touxiang"))
            end
        end
    end
end

function ZGZScene:updateplayerIndex(rtn_msg)
    self:setDirtyHeadDefaultTexture()

    for i, v in ipairs(self.player_ui) do
        local userData = PlayerData.getPlayerDataByClientID(i)
        print(i)
        -- dump(userData)
        v:setVisible(userData ~= nil)
        if userData and userData.dirty then
            print('---------------------------------')
            self:setSinglePlayerHead(i)
            self.player_ui[i]:setPosition(self.player_ui[userData.dirty]:getPosition())

            userData.dirty = nil
            self:addPlayerTouchLister(self.player_ui[i], i)
        end
    end
end

function ZGZScene:gameStartPeopleChange(rtn_msg)
    PlayerData.updateIndexByGameStart(rtn_msg)

    self.my_index = PlayerData.MyServerIndex
    -- 人数变化重设playerUI
    self:updateplayerIndex(rtn_msg)
end

function ZGZScene:setNonePeopleChair()
     self.wenhao_list={
        self:seekNode("wenhao1"),
        self:seekNode("wenhao2"),
        self:seekNode("wenhao3"),
        self:seekNode("wenhao4"),
        self:seekNode("wenhao5"),
        self:seekNode("wenhao6"),
    }
    if self.people_num == 5 then
        if self.isStyle2 then
            self.wenhao_list[4]:setVisible(false)
        else
            self.wenhao_list[3]:setVisible(false)
        end
    end
end

function ZGZScene:stenHead(head_node, scale)
    local scale = scale or 0.65
    local size  = head_node:getContentSize()

    local img_head = cc.Sprite:create("ui/qj_mj/img_head.png")
    img_head:setAnchorPoint(cc.p(0.5, 0.5))
    img_head:setScale(scale)
    head_node:addChild(img_head)
    img_head:setPosition(cc.p(size.width*0.5, size.height*0.5))
    return img_head
end

function ZGZScene:setPlayerHead()
    self.player_ui = {}

    for play_index = 1, 6 do
        -- 用户面板
        local play = tolua.cast(ccui.Helper:seekWidgetByName(self.node,"play" .. play_index), "ccui.ImageView")
        if play_index ~= 1 then
            play:setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)
        else
            play:setLocalZOrder(10000)
        end
        self.player_ui[play_index] = play
        play:setPosition(cc.p(self.wenhao_list[play_index]:getPosition()))
        -- 头像框
        self.player_ui[play_index].head_sp = self:stenHead(ccui.Helper:seekWidgetByName(play,"ImgHead"))--commonlib.stenHead(play)

        play:setVisible(false)

        play:getChildByName("lixian"):setVisible(false)
        play:getChildByName('PJN'):setVisible(false)
        play:getChildByName("ImgReady"):setVisible(false)
        play:getChildByName("ImgGujia"):setVisible(false)
        play:getChildByName("ImgRank"):setVisible(false)
        play:getChildByName('ImgLastCard'):setVisible(false)
        play:getChildByName('ImgGroup'):setVisible(false)

        if play_index == 1 and self.imgBottomBg then
            ccui.Helper:seekWidgetByName(self.imgBottomBg, 'FntScore'):setVisible(false)
            ccui.Helper:seekWidgetByName(self.imgBottomBg, 'ImgLiangCardTag'):setVisible(false)
        else
            ccui.Helper:seekWidgetByName(play, 'FntScore'):setVisible(false)
            ccui.Helper:seekWidgetByName(play, 'ImgLiangCardTag'):setVisible(false)
        end

        -- 点击头像，进入个人头像面板
        self:addPlayerTouchLister(play, play_index)
    end
    if self.people_num == 5 then
        if self.isStyle2 then
            self:seekNode("play4"):setVisible(false)
        else
            self:seekNode("play3"):setVisible(false)
            self.wenhao_list[2]:setPositionY(self.wenhao_list[6]:getPositionY())
            self:seekNode("play2"):setPositionY(self.wenhao_list[6]:getPositionY())
            self:seekNode("play2"):getChildByName("NodeOutCard"):setPositionY(60)
            self:seekNode("play2"):getChildByName("ImgMh"):setPositionY(60)
            self:seekNode("play2"):getChildByName("ImgZg"):setPositionY(60)
            self:seekNode("play2"):getChildByName("Imgbuchu"):setPositionY(60)
        end
    end
end

function ZGZScene:addPlayerTouchLister(play,play_index)
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

function ZGZScene:initPlayerHead()
    local MyUserData = PlayerData.getPlayerDataByClientID(1)
    if not MyUserData then
        return
    end

    local need_ready = (not MyUserData.hand_card or #MyUserData.hand_card <= 0)

    for index, player_ui_item in ipairs(self.player_ui) do
        -- log()
        local userData = PlayerData.getPlayerDataByClientID(index)
        local v        = userData
        -- 服务端座位号转本地座位号
        if userData then
            -- log()
            -- 微信头像地址
            local head = commonlib.wxHead(v.head)
            self.player_ui[index]:setVisible(true)
            -- 昵称
            if pcall(commonlib.GetMaxLenString, v.name, 12) then
                if index == 1 and self.imgBottomBg then
                    tolua.cast(ccui.Helper:seekWidgetByName(self.imgBottomBg, "TextName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name, 12))
                else
                    tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "TextName"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.name, 12))
                end
            else
                if index == 1 and self.imgBottomBg then
                    tolua.cast(ccui.Helper:seekWidgetByName(self.imgBottomBg, "TextName"), "ccui.Text"):setString(v.name)
                else
                    tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index], "TextName"), "ccui.Text"):setString(v.name)
                end
            end
            -- log()
            -- 分数
            self:setFntScore(index,v.score)
            -- 离线
            -- log()
            if index ~=1 and v.out_line then
                if type(v.out_line) == "boolean" then
                    v.out_line = 0
                end
                self.player_ui[index]:getChildByName("lixian"):setVisible(false)
            end
            -- log()
            -- 下载微信头像
            if head ~= "" then
                self.player_ui[index].head_sp:setVisible(true)
                self.player_ui[index].head_sp:downloadImg(head, g_wxhead_addr)
            else
                self.player_ui[index].head_sp:setVisible(false)
            end
            -- log()
            -- 准备手势
            if need_ready and v.ready then
                self.player_ui[index]:getChildByName("ImgReady"):setVisible(true)
            end
            -- log()
        end
    end
end

function ZGZScene:setBtnDeskShare()
    local share_title = self.desk .. g_game_name
    commonlib.showShareBtn(self.share_list, (string.gsub(self.wanfa_str, "[.\n]+", ",")), share_title, self.desk, self.copy,
        function()
            -- 得到当前人数
            local cur_num   = RoomInfo.getCurPeopleNum()
            -- 得到总人数
            local total_num = RoomInfo.getTotalPeopleNum()
            local str = string.format("%d缺%d", total_num, total_num - cur_num)
            return str
        end
    )
end

function ZGZScene:initResultUI(rtn_msg, shuohua)
    dump(rtn_msg)
    local node = tolua.cast(cc.CSLoader:createNode("ui/zgzxjs.csb"), "ccui.Widget")
    self:addChild(node, 100000)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self:setShareBtn(rtn_msg,node)
    local index_list  = {1, 2, 3, 4, 5, 6}
    local oper_beishu = {"", "", "", "", "", ""}
    self.jushu        = rtn_msg.cur_ju
    local shuo_hua    = rtn_msg.shuo_hua or shuohua
    for i, v in ipairs(shuo_hua or {}) do
        local client_index = self:indexTrans(i)
        if type(v) == 'number' then
            if v == SERVER_Surrender then
                oper_beishu[client_index] = "[认输]"
            elseif v == SERVER_ZhaGu then
                oper_beishu[client_index] = "[扎股]"
            elseif v == SERVER_Silence then
                oper_beishu[client_index] = "[没话]"
            end
        elseif type(v) == 'table' then
            local bHasHeart3   = self:hasHeart3(v)
            local bHasDiamond3 = self:hasDiamond3(v)
            local bHasClub3    = self:hasClub3(v)
            local bHasSpade3   = self:hasSpade3(v)

            oper_beishu[client_index] = oper_beishu[client_index] .. "[亮"
            if bHasHeart3 then
                oper_beishu[client_index] = oper_beishu[client_index] .. "红"
            end
            if bHasSpade3 then
                oper_beishu[client_index] = oper_beishu[client_index] .. "黑"
            end
            if bHasClub3 then
                oper_beishu[client_index] = oper_beishu[client_index] .. "梅"
            end
            if bHasDiamond3 then
                oper_beishu[client_index] = oper_beishu[client_index] .. "方"
            end

            oper_beishu[client_index] =oper_beishu[client_index] .. "三]"

        end
    end

    local posy = ccui.Helper:seekWidgetByName(node, "play6"):getPositionY()
    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        --local sortIndex = self:setResultIndex(play_index)
        index_list[play_index] = nil
        local play = tolua.cast(ccui.Helper:seekWidgetByName(node, "play" .. play_index), "ccui.ImageView")
        local oper = tolua.cast(ccui.Helper:seekWidgetByName(play, "oper"), "ccui.Text")
        local userData = PlayerData.getPlayerDataByClientID(play_index)
        if not userData then
            gt.uploadErr('zgz result peopleNumErroJoinRoomAgain')
            self:peopleNumErroJoinRoomAgain()
            return
        end

        local score_text = tolua.cast(ccui.Helper:seekWidgetByName(play, "score"), "ccui.TextBMFont")
        if score_text then
            score_text:setString(v.score)
        end
        oper_beishu[play_index] = oper_beishu[play_index].."[" .. v.bei_shu .. "倍]"
        if v.score <= 0 then
            score_text:setFntFile("ui/qj_zgz/fufen-export.fnt")
        else
            score_text:setFntFile("ui/qj_zgz/zongfen_-export.fnt")
        end

        if self.isStyle2 then
            if play_index == 1 then
                play:setPositionY(230)
            elseif play_index == 2 then
                play:setAnchorPoint(1, 0.5)
                play:setPositionX(self.NodeOutCard[2].x - 20)
                play:setPositionY(posy - 20)
            elseif play_index == 3 then
                play:setAnchorPoint(1, 0.5)
                play:setPositionX(self.NodeOutCard[3].x - 20)
                play:setPositionY(ccui.Helper:seekWidgetByName(node, "play5"):getPositionY())
            elseif play_index == 4 then
                play:setPositionX(ccui.Helper:seekWidgetByName(node, "play1"):getPositionX())
                play:setPositionY(ccui.Helper:seekWidgetByName(node, "play5"):getPositionY())
            elseif play_index == 5 then
                play:setAnchorPoint(0, 0.5)
                play:setPositionX(self.NodeOutCard[5].x)
            elseif play_index == 6 then
                play:setAnchorPoint(0, 0.5)
                play:setPositionX(self.NodeOutCard[6].x)
                play:setPositionY(posy - 20)
            end
        else
            if self.people_num == 5 then
                if play_index == 1 then
                    play:setPositionY(220)
                elseif play_index == 2 then
                    play:setPositionY(ccui.Helper:seekWidgetByName(node, "play6"):getPositionY())
                end
            else
                if play_index == 1 then
                    play:setPositionY(200)
                end
            end
        end
        oper:setString(oper_beishu[play_index])
        self.player_ui[play_index].coin = v.total_score or (self.player_ui[play_index].coin + v.score)
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node,"play" .. v):setVisible(false)
        end
    end

    ccui.Helper:seekWidgetByName(node, "btn-jxyx"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then

            node:removeFromParent(true)
            self:resetData()

            for ii, vv in ipairs(self.last_out_card) do
                if vv ~= 0 then
                    for __, v in ipairs(vv) do
                        v:removeFromParent(true)
                    end
                    self.last_out_card[ii] = 0
                end
            end
            self:resetStatus()
            self:setBeiShu(0)
            self:setAllFntLastCardNumVisible(false)

            for i, v in ipairs(self.player_ui) do
                if v.coin then
                    if i == 1 and self.imgBottomBg then
                        ccui.Helper:seekWidgetByName(self.imgBottomBg, "FntScore"):setString(commonlib.goldStr(v.coin))
                    else
                        ccui.Helper:seekWidgetByName(v, "FntScore"):setString(commonlib.goldStr(v.coin))
                    end
                end
            end

            if not self.is_playback then
                if not rtn_msg.results then
                    -- self.quan_lbl:setString("剩余"..(self.total_ju-rtn_msg.cur_ju-1).."局")
                    self:setTextJuShu(self.total_ju, rtn_msg.cur_ju+1)
                    self:sendReady()
                    AudioManager:playDWCBgMusic("sound/ddz_bgplay.mp3")
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, rtn_msg.log_ju_id, rtn_msg.gmId)
                end
            else
                if not rtn_msg.results then
                    self:unregisterEventListener()
                    AudioManager:stopPubBgMusic()
                    PKCommond.Bezier = {}
                    local scene      = require("scene.MainScene")
                    local gameScene  = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail ,rtn_msg.club_name, gt.playback_log_ju_id, rtn_msg.gmId)
                end
            end
        end
    end)

end

function ZGZScene:initVIPResultUI(rtn_msg, jiesan_detail,club_name,log_ju_id,gmId)
    self:removeResultNode()
    -- dump(rtn_msg)
    -- log("~~~~~~")
    local node = tolua.cast(cc.CSLoader:createNode("ui/zgzdjs.csb"), "ccui.Widget")
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

    local copy_str = os.date("切磋时间%m-%d %H:%M\n", os.time()).. "扎股子切磋详情:\n"

    table.sort( rtn_msg, function(x,y)
        return x.total_score > y.total_score
    end )

    for i, v in ipairs(rtn_msg) do
        local userData = PlayerData.getPlayerDataByServerID(v.index)
        if userData then
            copy_str = copy_str .. "选手号:" .. userData.uid .. "  名字:"
            copy_str = copy_str .. userData.uid .. "  成绩:" .. v.total_score .. "\n"
        else
            local errStr = self:mjUploadError('initVIPResult copy_str userData nil',tostring(v.index),'ingore')
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
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
            local errStr = self:mjUploadError('initVIPResult name userData nil',tostring(v.index),'ingore')
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
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

    self:setRoomNumber(tolua.cast(ccui.Helper:seekWidgetByName(node, "lab-fangjianhao"), "ccui.Text"))

    local index_list = {1,2,3,4,5,6}
    table.sort( rtn_msg, function(x,y)
        local xIndex = PlayerData.getPlayerClientIDByServerID(x.index)
        local yIndex = PlayerData.getPlayerClientIDByServerID(y.index)
        return xIndex < yIndex
    end)
    for i, v in ipairs(rtn_msg) do
        local play_index      = self:indexTrans(v.index)
        local sortIndex       = self:setResultIndex(play_index)
        index_list[sortIndex] = nil
        local play            = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")
        if self.people_num == 5 then
            play:setPositionX(256 + (i - 1) * 192)
        end
        local userData = PlayerData.getPlayerDataByClientID(play_index)
        local head = userData and userData.head or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView"):downloadImg(commonlib.wxHead(head), g_wxhead_addr)
        local uid = userData and userData.uid or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-id"), "ccui.Text"):setString(uid)
        local name = userData and userData.name or ''
        if pcall(commonlib.GetMaxLenString, name, 8) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(commonlib.GetMaxLenString(name, 8))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "name"), "ccui.Text"):setString(name)
        end

        local total_text = tolua.cast(ccui.Helper:seekWidgetByName(play, "benju"), "ccui.TextBMFont")
        if total_text then
            total_text:setString(v.total_score)
        end
        if v.total_score ~= max_score or max_score == 0 then
            ccui.Helper:seekWidgetByName(play, "Win"):setVisible(false)
        end
        if v.total_score <= 0 then
            total_text:setFntFile("ui/qj_zgz/zongfen--export.fnt")
        else
            total_text:setFntFile("ui/qj_zgz/zongfen_-export.fnt")
        end
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node,"play" .. v):setVisible(false)
        end
    end

    local btn_jiesan = ccui.Helper:seekWidgetByName(node, "btn-jsxq")
    if jiesan_detail then
        btn_jiesan:setVisible(true)
        btn_jiesan:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local JiesanLayer = require("scene.JiesanLayer")
                local jiesan      = JiesanLayer:create(jiesan_detail, self.desk, gmId)
                self:addChild(jiesan,100001)
            end
        end)
    else
        btn_jiesan:setVisible(false)
    end
end


function ZGZScene:setTextJuShu(total_ju,cur_ju)
    self.TextJuShu:setString("局数:" .. cur_ju .. '/' .. total_ju .. "局")
end

function ZGZScene:InitOutCardPos()
    self.NodeOutCard = {}
    for client_index = 1 , 6 do
        if self.isStyle2 then
            local NodeOutCard              = ccui.Helper:seekWidgetByName(self.node, "NodeOutCard" .. client_index)
            local posx,posy                = NodeOutCard:getPosition()
            -- local worldPos                 = self.player_ui[client_index]:convertToWorldSpace(cc.p(posx,posy))
            -- local layerpos                 = self:convertToNodeSpace(worldPos)

            self.NodeOutCard[client_index] = cc.p(posx,posy)
        else
            local NodeOutCard              = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "NodeOutCard")
            local posx,posy                = NodeOutCard:getPosition()
            local worldPos                 = self.player_ui[client_index]:convertToWorldSpace(cc.p(posx,posy))
            local layerpos                 = self:convertToNodeSpace(worldPos)
            self.NodeOutCard[client_index] = layerpos
        end
    end
    PKCommond.setOutCardPos(self.NodeOutCard)
end

function ZGZScene:setClubInvite()
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

function ZGZScene:setBtnDeskShare()
    local share_title = self.desk .. g_game_name
    commonlib.showShareBtn(self.share_list, (string.gsub(self.wanfa_str, "[.\n]+", ",")), share_title, self.desk, self.copy, function()
        -- 得到当前人数
        local cur_num   = RoomInfo.getCurPeopleNum()
        -- 得到总人数
        local total_num = RoomInfo.getTotalPeopleNum()
        local str       = string.format("%d缺%d",total_num,total_num - cur_num)
        return str
    end)
end

function ZGZScene:getWanFaStr()
    local room_info = RoomInfo.params
    self.game_name  = '扎股子\n'

    local str = nil

    str = self.game_name
    str = str .. room_info.total_ju .. "局" .. (RoomInfo.people_total_num or 5) .. "人\n"
    str = str .. ((room_info.zhuo_hong_san) and '捉红三\n' or '')
    str = str .. ((room_info.sheng_pai) and '显示剩牌\n' or '')
    str = str .. ((room_info.isHSPR) and '黑三骗人\n' or '')
    str = str .. ((room_info.isHSJF) and '黑三加分\n' or '')
    str = str .. ((room_info.isBLFKS) and '必亮方块三\n' or '')
    str = str .. ((room_info.isPTWF) and '普通玩法\n' or '')
    str = str .. ((room_info.isZHYGBD) and '最后一股不打\n' or '')
    str = str .. ((room_info.isJDFG) and '经典风格\n' or '流行风格\n')

    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str .. room_type

    return str
end


function ZGZScene:checkIpWarn(is_click_see)
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

                if (people_num == 2 or people_num == 3 or people_num == 4 or people_num == 5 or people_num == 6) and not is_click_see then
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

function ZGZScene:disapperClubInvite(bForceDiscover)
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

-- 准备
function ZGZScene:setAllImgReadyVisible(visible)
    for client_index = 1, 6 do
        self:setImgReadyVisible(client_index, visible)
    end
end

function ZGZScene:setImgReadyVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    self.player_ui[client_index]:getChildByName('ImgReady'):setVisible(visible)
end

-- 分数
function ZGZScene:setAllFntScoreVisible(visible)
    for client_index = 1, 6 do
        self:setFntScoreVisible(client_index,visible)
    end
end

function ZGZScene:setFntScoreVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    if client_index == 1 and self.imgBottomBg then
        ccui.Helper:seekWidgetByName(self.imgBottomBg, 'FntScore'):setVisible(visible)
    else
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], 'FntScore'):setVisible(visible)
    end
end

function ZGZScene:setFntScore(client_index, score)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    if client_index == 1 and self.imgBottomBg then
        ccui.Helper:seekWidgetByName(self.imgBottomBg, "FntScore"):setString(commonlib.goldStr(score))
        ccui.Helper:seekWidgetByName(self.imgBottomBg, "FntScore"):setVisible(true)
    else
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "FntScore"):setString(commonlib.goldStr(score))
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "FntScore"):setVisible(true)
    end
end

-- 剩余牌
function ZGZScene:setAllImgLastCardVisible(visible)
    for client_index = 1, 6 do
        self:setImgLastCardVisible(client_index, visible)
    end
end

function ZGZScene:setImgLastCardVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    if client_index == 1 then
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgLastCard"):setVisible(false)
    else
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgLastCard"):setVisible(visible)
    end
end

-- 剩余牌张数
function ZGZScene:setAllFntLastCardNumVisible(visible)
    for client_index = 1, 6 do
        self:setFntLastCardNumVisible(client_index, visible)
    end
end

function ZGZScene:setFntLastCardNumVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index], "FntLastCardNum"):setVisible(visible)
end

function ZGZScene:setFntLastCardNum(client_index,card_num)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index], "FntLastCardNum"):setString(tostring(card_num))
end

-- 没话
function ZGZScene:setAllImgMhVisible(visible)
    for client_index = 1, 6 do
        self:setImgMhVisible(client_index, visible)
    end
end

function ZGZScene:setImgMhVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local meiHua = nil
    if client_index == 1 then
        meiHua = self.NodePlayer1:getChildByName("ImgMh")
    else
        meiHua = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgMh")
    end
    meiHua:setVisible(visible)
end

function ZGZScene:runImgMhAction(client_index)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local node = nil
    if client_index == 1 then
        node = self.NodePlayer1:getChildByName("ImgMh")
    else
        node = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgMh")
    end
    node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(1.5),
        cc.Hide:create()
        )
        )
end

-- 扎股
function ZGZScene:setAllImgZgVisible(visible)
    for client_index = 1, 6 do
        self:setImgZgVisible(client_index, visible)
    end
end

function ZGZScene:setImgZgVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local zhaGu = nil
    if client_index == 1 then
        zhaGu = self.NodePlayer1:getChildByName("ImgZg")
    else
        zhaGu = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgZg")
    end
    zhaGu:setVisible(visible)
end

function ZGZScene:runImgZgAction(client_index)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local node = nil
    if client_index == 1 then
        node = self.NodePlayer1:getChildByName("ImgZg")
    else
        node = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgZg")
    end
    node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(1.5),
        cc.Hide:create()
        )
    )
end
-- 不出
function ZGZScene:setAllImgBuChuVisible(visible)
    for client_index = 1, 6 do
        self:setImgBuChuVisible(client_index,visible)
    end
end

function ZGZScene:setImgBuChuVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local buChu = nil
    if client_index == 1 then
        buChu = self.NodePlayer1:getChildByName("Imgbuchu")
    else
        buChu = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "Imgbuchu")
    end
    buChu:setVisible(visible)
end

-- 亮牌区域
function ZGZScene:setAllImgLiangCardTagVisible(visible)
    --log('亮3区域')
    for client_index = 1, 6 do
        self:setImgLiangCardTagVisible(client_index, visible)
    end
end

function ZGZScene:setImgLiangCardTagVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    -- log('亮3区域',client_index,visible)
    if client_index == 1 and self.imgBottomBg then
        ccui.Helper:seekWidgetByName(self.imgBottomBg, "ImgLiangCardTag"):setVisible(visible)
    else
        ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgLiangCardTag"):setVisible(visible)
    end
end

function ZGZScene:setAllImg3Visible(visible)
    for client_index = 1, 6 do
        self:setImg3Visible(client_index, 'ImgSpade', visible)
        self:setImg3Visible(client_index, 'ImgHeart', visible)
        self:setImg3Visible(client_index, 'ImgClub', visible)
        self:setImg3Visible(client_index, 'ImgDiamond', visible)
    end
end

function ZGZScene:setImg3Visible(client_index, node_name, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local ImgLiangCardTag = nil
    if client_index == 1 and self.imgBottomBg then
        ImgLiangCardTag = ccui.Helper:seekWidgetByName(self.imgBottomBg, "ImgLiangCardTag")
    else
        ImgLiangCardTag = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgLiangCardTag")
    end
    local node            = ImgLiangCardTag:getChildByName(node_name)
    if node then
        node:setVisible(visible)
    end
end

-- 那家
function ZGZScene:setAllImgGroupVisible(visible)
    for client_index = 1, 6 do
        self:setImgGroupVisible(client_index, visible)
    end
end

function ZGZScene:setImgGroupVisible(client_index, visible)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgGroup"):setVisible(visible)
end

function ZGZScene:setImgGroupTexture(client_index,texture_path, is_show)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    if texture_path == player_tag_texture_path[UnknownTeam] and client_index == 1 and not is_show then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index], "ImgGroup"):loadTexture(texture_path)
end

function ZGZScene:setshow3Visible(client_index, liang_san)
    if not client_index or not self.player_ui[client_index] then
        return
    end
    local show_card = {}
    outCardNum      = #liang_san
    for ci, card_id in ipairs(liang_san) do
        local card       = PKCommond.getCardById(card_id, nil, self.isRetroCard)
        local posx, posy = self.player_ui[client_index]:getPosition()
        card:setPosition(posx,posy)
        self.node:addChild(card)
        if self.isRetroCard then
            card:setScale(0.7)
        else
            card:setScale(0.5)
        end
        local desPos = PKCommond.calOutCarPos(client_index, outCardNum, ci, nil, self.isStyle2)
        --log('坐标')
        if not self.isStyle2 then
            if index == 4 or index == 5 then
                desPos.y = desPos.y -20
            end
        end
        show_card[#show_card+1] = card
        card:setLocalZOrder(ci)
        card:runAction(cc.MoveTo:create(0.05, desPos))
    end
    self.show_liangsan               = self.show_liangsan or {0, 0, 0, 0, 0, 0}
    self.show_liangsan[client_index] = show_card
end

function ZGZScene:setRankVisible(client_index, num)
    if not client_index or not self.player_ui[client_index] or num > 5 then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index],"ImgRank"):setVisible(true)
    ccui.Helper:seekWidgetByName(self.player_ui[client_index],"ImgRank"):loadTexture("ui/qj_zgz/" .. num .. "y.png")
end

function ZGZScene:setGuVisible(client_index, num)
    if not client_index or not self.player_ui[client_index] or num > 5 then
        return
    end
    ccui.Helper:seekWidgetByName(self.player_ui[client_index],"ImgGujia"):setVisible(true)
    ccui.Helper:seekWidgetByName(self.player_ui[client_index],"ImgGujia"):loadTexture("ui/qj_zgz/" .. num .. "gu.png")
end

-- 说话流程时亮三操作面板
function ZGZScene:setLiangSanVisible(visible)
    self.ImgKK:setVisible(visible)
    self.btnSurrender:setVisible(visible)
    self.btnShow3:setVisible(visible)
    self.btnSilence:setVisible(visible)
    self.btnZhaGu:setVisible(visible)
end

function ZGZScene:registerCardTouch()
    if self.is_playback then
        return
    end

    self.sel_list = {}
    self.can_opt  = false

    local began_index = nil
    local ended_index = nil
    self:setTouchEnabled(true)
    self:registerScriptTouchHandler(function(touch_type, xx, yy)
        if touch_type == "began" then
            local pos = cc.p(xx, yy)
            for i, v in ipairs(self.hand_card_list[1]) do
                if v.card then
                    local p = v.card:convertToNodeSpace(pos)
                    local s = v.card:getContentSize()
                    -- log(s)
                    local rect = cc.rect(0, 0, s.width, s.height)
                    if i ~= #self.hand_card_list[1] then
                        rect.width = PKCommond.handMarginX
                    end
                    if cc.rectContainsPoint(rect, p) then
                        if self.is_shuohua then
                            if self.zhuo_hong_san then
                                if v.card_id ~= HEART3 then
                                    return
                                end
                            else
                                if self.people_num == 6 then
                                    if v.card_id ~= DIAMOND3 and v.card_id ~= HEART3 then
                                        return
                                    end
                                else
                                    if (self.isBLFKS or v.card_id ~= DIAMOND3) and v.card_id ~= CLUB3 and v.card_id ~= HEART3 and v.card_id ~= SPADE3 then
                                        return
                                    end
                                end
                            end
                            if v.card_id == DIAMOND3 then
                                self:btnDiamond3CallBack()
                            elseif v.card_id == HEART3 then
                                self:btnHeart3CallBack()
                            elseif v.card_id == CLUB3 then
                                self:btnClub3CallBack()
                            elseif v.card_id == SPADE3 then
                                self:btnSpade3CallBack()
                            end
                        end

                        local exist = nil
                        for cii, cid in ipairs(self.sel_list) do
                            if v.card_id == cid then
                                exist = cii
                                break
                            end
                        end
                        if not exist then
                            self.sel_list[#self.sel_list+1] = v.card_id
                            local pos,r                     = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                            v:setPositionY(pos.y+30)
                        else
                            table.remove(self.sel_list, exist)
                            local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                            v:setPositionY(pos.y)
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
                        if self.is_shuohua then
                            if cid == DIAMOND3 and not self.isBLFKS and not self.zhuo_hong_san then
                                self:btnDiamond3CallBack()
                            elseif cid == HEART3 then
                                self:btnHeart3CallBack()
                            elseif cid == CLUB3 then
                                self:btnClub3CallBack()
                            elseif cid == SPADE3 then
                                self:btnSpade3CallBack()
                            end
                        end

                        if (self.isBLFKS or self.zhuo_hong_san) and self.is_shuohua then
                            if cid ~= DIAMOND3 then
                                table.remove(self.sel_list, cii)
                                local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                                v:setPositionY(pos.y)
                                break
                            end
                        else
                            table.remove(self.sel_list, cii)
                            local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                            v:setPositionY(pos.y)
                            break
                        end
                    end
                end
            end
            self.btnChuPai:setTouchEnabled(false)
            self.btnChuPai:setBright(false)
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
                        if self.is_shuohua then
                            return
                        end

                        if i < began_index then
                            var_begin   = i
                            var_end     = began_index-1
                            began_index = i
                        elseif i ~= began_index and i ~= ended_index then
                            if i < ended_index then
                                var_end   = ended_index
                                var_begin = i+1
                            else
                                var_begin = ended_index+1
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
                            local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                            v:setPositionY(pos.y + 30)
                        else
                            table.remove(self.sel_list, exist)
                            local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                            v:setPositionY(pos.y)
                        end
                    end
                end
            end
        else
            if self:canOutCard() and self:isMustChuCard() then
                self.btnChuPai:setTouchEnabled(true)
                self.btnChuPai:setBright(true)
            else
                self.btnChuPai:setTouchEnabled(false)
                self.btnChuPai:setBright(false)
            end
        end
    end)
end

function ZGZScene:canOutCard(is_last)
    self.last_out_card = self.last_out_card or {0, 0, 0, 0, 0, 0}
    local pre_card     = self.last_out_card[6]

    local count = 5
    while (pre_card == 0 and count >1)
    do
        pre_card = self.last_out_card[count]
        count    = count - 1
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
        for __, pre in ipairs(pre_card) do
            last_id_list[#last_id_list + 1] = pre.card_id
        end
        can = ZGZLogic:CompareCard(last_id_list, next_cards, self.bShowDiamond3, self.people_num)
    else
        can = ZGZLogic:GetCardType(next_cards, self.bShowDiamond3, self.people_num)>0
    end
    if can then
        if is_last then
            can = ZGZLogic:GetCardType(next_cards, self.bShowDiamond3, self.people_num)
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

function ZGZScene:sendShuoHua(tag, liang_san)
    --1:认输 2:亮三 3:扎股 4:没话
    local input_msg = {
        cmd = NetCmd.C2S_ZGZ_SHUO_HUA,
        tag = tag,
    }
    if tag == SERVER_Show3 then
        input_msg.liang_san = liang_san
    end

    dump(input_msg)
    ymkj.SendData:send(json.encode(input_msg))
end

function ZGZScene:getSelfHandCard()
    local cards = {}
    for i, v in ipairs(self.hand_card_list[1]) do
        if v and v.card_id then
            cards[#cards + 1] = v.card_id
        end
    end
    return cards
end

function ZGZScene:onRcvShuoHua(rtn_msg)
    --dump(rtn_msg)
    if self.is_playback then
        self:setLiangSanVisible(false)
    end
    local index = rtn_msg.index
    if not index then
        return
    end
    local tag = rtn_msg.tag
    if not tag then
        return
    end
    self:removeSelectCard()

    local client_index = PlayerData.getPlayerClientIDByServerID(index)
    local prefix       = self:getSoundPrefix(client_index)
    local fix          = ".mp3"
    local bei_shu      = rtn_msg.bei_shu
    self:setBeiShu(bei_shu)
    self:setImgLiangCardTagVisible(client_index,true)
    if tag == SERVER_Show3 then
        local liang_san = rtn_msg.liang_san
        if liang_san then
            local bThreeTeam   = false
            -- 是否亮了方三
            local soundDiamond = false
            -- 是否亮了红三
            local soundHeart   = false
            for i, v in pairs(liang_san) do
                if v == DIAMOND3 then
                    self:setImg3Visible(client_index, 'ImgDiamond', true)

                    bThreeTeam                           = true
                    soundDiamond                         = true
                    self.bShowDiamond3                   = true
                    self.sanjia[#self.sanjia + 1]        = {index = client_index, card = DIAMOND3}
                    self.sanjia_num[#self.sanjia_num +1] = client_index
                elseif v == HEART3 then
                    self:setImg3Visible(client_index,'ImgHeart',true)

                    bThreeTeam                            = true
                    soundHeart                            = true
                    self.sanjia[#self.sanjia + 1]         = {index = client_index, card = HEART3}
                    self.sanjia_num[#self.sanjia_num + 1] = client_index
                elseif v == CLUB3 then
                    self:setImg3Visible(client_index, 'ImgClub', true)
                elseif v == SPADE3 then
                    self:setImg3Visible(client_index, 'ImgSpade', true)
                end
            end
            if soundDiamond and soundHeart then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/dui3" .. fix)
            elseif soundDiamond and not soundHeart then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/fangkuai_3" .. fix)
            elseif not soundDiamond and soundHeart then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/hongtao_3" .. fix)
            end
            if bThreeTeam then
                self:setImgGroupTexture(client_index, player_tag_texture_path[ThreeTeam])
            else
                self.GuJia[#self.GuJia + 1] = client_index
                self:setImgGroupTexture(client_index, player_tag_texture_path[GuTeam])
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/zhagu" .. fix)
            end
            self:setshow3Visible(client_index, liang_san)
        end
    elseif tag == SERVER_Surrender then
        self:setImgGroupTexture(client_index, player_tag_texture_path[ThreeTeam])
    elseif tag == SERVER_Silence then
        if not self.zhuo_hong_san then
            self:setImgMhVisible(client_index, true)
            AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/guo" .. fix)
        end
        self:setImgGroupTexture(client_index, player_tag_texture_path[UnknownTeam])
        self.silenceCount = self.silenceCount + 1
    elseif tag == SERVER_ZhaGu then
        AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/zhagu" .. fix)
        self:setImgZgVisible(client_index, true)
        self.GuJia[#self.GuJia + 1] = client_index
        self:setImgGroupTexture(client_index, player_tag_texture_path[GuTeam])
        self.gu_num = self.gu_num + 1
        self:setGuVisible(client_index, self.gu_num)
    end
    if client_index == 1 then
        self:removeCardShadow()
    end
    local next_index = rtn_msg.next_index
    if next_index and next_index == PlayerData.MyServerIndex then
        self.NodePlayer1:getChildByName("tWait"):setVisible(false)
        local cards = self:getSelfHandCard()
        if self.zhuo_hong_san then
            if not self:hasHeart3(cards) and not self:hasDiamond3(cards) then
            -- 没有红三 默认发送没话
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                    self:btnSilenceCallBack()
                end)))
            elseif self:hasDiamond3(cards) and not self:hasHeart3(cards) then
            -- 只有方三 默认发送亮方三
                self:setLiangSanVisible(false)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self.selectedCard           = self.selectedCard or {}
                    self.selectedCard[DIAMOND3] = true
                    self:btnShow3CallBack()
                end)))
            else
                self:setShuoHuaBtn(cards)
            end
        else
            self:setShuoHuaBtn(cards)
        end
    end
    -- 经典风格中亮3后把所选中的牌取消选中状态
    if index == self.my_index and self.isStyle2 then
        self:removeSelectCard()
     end

    if next_index and not self.zhuo_hong_san then
        local client_index = PlayerData.getPlayerClientIDByServerID(next_index)
        self:setBiaoVisible(client_index, true)
    end
    local status = rtn_msg.status
    if status == STATUS_PLAY then
        self:removeCardShadow()
        self.NodePlayer1:getChildByName("tWait"):setVisible(false)
        if #self.GuJia == self.people_num - 1 then
            for i=1, self.people_num do
                local san = true
                for _, v in ipairs(self.GuJia) do
                    if i == v then
                        san = false
                    end
                end
                if san then
                    self:setImgGroupTexture(i, player_tag_texture_path[ThreeTeam])
                end
            end
        end
        self.GuJia = {}
        if #self.sanjia == 2 then
            for i = 1, 6 do
                local show3 = false
                for _, v in ipairs(self.sanjia) do
                    if i == v.index then
                        show3 = true
                    end
                end
                if show3 then
                    self:setImgGroupTexture(i, player_tag_texture_path[ThreeTeam])
                else
                    self:setImgGroupTexture(i, player_tag_texture_path[GuTeam])
                end
            end
        elseif #self.sanjia_num == 2 then
        	self:setAllSanjia()
        end

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            self:setAllImgMhVisible(false)
            self:setAllImgZgVisible(false)
            for ii, vv in ipairs(self.show_liangsan) do
                if vv ~= 0 then
                    for __, v in ipairs(vv) do
                        v:removeFromParent(true)
                    end
                    self.show_liangsan[ii] = 0
                end
            end
        end)))

        local chu_pai_id = rtn_msg.chu_pai_id
        if chu_pai_id == PlayerData.MyServerIndex then
            local cards  = self:getSelfHandCard()
            local ht5    = nil
            local target = 37
            for __, v in ipairs(cards) do
                if v == target then
                    ht5 = v
                    break
                end
            end
            self.target = target
            if ht5 then
                self.mustChuWu = true
            end

            self.can_opt = true

            if self.is_playback then
                self:resetOperPanel()
            else
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
                    self.panOprCard:setVisible(true)
                    self:resetOperPanel(100)
                end)))
            end
            log('正牌可以出牌了')
        end
        local client_index = PlayerData.getPlayerClientIDByServerID(chu_pai_id)
        self:setBiaoVisible(client_index,true)
    end
end

function ZGZScene:hasTargetCard(cards, targetCard)
    for _, v in ipairs(cards) do
        if v == targetCard then
            return true
        end
    end
    return false
end

function ZGZScene:hasHeart3(cards)
    return self:hasTargetCard(cards, HEART3)
end

function ZGZScene:hasDiamond3(cards)
    return self:hasTargetCard(cards, DIAMOND3)
end

function ZGZScene:hasSpade3(cards)
    return self:hasTargetCard(cards, SPADE3)
end

function ZGZScene:hasClub3(cards)
    return self:hasTargetCard(cards, CLUB3)
end

-- 有双张红三无黑三 投降 亮3(可亮一张红) 没话
-- 有双张红三有黑三 投降 亮3 (可亮一红但必须亮黑)  没话
-- 有单张红三无黑三 亮3  没话
-- 有单张红三有黑三 亮3 (可亮一红但必须亮黑)  没话
-- 只有黑三 亮黑3 扎股 没话
-- 无三 扎股 没话
function ZGZScene:setShuoHuaBtn(cards)
    --log('setShuoHuaBtn')
    if self.isStyle2 then
        self.ImgKK:setVisible(false)
        self.is_shuohua = true
        if self.isSetHands then
            self:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function ()
                self:setCardShadow()
            end)))
        else
            self:setCardShadow()
        end
    else
        self.ImgKK:setVisible(true)
    end

    -- 红桃三
    local bHasHeart3   = self:hasHeart3(cards)
    -- 方块三
    local bHasDiamond3 = self:hasDiamond3(cards)
    -- 梅花三
    local bHasClub3    = self:hasClub3(cards)
    -- 黑桃三
    local bHasSpade3   = self:hasSpade3(cards)
    if self.zhuo_hong_san then
    -- 是捉红三选项
        if not bHasHeart3 then
            self.btnHeart3:setColor(cc.c3b(100, 100, 100))
            self.btnHeart3:setTouchEnabled(false)
        else
            self.btnHeart3:setColor(cc.c3b(255, 255, 255))
            self.btnHeart3:setTouchEnabled(true)
        end

        self.btnDiamond3:setColor(cc.c3b(100, 100, 100))
        self.btnDiamond3:setTouchEnabled(false)

        self.btnClub3:setColor(cc.c3b(100, 100, 100))
        self.btnClub3:setTouchEnabled(false)

        self.btnSpade3:setColor(cc.c3b(100, 100, 100))
        self.btnSpade3:setTouchEnabled(false)

        if self.isStyle2 then
            for i, v in ipairs(self.hand_card_list[1]) do
                if v.card_id == DIAMOND3 then
                    local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                    if bHasDiamond3 then
                        self.selectedCard           = self.selectedCard or {}
                        self.selectedCard[DIAMOND3] = true
                    end

                    if self.selectedCard[DIAMOND3] then
                        if self.isSetHands then
                            v:runAction(cc.Sequence:create(cc.DelayTime:create(0.9), cc.CallFunc:create(function()
                                self.sel_list[#self.sel_list+1] = v.card_id
                                v:setPositionY(pos.y+30)
                            end)))
                        else
                            self.sel_list[#self.sel_list+1] = v.card_id
                            v:setPositionY(pos.y+30)
                        end
                    end
                end
            end
        end
    else
        if not bHasHeart3 then
            self.btnHeart3:setColor(cc.c3b(100, 100, 100))
            self.btnHeart3:setTouchEnabled(false)
        else
            self.btnHeart3:setColor(cc.c3b(255, 255, 255))
            self.btnHeart3:setTouchEnabled(true)
        end

        if self.isBLFKS then
            if not bHasDiamond3 then
                self.btnDiamond3:setColor(cc.c3b(100, 100, 100))
                self.btnDiamond3:setTouchEnabled(false)
            else
                self.btnDiamond3:setColor(cc.c3b(255, 255, 255))
                self.btnDiamond3:setTouchEnabled(false)
            end

            if self.isStyle2 then
                for i, v in ipairs(self.hand_card_list[1]) do
                    if v.card_id == DIAMOND3 then
                        local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                        if bHasDiamond3 then
                            self.selectedCard           = self.selectedCard or {}
                            self.selectedCard[DIAMOND3] = true
                        end

                        if self.selectedCard[DIAMOND3] then
                            if self.isSetHands then
                                v:runAction(cc.Sequence:create(cc.DelayTime:create(0.9), cc.CallFunc:create(function()
                                    self.sel_list[#self.sel_list+1] = v.card_id
                                    v:setPositionY(pos.y+30)
                                end)))
                            else
                                self.sel_list[#self.sel_list+1] = v.card_id
                                v:setPositionY(pos.y+30)
                            end
                        end
                    end
                end
            end
        else
            if not bHasDiamond3 then
                self.btnDiamond3:setColor(cc.c3b(100, 100, 100))
                self.btnDiamond3:setTouchEnabled(false)
            else
                self.btnDiamond3:setColor(cc.c3b(255, 255, 255))
                self.btnDiamond3:setTouchEnabled(true)
            end
        end

        if self.people_num == 6 then
            self.btnClub3:setColor(cc.c3b(100, 100, 100))
            self.btnClub3:setTouchEnabled(false)

            self.btnSpade3:setColor(cc.c3b(100, 100, 100))
            self.btnSpade3:setTouchEnabled(false)
        else
            if not bHasClub3 then
                self.btnClub3:setColor(cc.c3b(100, 100, 100))
                self.btnClub3:setTouchEnabled(false)
            else
                self.btnClub3:setColor(cc.c3b(255, 255, 255))
                self.btnClub3:setTouchEnabled(true)
            end
            if not bHasSpade3 then
                self.btnSpade3:setColor(cc.c3b(100, 100, 100))
                self.btnSpade3:setTouchEnabled(false)
            else
                self.btnSpade3:setColor(cc.c3b(255, 255, 255))
                self.btnSpade3:setTouchEnabled(true)
            end
        end
    end
    -- 至少有张红三
    self.bHasSingleR3  = (bHasHeart3 and not bHasDiamond3) or (not bHasHeart3 and bHasDiamond3)
    -- 有黑三
    self.bHasBlack3    = bHasClub3 or bHasSpade3
    -- 有双张红三
    self.bHasDoubleR3  = (bHasHeart3 and bHasDiamond3)
    -- 无黑三
    self.bHasNotBlack3 = not self.bHasBlack3
    -- 无红三
    self.bHasNotR3     = not bHasHeart3 and not bHasDiamond3
    -- 无三
    self.bHasNot3      = not self.bHasNotBlack3 and not self.bHasNotR3

    if not self.isStyle2 then
        if bHasHeart3 then
            self.selectedCard         = self.selectedCard or {}
            self.selectedCard[HEART3] = true
            self.btnHeart3:getChildByName('ImgSelected'):setVisible(true)
        end
        if bHasDiamond3 then
            self.selectedCard           = self.selectedCard or {}
            self.selectedCard[DIAMOND3] = true
            self.btnDiamond3:getChildByName('ImgSelected'):setVisible(true)
        end
    end
    if self.zhuo_hong_san then
        if not bHasDiamond3 then
        -- 没有方片三 不需要亮
            if bHasHeart3 then
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)
                self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        else
        -- 有方片三 默认亮
            if bHasHeart3 then
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            else
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnShow3:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
            end
        end
    else
        if self.bHasDoubleR3 then
            if self.isBLFKS and bHasDiamond3 then
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX,self.btnLeftPosY))
                --self.btnSilence:setPosition(cc.p(self.btnMidPosX,self.btnMidPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX,self.btnRightPosY))
            else
                -- 投降 亮3(可亮一张红) 没话
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        elseif self.bHasSingleR3 then
            -- 亮3  没话
            if self.isBLFKS and bHasDiamond3 then
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)

                self.btnShow3:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
            else
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)

                self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        elseif self.bHasBlack3 then
            -- 亮黑3 扎股 没话
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(true)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnZhaGu:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            -- 扎股 没话
            self.btnSilence:setVisible(true)
            self.btnZhaGu:setVisible(true)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnZhaGu:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        end
        -- 6人玩法勾选最后一股不打 没有红三且是最后一个说话的玩家
        local onlyZhagu = self.people_num == 6 and self.lastSpeekPeople == self.my_index and self.bHasNotR3 and self.isZHYGBD and self.silenceCount >= 5
        if onlyZhagu then
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)
            self.btnSurrender:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosX))
        end
    end
end

-- 认输
function ZGZScene:btnSurrenderCallBack()
    print('认输')
    self:sendShuoHua(SERVER_Surrender, nil)

    self:setLiangSanVisible(false)
    self.is_shuohua = false
    self.NodePlayer1:getChildByName("tWait"):setVisible(true)
end

-- 没话
function ZGZScene:btnSilenceCallBack()
    print('没话')
    self:sendShuoHua(SERVER_Silence, nil)

    self:setLiangSanVisible(false)
    self.is_shuohua = false
    self.NodePlayer1:getChildByName("tWait"):setVisible(true)
end

-- 亮3
function ZGZScene:btnShow3CallBack()
    print('亮3')
    if not self.selectedCard then return end
    local selectedCard = {}
    for i, v in pairs(self.selectedCard) do
        if v then
            selectedCard[#selectedCard+1] = i
        end
    end

    if #selectedCard == 0 then
        return
    end
    self:sendShuoHua(SERVER_Show3, selectedCard)
    self.is_shuohua = false
    self:setLiangSanVisible(false)
    self.NodePlayer1:getChildByName("tWait"):setVisible(true)
end

-- 扎股
function ZGZScene:btnZhaGuCallBack()
    print('扎股')
    self:sendShuoHua(SERVER_ZhaGu, nil)

    self.is_shuohua = false
    self:setLiangSanVisible(false)
    self.NodePlayer1:getChildByName("tWait"):setVisible(true)
end

-- 方块3
function ZGZScene:btnDiamond3CallBack()
    print('方块3')
    if self.zhuo_hong_san then return end
    self.selectedCard           = self.selectedCard or {}
    self.selectedCard[DIAMOND3] = not self.selectedCard[DIAMOND3]
    -- 6人模式有双三时要么不亮三要么亮双三
    if self.people_num == 6 and self.bHasDoubleR3 then
        self.selectedCard[HEART3] = self.selectedCard[DIAMOND3]
        self.btnHeart3:getChildByName('ImgSelected'):setVisible(self.selectedCard[HEART3])
        if self.isStyle2 then
            local exist = nil
            for cii, cid in ipairs(self.sel_list) do
                if HEART3 == cid then
                    exist = cii
                    break
                end
            end
            for i, v in ipairs(self.hand_card_list[1]) do
                if v.card_id == HEART3 then
                    local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                    if self.selectedCard[HEART3] then
                        self.sel_list[#self.sel_list+1] = v.card_id
                        v:setPositionY(pos.y+30)
                    else
                        if exist then
                            v:setPositionY(pos.y)
                            table.remove(self.sel_list, exist)
                        end
                    end
                end
            end
        end
    end

    if self.bHasBlack3 and self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
        -- 并且有黑三且没选择红三   没话
        if self.bHasDoubleR3 then
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)
            self.btnSurrender:setVisible(true)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnSilence:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
        end
    elseif self.bHasDoubleR3 then
        -- 有两个红三 亮三   没话 认输

        self.btnSurrender:setVisible(true)
        self.btnSilence:setVisible(true)
        self.btnShow3:setVisible(true)

        self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
        self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
        self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
    else
        -- 勾选了红三 没话   亮三
        self.btnSilence:setVisible(true)
        self.btnShow3:setVisible(true)
        self.btnZhaGu:setVisible(false)

        self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
        self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
    end
    self.btnDiamond3:getChildByName('ImgSelected'):setVisible(self.selectedCard[DIAMOND3])
end

-- 梅花3
function ZGZScene:btnClub3CallBack()
    print('梅花3')
    self.selectedCard        = self.selectedCard or {}
    self.selectedCard[CLUB3] = not self.selectedCard[CLUB3]

    self.btnClub3:getChildByName('ImgSelected'):setVisible(self.selectedCard[CLUB3])

    if self.bHasSingleR3 then
        if self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
            -- 只有一个红三且未选择   没话
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))

        else
            if self.isBLFKS and self.selectedCard[DIAMOND3] then
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnShow3:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
            else
                -- 没话 亮三
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        end
    elseif self.bHasNotR3 then
    -- 没有红三
        if self.selectedCard[CLUB3] or self.selectedCard[SPADE3] then
            -- 勾选了黑三   没话 亮三
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(true)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            --self.btnZhaGu:setPosition(cc.p(self.btnRightPosX,self.btnRightPosY))
        else
            -- 一个都没勾选   没话
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(true)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            --self.btnShow3:setPosition(cc.p(self.btnMidPosX,self.btnMidPosY))
            self.btnZhaGu:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        end
    elseif self.bHasDoubleR3 then
        if self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
            -- 没有勾选红三  没话 投降
            self.btnSurrender:setVisible(true)
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            --self.btnShow3:setPosition(cc.p(self.btnMidPosX,self.btnMidPosY))
            self.btnSilence:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            if self.isBLFKS and self.selectedCard[DIAMOND3] then
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            else
                -- 投降 亮3(可亮一张红) 没话
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        end
    end

end

-- 红桃3
function ZGZScene:btnHeart3CallBack()
    print('红桃3')
    self.selectedCard         = self.selectedCard or {}
    self.selectedCard[HEART3] = not self.selectedCard[HEART3]
    -- 6人模式要么有双三时要么不亮三要么亮双三
    if self.people_num == 6 and self.bHasDoubleR3 then
        self.selectedCard[DIAMOND3] = self.selectedCard[HEART3]
        self.btnDiamond3:getChildByName('ImgSelected'):setVisible(self.selectedCard[DIAMOND3])

        if self.isStyle2 then
            local exist = nil
            for cii, cid in ipairs(self.sel_list) do
                if DIAMOND3 == cid then
                    exist = cii
                    break
                end
            end
            for i, v in ipairs(self.hand_card_list[1]) do
                if v.card_id == DIAMOND3 then
                    local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                    if self.selectedCard[DIAMOND3] then
                        self.sel_list[#self.sel_list+1] = v.card_id
                        v:setPositionY(pos.y+30)
                    else
                        if exist then
                            v:setPositionY(pos.y)
                            table.remove(self.sel_list, exist)
                        end
                    end
                end
            end
        end
    end

    if self.bHasBlack3 and self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
        -- 并且有黑三且没选择红三   没话
        if self.bHasDoubleR3 then
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)
            self.btnSurrender:setVisible(true)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnSilence:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
        end
    elseif self.bHasDoubleR3 then
        if (self.isBLFKS or self.zhuo_hong_san) and self.selectedCard[DIAMOND3] then
            self.btnSurrender:setVisible(true)
            self.btnSilence:setVisible(false)
            self.btnShow3:setVisible(true)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            -- 有两个红三 亮三   没话 认输

            self.btnSurrender:setVisible(true)
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(true)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
            self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        end
    else
        if self.isBLFKS and self.selectedCard[DIAMOND3] then
            self.btnZhaGu:setVisible(false)
            self.btnSilence:setVisible(false)
            self.btnShow3:setVisible(true)

            --self.btnSurrender:setPosition(cc.p(self.btnLeftPosX,self.btnLeftPosY))
            self.btnShow3:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
        else
            -- 勾选了红三 没话   亮三
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(true)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        end
    end
    self.btnHeart3:getChildByName('ImgSelected'):setVisible(self.selectedCard[HEART3])
end

-- 黑桃3
function ZGZScene:btnSpade3CallBack()
    print('黑桃3')
    self.selectedCard = self.selectedCard or {}
    --if self.bHasSingleR3 and self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then return end

    self.selectedCard[SPADE3] = not self.selectedCard[SPADE3]
    self.btnSpade3:getChildByName('ImgSelected'):setVisible(self.selectedCard[SPADE3])

    if self.bHasSingleR3 then
        if self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
            -- 只有一个红三且未选择   没话
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
        else
            if self.isBLFKS and self.selectedCard[DIAMOND3] then
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnShow3:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
            else
                -- 没话 亮三
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)
                self.btnZhaGu:setVisible(false)

                self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        end
    elseif self.bHasNotR3 then
    -- 没有红三
        if self.selectedCard[CLUB3] or self.selectedCard[SPADE3] then
            -- 勾选了黑三   没话 亮三
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(true)
            self.btnZhaGu:setVisible(false)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            --self.btnZhaGu:setPosition(cc.p(self.btnRightPosX,self.btnRightPosY))
        else
            -- 一个都没勾选   没话
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(true)

            self.btnSilence:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnZhaGu:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        end
    elseif self.bHasDoubleR3 then
        if self.selectedCard and (not self.selectedCard[HEART3] and not self.selectedCard[DIAMOND3])then
            -- 没有勾选红三  没话 投降
            self.btnSurrender:setVisible(true)
            self.btnSilence:setVisible(true)
            self.btnShow3:setVisible(false)
            self.btnZhaGu:setVisible(false)

            self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
            self.btnSilence:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
        else
            if self.isBLFKS and self.selectedCard[DIAMOND3] then
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(false)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            else
                -- 投降 亮3(可亮一张红) 没话
                self.btnSurrender:setVisible(true)
                self.btnSilence:setVisible(true)
                self.btnShow3:setVisible(true)

                self.btnSurrender:setPosition(cc.p(self.btnLeftPosX, self.btnLeftPosY))
                self.btnSilence:setPosition(cc.p(self.btnMidPosX, self.btnMidPosY))
                self.btnShow3:setPosition(cc.p(self.btnRightPosX, self.btnRightPosY))
            end
        end
    end
end

-- 出牌
function ZGZScene:btnChuPaiCallBack()
    print('出牌')
    if #self.sel_list < 0 then
        self:sendOutCards()
    else
        self:sendOutCards(self.sel_list)
    end
    self.panOprCard:setVisible(false)
    self.can_opt = false
end

-- 不出
function ZGZScene:btnBuChuCallBack()
    print('不出')
    self:sendOutCards()
    self.panOprCard:setVisible(false)
    self.ImgDaBuQi:setVisible(false)
    self.can_opt = false
end

-- 提示更新
function ZGZScene:updateHintList()
    if not self.last_out_card_client_index then
        return
    end
    local pre_card   = self.last_out_card[self.last_out_card_client_index]
    local next_cards = {}
    for i, v in ipairs(self.hand_card_list[1]) do
        next_cards[#next_cards + 1] = v.card_id
    end
    local rtn      = nil
    self.hint_list = {}
    self.cur_hint  = 0
    if pre_card ~= 0 then
        local pre_cards_id = {}
        for __, pre in ipairs(pre_card) do
            pre_cards_id[#pre_cards_id + 1] = pre.card_id
        end
        ZGZLogic:SearchOutCard(next_cards, pre_cards_id, self.hint_list, self.bShowDiamond3, self.people_num)
    end
end

-- 提示
function ZGZScene:btnTiShiCallBack()

    --self:updateHintList()

    print('提示')
    local tishi_cards = nil
    if self.hint_list and #self.hint_list > 0 then
        self.cur_hint = (self.cur_hint or 0) + 1
        if self.cur_hint > #self.hint_list then
            self.cur_hint = 1
        end
        tishi_cards = self.hint_list[self.cur_hint]
    end
    if not tishi_cards or #tishi_cards <= 0 then
        -- self:sendOutCards()
        -- self.panOprCard:setVisible(false)
    else
        commonlib.echo(self.sel_list)
        for i, v in ipairs(self.hand_card_list[1]) do
            for cii, cid in ipairs(self.sel_list) do
                if v.card_id == cid then
                    table.remove(self.sel_list, cii)
                    local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i, self.paiShape, self.isStyle2)
                    v:setPositionY(pos.y)
                    break
                end
            end
            for _, cid in ipairs(tishi_cards) do
                if v.card_id == cid then
                    self.sel_list[#self.sel_list+1] = cid
                    local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                    v:setPositionY(pos.y+30)
                    --v:setPositionY(hand_card_pos[1].y+30)
                    break
                end
            end
        end
        commonlib.echo(self.sel_list)
        self.btnChuPai:setTouchEnabled(true)
        self.btnChuPai:setBright(true)
    end
end

function ZGZScene:setBiaoVisible(index, visible, time)
    self.Biao:stopAllActions()
    self.Biao:setVisible(visible)
    if not visible or index < 1 or index > 6 then
        return
    end
    if index == 1 then
        self.Biao:setVisible(false)
    end
    time = time or 15
    time = math.min(time, 15)
    self.Biao:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
        self.Biao.lab:setString(string.format("%02d", time))
        if time <= 5 and time >=3 then
            AudioManager:playDWCSound("sound/timeup_alarm.mp3")
        end
        if time <= 0 then
            self.Biao:stopAllActions()
        end
        time = time - 1
    end), cc.DelayTime:create(1))))
    self.Biao:setPosition(self.NodeTimesPos[index])
end

function ZGZScene:InitNodeTimes()
    self.NodeTimesPos = {}
    for client_index = 1 , 6 do
        local NodeTime                  = ccui.Helper:seekWidgetByName(self.player_ui[client_index], "NodeTime")
        local posx,posy                 = NodeTime:getPosition()
        local worldPos                  = self.player_ui[client_index]:convertToWorldSpace(cc.p(posx,posy))
        local layerpos                  = self:convertToNodeSpace(worldPos)
        self.NodeTimesPos[client_index] = layerpos
    end
end

function ZGZScene:setBeiShu(bei_shu)
    if bei_shu then
        if self.isStyle2 and self.FntBeiShu then
            self.FntBeiShu:setString(tostring(bei_shu))
        else
            self.TextBeiShu:setString('倍数:' .. tostring(bei_shu))
        end
    end
end

function ZGZScene:onRcvOutCard(rtn_msg)
    --dump(rtn_msg)
    self:resetData()
    print('PlayerData.MyServerIndex', PlayerData.MyServerIndex)
    local index = rtn_msg.index
    if not index then
        return
    end
    local out_card_data         = rtn_msg.out_card_data
    local client_out_card_index = PlayerData.getPlayerClientIDByServerID(index)
    local cur_user              = rtn_msg.cur_user
    local next_index            = 0
    if cur_user >=1 and cur_user <= self.people_num then
        next_index = PlayerData.getPlayerClientIDByServerID(cur_user)
    end

    local out_all_index = nil
    -- 设置谁出的牌
    local out_all_card  = false

    if rtn_msg.chu_wan == 1 then
        if next_index == 1 and not self.is_playback then
            out_all_card = true
        end
    end

    if self:isAllOutCard(index,cur_user) then
        out_all_index = self:isAllOutCard(index,cur_user)
        for _, v in ipairs(out_all_index) do
            local client_out_allcard_index = PlayerData.getPlayerClientIDByServerID(v)
            self:setOutCardRemoveLastOutCard(client_out_allcard_index)
        end
    end

    -- 出玩牌后标记头游尾游
    if rtn_msg.now_chu_wan then
        self.rank_num = self.rank_num + 1
        self:setRankVisible(client_out_card_index, self.rank_num)
    end

    if out_card_data and #out_card_data ~= 0 then
        local card_typ = ZGZLogic:GetCardType(out_card_data, self.bShowDiamond3, self.people_num)
        local prefix   = self:getSoundPrefix(client_out_card_index)
        local fix      = ".mp3"
        if card_typ == 6 then
            self:playRocketAni()
            AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/huojian_wangzha" .. fix)
        elseif card_typ == 3 or card_typ == 4 or card_typ == 5 then
            self:playBombAni(client_out_card_index)
            if card_typ == 5 then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/huojian_dui3" .. fix)
            else
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/zhadan" .. fix)
            end
        elseif card_typ == 2 then
            local vl = rtn_msg.out_card_data[1] % 16
            if vl < 3 then
                vl = vl + 13
            end
            AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/dui" .. vl .. fix)
        elseif  card_typ == 1 then
            local vl = rtn_msg.out_card_data[1] % 16
            if rtn_msg.out_card_data[1] >= 78 then
                vl = vl + 2
            elseif vl < 3 then
                vl = vl + 13
            end
            if rtn_msg.out_card_data[1] == 3 then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/fangkuai_3" .. fix)
            elseif rtn_msg.out_card_data[1] == 35 then
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/hongtao_3" .. fix)
            else
                AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/" .. vl .. fix)
            end
        end

        self:setOutCardToDesk(client_out_card_index, out_card_data)

        self.last_out_card_client_index = PlayerData.getPlayerClientIDByServerID(index)

        for i , v in pairs(out_card_data) do
            if v == DIAMOND3 then
                self:setImg3Visible(client_out_card_index, 'ImgDiamond', true)
            elseif v == HEART3 then
                self:setImg3Visible(client_out_card_index, 'ImgHeart', true)
            elseif v == CLUB3 then
                self:setImg3Visible(client_out_card_index, 'ImgClub', true)
            elseif v == SPADE3 then
                self:setImg3Visible(client_out_card_index, 'ImgSpade', true)
            end
        end

        if not self.isHSPR then
            if rtn_msg.shen_fen then
                if rtn_msg.shen_fen == 1 then
                    self:canAddSanNum(client_out_card_index)
                    self:setImgGroupTexture(client_out_card_index, player_tag_texture_path[ThreeTeam])
                else
                    self:setImgGroupTexture(client_out_card_index, player_tag_texture_path[GuTeam])
                end
            end
            if #self.sanjia_num == 2 then
                self:setAllSanjia()
            end
        end
        -- 出了红三或方三后身份标识变为3
        if self:hasHeart3(out_card_data) or self:hasDiamond3(out_card_data) then
            self:setImgGroupVisible(client_out_card_index, true)
            self:setImgGroupTexture(client_out_card_index, player_tag_texture_path[ThreeTeam])
            -- 插入未记录的红三
            if #self.sanjia < 2 then
                local san = {}
                for _, v in ipairs(out_card_data) do
                    if v == DIAMOND3 or v == HEART3 then
                        san[#san + 1] = v
                    end
                end
                if #san > 0 then
                    for _, v in ipairs(san) do
                        local canAddSan = true
                        if #self.sanjia >0 then
                            for _, vv in ipairs(self.sanjia) do
                                if v == vv.card then
                                    canAddSan = false
                                end
                            end
                        end
                        if canAddSan then
                            self.sanjia[#self.sanjia + 1] = {index = client_out_card_index, card = v}
                        end
                    end
                end
            end

            if #self.sanjia == 2 then
                for i = 1, 6 do
                    local show3 = false
                    for _, v in ipairs(self.sanjia) do
                        if i == v.index then
                            show3 = true
                        end
                    end
                    if show3 then
                        self:setImgGroupTexture(i, player_tag_texture_path[ThreeTeam])
                    else
                        self:setImgGroupTexture(i, player_tag_texture_path[GuTeam])
                    end
                end
            end
            self:canAddSanNum(client_out_card_index)
        end
        -- 剩牌显示
        if rtn_msg.left_num then
            self:setFntLastCardNum(client_out_card_index,rtn_msg.left_num)
            if rtn_msg.left_num <= 2 then
                ccui.Helper:seekWidgetByName(self.player_ui[client_out_card_index], "FntLastCardNum"):setVisible(true)
            end
        end
    elseif not rtn_msg.out_card_data or #rtn_msg.out_card_data == 0 then
        --self:showOutCardAni(client_out_card_index)
        local prefix = self:getSoundPrefix(client_out_card_index)
        AudioManager:playDWCSound("sound/zgz/" .. prefix .. "/pass.mp3")
        self:setImgBuChuVisible(client_out_card_index, true)
    end

    if cur_user then
        if cur_user == PlayerData.MyServerIndex then
            self.can_opt = true
            self.panOprCard:setVisible(true)
        end
        local cur_opr_client_index = PlayerData.getPlayerClientIDByServerID(cur_user)
        if cur_user ~= 65535 then
            self:setBiaoVisible(cur_opr_client_index, true)
        end
    end

    if next_index ~= 0 then
        if self.last_out_card[next_index] ~= 0 then
            for __, v in ipairs(self.last_out_card[next_index]) do
                v:removeFromParent(true)
            end
            self.last_out_card[next_index] = 0
        elseif self.last_out_card[next_index] == 0 then
            self:setImgBuChuVisible(next_index, false)
        end
    end

    if next_index ~= 0 and not self.is_playback then
        if next_index == 1 then
            if out_all_card then
                self:resetOperPanel(100)
            else
                if self.last_out_card_client_index and next_index ~= self.last_out_card_client_index then
                    self:updateHintList()
                    self:resetOperPanel(101)
                else
                    self:resetOperPanel(100)
                end
            end
        end
    end
end

function ZGZScene:onRcvPass(rtn_msg)

end

function ZGZScene:sendOutCards(cards, msgid)
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
    self.can_opt          = false
end

function ZGZScene:setOutCardRemoveLastOutCard(client_index)
    if not client_index then
        return
    end
    local last_out_card = self.last_out_card[client_index]
    if not last_out_card or last_out_card == 0 then
        return
    end
    for i, v in ipairs(last_out_card) do
        if v ~= 0 then
            v:removeFromParent(true)
        end
    end
    self.last_out_card[client_index] = 0
end

function ZGZScene:setOutCardToDesk(index, out_card_data)
    -- dump(out_card_data)
    local outCardNum = #out_card_data
    local out_card   = {}
    if index == 1 then
        for ci, card_id in ipairs(out_card_data) do
            local myscale = 0.5
            if self.isRetroCard then
                myscale = 0.7
            end
            for i, v in ipairs(self.hand_card_list[index]) do
                if v.card_id == card_id then
                    out_card[#out_card + 1] = v
                    table.remove(self.hand_card_list[index], i)
                    local desPos = PKCommond.calOutCarPos(index, outCardNum, ci, nil, self.isStyle2)
                    --v:runAction(cc.Spawn:create(cc.ScaleTo:create(0.075, 0.5),cc.MoveTo:create(0.075, desPos)))
                    v:setPosition(desPos)
                    v:setScale(myscale)
                    v:setRotation(0)
                    v:setLocalZOrder(ci+10)
                    break
                end
            end
            for i, v in ipairs(self.sel_list) do
                if v== card_id then
                    table.remove(self.sel_list, i)
                end
            end
        end
        local handCardNum = #(self.hand_card_list[index])
        for i, v in ipairs(self.hand_card_list[index]) do
            local desPos,r  = PKCommond.calHandCardPos(index, handCardNum, i,self.paiShape, self.isStyle2)
            v:setPosition(desPos)
            v:setRotation(r)
        end
    else
        for ci, card_id in ipairs(out_card_data) do
            local card       = PKCommond.getCardById(1, true, self.isRetroCard)
            local posx, posy = self.player_ui[index]:getPosition()
            card:setRotation(0)
            card:setPosition(posx,posy)
            self.node:addChild(card)
            card.card_id = card_id
            out_card[#out_card + 1] = card
            card.card = PKCommond.getCardById(card_id, nil, self.isRetroCard)
            card.card:setPosition(cc.p(card:getContentSize().width / 2, card:getContentSize().height / 2))
            if self.isRetroCard then
                card:setScale(0.7)
            else
                card:setScale(0.5)
            end
            card:addChild(card.card)
            local desPos = PKCommond.calOutCarPos(index, outCardNum, ci, nil, self.isStyle2)
            if not self.isStyle2 then
                if index == 4 or index == 5 then
                    desPos.y = desPos.y +10
                end
            end
            --log('坐标')
            --dump(desPos)
            --card:runAction(cc.MoveTo:create(0.05, desPos))
            card:setPosition(desPos)
            card:setLocalZOrder(ci)
        end
    end
    self.last_out_card        = self.last_out_card or {0 ,0, 0, 0, 0}
    self.last_out_card[index] = out_card
end

function ZGZScene:showLeftHandCard(msg)
    self:removeCardShadow()
    for index, card in pairs(msg) do
        local out_card_num = #card
        local out_card = {}
        if index == 1 and #card > 0 then
            local myscale = 0.6
            if self.isRetroCard then
                myscale = 0.7
            end
            for i, v in ipairs(self.hand_card_list[index]) do
                out_card[#out_card + 1] = v
                local desPos = PKCommond.calOutCarPos(index, out_card_num, i, nil, self.isStyle2)
                if self.isStyle2 then
                    desPos.y = desPos.y - 70
                else
                    if self.people_num == 5 then
                        desPos.y = desPos.y - 50
                    else
                        desPos.y = desPos.y - 70
                    end
                end
                v:runAction(cc.Spawn:create(cc.ScaleTo:create(0.075, myscale), cc.MoveTo:create(0.075, desPos)))
                v:setRotation(0)
                v:setLocalZOrder(i+100)
            end
        else
            if #card > 0 then
                for ci, card_id in ipairs(card) do
                    local pai_card = PKCommond.getCardById(1, true, self.isRetroCard)
                    pai_card:setRotation(0)
                    self.node:addChild(pai_card)
                    pai_card.card_id        = card_id
                    out_card[#out_card + 1] = pai_card
                    pai_card.cards          = PKCommond.getCardById(card_id, nil, self.isRetroCard)
                    local posx, posy        = self.player_ui[index]:getPosition()
                    pai_card.cards:setPosition(cc.p(pai_card:getContentSize().width / 2, pai_card:getContentSize().height / 2))
                    pai_card:addChild(pai_card.cards)
                    if self.isRetroCard then
                        pai_card:setScale(0.7)
                    else
                        pai_card:setScale(0.5)
                    end
                    local desPos = PKCommond.calOutCarPos(index, out_card_num, ci, nil, self.isStyle2)
                    if not self.isStyle2 then
                        if index == 4 or index == 5 then
                            desPos.y = desPos.y + 10
                        end
                    end
                    pai_card:runAction(cc.MoveTo:create(0.05, desPos))
                    if index == 3 then
                        pai_card:setLocalZOrder(ci + 10)
                    else
                        pai_card:setLocalZOrder(ci)
                    end
                end
            end
        end
        self.hand_card_list[index] = {}
        self.last_out_card[index]  = self.last_out_card[index] or {0, 0, 0, 0, 0, 0}
        if #out_card ~= 0 then
            self.last_out_card[index] = out_card
        end
    end
end

function ZGZScene:resetOperPanel(oper, msgid)
    if not oper then
        self.panOprCard:setVisible(false)
        self.panOprCard.msgid = nil
    else
        if 100 <= oper then
            if (oper == 101) and (not self.hint_list or #self.hint_list <= 0) then
                self.panOprCard:setVisible(true)
                self.btnTiShi:setVisible(false)
                self.btnChuPai:setVisible(false)
                self.btnBuChu:setVisible(true)
                self.ImgDaBuQi:setVisible(true)
                self.btnBuChu:setPositionX(235.00)
            else
                self.panOprCard:setVisible(true)
                self.btnChuPai:setVisible(true)
                self.btnBuChu:setVisible(100 ~= oper)
                self.btnTiShi:setVisible(100 ~= oper)
                self.btnBuChu:setPositionX(-47.00)
                self.ImgDaBuQi:setVisible(false)
                local x,y = self.btnTiShi:getPosition()
                if not self.btnTiShi:isVisible() then
                    self.btnChuPai:setPosition(x,y)
                else
                    self.btnChuPai:setPosition(cc.p(517.00, 49.2))
                end
                local boCanOutCard = self:canOutCard()
                if boCanOutCard and self:isMustChuCard() then
                    self.btnChuPai:setTouchEnabled(true)
                    self.btnChuPai:setBright(true)
                else
                    self.btnChuPai:setTouchEnabled(false)
                    self.btnChuPai:setBright(false)
                end
            end
        else
            self.panOprCard:setVisible(false)
        end
        self.panOprCard.msgid = msgid
    end
end

function ZGZScene:resetData()
    if self.mustChuWu then
        self.mustChuWu = nil
    end
end

-- 当首出必须出红桃5时，判断选中的牌中有没有红桃5
function ZGZScene:isMustChuCard()
    if self.mustChuWu then
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

function ZGZScene:playBombAni(direct)
    local spineFile  = 'ui/qj_ddz_ani/zhadan/zhadan'
    local sprEmotion = cc.Sprite:create("ui/qj_ddz_ani/zhadan/zd.png")
    local posx, posy = self.player_ui[direct]:getPosition()
    AudioManager:playDWCSound("sound/game/zhdan.mp3")
    self:addChild(sprEmotion,300)
    sprEmotion:setPosition(posx, posy)
    sprEmotion:setScale(0.7)

    local position = self.NodeOutCard[direct]

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
            moveto1,fadeout1,callfunc
                ))
end

function ZGZScene:playRocketAni()
    local spineFile = 'ui/qj_ddz_ani/huojian/huojian'
    AudioManager:playDWCSound("sound/game/huojian.mp3")
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode,100)

        skeletonNode:runAction(cc.Sequence:create(
            cc.MoveTo:create(1, cc.p(g_visible_size.width / 2, g_visible_size.height)),
            cc.RemoveSelf:create()))

end

function ZGZScene:showOutCardAni(direct)

    local sp       = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_socre_noout.png")
    local position = self.NodeOutCard[direct]
    sp:setPosition(position)
    self:addChild(sp, 10000)

    sp:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(0.3), cc.FadeOut:create(0.1), cc.CallFunc:create(function()
        sp:removeFromParent(true)
    end)))
end

function ZGZScene:playKaiju()
    spineFile = 'ui/qj_mj/huSpine/kaiju'

    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)

    skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.RemoveSelf:create()))
end

function ZGZScene:playWinAni()
    local spineFile = 'ui/qj_ddz_ani/ddzWin/shengli'

    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    skeletonNode:setAnimation(0, "animation", false)

    skeletonNode:setScale(1.0)
    local windowSize = cc.Director:getInstance():getWinSize()
    skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
    self:addChild(skeletonNode, 100)
    skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(1.5),cc.RemoveSelf:create()))
end

-- 插入未记录的三家的客户端index
function ZGZScene:canAddSanNum(client_out_card_index)
    local canAddSanNum = true
    for _,v in ipairs(self.sanjia_num) do
        if client_out_card_index == v then
            canAddSanNum = false
        end
    end
    if canAddSanNum then
        self.sanjia_num[#self.sanjia_num + 1] = client_out_card_index
    end
end

-- 设置所有玩家的身份
function ZGZScene:setAllSanjia()
    for i = 1, 6 do
        local show3 = false
        for _, v in ipairs(self.sanjia_num) do
            if i == v then
                show3 = true
            end
        end
        if show3 then
            self:setImgGroupTexture(i, player_tag_texture_path[ThreeTeam])
        else
            self:setImgGroupTexture(i, player_tag_texture_path[GuTeam])
        end
    end
end

-- 判断下家是否已经出完牌，若出完牌，取到下家的index，用来清除其桌子上的牌
-- @index 当前出牌的人的index
-- @next_index 下一个操作的的玩家的index(会跳过已出完牌的玩家)
function ZGZScene:isAllOutCard(index,next_index)
    if next_index == 65535 then
        return false
    end
    local count        = nil
    local allout_index = {}
    local player_index = nil
    if next_index < index then
        count = next_index + self.people_num - index
    else
        count = next_index - index
    end
    if count <= 1 or count > self.people_num then
        return false
    end

    for i=1, count - 1 do
        player_index = index + i
        if player_index > self.people_num then
            player_index = player_index - self.people_num
        end
        allout_index[#allout_index + 1] = player_index
    end
    return allout_index
end

function ZGZScene:getLastSpeekIndex(_index)
    if not _index then return false end
    return _index == 1 and self.people_num or _index - 1
end

function ZGZScene:setCardShadow()
    for i, v in ipairs(self.hand_card_list[1]) do
        if self.zhuo_hong_san then
            if v.card_id ~= HEART3 then
                v.card:setColor(cc.c3b(100, 100, 100))
            end
        else
            if self.people_num == 6 then
                if v.card_id ~= DIAMOND3 and v.card_id ~= HEART3 then
                    v.card:setColor(cc.c3b(100, 100, 100))
                end
            else
                if v.card_id ~= DIAMOND3 and v.card_id ~= CLUB3 and v.card_id ~= HEART3 and v.card_id ~= SPADE3 then
                    v.card:setColor(cc.c3b(100, 100, 100))
                end
            end
        end
    end
end

function ZGZScene:removeCardShadow()
    for i,v in ipairs(self.hand_card_list[1]) do
        if v.card then
            v.card:setColor(cc.c3b(255, 255, 255))
        end
    end
end

function ZGZScene:removeSelectCard()
    for i, v in ipairs(self.hand_card_list[1]) do
        for cii, cid in ipairs(self.sel_list) do
            if v.card_id == cid then
                table.remove(self.sel_list, cii)
                local pos,r = PKCommond.calHandCardPos(1, #self.hand_card_list[1], i,self.paiShape, self.isStyle2)
                v:setPositionY(pos.y)
                break
            end
        end
    end
end

function ZGZScene:peopleNumErroJoinRoomAgain()
    gt.uploadErr('zgz peopleNumErroJoinRoomAgain')
    local net_msg = {
        cmd =NetCmd.C2S_JOIN_ROOM_AGAIN,
        room_id=self.desk,
    }
    ymkj.SendData:send(json.encode(net_msg))
end

return ZGZScene