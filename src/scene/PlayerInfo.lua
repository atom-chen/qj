require('scene.PlayerData')
require('scene.DTUI')

local PlayerInfo = class("PlayerInfo", function()
    return cc.Layer:create()
end)

function PlayerInfo.create(user, index, is_self, ignoreArr, rtn_msg, mj)
    local layer = PlayerInfo.new()
    if mj then
        layer:createLayerMenuWithMJ(user, index, is_self, ignoreArr, rtn_msg)
    else
        layer:createLayerMenu(user, index, is_self, ignoreArr, rtn_msg)
    end
    return layer
end

function PlayerInfo:createLayerMenu(user, index, is_self, ignoreArr, rtn_msg)
    self.index = index or 1
    -- if index ==3 then index =0 end
    self.is_self   = is_self
    self.ignoreArr = ignoreArr or {}

    local csb  = DTUI.getInstance().csb_DT_UserinfoLayer
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    ccui.Helper:seekWidgetByName(node, "btExit"):addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))

    local playLastBtn = ccui.Helper:seekWidgetByName(node, "playlast")

    if self.is_self then
        playLastBtn:setVisible(false)
    else
        local id = ccui.Helper:seekWidgetByName(node, "id")
        id:setPositionY(id:getPositionY() + 60)
        local ip = ccui.Helper:seekWidgetByName(node, "ip")
        ip:setPositionY(ip:getPositionY() + 60)
    end

    playLastBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local NativeUtil = require("common.NativeUtil")
            if NativeUtil:getAbility("speex") then
                print("播放上一条语音")
                EventBus:dispatchEvent(EventEnum.playOneLast, {index = self.index})
            else
                commonlib.showLocalTip("体验新功能，需要下载最新的游戏版本安装哦！")
            end
            self:removeFromParent(true)
        end
    end)

    local profile = ProfileManager.GetProfile()
    if not profile then return end

    ----- 是否开启GPS
    local isgps = ccui.Helper:seekWidgetByName(node, "Panel_3")
    local nogps = ccui.Helper:seekWidgetByName(node, "Panel_4")
    nogps:setVisible(false)
    if pcall(commonlib.GetMaxLenString, user.nickname, 14) then
        ccui.Helper:seekWidgetByName(node, "name"):setString(commonlib.GetMaxLenString(user.nickname, 14) or "未知")
    else
        ccui.Helper:seekWidgetByName(node, "name"):setString(user.nickname or "未知")
    end
    ccui.Helper:seekWidgetByName(node, "ID"):setString(user.user_id or "未知")
    ccui.Helper:seekWidgetByName(node, "lab_yanbaoshu2"):setString(profile.card or 0)
    ccui.Helper:seekWidgetByName(node, "IP"):setString(user.ip or "未知")
    ccui.Helper:seekWidgetByName(node, "head"):downloadImg(user.photo, g_wxhead_addr)

    -- if rtn_msg.people_num ~= 4 then
    --     ccui.Helper:seekWidgetByName(node,"Panel_24"):setVisible(false)
    -- end

    for i, v in ipairs(rtn_msg.player_ui) do
        if #rtn_msg.player_ui < 4 then
            ccui.Helper:seekWidgetByName(node, "Panel_24"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "Panel_25"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "Panel_26"):setVisible(false)
        elseif #rtn_msg.player_ui < 5 then
            ccui.Helper:seekWidgetByName(node, "Panel_25"):setVisible(false)
            ccui.Helper:seekWidgetByName(node, "Panel_26"):setVisible(false)
        end
        if not v.user or v.user == user then
            ccui.Helper:seekWidgetByName(node, "Panel_2"..i):setVisible(false)
            if i + 1 <= #rtn_msg.player_ui then
                local x, y = ccui.Helper:seekWidgetByName(node, "Panel_2"..i):getPosition()
                local x1, y1 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 1)):getPosition()
                ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 1)):setPosition(x, y)
                if i + 2 <= #rtn_msg.player_ui then
                    local x2, y2 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 2)):getPosition()
                    ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 2)):setPosition(x1, y1)
                    if i + 3 <= #rtn_msg.player_ui then
                        local x3, y3 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 3)):getPosition()
                        ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 3)):setPosition(x2, y2)
                        if i + 4 <= #rtn_msg.player_ui then
                            ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 4)):setPosition(x3, y3)
                        end
                    end
                end
            end
        else
            local lons  = string.split(v.user.lon, "&")
            local lons2 = string.split(user.lon, "&")
            local dis   = commonlib.distanceLatLon(tonumber(lons[1]), tonumber(v.user.lat), tonumber(lons2[1]), tonumber(user.lat))

            if pcall(commonlib.GetMaxLenString, v.user.nickname, 10) then
                ccui.Helper:seekWidgetByName(node, "id"..i):setString(commonlib.GetMaxLenString(v.user.nickname, 10) or "未知")
            else
                ccui.Helper:seekWidgetByName(node, "id"..i):setString(v.user.nickname or "未知")
            end

            if dis < 5000 then
                dis = math.floor(dis * 0.5)
                ccui.Helper:seekWidgetByName(node, "juli"..i):setString(dis.."米" or "未知")
            elseif dis == 5000 then
                if not lon1 or not lat1 or not lon2 or not lat2 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                elseif lon1 == 0 and lat1 == 0 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                elseif lon2 == 0 and lat2 == 0 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                else
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString(">5千米")
                end
            else
                ccui.Helper:seekWidgetByName(node, "juli"..i):setString(">5千米")
            end
        end
    end
    if rtn_msg.isJZBQ and rtn_msg.isJZBQ == 1 then
        for i = 1, 6 do
            ccui.Helper:seekWidgetByName(node, "tool"..i):setColor(cc.c3b(96, 96, 96))
            ccui.Helper:seekWidgetByName(node, "tool"..i):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    commonlib.showLocalTip("互动表情已被管理员关闭，现不可使用！")
                end
            end)
        end
    else
        for i = 1, 6 do
            ccui.Helper:seekWidgetByName(node, "tool"..i):addTouchEventListener(
                function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        print(i.."@@@@@@@@@")
                        if is_self then
                            commonlib.showLocalTip("不能对自己使用道具")
                        else
                            preSendEmotionTime = preSendEmotionTime or 0
                            local time         = preSendEmotionTime + 10 - os.time()

                            if not gt.bqcount then
                                if time > 0 then
                                    preSendEmotionTime = os.time()
                                    gt.bqcount         = true
                                else
                                    preSendEmotionTime = os.time()
                                end
                                local input_msg = {
                                    cmd      = NetCmd.C2S_ROOM_CHAT_BQ,
                                    to_index = index,
                                    msg_id   = i + 100,
                                }
                                commonlib.echo(input_msg)
                                ymkj.SendData:send(json.encode(input_msg))
                                self:removeFromParent(true)
                            elseif gt.bqcount then
                                if time > 0 then
                                    commonlib.showLocalTip(string.format("操作太频繁了，喝杯茶休息会吧", time))
                                    return
                                else
                                    preSendEmotionTime = os.time()
                                    gt.bqcount         = nil
                                end
                                local input_msg = {
                                    cmd      = NetCmd.C2S_ROOM_CHAT_BQ,
                                    to_index = index,
                                    msg_id   = i + 100,
                                }
                                commonlib.echo(input_msg)
                                ymkj.SendData:send(json.encode(input_msg))
                                self:removeFromParent(true)
                            end
                        end
                    end
                end
            )
        end
    end
    if self.is_self then
        ccui.Helper:seekWidgetByName(node, "Panel_5"):setVisible(false)
    else
        ccui.Helper:seekWidgetByName(node, "Panel_y2"):setVisible(false)
        ccui.Helper:seekWidgetByName(node, "Panel_5"):setVisible(true)
    end

