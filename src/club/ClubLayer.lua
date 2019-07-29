require('club.ClubHallUI')

local ErrStrToClient = require('common.ErrStrToClient')

local ClubLayer = class("ClubLayer",function()
    return cc.Layer:create()
end)

local SHOUMING_CARD_ZORDER = 20

function ClubLayer:ctor(args)
    self.args = args
    self.mainScene = args.mainScene
    self:setName("ClubLayer")

    self:createLayerMenu()
    self:registerEventListener()
    if not self.args.rtn_msg then
        self:onReconnect()
        local ClubData = require('club.ClubData')
        self.clubs = ClubData.getClubs()
        if self.clubs and 0 ~= #self.clubs then
            if GameGlobal.is_los_club_id then
                local club_id = GameGlobal.is_los_club_id
                self.data = ClubData.getData(club_id)
                GameGlobal.is_los_club_id = nil
            end

            if not self.data then
                local club = self.clubs[1]
                if not club then
                    return
                end
                local club_id = club.club_id
                if not club_id then
                    return
                end
                self.data = ClubData.getData(club_id)
            end
            -- log('SSSSSS ')
        end
        -- print('-----------XXXXXXXXXXXXXXxxxxxxxxxx----------------------')
        -- print('----------------------------------')
        -- -- dump(self.clubs)
        -- -- dump(self.data)
        -- print('----------------------------------')
        -- print('-----------XXXXXXXXXXXXXXxxxxxxxxxx----------------------')
        if not self.data then
            return
        end
        self.args.rtn_msg = self.data
    end
    -- print('-----------XXXXXXXXXXXXXXxxxxxxxxxx----------------------')
    -- -- dump(self.data)
    -- print('-----------XXXXXXXXXXXXXXxxxxxxxxxx----------------------')
    self:initClub(self.args.rtn_msg)
    self:refreshLayer(true)
    self:refreshRodHot(self.args.rtn_msg.hasPlayerApplyJoin and self.args.rtn_msg.hasPlayerApplyJoin == 1)

    self:memoryLog()

    self:enableNodeEvents()
end

function ClubLayer:onReconnect()
    -- print('重连亲友圈数据 START')
    local input_msg = {
        cmd=NetCmd.C2S_INFO_MAX,
        isGetClubInfo = true,
    }
    ymkj.SendData:send(json.encode(input_msg))
    -- print('重连亲友圈数据 END')
end

function ClubLayer:registerEvent()
    local events = {
        {
            eType = EventEnum.onReconnect,
            func = handler(self,self.onReconnect),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function ClubLayer:unregisterEvent()
    for i,v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function ClubLayer:onEnter()
    self:registerEvent()
    -- print('进入亲友圈')
end

function ClubLayer:memoryLog()
    if GameGlobal.C2S_GET_USER_JU_RECORDS_log_ju_ids then
        if not self:getChildByName("ClubLogLayer") then
            self:onSelEvent('log')
        end
    end
end

function ClubLayer:onExit()
    self:stopAllDownHead()
    self:unregisterEvent()
    self:unregisterEventListener()
end

function ClubLayer:copyTable(oldData, newData)
    for k, v in pairs(newData or {}) do
        oldData[k] = v
    end
    return oldData
end

function ClubLayer:registerEventListener()
    local NETMSG_LISTENERS = {
        [NetCmd.S2C_CLUB_JIESAN_ROOM]           = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_ADD_ROOM]              = handler(self, self.onRcvMsg),
        [NetCmd.S2C_GET_CLUB_LIST]              = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_MODIFY]                = handler(self, self.onRcvMsg),
        [NetCmd.S2C_ROOM_STATUS]                = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_CLOSE_ROOM]            = handler(self, self.onRcvMsg),
        [NetCmd.S2C_LEAVE_ROOM]                 = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_CHANGE_ROOM]           = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_SYNC_CARD]             = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_ROOM_STATUS]           = handler(self, self.onRcvMsg),
        [NetCmd.S2C_CLUB_USER_TYPE]             = handler(self, self.onRcvMsg),
    }
    for k, v in pairs(NETMSG_LISTENERS) do
        gt.addNetMsgListener(k, v)
    end

    -- local function onNodeEvent(event)
    --     if event == "exitTransitionStart" then
    --         local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    --         local tLastTime = ccui.Helper:seekWidgetByName(Panel_bottom,"tLastTime")
    --         tLastTime:stopAllActions()
    --         self:unregisterEventListener()
    --     end
    -- end
    -- self:registerScriptHandler(onNodeEvent)
end

function ClubLayer:unregisterEventListener()
    local LISTENER_NAMES = {
        [NetCmd.S2C_CLUB_JIESAN_ROOM]           = handler(self, self.onRcvClubJieSanRoom),
        [NetCmd.S2C_CLUB_ADD_ROOM]              = handler(self, self.onRcvClubAddRoom),
        [NetCmd.S2C_GET_CLUB_LIST]              = handler(self, self.onRcvGetClubList),
        [NetCmd.S2C_CLUB_MODIFY]                = handler(self, self.onRcvClubModify),
        [NetCmd.S2C_ROOM_STATUS]                = handler(self, self.onRcvRoomStatus),
        [NetCmd.S2C_CLUB_CLOSE_ROOM]            = handler(self, self.onRcvClubCloseRoom),
        [NetCmd.S2C_LEAVE_ROOM]                 = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_CLUB_CHANGE_ROOM]           = handler(self, self.onRcvClubChangeRoom),
        [NetCmd.S2C_CLUB_SYNC_CARD]             = handler(self, self.onRcvClubSyncCard),
        [NetCmd.S2C_CLUB_ROOM_STATUS]           = handler(self, self.onRcvClubRoomStatus),
        [NetCmd.S2C_CLUB_USER_TYPE]             = handler(self, self.onRcvClubUserType),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function ClubLayer:delayReadNetData()
    if self.data then
        self.net_data = self.net_data or {}
        for i , v in ipairs(self.net_data) do
            local rtn_msg = v.rtn_msg
            self:onRcvMsg(rtn_msg)
        end
        self.net_data = {}
    end
end

function ClubLayer:onRcvMsg(rtn_msg)
    local NETMSG_LISTENERS = {
        [NetCmd.S2C_CLUB_JIESAN_ROOM]           = handler(self, self.onRcvClubJieSanRoom),
        [NetCmd.S2C_CLUB_ADD_ROOM]              = handler(self, self.onRcvClubAddRoom),
        [NetCmd.S2C_GET_CLUB_LIST]              = handler(self, self.onRcvGetClubList),
        [NetCmd.S2C_CLUB_MODIFY]                = handler(self, self.onRcvClubModify),
        [NetCmd.S2C_ROOM_STATUS]                = handler(self, self.onRcvRoomStatus),
        [NetCmd.S2C_CLUB_CLOSE_ROOM]            = handler(self, self.onRcvClubCloseRoom),
        [NetCmd.S2C_LEAVE_ROOM]                 = handler(self, self.onRcvLeaveRoom),
        [NetCmd.S2C_CLUB_CHANGE_ROOM]           = handler(self, self.onRcvClubChangeRoom),
        [NetCmd.S2C_CLUB_SYNC_CARD]             = handler(self, self.onRcvClubSyncCard),
        [NetCmd.S2C_CLUB_ROOM_STATUS]           = handler(self, self.onRcvClubRoomStatus),
        [NetCmd.S2C_CLUB_USER_TYPE]             = handler(self, self.onRcvClubUserType),
    }
    if NETMSG_LISTENERS[rtn_msg.cmd] then
        if rtn_msg.errno and rtn_msg.errno ~= 0 then
            commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or 'Unknown Error ' .. rtn_msg.errno)
        else
            self.net_data = self.net_data or {}
            if not self.data then
                local net_cell = {
                    cmd = rtn_msg.cmd,
                    rtn_msg = clone(rtn_msg),
                }
                table.insert(self.net_data,net_cell)
            else
                NETMSG_LISTENERS[rtn_msg.cmd](rtn_msg)
            end
        end
    end
end

function ClubLayer:onRcvClubJieSanRoom(rtn_msg)
    -- print('亲友圈解散 S')
    -- dump(rtn_msg)
    -- print('亲友圈解散 E')
    local club_id = rtn_msg.club_id
    if not club_id then
        return
    end
    local room_id = rtn_msg.room_id
    if not room_id then
        return
    end

    local ClubData = require('club.ClubData')
    ClubData.onRcvClubJieSanRoom(rtn_msg)
    self.data = ClubData.getData(self.data.club_info.club_id)

    -- 数据已存
    if club_id == self.data.club_info.club_id then
        -- 刷新房间信息
        self:refreshRoomInfo(room_id)
    end
end

function ClubLayer:onRcvClubAddRoom(rtn_msg)
    local ClubData = require('club.ClubData')
    if rtn_msg.params.qipai_type == "pk_pdk" and rtn_msg.params.isJDPDK then
        rtn_msg.params.qipai_type = "pk_jdpdk"
        rtn_msg.room_name = "经典"..rtn_msg.room_name
    end
    ClubData.onRcvClubAddRoom(rtn_msg)
    self.data = ClubData.getData(self.data.club_info.club_id)
    -- dump(rtn_msg)

    if rtn_msg.clubOpt == 2 then
        local club_id = rtn_msg.club_id
        if not club_id then
            return
        end
        local params = rtn_msg.params
        if not params then
            return
        end
        local room_id = params.room_id
        if not room_id then
            return
        end
        if self.data and self.data.club_info.club_id == club_id then
            -- 刷新房间信息
            self:refreshRoomInfo(room_id)
            local layer = self.mainScene:getChildByName("CreateLayer")
            if layer then
                layer:removeFromParent(true)
            end
            local ClubCreateJoin = self.mainScene:getChildByName('ClubCreateJoin')
            if ClubCreateJoin then
                ClubCreateJoin:removeFromParent()
            end
        end
    end
end

function ClubLayer:onRcvGetClubList(rtn_msg,client_self_refresh)
    -- print(client_self_refresh and '客户端自己先刷新' or '客户端同步服务器')
    local ClubData = require('club.ClubData')
    if not client_self_refresh then
        ClubData.onRcvGetClubList(rtn_msg)
    end
    self.clubs = ClubData.getClubs()
    self.data = ClubData.getData(self.data.club_info.club_id)

    if rtn_msg.clubs and #rtn_msg.clubs == 0 then
        self:exitLayer()
        return
    end

    self.clubs = rtn_msg.clubs

    local ownerClubs = nil
    for i , v in ipairs(self.clubs) do
        if v.club_id == gt.getData('uid') then
            ownerClubs = v
            table.remove(self.clubs,i)
            break
        end
    end
    if ownerClubs then
        table.insert(self.clubs,1,ownerClubs)
    end

    if self.mainScene then
        local layer = self.mainScene:getChildByName('CreateLayer')
        if layer then
            layer:removeFromParent()
        end
    end

    for i , v in ipairs(self.clubs) do
        if v.club_id == self.data.club_info.club_id then
            self.data.club_info = self:copyTable(self.data.club_info,v)
            break
        end
    end

    self:refreshMemStaus()

    self:refreshClubBoss()
    local layer = self:getChildByName('ClubCreateJoin')
    if layer then
        layer:refreshCreateJoinUi(self.clubs)
    end

    self:refreshClubList()

    local layer = self:getChildByName("ClubSetLayer")
    if layer then
        -- log('1111111111111111')
        layer:refreshSetUi(self.clubs,self.data)
    end

    self:refreshFangKa()

    self:refreshTime()
