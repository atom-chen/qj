require('club.ClubHallUI')

local cmd_list = {
    -- NetCmd.S2C_LOGDATA,
}

local ClubZhanJiLayer = class("ClubZhanJiLayer", function()
    return cc.Layer:create()
end)

function ClubZhanJiLayer:create(args)
    local layer = ClubZhanJiLayer.new()
    layer.data  = args.data
    layer:createLayerMenu(args.list)
    return layer
end

function ClubZhanJiLayer:registerEventListener()

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

function ClubZhanJiLayer:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubZhanJiLayer:exitLayer()
    self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubZhanJiLayer:createLayerMenu(list)
    -- dump(list,"ClubZhanJiLayer list")
    local csb  = ClubHallUI.getInstance().csb_club_zhanji
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:exitLayer()
            GameGlobal.Club_Memory_Cur_Ju = nil
        end
    end)

    self.ZJPanel = ccui.Helper:seekWidgetByName(node, "ZJPanel")

    local baseItem = self.ZJPanel:getChildByName("item")
    baseItem:setVisible(false)
    local listView = self.ZJPanel:getChildByName("ListView")
    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(listView)
    listView:addScrollViewEventListener(scorllCallBack)
    listView:addTouchEventListener(touchCallBack)
    for i, v in ipairs(list or {}) do
        local item = baseItem:clone()
        item:setVisible(true)
        if GameGlobal.Club_Memory_Cur_Ju and v.cur_ju == GameGlobal.Club_Memory_Cur_Ju then
            item:loadTexture("ui/qj_zhanji/kk-fs8.png")
            local child = {"tDate", "tRoomNO", "tRoomBoss", "tPlayers1", "tPlayers2",
                "tPlayers3", "tPlayers4", "tPlayers5", "tPlayers6", "tScores1", "tScores2", "tScores3",
                "tScores4", "tScores5", "tScores6"}
            for i, v in ipairs(child) do
                item:getChildByName(v):setColor(cc.c3b(62, 81, 134))
            end
        end
        item:getChildByName("tDate"):setString(os.date("%Y-%m-%d\n %H:%M:%S", v.create_time))
        item:getChildByName("tRoomNO"):setString(tostring(v.room_id))
        if v.room_id and v.cur_ju then
            item:getChildByName("tRoomNO"):setString(tostring(v.room_id) .. '\n第' .. v.cur_ju .. '局')
        end

        local ziSize = 12
        if #v.summary < 5 then
            self:nameSize(item, 1)
        else
            self:nameSize(item, 2)
            ziSize = 6
        end

        if pcall(commonlib.GetMaxLenString, self.data.club_info.club_name, ziSize) then
            item:getChildByName("tRoomBoss"):setString(commonlib.GetMaxLenString(self.data.club_info.club_name, ziSize))
        else
            item:getChildByName("tRoomBoss"):setString(self.data.club_info.club_name)
        end
        local nameStr1  = ""
        local nameStr2  = ""
        local nameStr3  = ""
        local nameStr4  = ""
        local nameStr5  = ""
        local nameStr6  = ""
        local scoreStr1 = ""
        local scoreStr2 = ""
        local scoreStr3 = ""
        local scoreStr4 = ""
        local scoreStr5 = ""
        local scoreStr6 = ""

        for j, player in ipairs(v.summary) do
            if pcall(commonlib.GetMaxLenString, player.name, ziSize) then
                player.name = commonlib.GetMaxLenString(player.name, ziSize) .. "\n"
            else
                player.name = player.name
            end
            if j == 1 then
                nameStr1  = player.name
                scoreStr1 = player.score
            elseif j == 2 then
                nameStr2  = player.name
                scoreStr2 = player.score
            elseif j == 3 then
                nameStr3  = player.name
                scoreStr3 = player.score
            elseif j == 4 then
                nameStr4  = player.name
                scoreStr4 = player.score
            elseif j == 5 then
                nameStr5  = player.name
                scoreStr5 = player.score
            elseif j == 6 then
                nameStr6  = player.name
                scoreStr6 = player.score
            end
        end
        item:getChildByName("tPlayers1"):setString(nameStr1)
        item:getChildByName("tPlayers2"):setString(nameStr2)
        item:getChildByName("tPlayers3"):setString(nameStr3)
        item:getChildByName("tPlayers4"):setString(nameStr4)
        item:getChildByName("tPlayers5"):setString(nameStr5)
        item:getChildByName("tPlayers6"):setString(nameStr6)
        item:getChildByName("tScores1"):setString(scoreStr1)
        item:getChildByName("tScores2"):setString(scoreStr2)
        item:getChildByName("tScores3"):setString(scoreStr3)
        item:getChildByName("tScores4"):setString(scoreStr4)
        item:getChildByName("tScores5"):setString(scoreStr5)
        item:getChildByName("tScores6"):setString(scoreStr6)
        if tonumber(scoreStr1) and tonumber(scoreStr1) > 0 then
            item:getChildByName("tScores1"):setColor(cc.c3b(255, 97, 60))
        end
        if tonumber(scoreStr2) and tonumber(scoreStr2) > 0 then
            item:getChildByName("tScores2"):setColor(cc.c3b(255, 97, 60))
        end
        if tonumber(scoreStr3) and tonumber(scoreStr3) > 0 then
            item:getChildByName("tScores3"):setColor(cc.c3b(255, 97, 60))
        end
        if tonumber(scoreStr4) and tonumber(scoreStr4) > 0 then
            item:getChildByName("tScores4"):setColor(cc.c3b(255, 97, 60))
        end
        if tonumber(scoreStr5) and tonumber(scoreStr5) > 0 then
            item:getChildByName("tScores5"):setColor(cc.c3b(255, 97, 60))
        end
        if tonumber(scoreStr6) and tonumber(scoreStr6) > 0 then
            item:getChildByName("tScores6"):setColor(cc.c3b(255, 97, 60))
        end
        item:getChildByName("btXQ"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                print("观看")
                local net_msg = {
                    cmd = NetCmd.C2S_LOGDATA,
                    id  = v.log_data_id,
                }
                ymkj.SendData:send(json.encode(net_msg))
                GameGlobal.is_los_club = true
                gt.playback_log_ju_id  = nil
                if v.cur_ju then
                    GameGlobal.Club_Memory_Cur_Ju = v.cur_ju
                end
            end
        end)
        listView:pushBackCustomItem(item)
    end
    if GameGlobal.Club_Memory_Cur_Ju then
        local index = GameGlobal.Club_Memory_Cur_Ju - 1
        listView:refreshView()
        listView:jumpToPercentVertical(self:CalculationInnerPosY(listView, 151, index))
    end
    self:enableNodeEvents()
