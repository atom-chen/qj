require('club.ClubHallUI')

local cmd_list = {
    -- NetCmd.S2C_LOGDATA,
}

local ClubRankUserLayer = class("ClubRankUserLayer", function()
    return cc.Layer:create()
end)

function ClubRankUserLayer:create(args)
    local layer = ClubRankUserLayer.new()
    layer.data  = args.data
    layer:createLayerMenu(args.list)
    return layer
end

function ClubRankUserLayer:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        -- if rtn_msg.cmd == NetCmd.S2C_LOGDATA then
        --     dump(rtn_msg,"NetCmd.S2C_LOGDATA",10)
        -- end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function ClubRankUserLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubRankUserLayer:exitLayer()
    self:removeFromParent(true)
end

function ClubRankUserLayer:createLayerMenu(list)
    local csb  = ClubHallUI.getInstance().csb_club_rank_consume
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:exitLayer()
        end
    end)

    -- dump(list)

    if #list == 0 then
        commonlib.showLocalTip("亲友圈内还没有对战产生，快去呼唤你的朋友一起来玩吧")
    end
    for i = 1, 7 do
        local item = ccui.Helper:seekWidgetByName(node, "item" .. i)
        local time = os.time() - 86400 * i
        local str  = ""

        if os.date("%w", time) == "0" then
            str = "星期天"
        elseif os.date("%w", time) == "1" then
            str = "星期一"
        elseif os.date("%w", time) == "2" then
            str = "星期二"
        elseif os.date("%w", time) == "3" then
            str = "星期三"
        elseif os.date("%w", time) == "4" then
            str = "星期四"
        elseif os.date("%w", time) == "5" then
            str = "星期五"
        elseif os.date("%w", time) == "6" then
            str = "星期六"
        end

        str = str .. os.date("\n%Y年%m月%d日", time)
        item:getChildByName("tData"):setString(str)
        if #list > 0 then
            for ii = 1, #list do
                local str_time = {}
                local time_num = string.gmatch(list[ii].date, "%w+")
                str_time.year  = tonumber(time_num())
                str_time.month = tonumber(time_num())
                str_time.day   = tonumber(time_num())
                if str_time.day == tonumber(os.date("%d", time)) then
                    item:getChildByName("tJushu"):setString(list[ii].total_ju)
                    item:getChildByName("tCardnum"):setString(list[ii].cost_card)
                    item:getChildByName("tJiesan"):setString(list[ii].cost_card_js)
                end
            end
        end
    end

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

return ClubRankUserLayer