end

function ClubLayer:onRcvClubModify(rtn_msg)
    if not rtn_msg.errno or rtn_msg.errno == 0 then
        -- dump(rtn_msg)
        local ClubData = require('club.ClubData')
        ClubData.onRcvClubModify(rtn_msg)
        self.data = ClubData.getData(self.data.club_info.club_id)
        self.clubs = ClubData.getClubs()

        local club_id = self.data.club_info.club_id
        if (rtn_msg.isACWF == 0 or rtn_msg.isACWF == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isACWF = rtn_msg.isACWF
            self:refreshClubModify({"isACWF"})
        elseif (rtn_msg.isOpen == 0 or rtn_msg.isOpen == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isOpen = rtn_msg.isOpen
            self:refreshClubModify({"isOpen"})
        elseif (rtn_msg.isAKFK == 0 or rtn_msg.isAKFK == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isAKFK = rtn_msg.isAKFK
            self:refreshClubModify({"isAKFK"})
        elseif (rtn_msg.isAKZJ == 0 or rtn_msg.isAKZJ == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isAKZJ = rtn_msg.isAKZJ
        elseif (rtn_msg.isAllowCharge == 0 or rtn_msg.isAllowCharge == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isAllowCharge = rtn_msg.isAllowCharge
        elseif (rtn_msg.isFZB == 0 or rtn_msg.isFZB == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isFZB = rtn_msg.isFZB
            self:refreshClubModify({"isFZB"})
        elseif (rtn_msg.is4To32 == 0 or rtn_msg.is4To32 == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.is4To32 = rtn_msg.is4To32
        elseif (rtn_msg.isJZBQ == 0 or rtn_msg.isJZBQ == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isJZBQ = rtn_msg.isJZBQ
        elseif (rtn_msg.isJSAA == 0 or rtn_msg.isJSAA == 1) and club_id == rtn_msg.club_id then
            self.data.club_info.isJSAA = rtn_msg.isJSAA
        elseif (rtn_msg.cTGT and rtn_msg.cTGT >= 0) and club_id == rtn_msg.club_id then
            self.data.club_info.cTGT = rtn_msg.cTGT
        elseif rtn_msg.name then
            for i,club in ipairs(self.clubs or {}) do
                if club.club_id == rtn_msg.club_id then
                    club.club_name = rtn_msg.name
                    if self.data.club_info.club_id == rtn_msg.club_id then
                        self.data.club_info.club_name = rtn_msg.name
                    end
                    self:refreshClubModify({"name"})
                    break
                end
            end
        elseif rtn_msg.weixin and ENABLE_CLUB_WXSET then
            self.data.club_info.weixin = rtn_msg.weixin
            self:refreshClubModify({"weixin"})
            local profile = ProfileManager.GetProfile()
            if profile.uid == rtn_msg.uid then
                commonlib.showLocalTip("微信设置成功")
            end
        end
        local layer = self:getChildByName("ClubSetLayer")
        if layer then
            layer:onClubModify(rtn_msg)
        end
    else
        -- commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or rtn_msg.errno)
    end
end

function ClubLayer:onRcvRoomStatus(rtn_msg)
    -- dump(rtn_msg)
    local club_id = rtn_msg.club_id
    if not club_id then
        return
    end
    local room_id = rtn_msg.room_id
    if not room_id then
        return
    end
    -- print('ClubLayer:onRcvRoomStatus START')
    -- dump(rtn_msg)
    -- print('ClubLayer:onRcvRoomStatus END')

    local ClubData = require('club.ClubData')
    ClubData.onRcvRoomStatus(rtn_msg)
    self.data = ClubData.getData(self.data.club_info.club_id)
    self.clubs = ClubData.getClubs()


    -- 数据已存
    if club_id == self.data.club_info.club_id then
        -- 刷新房间信息
        self:refreshRoomInfo(room_id)
    end

    -- local club_id = self.data and self.data.club_info and self.data.club_info.club_id
    -- if rtn_msg and rtn_msg.club_id and club_id == rtn_msg.club_id then
    --     for i,room in ipairs(self.data.club_rooms) do
    --         if room.room_id == rtn_msg.room_id then
    --             self.data.club_rooms[i] = self:copyTable(self.data.club_rooms[i],rtn_msg)
    --             self:refreshRoomInfo(room.room_id)
    --         end
    --     end
    -- end
end

function ClubLayer:onRcvClubCloseRoom(rtn_msg)
    if rtn_msg.errno and rtn_msg.errno == 1044 then
        local layer = self.mainScene:getChildByName("CreateLayer")
        if layer then
            layer:removeFromParent(true)
        end
        commonlib.showTipDlg(rtn_msg.msg or '房间中已有玩家, 不能修改')
        return
    end
end

function ClubLayer:onRcvLeaveRoom(rtn_msg)

end

function ClubLayer:onRcvClubChangeRoom(rtn_msg)
    if rtn_msg.clubOpt and rtn_msg.clubOpt == 2 then
        commonlib.showLocalTip(rtn_msg.room_id and '房间' .. rtn_msg.room_id .. '修改游戏玩法成功' or '修改游戏玩法成功')
    elseif rtn_msg.clubOpt and rtn_msg.clubOpt == 3 then
        local qipaiType = rtn_msg.params.qipai_type
        local preGameMap = {
            ["mj_tdh"]  = "waypre_game1",
            ["mj_kd"]   = "waypre_game1",
            ['mj_gsj']  = 'waypre_game1',
            ['mj_jz']   = 'waypre_game1',
            ['mj_jzgsj']= 'waypre_game1',
            ["mj_xian"] = "waypre_game2",
            ["mj_lisi"] = "waypre_game1",
            ["pk_pdk"]  = "waypre_game3",
            ["pk_ddz"]  = "waypre_game3",
            ["pk_zgz"]  = "waypre_game3",
            ["mj_hebei"] = 'waypre_game_hebei',
            ['mj_hbtdh'] = 'waypre_game_hebei',
            ['mj_dbz']   = 'waypre_game_hebei',
            ['mj_fn']    = 'waypre_game_hebei',
            ["pk_jdpdk"] = "waypre_game3",
        }
        if qipaiType == 'pk_pdk' and rtn_msg.params.isJDPDK then
            qipaiType = "pk_jdpdk"
            rtn_msg.params.qipai_type = "pk_jdpdk"
        end
        if not preGameMap[qipaiType] then
            log(qipaiType)
        else
            cc.UserDefault:getInstance():setStringForKey(preGameMap[qipaiType], qipaiType)
            cc.UserDefault:getInstance():flush()
        end

        if preGameMap[qipaiType] == "waypre_game1" then
            cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", 1)
            cc.UserDefault:getInstance():flush()
        elseif preGameMap[qipaiType] == "waypre_game2" then
            cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", 2)
            cc.UserDefault:getInstance():flush()
        elseif preGameMap[qipaiType] == "waypre_game3" then
            cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", 3)
            cc.UserDefault:getInstance():flush()
        elseif preGameMap[qipaiType] == "waypre_game_hebei" then
            cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", 4)
            cc.UserDefault:getInstance():flush()
        end

        local ClubResetWaysLayer = require('club.ClubResetWaysLayer')
        local layer = self:getChildByName('ClubResetWaysLayer')
        if not layer then
            layer = ClubResetWaysLayer:create({club_room_info = rtn_msg})
            layer:setName('ClubResetWaysLayer')
            self:addChild(layer)
        else
            layer:setShuoMing(rtn_msg)
        end
    end
end

function ClubLayer:convertClubSyncCard(rtn_msg)
    if rtn_msg.card and rtn_msg.club_id then
        return rtn_msg
    end
    rtn_msg.club_id = rtn_msg['1']
    rtn_msg.card = rtn_msg['2']
    return rtn_msg
end

-- 此条消息只更新房卡
function ClubLayer:onRcvClubSyncCard(rtn_msg)
    -- print('````````````````````')
    -- dump(rtn_msg)
    -- print('````````````````````')
    rtn_msg = self:convertClubSyncCard(rtn_msg)

    -- dump(rtn_msg)
    local ClubData = require('club.ClubData')
    ClubData.onRcvClubSyncCard(rtn_msg)
    self.data = ClubData.getData(self.data.club_info.club_id)

    local club_id = self.data.club_info.club_id
    if club_id == rtn_msg.club_id then
        self.data.club_info.card = rtn_msg.card
        --- self.data.club_info.endTime = rtn_msg.endTime or self.data.club_info.endTime
        self:refreshFangKa()

        -- 向下兼容
        if rtn_msg.endTime then
            self.data.club_info.endTime = rtn_msg.endTime
            self:refreshTime()
        end
    end
end

function ClubLayer:onRcvSyncClubNotify(rtn_msg)
    if rtn_msg.tag == 5 then
        local clubAgentBindDialog = require("club.ClubAgentBindDialog"):create(rtn_msg.agentid, rtn_msg.card, rtn_msg.freeDay)
        self:addChild(clubAgentBindDialog, ZOrder.DIALOG)
    elseif rtn_msg.tag == 4 then
        if self.data and self.data.club_info and self.data.club_info.club_id then
            local net_msg = {
                cmd = NetCmd.C2S_CLUB_GET_APPLY_LIST,
                club_id = self.data.club_info.club_id
            }
            ymkj.SendData:send(json.encode(net_msg))
        end
    end
end

function ClubLayer:onRcvClubRoomStatus(rtn_msg)
    if rtn_msg.players and #rtn_msg.players > 0 then
        self:JieSanRoomTips(rtn_msg)
    end
end

function ClubLayer:onRcvClubUserType(rtn_msg)
    local clubMemberLayer = self:getChildByName("ClubMemberLayer")
    local profile   = ProfileManager.GetProfile()
    local club_info = self.data.club_info
    if club_info and club_info.club_id == rtn_msg.clubId then
        if type(profile) == "table" and profile.uid == rtn_msg.uid then
            local oldType = club_info.utype
            if rtn_msg.type == 2 then
                self.isAdmin = true
                commonlib.showLocalTip("您已被任命为"..club_info.club_id.."的管理员！")
            elseif rtn_msg.type == 3 then
                self.isBaned = true
                commonlib.showLocalTip("您已被"..club_info.club_id.."的管理员封禁！")
            else
                if oldType == 2 then
                    commonlib.showLocalTip("您已被"..club_info.club_id.."的管理员降职为普通成员！")
                elseif oldType == 3 then
                    commonlib.showLocalTip("您已被"..club_info.club_id.."的管理员解除封禁！")
                end
                self.isBaned = false
                self.isAdmin = false
            end
            self:onReconnect()
        end
        if clubMemberLayer then
            if profile.uid == rtn_msg.uid then
                if rtn_msg.type == 2 then
                    clubMemberLayer.isAdmin = true
                else
                    clubMemberLayer.isAdmin = false
                end
            end
            clubMemberLayer:onRcvClubUserType(rtn_msg)
        end
    end
end

function ClubLayer:refreshClubModify(list)
    list = list or {"isACWF","isOpen","isAKFK","isFZB", "weixin"}
    for i,v in ipairs(list) do
        if v == "isACWF" then
            if not self.isBoss and not self.isAdmin then
                local isACWF = self.data.club_info.isACWF

                for i = 1 , table.maxn(self.data.club_rooms) do
                    local room = self.data.club_rooms[i]
                    if room then
                        local item = self.uiItemList[room.room_id]
                        if item then
                            local btChange = item:getChildByName("btChange")
                            local wanfa = btChange:getChildByName("wanfa")
                            local change = btChange:getChildByName("change")
                            if isACWF == 1 and self.data.club_rooms[i].people_num == 0 then
                                change:setVisible(true)

                                self:set2objectPosition(btChange,{wanfa,change},5)
                                -- wanfa:setPositionX(btChange:getContentSize().width*0.362)

                                --change:setPosition(wanfa:getPositionX() + wanfa:getContentSize().width()*wanfa:getAnchorPostion().x)

                                btChange:setTouchEnabled(true)

                                local img = ClubHallUI.getInstance():getModifyBg()
                                btChange:loadTextureNormal(img)
                                btChange:loadTexturePressed(img)
                            else
                                local img = ClubHallUI.getInstance():getNoOpertorBg()
                                btChange:loadTextureNormal(img)
                                btChange:loadTexturePressed(img)

                                wanfa:setPositionX(btChange:getContentSize().width/2)
                                change:setVisible(false)
                                btChange:setTouchEnabled(false)
                            end
                        end
                    end
                end
            end
        elseif v == "isOpen" then
            local isOpen = self.data.club_info.isOpen
            local PanelClose = ccui.Helper:seekWidgetByName(self.node,"PanelClose")
            if isOpen == 0 then
                PanelClose:setVisible(true)
                local lbKaiQi = ccui.Helper:seekWidgetByName(PanelClose,"lbKaiQi")
                local btKaiQi = ccui.Helper:seekWidgetByName(PanelClose,"btKaiQi")
                lbKaiQi:setVisible(not self.isBoss and not self.isAdmin)
                btKaiQi:setVisible(self.isBoss or self.isAdmin)
            else
                PanelClose:setVisible(false)
            end
        elseif v == "isAKFK" then
            -- 房卡
            self:refreshFangKa()
            -- 房卡边上的时间
            self:refreshTime()
        elseif v == "name" then
            self:refreshClubList()
        elseif v == "isFZB" then
            local isFZB = self.data.club_info.isFZB
            if not (self.isBoss or self.isAdmin) then
                if isFZB == 1 then
                    if self.img_FZB then
                        self.img_FZB:setVisible(true)
                    else
                        local version = gt.getVersion()
                        log('img_FZB' .. version)
                        gt.uploadErr('img_FZB' .. version)
                    end
                else
                    if self.img_FZB then
                        self.img_FZB:setVisible(false)
                    else
                        local version = gt.getVersion()
                        log('img_FZB' .. version)
                        gt.uploadErr('img_FZB' .. version)
                    end
                end
            else
                if self.img_FZB then
                    self.img_FZB:setVisible(false)
                else
                    local version = gt.getVersion()
                    log('img_FZB' .. version)
                    gt.uploadErr('img_FZB' .. version)
                end
            end
        elseif v == "weixin" and ENABLE_CLUB_WXSET then
            local Panel_mid = ccui.Helper:seekWidgetByName(self.node,"Panel_mid")
            local img_wxbg  = ccui.Helper:seekWidgetByName(Panel_mid, "img_wxbg")
            if self.data.club_info.weixin or self.isBoss or self.isAdmin then
                local weixinName = self.data.club_info.weixin
                local length     = string.len(self.data.club_info.weixin or '')

                if length > 8 then
                    weixinName = string.sub(weixinName, 1, 8) .. "..."
                end

                self.t_weixin:setString(weixinName or "暂未设置")
                img_wxbg:setVisible(true)

                if self.isBoss or self.isAdmin then
                    self.btn_setWX:setVisible(true)
                    self.btn_copy:setVisible(false)
                    if self.data.club_info.weixin then
                        self.btn_setWX:loadTextureNormal("ui/qj_commom/wx_change.png")
                    else
                        self.btn_setWX:loadTextureNormal("ui/qj_commom/wx_setting.png")
                    end
                else
                    if self.noWeixin then
                        self.noWeixin = false
                        self:refreshLayer(true, true)
                    end
                    self.btn_setWX:setVisible(false)
                    self.btn_copy:setVisible(true)
                end
            else
                img_wxbg:setVisible(false)
                self.btn_setWX:setVisible(false)
                self.btn_copy:setVisible(false)
            end
        end
    end
end

function ClubLayer:refreshClubList()
    self.clubs = self.clubs or {}
    for i,btn in ipairs(self.btnClubList) do
        local img = ""
        local v = self.clubs[tonumber(i)]

        local club_name =  btn:getChildByName('club_name')

        if v then
            if pcall(commonlib.GetMaxLenString, v.club_name, 12 ,true ) then
                btn.club_name:setString(commonlib.GetMaxLenString(v.club_name,12, true))
            else
                btn.club_name:setString(v.club_name)
            end

            if v.club_id == self.data.club_info.club_id then
                if i == 1 then
                    img = ClubHallUI.getInstance():getTopHLClubNameItemBg('left')
                elseif i == 5 then
                    img = ClubHallUI.getInstance():getTopHLClubNameItemBg('right')
                else
                    img = ClubHallUI.getInstance():getTopHLClubNameItemBg('mid')
                end
                club_name:setColor(ClubHallUI.getInstance().curClubNameColor)
            else
                if i == 1 then
                    img = ClubHallUI.getInstance():getTopClubNameItemBg('left')
                elseif i == 5 then
                    img = ClubHallUI.getInstance():getTopClubNameItemBg('right')
                else
                    img = ClubHallUI.getInstance():getTopClubNameItemBg('mid')
                end
                club_name:setColor(ClubHallUI.getInstance().otherClubNameColor)
            end
        else
            btn.club_name:setString("")
            if i == 1 then
                img = ClubHallUI.getInstance():getTopClubNameItemBg('left')
            elseif i == 5 then
                img = ClubHallUI.getInstance():getTopClubNameItemBg('right')
            else
                img = ClubHallUI.getInstance():getTopClubNameItemBg('mid')
            end
            club_name:setColor(ClubHallUI.getInstance().otherClubNameColor)
        end
        if img ~= "" then
            btn:loadTextureNormal(img)
            btn:loadTexturePressed(img)
        end
    end
end

function ClubLayer:refreshRoomInfo(room_id)
    -- print('-------*-----------------------')
    -- print('------*-*----------------------')
    -- print('----*-----*--------------------')
    -- print('-----*---*---------------------')
    -- print('------*-*----------------------')
    -- print('-------*-----------------------')
    -- logUp('桌子状态变更')
    local room = nil
    for i, v in pairs(self.data.club_rooms) do
        if v.room_id == room_id then
            room = v
            -- dump(room)
            break
        end
    end
-- "<var>" = {
--     "club_id"         = 2281
--     "club_index"      = 1
--     "cmd"             = 54
--     "cur_ju"          = 1
--     "need_people_num" = 4
--     "params" = {
--         "club_id"      = 2281
--         "club_index"   = 1
--         "club_name"    = "win5682"
--         "cmd"          = 150
--         "copy"         = 0
--         "create_id"    = 2281
--         "hall_name"    = "MJTDH_HALL"
--         "isBaoTing"    = true
--         "isCreateClub" = true
--         "isDaHu"       = true
--         "isDaiFeng"    = false
--         "isGBTKBNG"    = false
--         "isGM"         = true
--         "isHPBXQM"     = false
--         "isPingHu"     = false
--         "isQueYiMen"   = false
--         "isSJHZ"       = false
--         "isYHQ"        = false
--         "isZhiKeZiMo"  = false
--         "people_num"   = 4
--         "qipai_type"   = "mj_tdh"
--         "qunzhu"       = 1
--         "room_type"    = 1
--         "total_ju"     = 8
--     }
--     "people_num"      = 2
--     "players" = {
--         1 = {
--             "head" = ""
--             "name" = "win5455"
--             "uid"  = 2318
--         }
--         2 = {
--             "head" = ""
--             "name" = "win5682"
--             "uid"  = 2281
--         }
--     }
--     "room_id"         = 246537
--     "room_name"       = "推倒胡8局"
--     "room_type"       = 1
--     "status"          = 0
-- }

    local curUiItem = self.uiItemList[room_id]

    if not room or not curUiItem then return end
    local btChange = curUiItem:getChildByName("btChange")
    local wanfaLabel = btChange:getChildByName("wanfa")
    local bg = curUiItem:getChildByName("bg")
    local btJoin = curUiItem:getChildByName('btJoin')
    local tLastJuShu = btJoin:getChildByName('tLastJuShu')
    local Image_41 = btJoin:getChildByName('Image_41')
    wanfaLabel:setString(room.room_name or "")

    local uiPlayers = {}
    for j=1,6 do
        local uiPlayer = curUiItem:getChildByName("player" .. j)
        uiPlayers[j] = uiPlayer
        uiPlayer.uiChair = uiPlayer:getChildByName("chair")
        uiPlayer.uiChair:setVisible(true)
        uiPlayer.uiName = uiPlayer:getChildByName("name")
        uiPlayer.uiName:setString("")
        uiPlayer.uiHead = uiPlayer:getChildByName("head")
        uiPlayer.uiHead:setVisible(false)
        -- 停载上次下载图像
        uiPlayer.uiHead:stopAllActions()
    end

    curUiItem.uiPlayers = {}

    local cur_ju = room.cur_ju
    local people_num = room.people_num
    local need_people_num = room.need_people_num
    local status = room.status
    local room_start = (cur_ju> 0 and status == 1)
    if room_start then
        -- print('-------*-----------------------')
        -- print('------*-*----------------------')
        -- print('----*-----*--------------------')
        -- print('-----*---*---------------------')
        -- print('------*-*----------------------')
        -- print('-------*-----------------------')
        need_people_num = room.people_num
    end

    if need_people_num == 2 then
        for j=1,6 do
            if j == 1 or j == 3 then
                uiPlayers[j]:setVisible(true)
                curUiItem.uiPlayers[#curUiItem.uiPlayers+1] = uiPlayers[j]
            else
                uiPlayers[j]:setVisible(false)
            end
        end

        uiPlayers[1]:setPosition(ClubHallUI.getInstance().p2chair1Pos)
        uiPlayers[3]:setPosition(ClubHallUI.getInstance().p2chair3Pos)

        if  ClubHallUI.getClubStyle() == ClubHallUI.Classic then
            curUiItem:getChildByName("btTip"):setPositionX(84.95)
            uiPlayers[3].uiChair:setRotation(-90)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Simple then
            curUiItem:getChildByName("btTip"):setPositionX(58.56)
            uiPlayers[3].uiChair:setRotation(0)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.NewYear then
            uiPlayers[3].uiChair:setRotation(-90)
        end
    elseif need_people_num == 3 then
        for j=1,6 do
            if j == 4 or j == 5 or j == 6 then
                uiPlayers[j]:setVisible(false)
            else
                uiPlayers[j]:setVisible(true)
                curUiItem.uiPlayers[#curUiItem.uiPlayers+1] = uiPlayers[j]
            end
        end

        uiPlayers[1]:setPosition(ClubHallUI.getInstance().p3chair1Pos)
        uiPlayers[2]:setPosition(ClubHallUI.getInstance().p3chair2Pos)
        uiPlayers[3]:setPosition(ClubHallUI.getInstance().p3chair3Pos)

        if  ClubHallUI.getClubStyle() == ClubHallUI.Classic then
            curUiItem:getChildByName("btTip"):setPositionX(84.95)
            uiPlayers[3].uiChair:setRotation(-90)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Simple then
            curUiItem:getChildByName("btTip"):setPositionX(58.56)
            uiPlayers[3].uiChair:setRotation(0)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.NewYear then
            uiPlayers[3].uiChair:setRotation(-90)
        end
    elseif need_people_num == 4 then
        for j=1,6 do
            if j == 5 or j== 6 then
                uiPlayers[j]:setVisible(false)
            else
                uiPlayers[j]:setVisible(true)
                curUiItem.uiPlayers[#curUiItem.uiPlayers+1] = uiPlayers[j]
            end
        end

        uiPlayers[1]:setPosition(ClubHallUI.getInstance().p4chair1Pos)
        uiPlayers[2]:setPosition(ClubHallUI.getInstance().p4chair2Pos)
        uiPlayers[3]:setPosition(ClubHallUI.getInstance().p4chair3Pos)
        uiPlayers[4]:setPosition(ClubHallUI.getInstance().p4chair4Pos)


        if  ClubHallUI.getClubStyle() == ClubHallUI.Classic then
            curUiItem:getChildByName("btTip"):setPositionX(84.95)
            uiPlayers[3].uiChair:setRotation(-90)
            uiPlayers[4].uiChair:setRotation(-180)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Simple then
            curUiItem:getChildByName("btTip"):setPositionX(58.56)
            uiPlayers[3].uiChair:setRotation(0)
            uiPlayers[4].uiChair:setRotation(0)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.NewYear then
            uiPlayers[3].uiChair:setRotation(-90)
            uiPlayers[4].uiChair:setRotation(-180)
        end
        --curUiItem.uiPlayers = uiPlayers
    elseif need_people_num == 5 then
        for j=1,6 do
            if j== 6 then
                uiPlayers[j]:setVisible(false)
            else
                uiPlayers[j]:setVisible(true)
                curUiItem.uiPlayers[#curUiItem.uiPlayers+1] = uiPlayers[j]
            end
        end

        uiPlayers[1]:setPosition(ClubHallUI.getInstance().p5chair1Pos)
        uiPlayers[2]:setPosition(ClubHallUI.getInstance().p5chair2Pos)
        uiPlayers[3]:setPosition(ClubHallUI.getInstance().p5chair3Pos)
        uiPlayers[4]:setPosition(ClubHallUI.getInstance().p5chair4Pos)
        uiPlayers[5]:setPosition(ClubHallUI.getInstance().p5chair5Pos)


        if  ClubHallUI.getClubStyle() == ClubHallUI.Classic then
            curUiItem:getChildByName("btTip"):setPositionX(84.95)
            uiPlayers[3].uiChair:setRotation(-90)
            uiPlayers[4].uiChair:setRotation(-180)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Simple then
            curUiItem:getChildByName("btTip"):setPositionX(58.56)
            uiPlayers[3].uiChair:setRotation(0)
            uiPlayers[4].uiChair:setRotation(0)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.NewYear then
            uiPlayers[3].uiChair:setRotation(-90)
            uiPlayers[4].uiChair:setRotation(-180)
        end
        --curUiItem.uiPlayers = uiPlayers
    elseif need_people_num == 6 then
        for j=1,6 do
            uiPlayers[j]:setVisible(true)
            curUiItem.uiPlayers[#curUiItem.uiPlayers+1] = uiPlayers[j]
        end

        uiPlayers[1]:setPosition(ClubHallUI.getInstance().p6chair1Pos)
        uiPlayers[2]:setPosition(ClubHallUI.getInstance().p6chair2Pos)
        uiPlayers[3]:setPosition(ClubHallUI.getInstance().p6chair3Pos)
        uiPlayers[4]:setPosition(ClubHallUI.getInstance().p6chair4Pos)
        uiPlayers[5]:setPosition(ClubHallUI.getInstance().p6chair5Pos)
        uiPlayers[6]:setPosition(ClubHallUI.getInstance().p6chair6Pos)

        uiPlayers[3].uiChair:setRotation(0)

        if  ClubHallUI.getClubStyle() == ClubHallUI.Classic then
            curUiItem:getChildByName("btTip"):setPositionX(24.95)
            uiPlayers[4].uiChair:setRotation(-90)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Simple then
            curUiItem:getChildByName("btTip"):setPositionX(40)
            uiPlayers[4].uiChair:setRotation(0)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.NewYear then
            uiPlayers[4].uiChair:setRotation(-90)
        elseif ClubHallUI.getClubStyle() == ClubHallUI.Elegant then
            uiPlayers[3].uiChair:loadTexture('res/ui/qj_club_elegant/chairt.png')
            -- uiPlayers[3].uiChair:setContentSize(cc.size(60,84))
            uiPlayers[4].uiChair:loadTexture('res/ui/qj_club_elegant/chairl.png')
            -- uiPlayers[4].uiChair:setContentSize(cc.size(69,97))
        end
        curUiItem.uiPlayers = uiPlayers
    end

    if ClubHallUI.getClubStyle() == ClubHallUI.Elegant then
        if need_people_num ~= 6 then
            uiPlayers[4].uiChair:loadTexture('res/ui/qj_club_elegant/chairb.png')
            -- uiPlayers[4].uiChair:setContentSize(cc.size(66,75))
            uiPlayers[3].uiChair:loadTexture('res/ui/qj_club_elegant/chairl.png')
            -- uiPlayers[3].uiChair:setContentSize(cc.size(69,97))
        end

        for i  = 1, 6 do
            uiPlayers[i].uiChair:setContentSize(cc.size(100.00,120))
        end


        -- ClubHallUIElegant.p2chair1Pos = cc.p(284.82,177)
        -- ClubHallUIElegant.p2chair3Pos = cc.p(67.26,177)

        -- ClubHallUIElegant.p3chair1Pos = cc.p(284.82,177)
        -- ClubHallUIElegant.p3chair2Pos = cc.p(177,283)
        -- ClubHallUIElegant.p3chair3Pos = cc.p(67.26,177)

        -- ClubHallUIElegant.p4chair1Pos = cc.p(284.82,177)
        -- ClubHallUIElegant.p4chair2Pos = cc.p(177,283)
        -- ClubHallUIElegant.p4chair3Pos = cc.p(67.26,177)
        -- ClubHallUIElegant.p4chair4Pos = cc.p(177,74.34)

        -- ClubHallUIElegant.p5chair1Pos = cc.p(284.82,177)
        -- ClubHallUIElegant.p5chair2Pos = cc.p(177,283)
        -- ClubHallUIElegant.p5chair3Pos = cc.p(67.26,177)
        -- ClubHallUIElegant.p5chair4Pos = cc.p(113.28,74.34)
        -- ClubHallUIElegant.p5chair5Pos = cc.p(240.72,74.34)

        -- ClubHallUIElegant.p6chair1Pos = cc.p(284.82,177)
        -- ClubHallUIElegant.p6chair2Pos = cc.p(240.72,283)
        -- ClubHallUIElegant.p6chair3Pos = cc.p(113.28,283)
        -- ClubHallUIElegant.p6chair4Pos = cc.p(67.26,177)
        -- ClubHallUIElegant.p6chair5Pos = cc.p(113.28,74.34)
        -- ClubHallUIElegant.p6chair6Pos = cc.p(240.72,74.34)

    end

    local downImgIdx = 0
    for j,v in ipairs(room.players) do
        if pcall(commonlib.GetMaxLenString, v.name, 14) then
            curUiItem.uiPlayers[j].uiName:setString(commonlib.GetMaxLenString(v.name, 14))
        else
            curUiItem.uiPlayers[j].uiName:setString(v.name)
        end
        curUiItem.uiPlayers[j].uiHead:loadTexture('ui/qj_club/dt_clubroom_dianjijiaru_zhezhao.png')
        curUiItem.uiPlayers[j].uiHead:setVisible(true)
        curUiItem.uiPlayers[j].uiChair:setVisible(false)
        gt.performWithDelay(curUiItem.uiPlayers[j].uiHead,function( ... )
            if curUiItem and curUiItem.uiPlayers and curUiItem.uiPlayers[j] and curUiItem.uiPlayers[j].uiHead then
                curUiItem.uiPlayers[j].uiHead:downloadImg(commonlib.wxHead(v.head))
            end
        end,downImgIdx*0.1)
        downImgIdx = downImgIdx + 1
    end

    local btChange = curUiItem:getChildByName("btChange")
    local change = btChange:getChildByName("change")
    local wanfaLabel = btChange:getChildByName("wanfa")

    -- 可以修改 人数为空，且允许修改或者是群主
    if (self.data.club_info.isACWF == 1 or (self.isBoss or self.isAdmin)) and room.people_num == 0 then
        wanfaLabel:setPositionX(btChange:getContentSize().width*0.362)
        change:setVisible(true)
        change:setString("修改")
        local img = ClubHallUI.getInstance():getModifyBg()
        btChange:loadTextureNormal(img)
        btChange:loadTexturePressed(img)
        btChange:setTouchEnabled(true)
        btChange.nTag = 1
    -- 是群主且人数未满且未开始
    elseif (self.isBoss or self.isAdmin) and room.people_num ~= 0 and not room_start then
        wanfaLabel:setPositionX(btChange:getContentSize().width*0.362)
        change:setVisible(true)
        change:setString("解散")
        local img = ClubHallUI.getInstance():getDiscardBg()
        btChange:loadTextureNormal(img)
        btChange:loadTexturePressed(img)
        btChange:setTouchEnabled(true)
        btChange.nTag = 2
    -- 是群主且游戏开始
    elseif room.people_num ~= 0 and room.status == 1 and (self.isBoss or self.isAdmin) then
        wanfaLabel:setPositionX(btChange:getContentSize().width*0.362)
        change:setVisible(true)
        change:setString("解散")
        local img = ClubHallUI.getInstance():getDiscardBg()
        btChange:loadTextureNormal(img)
        btChange:loadTexturePressed(img)
        btChange:setTouchEnabled(true)
        btChange.nTag = 4
    --- 已有人且不是群主且游戏或者游戏开始
    elseif room.people_num ~= 0 and (not self.isBoss and not self.isAdmin) or room_start then
        wanfaLabel:setPositionX(btChange:getContentSize().width/2)
        change:setVisible(false)
        btChange:setTouchEnabled(false)
        local img = ClubHallUI.getInstance():getNoOpertorBg()
        btChange:loadTextureNormal(img)
        btChange:loadTexturePressed(img)
        btChange.nTag = 3
    elseif (self.data.club_info.isACWF == 0 and (not self.isBoss and not self.isAdmin)) then
        wanfaLabel:setPositionX(btChange:getContentSize().width/2)
        change:setVisible(false)
        btChange:setTouchEnabled(false)
        local img = ClubHallUI.getInstance():getNoOpertorBg()
        btChange:loadTextureNormal(img)
        btChange:loadTexturePressed(img)
        btChange.nTag = 3
    end

    self:set2objectPosition(btChange,{wanfaLabel,change},5)

    if room_start then
        local img = ClubHallUI.getInstance():getRoomItemPlayingBg()
        local imageMask = curUiItem:getChildByName("imageMask")
        if imageMask then
            imageMask:setVisible(true)
        else
            bg:loadTexture(img)
        end
        if room and room.params and room.params.total_ju and room.cur_ju then
            if room.params.total_ju >= 100 then
                if ClubHallUI.getClubStyle() == ClubHallUI.Simple then
                    local ImgLastJuShu = btJoin:getChildByName('ImgLastJuShu')
                    if ImgLastJuShu then
                        ImgLastJuShu:loadTexture('ui/qj_club_simple/playing-fs8.png')
                        ImgLastJuShu:setVisible(true)
                    end
                    tLastJuShu:setVisible(false)
                elseif ClubHallUI.getClubStyle() == ClubHallUI.Elegant then
                    local imagePlaying = btJoin:getChildByName('imagePlaying')
                    tLastJuShu:setVisible(true)
                    local ImgLastJuShu = btJoin:getChildByName('ImgLastJuShu')
                    ImgLastJuShu:setVisible(false)
                    local tLastJuShu = btJoin:getChildByName('tLastJuShu')
                    tLastJuShu:setVisible(false)
                else
                    tLastJuShu:setVisible(true)
                    tLastJuShu:setString(string.format("游戏中"))
                end
            else
                if ClubHallUI.getClubStyle() == ClubHallUI.Simple or ClubHallUI.getClubStyle() == ClubHallUI.Elegant then
                    local ImgLastJuShu = btJoin:getChildByName('ImgLastJuShu')
                    if ImgLastJuShu then
                        ImgLastJuShu:loadTexture('ui/qj_club_simple/left-fs8.png')
                        ImgLastJuShu:setVisible(true)
                    end
                end
                local imagePlaying = btJoin:getChildByName('imagePlaying')
                if imagePlaying then
                    imagePlaying:setVisible(false)
                end
                tLastJuShu:setVisible(true)
                tLastJuShu:setString(string.format("剩余 %d 局", room.params.total_ju - room.cur_ju))
            end
        end
        -- tLastJuShu:setVisible(true)
        Image_41:setVisible(false)

        if ClubHallUI.getInstance():getPlayingDeskGameNameColor() then
            wanfaLabel:setColor(ClubHallUI.getInstance():getPlayingDeskGameNameColor())
        end

        if ClubHallUI.getInstance():getPlayingDeskOptColor() then
            change:setColor(ClubHallUI.getInstance():getPlayingDeskOptColor())
        end
    else
        local img = ClubHallUI.getInstance():getRoomItemBg()
        local imageMask = curUiItem:getChildByName("imageMask")
        if imageMask then
            imageMask:setVisible(false)
        else
            bg:loadTexture(img)
        end
        Image_41:setVisible(true)
        tLastJuShu:setVisible(false)
        if ClubHallUI.getClubStyle() == ClubHallUI.Simple or ClubHallUI.getClubStyle() == ClubHallUI.Elegant then
            local ImgLastJuShu = btJoin:getChildByName('ImgLastJuShu')
            if ImgLastJuShu then
                ImgLastJuShu:setVisible(false)
            end
        end
        local imagePlaying = btJoin:getChildByName('imagePlaying')
        if imagePlaying then
            imagePlaying:setVisible(false)
        end

        if ClubHallUI.getInstance():getFreeDeskGameNameColor() then
            wanfaLabel:setColor(ClubHallUI.getInstance():getFreeDeskGameNameColor())
        end

        if ClubHallUI.getInstance():getFreeDeskOptColor() then
            change:setColor(ClubHallUI.getInstance():getFreeDeskOptColor())
        end
    end
end

function ClubLayer:exitLayer()
    self:unregisterEventListener()
    self:stopTimeAction()
    self:removeFromParent(true)
end

function ClubLayer:createLayerMenu()
    local node = ClubHallUI.getInstance():loadCsbFile()
    self.storgeStyle = ClubHallUI.getClubStyle()
    INFO('亲友圈风格',self.storgeStyle)

    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)
    self.node = node

    local Panel_top = ccui.Helper:seekWidgetByName(node,"Panel_top")
    local Panel_mid = ccui.Helper:seekWidgetByName(node,"Panel_mid")
    local Panel_bottom = ccui.Helper:seekWidgetByName(node,"Panel_bottom")
    local PanelClose = ccui.Helper:seekWidgetByName(node,"PanelClose")
    self.is_back_fromroom = nil
    if cc.UserDefault:getInstance():getStringForKey("is_back_fromroom") ~= "" then
        self.is_back_fromroom = cc.UserDefault:getInstance():getStringForKey("is_back_fromroom")
    end
    PanelClose:setVisible(false)

    self.isFzb = false

    local uiItem     = ccui.Helper:seekWidgetByName(Panel_mid, "item")
    self.t_weixin    = ccui.Helper:seekWidgetByName(Panel_mid, "t_weixin")
    self.btn_setWX   = ccui.Helper:seekWidgetByName(Panel_mid, "btn_setWX")
    self.btn_copy    = ccui.Helper:seekWidgetByName(Panel_mid, "btn_copy")
    local posY       = uiItem:getPositionY()
    self.uiItem_posy = posY

    self.btn_copy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local weixin = self.data.club_info.weixin or self.t_weixin:getString()
            ymkj.copyClipboard(weixin)
            commonlib.showLocalTip("复制成功")
        end
    end)

    self.btn_setWX:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:setWeiXin()
        end
    end)

    local btKaiQi = tolua.cast(ccui.Helper:seekWidgetByName(PanelClose,"btKaiQi"), "ccui.Button")
    btKaiQi:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local input_msg = {
                cmd = NetCmd.C2S_CLUB_MODIFY,
                isOpen = 1,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    local btSet = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top,"btSet"), "ccui.Button")
    btSet:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print("btSet")
            if not self.data or not self.clubs then
                return
            end
            local ClubSetLayer = require("club.ClubSetLayer")
            local layer = ClubSetLayer:create({
                isBoss = self.isBoss,
                isAdmin = self.isAdmin,
                data = self.data,
                clubs = self.clubs,
            })
            self:addChild(layer,100)
        end
    end)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            --self:exitLayer()

            self:setVisible(false)
        end
    end)

    -- 聊天室按钮
    local ltsBtn = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btLts"), "ccui.Button")
    ltsBtn:addTouchEventListener( function (sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local title   = string.format("茶馆:%s", tostring(self.data.club_info.club_id))
            local content = string.format("点击进入%s的茶馆，一起愉快聊天吧!", self.data.club_info.club_name)
            local bas   = ymkj.base64Encode(tostring(self.data.club_info.club_id))
            local ltsUrl = string.format("%s?s=%s", gt.getConf("share_chat_url"), bas)
            gt.wechatShareChatStart()
            ymkj.wxReq(2, content, title, ltsUrl, "1")
            gt.wechatShareChatEnd()
            print(title.."\n"..content.."\n"..ltsUrl.."\n打开聊天室分享")
        end
    end)

    for i=1,5 do
        local btSel = tolua.cast(Panel_bottom:getChildByName("btSel_" .. i), "ccui.Button")
        btSel:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i == 1 and self.is_back_fromroom == "true" and not self.isBoss and not self.isAdmin then
                    commonlib.showReturnTips("不可加入其它房间，")
                elseif i == 2 and (self.isBoss or self.isAdmin) and self.is_back_fromroom == "true" then
                    commonlib.showReturnTips("不可修改玩法，")
                elseif self.nameTab and self.nameTab[i] then
                    self:onSelEvent(self.nameTab[i])
                end
            end
        end)
    end

    local function showFaKaShuoMing()
        if not self.isBoss then
            return
        end
        local ClubCardNoticeLayer = require('club.ClubCardNoticeLayer')
        local Layer = ClubCardNoticeLayer:create({isAllowCharge = self.data.club_info.isAllowCharge,isBoss = self.isBoss,})
        Layer:setName('ClubCardNoticeLayer')
        self:addChild(Layer)
    end

    local btExchange = tolua.cast(ccui.Helper:seekWidgetByName(Panel_bottom,"btExchange"), "ccui.Button")
    btExchange:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print("btExchange")
            showFaKaShuoMing()
        end
    end)

    local btnfangka = tolua.cast(ccui.Helper:seekWidgetByName(Panel_bottom,"btnfangka"), "ccui.Button")
    self.btnfangka = btnfangka
    self.btnfangka:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print("btnfangka")
            showFaKaShuoMing()
        end
    end)

    self.img_FZB = ccui.Helper:seekWidgetByName(Panel_bottom,"imgFZB")
    if self.img_FZB then
        self.img_FZB:setVisible(false)
    else
        local version = gt.getVersion()
        log('img_FZB' .. version)
        gt.uploadErr('img_FZB' .. version)
    end

    local uiItem = ccui.Helper:seekWidgetByName(Panel_mid, "item")
    uiItem:setVisible(false)

    self.btnClubList = {}
    for i=1,5 do
        local btn = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top,"btnClub" .. i), "ccui.Button")
        btn.club_name = btn:getChildByName("club_name")
        btn.club_name:setString("")
        if i == 1 then
            local img = ClubHallUI.getInstance():getTopClubNameItemBg('left')
            btn:loadTextureNormal(img)
            -- log(img)
            local img = ClubHallUI.getInstance():getTopClubNameItemPressBg('left')
            btn:loadTexturePressed(img)
            -- log(img)
        elseif i == 5 then
            local img = ClubHallUI.getInstance():getTopClubNameItemBg('right')
            btn:loadTextureNormal(img)
            -- log(img)
            local img = ClubHallUI.getInstance():getTopClubNameItemPressBg('right')
            btn:loadTexturePressed(img)
            -- log(img)
        else
            local img = ClubHallUI.getInstance():getTopClubNameItemBg('mid')
            btn:loadTextureNormal(img)
            -- log(img)
            local img = ClubHallUI.getInstance():getTopClubNameItemPressBg('mid')
            btn:loadTexturePressed(img)
            -- log(img)
        end
        btn:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.began then
                local name = sender:getName()
                if self.ClickChangeClub and name ~= self.ClickChangeClub then
                    return
                end
                self.ClickChangeClub = name
            elseif eventType == ccui.TouchEventType.canceled then
                self.ClickChangeClub = nil
            elseif eventType == ccui.TouchEventType.ended then
                local name = sender:getName()
                if name ~= self.ClickChangeClub then
                    return
                end
                self.ClickChangeClub = nil

                local ClubData = require('club.ClubData')
                self.clubs = ClubData.clubs
                if self.clubs and self.clubs[i] then
                    AudioManager:playPressSound()

                    local club_id = self.clubs[i].club_id
                    if club_id ~= self.data.club_info.club_id then
                        self.data = ClubData.data[club_id]
                        self.mainScene:onRcvInfoMax(self.data,true)
                    else
                        return
                    end

                    --切换亲友圈
                    local input_msg = {
                        cmd = NetCmd.C2S_INFO_MAX,
                        club_id = self.clubs[i].club_id,
                    }
                    ymkj.SendData:send(json.encode(input_msg))

                    self.net_data = {}

                    self:stopTimeAction()

                    -- self.refreshPos = false
                    -- 过渡动画
                    -- commonlib.showLoading()
                end
            end
        end)
        self.btnClubList[i] = btn
    end
end

function ClubLayer:initClub(data)
    self.data = data
    -- dump(self.data)
    self.isAdmin = false
    local profile = ProfileManager.GetProfile()
    if type(profile) == "table" and profile.uid == self.data.club_info.club_id then
        self.isBoss = true
    else
        self.isBoss = false
    end
    if self.data.club_info.gmUids and #self.data.club_info.gmUids > 0 then
        for i,v in ipairs(self.data.club_info.gmUids) do
            if type(profile) == "table" and profile.uid == v and not self.isBoss then
                self.isAdmin = true
            end
        end
    end
    if self.data.club_info.utype == 3 then
        self.isBaned = true
    else
        self.isBaned = false
    end
    if self.data.club_info.gmUids and #self.data.club_info.gmUids >= 4 then
        self.isFullAdmin = true
    end
    -- log(self.data.club_info.gmUids)
    self.nameTab = {"quckjoin","club","rank", "friend"}
    if self.isBoss or self.isAdmin then
        self.nameTab = {"club","ways","rank", "log", "friend"}
    end
    self:refreshFangKa()

    self:refreshTime()

    gt.setClubID(self.data.club_info.club_id)
end

function ClubLayer:showLastTime(label)
    local function setLastTime()
        if self.data.club_info.endTime then
            local szLastTime = '****'
            local lCurTime = os.time()
            local lLastTime = self.data.club_info.endTime - lCurTime
            if lLastTime < 0 then
                lLastTime = 0
            end
            local lDay = math.floor(lLastTime/86400)
            if lDay >= 1 then
                szLastTime = lDay .. '天'
            else
                local lHour = math.floor(lLastTime/3600)
                if lHour >= 1 then
                    szLastTime = lHour .. '小时'
                else
                    local lMin = math.floor(lLastTime/60)
                    if lMin >= 1 then
                        szLastTime = lMin .. '分钟'
                    else
                        szLastTime = lLastTime .. '秒'
                    end
                end
            end
            label:setString(szLastTime)
        end
    end

    label:stopAllActions()
    label:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        setLastTime()
    end))))