end

function ClubZhanJiLayer:CalculationInnerPosY(listView, itemHeight, index)
    local minY    = listView:getContentSize().height - listView:getInnerContainerSize().height
    local PosY    = itemHeight * index - minY
    local percent = ((PosY + minY) * 100) /- minY
    if minY == 0 then
        percent = 0
    end
    if percent < 0 then
        return 0
    elseif percent > 100 then
        return 100
    elseif percent <= 0 and percent >= 100 then
        return percent
    else
        return 0
    end
end

function ClubZhanJiLayer:nameSize(item, typ)
    if typ == 1 then
        for i = 1, 6 do
            local positionx1 = 661.76
            local positionx2 = 879.02
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setAnchorPoint(cc.p(0.5, 1))
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setFontSize(30)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setFontSize(30)
        end
    else
        for i = 1, 6 do
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setFontSize(28)
            tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setFontSize(28)
            tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setAnchorPoint(cc.p(0, 1))
            if i < 5 then
                local positionx1 = 532.52
                local positionx2 = 854.02
                tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            else
                local positionx1 = 670.60
                local positionx2 = 908.08
                tolua.cast(item:getChildByName("tPlayers"..i), "ccui.Text"):setPositionX(positionx1)
                tolua.cast(item:getChildByName("tScores"..i), "ccui.Text"):setPositionX(positionx2)
            end
        end
    end
end

return ClubZhanJiLayer