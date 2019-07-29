local JiesanLayer = class("JiesanLayer",function()
    return cc.Layer:create()
end)

function JiesanLayer:create(rtn_msg, room_id, gmId)

    local scene = JiesanLayer.new()
    scene:createLayer(rtn_msg, room_id, gmId)
    return scene
end

function JiesanLayer:createLayer(rtn_msg, room_id, gmId)
    -- dump(rtn_msg)
    local csb = DTUI.getInstance().csb_jiesanxq
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local player_agree_list = {}
    for i,v in ipairs(rtn_msg.agree_list) do
        player_agree_list[i] = v
    end

    if rtn_msg.noact_list and rtn_msg.noact_list[1] then
        for i = 1,#rtn_msg.noact_list do
            player_agree_list[#player_agree_list+1] = rtn_msg.noact_list[i]
        end
    end

    local apply_name = ccui.Helper:seekWidgetByName(node, "apply_name")
    local apply_time = ccui.Helper:seekWidgetByName(node, "apple_time")
    local roomid     = ccui.Helper:seekWidgetByName(node, "roomid")
    local tuoguan    = ccui.Helper:seekWidgetByName(node, "tuoguan")
    apply_name:setVisible(true)

    local str = "时间:" .. os.date("%m-%d %H:%M", rtn_msg.apply_time)
    apply_time:setString(str)
    local GMid = rtn_msg.gmId or gmId
    if GMid then
        apply_name:setVisible(false)
        roomid:setString("此房间【".. room_id.. "】已被管理员【".. GMid .."】解散")
    else
        roomid:setString("发起投票解散房间[".. room_id.. "]")
    end
    for i =1 ,6 do
        if player_agree_list and player_agree_list[i] then
            if rtn_msg.apply_uid ==  player_agree_list[i].uid then
                if pcall(commonlib.GetMaxLenString, player_agree_list[i].name, 14) then
                    apply_name:setString(string.format("玩家:%s",commonlib.GetMaxLenString(player_agree_list[i].name,14)))
                else
                    apply_name:setString(string.format("玩家:%s",player_agree_list[i].name))
                end
                table.remove(player_agree_list,i)
            end
        end
    end
    if rtn_msg.tg_list and rtn_msg.tg_list[1] then
        tuoguan:setVisible(true)
    end
    local people_num = #player_agree_list
    log(people_num)
    if people_num == 1 then
        ccui.Helper:seekWidgetByName(node,"player1"):setPositionX(370.5)
    elseif people_num == 2 then
        ccui.Helper:seekWidgetByName(node,"player1"):setPositionX(244.5)
        ccui.Helper:seekWidgetByName(node,"player2"):setPositionX(489)
    elseif people_num == 3 then
        ccui.Helper:seekWidgetByName(node,"player1"):setPositionX(185.25)
        ccui.Helper:seekWidgetByName(node,"player2"):setPositionX(370.5)
        ccui.Helper:seekWidgetByName(node,"player3"):setPositionX(555.75)
    elseif people_num == 4 then
        ccui.Helper:seekWidgetByName(node,"player1"):setPositionX(96.33)
        ccui.Helper:seekWidgetByName(node,"player2"):setPositionX(281.58)
        ccui.Helper:seekWidgetByName(node,"player3"):setPositionX(466.83)
        ccui.Helper:seekWidgetByName(node,"player4"):setPositionX(652.08)
    elseif people_num == 5 then
        ccui.Helper:seekWidgetByName(node,"player1"):setPositionX(66.69)
        ccui.Helper:seekWidgetByName(node,"player2"):setPositionX(214.89)
        ccui.Helper:seekWidgetByName(node,"player3"):setPositionX(363.09)
        ccui.Helper:seekWidgetByName(node,"player4"):setPositionX(511.29)
        ccui.Helper:seekWidgetByName(node,"player5"):setPositionX(659.49)
    elseif people_num == 6 then
        for i=1,6 do
            local pos= 72.28 + (i-1) * 118.56
            ccui.Helper:seekWidgetByName(node,"player"..i):setScale(0.9)
            ccui.Helper:seekWidgetByName(node,"player"..i):setPositionX(pos)
        end
    end
    for i = 1 ,6 do
        local item = ccui.Helper:seekWidgetByName(node,"player"..i)
        if player_agree_list and player_agree_list[i] then
            local info =  player_agree_list[i]

            ccui.Helper:seekWidgetByName(item, "touxiang"):downloadImg(commonlib.wxHead(info.head), g_wxhead_addr)
            if pcall(commonlib.GetMaxLenString, player_agree_list[i].name, 12) then
                ccui.Helper:seekWidgetByName(item, "name"):setString(commonlib.GetMaxLenString(info.name, 12))
            else
                ccui.Helper:seekWidgetByName(item, "name"):setString(info.name)
            end
            ccui.Helper:seekWidgetByName(item, "id"):setString(info.uid)

            if rtn_msg.noact_list and rtn_msg.noact_list[1] then
                for ii =1,#rtn_msg.noact_list do
                    if info.uid == rtn_msg.noact_list[ii].uid then
                        ccui.Helper:seekWidgetByName(item, "agree"):loadTexture("ui/qj_ddz_final/2-fs8.png")
                    end
                end
            end
            if rtn_msg.tg_list and rtn_msg.tg_list[1] then
                for ii =1,#rtn_msg.tg_list do
                    if info.uid == rtn_msg.tg_list[ii].uid then
                        ccui.Helper:seekWidgetByName(item, "agree"):loadTexture("ui/qj_ddz_final/imgtuoguan.png")
                    end
                end
            end
        else
            item:setVisible(false)
        end
    end

    ccui.Helper:seekWidgetByName(node, "btExit"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
                self:removeFromParent(true)
        end
    end)

    ccui.Helper:seekWidgetByName(node, "btEnter"):addTouchEventListener(function(__, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
                self:removeFromParent(true)
        end
    end)
end

return JiesanLayer

