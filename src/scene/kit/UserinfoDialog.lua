require('scene.DTUI')

local cmd_list = {
    NetCmd.S2C_SMS_GET_CODE,
    NetCmd.S2C_SMS_BIND,
    NetCmd.S2C_SYNC_USER_DATA,
    NetCmd.S2C_BIND_APPID,
}

local UserinfoDialog = class("UserinfoDialog", function()
    return gt.createMaskLayer()
end)

function UserinfoDialog:ctor()
    self:createLayerMenu()
    self:enableNodeEvents()
end

function UserinfoDialog:onEnter()
    self:registerEventListener()
end

function UserinfoDialog:onExit()
    self:unregisterEventListener()
end

function UserinfoDialog:registerEventListener()
    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        local rtn_msg    = custom_event:getUserData()
        rtn_msg          = json.decode(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_SMS_GET_CODE then
            if rtn_msg.errno and rtn_msg.errno == 1 then
                commonlib.showLocalTip("此手机已被绑定，请重新输入！")
                self.phoneNumInput:setString("")
                return
            end
            if rtn_msg.code then
                self.code = rtn_msg.code
            else
                commonlib.showLocalTip("获取验证码失败！")
                return
            end
            cc.UserDefault:getInstance():setStringForKey("start_time_frombind", tostring(os.time()))
            cc.UserDefault:getInstance():flush()
            self:CountDown(59)
        elseif rtn_msg.cmd == NetCmd.S2C_SMS_BIND then
            commonlib.showLocalTip("绑定成功！")
            self.phoneNum:setString(self.phone)
            self.imgBind:loadTexture("ui/qj_userInfo/changeBind.png")
            self.bind:removeFromParent(true)
        elseif rtn_msg.cmd == NetCmd.S2C_SYNC_USER_DATA then
            if rtn_msg.key == "phone" then
                cc.UserDefault:getInstance():setStringForKey("bindphone", tostring(rtn_msg.value))
                cc.UserDefault:getInstance():flush()
            end
        elseif rtn_msg.cmd == NetCmd.S2C_BIND_APPID then
            if rtn_msg.errno == 0 then
                if rtn_msg.pack == "ylqj_xl_1" then
                    commonlib.showLocalTip("绑定闲聊成功，获得房卡x" .. (rtn_msg.card or 0))
                    cc.UserDefault:getInstance():setStringForKey("isAwardedXL", "YES")
                    cc.UserDefault:getInstance():flush()
                    self:refreshBind()
                elseif rtn_msg.pack == "ylqj_ql_1" then
                    commonlib.showLocalTip("绑定亲聊成功，获得房卡x" .. (rtn_msg.card or 0))
                    cc.UserDefault:getInstance():setStringForKey("isAwardedQL", "YES")
                    cc.UserDefault:getInstance():flush()
                    self:refreshBind()
                end
            else
                if rtn_msg.msg then
                    commonlib.showLocalTip(rtn_msg.msg)
                end
            end
        end
    end

    for _, v in pairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function UserinfoDialog:unregisterEventListener()
    for _, v in pairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function UserinfoDialog:refreshBind()
    local imgBindXianl = self:seekNode("imgBindXianl")
    local btn_xianl    = self:seekNode("btn_xianl")
    local isAwardedXL  = cc.UserDefault:getInstance():getStringForKey("isAwardedXL", "NO")
    if isAwardedXL == "YES" then
        imgBindXianl:setVisible(true)
        btn_xianl:setVisible(false)
    end
    local btn_qinl  = self:seekNode("btnBindwl")
    local imgBindQl = self:seekNode("imgBindwl")
    local isAwardedQL  = cc.UserDefault:getInstance():getStringForKey("isAwardedQL", "NO")
    if isAwardedQL == "YES" then
        imgBindQl:setVisible(true)
        btn_qinl:setVisible(false)
    end
end

function UserinfoDialog:createLayerMenu()
    local csb = DTUI.getInstance().csb_main_userinfo_dialog
    self:addCSNode(csb)

    self.phoneNum = self:seekNode("phoneNum")
    self.imgBind  = self:seekNode("imgBind")

    local phone = cc.UserDefault:getInstance():getStringForKey("bindphone", "0")
    if phone ~= "0" then
        self.phoneNum:setString(phone)
        self.imgBind:loadTexture("ui/qj_userInfo/changeBind.png")
    end

    self:addBtListener("btExit", function(sender, eventType)
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)

    self:addBtListener("btnBind", function(sender, eventType)
        AudioManager:playPressSound()
        self:createLayerBind()
    end)

    self:addBtListener("btn_xianl", function(sender, eventType)
        AudioManager:playPressSound()
        local NativeUtil = require("common.NativeUtil")
        NativeUtil:loginThird({
            typ   = "xianliao",
            state = "" .. os.time(),
            classId = function(ret)
                dump(ret, "authByXianLiao")
                if tonumber(ret.code) == 0 and ret.authcode then
                    local input_msg = {
                        cmd  = NetCmd.C2S_BIND_APPID,
                        code = ret.authcode,
                        pack = "ylqj_xl_1",
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                elseif tonumber(ret.code) == -1 then
                    NativeUtil:dowloadOtherTip("xianliao")
                end
            end
        })
    end)

    self:addBtListener("btnBindwl", function(sender, eventType)
        AudioManager:playPressSound()
        local NativeUtil = require("common.NativeUtil")
        NativeUtil:loginThird({
            typ   = "qinliao",
            state = "" .. os.time(),
            classId = function(ret)
                --dump(ret, "authByQinLiao")
                if tonumber(ret.code) == 0 and ret.authcode then
                    local input_msg = {
                        cmd  = NetCmd.C2S_BIND_APPID,
                        code = ret.authcode,
                        pack = "ylqj_ql_1",
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                elseif tonumber(ret.code) == -1 then
                    NativeUtil:dowloadOtherTip("qinliao")
                end
            end
        })
    end)

    self:initHuobiInfo()
    self:refreshBind()
end

function UserinfoDialog:createLayerBind()
    local csb = DTUI.getInstance().csb_bindphone_dialog
    self.bind = self:addCSNode(csb)

    self.phoneNumInput = self.bind:seekNode("ePhoneNum")
    local code         = self.bind:seekNode("eCode")

    self.bind:seekNode("btLogin"):setVisible(false)
    self.sendBtn = self.bind:seekNode("btSend")
    self.djs     = self.bind:seekNode("djs")
    self.send    = self.bind:seekNode("imgSend")
    self.send:setVisible(false)
    self.djs:setVisible(false)
    local time = cc.UserDefault:getInstance():getStringForKey("start_time_frombind", "0")
    time       = tonumber(time)
    if os.time() - time >= 60 then
        time = nil
    else
        self:CountDown(60 - (os.time() - time))
    end
    self.bind:addBtListener("btExit", function(sender, eventType)
        AudioManager:playPressSound()
        self.bind:removeFromParent(true)
    end)

    self.sendBtn:addClickEventListener(function(sender, eventType)
        AudioManager:playPressSound()
        local phonenum = self.phoneNumInput:getString()
        if(string.len(phonenum) <= 0) then
            commonlib.showLocalTip("手机号码不能为空！")
            return
        end

        if(string.len(phonenum) ~= 11 or string.match(phonenum, "[1]%d%d%d%d%d%d%d%d%d%d") ~= phonenum) then
            commonlib.showLocalTip("您输入的手机号码错误，请重新输入！")
            self.phoneNumInput:setString("")
            return
        end
        local input_msg = {
            cmd         = NetCmd.C2S_SMS_GET_CODE,
            phoneNumber = tonumber(phonenum),
            type        = 1,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end)

    self.bind:addBtListener("btBind", function(sender, eventType)
        AudioManager:playPressSound()
        if code:getString() == "" then
            commonlib.showLocalTip("输入的验证码不能为空！")
            return
        end
        if self.code and tonumber(code:getString()) == self.code then
            local input_msg = {
                cmd         = NetCmd.C2S_SMS_BIND,
                phoneNumber = tonumber(self.phoneNumInput:getString()),
                -- {phoneNumber = 17043256196},
            }
            ymkj.SendData:send(json.encode(input_msg))
            self.phone = self.phoneNumInput:getString()
        else
            commonlib.showLocalTip("输入的验证码不正确！")
            code:setString("")
        end
    end)
end

function UserinfoDialog:CountDown(time)
    self.djs.time = time
    self.djs:setString("("..self.djs.time..")")
    self.sendBtn:setTouchEnabled(false)
    self.sendBtn:setBright(false)
    self.djs:setVisible(true)
    self.send:setVisible(true)
    self.djs:runAction(cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        self.djs.time = math.max(self.djs.time - 1, 0)
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

function UserinfoDialog:initHuobiInfo()
    local profile  = ProfileManager.GetProfile()
    local ClientIP = gt.getClientIp()
    if not profile then return end
    if pcall(commonlib.GetMaxLenString, profile.name, 14) then
        self:seekNode("name"):setString(commonlib.GetMaxLenString(profile.name, 14))
    else
        self:seekNode("name"):setString(profile.name)
    end

    self:seekNode("ID"):setString("ID:"..profile.uid)
    self:seekNode("head"):downloadImg(commonlib.wxHead(profile.head), g_wxhead_addr)
    self:seekNode("showHead"):downloadImg(commonlib.wxHead(profile.head), g_wxhead_addr)
    if ClientIP[1] == '0' and ClientIP[2] == '0' then
        self:seekNode("IP"):setString("未获取到你的位置信息")
    else
        local addr    = string.find(ClientIP[2], "&") or 0
        local addr2   = string.find(ClientIP[2], "市")
        local address = nil
        if addr2 then
            address = string.sub(ClientIP[2], addr + 1, addr2 + 2)
        else
            address = string.sub(ClientIP[2], addr + 1)
        end
        self:seekNode("IP"):setString(address)
    end
end

return UserinfoDialog