end

function ClubLayer:stopTimeAction()
    -- log('@@@@@@@@@ stopTimeAction')
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    local tLastTime = ccui.Helper:seekWidgetByName(Panel_bottom,"tLastTime")
    tLastTime:stopAllActions()
    tLastTime:setString('--')
end

function ClubLayer:refreshFangKa()
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    local fangka = ccui.Helper:seekWidgetByName(Panel_bottom,"fangka")
    if type(self.data.club_info) == "table" then
        if (self.isBoss or self.isAdmin) or self.data.club_info.isAKFK == 1 then
            fangka:setString(self.data.club_info.card or 0)
        else
            fangka:setString("****")
        end
    end
end

function ClubLayer:refreshTime()
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    local tLastTime = ccui.Helper:seekWidgetByName(Panel_bottom,"tLastTime")
    tLastTime:setString('--')
    if type(self.data.club_info) == "table" then
        if (self.isBoss or self.isAdmin) or self.data.club_info.isAKFK == 1 then
            self:showLastTime(tLastTime)
        else
            tLastTime:stopAllActions()
            tLastTime:setString("****")
        end
    end
end

function ClubLayer:refreshLayer(isInit, firstHasWX)
    if not self.data then
        return
    end

    if not self.data.club_info.weixin then
        self.noWeixin = true
    end
    local Panel_top = ccui.Helper:seekWidgetByName(self.node,"Panel_top")
    local Panel_mid = ccui.Helper:seekWidgetByName(self.node,"Panel_mid")
    local img_wxbg = ccui.Helper:seekWidgetByName(Panel_mid,"img_wxbg")
    img_wxbg:setVisible(ENABLE_CLUB_WXSET)
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    local profile = ProfileManager.GetProfile()

    -- local num = ccui.Helper:seekWidgetByName(Panel_bottom,"num")
    local clubid = ccui.Helper:seekWidgetByName(Panel_bottom,"clubid")
    local tLastTime = ccui.Helper:seekWidgetByName(Panel_bottom,"tLastTime")

    if type(self.data.club_info) == "table" then
        clubid:setString(string.format("亲友圈ID：%s",self.data.club_info.club_id))
        -- num:setString(string.format("总人数：    %d/%d",self.data.club_info.onlineCount,self.data.club_info.memCount))
    end

    self:refreshMemStaus()
    for i=1,5 do
        local btSel = tolua.cast(Panel_bottom:getChildByName("btSel_" .. i), "ccui.Button")
        if self.nameTab[i] then
            btSel:setVisible(true)
            local img = ClubHallUI.getInstance():getBtnImgByName(self.nameTab[i])
            btSel:loadTextureNormal(img)
            local img = ClubHallUI.getInstance():getBtnImgPressByName(self.nameTab[i])
            btSel:loadTexturePressed(img)
        else
            btSel:setVisible(false)
        end
    end

    local uiItem = ccui.Helper:seekWidgetByName(Panel_mid, "item")



    local btChange = ccui.Helper:seekWidgetByName(uiItem, "btChange")
    uiItem:setVisible(false)

    -- if type(self.uiItemList) == "table" then
    --     for i,item in pairs(self.uiItemList) do
    --         item:removeFromParent(true)
    --     end
    -- end
    self.uiItemList = {}
