local cmd_list = {
    NetCmd.S2C_SHOP,
    NetCmd.S2C_SHOP_ORDER,
    NetCmd.S2C_APPLE_TRANS,
    "sdk_callback",
    "cards_change",
}

local zzf_game_cfg = {
    ["ios"] = {
        ["ylqp"] = {
            name    = "秦晋棋牌房卡版",
            package = "com.xm888.ylqpfkb",
            appid   = 2999,
        },
        ["ylqp2"] = {
            name    = "秦晋棋牌【房卡版】",
            package = "com.iw888.ylqp",
            appid   = 2999,
        },
        ["ylqp3"] = {
            name    = "秦晋棋牌【房卡版】",
            package = "com.iw888.ylqp",
            appid   = 2999,
        },
        ["yltest"] = {
            name    = "秦晋测试",
            package = "com.hnmj.mm",
            appid   = 2999,
        },
        ["ylhn_wechat_2"] = {
            name    = "秦晋亲友版",
            package = "com.iw888.ylqp",
            appid   = 2999,
        },
    },
    ["android"] = {
        ["ylqp"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["ylqp2"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["ylqp3"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["yltest"] = {
            name    = "秦晋测试",
            package = "com.hnmj.mm",
            appid   = 2997,
        },
        ["ylhn_wechat_2"] = {
            name    = "秦晋亲友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
    },
    ["win"] = {
        ["ylqp"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["ylqp2"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["ylqp3"] = {
            name    = "秦晋棋牌好友版",
            package = "com.sy18.ysz",
            appid   = 2997,
        },
        ["yltest"] = {
            name    = "秦晋测试",
            package = "com.hnmj.mm",
            appid   = 2997,
        },
        ["ylhn_wechat_2"] = {
            name    = "秦晋亲友版",
            package = "com.sy18.ysz",
            appid   = 2999,
        },
    },
}

local ChargeLayer = class("ChargeLayer", function()
    return cc.Layer:create()
end)

function ChargeLayer.create()
    local layer = ChargeLayer.new()
    return layer
end

function ChargeLayer:ctor()
    self:createLayerMenu()
end

function ChargeLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        if event_name == "cards_change" then
            self:initHuobiInfo()
            return
        end
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            if rtn_msg.cmd == NetCmd.S2C_APPLE_TRANS then
                if rtn_msg.guibin_des then
                    self.guibin_lbl:setString(rtn_msg.guibin_des)
                end
                commonlib.showLocalTip("贵宾卡购买成功")
            elseif rtn_msg.cmd == NetCmd.S2C_SHOP then
                -- dump(rtn_msg,"NetCmd.S2C_SHOP")
                self.charge_list = rtn_msg.products or {}
                self.pay_style   = rtn_msg.style or {1}
                if rtn_msg.guibin_des then
                    self.guibin_lbl:setString(rtn_msg.guibin_des)
                end
                self:initGoodList()
            elseif rtn_msg.cmd == NetCmd.S2C_SHOP_ORDER then
                -- dump(rtn_msg,"NetCmd.S2C_SHOP_ORDER")
                if ios_checking then -- 苹果商店
                    ymkj.storePay(rtn_msg.productinfo)
                elseif not rtn_msg.typ or rtn_msg.typ == 1 then -- 明天动力
                    if rtn_msg.payChannelId == "wechat" then
                        ymkj.sdkPay(rtn_msg.amount, rtn_msg.mchntOrderNo, rtn_msg.subject, rtn_msg.clientIp, rtn_msg.notifyUrl, rtn_msg.signature, rtn_msg.extra, rtn_msg.appid, 1)
                    else
                        ymkj.sdkPay(rtn_msg.amount, rtn_msg.mchntOrderNo, rtn_msg.subject, rtn_msg.clientIp, rtn_msg.notifyUrl, rtn_msg.signature, rtn_msg.extra, rtn_msg.appid, 2)
                    end
                elseif rtn_msg.typ == 4 then -- 掌支付
                    if not rtn_msg.payChannelId or rtn_msg.payChannelId == "wechat" then
                        local zzf = zzf_game_cfg[g_os][g_game_pack] or {name = g_game_name, package = g_game_pack}
                        ymkj.sdkPay2(rtn_msg.money, rtn_msg.appFeeName, rtn_msg.appFeeName, rtn_msg.cpparam, rtn_msg.sign, rtn_msg.partnerId, rtn_msg.qn, rtn_msg.appId, g_res_ver, zzf.name, zzf.package)
                    else
                        local zzf = zzf_game_cfg[g_os][g_game_pack] or {name = g_game_name, package = g_game_pack}
                        ymkj.zzfZFB(rtn_msg.money, rtn_msg.appFeeName, rtn_msg.appFeeName, rtn_msg.cpparam, rtn_msg.sign, rtn_msg.partnerId, rtn_msg.qn, rtn_msg.appId, g_res_ver, zzf.name, zzf.package)
                    end
                elseif rtn_msg.typ == 5 then -- 支付宝
                    ymkj.sdkPay3(rtn_msg.trans_id, 5)
                elseif rtn_msg.typ == 6 then -- 微信
                    ymkj.sdkPay3(rtn_msg.trans_id, 6)
                else -- wrap支付
                    commonlib.openWeb(rtn_msg.pay_url)
                end
            elseif event_name == "sdk_callback" then
                if rtn_msg.typ ~= 9001 then
                    if not ios_checking then
                        if rtn_msg.is_asyn == 1 then
                            commonlib.showLocalTip("订单支付成功，请留意房卡变化")
                        else
                            commonlib.showLocalTip("订单支付成功，请留意房卡变化")
                        end
                    else
                        commonlib.showLocalTip("订单支付成功，请留意房卡变化")
                        self:reqChargeCallback(rtn_msg)
                    end
                end
            end
        else
            if rtn_msg.typ ~= 9001 then
                commonlib.showLocalTip(rtn_msg.msg)
            end
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end

end

function ChargeLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ChargeLayer:reqChargeList()
    if ios_checking then
        local idtyp = 2
        if gt.getPackageName() == "com.hnthj.hlhbmj" then
            idtyp = 3
        elseif gt.getPackageName() == "com.hnthj.nxqp" then
            idtyp = 7
        end
        local input_msg = {
            cmd          = NetCmd.C2S_SHOP,
            ios_checking = true,
            idtyp        = idtyp,
        }
        ymkj.SendData:send(json.encode(input_msg))
    else
        local input_msg = {
            cmd = NetCmd.C2S_SHOP,
        }
        ymkj.SendData:send(json.encode(input_msg))
    end
end

function ChargeLayer:reqChargeTrans(product_id)
    local supportWayVer = 1
    if ymkj.supportPayWay then
        supportWayVer = ymkj.supportPayWay()
    end
    local zzf       = zzf_game_cfg[g_os][g_game_pack]
    local zzf_appid = nil
    if zzf then
        zzf_appid = zzf.appid
    end
    if ios_checking then
        local input_msg = {
            cmd          = NetCmd.C2S_SHOP_ORDER,
            os           = g_os,
            product_id   = product_id,
            uid          = ProfileManager.GetProfile().uid,
            ver          = supportWayVer, -- 1:sdk and wrap 2:sdk and wrap(no mtdl sdk and no alipay sdk)
            style        = 3, -- 1:wechat 2:zfb 3:appstore
            ios_checking = true,
        }
        ymkj.SendData:send(json.encode(input_msg))
    else
        if #self.pay_style == 1 then
            local style = self.pay_style[1]
            local input_msg = {
                cmd        = NetCmd.C2S_SHOP_ORDER,
                os         = g_os,
                product_id = product_id,
                uid        = ProfileManager.GetProfile().uid,
                ver        = supportWayVer, -- 1:sdk and wrap 2:sdk and wrap(no mtdl sdk and no alipay sdk)
                style      = style,
            }
            if zzf_appid then
                input_msg.appid = zzf_appid
            end
            local app_info = nil
            if ymkj.getAppInfo then app_info = ymkj.getAppInfo() end
            if app_info and app_info ~= "" then
                input_msg.appinfo = app_info
            end
            ymkj.SendData:send(json.encode(input_msg))
        else
            local node = tolua.cast(cc.CSLoader:createNode("ui/zfzx.csb"), "ccui.Widget")
            cc.Director:getInstance():getRunningScene():addChild(node, 999999, 189189)

            node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

            ccui.Helper:doLayout(node)

            ccui.Helper:seekWidgetByName(node, "btn-exit"):addTouchEventListener(
                function(__, eventType)
                    if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                        node:removeFromParent(true)
                    end
                end
            )
            ccui.Helper:seekWidgetByName(node, "zhifubaopay"):addTouchEventListener(
                function(__, eventType)
                    if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                        node:removeFromParent(true)
                        local input_msg = {
                            cmd        = NetCmd.C2S_SHOP_ORDER,
                            os         = g_os,
                            product_id = product_id,
                            uid        = ProfileManager.GetProfile().uid,
                            ver        = supportWayVer, -- 1:sdk and wrap 2:sdk and wrap(no mtdl sdk and no alipay sdk)
                            style      = 2, -- 1:wechat 2:zfb 3:appstore
                        }
                        if zzf_appid then
                            input_msg.appid = zzf_appid
                        end
                        local app_info = nil
                        if ymkj.getAppInfo then app_info = ymkj.getAppInfo() end
                        if app_info and app_info ~= "" then
                            input_msg.appinfo = app_info
                        end
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end
            )
            ccui.Helper:seekWidgetByName(node, "weixinpay"):addTouchEventListener(
                function(__, eventType)
                    if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                        node:removeFromParent(true)
                        local input_msg = {
                            cmd        = NetCmd.C2S_SHOP_ORDER,
                            os         = g_os,
                            product_id = product_id,
                            uid        = ProfileManager.GetProfile().uid,
                            ver        = supportWayVer, -- 1:sdk and wrap 2:sdk and wrap(no mtdl sdk and no alipay sdk)
                            style      = 1, -- 1:wechat 2:zfb 3:appstore
                        }
                        if zzf_appid then
                            input_msg.appid = zzf_appid
                        end
                        local app_info = nil
                        if ymkj.getAppInfo then app_info = ymkj.getAppInfo() end
                        if app_info and app_info ~= "" then
                            input_msg.appinfo = app_info
                        end
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                end
            )
        end
    end
end

function ChargeLayer:reqChargeCallback(trans_data)
    local input_msg = {
        cmd            = NetCmd.C2S_APPLE_TRANS,
        transaction_id = trans_data.apple_receipt,
    }
    ymkj.SendData:send(json.encode(input_msg))
end

function ChargeLayer:initHuobiInfo()
    local profile = ProfileManager.GetProfile()
    -- tolua.cast(ccui.Helper:seekWidgetByName(self.node,"fangkashu"), "ccui.TextAtlas"):setString(profile.card or 0)
end

function ChargeLayer:initGoodList()
    local charge_list = {}
    if self.charge_list and #self.charge_list > 0 then
        table.sort(self.charge_list, function(a, b)
            return tonumber(a.id) < tonumber(b.id)
        end)
        for __, v in ipairs(self.charge_list) do
            v.typ = v.typ or 1
            if v.typ == self.pay_kind then
                charge_list[#charge_list + 1] = v
            end
        end
    end

    if #charge_list <= 0 then
        commonlib.showLocalTip("此栏暂无商品，敬请期待")
    end

    for i = 1, 6 do
        local good_btn = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "btn_buy"..i), "ccui.Button")
        if not good_btn then
            break
        end
        good_btn:setContentSize(cc.size(g_visible_size.width / 960 * 216, 292))
        ccui.Helper:doLayout(good_btn)
        good_btn:setVisible(false)
        good_btn:setTouchEnabled(false)
    end

    for i = 1, 6 do
        local data     = charge_list[i]
        local good_btn = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "btn_buy"..i), "ccui.Button")
        if not good_btn then
            break
        end
        if not data then
            break
        end
        good_btn:setVisible(true)
        good_btn:setTouchEnabled(true)

        local btn = tolua.cast(ccui.Helper:seekWidgetByName(good_btn, "btn_b1"), "ccui.Button")
        btn:setTouchEnabled(false)

        local priceStr = ""
        if type(data.amount) == "number" then
            priceStr = data.amount / 100 .. "元"
        else
            priceStr = data.amount
        end
        btn:setTitleText(priceStr)

        local zengSongLabel = ccui.Helper:seekWidgetByName(good_btn, "Text_1")
        local zengSongStr   = ""
        if data.card and data.card_add then
            zengSongStr = string.format("买%s送%s", tostring(data.card), tostring(data.card_add))
        else
            zengSongStr = data.name
        end
        zengSongLabel:setString(zengSongStr)

        good_btn:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                if not self.in_req then
                    self:reqChargeTrans(data.id)
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function()
                        self.in_req = nil
                    end)))
                    self.in_req = true
                end
            end
        end)
    end
end

function ChargeLayer:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/shangcheng.csb"), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node
    ccui.Helper:seekWidgetByName(self.node, "btn_buy6"):setVisible(false)
    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btexit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()

                self:unregisterEventListener()
                self.charge_list = nil
                self.node        = nil

                self:removeFromParent(true)

            end
        end
    )

    for i = 1, 6 do
        local good_btn = tolua.cast(ccui.Helper:seekWidgetByName(self.node, "btn_buy"..i), "ccui.Button")
        if not good_btn then
            break
        end
        good_btn:setVisible(false)
        good_btn:setTouchEnabled(false)
    end

    self.pay_kind = 1
    self:initHuobiInfo()
    self:registerEventListener()
    self:reqChargeList()
end

return ChargeLayer