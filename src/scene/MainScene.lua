require('scene.DTUI')
require('club.ClubHallUI')

local ErrStrToClient = require('common.ErrStrToClient')

local ZOrder = {
    BG     = 1,
    DIALOG = 2,
    TIP    = 3,
    GRID   = 100,
}

local MainScene = class("MainScene",function()
    return cc.Scene:create()
end)

function MainScene.create_from_login()

    g_yuyin_msg = nil
    if g_os == "ios" and ymkj.closeWeb then
        ymkj.closeWeb()
    end
    cc.Director:getInstance():getEventDispatcher():removeAllEventListeners()
    local sendId = 1
    if cc.UserDefault:getInstance():getStringForKey("NOTICE") ~= "" then
        local notices = json.decode(cc.UserDefault:getInstance():getStringForKey("NOTICE"))
        for i,v in ipairs(notices) do
            if v.id > sendId then
                sendId = v.id
            end
        end
    end
    local net_msg = {
        cmd = NetCmd.C2S_NOTICE,
        minId = sendId,
    }
    ymkj.SendData:send(json.encode(net_msg))
    local scene = MainScene.new()
    scene.isFromLogin = true
    return scene
end

function MainScene.create(args)
    g_yuyin_msg = nil
    if g_os == "ios" and ymkj.closeWeb then
        ymkj.closeWeb()
    end

    cc.Director:getInstance():resume()
    cc.Director:getInstance():getScheduler():setTimeScale(1)

    cc.Director:getInstance():getEventDispatcher():removeAllEventListeners()

    AudioManager:restartManager()
    AudioManager:playPubBgMusic()

    local scene = MainScene.new()
    scene.operType = args and args.operType
    return scene
end

function MainScene:ctor()
    self.is_in_main = true
    RoomController:getModel():reset()
    self:enableNodeEvents()
    self:createLayerMenu()
end

function MainScene:onEnter()
    self:openAgentBind()

    if GameGlobal.ZjLayerMainMsg or GameGlobal.ZjLayerMain then
        local ZjLayer = require("scene.ZjLayer")
        self:addChild(ZjLayer:create(), ZOrder.DIALOG)
    end
    gt.removeUnusedRes()

    self:onUpdate(function(dt)
        self:update(dt)
    end)
    self:autoJoinRoom()

    self:doesBaseVerNeedUpdate()
end

function MainScene:doesBaseVerNeedUpdate()
    local noticeUpdateVersion = gt.getConf('notice_update_version')
    if g_base_ver <= noticeUpdateVersion then
        local noticeUpdateVersionTime = gt.getLocalInt('noticeUpdateVersionTime',0)
        if noticeUpdateVersionTime <= gt.getCurDayHourTime(0) then
            gt.setLocalInt('noticeUpdateVersionTime',os.time(),true)
            commonlib.showTipDlg("游戏有新的更新，请更新游戏体验最新版本！", function(is_ok)
                if is_ok then
                    gt.openUrl(gt.getConf('download_url'))
                else

                end
            end)
        end
    end
end

function MainScene:onExit()

end

function MainScene:autoJoinRoom(isFEvent)
    gt.performWithDelay(self,function( ... )
        local NativeUtil = require("common.NativeUtil")
        NativeUtil:getGameInfo({
            classId = function(ret)
                dump(ret,"getGameInfo")
                if (self.isFromLogin or isFEvent) and ret.roomId and ret.roomId ~= "" and ret.roomId ~= "0" then
                    self.isFromLogin = nil
                    local clientIp = gt.getClientIp()
                    local net_msg = {
                        cmd = NetCmd.C2S_JOIN_ROOM,
                        room_id = tonumber(ret.roomId),
                        lat = clientIp[1],
                        lon = clientIp[2],
                    }
                    ymkj.SendData:send(json.encode(net_msg))
                end
            end
        })
    end,0.1)
end

function MainScene:playRedBag()
    if self.isPlayRedbag then return end
    local data = RedBagController:getModel():pop()
    if not data then return end
    local Panel_msg = ccui.Helper:seekWidgetByName(self.node,"Panel_msg")
    local RichLabel = require("modules.view.RichLabel")
    self.isPlayRedbag = true
    self.msg_lbl:setVisible(false)
    local spriteHbGg = display.newNode()
    Panel_msg:addChild(spriteHbGg)
    spriteHbGg:setPosition(cc.p(0,0))
    local Hb_type = "巧遇财神到"
    local label ={}
    for i=1,#data.reds do
        local amountRmb = data.reds[i].amount/100
        if data.type == 1 then
            Hb_type = "巧遇财神到"
        elseif data.type == 2 then
            Hb_type = "遭遇红包雨"
        end
        local nameCut = data.reds[i].name

        label[i] = RichLabel:create({
            fontName = "ui/zhunyuan.ttf",
            fontSize = 25,
            fontColor = cc.c3b(255, 0, 0),
            dimensions = cc.size(800, 200),
            text = "[fontColor=ffffff fontSize=25]玩家[/fontColor]".."[fontColor=ff5047 fontSize=25]"..nameCut.."[/fontColor]".."[fontColor=ffffff fontSize=25]"..Hb_type.."[/fontColor]"..
            "[fontColor=ffffff fontSize=25],获得￥[/fontColor]".."[fontColor=ff5047 fontSize=25]"..amountRmb.."[/fontColor]".."[fontColor=ffffff fontSize=25]元红包[/fontColor]",
        })
        spriteHbGg:addChild(label[i])
        label[i]:setAnchorPoint(cc.p(0,0.5))
        label[i]:setPosition(cc.p(90, 7-50*(i -1)))
    end

    local motion = transition.sequence({
        cc.MoveBy:create(1.5,cc.p(0,25)),
        cc.DelayTime:create(1.0),
        cc.MoveBy:create(1.0,cc.p(0,25)),
    })
    local motion1 = cc.Repeat:create(motion,#data.reds)
    spriteHbGg:runAction(
        transition.sequence({
            motion1,
            cc.CallFunc:create(function()
                self.isPlayRedbag = nil
                self.msg_lbl:setVisible(true)
                spriteHbGg:removeSelf()
            end)
        })
    )
end

function MainScene:update(dt)
    if self.isPlayRedbag == nil then
        self:playRedBag()
    end
end

function MainScene:keypadEvent()

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

function MainScene:registerEventListener()
    ymkj.GlobalData:getInstance():clear()

    local NETMSG_LISTENERS = {
        [NetCmd.S2C_LOAD_USER_DATA]      = handler(self, self.onRcvLoadUserData),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSyncUserData),
        [NetCmd.S2C_HUODONG]             = handler(self, self.onRcvHuodong),
        [NetCmd.S2C_NOTICE]              = handler(self, self.onRcvNotice),
        [NetCmd.S2C_CHARGE]              = handler(self, self.onRcvCharge),
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_MJ_TDH_CREATE_ROOM]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_KD_CREATE_ROOM]   = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_XIAN_CREATE_ROOM] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_LISI_CREATE_ROOM] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_GSJ_CREATE_ROOM]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JZ_CREATE_ROOM]   = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JOIN_ROOM_AGAIN]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JOIN_ROOM]        = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JZGSJ_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_HEBEI_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_HBTDH_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_BDDBZ_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_FN_CREATE_ROOM]   = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_LOGDATA]             = handler(self, self.onRcvLogData),
        [NetCmd.S2C_INFO_MAX]            = handler(self, self.onRcvInfoMax),
        -- [NetCmd.S2C_QUNZHU]              = handler(self, self.onRcvQunZhu),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_APPLY_JOIN]     = handler(self, self.onRcvClubApplyJoin),
        [NetCmd.S2C_CLUB_INVITE_PLAY]    = handler(self, self.onRcvClubInvitePlay),
    }
    for k, v in pairs(NETMSG_LISTENERS) do
        gt.addNetMsgListener(k, v)
    end
    local CUSTOM_LISTENERS = {
        ["game_conf"]         = handler(self, self.onGameConf),
        ["version_number"]    = handler(self, self.onVersionNumber),
        ["req_redbag_action"] = handler(self, self.resRedBagAction),
        ["APP_ENTER_FOREGROUND_EVENT"] = handler(self,self.onWillEnterForeground),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
    ClubController:registerEventListener()
end

function MainScene:unregisterEventListener()
    local LISTENER_NAMES = {
        [NetCmd.S2C_LOAD_USER_DATA]      = handler(self, self.onRcvLoadUserData),
        [NetCmd.S2C_SYNC_USER_DATA]      = handler(self, self.onRcvSyncUserData),
        [NetCmd.S2C_HUODONG]             = handler(self, self.onRcvHuodong),
        [NetCmd.S2C_NOTICE]              = handler(self, self.onRcvNotice),
        [NetCmd.S2C_CHARGE]              = handler(self, self.onRcvCharge),
        [NetCmd.S2C_BROAD]               = handler(self, self.onRcvBroad),
        [NetCmd.S2C_MJ_TDH_CREATE_ROOM]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_KD_CREATE_ROOM]   = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_XIAN_CREATE_ROOM] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_LISI_CREATE_ROOM] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_GSJ_CREATE_ROOM]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JOIN_ROOM_AGAIN]  = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JOIN_ROOM]        = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_JZGSJ_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_HEBEI_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_HBTDH_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_BDDBZ_CREATE_ROOM]= handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_MJ_FN_CREATE_ROOM]   = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_CREATE_ROOM]     = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_JOIN_ROOM]       = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN] = handler(self, self.onEnterGameRoom),
        [NetCmd.S2C_JIESAN]              = handler(self, self.onRcvJiesan),
        [NetCmd.S2C_LOGDATA]             = handler(self, self.onRcvLogData),
        [NetCmd.S2C_INFO_MAX]            = handler(self, self.onRcvInfoMax),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]    = handler(self, self.onRcvSyncClubNotify),
        [NetCmd.S2C_CLUB_APPLY_JOIN]     = handler(self, self.onRcvClubApplyJoin),
        [NetCmd.S2C_CLUB_INVITE_PLAY]    = handler(self, self.onRcvClubInvitePlay),

        ["game_conf"]         = handler(self, self.onGameConf),
        ["version_number"]    = handler(self, self.onVersionNumber),
        ["req_redbag_action"] = handler(self, self.resRedBagAction),
        ["APP_ENTER_FOREGROUND_EVENT"] = handler(self,self.onWillEnterForeground),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    self.img_head = nil
    commonlib.showLoading(true)

    local clubLayer = self:getChildByName("ClubLayer")
    if clubLayer then
        clubLayer:exitLayer()
    end
    ClubController:unregisterEventListener()
end

function MainScene:onWillEnterForeground()
    self:autoJoinRoom(true)
end

function MainScene:onRcvLoadUserData(rtn_msg)
    -- dump(rtn_msg)

    -- log('@@@@@@@@@@@@@@@@@@@@@@ rtn_msg.db.qunzhu ' .. tostring(rtn_msg.db.qunzhu))

    GameGlobal.qunzhu = rtn_msg.db and rtn_msg.db.qunzhu or nil
    ProfileManager.SetProfile(rtn_msg.db)
    if kefuTextConfig.invite_code then
        ProfileManager.GetProfile().invite_code = kefuTextConfig.invite_code
        kefuTextConfig.invite_code = nil
    end

    if kefuTextConfig.club_url then
        ProfileManager.GetProfile().club_url = kefuTextConfig.club_url
        ccui.Helper:seekWidgetByName(self.topPanel, "ShareBtn"):setVisible(true)
        kefuTextConfig.club_url = nil
    end
    local phoneNum = cc.UserDefault:getInstance():getStringForKey("bindphone", "0")
    if rtn_msg.db and rtn_msg.db.phone then
        if phoneNum ~= "0" then
            if rtn_msg.db.phone ~= tonumber(phoneNum) then
                cc.UserDefault:getInstance():setStringForKey("zzrecord","")
            end
        end
        cc.UserDefault:getInstance():setStringForKey("bindphone", tostring(rtn_msg.db.phone))
        cc.UserDefault:getInstance():flush()
    end
    self:initHuobiInfo()

    cc.UserDefault:getInstance():setStringForKey("s3s3s3", (rtn_msg.db.recharge or '0'))
    cc.UserDefault:getInstance():setStringForKey("s4s4s4", (rtn_msg.db.cost_card or '0'))
    cc.UserDefault:getInstance():flush()

    local db = rtn_msg.db
    local TalkingData = require("scene.TalkingData")
    TalkingData:call("onLogin",{
            uid = tostring(db.uid),
            name = db.name or "",
            accountType = 6,
            level = 1,
            gender = db.sex or 1,
            age = 18,
            gameServer = "gameServer",
        },function(ok,ret)
            if ok then
                TalkingData.registeredAccount = true
            end
        end)