--* 每排桌子数量
    require 'scene.GameSettingDefault'
    self.desknum = gt.getLocal("int", "qyqDesk", GameSettingDefault.CLUB_DESK_NUM)
    if self.desknum ~= 3 and self.desknum ~= 4 and self.desknum ~=5 then
        self.desknum = 3
    end

    local ScrollView = ccui.Helper:seekWidgetByName(Panel_mid, "ScrollView")
    local LayerCont = ScrollView:getChildByName("LayerCont")
    if not self.data.club_rooms then
        return
    end
    local nMin = math.max(math.ceil(#self.data.club_rooms/self.desknum) ,2)
    local Height = nil
    local nHeightAlign = nil
    local nHeightScale = nil
    if self.desknum == 4 then
        nHeightAlign = ClubHallUI.getInstance().HeightAlign4Ren
        nHeightScale = ClubHallUI.getInstance().HeightScale4Ren
    elseif self.desknum == 5 then
        nHeightAlign = ClubHallUI.getInstance().HeightAlign5Ren
        nHeightScale = ClubHallUI.getInstance().HeightScale5Ren
    else
        nHeightAlign = ClubHallUI.getInstance().HeightAlign3Ren
        nHeightScale = ClubHallUI.getInstance().HeightScale3Ren
    end

    require 'common.global'
    if ENABLE_CLUB_WXSET and (self.data.club_info.weixin or self.isBoss or self.isAdmin) then
        uiItem:setPositionY(self.uiItem_posy - 27)
        Height = (uiItem:getContentSize().height + nHeightAlign) * nMin * nHeightScale + 35
    else
        uiItem:setPositionY(self.uiItem_posy)
        Height = (uiItem:getContentSize().height + nHeightAlign) * nMin * nHeightScale
    end

    LayerCont:setPositionY(-LayerCont:getContentSize().height + Height)

    ScrollView:setInnerContainerSize(cc.size(LayerCont:getContentSize().width, Height))
    ScrollView:jumpToTop()

    -- self.clubLayerPos = self.clubLayerPos or {}
    -- if not self.clubLayerPos[self.data.club_info.club_id] then
    --     ScrollView:jumpToTop()
    --     self.clubLayerPos[self.data.club_info.club_id] = ScrollView:getInnerContainer():getPositionY()
    -- else
    --     if self.clubLayerPos[self.data.club_info.club_id] > 0 then
    --         self.clubLayerPos[self.data.club_info.club_id] = 0
    --     elseif self.clubLayerPos[self.data.club_info.club_id] < -ScrollView:getInnerContainerSize().height + ScrollView:getContentSize().height then
    --         self.clubLayerPos[self.data.club_info.club_id] =  -ScrollView:getInnerContainerSize().height + ScrollView:getContentSize().height
    --     end
    --     ScrollView:getInnerContainer():setPositionY(self.clubLayerPos[self.data.club_info.club_id])
    -- end

    -- self.refreshPos = true

    -- dump(self.clubLayerPos)

    local roomwidth = nil
    local itemHeight = nil
    local windowSize = cc.Director:getInstance():getWinSize()
    log(windowSize)
    if self.desknum == 4 then
        uiItem:setScale(ClubHallUI.getInstance().RoomItemScale4R)
        btChange:setScale(1.2)
        uiItem:setPositionX(ClubHallUI.getInstance().RoomFirstPosX4R)
        roomwidth = (windowSize.width-ClubHallUI.getInstance().RoomFirstPosX4R*2-354*ClubHallUI.getInstance().RoomItemScale4R)/3
        itemHeight = ClubHallUI.getInstance().RoomItemHeight4R
    elseif self.desknum == 5 then
        uiItem:setScale(ClubHallUI.getInstance().RoomItemScale5R)
        btChange:setScale(1.2)
        uiItem:setPositionX(ClubHallUI.getInstance().RoomFirstPosX5R)
        roomwidth =(windowSize.width-ClubHallUI.getInstance().RoomFirstPosX5R*2-354*ClubHallUI.getInstance().RoomItemScale5R)/4
        itemHeight = ClubHallUI.getInstance().RoomItemHeight5R
    else
        uiItem:setScale(ClubHallUI.getInstance().RoomItemScale3R)
        btChange:setScale(1)
        uiItem:setPositionX(ClubHallUI.getInstance().RoomFirstPosX3R)
        roomwidth = (windowSize.width-ClubHallUI.getInstance().RoomFirstPosX3R*2-354*ClubHallUI.getInstance().RoomItemScale3R)/2
        itemHeight = ClubHallUI.getInstance().RoomItemHeight3R
    end

    local club_rooms = self.data.club_rooms

    -- 房间有效
    club_rooms = self:checkRoom(club_rooms)

    self:sortRoomByIndex(club_rooms)

    local starttime = os.clock()

    self.clubItemPos = self.clubItemPos or {}
    for i = 1, table.maxn(club_rooms) do
        local x = ((i-1)%self.desknum)*roomwidth
        local y = - math.floor((i-1)/self.desknum)*itemHeight
        self.clubItemPos[i] = cc.p(x + uiItem:getPositionX(),y + uiItem:getPositionY())

        print('------------------------',i)
        print(x,y)

    end

    self.max_desk = self.max_desk or 0
    self.max_desk = (table.maxn(club_rooms) > self.max_desk and table.maxn(club_rooms) or self.max_desk)
    for i = 1, self.max_desk do
        local item = LayerCont:getChildByName('Desk ' .. i)
        if item then
            item:setVisible(false)
            item.hasSet = false
        end
    end

    local function setItem(i, room, pos)
        local item = LayerCont:getChildByName('Desk ' .. i)
        local x = pos.x
        local y = pos.y
        if not item then
            item = uiItem:clone()
            item:setPosition(cc.p(x,y))
            LayerCont:addChild(item)
            item:setName('Desk ' .. i)
        else
            item:setPosition(cc.p(x,y))
            if self.desknum == 4 then
                item:setScale(ClubHallUI.getInstance().RoomItemScale4R)
                btChange:setScale(1.2)
            elseif self.desknum == 5 then
                item:setScale(ClubHallUI.getInstance().RoomItemScale5R)
                btChange:setScale(1.2)
            else
                item:setScale(ClubHallUI.getInstance().RoomItemScale3R)
                btChange:setScale(1)
            end
        end

        item.hasSet = true

        curUiItem = item
        curUiItem:setVisible(true)

        self.uiItemList[room.room_id] = curUiItem

        local tbIndex = ccui.Helper:seekWidgetByName(curUiItem, "tbIndex")
        tbIndex:setString(string.format("- %d -",tostring(room.club_index or 0)))

        for i=1,5 do
            ccui.Helper:seekWidgetByName(curUiItem, "player"..i):addTouchEventListener(function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    if self.isBaned then
                        commonlib.showTipDlg("您当前处于被封禁状态，无法在当前亲友圈打牌，请联系圈主/管理员解封!", nil, nil, nil, nil, true)
                        return
                    end
                    if self.is_back_fromroom == "true" then
                        commonlib.showReturnTips("不可加入其它房间，")
                    else
                        local clientIp = gt.getClientIp()
                        if self.data.club_info.isFZB == 1 and tonumber(clientIp[1]) == 0 and tonumber(clientIp[2]) == 0 then
                            commonlib.avoidJoinTip()
                        else
                            local net_msg = {
                                cmd = NetCmd.C2S_JOIN_ROOM,
                                room_id = room.room_id,
                                lat = clientIp[1],
                                lon = clientIp[2],
                            }
                            ymkj.SendData:send(json.encode(net_msg))
                        end
                    end
                end
            end)
        end

        local btJoin = ccui.Helper:seekWidgetByName(curUiItem, "btJoin")
        btJoin:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                print("btJoin",i)
                if self.isBaned then
                    commonlib.showTipDlg("您当前处于被封禁状态，无法在当前亲友圈打牌，请联系圈主/管理员解封!", nil, nil, nil, nil, true)
                    return
                end
                if self.is_back_fromroom == "true" then
                    commonlib.showReturnTips("不可加入其它房间，")
                else
                    local clientIp = gt.getClientIp()
                    if self.data.club_info.isFZB == 1 and tonumber(clientIp[1]) == 0 and tonumber(clientIp[2]) == 0 then
                        commonlib.avoidJoinTip()
                    else
                        local net_msg = {
                            cmd = NetCmd.C2S_JOIN_ROOM,
                            room_id = room.room_id,
                            lat = clientIp[1],
                            lon = clientIp[2],
                        }
                        ymkj.SendData:send(json.encode(net_msg))
                    end
                end
            end
        end)

        local btTip = curUiItem:getChildByName("btTip")
        btTip:setVisible(ClubHallUI.getClubStyle() ~= ClubHallUI.Elegant)
        btTip:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.began then
                AudioManager:playPressSound()
                print("btTip",i)
                local pox = 60
                if (i-1)%self.desknum == self.desknum-1 then
                    pox = -180
                end
                -- dump(room)
                if not self.ClubShuoMingLayer then
                    local ClubShuoMingLayer = require('club.ClubShuoMingLayer')
                    self.ClubShuoMingLayer = ClubShuoMingLayer:create({
                        club_room_info = room,
                        })
                    self.ClubShuoMingLayer:setAnchorPoint(cc.p(0,1))
                    self.ClubShuoMingLayer:setShuoMing(room)
                    LayerCont:addChild(self.ClubShuoMingLayer)

                    self.ClubShuoMingLayer:setLocalZOrder(SHOUMING_CARD_ZORDER)
                else
                    self.ClubShuoMingLayer:setShuoMing(room)
                    self.ClubShuoMingLayer:setVisible(true)
                end
                local pos = nil
                if self.desknum == 4 then
                    pos = btTip:convertToWorldSpace(cc.p(pox, - 400))
                elseif self.desknum == 5 then
                    pos = btTip:convertToWorldSpace(cc.p(pox, - 440))
                else
                    pos = btTip:convertToWorldSpace(cc.p(pox, - 330))
                end

                -- print('pos ' .. pos.x .. ' _ ' ..pos.y)
                local layerpos = LayerCont:convertToNodeSpace(pos)
                -- print('layerpos ' .. layerpos.x .. ' _ ' .. layerpos.y)
                self.ClubShuoMingLayer:setPosition(layerpos)
                -- end
            elseif eventType == ccui.TouchEventType.canceled then
                -- log('canceled')
                -- print("btTip",i)
                if self.ClubShuoMingLayer then
                    self.ClubShuoMingLayer:setVisible(false)
                end
            elseif eventType == ccui.TouchEventType.ended then
                -- log('ended')
                -- print("btTip",i)
                if self.ClubShuoMingLayer then
                    self.ClubShuoMingLayer:setVisible(false)
                end
            end
        end)

        local btChange = curUiItem:getChildByName("btChange")
        btChange:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                -- 修改条件 是普通成员且允许修改或者是群主，且房间无人
                if self.is_back_fromroom == "true" then
                    commonlib.showReturnTips("不可修改玩法，")
                else
                    if btChange.nTag == 1 then
                        -- print("btChange",i)
                        ----------修改桌子玩法时记录所选的游戏----------
                        local qipaiType = room.params.qipai_type
                        local preGameMap = {
                            ["mj_tdh"]   = "qyqpre_game1",
                            ["mj_kd"]    = "qyqpre_game1",
                            ['mj_gsj']   = 'qyqpre_game1',
                            ['mj_jz']    = 'qyqpre_game1',
                            ['mj_jzgsj'] = 'qyqpre_game1',
                            ["mj_xian"]  = "qyqpre_game2",
                            ["mj_lisi"]  = "qyqpre_game1",
                            ["pk_pdk"]   = "qyqpre_game3",
                            ["pk_ddz"]   = "qyqpre_game3",
                            ["pk_zgz"]   = "qyqpre_game3",
                            ['mj_hebei'] = 'qyqpre_game_hebei',
                            ['mj_hbtdh'] = 'qyqpre_game_hebei',
                            ['mj_dbz']   = 'qyqpre_game_hebei',
                            ['mj_fn']    = 'qyqpre_game_hebei',
                            ["pk_jdpdk"] = "qyqpre_game3",
                        }
                        if qipaiType == 'pk_pdk' and room.params.isJDPDK then
                            qipaiType = "pk_jdpdk"
                        end
                        if not preGameMap[qipaiType] then
                            log(qipaiType)
                        else
                            cc.UserDefault:getInstance():setStringForKey(preGameMap[qipaiType], qipaiType)
                            cc.UserDefault:getInstance():flush()
                        end

                        if preGameMap[qipaiType] == "qyqpre_game1" then
                            cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", 1)
                            cc.UserDefault:getInstance():flush()
                        elseif preGameMap[qipaiType] == "qyqpre_game2" then
                            cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", 2)
                            cc.UserDefault:getInstance():flush()
                        elseif preGameMap[qipaiType] == "qyqpre_game3" then
                            cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", 3)
                            cc.UserDefault:getInstance():flush()
                        elseif preGameMap[qipaiType] == 'qyqpre_game_hebei' then
                            cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", 4)
                            cc.UserDefault:getInstance():flush()
                        end
                        ------------------------
                        local CreateLayer = require("scene.CreateLayer")
                        self.mainScene:addChild(CreateLayer:create({
                            clubOpt = 2,
                            room_id = room.room_id,
                            club_id = self.data.club_info.club_id,
                            qunzhu = 1,
                            club_room_info = room,
                            mainScene = self.mainScene,
                            isGM = self.isBoss or self.isAdmin,
                            isFzb = self.data.club_info.isFZB
                        }))
                    -- 解散条件是群主且有人数且未满且未开始
                    elseif btChange.nTag == 2 then
                        -- print("btJieSan",i)
                        local input_msg = {
                            cmd = NetCmd.C2S_CLUB_JIESAN_ROOM,
                            room_id = room.room_id,
                            club_id = self.data.club_info.club_id,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    elseif btChange.nTag == 4 then
                        local input_msg = {
                            cmd = NetCmd.C2S_CLUB_ROOM_STATUS,
                            room_id = room.room_id,
                            club_id = self.data.club_info.club_id,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end
            end
        end)

        self:refreshRoomInfo(room.room_id)
    end

    local function setRoomItem()
        local pos_index = 0
        for i = 1, table.maxn(club_rooms) do
            if club_rooms[i] then
                pos_index = pos_index + 1
                local pos = self.clubItemPos[pos_index]
                local layerPosX = pos.x - uiItem:getPositionX()
                local layerPosY = pos.y - uiItem:getPositionY()
                local worldPos = uiItem:convertToWorldSpace(cc.p(layerPosX, layerPosY))
                local item = LayerCont:getChildByName('Desk ' .. i)
                if (not item or not item.hasSet) and worldPos.y + itemHeight > 0 then
                    setItem(i,club_rooms[i],pos)
                end
            end
        end
    end
    setRoomItem()

    local function ScrollViewCallBack(sender, eventType)
        if eventType == 4 then
            setRoomItem()
            -- if self.refreshPos then
            --     if self.data and self.data.club_info and self.data.club_info.club_id then
            --         self.clubLayerPos[self.data.club_info.club_id] = ScrollView:getInnerContainer():getPositionY()
            --     end
            -- end
        end
    end
    ScrollView:addEventListener(ScrollViewCallBack)

    -- for i,room in ipairs(club_rooms) do
    --     setItem(i,room)
    -- end

    local endtime = os.clock()
    print(string.format("加载亲友圈 cost time  : %.4f", endtime - starttime))

    self.max_desk = table.maxn(club_rooms)
    if not firstHasWX then
        self:refreshClubModify()
    end

    if isInit then
        local ClubData = require('club.ClubData')
        local clubs = ClubData.getClubs()
        if clubs and 0 ~= #clubs then
            self:onRcvGetClubList({clubs = clubs},true)
        end
        local input_msg = {
            cmd = NetCmd.C2S_GET_CLUB_LIST,
        }
        ymkj.SendData:send(json.encode(input_msg))
    else
        self:refreshClubList()
    end
    self.btnfangka:getChildByName("ImgAdd"):setVisible(true)
    if not self.isBoss then
        self.btnfangka:getChildByName("ImgAdd"):setVisible(false)
    end
    -- local children = LayerCont:getChildren()
    -- print('$ --------------- ' .. tostring(#children))
    -- self:refreshRodHot()

    self:delayReadNetData()

    self:memoryLog()
end

function ClubLayer:refreshRodHot(bShowRehot)
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    for i=1,5 do
        local btSel = tolua.cast(Panel_bottom:getChildByName("btSel_" .. i), "ccui.Button")
        if self.nameTab[i] == "friend" then
            local red_dot = btSel:getChildByName('red_dot')
            if not red_dot then
                red_dot = cc.Sprite:create("ui/qj_main/red_dot.png")
                red_dot:setPosition(cc.p(75, 50))
                red_dot:setName('red_dot')
                red_dot:setVisible(false)
                btSel:addChild(red_dot)
            end
            if bShowRehot then
                red_dot:setVisible(true)
                red_dot:stopAllActions()
                red_dot:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),
                    cc.DelayTime:create(0.2), cc.FadeTo:create(0.3, 127))))
            else
                red_dot:setVisible(false)
                red_dot:stopAllActions()
            end
            break
        end
    end
