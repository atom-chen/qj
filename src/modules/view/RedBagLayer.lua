local cmd_list = {
    "sdk_callback",
}

local GrayLayer = require("modules.view.GrayLayer")
local RedBagLayer = class("RedBagLayer",GrayLayer)

function RedBagLayer:ctor()
    self:setName("RedBagLayer")
    GrayLayer.ctor(self)
    --如果是分享的好友就不用给php发送分享成功
    self.isSharedHy = false
end

function RedBagLayer:registerEventListener()
    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        if event_name == "sdk_callback" then
            local rtn_msg = custom_event:getUserData()
            if not rtn_msg or rtn_msg == "" then return end
            rtn_msg = json.decode(rtn_msg)
            if rtn_msg.typ == 9001 then
                if rtn_msg.errno == 0 then
                    -- commonlib.showLocalTip("分享成功")
                    if not self.isSharedHy then
                        RedBagController:reqRedBagNoticePhp()
                    end
                else
                    commonlib.showLocalTip("分享失败")
                end
            end
        end
    end
    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function RedBagLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function RedBagLayer:onEnter()
    GrayLayer.onEnter(self)
    local node = tolua.cast(cc.CSLoader:createNode("ui/ui_redbags.csb"),"ccui.Widget")
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)
    self:addChild(node)
    self.node = node

    local close_btn = ccui.Helper:seekWidgetByName(node, "close_btn")
    close_btn:setTouchEnabled(true)
    close_btn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:removeFromParent(true)
        end
    end)

    local lqjl_btn = ccui.Helper:seekWidgetByName(node, "lqjl_btn")
    lqjl_btn:setTouchEnabled(true)
    lqjl_btn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local RedBagJiLuLayer = require("modules.view.RedBagJiLuLayer")
            local layer = RedBagJiLuLayer:create()
            self:addChild(layer)
        end
    end)

    local ShareFriend_btn = ccui.Helper:seekWidgetByName(node, "ShareFriend_btn")
    ShareFriend_btn:setTouchEnabled(true)
    ShareFriend_btn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self.isSharedHy = false
            local redbag_writings_rul = gt.getConf("redbag_writings_rul")
            local rbModel = RedBagController:getModel()
            local pyq_text = rbModel:getConf("pyq")

            local data = RedBagController:getModel():getHBInfo()
            local has_lq = data.has_lq or 0
            pyq_text = string.format(pyq_text,has_lq*0.01)

            ymkj.wxReq(2, "秦晋棋牌", pyq_text, redbag_writings_rul, 2)
            local hbInfo = rbModel:getHBInfo()
            if tonumber(hbInfo.bind_wx) == 0 then
                RedBagController:reqRedBagInfo()
            end
        end
    end)

    local guanzhu_btn = ccui.Helper:seekWidgetByName(node, "guanzhu_btn")
    guanzhu_btn:setTouchEnabled(true)
    guanzhu_btn:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:sharedSuccess(true)
        end
    end)

    -- 初始化活动按钮
    self:initBtn()

    RedBagController:registerEventListener()

    RedBagController:reqRedBagInfo()
    RedBagController:reqRedBagMy()
    RedBagController:reqRedBagPhb()
    RedBagController:reqRedBagLqjl()
    RedBagController:reqRedBagTime()
    self:registerEventListener()
end