end

function MainScene:onRcvSyncUserData(rtn_msg)
    if rtn_msg.key == "card" then
        local profile = ProfileManager.GetProfile()
        profile.card = rtn_msg.value
        self:initHuobiInfo(true)
    elseif rtn_msg.key == "score" then
        local profile = ProfileManager.GetProfile()
        profile.score = rtn_msg.value
        self:initHuobiInfo(true)
    end
end

function MainScene:onRcvHuodong(rtn_msg)
    local is_first = ((kefuTextConfig.wx ~= rtn_msg.wx) or (kefuTextConfig.delegate ~= rtn_msg.delegate))
    kefuTextConfig.wx = rtn_msg.wx or kefuTextConfig.wx
    kefuTextConfig.qq = rtn_msg.qq or kefuTextConfig.qq
    kefuTextConfig.delegate = rtn_msg.delegate or kefuTextConfig.delegate
    kefuTextConfig.guanggao = rtn_msg.guanggao
    if rtn_msg.hd_list and rtn_msg.hd_list ~= "" then
        kefuTextConfig.hd_list = string.split(rtn_msg.hd_list, ",")
    end
    kefuTextConfig.isOpenXT = false
    if rtn_msg.games and rtn_msg.games ~= "" then
        kefuTextConfig.games = {}
        for i, v in ipairs(string.split(rtn_msg.games, ",") or {}) do
            kefuTextConfig.games[i] = tonumber(v)
        end
        for i, v in pairs(kefuTextConfig.games) do
            if v == 14 then
                kefuTextConfig.isOpenXT = true
            end
        end
        --kefuTextConfig.games[14] = nil
    end

    if rtn_msg.appid and rtn_msg.appid ~= "" then
        if rtn_msg.appid ~= "copy" then
            if (g_os == "ios" or g_is_multi_wechat) and ymkj.registerApp then
                ymkj.registerApp(rtn_msg.appid)
                g_copy_share = nil
            else
                g_copy_share = true
            end
        else
            g_copy_share = true
        end
    else
        g_copy_share = nil
        if ymkj.getAppInfo then
            local app_info = ymkj.getAppInfo()
            if type(app_info) == "string" then
                local tab = string.split(app_info,"|")
                if tab[2] and tab[2] == " com.thcs.yyzz.hnyl" then
                    ymkj.registerApp("wx5d50213ded15555c")
                end
            end
        end
    end

    if g_author_game then
        kefuTextConfig.broadcast = {"欢迎光临，本平台仅供娱乐，禁止赌博"}
    elseif rtn_msg.fix_msg and rtn_msg.fix_msg ~= "" then
        if ios_checking then
            kefuTextConfig.broadcast = {"欢迎光临"}
        else
            kefuTextConfig.broadcast = string.split(rtn_msg.fix_msg, ";") or kefuTextConfig.broadcast
        end
    end

    if rtn_msg.invite_code then
        if  ProfileManager.GetProfile() then
            ProfileManager.GetProfile().invite_code = rtn_msg.invite_code
        else
            kefuTextConfig.invite_code = rtn_msg.invite_code
        end
    end

    if rtn_msg.club_url and rtn_msg.club_url ~= "" then
        if ProfileManager.GetProfile() then
            ProfileManager.GetProfile().club_url = rtn_msg.club_url
            ccui.Helper:seekWidgetByName(self.topPanel, "ShareBtn"):setVisible(true)
        else
            kefuTextConfig.club_url = rtn_msg.club_url
        end
    end


    kefuTextConfig.youhui = rtn_msg.youhui or kefuTextConfig.youhui
    self:enterMain(true)

    if rtn_msg.hd_img and not ios_checking and is_first then
        local is_new_install = cc.UserDefault:getInstance():getStringForKey("new_install", "1")
        if is_new_install == "1" then
            require 'scene.GameSettingDefault'
            gt.setLocal("int", "pingmian", GameSettingDefault.MJ_STYLE, true)
            cc.UserDefault:getInstance():setStringForKey("new_install", "0")
            cc.UserDefault:getInstance():flush()
            kefuTextConfig.notice_list = {{}}
            kefuTextConfig.notice_list[2] = {name= rtn_msg.hd_name, img= rtn_msg.hd_img}
        else
            kefuTextConfig.notice_list = {{name= rtn_msg.hd_name, img= rtn_msg.hd_img}}
        end
        if rtn_msg.other_hd_name and rtn_msg.other_hd_img and rtn_msg.other_hd_img ~= "" then
            local other_hd_name = string.split(rtn_msg.other_hd_name, ",")
            local other_hd_img = string.split(rtn_msg.other_hd_img, ",")
            for i, v in ipairs(other_hd_img) do
                kefuTextConfig.notice_list[i+1] = {name=other_hd_name[i], img = v}
            end
        end
        if is_new_install ~= "1" then
            kefuTextConfig.notice_list[#kefuTextConfig.notice_list+1] = {}
        end
    end
end

function MainScene:onRcvNotice(rtn_msg)
    local profile  = ProfileManager.GetProfile()
    local isQunzhu = false
    if profile and profile.qunzhu == 1 then
        isQunzhu = true
    end
    if rtn_msg.notices then
        if cc.UserDefault:getInstance():getStringForKey("NOTICE") == "" then
            self.notices = rtn_msg.notices
            for i,v in ipairs(self.notices) do
                if v.is_popup == 1 then
                    if v.is_qunzhu == 1 then
                        if isQunzhu then
                            self:showHDDlg(v)
                            v.is_new = false
                        end
                    else
                        self:showHDDlg(v)
                        v.is_new = false
                    end
                else
                    v.is_new = true
                    if not ios_checking then
                        self.red_dot:setVisible(true)
                        self.red_dot:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),
                            cc.DelayTime:create(0.2), cc.FadeTo:create(0.3, 127))))
                    end
                end
            end
            cc.UserDefault:getInstance():setStringForKey("NOTICE", json.encode(self.notices))
            cc.UserDefault:getInstance():flush()
        else
            --无消息播放动画
            if RedBagController:HBPlay() then
                local actionLayer = require("modules.view.RedBagActionLayer"):create()
                self:addChild(actionLayer,ZOrder.TIP+1)
            end
            self.notices = json.decode(cc.UserDefault:getInstance():getStringForKey("NOTICE"))
            if rtn_msg.ignoreIds then
                for __,v in ipairs(rtn_msg.ignoreIds) do
                    for i=#self.notices, 1, -1 do
                        if v == self.notices[i].id then
                            table.remove(self.notices,i)
                        end
                    end
                end
            end
            if rtn_msg.popupIds and #rtn_msg.popupIds > 0 then
                for __,v in ipairs(self.notices) do
                    local is_change = false
                    for i=#rtn_msg.popupIds, 1, -1 do
                        if v.id == rtn_msg.popupIds[i] then
                            v.is_popup = 1
                            v.is_new = false
                            is_change = true
                        end
                    end
                    if not is_change then
                        v.is_popup = 0
                    end
                end
            else
                for __,v in ipairs(self.notices) do
                    v.is_popup = 0
                end
            end
            for __,v in ipairs(rtn_msg.notices) do
                local is_new_notice = true
                for __,vv in ipairs(self.notices) do
                    if vv.id == v.id then
                        is_new_notice = false
                    end
                end
                if is_new_notice then
                    table.insert(self.notices,v)
                    if v.is_popup == 1 then
                        self.notices[#self.notices].is_new = false
                    else
                        self.notices[#self.notices].is_new = true
                    end
                end
            end
            for i,v in ipairs(self.notices) do
                if v.is_popup == 1 then
                    if v.is_qunzhu == 1 then
                        if isQunzhu then
                            self:showHDDlg(v)
                        end
                    else
                        self:showHDDlg(v)
                    end
                end
                if v.is_new == true and not ios_checking then
                    self.red_dot:setVisible(true)
                    self.red_dot:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),
                        cc.DelayTime:create(0.2), cc.FadeTo:create(0.3, 127))))
                end
            end
            cc.UserDefault:getInstance():setStringForKey("NOTICE", json.encode(self.notices))
            cc.UserDefault:getInstance():flush()
        end
    end
end

function MainScene:onRcvCharge(rtn_msg)
    local profile = ProfileManager.GetProfile()
    profile.card = rtn_msg.left
    profile.score = rtn_msg.left_score or profile.score
    self:initHuobiInfo(true)
    local str = "充值成功，新增"..rtn_msg.add_cards.."张房卡"
    if rtn_msg.add_score then
        str = str .. rtn_msg.add_score .. "个粽子"
    end
    commonlib.showLocalTip(str)
    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("cards_change")
end

