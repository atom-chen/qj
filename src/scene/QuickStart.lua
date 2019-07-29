

local QuickStart = class("QuickStart",function()
    return cc.Layer:create()
end)

function QuickStart:ctor(args)

    self:createLayerMenu()
    self:registerEventListener()
end

function QuickStart:onEnter()
    -- self:registerEventListener()
end

function QuickStart:onExit()
    self:unregisterEventListener()
end

function QuickStart:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        if rtn_msg.cmd == NetCmd.S2C_CLUB_IDLE_PLAYERS then
            -- dump(rtn_msg)
        end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end
end

function QuickStart:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function QuickStart:exitLayer()

end

function QuickStart:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/quickstart.csb"), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node


end

return QuickStart