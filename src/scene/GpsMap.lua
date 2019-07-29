local Gps = {}


function Gps.showMap(parent,people_num,is_click_see)
    -- GPS
    local node = tolua.cast(cc.CSLoader:createNode("ui/"..people_num.."dizhi.csb"), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 85001)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local bg = ccui.Helper:seekWidgetByName(node, "bg")
    --local minScale = math.min(g_visible_size.width/1280,g_visible_size.height/720)
    --bg:setScale(minScale)

    local neighbor = {}
    if people_num == 2 then
        neighbor[1] = {3}
        neighbor[3] = {}
    else
        neighbor[1] = {2, 4}
        if people_num == 4 then
            neighbor[2] = {3,4}
            neighbor[3] = {4}
            neighbor[4] = {}
        else
            neighbor[2] = {4}
            neighbor[4] = {}
        end
    end

    for i, v in ipairs(parent.player_ui) do
        --本地位置的index UI
        local play_ui = ccui.Helper:seekWidgetByName(node, "play"..math.min(i, people_num))
        if v.user then
            -- 设置头像
            tolua.cast(play_ui:getChildByName("Image_8"), "ccui.ImageView"):downloadImg(v.user.photo, g_wxhead_addr)
            -- 设置昵称
            if pcall(commonlib.GetMaxLenString, v.user.nickname, 8) then
                tolua.cast(ccui.Helper:seekWidgetByName(play_ui,"Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(v.user.nickname, 8))
            else
                tolua.cast(play_ui:getChildByName(play_ui,"Text_2"), "ccui.Text"):setString(v.user.nickname)
            end
            -- IP
            tolua.cast(play_ui:getChildByName("ip"), "ccui.Text"):setString(v.user.ip)
            local lons = string.split(v.user.lon, "&")
            -- 地址
            tolua.cast(play_ui:getChildByName("weizhi"), "ccui.Text"):setString(lons[2] and "" or "未取到精确位置\n(或未开启定位)")

            for __, ii in ipairs(neighbor[i] or {}) do
                local neighbor_index = math.min(ii, people_num)
                -- 用户 和 用户信息
                log(ii)
                 --log(parent.player_ui)
                -- log(parent.player_ui[ii].user)
                if parent.player_ui[ii] and parent.player_ui[ii].user then
                    local lons2 = string.split(parent.player_ui[ii].user.lon, "&")
                    local dis = commonlib.distanceLatLon(tonumber(lons[1]), tonumber(v.user.lat), tonumber(lons2[1]), tonumber(parent.player_ui[ii].user.lat))
                    if dis < 5000 then dis = math.floor(dis*0.5) end
                    local strIpWarn = ""
                    if v.user.ip == parent.player_ui[ii].user.ip then
                        strIpWarn = "\nIP相同"
                    end
                    local strPrefix = ""
                    if i==2 and neighbor_index == 4 then
                        strPrefix = "左右两家"
                    end
                    if dis >= 5000 then
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setString(strPrefix.."相距5千米以上"..strIpWarn)
                    else
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setString(strPrefix.."相距约"..dis.."米"..strIpWarn)
                    end
                    ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(true)
                    if strIpWarn ~= "" or dis <= 300 then
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setColor(cc.c3b(228, 81,54))
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/1-fs8.png")
                    else
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setColor(cc.c3b(17,200,8))
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/2-fs8.png")
                    end
                else
                    ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                    ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
                end
            end
        elseif neighbor[i] then
            for __, ii in ipairs(neighbor[i] or {}) do
                local neighbor_index = math.min(ii, people_num)
                ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
            end
            play_ui:setVisible(false)
        end
    end

    if is_click_see then
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setTouchEnabled(false)
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setBright(false)
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setVisible(false)
        ccui.Helper:seekWidgetByName(node,"btn-tongyijiesan"):setVisible(false)
    else
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
                    -- print("cancel")
                    node:removeFromParent(true)
                    -- 房主解散房间
                    if parent.is_fangzhu then
                        local input_msg = {
                            cmd =NetCmd.C2S_JIESAN,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    else
                        -- 非房主退出房间
                        local input_msg = {
                            cmd =NetCmd.C2S_LEAVE_ROOM,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end

                end
            end)
    end

    ccui.Helper:seekWidgetByName(node,"btn-tongyijiesan"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
                -- 继续游戏
                if not is_click_see then
                    if parent.xiapaozi_mode then
                        if parent.xiapaozi_mode == false then
                            parent:sendReady()
                        else
                            parent.jiesanroom:setVisible(false)
                            parent:disapperClubInvite(true)
                            parent.xiapaozi_panel:setVisible(true)
                            parent.xiapaozi_panel:setEnabled(true)
                            commonlib.showShareBtn(parent.share_list)
                        end
                        return
                    end
                    if parent.isPiaoFen then
                        parent.pnPiaoFen:setVisible(true)
                        parent.pnPiaoFen:setEnabled(true)
                        commonlib.showbtn(parent.jiesanroom)
                        commonlib.showShareBtn(parent.share_list)
                        return
                    end
                    parent:sendReady()
                end
            end
        end
    )

    if is_click_see then
        ccui.Helper:seekWidgetByName(node,"Panel_1"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    node:removeFromParent(true)
                end
            end
        )
    end
end

function Gps.mjShowMap(parent,people_num,is_click_see)
    -- GPS
    local node = tolua.cast(cc.CSLoader:createNode("ui/"..people_num.."dizhi.csb"), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999, 85001)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local bg = ccui.Helper:seekWidgetByName(node, "bg")
    --local minScale = math.min(g_visible_size.width/1280,g_visible_size.height/720)
    --bg:setScale(minScale)

    local neighbor = {}
    if people_num == 2 then
        neighbor[1] = {3}
        neighbor[3] = {}
    else
        neighbor[1] = {2, 4}
        if people_num == 4 then
            neighbor[2] = {3,4}
            neighbor[3] = {4}
            neighbor[4] = {}
        else
            neighbor[2] = {4}
            neighbor[4] = {}
        end
    end

    require('scene.PlayerData')
    print('----------------------------------------')
    print('----------------------------------------')
    print('-----------GPS GET DATA ING-------------')
    print('----------------------------------------')
    print('----------------------------------------')
    print('----------------------------------------')
    print('----------------------------------------')
-- [LUA-print] -         "head"       = "" commonlib.wxHead(userData.head)
-- [LUA-print] -         "index"      = 3
-- [LUA-print] -         "ip"         = "113.247.4.241"
-- [LUA-print] -         "is_ting"    = false
-- [LUA-print] -         "lat"        = "0"
-- [LUA-print] -         "lon"        = "0"
-- [LUA-print] -         "name"       = "win7672"
-- [LUA-print] -         "out_card" = {
-- [LUA-print] -         }
-- [LUA-print] -         "ready"      = true
-- [LUA-print] -         "score"      = 0
-- [LUA-print] -         "sex"        = 1
-- [LUA-print] -         "uid"        = 713006
-- [LUA-print] -         "ver"        = 800000
-- commonlib.wxHead(userData.head)
    for i, v in ipairs(parent.player_ui) do
        --本地位置的index UI
        local play_ui = ccui.Helper:seekWidgetByName(node, "play"..math.min(i, people_num))
        local userData = PlayerData.getPlayerDataByClientID(i)
        if v and userData then
            -- 设置头像
            tolua.cast(play_ui:getChildByName("Image_8"), "ccui.ImageView"):downloadImg(commonlib.wxHead(userData.head), g_wxhead_addr)
            -- 设置昵称
            if pcall(commonlib.GetMaxLenString, userData.name, 8) then
                tolua.cast(ccui.Helper:seekWidgetByName(play_ui,"Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(userData.name, 8))
            else
                tolua.cast(play_ui:getChildByName(play_ui,"Text_2"), "ccui.Text"):setString(userData.name)
            end
            -- IP
            tolua.cast(play_ui:getChildByName("ip"), "ccui.Text"):setString(userData.ip)
            local lons = string.split(userData.lon, "&")
            -- 地址
            tolua.cast(play_ui:getChildByName("weizhi"), "ccui.Text"):setString(lons[2] and "" or "未取到精确位置\n(或未开启定位)")

            for __, ii in ipairs(neighbor[i] or {}) do
                local neighbor_index = math.min(ii, people_num)
                -- 用户 和 用户信息
                log(ii)
                 --log(parent.player_ui)
                -- log(parent.player_ui[ii].user)
                local userDataii = PlayerData.getPlayerDataByClientID(ii)
                if parent.player_ui[ii] and userDataii then
                    local lons2 = string.split(userDataii.lon, "&")
                    local dis = commonlib.distanceLatLon(tonumber(lons[1]), tonumber(userData.lat), tonumber(lons2[1]), tonumber(userDataii.lat))
                    if dis < 5000 then dis = math.floor(dis*0.5) end
                    local strIpWarn = ""
                    if userData.ip == userDataii.ip then
                        strIpWarn = "\nIP相同"
                    end
                    local strPrefix = ""
                    if i==2 and neighbor_index == 4 then
                        strPrefix = "左右两家"
                    end
                    if dis >= 5000 then
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setString(strPrefix.."相距5千米以上"..strIpWarn)
                    else
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setString(strPrefix.."相距约"..dis.."米"..strIpWarn)
                    end
                    ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(true)
                    if strIpWarn ~= "" or dis <= 300 then
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setColor(cc.c3b(228, 81,54))
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/1-fs8.png")
                    else
                        ccui.Helper:seekWidgetByName(node,"xiangju"..i..neighbor_index):setColor(cc.c3b(17,200,8))
                        ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):loadTexture("ui/xclub/2-fs8.png")
                    end
                else
                    ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                    ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
                end
            end
        elseif neighbor[i] then
            for __, ii in ipairs(neighbor[i] or {}) do
                local neighbor_index = math.min(ii, people_num)
                ccui.Helper:seekWidgetByName(node, "xiangju"..i..neighbor_index):setString("")
                ccui.Helper:seekWidgetByName(node, "line"..i..neighbor_index):setVisible(false)
            end
            play_ui:setVisible(false)
        end
    end

    if is_click_see then
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setTouchEnabled(false)
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setBright(false)
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):setVisible(false)
        ccui.Helper:seekWidgetByName(node,"btn-tongyijiesan"):setVisible(false)
    else
        ccui.Helper:seekWidgetByName(node,"btn-butongyi"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then    AudioManager:playPressSound()
                    -- print("cancel")
                    node:removeFromParent(true)
                    -- 房主解散房间
                    if parent.is_fangzhu then
                        local input_msg = {
                            cmd =NetCmd.C2S_JIESAN,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    else
                        -- 非房主退出房间
                        local input_msg = {
                            cmd =NetCmd.C2S_LEAVE_ROOM,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end

                end
            end)
    end

    ccui.Helper:seekWidgetByName(node,"btn-tongyijiesan"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                node:removeFromParent(true)
                -- 继续游戏
                if not is_click_see then
                    if parent.xiapaozi_mode then
                        if parent.xiapaozi_mode == false then
                            parent:sendReady()
                        else
                            parent.jiesanroom:setVisible(false)
                            parent:disapperClubInvite(true)
                            parent.xiapaozi_panel:setVisible(true)
                            parent.xiapaozi_panel:setEnabled(true)
                            commonlib.showShareBtn(parent.share_list)
                        end
                        return
                    end
                    parent:sendReady()
                end
            end
        end
    )

    if is_click_see then
        ccui.Helper:seekWidgetByName(node,"Panel_1"):addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    node:removeFromParent(true)
                end
            end
        )
    end
end

return Gps