function MainScene:onRcvBroad(rtn_msg)
    if not rtn_msg.typ then
        commonlib.showTipDlg(rtn_msg.content or "系统提示")
    else
        if rtn_msg.is_hb then
            for i=1,3 do
                self.msg_content_list[#self.msg_content_list+1]=rtn_msg.content
            end
        else
            self.msg_content_list[#self.msg_content_list+1]=rtn_msg.content
        end
    end
end

-- NetCmd.S2C_XXX_CREATE_ROOM NetCmd.S2C_XXX_JOIN_ROOM NetCmd.S2C_XXX_JOIN_ROOM_AGAIN 三种消息通用处理
-- 这三种消息都要进入房间
function MainScene:onEnterGameRoom(rtn_msg)
    local profile = ProfileManager.GetProfile()
    local clientIp = gt.getClientIp()
    if rtn_msg.errno and rtn_msg.errno ~= 0 then
        self.number = 0
        self.inputNum = 0
        if self.number_lbl then
            self.number_lbl:setString("请输入房间号")
        end
        if rtn_msg.cmd ~= NetCmd.S2C_MJ_JOIN_ROOM_AGAIN
            or rtn_msg.cmd ~= NetCmd.S2C_PDK_JOIN_ROOM_AGAIN
            or rtn_msg.cmd ~= NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN
            or rtn_msg.cmd ~= NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN
            then
            if rtn_msg.errno == 1023 then
                if  tonumber(clientIp[1]) == 0 and tonumber(clientIp[2]) == 0 then
                    commonlib.avoidJoinTip()
                else
                    commonlib.avoidJoinTip("距离太近或IP相同")
                end
            else
                self:showErrTip(rtn_msg)
            end
        elseif rtn_msg.errno == 1010 then
            commonlib.showLocalTip("您的房间已经结束或解散了")
        elseif rtn_msg.errno ~= 0 then
            commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or "")
        end
        return
    end
    if rtn_msg.room_id and rtn_msg.room_id == 0 then
        commonlib.showLocalTip('修改失败,必须开启GPS')
        return
    end
    -- self.ui:removeFromParent()
    self:unregisterEventListener()

    -- 跑得快消息收发更改
    if rtn_msg.cmd == NetCmd.S2C_PDK_CREATE_ROOM or
        rtn_msg.cmd == NetCmd.S2C_PDK_JOIN_ROOM or
        rtn_msg.cmd == NetCmd.S2C_PDK_JOIN_ROOM_AGAIN or
        rtn_msg.cmd == NetCmd.S2C_DDZ_CREATE_ROOM or
        rtn_msg.cmd == NetCmd.S2C_DDZ_JOIN_ROOM or
        rtn_msg.cmd == NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN
        then
        GameController:registerEventListener()
    end

    local qipaiType = rtn_msg.room_info.qipai_type

    if rtn_msg.cmd ~= NetCmd.S2C_MJ_JOIN_ROOM_AGAIN
        and rtn_msg.cmd ~= NetCmd.S2C_PDK_JOIN_ROOM_AGAIN
        and rtn_msg.cmd ~= NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN
        and rtn_msg.cmd ~= NetCmd.S2C_ZGZ_JOIN_ROOM_AGAIN
        then
        local preGameMap = {
            ["mj_tdh"]  = "pre_game1",
            ["mj_kd"]   = "pre_game1",
            ['mj_gsj']  = 'pre_game1',
            ['mj_jz']   = 'pre_game1',
            ['mj_jzgsj']= 'pre_game1',
            ["mj_xian"] = "pre_game2",
            ["mj_lisi"] = "pre_game1",
            ["pk_pdk"]  = "pre_game3",
            ["pk_jdpdk"]= "pre_game3",
            ["pk_ddz"]  = "pre_game3",
            ['pk_zgz']  = 'pre_game3',
            ['mj_hebei']= 'pre_game_hebei',
            ['mj_hbtdh']= 'pre_game_hebei',
            ['mj_dbz']  = 'pre_game_hebei',
            ['mj_fn']   = 'pre_game_hebei',
        }
        if qipaiType == 'pk_pdk' and rtn_msg.room_info.isJDPDK then
            qipaiType = 'pk_jdpdk'
        end
        log(qipaiType)
        log(preGameMap[qipaiType])
        if not preGameMap[qipaiType] then
            log(qipaiType)
        else
            cc.UserDefault:getInstance():setStringForKey(preGameMap[qipaiType], qipaiType)
            cc.UserDefault:getInstance():flush()
        end
        if self:needReady(rtn_msg.room_info) then
            local input_msg = {
                cmd =NetCmd.C2S_READY,
                index = rtn_msg.room_info.index,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end

    if rtn_msg.cmd == NetCmd.S2C_MJ_TDH_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_KD_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_XIAN_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_LISI_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_GSJ_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_JZ_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_PDK_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_DDZ_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_JZGSJ_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_HEBEI_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_HBTDH_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_BDDBZ_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_MJ_FN_CREATE_ROOM
        or rtn_msg.cmd == NetCmd.S2C_ZGZ_CREATE_ROOM
        then
        cc.UserDefault:getInstance():setStringForKey("room_id", tostring(rtn_msg.room_id))
        cc.UserDefault:getInstance():flush()
    end

    local starttime = os.clock()

    local sceneMap = {
        ["mj_tdh"]        = "scene.TDHMJScene",
        ["mj_kd"]         = "scene.KDMJScene",
        ["mj_xian"]       = "scene.XAMJScene",
        ["mj_lisi"]       = "scene.LSMJScene",
        ['mj_gsj']        = 'scene.GSJMJScene',
        ['mj_jz']         = 'scene.JZMJScene',
        ['mj_jzgsj']      = 'scene.JZGSJMJScene',
        ["pk_pdk"]        = "scene.PDKScene",
		["pk_jdpdk"]	  = "scene.JDPDKScene",
        ["pk_ddz"]        = "scene.DDZScene",
        ['mj_hebei']      = 'scene.HBMJScene',
        ['mj_jzgsj_lisi'] = 'scene.JZGSJLSMJScene',
        ['mj_hbtdh']      = 'scene.HBTDHMJScene',
        ["pk_zgz"]        = "scene.ZGZScene",
        ['mj_dbz']        = 'scene.BDDBZMJScene',
        ['mj_dbz_kp']     = 'scene.BDDBZKPMJScene',
        ['mj_fn']         = 'scene.FNMJScene',
    }
    if qipaiType == 'mj_jzgsj' and rtn_msg.room_info.isLiSi then
        qipaiType = 'mj_jzgsj_lisi'
    elseif qipaiType == 'mj_dbz' and rtn_msg.room_info.isKouPai then
        qipaiType = 'mj_dbz_kp'
    elseif qipaiType == 'pk_pdk' and rtn_msg.room_info.isJDPDK then
        qipaiType = 'pk_jdpdk'
    end
    RoomController:getModel():setRoomInfo(rtn_msg)

    if qipaiType == "pk_ddz" then
        local gameScene = cc.Scene:create()
        gameScene:addChild(require(sceneMap[qipaiType]):create(rtn_msg))
        cc.Director:getInstance():replaceScene(gameScene)
    else
        local gameScene = require(sceneMap[qipaiType])
        cc.Director:getInstance():replaceScene(gameScene.create(rtn_msg))
    end

    local endtime = os.clock()
    print(string.format("@@@@@@@@@  game scene cost time  : %.4f", endtime - starttime))
end

-- @depreated
function MainScene:onRcvQunZhu(rtn_msg)
    -- self:showQunzhuRoom(rtn_msg)
    local createLayer = self:getChildByName("CreateLayer")
    if createLayer then
        createLayer:removeFromParent(true)
    end
    commonlib.showLoading(true)
    if self.loading_node then
        self.loading_node:unregisterEventListener()
        self.loading_node:removeFromParent(true)
        self.loading_node = nil
    end
    local input_msg = {
        cmd=NetCmd.C2S_INFO_MAX,
        isGetClubInfo = true,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function MainScene:needReady(room_info)
    local qipaiType = room_info.qipai_type
    log(qipaiType)
    if qipaiType == 'mj_xian' or qipaiType == 'pk_pdk' or qipaiType == 'pk_ddz' then
        return false
    end
    if qipaiType == 'mj_tdh' and room_info.isPiaoFen and room_info.isPiaoFen > 100 then
        return false
    end
    return true
end

function MainScene:onRcvJiesan(rtn_msg)
    local clubLayer = self:getChildByName("ClubLayer")
    if clubLayer then
        clubLayer.is_back_fromroom = "false"
    end
    local jiarufangjian = self:getChildByName("jiarufangjian")
    if jiarufangjian then
        jiarufangjian:removeFromParent(true)
    end


    --gt.playInteractiveSpine(self,"jiarufangjian")

    self.is_back_fromroom = "false"
    cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", self.is_back_fromroom)
    cc.UserDefault:getInstance():flush()

    self:isPlayMainAction(self.isMainAction, true)
end

--通过回放获取造牌牌堆
function MainScene:getMjMakeCards(rtn_msg)
    local pai_list = {}
    for i,player in ipairs(rtn_msg.logdata.players) do
        for j,v in ipairs(player.cards) do
            if j < 14 then
                pai_list[#pai_list+1] = (math.floor(v/16)*10 + v%16)
            end
        end
    end
    local last = rtn_msg.logdata.players[1].cards[14]
    pai_list[#pai_list+1] = (math.floor(last/16)*10 + last%16)
    for i,v in ipairs(rtn_msg.logdata.order) do
        if v.cddm == 361 then
            pai_list[#pai_list+1] = (math.floor(v.card/16)*10 + v.card%16)
        end
    end
    local str = ""
    for i,v in ipairs(pai_list) do
        str = str .. v .. ","
    end
    print(str)
end

function MainScene:onRcvLogData(rtn_msg)
    if not rtn_msg.ret then
        commonlib.showLocalTip('回放不存在或已过期')
        return
    end
    -- self:getMakeCards(rtn_msg)
    local time = rtn_msg.logdata.create_time
    local logdata_content =string.gsub(rtn_msg.logdata.content,"cmd","cddm")
    rtn_msg.logdata = json.decode(logdata_content)
    rtn_msg.create_time = time
    -- dump(rtn_msg)
    -- dump(rtn_msg.logdata.order)
    local qipaiType = rtn_msg.logdata.room_info.qipai_type or rtn_msg.logdata.qipai_type
    if rtn_msg.ret and rtn_msg.logdata then
        if g_author_game == "csmj" and qipaiType ~= "CSMJ" then
            commonlib.showLocalTip("回放不存在或已过期")
        elseif g_author_game == "ddz" and (qipaiType ~= "DDZ" and qipaiType ~= "DDZ4") then
            commonlib.showLocalTip("回放不存在或已过期")
        elseif g_author_game == "pdk" and qipaiType ~= "pdk" then
            commonlib.showLocalTip("回放不存在或已过期")
        elseif  qipaiType == "mj_tdh"   or
                qipaiType == "mj_xian"  or
                qipaiType == "mj_kd"    or
                qipaiType == "mj_lisi"  or
                qipaiType == "mj_gsj"   or
                qipaiType == "mj_jz"    or
                qipaiType == 'mj_jzgsj' or
                qipaiType == 'mj_hebei' or
                qipaiType == 'mj_hbtdh' or
                qipaiType == 'XIAN'     or
                qipaiType == 'LISI'     or
                qipaiType == 'mg_hebei' or
                qipaiType == 'mj_dbz'   or
                qipaiType == 'mj_fn'
            then
            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order, log_data_id = rtn_msg.log_data_id ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)

            local qipaiToScene = {}
            qipaiToScene['mj_tdh']          = 'scene.TDHMJScene'
            qipaiToScene['mj_xian']         = 'scene.XAMJScene'
            qipaiToScene['mj_kd']           = 'scene.KDMJScene'
            qipaiToScene['mj_lisi']         = 'scene.LSMJScene'
            qipaiToScene['mj_gsj']          = 'scene.GSJMJScene'
            qipaiToScene['mj_jz']           = 'scene.JZMJScene'
            qipaiToScene['mj_jzgsj']        = 'scene.JZGSJMJScene'
            qipaiToScene['mj_hebei']        = 'scene.HBMJScene'
            qipaiToScene['mg_hebei']        = 'scene.HBMJScene'
            qipaiToScene['XIAN']            = 'scene.XAMJScene'
            qipaiToScene['LISI']            = 'scene.LSMJScene'
            qipaiToScene['mj_hbtdh']        = 'scene.HBTDHMJScene'
            qipaiToScene['mj_jzgsj_lisi']   = 'scene.JZGSJLSMJScene'
            qipaiToScene['mj_dbz']          = 'scene.BDDBZMJScene'
            qipaiToScene['mj_dbz_kp']       = 'scene.BDDBZKPMJScene'
            qipaiToScene['mj_fn']           = 'scene.FNMJScene'
            print('回放')
            local qipai_type = rtn_msg.logdata.room_info.qipai_type
            if qipai_type =='mj_jzgsj' and rtn_msg.logdata.room_info.isLiSi then
                qipai_type = 'mj_jzgsj_lisi'
            end
            if qipai_type == 'mj_dbz' and rtn_msg.logdata.room_info.isKouPai then
                qipai_type = 'mj_dbz_kp'
            end
            -- 有收到空数据的情况
            if not qipai_type or not qipaiToScene[qipai_type] then
                commonlib.showLocalTip('回放不存在或已过期')
                return
            end
            local MJScene = require(qipaiToScene[qipai_type])
            local sc = MJScene.create(msg)
            sc.is_in_main = true
            cc.Director:getInstance():replaceScene(sc)
        elseif qipaiType == "PDK" or qipaiType == "pk_pdk" or qipaiType == "pk_jdpdk" then

            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order, log_data_id = rtn_msg.log_data_id ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)
            local PDKScene = require("scene.PDKScene")
            if qipaiType == "pk_jdpdk" then
                PDKScene = require("scene.JDPDKScene")
            end
            local sc = PDKScene.create(msg)
            sc.is_in_main = true
            cc.Director:getInstance():replaceScene(sc)
        elseif qipaiType == "DDZ" or qipaiType == "pk_ddz" then

            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order, log_data_id = rtn_msg.log_data_id ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)
            local gameScene = cc.Scene:create()
            local ddzScene = require("scene.DDZScene"):create(msg)
            ddzScene.is_in_main = true
            gameScene:addChild(ddzScene)
            cc.Director:getInstance():replaceScene(gameScene)
        elseif qipaiType == "ZGZ" or qipaiType == "pk_zgz" then

            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order, log_data_id = rtn_msg.log_data_id ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)
            local ZGZScene = require("scene.ZGZScene")
            local sc = ZGZScene.create(msg)
            sc.is_in_main = true
            cc.Director:getInstance():replaceScene(sc)
        elseif rtn_msg.logdata.qipai_type == "DDZ4" then
            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)
            local DDZScene = require("scene.DDZSceneFour")
            local sc = DDZScene.create(msg)
            sc.is_in_main = true
            cc.Director:getInstance():replaceScene(sc)
        elseif rtn_msg.logdata.qipai_type == "PHZ" then

            -- self.ui:removeFromParent()
            self:unregisterEventListener()

            local self_index = yy_record_index or 1
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.uid == ProfileManager.GetProfile().uid then
                    self_index = v.index
                    break
                end
            end

            local msg = rtn_msg.logdata.room_info
            for __, v in ipairs(rtn_msg.logdata.players) do
                if v.index == self_index then
                    msg.index = v.index
                    msg.player_info = v
                else
                    msg.other = msg.other or {}
                    msg.other[#msg.other+1] = v
                end
            end
            msg.status = 101
            msg = {is_playback=true, room_id=msg.room_id, room_info=msg, order=rtn_msg.logdata.order ,create_time= rtn_msg.create_time}
            commonlib.echo(msg)
            local PHZScene= nil
            if  msg.room_info.address_id and msg.room_info.address_id==14 then
                PHZScene = require("scene.PHZXTScene")
                print("scene.PHZXTScene")
            else
                PHZScene =require("scene.PHZScene")
                print("scene.PHZScene")
            end
            local sc = PHZScene.create(msg)
            sc.is_in_main = true
            cc.Director:getInstance():replaceScene(sc)
        end
    else
        commonlib.showLocalTip("回放不存在或已过期")
    end
end

function MainScene:convertInfoMax(rtn_msg)
    -- 没有房间信息
    local roomParams = rtn_msg and rtn_msg.club_rooms and rtn_msg.club_rooms.roomParams
    if not roomParams then
        return rtn_msg
    end

    local new_rtn_msg = {
        room_id = 0,
        club_index = 0,
        room_name= 0,
        room_type =0,
        need_people_num=0,
        cur_ju=0,
        status=0,
        people_num=0,
        players=0,
    }

    local server_club_rooms = rtn_msg.club_rooms
    -- print('原始消息')
    -- dump(rtn_msg.club_rooms.roomParams)
    -- print('原始消息222')
    local server_roomParams = clone(rtn_msg.club_rooms.roomParams)
    for i , v in pairs(server_club_rooms) do
        if i ~= 'roomParams' then
            local club_room = clone(new_rtn_msg)
            local server_club_room = server_club_rooms[i]
            club_room.room_id = server_club_room[1]
            club_room.club_index = server_club_room[2]
            club_room.room_name = server_club_room[3]
            club_room.room_type = server_club_room[4]
            club_room.need_people_num = server_club_room[5]
            club_room.cur_ju = server_club_room[6]
            club_room.status = server_club_room[7]
            club_room.people_num = server_club_room[8]
            club_room.players = server_club_room[9]

            server_club_rooms[i] = club_room
        else
            server_club_rooms.roomParams = nil
        end
    end

    local roomParams = {}
    for i , v in pairs(server_roomParams) do
        roomParams[v.room_id] = v
    end

    -- dump(server_club_rooms)

    local closure = function(params)
        -- print('111111111111111111111')
        local eventStr = ''
        local msg = ''
        local pFunc = function()
            eventStr = params
            msg = json.decode(params)
        end
        local ok , errMsg = xpcall(pFunc, function(errorMessage)
            local str = tostring(errorMessage) .. debug.traceback("", 2)
            local errStr = string.format("json.decode(eventStr) fail event = %s errMsg = %s eventStr = %s",tostring(610),tostring(str),tostring(eventStr))
            print(errStr)
            gt.uploadErr(errStr)
        end,params)
        if ok then
            if msg then
            else
                local errStr = string.format("json.decode(eventStr) nil event = %s eventStr = %s",tostring(610),tostring(eventStr))
                gt.uploadErr(errStr)
            end
        end
        return msg
    end

    -- log('AAAAAAAAAAAAAAAAAAAAAAAAA')
    for i , v in pairs(server_club_rooms) do
        local room = roomParams[v.room_id] or roomParams[0]
        server_club_rooms[i].params = closure(room.params)
    end
    -- log('BBBBBBBBBBBBBBBBBBBBBBBBBBBBB')

    local client_club_rooms = {}

    for i ,v in pairs(server_club_rooms) do
        client_club_rooms[v.club_index] = v
    end
    rtn_msg.club_rooms = client_club_rooms

    for i, v in ipairs(rtn_msg.club_rooms) do
        if v.params.qipai_type == "pk_pdk" and v.params.isJDPDK then
            v.params.qipai_type = "pk_jdpdk"
            v.room_name = "经典"..v.room_name
        end
    end
    return rtn_msg
end

function MainScene:onRcvInfoMax(rtn_msg,client_self_refresh)
    if client_self_refresh then
        return
    end
    -- 网络较好
    self.is_network_bad = false

    local endtime = os.clock()
    if self.starttime then
        print(string.format("网络 cost time  : %.4f", endtime - self.starttime))
        self.starttime = nil
    end

    -- print('VNBNVCMCMF')
    -- log('````````````````````````',rtn_msg)
    -- log('````````````````````````')
    -- log('````````````````````````')
    -- log('````````````````````````')
    -- log('````````````````````````')
    -- print(client_self_refresh and '客户端自己先刷新' or '客户端同步服务器')
    if not client_self_refresh then
        rtn_msg = self:convertInfoMax(rtn_msg)
        local ClubData = require ('club.ClubData')
        ClubData.onRcvInfoMax(rtn_msg)
        ClubController:getModel():setClubData(rtn_msg)
        ClubController:reqSendClubUid()
    end

    -- dump(rtn_msg)

    if self.loading_node then
        self.loading_node:stopRepeat()
    end
    local function refreshClub(bForce)
        if not self then
            return
        end
        local clubLayer = self:getChildByName("ClubLayer")
        if clubLayer then
            clubLayer:initClub(rtn_msg)
            clubLayer:refreshLayer(GameGlobal.is_los_club or bForce)
            clubLayer:refreshRodHot(rtn_msg.hasPlayerApplyJoin and rtn_msg.hasPlayerApplyJoin == 1)
        else
            local ClubLayer = require("club.ClubLayer")
            clubLayer = ClubLayer:create({mainScene = self,rtn_msg = rtn_msg})
            self:addChild(clubLayer, ZOrder.DIALOG)
        end
        -- 修改默认玩法
        if self.operType and self.operType == 2 then
            clubLayer:showResetWaysTips()
            self.isChangeRoom = nil
            self.operType = nil
            return
        end
        -- 解散
        if self.operType and self.operType == 1 then
            clubLayer:showJieSan()
            self.isChangeRoom = nil
            self.operType = nil
            return
        end

        -- 过渡动画
        -- commonlib.showLoading(true)
        -- commonlib.showSeZiLoading(true)
    end
    if rtn_msg.isGetClubInfo then
        if rtn_msg.club_info then
            refreshClub(true)
        else
            if rtn_msg.isClickGetClubInfo then
                local ClubCreateJoin = require("club.ClubCreateJoin")
                self.clubCreateJoin = ClubCreateJoin:create({mainScene = self})
                self:addChild(self.clubCreateJoin, ZOrder.DIALOG)
            end
            local ClubLayer = self:getChildByName('ClubLayer')
            if ClubLayer then
                ClubLayer:exitLayer()
            end
        end
    else
        if rtn_msg.club_info then
            refreshClub()
        end
    end
    GameGlobal.is_los_club = nil
end

function MainScene:onRcvSyncClubNotify(rtn_msg)
    if not rtn_msg.errno or rtn_msg.errno == 0 then
        if rtn_msg.club_info then
            if rtn_msg.tag == 1 then
                commonlib.showLocalTip(string.format("%s同意了你的亲友圈申请", rtn_msg.club_info.club_name))
            elseif rtn_msg.tag == 2 then
                commonlib.showLocalTip(string.format("%s拒绝了你的申请,加入亲友圈失败", rtn_msg.club_info.club_name))
            elseif rtn_msg.tag == 3 then
                commonlib.showLocalTip(string.format("您被 '%s' 管理员踢出了亲友圈!", rtn_msg.club_info.club_name))
            elseif rtn_msg.tag == 4 then -- 有玩家申请
                local clubLayer = self:getChildByName("ClubLayer")
                if clubLayer then
                    clubLayer:onRcvSyncClubNotify(rtn_msg)
                    clubLayer:refreshRodHot(true)
                    -- local ClubMemberLayer = clubLayer:getChildByName('ClubMemberLayer')
                    -- if ClubMemberLayer then
                    --     ClubMemberLayer:onSq(true)
                    -- end
                end
            end
        elseif rtn_msg.tag == 5 then
            local clubAgentBind = self:getChildByName('ClubAgentBind')
            if clubAgentBind then
                clubAgentBind:setData(rtn_msg.agentid, rtn_msg.card, rtn_msg.freeDay)
                return
            end
            local clubAgentBindDialog = require("club.ClubAgentBindDialog"):create(rtn_msg.agentid, rtn_msg.card, rtn_msg.freeDay)
            self:addChild(clubAgentBindDialog, ZOrder.DIALOG)
        elseif rtn_msg.tag == 6 then
            local createLayer = self:getChildByName("CreateLayer")
            if createLayer then
                createLayer:removeFromParent(true)
            end
            commonlib.showLoading(true)
            if self.loading_node then
                self.loading_node:unregisterEventListener()
                self.loading_node:removeFromParent(true)
                self.loading_node = nil
            end
            local input_msg = {
                cmd           = NetCmd.C2S_INFO_MAX,
                isGetClubInfo = true,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    else
        commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or "")
    end
end

function MainScene:onRcvClubApplyJoin(rtn_msg)
    local str = nil
    if rtn_msg.errno == 0 then
        str = string.format("申请加入亲友圈%s成功，请耐心等待\n群主审核通过。", tostring(rtn_msg.club_id))
    else
        str = rtn_msg.msg
    end
    if str then
        local ClubTipLayer = require("club.ClubTipLayer")
        local args = {
            msg = str,
        }
        self:addChild(ClubTipLayer:create(args), ZOrder.DIALOG)
    end
end

function MainScene:onRcvClubInvitePlay(rtn_msg)
    if 'true' == self.is_back_fromroom then
        return
    end

    local layer = self:getChildByName('ClubInviteDialog')
    if layer then
        layer:exitLayer()
    end

    local ClubInviteDialog = require('club.ClubInviteDialog')
    local layer = ClubInviteDialog:create({room_id = rtn_msg.room_id,
            name = rtn_msg.name,
            club_name = rtn_msg.club_name,
            room_info = rtn_msg.room_info,
        })
    self:addChild(layer, ZOrder.DIALOG)
end

function MainScene:onGameConf(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local func = loadstring("return "..rtn_msg)
    local ret, gameconf = pcall(func)
    if ret and gameconf then
        gt.game_conf = gameconf
        gt.saveLocalGameConf(rtn_msg)
        dump(gameconf,"gameconf MainScene")
    end
end

function MainScene:onVersionNumber(rtn_msg)
    local local_ver = cc.UserDefault:getInstance():getStringForKey("UpdateVersion","")
    local remote_ver = rtn_msg
    if local_ver ~= "" and remote_ver > local_ver then
        local curtime = os.time()
        local cur2time = gt.getCurDayHourTime(2)
        local cur8time = gt.getCurDayHourTime(8)
        if curtime >= cur2time and curtime <= cur8time then
            commonlib.showTipDlg("游戏有新的更新，重新打开游戏体验最新版本！", function(is_ok)
                if is_ok then
                    cc.Director:getInstance():endToLua()
                end
            end,nil,nil,nil,true)
        else
            commonlib.showTipDlg("游戏有新的更新，重新打开游戏体验最新版本！", function(is_ok)
                if is_ok then
                    cc.Director:getInstance():endToLua()
                else
                    gt.uploadErr('this bother refuses update')
                end
            end)
        end
    end
    return
end

function MainScene:showErrTip(rtn_msg)
    commonlib.showLocalTip(rtn_msg.msg or ErrStrToClient[rtn_msg.errno] or rtn_msg.errno)
    if rtn_msg.errno == 1010 or rtn_msg.errno == 1009 then
        self.number = 0
        self.inputNum = 0
        if self.number_lbl then
            self.number_lbl:setString("请输入房间号")
        end
    end
    -- if errno == 1008 then
    --     commonlib.showLocalTip("房卡不足")
    -- elseif errno == 1009 then
    --     commonlib.showLocalTip("房间满了")
    --     self.number = 0
    --     self.inputNum = 0
    --     if self.number_lbl then
    --         self.number_lbl:setString("请输入房间号")
    --     end
    -- elseif errno == 1010 then
    --     commonlib.showLocalTip("房间不存在")
    --     self.number = 0
    --     self.inputNum = 0
    --     if self.number_lbl then
    --         self.number_lbl:setString("请输入房间号")
    --     end
    -- elseif errno == 1011 then
    --     commonlib.showLocalTip("房间已开始游戏")
    -- elseif errno == 1016 then
    --     commonlib.showLocalTip("亲友圈房间数量超限")
    -- elseif errno == 1020 then
    --     -- commonlib.showLocalTip("亲友圈房间，未经验证无法加入")
    --     commonlib.showLocalTip("亲友圈申请消息已发送，请等待管理员同意")
    -- elseif errno == 1049 then
    --     commonlib.showLocalTip("房间已达上限")
    -- end
    commonlib.showLoading(true)
    if self.loading_node then
        self.loading_node:unregisterEventListener()
        self.loading_node:removeFromParent(true)
        self.loading_node = nil
    end
end

function MainScene:showHDDlg(rtn_msg)
    if g_os ~= "win" and not ios_checking then
        local MoreMsgDialog = require("scene.kit.MoreMsgDialog")
        local moreMsg = MoreMsgDialog.create(self,rtn_msg)
        moreMsg.is_in_main = true
        self:addChild(moreMsg, ZOrder.DIALOG)
    end
end

function MainScene:enterMain(is_login)
    local clientIp = gt.getClientIp()
    if is_login then
        local isSendedJoin = false
        local function sendJoinRoom(room_id)
            local net_msg = {
                cmd =NetCmd.C2S_JOIN_ROOM,
                room_id=room_id,
                lat = clientIp[1],
                lon = clientIp[2],
            }
            ymkj.SendData:send(json.encode(net_msg))
            isSendedJoin = true
        end
        local str = ymkj.baseInfo(1001)
        if str and str ~= "" and str ~= "0"  and str ~= "win" and str ~= "ios" and str ~= "android" then
            local room_id = tonumber(str)
            if room_id then
                sendJoinRoom(room_id)
            end
        end
        if isSendedJoin == false then
            local NativeUtil = require("common.NativeUtil")
            local clipStr = NativeUtil:getPasteboard()
            print("clipStr",clipStr)
            local _,e = string.find(clipStr,":")
            if e and string.len(clipStr)>e+6 then
                local roomId = string.sub(clipStr,e+1,e+6)
                local room_id = tonumber(roomId)
                if room_id then
                    sendJoinRoom(room_id)
                    ymkj.copyClipboard("")
                    isSendedJoin = true
                end
            end
        end
    end

    self:scrollSysMsg()
end

function MainScene:scrollSysMsg(idx)
    local index = #self.msg_content_list
    local str = self.msg_content_list[index]
    if str and not ios_checking then
        self.msg_lbl:setString(str)
        table.remove(self.msg_content_list, index)
    else
        index = #kefuTextConfig.broadcast
        if idx then
            if idx < 1 then
                index = index
            elseif idx > index then
                index = 1
            else
                index = idx
            end
        else
            index = 1
        end
        str = kefuTextConfig.broadcast[index]
        self.msg_lbl:setString(str)
        index = index+1
    end

    self.msg_lbl:setPositionX(self.msg_lbl.init_posx)
    self.msg_lbl:stopAllActions()

    local msgWidth = self.msg_lbl.init_posx+self.msg_lbl:getContentSize().width
    self.msg_lbl:runAction(cc.Sequence:create(cc.MoveBy:create(msgWidth/75, cc.p(-msgWidth, 0)),
        cc.CallFunc:create(function() self:scrollSysMsg(index) end)))
end

function MainScene:initHuobiInfo(is_cards_change)
    local profile = ProfileManager.GetProfile()
    if not profile then return end
    ccui.Helper:seekWidgetByName(self.Panel_fangka,"lab_yanbaoshu"):setString(profile.card or 0)
    --local labJifenshu = ccui.Helper:seekWidgetByName(self.topPanel,"lab-jifenshu")
    --labJifenshu:setString(profile.score or 0)
    if is_cards_change then return end
    if pcall(commonlib.GetMaxLenString, profile.name, 14) then
        ccui.Helper:seekWidgetByName(self.Panel_touxiang,"Text_name"):setString(commonlib.GetMaxLenString(profile.name, 14))
    else
        ccui.Helper:seekWidgetByName(self.Panel_touxiang,"Text_name"):setString(profile.name)
    end
    ccui.Helper:seekWidgetByName(self.Panel_touxiang,"Text_id"):setString(profile.uid)
    if self.img_head then
        self.img_head:downloadImg(commonlib.wxHead(profile.head), g_wxhead_addr)
    end
end


function MainScene:deepcompare(t1,t2,ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
      -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
      -- as well as tables which have the metamethod __eq
    for k1,v1 in pairs(t1) do
        if k1 ~= ignore_mt then
            local v2 = t2[k1]
            if v2 == nil or not self:deepcompare(v1,v2) then return false end
        end
    end
    for k2,v2 in pairs(t2) do
        if k2 ~= ignore_mt then
            local v1 = t1[k2]
            if v1 == nil or not self:deepcompare(v1,v2) then return false end
        end
    end
    return true
end


function MainScene:createLayerMenu()
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, ZOrder.GRID)
    end

    self.ui = cc.Layer:create()
    self:addChild(self.ui)

    -- local gridLayer = require("scene.GridLayer").new()
    -- self:addChild(gridLayer, 10000)

    local csb = DTUI.getInstance().csb_file
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self.ui:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node

    if gt.getLocalBool("isOpenAgainDialog") then
        self:refreshSetDialog()
    end
    -- 主界面加载成功时把 isOpenAgainDialog 的值设为默认false。防止未修改主界面风格时被打开
    gt.setLocalBool("isOpenAgainDialog", false, true)

    --------gt.bqcount为nil，代表10秒内第一次发互动表情，当为true时，代表10秒内第二次发送表情
    gt.bqcount = nil

    self.bg_node = ccui.Helper:seekWidgetByName(node,"Panel_Bg")

    self.topPanel = tolua.cast(ccui.Helper:seekWidgetByName(node,"Panel_1ji"), "ccui.Widget")
    self.Panel_touxiang = tolua.cast(ccui.Helper:seekWidgetByName(node,"Panel_touxiang"), "ccui.Widget")
    self.Panel_fangka = tolua.cast(ccui.Helper:seekWidgetByName(node,"Panel_yuanbaoshu"), "ccui.Widget")
    self.topPanel:setLocalZOrder(ZOrder.BG)
    self.Panel_touxiang:setLocalZOrder(ZOrder.BG)

    self.msg_panel = ccui.Helper:seekWidgetByName(node, "Panel_3")
    self.msg_lbl = tolua.cast(ccui.Helper:seekWidgetByName(self.msg_panel,"lab_msg"), "ccui.Text")
    self.msg_lbl.init_posx = self.msg_lbl:getPositionX()
    self.msg_content_list = {}
    if cc.UserDefault:getInstance():getStringForKey("is_back_fromroom") ~= "" then
        self.is_back_fromroom = cc.UserDefault:getInstance():getStringForKey("is_back_fromroom")
    end
    ccui.Helper:seekWidgetByName(node,"btn_add"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn shangcheng")
            if ios_checking then
                local ChargeLayer = require("scene.ChargeLayer")
                local layer = ChargeLayer.create()
                self:addChild(layer,ZOrder.DIALOG)
            else
                self:showShopdaili()
            end
        end
    end)

    -- 获取主界面图片
    self.img_qingyouquan = ccui.Helper:seekWidgetByName(node,"Image_qingyouquan")
    self.img_joinroom    = ccui.Helper:seekWidgetByName(node, "Image_jiaru")
    self.img_createroom  = ccui.Helper:seekWidgetByName(node, "Image_chuangjian")
    self.img_juese       = ccui.Helper:seekWidgetByName(node, "Image_juese")
    self.img_qingyouquan:setVisible(false)
    self.img_joinroom:setVisible(false)
    self.img_createroom:setVisible(false)
    self.img_juese:setVisible(false)

    -- 获取是否播放主界面动画
    require 'scene.GameSettingDefault'
    if g_close_main_ani then
        self.isMainAction = cc.UserDefault:getInstance():getBoolForKey("isMainAction",GameSettingDefault.PLAY_ANIMATION)
    else
        self.isMainAction = true
    end
    if self.isMainAction then
        self:isPlayMainAction(true)
    else
        self:isPlayMainAction(false)
    end


    local btn_share = ccui.Helper:seekWidgetByName(node,"btn_share")
    if ios_checking then
        btn_share:setVisible(false)
    end
    btn_share:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn tuijian")
            local ShareDialog = require("scene.kit.ShareDialog")
            local share = ShareDialog.create()
            share.is_in_main = true
            self:addChild(share, ZOrder.DIALOG)
        end
    end)

    if not self.notices then
        local noticeStr = cc.UserDefault:getInstance():getStringForKey("NOTICE")
        if #noticeStr > 0 then
            self.notices = json.decode(noticeStr)
        end
    end
    local btnKefu = ccui.Helper:seekWidgetByName(node,"btn_xiaoxi")
    btnKefu:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn kefu")
            local notices = self.notices
            if ios_checking then
                notices = {}
            end
            local MsgDialog = require("scene.kit.MsgDialog")
            local Msg = MsgDialog.create(self,self.notices)
            Msg.is_in_main = true
            self:addChild(Msg, ZOrder.DIALOG)
            self.red_dot:setVisible(false)
        end
    end)

    self.red_dot = cc.Sprite:create("ui/qj_main/red_dot.png")
    self.red_dot:setPosition(cc.p(55, 80))
    btnKefu:addChild(self.red_dot)
    self.red_dot:setVisible(false)

    local btnSM = ccui.Helper:seekWidgetByName(node,"btn_shiming")
    if cc.UserDefault:getInstance():getStringForKey("isshiming") == 'true' then
        btnSM:setVisible(false)
    end

    btnSM:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn shiming")

            local csb = DTUI.getInstance().csb_DT_RelNameLayer
            local smnode = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
            self:addChild(smnode, ZOrder.DIALOG)

            smnode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
            ccui.Helper:doLayout(smnode)

            local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(smnode,"btExit"), "ccui.Widget")
            backBtn:addTouchEventListener(
                function(sender,eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        --commonlib.fadeOut(ccui.Helper:seekWidgetByName(smnode, "Panel_1"))
                        --commonlib.scaleOut(ccui.Helper:seekWidgetByName(smnode, "Panel_2"), function( )
                            smnode:removeFromParent(true)
                        --end)
                    end
                end
            )

            commonlib.fadeIn(ccui.Helper:seekWidgetByName(smnode, "Panel_1"))
            commonlib.scaleIn(ccui.Helper:seekWidgetByName(smnode, "Panel_2"))


            local login_un_input =   tolua.cast(ccui.Helper:seekWidgetByName(smnode, "eName"), "ccui.TextField")
            local login_pw_input =   tolua.cast(ccui.Helper:seekWidgetByName(smnode, "eIDcard"), "ccui.TextField")

            login_un_input:setPlaceHolderColor(cc.c4b(200,200,200,255))
            login_pw_input:setPlaceHolderColor(cc.c4b(200,200,200,255))

            ccui.Helper:seekWidgetByName(smnode,"btEnter"):addTouchEventListener(
                function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
                        local name = login_un_input:getString()
                        if(string.len(name) <= 0 ) then
                            commonlib.showLocalTip("姓名不能为空")
                            return
                        end

                        if(not string.find(name,"[^%d|%a]")) then
                            commonlib.showLocalTip("姓名不能包含字母或数字")
                            return
                        end


                        local pwd = login_pw_input:getString()
                        if(string.len(pwd) ~= 18) then
                            commonlib.showLocalTip("身份证号码必须18位组成")
                            return
                        end

                        if string.find(pwd,"[^%d|%a]") then
                            commonlib.showLocalTip("身份证号码只能是字母或数字组成")
                            return
                        end

                        smnode:removeFromParent(true)

                        commonlib.showLocalTip("认证成功")
                        self.is_shiming = 'true'
                        cc.UserDefault:getInstance():setStringForKey("isshiming", self.is_shiming)
                        cc.UserDefault:getInstance():flush()
                        btnSM:setVisible(false)
                    end
                end
            )

        end
    end)

    local btnHB = ccui.Helper:seekWidgetByName(node,"btn_hongbao")
    btnHB:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print("click btn hongbao")
            local RedBagLayer = require("modules.view.RedBagLayer")
            local layer = RedBagLayer:create()
            self:addChild(layer, ZOrder.DIALOG)
        end
    end)

    ccui.Helper:seekWidgetByName(node,"btn_wanfa"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn bangzhu")
            local HelpLayer = require("scene.kit.HelpDialog")
            local help = HelpLayer.create()
            help.is_in_main = true
            self:addChild(help, ZOrder.DIALOG)
        end
    end)

    ccui.Helper:seekWidgetByName(node,"btn_zhanji"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click btn zhanji")
            if self.is_back_fromroom == "true" then
                commonlib.showReturnTips("不可查看战绩，")
            else
                local ZjLayer = require("scene.ZjLayer")
                self:addChild(ZjLayer:create(), ZOrder.DIALOG)
            end
        end
    end)

    local btn_fankui = ccui.Helper:seekWidgetByName(node,"btn_fankui")
    btn_fankui:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local FankuiDialog = require("scene.kit.FankuiDialog")
            local fankui = FankuiDialog.create()
            fankui.is_in_main = true
            self:addChild(fankui, ZOrder.DIALOG)
        end
    end)

    local btn_shezhi = ccui.Helper:seekWidgetByName(node,"btn_shezhi")
    btn_shezhi:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            if self.is_back_fromroom == "true" then
                local SetLayer = require("scene.RoomSetingLayer")
                self:addChild(SetLayer.create(false,true), ZOrder.DIALOG)
            else
                local SetLayer = require("scene.kit.SetDialog")
                local set = SetLayer.create()
                set.is_in_main = true
                self:addChild(set, ZOrder.DIALOG)
            end
        end
    end)
    btn_shezhi:setVisible(not ios_checking)

    ccui.Helper:seekWidgetByName(node,"btn_tx"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            if ios_checking then
                return
            end
            AudioManager:playPressSound()
            --self:showPlayerXinxi()
            local UserinfoLayer = require("scene.kit.UserinfoDialog")
            local userinfo = UserinfoLayer.create()
            userinfo.is_in_main = true
            self:addChild(userinfo, ZOrder.DIALOG)
        end
    end)

    self.curRoomType = 1

    local function getClubInfo()
        local input_msg = {
            cmd=NetCmd.C2S_INFO_MAX,
            isGetClubInfo = true,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
    local btn_qingyouquan = ccui.Helper:seekWidgetByName(node,"btn_qingyouquan")
    local btn_joinroom = ccui.Helper:seekWidgetByName(node, "btn-jiaru")
    local btn_createroom = ccui.Helper:seekWidgetByName(node, "btn-chuangjian")
    btn_qingyouquan:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local clubLayer = self:getChildByName("ClubLayer")
            if clubLayer and clubLayer.storgeStyle == ClubHallUI.getClubStyle() then
                clubLayer:refreshLayer(true)
                clubLayer:setVisible(true)
                return
            elseif clubLayer then
                clubLayer:exitLayer()
            end

            local input_msg = {
                cmd=NetCmd.C2S_INFO_MAX,
                isGetClubInfo = true,
                isClickGetClubInfo = true,
                club_id = 882007,
            }
            -- 网络是否较差  true：网络差，3秒内无法接收到亲友圈点击的消息
            self.is_network_bad = true
            ymkj.SendData:send(json.encode(input_msg))

            -- 若能在3秒内能收到亲友圈点击的消息，则把 self.is_network_bad 设置为false
            btn_qingyouquan:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function ()
                if self.is_network_bad then
                    commonlib.showLocalTip("当前网络状况较差")
                end
            end)))
            self.starttime = os.clock()

            btn_qingyouquan:setTouchEnabled(false)
            btn_qingyouquan:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
                btn_qingyouquan:setTouchEnabled(true)
            end)))
        end
    end)


    if GameGlobal.is_los_club then
        local ClubLayer = require("club.ClubLayer")
        local clubLayer = ClubLayer:create({mainScene = self})
        self:addChild(clubLayer, ZOrder.DIALOG)
    end

    self:registerEventListener()
    self:keypadEvent()
    self.img_head = ccui.Helper:seekWidgetByName(node,"Img-TX")
    self:initHuobiInfo()
    btn_joinroom:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print("click join room")
            if self.is_back_fromroom == "true" then
                local id = cc.UserDefault:getInstance():getStringForKey("room_id")
                local input_msg = {
                cmd=NetCmd.C2S_JOIN_ROOM_AGAIN,
                room_id = tonumber(id),
            }
            ymkj.SendData:send(json.encode(input_msg))

                self.is_back_fromroom ="false"
                cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", self.is_back_fromroom)
                cc.UserDefault:getInstance():flush()
            else
                self:joinRoomUI()
            end
        end
    end)


    btn_createroom:addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
            print("click create room")
            if self.is_back_fromroom == "true" then
                commonlib.showReturnTips("不可再次创建房间，")
            else
                local type_pre = cc.UserDefault:getInstance():getStringForKey("pre_game_typ",'1')
                type_pre = tonumber(type_pre)
                local CreateLayer = require("scene.CreateLayer")
                self:addChild(CreateLayer:create({
                    typ =type_pre,
                    qunzhu = 2,
                    mainScene = self,
                }), ZOrder.DIALOG)
            end
        end
    end)

    if ios_checking then
        local Panel_qingyouquan = ccui.Helper:seekWidgetByName(node,"Panel_qingyouquan")
        Panel_qingyouquan:setVisible(false)
        btn_createroom:setPositionX(btn_createroom:getPositionX()-245)
        btn_joinroom:setPositionX(btn_joinroom:getPositionX()-155)
        local btn_shezhi = ccui.Helper:seekWidgetByName(node,"btn_shezhi")
        local btn_fankui = ccui.Helper:seekWidgetByName(node,"btn_fankui")
        btn_fankui:setVisible(false)
        btn_shezhi:setPosition(cc.p(btn_fankui:getPosition()))
        local btn_xiaoxi = ccui.Helper:seekWidgetByName(node,"btn_xiaoxi")
        local btn_share = ccui.Helper:seekWidgetByName(node,"btn_share")
        btn_xiaoxi:setVisible(false)
        btn_share:setPosition(cc.p(btn_xiaoxi:getPosition()))
    end
    gt.IpMgr:initIp("conf")
    if g_os ~= "win" then
        local version_url = gt.getConf("version_url")
        if g_is_new_update then
            local cfg = require("launcher.cfg")
            version_url = cfg.verPath2
        else
            if test_package then
                if test_package == 1 then
                    version_url = gt.getConf("version_url_tyb")
                else
                    version_url = gt.getConf("version_url_test")
                end
            end
        end
        ymkj.UrlPool:instance():reqHttpGet("version_number",version_url)
    end
    self:enterMain()

    -- 播放红包引导动画
    -- local x = cc.UserDefault:getInstance():getStringForKey("action_RedBag")
    -- if cc.UserDefault:getInstance():getStringForKey("action_RedBag") == "" then
    --     local actionLayer = require("modules.view.RedBagActionLayer"):create()
    --     self:addChild(actionLayer,ZOrder.DIALOG+1)
    -- end

    self:reqRedBagAction()