function RedBagLayer:initBtn()
    -- 按钮表
    local btnTable = {
        ["btn_lqsm"] = ccui.Helper:seekWidgetByName(self.node, "lq_btn"),
        ["btn_hdgz"] = ccui.Helper:seekWidgetByName(self.node, "hdgz_btn"),
        ["btn_wdhb"] = ccui.Helper:seekWidgetByName(self.node, "hb_btn"),
        ["btn_phb"] = ccui.Helper:seekWidgetByName(self.node, "phb_btn"),
    }
    -- 页面表
    local panelTable = {
        ["panel_lqsm"] = ccui.Helper:seekWidgetByName(self.node, "lq_Panel"),
        ["panel_hdgz"] = ccui.Helper:seekWidgetByName(self.node, "hdgz_Panel"),
        ["panel_wdhb"] = ccui.Helper:seekWidgetByName(self.node, "hb_Panel"),
        ["panel_phb"] = ccui.Helper:seekWidgetByName(self.node, "phb_Panel"),
    }

    btnTable["btn_lqsm"]:setTouchEnabled(true)
    btnTable["btn_lqsm"]:setBright(false)
    for name,data in pairs(panelTable) do
        if name == "panel_lqsm" then
            data:setVisible(true)
            data:setLocalZOrder(2)
        else
            data:setVisible(false)
            data:setLocalZOrder(1)
        end
    end
    btnTable["btn_lqsm"]:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            for name,data in pairs(btnTable) do
                if name == "btn_lqsm" then
                    data:setBright(false)
                else
                    data:setBright(true)
                end
            end
            for name,data in pairs(panelTable) do
                if name == "panel_lqsm" then
                    data:setVisible(true)
                    data:setLocalZOrder(2)
                else
                    data:setVisible(false)
                    data:setLocalZOrder(1)
                end
            end
        end
    end)
    btnTable["btn_hdgz"]:setTouchEnabled(true)
    btnTable["btn_hdgz"]:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            for name,data in pairs(btnTable) do
                if name == "btn_hdgz" then
                    data:setBright(false)
                else
                    data:setBright(true)
                end
            end
            for name,data in pairs(panelTable) do
                if name == "panel_hdgz" then
                    data:setVisible(true)
                    data:setLocalZOrder(2)
                else
                    data:setVisible(false)
                    data:setLocalZOrder(1)
                end
            end
        end
    end)
    btnTable["btn_wdhb"]:setTouchEnabled(true)
    btnTable["btn_wdhb"]:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            for name,data in pairs(btnTable) do
                if name == "btn_wdhb" then
                    data:setBright(false)
                else
                    data:setBright(true)
                end
            end
            for name,data in pairs(panelTable) do
                if name == "panel_wdhb" then
                    data:setVisible(true)
                    data:setLocalZOrder(2)
                else
                    data:setVisible(false)
                    data:setLocalZOrder(1)
                end
            end
        end
    end)
    btnTable["btn_phb"]:setTouchEnabled(true)
    btnTable["btn_phb"]:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            for name,data in pairs(btnTable) do
                if name == "btn_phb" then
                    data:setBright(false)
                else
                    data:setBright(true)
                end
            end
            -- addChild(child, zOrder, name)
            for name,data in pairs(panelTable) do
                if name == "panel_phb" then
                    data:setVisible(true)
                    data:setLocalZOrder(2)
                else
                    data:setVisible(false)
                    data:setLocalZOrder(1)
                end
            end
        end
    end)
end

function RedBagLayer:onExit()
    GrayLayer.onExit(self)
    RedBagController:unregisterEventListener()
    self:unregisterEventListener()
end

function RedBagLayer:sharedSuccess(noShare)
    local rbModel = RedBagController:getModel()
    local hbInfo = rbModel:getHBInfo()
    local unionid = AccountController:getModel():getUnionid()
    local redbag_lq_url = gt.getConf("redbag_lq_url")
    local url = gt.attachUrlParams(redbag_lq_url,{
        u = unionid,
    })
    if tonumber(hbInfo.bind_wx) == 0 then
        local tip_text = rbModel:getConf("share_tip")
        commonlib.showTipDlg(tip_text, function(is_ok)
            if is_ok then
                self.isSharedHy = true
                local hy_text = rbModel:getConf("hy")
                ymkj.wxReq(2,hy_text,"秦晋棋牌",url, 1)
            end
        end)
    else

        if noShare then
            gt.openUrl(url)
        else
            commonlib.showTipDlg("分享成功,是否前往领取？", function(is_ok)
                if is_ok then
                    gt.openUrl(url)
                end
            end)
        end
    end
end

function RedBagLayer:refreshHBInfo()
    local data = RedBagController:getModel():getHBInfo()
    local has_lq = data.has_lq or 0
    local no_lq = data.no_lq or 0
    local sx_lq = data.sx_lq or 0
    local ylq_label = ccui.Helper:seekWidgetByName(self.node, "ylq_label")
    ylq_label:setString(string.format("%.2f",has_lq*0.01))
    local wlq_label = ccui.Helper:seekWidgetByName(self.node, "wlq_label")
    wlq_label:setString(string.format("%.2f",no_lq*0.01))
    local ysx_lable = ccui.Helper:seekWidgetByName(self.node, "ysx_lable")
    ysx_lable:setString(string.format("%.2f",sx_lq*0.01))
    local zhq_label = ccui.Helper:seekWidgetByName(self.node, "zhq_label")
    zhq_label:setString(string.format("%.2f",(has_lq+no_lq+sx_lq)*0.01))
end

