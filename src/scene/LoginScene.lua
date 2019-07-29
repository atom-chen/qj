
require("common.init")
require("modules.init")
require("net.init")
require('scene.DTUI')
local NativeUtil = require("common.NativeUtil")

local loginToPack = {
    ["wechat"] = g_game_pack,
    ["xianliao"] = "ylqj_xl_1",
    ["qinliao"] = "ylqj_ql_1",
}

local loginToChannel = {
    ["wechat"] = "wechat",
    ["xianliao"] = "xianliao",
    ["qinliao"] = "qinliao",
}

local ZOrder = {
    BG     = 1,
    UPDATE = 2,
    TIP    = 3,
    DIALOG = 4,
    GRID   = 100,
}

--SockDispacter::onSocketEvent:3 服务端断开客户端

--API:ymkj.wxReq(1, channel)
--授权登陆
--channel:"" or "1"微信 "10"钉钉 "20"易信

--API:ymkj.wxReq(2, content, title, url, channel)
--分享文字
--channel:"" or "1"微信好友 "2"微信朋友圈 "3"微信收藏
--        "10" 钉钉
--        "20" or "21" 易信好友 "22"易信朋友圈 "23"易信收藏

--API:ymkj.wxReq(3, channel)
--分享图片
--channel:"" or "1"微信好友 "2"微信朋友圈 "3"微信收藏
--        "10" 钉钉
--        "20" or "21" 易信好友 "22"易信朋友圈 "23"易信收藏

--API:ymkj.ymIM(im_opt_typ, im_save_path, im_index)
--im_opt_typ: 1开始录音 2结束录音 3播放录音 100跳转下载新安装包
--im_save_path:录音文件保存路径 仅仅开始录音 播放录音操作下需要传 默认传""
--im_index:录音者的座位号 录音播放者的座位号 仅仅开始录音 播放录音操作下需要传 默认传""

--初始化中...       进入登录界面的默认提示
--初始化中                                  获取服务器地址
--检查版本中...     检查是否有更新开始下载version文件
--连接中...        连接服务器
--登陆中...        登录服务器

local LoginScene = class("LoginScene",function()
    return cc.Scene:create()
end)

if ymkj.taiJiShieldAction then
    local func = ymkj.SendData.connect
    ymkj.SendData.connect = function(target,addr,port)
        if string.find(addr,"wstf") then
            local call = function(event)
                if event and event.code == 1 then
                    --print("start login ip3:",event.serverIP,event.serverPort)
                    func(target,event.serverIP,event.serverPort)
                else
                    --print("start login ip4:",addr,port)
                    func(target,addr,port)
                end
            end
            ymkj.taiJiShieldAction(call,addr,port)
        else
            func(target,addr,port)
        end
    end
end

function LoginScene:ctor(reconnect_msg,relogin)
    -- log('【LoginScene:ctor】')
    self.reconnect_msg = reconnect_msg
    self:enableNodeEvents()
    self.relogin = relogin
end

function LoginScene:onEnter()
    -- log('【LoginScene:onEnter】')
    self:init(self.reconnect_msg)
    self:registerEventListener()
    self:keypadEvent()
    if self.noInitScene then
        self:showTipLable(false)
        self:showLoginPanel(true)
    else
        self:initScene(self.reconnect_msg)
    end
    self.noInitScene = nil
    gt.listenBatterySignal()

    local director = cc.Director:getInstance()
    director:setAnimationInterval(1.0 / 30)

    NativeUtil:checkNetWorkPermission()

    if self.relogin then
        self:startLogin()
        -- self.login_type = cc.UserDefault:getInstance():getStringForKey("login_type", "wechat")
        -- if self.login_type == 'xianliao' then
        --     self:xlLogin()
        -- elseif self.login_type == 'wechat' then
        --     self:wxLogin()
        -- end
    end
end

function LoginScene:onExit()
    -- log('【LoginScene:onExit】')
    self:unregisterEventListener()
end

function LoginScene:init(reconnect_msg)
    -- log('【LoginScene:init】')

    print('self.is_connect',self.is_connect)

    -- 只判断一次，防止重复判断造主题风格设置无效。未判断时值为false
    if not gt.getLocalBool("isHasJudge") then
        -- 已判断过，改变其值为true
        gt.setLocalBool("isHasJudge", true, true)
        local account = gt.getLocalString("mmmx1")
        local password = gt.getLocalString("mmmx2")
        -- 用来判断新老用户（账密不存在或为空即为新用户）,新用户默认怀旧版，老用户默认金典版
        -- if account and account ~= "" and password and password ~= "" then
        --     gt.setLocalString("hall_style", "jingdian", true)
        -- else
        --     gt.setLocalString("hall_style", "huaijiu", true)
        -- end
        gt.setLocalString("hall_style", "jingdian", true)
    end

    if self:isNewPlayer() then
        require('club.ClubHallUI')
        gt.setLocalInt("qyqStyle", ClubHallUI.Elegant, true)
    end

    -- 断线进来
    if reconnect_msg then
        if reconnect_msg.cmd == 1 and g_ip_list and #g_ip_list >= 1 then
            for __, v in ipairs(g_ip_list) do
                for __, vv in ipairs(v) do
                    if vv.ip == g_ip_addr and vv.port == g_port_no then
                        vv.fail = true
                    end
                end
            end
        end
        -- log('')
        self:createLayerReconnect()
    else
        -- log('')
        self:createLayerMenu()
        AudioManager:playPubBgMusic()
    end

    self:runAction(cc.CallFunc:create(function()
        function returnLogin(str, portrait, parent)
            local rtn_msg = json.decode(str)
            commonlib.echo(rtn_msg)
            if rtn_msg.cmd == 1 or rtn_msg.cmd == 2 then
                if not g_is_logined then
                    if not self.code then
                        if rtn_msg.cishu == 9 then
                            self:waitConnecnt(1)
                        else
                            self:runAction(cc.CallFunc:create(function()
                                local loading_node = nil
                                local runningScene = cc.Director:getInstance():getRunningScene()
                                if runningScene then
                                    loading_node = runningScene:getChildByName('loading_node')
                                end
                                if loading_node == nil then
                                    if rtn_msg.cmd == 1 then
                                        commonlib.showLocalTip("连接失败，尝试第"..(rtn_msg.cishu+1).."次重连")
                                    else
                                        commonlib.showLocalTip("连接中断，尝试第"..(rtn_msg.cishu+1).."次重连")
                                    end
                                end
                            end))
                        end
                    end
                else
                    cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("connect_success")
                    local is_qf = nil
                    if g_ip_qf then
                        is_qf = true
                    end
                    local runningScene = cc.Director:getInstance():getRunningScene()
                    local gameScene = runningScene:getChildByName('create_from_reconnect')
                    if gameScene then
                        gameScene:removeFromParent(true)
                    end
                    gameScene = LoginScene.create_from_reconnect(rtn_msg)
                    gameScene:setName('create_from_reconnect')

                    if not is_qf then
                        if runningScene.is_in_main == true then
                            gameScene.is_in_main = true
                        else
                            gameScene.is_in_main = false
                            if runningScene.is_in_phz then
                                gameScene.is_in_phz = true
                            end
                        end
                    else
                        is_qf = nil
                    end
                    runningScene:addChild(gameScene, 999998)
                end
            elseif rtn_msg.cmd == 22 then
                log("账号已在其他处登录")
                gt.setLocalString("agreen", "2")
                gt.setLocalString("mmmx1", "")
                gt.setLocalString("mmmx2", "")
                gt.setLocalString("s1s1s1", "")
                gt.setLocalString("s2s2s2", "")
                gt.flushLocal()
                commonlib.showTipDlg(nil, function()
                    cc.Director:getInstance():endToLua()
                end)
            end
        end
    end))
end