end


--请求是否播放红包引导动画
function MainScene:reqRedBagAction()
    local isGuided = RedBagController:getModel():getIsGuided()
    if isGuided then
        return
    end
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_action",url,{
        cmd = 125,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
        type = 1,
    })
end

function MainScene:resRedBagAction(rtn_msg)
    dump("rtn_msg===",rtn_msg,10)
    --收到消息播放把是否能播放红包数据
    local data = nil
    local function readJson()
        data = json.decode(rtn_msg)
    end
    pcall(readJson)
    if not data then
        gt.uploadErr(rtn_msg)
        return
    end
    if data.code == -1 then
        RedBagController:getModel():setIsGuided(true)
    end
    RedBagController:setHBPlay(data)
    -- local actionLayer = require("modules.view.RedBagActionLayer"):create()
    -- if data.code == 0 then
    --     if data.read == 0 then  --新用户红包引导动画
    --         self:addChild(actionLayer,ZOrder.DIALOG+1)
    --     end
    -- end
end

function MainScene:openAgentBind()
    if clubAgentBindMsg then
        self:onRcvSyncClubNotify(clubAgentBindMsg)
        clubAgentBindMsg = nil
        return
    end
end

function MainScene:joinRoomUI()
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_JoinroomLayer.csb"),"ccui.Widget")
    self:addChild(node, ZOrder.DIALOG)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local clientIp = gt.getClientIp()
    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

   local number = 0
   local number_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "tRoomID"), "ccui.Text")
   local inputNum = 0
   self.number = number
   self.number_lbl=number_lbl
   self.inputNum = inputNum
    for i=0, 9 do
        ccui.Helper:seekWidgetByName(node, string.format("%d", i)):addTouchEventListener(
            function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                        self.number = self.number*10+i
                        self.number_lbl:setString(self.number)
                        self.inputNum = self.inputNum + 1
                    if self.inputNum >=6 then
                        self.number = self.number_lbl:getString()
                        local net_msg = {
                            cmd =NetCmd.C2S_JOIN_ROOM,
                            room_id=self.number,
                            lat = clientIp[1],
                            lon = clientIp[2],
                        }
                        ymkj.SendData:send(json.encode(net_msg))
                    end
                end
            end)
    end

    ccui.Helper:seekWidgetByName(node,"btReinput"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.number = 0
            self.inputNum = 0
            self.number_lbl:setString("请输入房间号")
        end
    end)

    ccui.Helper:seekWidgetByName(node,"btDel"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.number = math.floor(self.number/10)
            if self.inputNum >0 then
                self.inputNum = self.inputNum - 1
            end
            if self.number == 0 then
                self.number_lbl:setString("请输入房间号")
            else
                self.number_lbl:setString(self.number)
            end
        end
    end)
    ccui.Helper:seekWidgetByName(node,"btOk"):setVisible(false)
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
end