end

function ClubLayer:onSelEvent(name)
    if not self.data or not self.clubs then
        return
    end
    if name == "friend" then
        local ClubMemberLayer = require("club.ClubMemberLayer")
        local layer = ClubMemberLayer:create({
            isBoss = self.isBoss,
            isAdmin = self.isAdmin,
            isFullAdmin = self.isFullAdmin,
            data = self.data,
            parent = self,
        })
        layer:setName('ClubMemberLayer')
        self:addChild(layer)
    elseif name == "ways" then
        local CreateLayer = require("scene.CreateLayer")
        local layer = CreateLayer:create({
            clubOpt = 3,
            club_id = self.data.club_info.club_id,
            qunzhu  = 1,
            mainScene = self.mainScene,
            isGM    = self.isBoss or self.isAdmin,
        })
        self.mainScene:addChild(layer)
    elseif name == "club" then
        local ClubCreateJoin = require("club.ClubCreateJoin")
        local layer = ClubCreateJoin:create({isBoss = self.iAmBoss, clubs = self.clubs,mainScene = self.mainScene})
        layer:setName('ClubCreateJoin')
        self:addChild(layer)
    elseif name == "log" then
        local ClubLogLayer = require("club.ClubLogLayer")
        local layer = ClubLogLayer:create({data = self.data})
        self:addChild(layer)
    elseif name == "rank" then
        local ClubRankLayer = require("club.ClubRankLayer")
        local layer = ClubRankLayer:create({
            isBoss = self.isBoss,
            isAdmin = self.isAdmin,
            club_id = self.data.club_info.club_id,
            data = self.data
            })
        self:addChild(layer)
    elseif name == "quckjoin" then
        local isOpen = self.data.club_info.isOpen
        if isOpen == 0 then
            commonlib.showLocalTip('亲友圈暂时关闭，快去喊房主开启!')
            return
        end
        self:onQuickJoin()
    end