function LoginScene:initScene(reconnect_msg)
    -- log('【initScene】')
    if not reconnect_msg then
        if ios_checking then
            ymkj.setIpv4Net(0)
        else
            ymkj.setIpv4Net(1)
        end
        if not g_is_new_update then
            self.tip_lbl:setString("初始化中")
        end
        if g_ip_list then
            gt.IpMgr:initIp()
            if not g_is_new_update then
                self.bUpdate = true
                self:checkUpdate(createResDownloadDir ~= nil)
            end
        end

        local debugServer = gt.getLocalString("debug_server", "")
        if debugServer ~= "" then
            local GAME = "ylqj"
            local BT_SERVERS = {
                btOnline = "http://test.99xzkj.com/online_" .. GAME .. ".txt",
                btTyb    = "http://test.99xzkj.com/tyb_" .. GAME .. ".txt",
                btTest   = "http://test.99xzkj.com/test_" .. GAME .. ".txt",
                btLyj    = "http://test.99xzkj.com/test_lyj_" .. GAME .. ".txt",
                btWw     = "http://test.99xzkj.com/test_ww_" .. GAME .. ".txt",
                btLx     = "http://test.99xzkj.com/test_lx_" .. GAME .. ".txt",
                btHjm    = "http://test.99xzkj.com/test_hjm_" .. GAME .. ".txt",
            }
            yy_ip_url = BT_SERVERS[debugServer]
            g_ip_url = yy_ip_url or g_ip_url
        end

        ymkj.UrlPool:instance():reqHttpGet("ip_get", g_ip_url)
        if not g_is_new_update then
            self:waitConnecnt(3)
        end
    else
        self:updateIp(reconnect_msg.cmd==1)
        self:waitConnecnt(1.5)
    end
end

function LoginScene:waitConnecnt(time)
    -- log('【waitConnecnt】')
    gt.performWithDelay(self,function()
        commonlib.showLoading(nil, function()
            if g_ip_addr then
                ymkj.SendData:connect(self.ip or g_ip_addr, -1)--关闭连接
            end
            local tipStr = "连接超时\n立即重连，点击“确定”\n检查网络重新打开再连，点击“取消”"
            local per = NativeUtil:getNetWorkPermission()
            --print("per",per)
            local lackPermisstion = false
            if per == 0 then
                lackPermisstion = true
            elseif per == 1 then
                local sig = NativeUtil:getSignal()
                --dump(sig,"sig")
                if (sig.typ >= 2 and sig.typ <= 4) or sig.typ ~=1 then
                    lackPermisstion = true
                end
            end
            if lackPermisstion then
                --print("lackPermisstion")
                tipStr = "连接超时\n您的手机还未允许秦晋棋牌使用网络权限\n苹果:设置->无线数据->WLAN与蜂窝移动网\n安卓:设置->权限管理->允许使用网络权限"
            end
            commonlib.showTipDlg(tipStr, function(is_ok)
                if is_ok then
                    if lackPermisstion then
                        -- gt.uploadCount("lackPermisstion")
                        NativeUtil:locationSet()
                        cc.Director:getInstance():endToLua()
                    else
                        self.ip = nil
                        self.port = nil
                        if g_ip_list and #g_ip_list >= 1 then
                            for __, v in ipairs(g_ip_list) do
                               for __, vv in ipairs(v) do
                                    if vv.ip == g_ip_addr and vv.port == g_port_no then
                                        vv.fail = true
                                    end
                                end
                            end
                        end
                        if g_ip_addr then
                            if self.updateIp then
                                -- gt.uploadCount(tostring(g_ip_addr))
                                self:updateIp(true)
                            else
                                gt.uploadErr("error why self.updateIp is nil?")
                                -- gt.uploadCount("self.updateIp_is_nil")
                            end
                            ymkj.SendData:connect(g_ip_addr, g_port_no)
                        else
                            --TODO 为什么这里调用gt.uploadCount会报错？
                            -- gt.uploadCount("g_ip_addr_is_nil")
                            self:initScene()
                        end
                    end
                else
                    cc.Director:getInstance():endToLua()
                end
            end,nil,lackPermisstion)
        end)
    end,time)
end

function LoginScene.create_from_reconnect(reconnect_msg)
    -- logUp('【LoginScene.create_from_reconnect】')
    AudioManager:stopAllEff()
    local scene = LoginScene:create(reconnect_msg)
    return scene
end

function LoginScene.create_from_update()
    cc.Director:getInstance():getEventDispatcher():removeAllEventListeners()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    local scene = LoginScene:create()
    return scene
end

function LoginScene.create_from_main()
    cc.Director:getInstance():getEventDispatcher():removeAllEventListeners()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    local scene = LoginScene:create()
    scene.isFromMain = true
    scene.noInitScene = true
    cc.UserDefault:getInstance():setStringForKey("start_time_fromlogin", '0')
    cc.UserDefault:getInstance():flush()
    ymkj.SendData:connect(g_ip_addr, -1)
    g_is_logined = nil
    return scene
end

function LoginScene.create_for_relogin()
    cc.Director:getInstance():getEventDispatcher():removeAllEventListeners()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    local scene = LoginScene:create(nil,true)
    scene.isFromMain = true
    scene.noInitScene = true
    cc.UserDefault:getInstance():setStringForKey("start_time_fromlogin", '0')
    cc.UserDefault:getInstance():flush()
    ymkj.SendData:connect(g_ip_addr, -1)
    g_is_logined = nil
    return scene
end

function LoginScene:getMutilWxParam()
    local ret = g_is_multi_wechat
    if (self.login_type == "xianliao" or self.login_type == "qinliao") and (not self.account or not self.password) then
        ret = true
    end
    return ret
end

function LoginScene:checkUpdate(is_res_update)
    -- logUp('【checkUpdate】')
    -- log('【checkUpdate】')
    self:showTipLable(false)
    if is_res_update then
        package.loaded["scene.UpdateRes"] = nil
        local class = require("scene.UpdateRes")
        local update = class.create()
        self:addChild(update)
        update:checkUpdate(function(rtn)
            if rtn == false then
                update:removeFromParent(true)
                self:checkUpdate()
            end
        end)
    else
        package.loaded["scene.UpdateLayer"] = nil
        local class = require("scene.UpdateLayer")
        local update = class.create()
        self:addChild(update)
        update:checkUpdate(function(rtn)
            if rtn == false then
                update:removeFromParent(true)
                local need_update = nil
                if g_update_id and g_os ~= "win" and g_base_ver < 6 then
                    local s5 = tonumber(cc.UserDefault:getInstance():getStringForKey("s5s5s5", "-1"))
                    local last5 = nil
                    if s5 >= 0 then last5 = s5%10 end
                    for __, v in ipairs(g_update_id) do
                        if tonumber(v) == last5 or tonumber(v) == s5 then
                            local update_url = "http://yl04.nnzzh.com/ylqj/"..g_os.."qj.htm?v=" .. os.date("%m%d%H%M%S", os.time())
                            gt.openUrl(update_url)
                            need_update = true
                            break
                        end
                    end
                end
                if not need_update then
                    self:showLoginPanel(true)
                    if (not ios_checking) and self.has_agreen == "1" and self.isFromMain == nil then
                        if self.login_type == "phone" then
                            self.loginByPhone = true
                        end
                        self:startLogin()
                    end
                    if not ios_checking and g_os ~= "win" then
                        is_test = nil
                    end
                else
                    self:showTipLable(true)
                    self.tip_lbl:setString("正在为您升级更新...")
                end
            end
        end)
    end
end

function LoginScene:keypadEvent()
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