function MainScene:showQunzhuRoom(rtn_msg)
    local yqui = tolua.cast(cc.CSLoader:createNode("ui/qzkftanchuang.csb"), "ccui.Widget")
    self:addChild(yqui, ZOrder.DIALOG)
    yqui:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(yqui)

    tolua.cast(ccui.Helper:seekWidgetByName(yqui, "fanghao"), "ccui.Text"):setString(rtn_msg.room_id)


    if rtn_msg.qunzhu == 4 then
        ccui.Helper:seekWidgetByName(yqui, "fangkashu"):setScale(0.8)
        if rtn_msg.total_ju<= 10 then
            ccui.Helper:seekWidgetByName(yqui, "fangkashu"):setString("每人1")
        else
           ccui.Helper:seekWidgetByName(yqui, "fangkashu"):setString("每人2")
        end
    else
        local ncard = g_qz_card[rtn_msg.qipai_type..rtn_msg.total_ju] or 1
        tolua.cast(ccui.Helper:seekWidgetByName(yqui, "fangkashu"), "ccui.Text"):setString("x"..ncard)
    end

    local str = self:getPlayDes(rtn_msg)
    tolua.cast(ccui.Helper:seekWidgetByName(yqui, "leixing"), "ccui.Text"):setString(str)


    ccui.Helper:seekWidgetByName(yqui,"btn-queren"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                yqui:removeFromParent(true)
                AudioManager:playPressSound()
                gt.wechatShareChatStart()
                if rtn_msg.qunzhu == 4 then
                    ymkj.wxReq(2, str, g_game_name.."房号:"..rtn_msg.room_id.."(亲友圈-AA)", g_share_url.."&room_id="..rtn_msg.room_id)
                else
                    ymkj.wxReq(2, str, g_game_name.."房号:"..rtn_msg.room_id.."(亲友圈畅玩)", g_share_url.."&room_id="..rtn_msg.room_id)
                end
                gt.wechatShareChatEnd()
            end
        end
    )

    ccui.Helper:seekWidgetByName(yqui,"btn-quxiao"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                yqui:removeFromParent(true)
            end
        end
    )