end

function ClubLayer:onQuickJoin()
    if self.isBaned then
        commonlib.showTipDlg("您当前处于被封禁状态，无法在当前亲友圈打牌，请联系圈主/管理员解封!", nil, nil, nil, nil, true)
        return
    end
    local clientIp = gt.getClientIp()
    -- 默认房
    local default_room_id = nil
    -- 修改房
    local repair_room_id = nil
    local club_rooms = clone(self.data.club_rooms)
    club_rooms = self:checkRoom(club_rooms)
    self:sortRoomByIndex(club_rooms)

    local default_min_empty_chaird = 10
    local repair_min_empty_chaird = 10
    for i , v in ipairs(club_rooms) do
        local empty_chaird = v.need_people_num - v.people_num
        if v.room_type == 1 then
            if default_min_empty_chaird > empty_chaird and empty_chaird > 0 then
                default_min_empty_chaird = empty_chaird
                default_room_id = v.room_id
            end
        else
            if repair_min_empty_chaird > empty_chaird and empty_chaird > 0 then
                repair_min_empty_chaird = empty_chaird
                repair_room_id = v.room_id
            end
        end
    end
    -- 优先默认房间，人最多且未满房间
    local room_id = default_room_id
    if not room_id then
        -- 其次修改房，人最多且未满房间
        room_id = repair_room_id
    end
    if room_id then
        local net_msg = {
            cmd = NetCmd.C2S_JOIN_ROOM,
            room_id = room_id,
            lat = clientIp[1],
            lon = clientIp[2],
        }
        ymkj.SendData:send(json.encode(net_msg))
    else
        commonlib.showLocalTip("没有找到能快速加入的房间哦~~")
    end