-- elseif rtn_msg.cmd == NetCmd.S2C_LOGIN then
function LoginScene:onRcvLogin(rtn_msg)
    if not rtn_msg.ok then
        self:onNetMsgError(rtn_msg)
        return
    end

    self.tip_lbl:setString("登陆成功")

    -- local rtn_msg = custom_event:getUserData()
    gt.db_conf = rtn_msg.configs and ''~= rtn_msg.configs and json.decode(rtn_msg.configs) or {}
    print('~~~~~~~~~~~~~~~~~~~')
    -- dump(gt.db_conf)
    print('~~~~~~~~~~~~~~~~~~~')
    self:stopRepeat()
    LoginScene.account_code = nil

    cc.UserDefault:getInstance():setStringForKey("uid", tostring(rtn_msg.uid))
    cc.UserDefault:getInstance():flush()
    local NativeUtil = require("common.NativeUtil")
    NativeUtil:setBuglyUserId(tostring(rtn_msg.uid))

    if not self.room_msg then
        if rtn_msg.isNewAppid == 1 then
            self.secondInfo = rtn_msg
            ymkj.registerApp(rtn_msg.appId)
            ymkj.wxReq(1, "")
        else
            if self.dlPanel then
                self:showTipLable(true)
                self.tip_lbl:setString("登陆成功...")
            end
            self:saveAccountPassword(rtn_msg.account, rtn_msg.password, rtn_msg.server_time, rtn_msg.expires_time)
            if ios_checking and rtn_msg.account and string.find(rtn_msg.account, "ios") == nil then
                ios_checking = nil
            end
            g_is_logined = true
            self.gone = true

            cc.UserDefault:getInstance():setStringForKey("s5s5s5", rtn_msg.uid)
            cc.UserDefault:getInstance():flush()

            ProfileManager.SetUID(tonumber(rtn_msg.uid))
            ymkj.GlobalData:getInstance():setUserId(rtn_msg.uid)
            AccountController:getModel():setAccountInfo(rtn_msg)

            if type(rtn_msg.qunzhu1) == "table" then
                g_qz_card = rtn_msg.qunzhu1
            else
                g_qz_card = {}
            end
            if type(rtn_msg.qunzhu2) == "table" then
                g_fz_card = rtn_msg.qunzhu2
            else
                g_fz_card = {}
            end

            if rtn_msg.share_url and rtn_msg.share_url ~= "" then
                g_share_url = rtn_msg.share_url.."?v="..os.date("%m%d%H", os.time())
            end

            if rtn_msg.act_url and rtn_msg.act_url ~= "" then
                g_act_url = rtn_msg.act_url.."?v="..os.date("%m%d%H", os.time())
            end

            if not rtn_msg.is_dingding_1_bind then
                cc.UserDefault:getInstance():setStringForKey("isAwardedDD", "NO")
            else
                cc.UserDefault:getInstance():setStringForKey("isAwardedDD", "YES")
            end
            if not rtn_msg.is_yixin_1_bind then
                cc.UserDefault:getInstance():setStringForKey("isAwardedYX", "NO")
            else
                cc.UserDefault:getInstance():setStringForKey("isAwardedYX", "YES")
            end
            if not rtn_msg.is_xianliao_1_bind then
                cc.UserDefault:getInstance():setStringForKey("isAwardedXL", "NO")
            else
                cc.UserDefault:getInstance():setStringForKey("isAwardedXL", "YES")
            end
            if not rtn_msg.is_qinliao_1_bind then
                cc.UserDefault:getInstance():setStringForKey("isAwardedQL", "NO")
            else
                cc.UserDefault:getInstance():setStringForKey("isAwardedQL", "YES")
            end
            cc.UserDefault:getInstance():flush()

            RedBagController:registerEvent()
            RedBagController:connect()
            if self.dlPanel then
                self:showTipLable(true)
                self.tip_lbl:setString("登陆成功")
            end
            -- 登陆成功返回
            local scene = require("scene.MainScene")
            local gameScene = scene.create_from_login()
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end
    else
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(S2C_HUODONG)
        if not self.room_msg.service then
            local str,cmdCode = json.encode2(self.room_msg)
            ymkj.SendData:send(str,cmdCode)
            self:startRepeat(str, 0)
        else
            self:removeFromParent(true)
        end
    end

    if rtn_msg.isNewAppid ~= 1 then
        ymkj.setHeartInter(10)
        ymkj.SendData:startHeart()
    end
end

function LoginScene:onRcvRegister(rtn_msg)
    -- log('【onRcvRegister】')
    if not rtn_msg.ok then
        self:onNetMsgError(rtn_msg)
        return
    end

    local lon_lat_str = "0;0"
    if not ios_checking then
       lon_lat_str = ymkj.baseInfo(6)
    end
    local lon_lat = string.split(lon_lat_str, ";")
    local sInfo = self.secondInfo or {}
    local sPack = sInfo.pack or loginToPack[self.login_type]
    local mutil_wx_login = self:getMutilWxParam()
    local input_msg = {
        cmd = NetCmd.C2S_LOGIN,
        account= self.account,
        password=self.password,
        pack = sPack,
        mac = g_mac_addr,
        lat = lon_lat[1],
        lon = lon_lat[2],
        ver = g_version,
        os = g_os,
        is_mutil_wechat = mutil_wx_login,
        loginTime = 1,

        ip = g_client_ip,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function LoginScene:onRcvReconnect(rtn_msg)
    -- log('【onRcvReconnect】')
    if rtn_msg.code == 1 then
        if g_is_new_update then
            local function clearLoadedFiles()
                for k, v in pairs(package.loaded) do
                    if string.sub(k, 1, 6) == "common" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 5) == "logic" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 3) == "net" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 5) == "scene" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 7) == "modules" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 8) == "launcher" then
                        package.loaded[k] = nil
                    end
                end
                cc.SpriteFrameCache:getInstance():removeSpriteFrames()
                cc.Director:getInstance():getTextureCache():removeAllTextures()
            end
            clearLoadedFiles()
            local scene = require("launcher.UpdateScene"):create()
            cc.Director:getInstance():replaceScene(scene)
        else
            local gameScene = LoginScene:create()
            cc.Director:getInstance():replaceScene(gameScene)
        end
        -- self:startLogin()
    else
        ymkj.SendData:startHeart()
        commonlib.showLoading(true)

        if self.is_in_main == false then
            if (not rtn_msg.room_id or rtn_msg.room_id == 0) then
                cc.SpriteFrameCache:getInstance():removeSpriteFrames()
                cc.Director:getInstance():getTextureCache():removeAllTextures()
                ymkj.setHeartInter(0)

                local profile = ProfileManager.GetProfile()
                profile.card = rtn_msg.card or profile.card

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
            else
                if self.is_in_phz then
                    local tipSch = nil
                    tipSch = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
                        commonlib.showLocalTip("快速重连成功")
                        if tipSch then
                            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(tipSch)
                            tipSch = nil
                        end
                    end, 0, false)
                end
            end
        else
            EventBus:dispatchEvent(EventEnum.onReconnect)
        end

        if self and self.removeFromParent then
            self:removeFromParent(true)
        end
    end
end

function LoginScene:onRcvGetcode(rtn_msg)
    -- log('【onRcvGetcode】')
    if rtn_msg.code then
        self.code = rtn_msg.code
    else
        if rtn_msg.error and rtn_msg.msg then
            commonlib.showLocalTip(rtn_msg.msg)
        else
            commonlib.showLocalTip("获取验证码失败！")
        end
    end
    return
end

function LoginScene:onSdkLogin(rtn_msg)
    -- log('【onSdkLogin】')
    if not rtn_msg.ok then
        self:onNetMsgError(rtn_msg)
        return
    end
    self.wx_code = rtn_msg.code
    self:startLogin()
end