end

function MainScene:getPlayDes(rtn_msg)
    local str = ""
    rtn_msg.qipai_type = rtn_msg.qipai_type or rtn_msg.hall_name
    local has_trans = nil
    if rtn_msg.qipai_type == "MAJAING_HALL" then
        rtn_msg.qipai_type = "MAJIANG_HALL"
        has_trans = true
    end

    if rtn_msg.qipai_type == "CSMJ_HALL" or rtn_msg.qipai_type == "MAJIANG_HALL" then
        if rtn_msg.kaifang then

        if rtn_msg.is_ningxiang == 1 then
            str = str.."宁乡麻将:"
        else
            str = str.."长沙麻将:"
        end

        if rtn_msg.kaiwang == 1 then
            str = str.."上下王."
        else
            str = str.."原始."
        end
        str = str..rtn_msg.total_ju.."局"..(rtn_msg.people_num or 4).."人."
        if rtn_msg.kaifang == 1 then
            str = str.."全开放."
        elseif rtn_msg.kaifang == 2 then
            str = str.."半开放."
        else
            str = str.."不开放."
        end
        if rtn_msg.zx == 1 then
            str = str.."算庄闲."
        else
            str = str.."不算庄闲."
        end

        if rtn_msg.zm == 1 then
            if rtn_msg.kaiwang == 1 then
                str = str.."只准自摸."
            else
                str = str.."门清自摸."
            end
        end

        if rtn_msg.has_zhongtusixi == 1 then
            str = str.."中途四喜."
        end

        rtn_msg.niaonum = rtn_msg.niaonum or 0
        if rtn_msg.niaonum == 100 then
            str = str.."一鸟全中(加分)."
        elseif rtn_msg.niaonum <= 10 then
            str = str.."扎"..rtn_msg.niaonum.."鸟(加分)."
        else
            str = str.."扎"..(rtn_msg.niaonum-10).."鸟(翻倍)."
        end
        if rtn_msg.piaoniao == 0 then
            str = str.."不飘鸟."
        else
            str = str.."飘鸟."
        end

        else

        if rtn_msg.kaiwang == 1 then
            str = str.."红中麻将:"
        else
            str = str.."转转麻将:"
        end
        str = str..rtn_msg.total_ju.."局"..(rtn_msg.people_num or 4).."人."
        if rtn_msg.majiang_type ~= 2 then
            str = str.."可抢杠胡."
        else
            str = str.."自摸胡."
        end

        if rtn_msg.zx == 1 then
            str = str.."算庄闲."
        else
            str = str.."不算庄闲."
        end

        if rtn_msg.has_qixiaodui == 1 then
            str = str.."可胡七对."
        end

        if rtn_msg.niaonum == 101 then
            str = str.."摸几奖几."
        elseif rtn_msg.niaonum == 100 then
            str = str.."一鸟全中(加分)."
        else
            str = str.."扎"..(rtn_msg.niaonum or 1).."鸟."
        end

        if rtn_msg.piaoniao == 0 then
            str = str.."不飘鸟."
        else
            str = str.."飘鸟."
        end

        if rtn_msg.jpbc == 1 then
            str = str.."见炮必踩."
        end

        end
    elseif rtn_msg.qipai_type == "MJGXTDH_HALL" then
        str = str.."推倒胡:"

        str = str..rtn_msg.total_ju.."局"..(rtn_msg.people_num or 4).."人."
        if rtn_msg.has_dapai == 1 then
            str = str.."大牌."
        end
        if rtn_msg.has_wufen == 1 then
            str = str.."全五分."
        end
        if rtn_msg.can_qianggang == 1 then
            str = str.."可抢杠胡."
        end
        if rtn_msg.qianggang_all == 1 then
            str = str.."抢杠胡全包."
        end
        if rtn_msg.gangbao_all == 1 then
            str = str.."杠爆全包."
        end
        if rtn_msg.no_feng == 1 then
            str = str.."不带风."
        end
        if rtn_msg.has_qidui == 1 then
            str = str.."可胡七对."
        end
        if rtn_msg.qidui_fan == 1 then
            str = str.."七对加番."
        end
        if rtn_msg.no_gui_double == 1 then
            str = str.."无鬼加倍."
        end
        if rtn_msg.jiejiegao == 1 then
            str = str.."节节高."
        end
        if rtn_msg.gen_zhuang ==1 then
            str = str.."跟庄."
        end
        if rtn_msg.gui_type==0 then
            str = str.."无鬼."
        elseif rtn_msg.gui_type==1 then
            str = str.."单鬼."
        elseif rtn_msg.gui_type==2 then
            str = str.."双鬼."
        elseif rtn_msg.gui_type==3 then
            str = str.."白板做鬼."
        end
        if rtn_msg.ma_num==100 then
            str = str.."爆炸马(加分)."
        elseif rtn_msg.ma_num==101 then
            str = str.."爆炸马(翻倍)."
        elseif rtn_msg.ma_num==0 then
            str = str.."无马."
        else
            str = str.."买"..rtn_msg.ma_num.."马."
        end
        if rtn_msg.ma_gen_difen==1 then
            str = str.."马跟底分."
        end
        if rtn_msg.queyimen == 1 then
            str = str.."缺一门(万)."
        end
        if rtn_msg.can_jiepao == 1 then
            str = str.."可接炮."
        end
    elseif rtn_msg.qipai_type == "PDK_HALL" then
        str = str.."跑得快:"
        str = str..rtn_msg.people_num.."人玩:"
        if rtn_msg.poke_type == 1 then
            str = str.."16张牌."
        elseif rtn_msg.poke_type == 2 then
            str = str.."15张牌."
        elseif rtn_msg.poke_type == 3 then
            str = str.."切四张牌."
        end
        if rtn_msg.chu_san ~= 2 then
            str = str.."首把必带黑桃3."
        end
        if rtn_msg.host_type ~= 2 then
            str = str.."赢家当庄."
        else
            str = str.."黑桃3当庄."
        end
        if rtn_msg.has_houzi == 1 then
            str = str.."带猴子."
        else
            str = str.."不带猴子."
        end
        if rtn_msg.qiang_guan == 1 then
            str = str.."不可强关."
        else
            str = str.."可以强关."
        end
        if rtn_msg.zha_chai == 1 then
            str = str.."炸弹不可拆."
        else
            str = str.."炸弹可拆."
        end
        if rtn_msg.left_show == 1 then
            str = str.."牌数显示."
        end
        if rtn_msg.bdbcd == 1 then
            str = str.."报单必出大."
        end
        str = str..rtn_msg.total_ju.."局."
    elseif rtn_msg.qipai_type == "pk_jdpdk" then
        str = str.."经典跑得快:"
        str = str..rtn_msg.people_num.."人玩:"
        if room_info.chu_san == 1 then
            str = str.."首出必带红桃3."
        end
    elseif rtn_msg.qipai_type == "PHZ_HALL" or rtn_msg.qipai_type == "YHZYY_HALL" then
        if rtn_msg.address_id == 1 then
            str = "益阳常德:"..rtn_msg.total_ju.."局.红胡.点胡.红乌.乌胡.对对胡.大小字胡.天地胡.海底胡."
        elseif rtn_msg.address_id == 8 then
            local fending = "不"
            if rtn_msg.total_score and rtn_msg.total_score ~= 0 then
                fending = rtn_msg.total_score.."分"
            end
            if rtn_msg.mingang == 4 then
                str = "汉寿字牌:"..rtn_msg.total_ju.."局."
                if rtn_msg.total_score == 1 then
                    str = str.."倒一."
                elseif rtn_msg.total_score == 3 then
                    str = str.."倒三."
                elseif rtn_msg.total_score == 5 then
                    str = str.."倒五."
                elseif rtn_msg.total_score == 8 then
                    str = str.."倒八."
                end
            elseif rtn_msg.mingang == 3 then
                str = "常德全名堂:红黑点."..rtn_msg.total_ju.."局."..fending.."封顶."
            elseif rtn_msg.mingang == 2 then
                str = "常德全名堂:全名堂(8-10番)."..rtn_msg.total_ju.."局."..fending.."封顶."
            else
                str = "常德全名堂:全名堂(6-8番)."..rtn_msg.total_ju.."局."..fending.."封顶."
            end
            if rtn_msg.mingang_list then
                 if rtn_msg.mingang == 4 then
                    if rtn_msg.mingang_list[1] == 1 then
                        str = str.."红胡."
                    end
                    if rtn_msg.mingang_list[2] == 1 then
                        str = str.."乌胡."
                    end
                    if rtn_msg.mingang_list[3] == 1 then
                        str = str.."点胡."
                    end
                    if rtn_msg.mingang_list[4] == 1 then
                        str = str.."夹红."
                    end
                    if rtn_msg.mingang_list[5] == 1 then
                        str = str.."碰胡."
                    end
                elseif rtn_msg.mingang == 2 then
                    if rtn_msg.mingang_list[14] == 1 then
                        str = str.."黄番."
                    end
                    if rtn_msg.mingang_list[13] == 1 then
                        str = str.."七行息."
                    end
                    if rtn_msg.mingang_list[12] == 1 then
                        str = str.."大团圆."
                    end
                    if rtn_msg.mingang_list[11] == 1 then
                        str = str.."耍猴."
                    end
                    if rtn_msg.mingang_list[10] == 1 then
                        str = str.."听胡."
                    end
                elseif rtn_msg.mingang == 1 then
                    if rtn_msg.mingang_list[12] == 1 then
                        str = str.."项项息."
                    end
                    if rtn_msg.mingang_list[11] == 1 then
                        str = str.."印."
                    end
                    if rtn_msg.mingang_list[10] == 1 then
                        str = str.."听胡."
                    end
                end
            end
        elseif rtn_msg.address_id == 2 then
            str = "长沙跑胡:"..rtn_msg.total_ju.."局.红胡.点胡.乌胡.对对胡.大小字胡.天地胡.双飘.比胡."
        elseif rtn_msg.address_id == 4 then
            str = "怀化红拐弯:"..rtn_msg.total_ju.."局.红胡.点胡.乌胡.对对胡.大小字胡.天地胡.海底胡."
        elseif rtn_msg.address_id == 5 then
            local str_ka = "卡歪."
            if rtn_msg.ka_wai == 1 then
                str_ka = "不卡歪."
            end
            str = "岳阳歪胡:"..rtn_msg.total_ju.."局."..str_ka
        elseif rtn_msg.address_id == 6 then
            str = "益阳歪胡:"..rtn_msg.total_ju.."局."..(rtn_msg.min_xi or 6).."息起."..(rtn_msg.max_xi or 200).."息顶."
            if rtn_msg.has_mingtang == 1 then
                str = str.."名堂."
            end
            if rtn_msg.has_daxiaohu == 1 then
                str = str.."大小字."
            end
            if rtn_msg.has_tiandihu == 1 then
                str = str.."天地胡."
            end
        elseif rtn_msg.address_id == 3 then
            str = "娄底放炮罚:单局"..rtn_msg.total_score.."胡息封顶.满100胡息结束.可胡放炮."
