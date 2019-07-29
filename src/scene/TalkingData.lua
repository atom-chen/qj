local NativeUtil = require("common.NativeUtil")

local TalkingData = {
    registeredAccount = false
}

function TalkingData:call(funcName, args, callback, sigs)
    if not NativeUtil:getAbility("TalkingData") then return end
    callback = callback or function()end
    -- if not self.registeredAccount and funcName ~= "onLogin" then return end
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local className = "XZTalkingData"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        callback(ok, ret)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif g_os == "android" then
        if funcName == "setLatitude" then
            return
        end
        local luaj = require("cocos.cocos2d.luaj")
        -- commonlib.showLocalTip("TalkingData")
        local args      = {json.encode(args)}
        local sigs      = sigs or "(Ljava/lang/String;)V"
        local className = "com/sy18/luaj/XZTalkingData"
        local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
        callback(ok, ret)
        if not ok then
            print("not ok The ret is:", ret)
        end
        -- commonlib.showLocalTip(funcName)
    end
end

function TalkingData:Test()
    print("TalkingData:Test")
    -- commonlib.showLocalTip("TalkingData")
    self:call("onLogin", {
        uid         = "00",
        name        = "test",
        accountType = 6,
        level       = 1,
        gender      = 1,
        age         = 18,
        gameServer  = "gameServer",
        }, function(ok, ret)
        if ok then
            self.registeredAccount = true
        end
    end)
    self:call("setLatitude", {
        lat = 50.7854,
        lon = 78.7854,
    })
    self:call("onEvent", {
        eventId = "进入主界面",
        eventData = json.encode({
            ["进入方式"] = "从登陆界面进入",
        }),
    })
    local orderId = tostring(os.time())
    display.getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        self:call("onChargeRequst", {
            orderId               = orderId,
            iapId                 = "VIP3礼包",
            currencyAmount        = 12.88,
            currencyType          = "CNY",
            virtualCurrencyAmount = 1288,
            paymentType           = "微信支付",
        })
    end)))
    display.getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
        self:call("onChargeSuccess", {
            orderId = orderId,
        })
    end)))
    self:call("onReward", {
        virtualCurrencyAmount = 4,
        reason                = "红包雨活动送2房卡",
    })
    self:call("onPurchase", {
        item   = "房卡",
        number = 1,
        price  = 5,
    })
    self:call("onUse", {
        item   = "房卡",
        number = 1,
    })
    self:call("onBegin", {
        missionId = "打怪任务",
    })
    self:call("onCompleted", {
        missionId = "打怪任务",
    })
    self:call("onFailed", {
        missionId = "打怪任务",
        cause     = "装备太差",
    })
end

return TalkingData