end

function PlayerInfo:createLayerMenuWithMJ(userData, index, is_self, ignoreArr, rtn_msg)
    self.index     = userData.index or 1
    index          = userData.index
    self.is_self   = is_self
    self.ignoreArr = ignoreArr or {}

    local csb  = DTUI.getInstance().csb_DT_UserinfoLayer
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    ccui.Helper:seekWidgetByName(node, "btExit"):addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))

    local playLastBtn = ccui.Helper:seekWidgetByName(node, "playlast")

    if self.is_self then
        playLastBtn:setVisible(false)
    else
        local id = ccui.Helper:seekWidgetByName(node, "id")
        id:setPositionY(id:getPositionY() + 60)
        local ip = ccui.Helper:seekWidgetByName(node, "ip")
        ip:setPositionY(ip:getPositionY() + 60)
    end

    playLastBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local NativeUtil = require("common.NativeUtil")
            if NativeUtil:getAbility("speex") then
                print("播放上一条语音")
                EventBus:dispatchEvent(EventEnum.playOneLast, {index = self.index})
            else
                commonlib.showLocalTip("体验新功能，需要下载最新的游戏版本安装哦！")
            end
            self:removeFromParent(true)
        end
    end)

    local profile = ProfileManager.GetProfile()
    if not profile then return end

    ----- 是否开启GPS
    local isgps = ccui.Helper:seekWidgetByName(node, "Panel_3")
    local nogps = ccui.Helper:seekWidgetByName(node, "Panel_4")
    nogps:setVisible(false)
    if pcall(commonlib.GetMaxLenString, userData.name, 14) then
        ccui.Helper:seekWidgetByName(node, "name"):setString(commonlib.GetMaxLenString(userData.name, 14) or "未知")
    else
        ccui.Helper:seekWidgetByName(node, "name"):setString(userData.name or "未知")
    end
    ccui.Helper:seekWidgetByName(node, "ID"):setString(userData.uid or "未知")
    ccui.Helper:seekWidgetByName(node, "lab_yanbaoshu2"):setString(profile.card or 0)
    ccui.Helper:seekWidgetByName(node, "IP"):setString(userData.ip or "未知")
    ccui.Helper:seekWidgetByName(node, "head"):downloadImg(commonlib.wxHead(userData.head), g_wxhead_addr)

    -- if rtn_msg.people_num ~= 4 then
    --     ccui.Helper:seekWidgetByName(node,"Panel_24"):setVisible(false)
    -- end
    if #rtn_msg.player_ui == 6 then
        for i = 1, 6 do
            ccui.Helper:seekWidgetByName(node, "Panel_2"..i):setPositionY(150 - (i - 1) * 40)
        end
    end
    if #rtn_msg.player_ui < 4 then
        ccui.Helper:seekWidgetByName(node, "Panel_24"):setVisible(false)
        ccui.Helper:seekWidgetByName(node, "Panel_25"):setVisible(false)
        ccui.Helper:seekWidgetByName(node, "Panel_26"):setVisible(false)
    elseif #rtn_msg.player_ui < 5 then
        ccui.Helper:seekWidgetByName(node, "Panel_25"):setVisible(false)
        ccui.Helper:seekWidgetByName(node, "Panel_26"):setVisible(false)
    elseif #rtn_msg.player_ui < 6 then
        ccui.Helper:seekWidgetByName(node, "Panel_26"):setVisible(false)
    end

    for i, v in ipairs(rtn_msg.player_ui) do
        local userDataOther = PlayerData.getPlayerDataByClientID(i)

        if not userDataOther or (userDataOther and userDataOther.uid == userData.uid) then
            ccui.Helper:seekWidgetByName(node, "Panel_2"..i):setVisible(false)
            if i + 1 <= #rtn_msg.player_ui then
                local x, y = ccui.Helper:seekWidgetByName(node, "Panel_2"..i):getPosition()
                local x1, y1 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 1)):getPosition()
                ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 1)):setPosition(x, y)
                if i + 2 <= #rtn_msg.player_ui then
                    local x2, y2 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 2)):getPosition()
                    ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 2)):setPosition(x1, y1)
                    if i + 3 <= #rtn_msg.player_ui then
                        local x3, y3 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 3)):getPosition()
                        ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 3)):setPosition(x2, y2)
                        if i + 4 <= #rtn_msg.player_ui then
                            local x4, y4 = ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 4)):getPosition()
                            ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 4)):setPosition(x3, y3)
                            if i + 5 <= #rtn_msg.player_ui then
                                ccui.Helper:seekWidgetByName(node, "Panel_2" .. (i + 5)):setPosition(x4, y4)
                            end
                        end
                    end
                end
            end
        else
            local lons  = string.split(userDataOther.lon, "&")
            local lons2 = string.split(userData.lon, "&")
            local dis   = commonlib.distanceLatLon(tonumber(lons[1]), tonumber(userDataOther.lat), tonumber(lons2[1]), tonumber(userData.lat))

            if pcall(commonlib.GetMaxLenString, userDataOther.name, 10) then
                ccui.Helper:seekWidgetByName(node, "id"..i):setString(commonlib.GetMaxLenString(userDataOther.name, 10) or "未知")
            else
                ccui.Helper:seekWidgetByName(node, "id"..i):setString(userDataOther.name or "未知")
            end

            if dis < 5000 then
                dis = math.floor(dis * 0.5)
                ccui.Helper:seekWidgetByName(node, "juli"..i):setString(dis.."米" or "未知")
            elseif dis == 5000 then
                if not lon1 or not lat1 or not lon2 or not lat2 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                elseif lon1 == 0 and lat1 == 0 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                elseif lon2 == 0 and lat2 == 0 then
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString("未知")
                else
                    ccui.Helper:seekWidgetByName(node, "juli"..i):setString(">5千米")
                end
            else
                ccui.Helper:seekWidgetByName(node, "juli"..i):setString(">5千米")
            end
        end
    end
    if rtn_msg.isJZBQ and rtn_msg.isJZBQ == 1 then
        for i = 1, 6 do
            ccui.Helper:seekWidgetByName(node, "tool"..i):setColor(cc.c3b(96, 96, 96))
            ccui.Helper:seekWidgetByName(node, "tool"..i):addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    commonlib.showLocalTip("互动表情已被管理员关闭，现不可使用！")
                end
            end)
        end
    else
        for i = 1, 6 do
            ccui.Helper:seekWidgetByName(node, "tool"..i):addTouchEventListener(
                function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        print(i.."@@@@@@@@@")
                        if is_self then
                            commonlib.showLocalTip("不能对自己使用道具")
                        else
                            preSendEmotionTime = preSendEmotionTime or 0
                            local time         = preSendEmotionTime + 10 - os.time()

                            if not gt.bqcount then
                                if time > 0 then
                                    preSendEmotionTime = os.time()
                                    gt.bqcount         = true
                                else
                                    preSendEmotionTime = os.time()
                                end
                                local input_msg = {
                                    cmd      = NetCmd.C2S_ROOM_CHAT_BQ,
                                    to_index = index,
                                    msg_id   = i + 100,
                                }
                                commonlib.echo(input_msg)
                                ymkj.SendData:send(json.encode(input_msg))
                                self:removeFromParent(true)
                            elseif gt.bqcount then
                                if time > 0 then
                                    commonlib.showLocalTip(string.format("操作太频繁了，喝杯茶休息会吧", time))
                                    return
                                else
                                    preSendEmotionTime = os.time()
                                    gt.bqcount         = nil
                                end
                                local input_msg = {
                                    cmd      = NetCmd.C2S_ROOM_CHAT_BQ,
                                    to_index = index,
                                    msg_id   = i + 100,
                                }
                                commonlib.echo(input_msg)
                                ymkj.SendData:send(json.encode(input_msg))
                                self:removeFromParent(true)
                            end
                        end
                    end
                end
            )
        end
    end

    if self.is_self then
        ccui.Helper:seekWidgetByName(node, "Panel_5"):setVisible(false)
    else
        ccui.Helper:seekWidgetByName(node, "Panel_y2"):setVisible(false)
        ccui.Helper:seekWidgetByName(node, "Panel_5"):setVisible(true)
    end

end

return PlayerInfo