-----------zengya 2018.05.08
        elseif rtn_msg.address_id == 14 then
            str = "湘潭跑胡子:"..rtn_msg.total_ju.."局."
            self.hasYWS = rtn_msg.hasYWS
            self.weiType = rtn_msg.weiType

            if rtn_msg.zhuangType == 1 then
                str = str.."随机庄."
            elseif rtn_msg.zhuangType == 2 then
                str = str.."房主庄."
            end
            if rtn_msg.weiType == 1 then
                str = str.."明偎."
            elseif rtn_msg.weiType == 2 then
                str = str.."暗偎."
            end
            if rtn_msg.hasYWS == 1 then
                str = str.."一五十."
            end
            if rtn_msg.isZhangXiChi == 1 then
                str = str.."涨吃."
            end
            if rtn_msg.isZiMoJiaXi == 1 then
                str= str.."自摸加3."
            end
            local mt_name = {
                "30胡",
                "天地",
                "碰碰",
                "大小字",
                "黑",
                "一点红",
                "13红",
                "10红",
            }

            for i , v in pairs(rtn_msg.mt_list) do
                if v ==1 then
                    str= str.. mt_name[i].."."
                end
            end
-----------end 05.08
        else
            str = "邵阳剥皮:满"..(rtn_msg.total_score or 100).."胡息结束."
            if rtn_msg.tianhu == 1 then
                str = str.."天地胡."
            end
            if rtn_msg.honghei == 1 then
                str = str.."红黑胡."
            end
        end
    elseif rtn_msg.qipai_type == "DDZ_HALL" then
        str = (rtn_msg.people_num or 3).."人斗地主:"
        if rtn_msg.host_type ~= 2 then
            str = str.."赢家叫地主."
        else
            str = str.."轮流叫地主."
        end
        if rtn_msg.left_show == 1 then
            str = str.."牌数显示."
        end
        str = str..rtn_msg.difen.."分场."..rtn_msg.max_zhai.."炸封顶."..rtn_msg.total_ju.."局."
    elseif rtn_msg.qipai_type == "DDZ4_HALL" then
        str = "4人斗地主:"
        str = str..rtn_msg.total_ju.."局."
        if rtn_msg.host_type ~= 2 then
            str = str.."赢家叫地主."
        else
            str = str.."轮流叫地主."
        end
        str = str..rtn_msg.difen.."分场."
        if rtn_msg.max_zhai and rtn_msg.max_zhai ~= 0 then
            str = str..rtn_msg.max_zhai.."炸."
        else
            str = str.."不封顶."
        end
        if rtn_msg.can_jiabei == 1 then
            str = str.."可加倍."
        end
        if rtn_msg.left_show == 1 then
            str = str.."牌数显示."
        end
        if rtn_msg.zhai_mode == 2 then
            str = str.."炸弹翻倍"
        end
    end
    if rtn_msg.qunzhu == 4 then
        str = str.."(亲友圈-AA)"
    else
        str = str.."(亲友圈畅玩)"
    end

    if has_trans and rtn_msg.qipai_type == "MAJIANG_HALL" then
        rtn_msg.qipai_type = "MAJAING_HALL"
    end
    return str