end

function ClubLayer:refreshClubBoss()
    local uid = gt.getData('uid')
    for i,v in ipairs(self.clubs) do
        if uid == v.club_id then
            self.iAmBoss = true
            break
        end
    end
end

function ClubLayer:JieSanRoomTips(rtn_msg)
    local csb = ClubHallUI.getInstance().csb_club_jiesanroom_dialog
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    ccui.Helper:seekWidgetByName(node,"btCanel"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            node:removeFromParent(true)
        end
    end)
    ccui.Helper:seekWidgetByName(node,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local input_msg = {
                cmd = NetCmd.C2S_CLUB_JIESAN_ROOM,
                room_id = rtn_msg.room_id,
                isForceJieSan = true,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
            node:removeFromParent(true)
        end
    end)
    if rtn_msg.total_ju > 100 then
        ccui.Helper:seekWidgetByName(node,"gameJu"):setString("游戏圈数:"..(rtn_msg.cur_quan or 1)..'/'..(rtn_msg.total_ju - 100))
    else
        ccui.Helper:seekWidgetByName(node,"gameJu"):setString("游戏局数:"..(rtn_msg.cur_ju or 1)..'/'..rtn_msg.total_ju)
    end
    local str = ""
    for i=1,6 do
        if #rtn_msg.players < 5 then
            local pos= 466.63 - (i-1)* 57.6
            ccui.Helper:seekWidgetByName(node,"Player"..i):setPositionY(pos)
            ccui.Helper:seekWidgetByName(node,"Player"..i.."_status"):setPositionY(pos)
        else
            local pos= 466.63 - (i-1)* 43.2
            ccui.Helper:seekWidgetByName(node,"Player"..i):setPositionY(pos)
            ccui.Helper:seekWidgetByName(node,"Player"..i.."_status"):setPositionY(pos)
        end
        if rtn_msg.players[i] then
            if rtn_msg.players[i].out_line then
                str = "离线"
            else
                str = "游戏中"
            end
            if pcall(commonlib.GetMaxLenString, rtn_msg.players[i].name, 14) then
                ccui.Helper:seekWidgetByName(node,"Player"..i):setString(commonlib.GetMaxLenString(rtn_msg.players[i].name, 14))
            else
                ccui.Helper:seekWidgetByName(node,"Player"..i):setString(rtn_msg.players[i].name)
            end
            ccui.Helper:seekWidgetByName(node,"Player"..i.."_status"):setString(str)
        else
            ccui.Helper:seekWidgetByName(node,"Player"..i):setVisible(false)
            ccui.Helper:seekWidgetByName(node,"Player"..i.."_status"):setVisible(false)
        end
    end


end

function ClubLayer:refreshMemStaus()
    local Panel_bottom = ccui.Helper:seekWidgetByName(self.node,"Panel_bottom")
    local clubid = ccui.Helper:seekWidgetByName(Panel_bottom,"clubid")
    local num = ccui.Helper:seekWidgetByName(Panel_bottom,"num")
    clubid:setString(string.format("亲友圈ID:%s",self.data.club_info.club_id))
    num:setString(string.format("总人数:    %d/%d",self.data.club_info.onlineCount,self.data.club_info.memCount))
end

function ClubLayer:showResetWaysTips()
    commonlib.showLocalTip('管理员已修改此玩法')
end

function ClubLayer:showJieSan()
    commonlib.showLocalTip('房间已被管理员解散')
end

function ClubLayer:checkRoom(rooms)
    local check_rooms = {}
    for i = 1 , table.maxn(rooms) do
        if rooms[i] and rooms[i].club_index and rooms[i].room_id then
            check_rooms[#check_rooms+1] = rooms[i]
        end
    end
    return check_rooms
end

function ClubLayer:sortRoomByIndex(rooms)
    local rooms_sort = {}
    for i = 1 , table.maxn(rooms) do
        if rooms[i] then
            rooms_sort[#rooms_sort+1] = rooms[i]
        end
    end
    local function sortRoom(a,b)
        if a.club_index < b.club_index then
            return true
        end
        return false
    end
    table.sort(rooms_sort,sortRoom)

    rooms = rooms_sort
end

function ClubLayer:set2objectPosition(parent,children,algin)
    algin = algin or 5
    local wanfaLabel = children[1]
    local change = children[2]
    if not children[2]:isVisible() then
        wanfaLabel:setPositionX(parent:getContentSize().width/2)
        return
    end

    local algin = algin
    local width = wanfaLabel:getContentSize().width
    if width <= 85 then
        algin = algin*3
    elseif width <= 109 then
        algin = algin*2
    end

    local pwidth = parent:getContentSize().width

    local swidth = wanfaLabel:getContentSize().width + change:getContentSize().width + algin
    -- print('长度')
    -- print(wanfaLabel:getContentSize().width)
    local startpos = (pwidth - swidth)/2

    wanfaLabel:setPositionX(startpos + wanfaLabel:getContentSize().width*wanfaLabel:getAnchorPoint().x)

    change:setPositionX(wanfaLabel:getPositionX() + wanfaLabel:getContentSize().width * (1-wanfaLabel:getAnchorPoint().x)
     + algin + change:getContentSize().width*change:getAnchorPoint().x)
end

function ClubLayer:setWeiXin()
    local csb = DTUI.getInstance().csb_DT_RelNameLayer
    local smnode = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(smnode, 10)

    smnode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(smnode)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(smnode,"btExit"), "ccui.Widget")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                smnode:removeFromParent(true)
            end
        end
    )
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(smnode, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(smnode, "Panel_2"))
    local login_un_input =   tolua.cast(ccui.Helper:seekWidgetByName(smnode, "eName"), "ccui.TextField")
    local login_pw_input =   tolua.cast(ccui.Helper:seekWidgetByName(smnode, "eIDcard"), "ccui.TextField")
    local IDcardBg       = ccui.Helper:seekWidgetByName(smnode, "IDcardBg")
    local IDcard         = ccui.Helper:seekWidgetByName(smnode, "IDcard")

    local title   = ccui.Helper:seekWidgetByName(smnode, "title")
    local Panel_3 = ccui.Helper:seekWidgetByName(smnode, "Panel_3")
    local name    = ccui.Helper:seekWidgetByName(smnode, "name")
    local nameBg  = ccui.Helper:seekWidgetByName(smnode, "nameBg")

    IDcard:setVisible(false)
    IDcardBg:setVisible(false)
    login_pw_input:setVisible(false)

    title:loadTexture("ui/qj_common_new_year/wxsetting.png")
    Panel_3:setPositionY(277)
    name:setString("微信")
    name:setPositionY(144)
    nameBg:setPositionY(144)
    nameBg:loadTexture("ui/qj_common_new_year/namebg.png")
    login_un_input:setPlaceHolderColor(cc.c4b(255,244,221,255))
    login_un_input:setPlaceHolder("请输入你的微信号")
    login_un_input:setColor(cc.c3b(255, 244, 221))

    ccui.Helper:seekWidgetByName(smnode,"btEnter"):addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
                local pwd = login_un_input:getString()
                if string.find(pwd,"[^%w_-]") or (string.len(pwd) < 6) or (string.len(pwd) > 20) or string.find(string.sub(pwd, 1, 1), "[^%a]") then
                    commonlib.showLocalTip("请填写正确的微信号")
                    return
                end

                smnode:removeFromParent(true)
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_MODIFY,
                    weixin  = pwd,
                    club_id = self.data.club_info.club_id,
                    uid     = ProfileManager.GetProfile().uid,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end
    )
end

function ClubLayer:stopAllDownHead()
    local Panel_mid = ccui.Helper:seekWidgetByName(self.node,"Panel_mid")
    local ScrollView = ccui.Helper:seekWidgetByName(Panel_mid, "ScrollView")
    local LayerCont = ScrollView:getChildByName("LayerCont")
    for i = 1, 1000 do
        local item = LayerCont:getChildByName('Desk ' .. i)
        if not item then
            break
        end
        for j=1,6 do
            local uiPlayer = item:getChildByName("player" .. j)
            if not uiPlayer then
                gt.uploadErr('ClubLayer:stopAllDownHead old res')
                break
            end
            local uiHead = uiPlayer:getChildByName("head")
            uiHead:setVisible(false)
            uiHead:stopAllActions()
        end
    end
end

return ClubLayer