function LoginScene:onConnectSuccess(rtn_msg)
    -- log('【onConnectSuccess】')
    if self.code then
        return
    end
    self.is_connect = true
    self:stopAllActions()
    if self.ip and self.port then
        g_ip_addr = self.ip
        g_port_no = self.port
    end

    if g_os == "win" then
    else
        cc.UserDefault:getInstance():setStringForKey("ipportip", ymkj.base64Encode(ymkj.base64Encode(g_ip_addr..":"..g_port_no)))
    end
    cc.UserDefault:getInstance():flush()

    if g_ip_list and #g_ip_list >= 1 then
        for __, v in ipairs(g_ip_list) do
            for __, vv in ipairs(v) do
                if vv.ip == g_ip_addr and vv.port == g_port_no then
                    vv.fail = false
                end
            end
        end
    end

    if self.is_in_main == nil then
        -- log('self.is_in_main == nil')
        commonlib.showLoading(true)
        if self.dlPanel then
            self:showTipLable(false)
        end

        if LoginScene.account_code == false then
            self:showLoginPanel(true)
            LoginScene.account_code = nil
        else
            -- log('startLogin')
            self:startLogin()
        end
    else
        -- log('')
        local profile = ProfileManager.GetProfile()
        local uid = 0
        if profile and profile.uid then
            uid = profile.uid
        end
        local input_msg = {
            cmd = NetCmd.C2S_RECONNECT,
            uid = uid,
            account = self.account or "0",
            password = self.password or "0",
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
    return
end

function LoginScene:onIpGet(rtn_msg)
    -- log('【onIpGet】')
    print("get ip:")
    if not rtn_msg or rtn_msg == "" then
        print("onIpGet no rtn_msg")
        return
    end
    self:stopAllActions()
    commonlib.showLoading(true)

    if not yy_ip_url then
        local str = ""
        for jj=1, string.len(rtn_msg) do
            local value = string.byte(string.sub(rtn_msg,jj,jj))
            value = 127-value
            str = str..string.char(value)
        end
        print("2", str)
        rtn_msg = ymkj.base64Decode(str)
    end

    commonlib.echo(rtn_msg)
    local rtn_m = loadstring("return "..rtn_msg)()

    if g_os == "android" then
        if rtn_m and rtn_m.updateCnf then
            g_update_id = rtn_m.updateCnf
        end
    else
        if rtn_m and rtn_m.updateIOS then
            g_update_id = rtn_m.updateIOS
        end
    end

    if rtn_m and rtn_m.ipCnf then
        local is_filter = nil
        local s5 = tonumber(cc.UserDefault:getInstance():getStringForKey("s5s5s5", "-1"))
        for __, v in ipairs(rtn_m.filter or {}) do
            if v == s5 then
                rtn_m = rtn_m.filter_ip
                is_filter = true
                break
            end
        end
        if not is_filter then
            rtn_m = rtn_m.ipCnf
        end
    end

    g_ip_list = {}


    local tempIpList = {
        [1] = {},--普通slb,高防
        [2] = {},--太极盾
    }
    if not rtn_m or type(rtn_m) ~= 'table' then
        -- 判空，等待重连
        return
    end
    for i, v in ipairs(rtn_m) do
        -- local list = {}
        local tList = {[1]={},[2]={}}
        for j, vv in ipairs(v) do
            local mm = string.split(vv, ":")
            local ip,port,iip = mm[1],tonumber(mm[2]),mm[3]
            local idx = 1
            if string.find(ip,"wstf") then
                idx = 2
            end
            tList[idx][#tList[idx]+1]={ip=ip, port=port, iip = iip, fail = false,}
            -- list[j] = {ip=mm[1], port=tonumber(mm[2]), iip = mm[3], fail = false,}
        end
        for n=1,2 do
            if #tList[n] >= 1 then
                tempIpList[n][#tempIpList[n]+1] = tList[n]
            end
        end
        -- if #list >= 1 then
        --     g_ip_list[#g_ip_list+1] = list
        -- end
    end
    if #tempIpList[2] >= 1 and ymkj.taiJiShieldAction and not ios_checking and gt.getConf("is_use_tjd") ~= 0 then
        g_ip_list = tempIpList[2]
    else
        g_ip_list = tempIpList[1]
    end
    -- g_ip_list =  { { { fail = false, ip = "192.168.0.100", port = 6006 } } } -- 直接指定服务器ip与端口
    commonlib.echo(g_ip_list)

    -- WARN(g_ip_list)

    gt.saveLocalIp(json.encode(g_ip_list))

    gt.IpMgr:initIp()
    if not self.bUpdate and not g_is_new_update then
        self:checkUpdate(createResDownloadDir ~= nil)
    end
end

function LoginScene:onClientIpGetDaili(rtn_msg)
    -- log('【onClientIpGetDaili】')
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local ok1,p1 = pcall(string.find,rtn_msg,":")
    local ok2,p2 = pcall(string.find,rtn_msg,",")
    if not ok1 or not ok2 then
        gt.uploadErr(rtn_msg)
        return
    end
    -- WARN(rtn_msg)
    -- WARN(p1)
    -- WARN(p2)
    local str = string.sub(rtn_msg,p1+3,p2-2)
    g_client_ip = str
    -- WARN(str)
    return
end

function LoginScene:onClientIpGetTaobao(rtn_msg)
    -- log('【onClientIpGetTaobao】')
    if not rtn_msg or rtn_msg == "" then
        return
    end
    if string.find(rtn_msg,"html") then
        return
    end
    local ok,tab = pcall(json.decode,rtn_msg)
    if not ok then
        gt.uploadErr(rtn_msg)
        return
    end
    -- WARN(tab)
    local str = nil
    if tab and tab.code == 0 then
        str = tab.data.ip
    end
    g_client_ip = str
    return
end

function LoginScene:onGameConf(rtn_msg)
    -- log('【onGameConf】')
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local func = loadstring("return "..rtn_msg)
    local ret, gameconf = pcall(func)
    if ret and gameconf then
        gt.game_conf = gameconf
        gt.saveLocalGameConf(rtn_msg)
        -- dump(gameconf,"gameconf LoginScene")
    end
end

function LoginScene:onNetMsgError(rtn_msg)
    -- log('【onNetMsgError】')
    self:stopRepeat()

    if ios_checking or g_author_game then
        self:clearAccountPassword()
        self:startLogin()
    else
        if rtn_msg.msg == "该手机号还没有绑定玩家" then
            commonlib.showLocalTip("微信登录后，点击游戏大厅左上角玩家头像并进行手机绑定，才可使用此功能")
            LoginScene.account_code = false
            if self.dlPanel then
                self:showLoginPanel(true)
                self:showTipLable(false)
                self.tip_lbl:setString("")
            end
        else
            commonlib.showLocalTip(rtn_msg.msg, nil, -90)
            if not LoginScene.account_code then
                if rtn_msg.code == 1001 then
                    ios_checking = nil
                    self:clearAccountPassword()
                    if self.login_type == "xianliao" then
                        self:authByXianLiao()
                    elseif self.login_type == "qinliao" then
                        self:authByQinLiao()
                    else
                        ymkj.wxReq(1, "")
                    end
                elseif rtn_msg.code == 1002 or rtn_msg.code == 1003 then
                    self:clearAccountPassword()
                    if not is_test then
                        if self.login_type == "xianliao" then
                            self:authByXianLiao()
                        elseif self.login_type == "qinliao" then
                            self:authByQinLiao()
                        else
                            ymkj.wxReq(1, "")
                        end
                    else
                        self:startLogin()
                    end
                elseif rtn_msg.code == 1100 then
                    commonlib.showTipDlg("您的版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
                        ymkj.ymIM(100, "", "")
                    end)
                end
            else
                LoginScene.account_code = false
                if self.dlPanel then
                    self:showLoginPanel(true)
                    self:showTipLable(false)
                    self.tip_lbl:setString("")
                end
            end
        end
    end
end

function LoginScene:registerEventListener()
    local NETMSG_LISTENERS = {
        ["sdk_login"]               = handler(self, self.onSdkLogin),
        [NetCmd.S2C_LOGIN]          = handler(self, self.onRcvLogin),
        [NetCmd.S2C_REGISTER]       = handler(self, self.onRcvRegister),
        [NetCmd.S2C_RECONNECT]      = handler(self, self.onRcvReconnect),
        [NetCmd.S2C_SMS_GET_CODE]   = handler(self, self.onRcvGetcode),
    }
    for k, v in pairs(NETMSG_LISTENERS) do
        gt.addNetMsgListener(k, v)
    end
    local CUSTOM_LISTENERS = {
        ["connect_success"]      = handler(self, self.onConnectSuccess),
        ["ip_get"]               = handler(self, self.onIpGet),
        ["client_ip_get_daili"]  = handler(self, self.onClientIpGetDaili),
        ["client_ip_get_taobao"] = handler(self, self.onClientIpGetTaobao),
        ["game_conf"]            = handler(self, self.onGameConf),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function LoginScene:unregisterEventListener()
    local LISTENER_NAMES = {
        [NetCmd.S2C_LOGIN]          = handler(self, self.onRcvLogin),
        [NetCmd.S2C_REGISTER]       = handler(self, self.onRcvRegister),
        [NetCmd.S2C_RECONNECT]      = handler(self, self.onRcvReconnect),
        [NetCmd.S2C_SMS_GET_CODE]   = handler(self, self.onRcvGetcode),

        ["sdk_login"]            = handler(self, self.onSdkLogin),
        ["connect_success"]      = handler(self, self.onConnectSuccess),
        ["ip_get"]               = handler(self, self.onIpGet),
        ["client_ip_get_daili"]  = handler(self, self.onClientIpGetDaili),
        ["client_ip_get_taobao"] = handler(self, self.onClientIpGetTaobao),
        ["game_conf"]            = handler(self, self.onGameConf),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end

    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.listenerKeyboard)
    self.listenerKeyboard = nil
    self.account = nil
    self.password = nil
end

function LoginScene:updateIp(fail_reconnect)
    -- log('【updateIp】')
    local is_pre = nil
    if not fail_reconnect then--and g_os ~= "win" then
        local ipport = cc.UserDefault:getInstance():getStringForKey("ipportip", "")
        if ipport and ipport ~= "" then
            if g_os ~= "win" then
                ipport = ymkj.base64Decode(ymkj.base64Decode(ipport))
            end
            if ipport and ipport ~= "" then
                local pre = string.split(ipport, ":")
                if type(pre) == "table" and #pre == 2 then
                    g_ip_addr = pre[1]
                    g_port_no = tonumber(pre[2])
                    if g_ip_list and #g_ip_list >= 1 then
                        for __, v in ipairs(g_ip_list) do
                            for __, vv in ipairs(v) do
                               if (vv.ip == g_ip_addr or vv.iip == g_ip_addr) and vv.port == g_port_no then
                                    is_pre = true
                                    if not g_is_ipv6 then
                                        g_ip_addr = vv.iip or vv.ip
                                    else
                                        g_ip_addr = vv.ip or vv.iip
                                    end
                                    break
                               end
                            end
                            if is_pre then
                                break
                            end
                        end
                    end
                end
            end
        end
    else
        if not g_is_logined then
            if not g_is_ipv6 then
                g_is_ipv6 = true
                cc.UserDefault:getInstance():setStringForKey("ipv6", "1")
            else
                g_is_ipv6 = false
                cc.UserDefault:getInstance():setStringForKey("ipv6", "0")
            end
            cc.UserDefault:getInstance():flush()
        end
    end

    if not is_pre and g_ip_list and #g_ip_list >= 1 then
        local enable_ip_list = {}
        for __, v in ipairs(g_ip_list) do
            local list = {}
            for __, vv in ipairs(v) do
                if not vv.fail then
                    list[#list+1] = vv
                end
            end
            if #list >=1 then
                enable_ip_list[#enable_ip_list+1] = list
            end
        end

        local ip_port = nil
        if #enable_ip_list >= 1 then
            local comb = nil
            for i, v in ipairs(enable_ip_list) do
                for j, vv in ipairs(v) do
                    if (vv.ip == g_ip_addr or vv.iip == g_ip_addr) and vv.port == g_port_no then
                        comb = i
                        break
                    end
                end
                if comb then
                    break
                end
            end
            local comb_ip = enable_ip_list[comb or math.random(1, #enable_ip_list)]
            ip_port = comb_ip[math.random(1, #comb_ip)]
        else
            local comb_ip = g_ip_list[math.random(1, #g_ip_list)]
            ip_port = comb_ip[math.random(1, #comb_ip)]
        end
        if ip_port then
            if not g_is_ipv6 then
                g_ip_addr = ip_port.iip or ip_port.ip
            else
                g_ip_addr = ip_port.ip or ip_port.iip
            end
            g_port_no = ip_port.port
        end
    end
    if g_ip_qf then
        g_ip_addr = g_ip_qf.ip
        g_port_no = g_ip_qf.port
        g_ip_qf = nil
    end

    if ymkj.GlobalData:getInstance().setIpPort then
        ymkj.GlobalData:getInstance():setIpPort(g_ip_addr, g_port_no)
    end
end

function LoginScene:saveAccountPassword(account, password, server_time, expires_time)
    -- log('【saveAccountPassword】')
    if account and account ~= "" and password and password ~= "" and (is_test
         or (server_time and server_time ~="" and expires_time and expires_time ~="")) then
        if g_os == "win" then
            cc.UserDefault:getInstance():setStringForKey("mmmx1", account)
            cc.UserDefault:getInstance():setStringForKey("mmmx2", password)
        else
            cc.UserDefault:getInstance():setStringForKey("mmmx1", ymkj.base64Encode(account))
            cc.UserDefault:getInstance():setStringForKey("mmmx2", ymkj.base64Encode(password))
        end
        cc.UserDefault:getInstance():setStringForKey("s1s1s1", server_time)
        cc.UserDefault:getInstance():setStringForKey("s2s2s2", expires_time)
        cc.UserDefault:getInstance():flush()
    end
end

function LoginScene:clearAccountPassword()
    -- log('【clearAccountPassword】')
    cc.UserDefault:getInstance():setStringForKey("mmmx1", "")
    cc.UserDefault:getInstance():setStringForKey("mmmx2", "")
    cc.UserDefault:getInstance():setStringForKey("s1s1s1", "")
    cc.UserDefault:getInstance():setStringForKey("s2s2s2", "")
    cc.UserDefault:getInstance():flush()
    self.account = nil
    self.password = nil
end

function LoginScene:initAccountPassword()
    -- log('【initAccountPassword】')
    local server_time = cc.UserDefault:getInstance():getStringForKey("s1s1s1", "")
    local expires_time = cc.UserDefault:getInstance():getStringForKey("s2s2s2","")
    if is_test or (server_time and server_time ~="" and expires_time and expires_time ~= "") then
        if not is_test and (not g_is_logined) and tonumber(expires_time) <= tonumber(server_time) then
            self:clearAccountPassword()
        else
            local account = cc.UserDefault:getInstance():getStringForKey("mmmx1")
            local password = cc.UserDefault:getInstance():getStringForKey("mmmx2")
            if account and account ~= "" then
                if g_os == "win" then
                    self.account = account
                else
                    self.account = ymkj.base64Decode(account)
                end
            end
            if password and password ~= "" then
                if g_os == "win" then
                    self.password = password
                else
                    self.password = ymkj.base64Decode(password)
                end
            end
        end
    end
    g_is_ipv6 = tonumber(cc.UserDefault:getInstance():getStringForKey("ipv6","0"))
    if g_is_ipv6 == 0 then
        g_is_ipv6 = nil
    else
        g_is_ipv6 = true
    end
end

function LoginScene:startLogin()
    -- logUp('【startLogin】')
    -- log('【startLogin】')
    if not self.sendByPhone then
        self:showLoginPanel(false)
    end

    local base = (g_is_multi_wechat and 3 or 2)
    if not g_base_ver or g_base_ver < base then
        commonlib.showTipDlg("您的游戏版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
             ymkj.ymIM(100, "", "")
        end)
        return
    end

    if self.has_agreen ~= "1" and not ios_checking then
        commonlib.showTipDlg("请确认并同意用户协议", function()
            if self.dlPanel then
                self:showLoginPanel(true)
            end
        end)
        return
    end
    self:sendLogin()
end

function LoginScene:sendLogin()
    -- log('【sendLogin】')
    if not g_author_game and not ios_checking and self.account and string.find(self.account, "ios") ~= nil then
        self:clearAccountPassword()
    end
    if (not self.wx_code) and (not LoginScene.account_code) and (self.account==nil or self.password==nil) and (not is_test) and (not self.sendByPhone) and (not self.loginByPhone) and (not self.loginByUid) then
        if self.login_type == "xianliao" then
            self:authByXianLiao()
        elseif self.login_type == "qinliao" then
            self:authByQinLiao()
        else
            ymkj.wxReq(1, "")
        end
        self:showLoginPanel(true)
        return
    end
    self.account = yy_account or self.account
    self.password = yy_password or self.password

    if not self.is_connect then
        -- log('【connect】')
        if self.dlPanel and not self.sendByPhone then
            self:showTipLable(true)
            self.tip_lbl:setString("连接中...")
        end
        self:updateIp()
        self:waitConnecnt(1.5)
        ymkj.SendData:connect(g_ip_addr, g_port_no)
        return
    end
    if self.sendByPhone then
        local input_msg = {
            cmd = NetCmd.C2S_SMS_GET_CODE,
            account = "",
            phoneNumber = self.inputPhoneNum,
            type = 2,
        }
        ymkj.SendData:send(json.encode(input_msg))
        self.sendByPhone = nil
    elseif self.loginByPhone then
        local input_msg = {
            cmd = NetCmd.C2S_LOGIN,
            phoneNumber = self.inputPhoneNum or tostring(self.phone),
            account = "",
        }
        local str,cmdCode = json.encode(input_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)

        if self.dlPanel then
            self:showTipLable(true)
            self.tip_lbl:setString("登陆中...")
        end

        self.loginByPhone = nil
    elseif self.loginByUid then
        local input_msg = {
            cmd = NetCmd.C2S_LOGIN,
            uid = self.uid,
            password = self.password,
            account = "",
        }
        local str,cmdCode = json.encode(input_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)

        if self.dlPanel then
            self:showTipLable(true)
            self.tip_lbl:setString("登陆中...")
        end

        self.loginByUid = nil
    elseif self.wx_code then
        local sInfo = self.secondInfo or {}
        local sPack = sInfo.pack or loginToPack[self.login_type]
        local lon_lat_str = "0;0"
        if not ios_checking then
            lon_lat_str = ymkj.baseInfo(6)
        end
        local lon_lat = string.split(lon_lat_str, ";")
        local mutil_wx_login = self:getMutilWxParam()
        local input_msg = {
            cmd = NetCmd.C2S_LOGIN,
            code= self.wx_code,
            channel = loginToChannel[self.login_type],
            account = "",
            mac = g_mac_addr,
            lat = lon_lat[1],
            lon = lon_lat[2],
            ver = g_version,
            os = g_os,

            is_mutil_wechat = mutil_wx_login,
            appId = sInfo.appId ,
            pack = sPack,
            firstAccount = sInfo.firstAccount,
            loginTime = sInfo.loginTime or 1,

            ip = g_client_ip,
        }
        local str,cmdCode = json.encode(input_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)

        if self.dlPanel then
            self:showTipLable(true)
            self.tip_lbl:setString("登陆中...")
        end
        self.wx_code = nil
    elseif LoginScene.account_code then
         --绑定账号密码外网暂时未开放
        local lon_lat_str = "0;0"
        if not ios_checking then
           lon_lat_str = ymkj.baseInfo(6)
        end
        local lon_lat = string.split(lon_lat_str, ";")
        local sInfo = self.secondInfo or {}
        local sPack = sInfo.pack or loginToPack[self.login_type]
        local input_msg = {
            cmd = NetCmd.C2S_LOGIN,
            account= LoginScene.account_code.account,
            password= LoginScene.account_code.password,
            pack = sPack,
            mac = g_mac_addr,
            lat = lon_lat[1],
            lon = lon_lat[2],
            ver = g_version,
            channel = "self",
            os = g_os,
            ip = g_client_ip,
        }
        local str,cmdCode = json.encode(input_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)
        if self.dlPanel then
            self:showTipLable(true)
            self.tip_lbl:setString("登陆中...")
        end
    elseif self.account and self.password then
        -- log('【login】')
        local lon_lat_str = "0;0"
        if not ios_checking then
           lon_lat_str = ymkj.baseInfo(6)
        end
        local lon_lat = string.split(lon_lat_str, ";")
        local sInfo = self.secondInfo or {}
        local sPack = sInfo.pack or loginToPack[self.login_type]
        local mutil_wx_login = self:getMutilWxParam()
        local input_msg = {
            cmd = NetCmd.C2S_LOGIN,
            account= self.account,
            password=self.password,
            pack = sPack,
            mac = g_mac_addr,
            lat = lon_lat[1],
            lon = lon_lat[2],
            ver = g_version,
            os = g_os,
            is_mutil_wechat = mutil_wx_login,
            loginTime = 1,--仅仅为了保持服务端逻辑一致性

            ip = g_client_ip,
        }
        -- 登陆
        local str,cmdCode = json.encode(input_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)
        if self.dlPanel then
            self:showTipLable(true)
            self.tip_lbl:setString("登陆中...")
        end
    else
        if not is_test and not g_author_game then
            if self.login_type == "xianliao" then
                self:authByXianLiao()
            elseif self.login_type == "qinliao" then
                self:authByQinLiao()
            else
                ymkj.wxReq(1, "")
            end
        else
            local lon_lat_str = "0;0"
            if not ios_checking then
               lon_lat_str = ymkj.baseInfo(6)
            end
            local lon_lat = string.split(lon_lat_str, ";")
            self.account = g_os..math.random(100, 9999)
            self.password = "123456"
            local input_msg = {
                cmd = NetCmd.C2S_REGISTER,
                account= self.account,
                password=self.password,
                pack=g_game_pack,
                mac =g_mac_addr,
                lat = lon_lat[1],
                lon = lon_lat[2],
                ver = g_version,
                os = g_os,
            }
            ymkj.SendData:send(json.encode(input_msg))

            if self.dlPanel then
                self:showTipLable(true)
                self.tip_lbl:setString("登陆中...")
            end
        end
    end
end

function LoginScene:startRepeat(msg, cishu)
    -- self.repeat_msg = msg
    self:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.CallFunc:create(function()
        -- if self.repeat_msg  then
        --     if cishu == 0 then
                self:checkRepeat(cishu or 0)

                -- commonlib.showLoading(nil, function()
                --     commonlib.showTipDlg("网络超时\n检查网络重新打开再试，点击“确定”", function(is_ok)
                --         if is_ok then
                --             -- ymkj.SendData:send(self.repeat_msg)
                --             -- self:startRepeat(self.repeat_msg, 0)
                --             cc.Director:getInstance():endToLua()
                --         else
                --             cc.Director:getInstance():endToLua()
                --         end
                --     end)
                -- end)

        --     end
        --     ymkj.SendData:send(self.repeat_msg)
        --     if cishu < 4 then
        --         self:startRepeat(self.repeat_msg, cishu+1)
        --     end
        -- end
    end)))
end

function LoginScene:stopRepeat()
    -- self.repeat_msg = nil
    self:stopAllActions()
    commonlib.showLoading(true)
end

function LoginScene:checkRepeat(cishu)
    if cishu >= 5 then
        commonlib.showTipDlg("网络超时\n检查网络重新打开再试，点击“确定”", function(__)
            cc.Director:getInstance():endToLua()
        end)
    else
        cishu = cishu+1
        commonlib.showLoading(nil, function()
            self:checkRepeat(cishu)
        end)
    end
end

function LoginScene:authByXianLiao()
    local NativeUtil = require("common.NativeUtil")
    NativeUtil:loginThird({
        typ = "xianliao",
        state = "" .. os.time(),
        classId = function(ret)
            -- dump(ret,"authByXianLiao")
            if tonumber(ret.code) == 0 and ret.authcode then
                self.wx_code = ret.authcode
                self:showLoginPanel(false)
                self:startLogin()
            elseif tonumber(ret.code) == -1 then
                NativeUtil:dowloadOtherTip("xianliao")
            end
        end
    })
end

function LoginScene:authByQinLiao()
    local NativeUtil = require("common.NativeUtil")
    NativeUtil:loginThird({
        typ = "qinliao",
        classId = function(ret)
            dump(ret,"authByXianLiao")
            if tonumber(ret.code) == 0 then
                if ret.authcode and ret.authcode ~= "" then
                    self.wx_code = ret.authcode
                    self:showLoginPanel(false)
                    self:startLogin()
                end
            elseif tonumber(ret.code) == -1 then
                NativeUtil:dowloadOtherTip("qinliao")
            end
        end
    })
end

function LoginScene:createLayerMenu()
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, ZOrder.GRID)
    end

    commonlib.showLoading(true)
    if ios_checking then
        is_test = true
        cc.UserDefault:getInstance():setStringForKey("agreen", "1")
    end

    local node = tolua.cast(cc.CSLoader:createNode("ui/denglu"..(g_author_game==nil and "" or "_author")..".csb"),"ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)

	if g_author_game then
        ccui.Helper:seekWidgetByName(node, "Image_1"):loadTexture("ui/qj_majiang/dt/image_logo"..g_author_game..".png")
	end

    self.has_agreen = cc.UserDefault:getInstance():getStringForKey("agreen", "2")
    self.login_type = cc.UserDefault:getInstance():getStringForKey("login_type", "wechat")

    if ios_checking then
        local zbq = ccui.Helper:seekWidgetByName(node, "Image_1")
        if zbq then
            zbq:loadTexture("ui/qj_login/LOGO-appstore.png")
        end
    end

    local UpdateVersion = cc.UserDefault:getInstance():getStringForKey("UpdateVersion","1.0.0")
    local version = "版本号 res:" .. UpdateVersion
    local str = string.format( version)
    local lbInfo = ccui.Helper:seekWidgetByName(node, "lbInfo")
    lbInfo:setString(str)
    local debugDialogClickCount = 0
    local lbGameTipClickCount = 0
    lbInfo:addOnClick(function()
        debugDialogClickCount = debugDialogClickCount + 1
        if g_os == "win" or (debugDialogClickCount == 5 and lbGameTipClickCount == 2) then
            local DebugDialog = require("scene.kit.DebugDialog")
            local debugDialog = DebugDialog:create(self)
            self:addChild(debugDialog, ZOrder.DIALOG)
        end
    end)

    local lbGameTip = node:seekNode("Image_3")
    lbGameTip:addOnClick(function()
        lbGameTipClickCount = lbGameTipClickCount + 1
    end)

    self.tip_lbl = cc.LabelTTF:create("初始化中...", "STHeitiSC-Medium", 30)
    if g_is_new_update then
        self.tip_lbl:setString("")
    end
    self.tip_lbl:setHorizontalAlignment(1)
    self.tip_lbl:setColor(cc.c3b(255,255,255))
    self.tip_lbl:setPosition(cc.p(g_visible_size.width/2, 110))
    self:addChild(self.tip_lbl, ZOrder.TIP)

    self.dlPanel = ccui.Helper:seekWidgetByName(node, "dlPanel")
    self.wxBtn = ccui.Helper:seekWidgetByName(self.dlPanel, "bt_WXlogin")
    self.xlBtn = ccui.Helper:seekWidgetByName(self.dlPanel, "bt_XLlogin")
    self.wlBtn = ccui.Helper:seekWidgetByName(self.dlPanel, "bt_WLlogin")
    self.phoneBtn = ccui.Helper:seekWidgetByName(self.dlPanel, "bt_Phonelogin")
    self.phone = cc.UserDefault:getInstance():getStringForKey("bindphone","0")
    if self.phoneBtn then
        self.phoneBtn:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended and not self.gone then
                AudioManager:playPressSound()
                self:phoneLogin()
            end
        end)
    end
    if ios_checking then
        self.wxBtn:setPositionX(self.wxBtn:getPositionX()-170)
        self.phoneBtn:setVisible(false)
    end
    self.wxBtn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended and not self.gone then
            AudioManager:playPressSound()
            self:wxLogin()
        end
    end)

    self.xlBtn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended and not self.gone then
            AudioManager:playPressSound()
            self:xlLogin()
        end
    end)

    self.wlBtn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended and not self.gone then
            AudioManager:playPressSound()
            self:wlLogin()
        end
    end)

    local agreen_opt = ccui.Helper:seekWidgetByName(node, "gouImg")
    agreen_opt:setTouchEnabled(true)
    agreen_opt:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.has_agreen ~= "1" then
                self.has_agreen = "1"
                agreen_opt:loadTexture("ui/qj_login/k1.png")
            else
                self.has_agreen = "0"
                agreen_opt:loadTexture("ui/qj_login/k.png")
            end
            cc.UserDefault:getInstance():setStringForKey("agreen", self.has_agreen)
            cc.UserDefault:getInstance():flush()
        end
    end)

    local function popAgree()
        local csb = DTUI.getInstance().csb_agree
        local xiaoxi = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
        self:addChild(xiaoxi, ZOrder.DIALOG)
        xiaoxi:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
        ccui.Helper:doLayout(xiaoxi)

        ccui.Helper:seekWidgetByName(xiaoxi,"btn-exit"):addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                xiaoxi:removeFromParent(true)
            end
        end)

        ccui.Helper:seekWidgetByName(xiaoxi,"btn-zh"):addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.has_agreen = "1"
                agreen_opt:loadTexture("ui/qj_login/k1.png")
                cc.UserDefault:getInstance():setStringForKey("agreen", self.has_agreen)
                cc.UserDefault:getInstance():flush()
                xiaoxi:removeFromParent(true)
            end
        end)

        local ScrollView_1 = ccui.Helper:seekWidgetByName(xiaoxi,"ScrollView_1")
        ScrollView_1:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.began and ScrollView_1.isAdd == nil then
                ScrollView_1.isAdd = true
                local XieYi = require("common.XieYi")
                for i=1,7 do
                    local neirong = ccui.Helper:seekWidgetByName(xiaoxi,"neirong" .. i)
                    neirong:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function()
                        neirong:setString(XieYi["neirong" .. i])
                    end)))
                end
            end
        end)
        if ios_checking then
            local XieYi = require("common.XieYi")
            local neirong = ccui.Helper:seekWidgetByName(xiaoxi,"neirong" .. 0)
            neirong:setString(XieYi["neirong" .. 0])
        end
    end

    local agreen_btn = ccui.Helper:seekWidgetByName(node, "protoPanel")
    agreen_btn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            popAgree()
        end
    end)

    if self.has_agreen == "1" then
        agreen_opt:loadTexture("ui/qj_login/k1.png")
    else
        agreen_opt:loadTexture("ui/qj_login/k.png")
    end

    if self.has_agreen == "2" and not ios_checking then
        local a = cc.CallFunc:create(function()
            popAgree()
        end)
        self:runAction(a)
    end
    if not g_is_new_update then
        self:showLoginPanel(false)
    end
    self:initAccountPassword()
end

function LoginScene:showTipLable(b)
    if self.tip_lbl then
        self.tip_lbl:setVisible(b)
    end
end

function LoginScene:phoneLogin()
    require "scene.DTUI"
    local csb = DTUI.getInstance().csb_bindphone_dialog
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local phoneNumInput = ccui.Helper:seekWidgetByName(node,"ePhoneNum")
    local code = ccui.Helper:seekWidgetByName(node,"eCode")
    local login = ccui.Helper:seekWidgetByName(node,"btLogin")
    self.sendBtn = ccui.Helper:seekWidgetByName(node,"btSend")
    local title = ccui.Helper:seekWidgetByName(node,"title")
    local imgBind = ccui.Helper:seekWidgetByName(node,"imgBind")
    ccui.Helper:seekWidgetByName(node,"btBind"):setVisible(false)
    title:loadTexture("ui/qj_userInfo/phoneloginTitle.png")
    if self.phone ~= '0' then
        phoneNumInput:setString(self.phone)
    end
    self.djs = ccui.Helper:seekWidgetByName(node, "djs")
    self.send = ccui.Helper:seekWidgetByName(node, "imgSend")
    self.send:setVisible(false)
    self.djs:setVisible(false)
    local time = cc.UserDefault:getInstance():getStringForKey("start_time_fromlogin","0")
    time = tonumber(time)
    if os.time() - time >= 60 then
        time = nil
    else
        self:Countdown(60-(os.time() - time))
    end
    ccui.Helper:seekWidgetByName(node,"btExit"):addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    self.sendBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local phonenum = phoneNumInput:getString()
                if(string.len(phonenum) <= 0 ) then
                    commonlib.showLocalTip("手机号码不能为空")
                    return
                end

                if(string.len(phonenum) ~= 11 or string.match(phonenum,"[1]%d%d%d%d%d%d%d%d%d%d") ~= phonenum) then
                    commonlib.showLocalTip("您输入的手机号码错误，请重新输入")
                    phoneNumInput:setString("")
                    return
                end
                self.inputPhoneNum = tonumber(phonenum)
                self.sendByPhone = true

                self:sendLogin()

                cc.UserDefault:getInstance():setStringForKey("start_time_fromlogin", tostring(os.time()))
                cc.UserDefault:getInstance():flush()
                self:Countdown(59)
            end
        end
    )

    login:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if code:getString() == "" then
                    commonlib.showLocalTip("输入的验证码不能为空！")
                    return
                end
                if self.code and tonumber(code:getString()) == self.code then
                    LoginScene.account_code = nil
                    self.login_type = "phone"
                    cc.UserDefault:getInstance():setStringForKey("login_type", "phone")
                    cc.UserDefault:getInstance():flush()
                    node:removeFromParent(true)
                    self.dlPanel:setVisible(false)
                    self.dlPanel:setEnabled(false)
                    self.loginByPhone = true
                    self:startLogin()
                else
                    commonlib.showLocalTip("验证码输入不正确,请重新进行输入!")
                    code:setString("")
                end
            end
        end
    )