end

function MainScene:openVipCreate(club_id, callfunc, btn)

    local pb_node = ccui.Layout:create()
    pb_node:setTouchEnabled(true)
    -- pb_node:setBackGroundColorType(1)
    -- pb_node:setBackGroundColor(cc.c3b(0, 0, 0))
    -- pb_node:setOpacity(0)
    pb_node:setContentSize(g_visible_size)
    self:addChild(pb_node, ZOrder.DIALOG)

    local yqui = tolua.cast(cc.CSLoader:createNode("ui/VIPKF.csb"), "ccui.Widget")
    self:addChild(yqui, ZOrder.DIALOG)
    yqui:setPosition(commonlib.worldPos(btn))

    local btn_list = {
                      ccui.Helper:seekWidgetByName(yqui, "BtnVip"),
                      ccui.Helper:seekWidgetByName(yqui, "BtnAA"),
                      ccui.Helper:seekWidgetByName(yqui, "BtnClose"),
                      pb_node,
                     }

    if club_id and self.club_info and self.club_info.free_mode then
        if self.club_info.free_mode == 2 then
            btn_list[1]:setTouchEnabled(false)
            btn_list[1]:setBright(false)
        elseif self.club_info.free_mode == 1 then
            btn_list[2]:setTouchEnabled(false)
            btn_list[2]:setBright(false)
        end
    end

    for i=1, 4 do

        if i ~= 4 then
            btn_list[i].pos = cc.p(btn_list[i]:getPosition())
            btn_list[i]:setPosition(cc.p(0, 0))
            btn_list[i]:setScale(0.1)

            btn_list[i]:runAction(cc.Spawn:create(cc.MoveTo:create(0.25, btn_list[i].pos), cc.ScaleTo:create(0.25, 1),
                                    cc.RotateBy:create(0.25, 360)))
        end

        btn_list[i]:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i == 1 then
                    callfunc(1)
                elseif i == 2 then
                    callfunc(4)
                end
                for ii=1, 3 do
                    if ii == 3 then
                        btn_list[ii]:runAction(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(0, 0)), cc.ScaleTo:create(0.2, 0.1),
                        cc.RotateBy:create(0.2, 360)))
                    else
                        btn_list[ii]:runAction(cc.Sequence:create(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(0, 0)), cc.ScaleTo:create(0.2, 0.1),
                        cc.RotateBy:create(0.2, 360)), cc.CallFunc:create(function()
                            yqui:removeFromParent(true)
                            pb_node:removeFromParent(true)
                        end)))
                    end
                end
            end
        end)
    end
end

--[[function MainScene:showPlayerXinxi()
    local profile = ProfileManager.GetProfile()
    if not profile then return  end
    local gerenxx = tolua.cast(cc.CSLoader:createNode("ui/DT_Genrenxx.csb"), "ccui.Widget")
    self:addChild(gerenxx, ZOrder.DIALOG)

    gerenxx:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(gerenxx)

    ccui.Helper:seekWidgetByName(gerenxx,"btExit"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                --commonlib.scaleOut(ccui.Helper:seekWidgetByName(gerenxx, "Panel_2"))
                --commonlib.fadeOut(ccui.Helper:seekWidgetByName(gerenxx, "Panel_1"), function()
                gerenxx:removeFromParent(true)
                --end)
            end
        end
    )
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(gerenxx, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(gerenxx, "Panel_1"))
    if pcall(commonlib.GetMaxLenString, profile.name, 14) then
        ccui.Helper:seekWidgetByName(gerenxx,"name"):setString(commonlib.GetMaxLenString(profile.name, 14))
    else
        ccui.Helper:seekWidgetByName(gerenxx,"name"):setString(profile.name)
    end
    ccui.Helper:seekWidgetByName(gerenxx,"ID"):setString(profile.uid)
    ccui.Helper:seekWidgetByName(gerenxx,"lab_yanbaoshu2"):setString(profile.card or 0)
    ccui.Helper:seekWidgetByName(gerenxx,"IP"):setString(profile.ip)
    ccui.Helper:seekWidgetByName(gerenxx,"head"):downloadImg(commonlib.wxHead(profile.head), g_wxhead_addr)

end]]
function MainScene:showShopdaili()
    local csb = DTUI.getInstance().csb_DT_kefu
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node, ZOrder.DIALOG)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    ccui.Helper:seekWidgetByName(node, "wxNum1"):setString(gt.getConf("wxFkYx") or '敬请期待')
    ccui.Helper:seekWidgetByName(node, "wxNum2"):setString(gt.getConf("wxFkFk") or '敬请期待')
    local wxnumber1 = tolua.cast(ccui.Helper:seekWidgetByName(node, "wxNum1"), "ccui.Text"):getString()
    local wxnumber2 = tolua.cast(ccui.Helper:seekWidgetByName(node, "wxNum2"), "ccui.Text"):getString()

    tolua.cast(ccui.Helper:seekWidgetByName(node,"Copy_1"), "ccui.Button"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if ymkj.copyClipboard then
                    ymkj.copyClipboard(wxnumber1)
                end
             commonlib.showTipDlg("复制内容 "..wxnumber1.." 成功")
            end
        end
    )

    tolua.cast(ccui.Helper:seekWidgetByName(node,"Copy_2"), "ccui.Button"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if ymkj.copyClipboard then
                    ymkj.copyClipboard(wxnumber2)
                end
            commonlib.showTipDlg("复制内容 "..wxnumber2.." 成功")
            end
        end
    )
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
end

function ymimCallback(str, portrait, parent)
    local rtn_msg = json.decode(str)
    commonlib.echo(rtn_msg)
    if rtn_msg.cmd == "cool_pao" then
        print('sound cool_pao')
    elseif rtn_msg.cmd == "finish_play" then
        print('sound finish_play')
        if rtn_msg.result ~= 0 and rtn_msg.msg then
            commonlib.showLocalTip(rtn_msg.msg)
        end
        EventBus:dispatchEvent(EventEnum.onPlayStop,{mType = "yaya",index = rtn_msg.index})
    elseif rtn_msg.result ~= 0 then
        print('sound rtn_msg.result')
        if rtn_msg.msg then
            commonlib.showLocalTip(rtn_msg.msg)
        end
    else
        if rtn_msg.path == "http://f.aiwaya.cn:80/" or #rtn_msg.path <= 22 then
            commonlib.showLocalTip("～音量太小，或未对准麦克风，说话失败～")
        else
            local input_msg = {
                cmd =NetCmd.C2S_ROOM_CHAT,
                msg_type=3,
                msg = rtn_msg.path,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end
end

-- 是否播放主界面动画  参数1：是否播放主界面动画  参数2：只重新创建名字为 “jiarufangjian” 的骨骼动画
function MainScene:isPlayMainAction(is_play, isOnlyJRFJ)
    -- 存放骨骼动画的名字
    local actionName = {"qinyouquan", "jiarufangjian", "chuangjianfangjian", "juese"}
    if is_play then
        -- 图片设置不可见
        self.img_qingyouquan:setVisible(false)
        self.img_joinroom:setVisible(false)
        self.img_createroom:setVisible(false)
        self.img_juese:setVisible(false)
        if not isOnlyJRFJ then
            -- 播放骨骼动画（添加的父节点不同其 playInteractiveSpine函数的第一个参数不同）
            for __,v in ipairs(actionName) do
                if v == "qinyouquan" then
                    if not ios_checking then
                        gt.playInteractiveSpine(self,v)
                    end
                elseif v == "juese" then
                    gt.playInteractiveSpine(self.node,v)
                else
                    gt.playInteractiveSpine(self,v)
                end
            end
        else
            gt.playInteractiveSpine(self,"jiarufangjian")
        end
    else
        -- 可以返回房间
        if self.is_back_fromroom == "true" then
            if gt.getLocalString("hall_style") == "huaijiu" then
                self.img_joinroom:loadTexture("ui/qj_main_before/backroom.png")
            else
                self.img_joinroom:loadTexture("ui/qj_setting/backroom.png")
            end
        else
            if gt.getLocalString("hall_style") == "huaijiu" then
                self.img_joinroom:loadTexture("ui/qj_main_before/join-room.png")
            else
                self.img_joinroom:loadTexture("ui/qj_setting/join-room.png")
            end

        end
        self.img_qingyouquan:setVisible(true)
        self.img_joinroom:setVisible(true)
        self.img_createroom:setVisible(true)
        self.img_juese:setVisible(true)
        for __,v in ipairs(actionName) do
            local child = self:getChildByName(v)
            if v == "juese" then
                child = self.node:getChildByName(v)
            end
            if child then
                -- 移除骨骼动画
                child:runAction(cc.RemoveSelf:create())
            end
        end
    end
end

-- 设置主界面风格（在DTUI中判断了是哪一种主界面风格）
-- 本函数通过重新加载MainScene场景从而实现主界面风格改变的效果
function MainScene:updateHallStyle()
    gt.setLocalBool("isOpenAgainDialog", true, true)
    -- 重新加载MainScene场景
    local gameScene = cc.Scene:create()
    gameScene:addChild(require("scene.MainScene"):create())
    cc.Director:getInstance():replaceScene(gameScene)
end

-- 回复开始的设置界面(即将设置界面手动显示出来)
function MainScene:refreshSetDialog()
    local SetLayer = require("scene.kit.SetDialog")
    local set = SetLayer.create()
    set.is_in_main = true
    self:addChild(set, ZOrder.DIALOG)
end
return MainScene
