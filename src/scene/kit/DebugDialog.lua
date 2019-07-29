--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2019-06-27
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2019-06-27
-- @Desc: 调试设置对话框
--------------------------------------------------------------------------------
require('scene.DTUI')

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

local DebugDialog = class("DebugDialog", function()
    return gt.createMaskLayer()
end)

function DebugDialog:ctor(loginScene)
    self.loginScene = loginScene

    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end
    local csb = DTUI.getInstance().csb_debug
    self:addCSNode(csb)
    -- self:printNode()

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end, true)

    for k, v in pairs(BT_SERVERS) do
        self[k] = self:addBtListener(k, function()
            AudioManager:playPressSound()
            self:refreshBtServer(k)
        end)
    end
    self:refreshBtServer(gt.getLocalString("debug_server", "btOnline"))

    self.tUid = self:seekNode("tUid")
    self.tUid:onEvent(function(event)
        if event.name == "DETACH_WITH_IME" then
            log(self.tUid:getString())
        end
    end)

    self.tPassword = self:seekNode("tPassword")
    self.tPassword:setPasswordEnabled(true)
    self.tPassword:onEvent(function(event)
        if event.name == "DETACH_WITH_IME" then
            log(self.tPassword:getString())
        end
    end)
    self:addBtListener("btLogin", function()
        local uid = self.tUid:getString()
        local password = self.tPassword:getString()
        if (not uid or uid == "") or (not password or password == "") then
            gt.floatText("请输出玩家id和密码")
            return
        end
        self.loginScene.loginByUid = true
        self.loginScene.uid = self.tUid:getString()
        self.loginScene.password = self.tPassword:getString()
        self.loginScene:startLogin()
    end)

    self.tReplayCode = self:seekNode("tReplayCode")
    self.tReplayCode:onEvent(function(event)
        if event.name == "DETACH_WITH_IME" then
            log(self.tReplayCode:getString())
        end
    end)

    self:addBtListener("btClearData", function()
        AudioManager:playPressSound()
        cc.FileUtils:getInstance():removeFile(cc.UserDefault:getXMLFilePath())
    end)
    self:addBtListener("btClearRes", function()
        AudioManager:playPressSound()
        local pathToSave = createDownloadDir()
        cc.FileUtils:getInstance():removeDirectory(pathToSave.."/")
        pathToSave = createResDownloadDir()
        cc.FileUtils:getInstance():removeDirectory(pathToSave.."/")
    end)

    self.btLog = self:seekNode("btLog")
    self:refreshBtLog()
    self.btLog:addClickEventListener(function()
        AudioManager:playPressSound()
        self:refreshBtLog(true)
    end)

    self.btSpine = self:seekNode("btSpine")
    self:refreshBtSpine()
    self.btSpine:addClickEventListener(function()
        AudioManager:playPressSound()
        self:refreshBtSpine(true)
    end)
end

function DebugDialog:refreshBtLog(isToggle)
    local isOn = gt.getLocalBool("debug_log", false)
    if isToggle then
        isOn = not isOn
    end
    if isOn then
        self.btLog:loadTextureNormal("ui/qj_setting/dt_setting_btn_kai.png")
        self.btLog:loadTexturePressed("ui/qj_setting/dt_setting_btn.png")
        gt.setLocalBool("debug_log", isOn, true)
    else
        self.btLog:loadTextureNormal("ui/qj_setting/dt_setting_btn.png")
        self.btLog:loadTexturePressed("ui/qj_setting/dt_setting_btn_kai.png")
        gt.setLocalBool("debug_log", isOn, true)
    end
end

function DebugDialog:refreshBtSpine(isToggle)
    local isOn = gt.getLocalBool("debug_spine", false)
    if isToggle then
        isOn = not isOn
    end
    g_close_main_ani = not isOn
    if isOn then
        self.btSpine:loadTextureNormal("ui/qj_setting/dt_setting_btn_kai.png")
        self.btSpine:loadTexturePressed("ui/qj_setting/dt_setting_btn.png")
        gt.setLocalBool("debug_spine", isOn, true)
    else
        self.btSpine:loadTextureNormal("ui/qj_setting/dt_setting_btn.png")
        self.btSpine:loadTexturePressed("ui/qj_setting/dt_setting_btn_kai.png")
        gt.setLocalBool("debug_spine", isOn, true)
    end
end

function DebugDialog:refreshBtServer(btServer)
    for k, v in pairs(BT_SERVERS) do
        if k == btServer then
            self[k]:loadTextureNormal("ui/qj_setting/speedBtn_select.png")
            self[k]:loadTexturePressed("ui/qj_setting/speedBtn_normal.png")
            gt.setLocalString("debug_server", k, true)
            yy_ip_url = v
            g_ip_url = yy_ip_url or g_ip_url
            ymkj.UrlPool:instance():reqHttpGet("ip_get", g_ip_url)
        else
            self[k]:loadTextureNormal("ui/qj_setting/speedBtn_normal.png")
            self[k]:loadTexturePressed("ui/qj_setting/speedBtn_select.png")
        end
    end
end

function DebugDialog:inputUid()
    local node = self:addCSNode("ui/DT_JoinroomLayer.csb")
    node:addBtListener("btExit", function(sender, eventType)
        AudioManager:playPressSound()
        node:removeFromParent(true)
    end)

    local number     = 0
    local number_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "tRoomID"), "ccui.Text")
    number_lbl:setString("请输入玩家id")
    local inputNum = 0

    for i = 0, 9 do
        ccui.Helper:seekWidgetByName(node, string.format("%d", i)):addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    number = number * 10 + i
                    number_lbl:setString(number)
                    inputNum = inputNum + 1
                    if number >= 10000000000 then
                        number   = 0
                        inputNum = 0
                        commonlib.showLocalTip("输入不能超过10位数")
                        number_lbl:setString("请输入回放码")
                    end
                end
            end)
    end

    ccui.Helper:seekWidgetByName(node, "btReinput"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            number   = 0
            inputNum = 0
            number_lbl:setString("请输入回放码")
        end
    end)

    ccui.Helper:seekWidgetByName(node, "btOk"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            -- number = number_lbl:getString()
            if number == 0 then
                return
            end

            local net_msg = {
                cmd = NetCmd.C2S_LOGDATA,
                id  = number,
            }
            ymkj.SendData:send(json.encode(net_msg))

            GameGlobal.ZjLayerMain         = true
            GameGlobal.ZjLayerMainMsg      = nil
            GameGlobal.ZjLayerMainMsgCurJu = nil
        end
    end)
    ccui.Helper:seekWidgetByName(node, "btDel"):setVisible(false)
end

return DebugDialog