end

--倒计时动画
function LoginScene:Countdown(time)
    self.djs.time = time
    self.djs:setString("("..self.djs.time..")")
    self.sendBtn:setTouchEnabled(false)
    self.sendBtn:setBright(false)
    self.djs:setVisible(true)
    self.send:setVisible(true)
    self.djs:runAction(cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        self.djs.time = math.max(self.djs.time -1, 0)
        self.djs:setString("("..self.djs.time..")")
            if self.djs.time <= 0 then
                self.sendBtn:setTouchEnabled(true)
                self.sendBtn:setBright(true)
                self.djs:setVisible(false)
                self.send:setVisible(false)
                self.djs:stopAllActions()
            end
        end)), self.djs.time))
end

function LoginScene:showLoginPanel(b)
    if self.dlPanel then
        self.dlPanel:setVisible(b)
        self.dlPanel:setEnabled(b)
    end
end

function LoginScene:createLayerMain(room_msg)
    commonlib.showLoading(true)
    if ios_checking then
        is_test = true
    end
    self.has_agreen = cc.UserDefault:getInstance():getStringForKey("agreen", "1")
    self.login_type = cc.UserDefault:getInstance():getStringForKey("login_type", "wechat")
    local pb_node = ccui.Layout:create()
    pb_node:setTouchEnabled(true)
    pb_node:setContentSize(g_visible_size)
    self:addChild(pb_node)
    self:initAccountPassword()
    self.room_msg = room_msg

    if not self.room_msg.service then
        -- 创建房间
        local net_msg = {
            cmd =NetCmd.C2S_GAME_ROOM_SERVER,
        }
        if self.room_msg.cmd == NetCmd.C2S_JOIN_ROOM then
            net_msg.room_id = self.room_msg.room_id
            net_msg.ip=g_ip_addr..":"..g_port_no
        else
            net_msg.ip=g_ip_addr..":"..g_port_no
            local is_vip = false
            for __, v in ipairs(self.room_msg) do
                if v.qunzhu == 1 then
                    is_vip = true
                    break
                end
            end
            net_msg.is_vip=is_vip
        end
        local str,cmdCode = json.encode(net_msg)
        ymkj.SendData:send(str,cmdCode)
        self:startRepeat(str, 0)
    else
        local rtn_m = string.split(self.room_msg.service, ":")
        self.ip = rtn_m[1]
        self.port = tonumber(rtn_m[2])

        local comb1 = nil
        local comb2 = nil
        if g_ip_list and #g_ip_list >= 1 then
            for i, v in ipairs(g_ip_list) do
                for __, vv in ipairs(v) do
                    if vv.ip == self.ip and vv.port == self.port then
                        comb1 = comb1 or i
                    end
                    if vv.ip ==g_ip_addr and vv.port == g_port_no then
                        comb2 = comb2 or i
                    end
                    if comb1 and comb2 then
                        break
                    end
                end
                if comb1 and comb2 then
                    break
                end
            end
        end

        if (comb1 ~= nil and comb1 == comb2) or (self.ip == g_ip_addr and self.port == g_port_no) then
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function()
                self:removeFromParent(true)
            end)))
        else
            self:waitConnecnt(1.5)
            if g_os == "win" then
                ymkj.SendData:send("duankai")
                g_ip_qf = {ip=self.ip, port=self.port}
            else
                ymkj.SendData:connect(self.ip, self.port)
            end
        end
    end