function RedBagLayer:refreshHBMy()
    local data = RedBagController:getModel():getHBMy()
    local listView_hb = ccui.Helper:seekWidgetByName(self.node, "ListView_hb")
    if data and next(data)~=nil then
        local wd_item = ccui.Helper:seekWidgetByName(self.node, "wd_item")
        -- 我的红包列表
        for _,hb_data in pairs(data) do
            -- 创建红包列表item
            local item = wd_item
            if _>1 then
                item = wd_item:clone()
                listView_hb:pushBackCustomItem(item)
            end
            -- 设置红包列表item信息
            ccui.Helper:seekWidgetByName(item, "time"):setString(hb_data.time)
            if hb_data.type == 2 then
                ccui.Helper:seekWidgetByName(item, "hb_type"):setString("红包雨")
            elseif hb_data.type == 1 then
                ccui.Helper:seekWidgetByName(item, "hb_type"):setString("财神到")
            end
            ccui.Helper:seekWidgetByName(item, "hb_money"):setString(""..hb_data.money*0.01)
            local path = "ui/qj_redbag/"
            if hb_data.status == 1 then  --已领取
                path = path.."lingqu.png"
            elseif hb_data.status == 0 then  --待领取
                path = path.."dailingqu.png"
            elseif hb_data.status == 2 then  --待分享
                path = path.."fenxiang.png"
            elseif hb_data.status == 3 then  --已失效
                path = path.."shixiao.png"
            end
            local hb_status = display.newSprite(path)
            hb_status:setAnchorPoint(cc.p(0.5,0.5))
            ccui.Helper:seekWidgetByName(item, "status"):addChild(hb_status)
        end
    else
        listView_hb:removeSelf()
        local hb_Panel = ccui.Helper:seekWidgetByName(self.node, "hb_Panel")
        local size = hb_Panel:getContentSize()
        local wdhb_tip = display.newSprite("ui/qj_redbag/hb_tip.png")
        hb_Panel:addChild(wdhb_tip)
        wdhb_tip:setPosition(cc.p(size.width/2, size.height/2))
    end
end

function RedBagLayer:refreshHBPhb()
    local data = RedBagController:getModel():getHBPhb()
    if data and next(data)~=nil then
        local listView_phb = ccui.Helper:seekWidgetByName(self.node, "ListView_phb")
        local rank_item = ccui.Helper:seekWidgetByName(self.node, "rankItem")
        -- 排行榜列表
        if data.rankdata and next(data.rankdata)~=nil then
            listView_phb:setVisible(true)
            for rank,rankdata in pairs(data.rankdata) do
                if rank ~= rankdata.rank then
                    print("接收到的消息顺序与排行榜顺序不一致")
                end
                -- 创建排行榜item
                local item = rank_item
                if rank>1 then
                    item = rank_item:clone()
                    listView_phb:pushBackCustomItem(item)
                end
                -- 设置排行榜item信息
                local rankNum = ccui.Helper:seekWidgetByName(item, "rank_1")
                rankNum:setVisible(false)
                if rankdata.rank<=3 then
                    rankNum = ccui.Helper:seekWidgetByName(item, "rank_"..rankdata.rank)
                elseif rankdata.rank>3 then
                    rankNum = ccui.Helper:seekWidgetByName(item, "rank_4")
                    rankNum:setString(""..rankdata.rank)
                end
                rankNum:setVisible(true)
                local touxiang = ccui.Helper:seekWidgetByName(item, "tx_d")
                touxiang:downloadImg(commonlib.wxHead(rankdata.head_url), g_wxhead_addr)
                ccui.Helper:seekWidgetByName(item, "name"):setString(""..rankdata.nick_name)
                ccui.Helper:seekWidgetByName(item, "hb_money"):setString(""..rankdata.money*0.01)
                -- 设置排行榜的最大显示数目
                if rank>=20 then
                    break
                end
            end
            -- 自己的排名
            if data.mydata and next(data.mydata)~=nil then
                ccui.Helper:seekWidgetByName(self.node, "my_rank"):setString("我的排名:  "..data.mydata[1].rank)
                ccui.Helper:seekWidgetByName(self.node, "my_money"):setString("金额:  "..data.mydata[1].money*0.01)
            end
        else
            print("排行榜暂无数据")
            listView_phb:setVisible(false)
            rank_item:setVisible(false)
            --TODO 排行榜暂无数据
        end
    end
end

function RedBagLayer:refreshHBGuiZe()
    --活动时间和活动内容
    local data = RedBagController:getModel():getHBTime()
    if data and next(data)~=nil then
        local hd_time = ccui.Helper:seekWidgetByName(self.node, "hd_time")
        local hdxq = ccui.Helper:seekWidgetByName(self.node, "hdxq")
        hd_time:setString(data.title)
        hdxq:setString(data.content)
    end
end

return RedBagLayer