end

function LoginScene:wxLogin()
    LoginScene.account_code = nil
    self.loginByPhone = nil
    self.sendByPhone = nil
    self.code = nil
    self.login_type = "wechat"
    cc.UserDefault:getInstance():setStringForKey("login_type", "wechat")
    cc.UserDefault:getInstance():flush()
    self:startLogin()
end

function LoginScene:xlLogin()
    local NativeUtil = require("common.NativeUtil")
    local ret = NativeUtil:isInstallThird({typ="xianliao"})
    if ret == 1 then
        LoginScene.account_code = nil
        self.loginByPhone = nil
        self.sendByPhone = nil
        self.code = nil
        self.login_type = "xianliao"
        cc.UserDefault:getInstance():setStringForKey("login_type", "xianliao")
        cc.UserDefault:getInstance():flush()
        self:startLogin()
    else
        NativeUtil:dowloadOtherTip("xianliao")
    end
end

function LoginScene:wlLogin()
    local NativeUtil = require("common.NativeUtil")
    LoginScene.account_code = nil
    self.loginByPhone = nil
    self.sendByPhone = nil
    self.code = nil
    self.login_type = "qinliao"
    cc.UserDefault:getInstance():setStringForKey("login_type", "qinliao")
    cc.UserDefault:getInstance():flush()
    self:startLogin()
end

function LoginScene:createLayerReconnect()
    -- logUp('LoginScene:createLayerReconnect')
    commonlib.showLoading(true)
    if ios_checking then
        is_test = true
    end

    self.has_agreen = cc.UserDefault:getInstance():getStringForKey("agreen", "1")
    self.login_type = cc.UserDefault:getInstance():getStringForKey("login_type", "wechat")
    self:initAccountPassword()
end

-- 判断是否为新玩家
function LoginScene:isNewPlayer()
    local account = gt.getLocalString("mmmx1")
    local password = gt.getLocalString("mmmx2")
    -- 用来判断新老用户（账密不存在或为空即为新用户）
    if account and account ~= "" and password and password ~= "" then
        return false
    else
        return true
    end
end

return LoginScene

