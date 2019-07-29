require('club.ClubHallUI')

local cmd_list = {

}

local ClubInviteDialog = class("ClubInviteDialog", function()
    return cc.Layer:create()
end)

function ClubInviteDialog:create(args)
    local layer = ClubInviteDialog.new()
    print('invite')
    -- dump(args)
    layer.room_id   = args.room_id
    layer.club_name = args.club_name
    layer.name      = args.name
    layer.room_info = args.room_info
    layer:createLayerMenu()
    layer:setName('ClubInviteDialog')
    layer:setLocalZOrder(200)
    return layer
end

function ClubInviteDialog:registerEventListener()

    local function rspCallback(custom_event)
        local event_name = custom_event:getEventName()
        print("rtn:"..event_name.." success")
        local rtn_msg = custom_event:getUserData()
        if not rtn_msg or rtn_msg == "" then return end
        rtn_msg = json.decode(rtn_msg)
        commonlib.echo(rtn_msg)
        -- if rtn_msg.cmd == NetCmd.S2C_CLUB_IDLE_PLAYERS then
        --     self.player_list = rtn_msg.idleUsers
        --     self:refreshInvite()
        -- end
    end

    for __, v in ipairs(cmd_list) do
        local listenerRsp = cc.EventListenerCustom:create(v, rspCallback)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listenerRsp, 1)
    end

    -- local function onNodeEvent(event)
    --     if event == "exitTransitionStart" then
    --         self:unregisterEventListener()
    --     end
    -- end
    -- self:registerScriptHandler(onNodeEvent)
end

function ClubInviteDialog:unregisterEventListener()
    for __, v in ipairs(cmd_list) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(v)
    end
end

function ClubInviteDialog:exitLayer()
    -- self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubInviteDialog:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_invite_dialog
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node

    -- 头像
    ccui.Helper:seekWidgetByName(node, "Img-TX"):downloadImg(commonlib.wxHead(self.room_info and self.room_info.player_info and self.room_info.player_info.head or ''))

    -- 羽儿，邀请您加入'赌博'的亲友圈2号桌
    local szInvite    = nil
    local strName     = self.name
    local strClubName = self.club_name
    if pcall(commonlib.GetMaxLenString, self.name, 14) and pcall(commonlib.GetMaxLenString, self.club_name, 12) then
        strName     = commonlib.GetMaxLenString(self.name, 14)
        strClubName = commonlib.GetMaxLenString(self.club_name, 12)
    end
    szInvite = string.format('%s，邀请您加入\'%s\'的亲友圈%d号桌', strName, strClubName, self.room_info.club_index)
    ccui.Helper:seekWidgetByName(node, "tInvite"):setString(szInvite)

    self:setShuoMing(self.room_info)

    local btnExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btnExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print('btnExit')
            self:exitLayer()
        end
    end)

    local btnRefuse = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-refuse"), "ccui.Button")
    btnRefuse:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print('btnRefuse')
            self:exitLayer()
        end
    end)

    local clientIp = gt.getClientIp()

    local btnAgreen = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-agreen"), "ccui.Button")
    btnAgreen:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            print('btnAgreen')
            local net_msg = {
                cmd     = NetCmd.C2S_JOIN_ROOM,
                room_id = self.room_id,
                lat     = clientIp[1],
                lon     = clientIp[2],
            }
            ymkj.SendData:send(json.encode(net_msg))
            self:exitLayer()
        end
    end)

    -- self:registerEventListener()

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))
end

function ClubInviteDialog:refreshData(args)
    -- dump(args)
    self.room_id   = args.room_id
    self.club_name = args.club_name
    self.name      = args.name
    self.room_info = args.room_info

    -- 头像
    ccui.Helper:seekWidgetByName(self.node, "Img-TX"):downloadImg(commonlib.wxHead(''))

    -- 羽儿，邀请您加入'赌博'的亲友圈2号桌
    local szInvite = string.format('%s，邀请您加入‘%s’的亲友圈桌子进行游戏', self.name, self.club_name)
    ccui.Helper:seekWidgetByName(self.node, "tInvite"):setString(szInvite)

    self:setShuoMing(self.room_info)
end

function ClubInviteDialog:setShuoMing(club_room_info)

    local params     = club_room_info
    local qipai_type = params.qipai_type

    local str = ''
    if qipai_type == "mj_tdh" then
        str = self:getMjTdhParams(params)
    elseif qipai_type == "mj_kd" then
        str = self:getMjKdParams(params)
    elseif qipai_type == "mj_xian" then
        str = self:getMjXaParams(params)
    elseif qipai_type == "pk_pdk" then
        str = self:getPdkParams(params)
    elseif qipai_type == "pk_ddz" then
        str = self:getDdzParams(params)
    elseif qipai_type == "mj_lisi" then
        str = self:getLsParams(params)
    elseif qipai_type == "mj_gsj" then
        str = self:getGsjParams(params)
    elseif qipai_type == 'mj_jz' then
        str = self:getJzParams(params)
    elseif qipai_type == "mj_jzgsj" then
        str = self:getJzGsjParams(params)
    elseif qipai_type == 'mj_hebei' then
        str = self:getMjHBParams(params)
    elseif qipai_type == 'mj_hbtdh' then
        str = self:getMjHBTdhParams(params)
    elseif qipai_type == 'mj_dbz' then
        str = self:getMjBDDbzParams(params)
    elseif qipai_type == "pk_zgz" then
        str = self:getZgzParams(params)
    elseif qipai_type == "mj_fn" then
        str = self:getFnParams(params)
    elseif qipai_type == "pk_jdpdk" then
        str = self:getJdpdkParams(params)
    end

    ccui.Helper:seekWidgetByName(self.node, "tRule"):setString('规则：' .. str)
end

function ClubInviteDialog:getMjTdhParams(params)
    local room_info = params
    local game_name = '推倒胡,'

    local str = ''
    str       = game_name
    str       = str..room_info.total_ju.."局" .. (room_info.people_num or 4) .. "人,"
    -- 报听-- 带风-- 只可自摸-- 改变听口不能扛-- 随机耗子-- 大胡-- 平胡
    str       = str .. (room_info.isBaoTing and '报听,' or '')
    str       = str .. (room_info.isDaiFeng and '带风,' or '')
    str       = str .. (room_info.isZhiKeZiMo and '只可自摸,' or '')
    str       = str .. (room_info.isGBTKBNG and '改变听口不能杠,' or '')
    str       = str .. (room_info.isSJHZ and '随机耗子,' or '')
    str       = str .. (room_info.isDaHu and '大胡,' or '')
    str       = str .. (room_info.isPingHu and '平胡,' or '')
    str       = str .. (room_info.isQueYiMen and '缺一门,' or '')
    str       = str .. (room_info.isHPBXQM and '胡牌必须缺门' or '')
    str       = str .. (room_info.isYHQ and '硬豪七' or '')
    str       = str .. (room_info.isGSHZ and '杠随胡走' or '')

    if room_info.isPiaoFen then
        if room_info.isPiaoFen > 0 and room_info.isPiaoFen <= 10 then
            str = str .. '定飘' .. room_info.isPiaoFen .. '分'
        elseif room_info.isPiaoFen == 101 then
            str = str .. '飘123'
        elseif room_info.isPiaoFen == 102 then
            str = str .. '飘235'
        elseif room_info.isPiaoFen == 103 then
            str = str .. '飘258'
        end
    end

    if room_info.rTGT and room_info.rTGT ~= 0 then
        str = str .. '超时托管' .. room_info.rTGT .. '秒'
    end
    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getMjKdParams(params)
    local room_info = params
    local game_name = '抠点,'

    local str = ''
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈,"
    else
        str = str..room_info.total_ju.."局,"
    end
    str = str .. (room_info.people_num or 4) .. "人,"
    str = str .. (room_info.isQYSYTLJF and '清一色加番\n一条龙加番,' or '')
    str = str .. (room_info.isZhouHaoZi and '捉耗子,' or '')
    str = str .. (room_info.isFengHaoZi and '风耗子,' or '')

    str = str .. ((not room_info.isZhouHaoZi and not room_info.isFengHaoZi) and '无耗子,' or '')

    str = str .. (room_info.isDaiZhuang and '带庄,' or '')
    str = str .. (room_info.isZMZFFB and '自摸庄分翻倍,' or '')
    str = str .. (room_info.isGBTKBNG and '改变听口不能杠,' or '')
    str = str .. (room_info.isFengZuiZi and '风嘴子,' or '')
    str = str .. (room_info.isDGBG and '点杠包杠,' or '')
    str = str .. (room_info.isDPBG and '点炮包杠,' or '')
    str = str .. (room_info.isKHQDBJF and '可胡七对不加番,' or '')
    str = str .. (room_info.isHZDDBXZM and '耗子单吊必须自摸,' or '')
    str = str .. (room_info.isQueYiMen and '缺一门,' or '')
    str = str .. (room_info.isFSF and '番上番,' or '')
    str = str .. (room_info.isDHJD and '大胡加点,' or '')
    str = str .. (room_info.is3DKT and '3点可听,' or '')
    str = str .. (room_info.isYHBH and '有胡必胡,' or '')

    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getMjXaParams(params)
    local room_info = params
    local game_name = '西安麻将,'

    local str = nil
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈," .. (room_info.people_num or 4) .. "人,"
    else
        str = str..room_info.total_ju.."局," .. (room_info.people_num or 4) .. "人,"
    end
    str = str .. (room_info.isZhiKeZiMo and '只可自摸,' or '')
    str = str .. (room_info.isXiaPaoZi and '下炮子,' or '')
    str = str .. (room_info.is258Jiang and '258硬将,' or '')
    str = str .. (room_info.isHongZhong and '红中癞子,' or '')
    str = str .. (room_info.isDaiFeng and '带风,' or '')
    str = str .. (room_info.isQingYiSe and '清一色,' or '')
    str = str .. (room_info.isHu258Fan and '胡258加番,' or '')
    str = str .. (room_info.isJiang258Fan and '将258加番,' or '')
    str = str .. (room_info.canHuQiDui == 1 and '可胡七对不加番,' or '')
    str = str .. (room_info.canHuQiDui == 2 and '可胡七对加番,' or '')
    str = str .. (room_info.isQueYiMen and '缺一门,' or '')

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getPdkParams(params)
    local room_info = params
    local game_name = '跑得快,'

    local str = game_name .. room_info.people_num.."人玩,"
    str       = str..room_info.total_ju.."局,"
    if room_info.poke_type == 1 then
        str = str.."16张牌,"
    elseif room_info.poke_type == 2 then
        str = str.."15张牌,"
    elseif room_info.poke_type == 3 then
        str = str.."切四张牌,"
    end
    if room_info.chu_san == 1 then
        str = str.."首出必带红桃3,"
    end
    if room_info.host_type == 1 then
        str = str.."赢家当庄,"
    elseif room_info.host_type == 3 then
        str = str.."轮流当庄,"
    else
        str = str.."红桃3当庄,"
    end
    if room_info.has_houzi == 1 then
        str = str.."抓鸟(红桃10),"
    end
    if room_info.qiang_guan == 1 then
        str = str.."不可强关,"
    end
    if room_info.zha_chai == 1 then
        str = str.."不拆炸弹,"
    end

    if room_info.bdbcd == 1 then
        str = str.."报单必出大,"
    end

    if room_info.piaoniao and room_info.piaoniao == 1 then
        str = str.."飘分,"
    end

    if room_info.pzfd and room_info.pzfd == 8 then
        str = str.."8张封顶,"
    end

    if room_info.sdyd and room_info.sdyd == 1 then
        str = str.."三带一对,"
    end

    if room_info.sadzd and room_info.sadzd == 1 then
        str = str.."3A当炸弹,"
    end

    if room_info.zddp and room_info.zddp == 2 then
        str = str.."四带三,"
    end

    if room_info.zddp and room_info.zddp == 1 then
        str = str.."四带二,"
    end

    if room_info.zddp and room_info.zddp == 0 then
        str = str.."不可带,"
    end

    if room_info.zdbsf and room_info.zdbsf == 1 then
        str = str .. '炸弹不算分.'
    end

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getDdzParams(params)
    local room_info = params
    local game_name = '斗地主,'

    local str = game_name .. room_info.people_num.."人玩,"
    str       = str..room_info.total_ju.."局,"
    if room_info.host_type ~= 2 then
        str = str.."赢家当庄,"
    else
        str = str.."轮流坐庄,"
    end

    if room_info.difen == 1 then
        str = str.."一分底,"
    elseif room_info.difen == 2 then
        str = str.."二分底,"
    else
        str = str.."三分底,"
    end

    if room_info.max_zhai == 8 then
        str = str.."3炸,"
    elseif room_info.max_zhai == 16 then
        str = str.."4炸,"
    elseif room_info.max_zhai == 32 then
        str = str.."5炸,"
    else
        str = str.."不封顶,"
    end

    if room_info.left_show == 1 then
        str = str.."牌数显示,"
    end

    if room_info.people_num == 3 then
        if room_info.jiaofen == 10 then
            str = str.."5/10分\n"
        else
            str = str.."1/2/3分\n"
        end
        if room_info.can_jiabei == 1 then
            str = str.."可加倍\n"
        end
    else
        if room_info.rpfd == 1 then
            str = str .. "让牌1倍\n"
        elseif room_info.rpfd == 4 then
            str = str .. "让牌4倍\n"
        elseif room_info.rpfd == 8 then
            str = str .. "让牌8倍\n"
        else
            str = str .. "让牌16倍\n"
        end
    end

    if room_info.isFDBHCT == 1 then
        str = str.."封顶包含春天\n"
    end

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getLsParams(params)
    local room_info = params
    local game_name = '立四麻将,'

    local str = nil
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈," .. (room_info.people_num or 4) .. "人,"
    else
        str = str..room_info.total_ju.."局," .. (room_info.people_num or 4) .. "人,"
    end

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getGsjParams(params)
    local room_info = params
    local game_name = '拐三角\n'

    local str = nil
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈."
    else
        str = str..room_info.total_ju.."局."
    end

    str = str .. (room_info.people_num or 3) .. "人."
    str = str .. (room_info.isQiXiaoDui and '七小对.' or '')
    str = str .. (room_info.is13Yao and '十三幺.' or '')
    str = str .. (room_info.isYing8Zhang and '硬八张.' or '')
    str = str .. (room_info.isZiMoIfPass and '过胡后只能自摸.' or '')
    str = str .. (room_info.isDanDiaoKan and '吊张算砍胡.' or '')
    str = str .. (room_info.isDaiKanSuanKan and '带砍算砍胡.' or '')
    str = str .. (room_info.diFen and room_info.diFen .. '分.' or '')
    str = str .. (room_info.isQueYiMen and '缺一门\n' or '')

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getJzParams(params)
    local room_info = params
    local game_name = '晋中\n'

    local str = nil
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈."
    else
        str = str..room_info.total_ju.."局."
    end

    str = str .. (room_info.people_num or 4) .. "人."
    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙.' or '')
    str = str .. (room_info.isLiuJuGenGang and '流局跟杠.' or '')
    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸.' or '')
    str = str .. (room_info.is13Yao and '十三幺.' or '')
    str = str .. (room_info.isCanHuanGang and '可缓杠.' or '')
    str = str .. (room_info.isPassPeng and '过手碰.' or '')

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getJzGsjParams(params)
    local room_info = params
    local game_name = '晋中拐三角\n'

    local str = nil
    str       = game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈." .. (room_info.people_num or 3) .. "人."
    else
        str = str..room_info.total_ju.."局." .. (room_info.people_num or 3) .. "人."
    end

    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸.' or '')
    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙.' or '')
    str = str .. (room_info.isDaiKanSuanKan and '带砍算砍胡.' or '')
    str = str .. (room_info.isLiSi and '立四张.' or '')

    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function ClubInviteDialog:getJuAndPersonNums(str, room_info)
    local str = str
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈." .. (room_info.people_num or 3) .. "人."
    else
        str = str..room_info.total_ju.."局." .. (room_info.people_num or 3) .. "人."
    end

    return str
end

function ClubInviteDialog:getRoomType(room_info)
    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    return room_type
end

function ClubInviteDialog:getMjHBParams(params)
    local room_info  = params
    local game_name = '河北麻将.'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info)

    str = str .. (room_info.isDaiZhuang and '带庄闲.' or '')
    str = str .. (room_info.isDaiFeng and '带风玩法.' or '')
    str = str .. (room_info.isCanChiPai and '可吃牌.' or '')
    str = str .. (room_info.isSuiJiWang and '随机癞子.' or '')
    str = str .. (room_info.isMenQing and '门清.' or '')
    str = str .. (room_info.isZhuo5Kui and '捉五魁.' or '')
    str = str .. (room_info.isDaDiaoChe and '大吊车.' or '')
    str = str .. (room_info.isHaiDiLaoYue and '海底捞月.' or '')
    str = str .. (room_info.isHuaLong and '花龙.' or '')
    str = str .. (room_info.isYiPaoDuoHu and '可一炮多响.' or '')
    str = str .. (room_info.isDGBG and '点杠包杠.' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubInviteDialog:getMjHBTdhParams(params)
    local room_info  = params
    local game_name = '河北推倒胡\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info)

    str = str .. (room_info.isDaHu and '大胡.' or '')
    str = str .. (room_info.isPingHu and '平胡.' or '')
    str = str .. (room_info.isBTDGBB and '报听点杠不包\n' or '')
    str = str .. (room_info.isDaiFeng and '带风.' or '')
    str = str .. (room_info.isBaoTing and '报听.' or '')
    str = str .. (room_info.isChiPai and '可吃牌.' or '')
    str = str .. (room_info.isHZLZ and '红中癞子.' or '')
    str = str .. (room_info.isZhiKeZiMo and '只可自摸胡.' or '')
    str = str .. (room_info.isQueYiMen and '缺一门.' or '')
    str = str .. (room_info.isYPDX and '可一炮多响.' or '')
    str = str .. (room_info.isBBTBHBG and '不报听包胡包杠.' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubInviteDialog:getMjBDDbzParams(params)
    local room_info  = params
    local game_name = '保定打八张\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info)

    str = str .. (room_info.isDPXB and '点炮小包.' or '')
    str = str .. (room_info.isDPDB and '点炮大包.' or '')
    str = str .. (room_info.isDPSJC and '点炮三家出.' or '')
    str = str .. (room_info.isDaiZhuangXian and '带庄闲.' or '')
    str = str .. (room_info.isDaiFeng and '带风.' or '')
    str = str .. (room_info.isChiPai and '吃牌.' or '')
    str = str .. (room_info.isYPDX and '一炮多响.' or '')
    str = str .. (room_info.isGenZhuang and '跟庄.' or '')
    str = str .. (room_info.isKouPai and '扣牌.' or '')
    str = str .. (room_info.isDaJiang and '大将.' or '')
    str = str .. (room_info.isKouPaiKeJian and '扣牌可见.' or '')
    str = str .. (room_info.isYingBaZhang and '硬八张.' or '')
    str = str .. (room_info.isGuoShouPeng and '过手碰.' or '')
    str = str .. (room_info.isGSHZ and '杠随胡走.' or '')
    str = str .. (room_info.isSSZLJ and '十四张流局.' or '')
    str = str .. "底分" .. room_info.iDiFeng .. "分."

    if room_info.iFengDing == 0 then
        str = str .. "不封顶."
    else
        str = str .. room_info.iFengDing .. "分封顶."
    end

    str = str..self:getRoomType(room_info)

    return str
end

function ClubInviteDialog:getZgzParams(params)
    local room_info  = params
    local game_name = '扎股子\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info)

    str = str .. ((room_info.zhuo_hong_san) and '捉红三' or '')
    str = str .. ((room_info.sheng_pai) and '显示剩牌' or '')
    str = str .. ((room_info.isHSPR) and '黑三骗人' or '')
    str = str .. ((room_info.isHSJF) and '黑三加分' or '')
    str = str .. ((room_info.isBLFKS) and '必亮方块三' or '')
    str = str .. ((room_info.isPTWF) and '普通玩法' or '')
    str = str .. ((room_info.isZHYGBD) and '最后一股不打' or '')
    str = str .. ((room_info.isJDFG) and '经典风格' or '流行风格')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubInviteDialog:getFnParams(params)
   local room_info = params
    local game_name = '丰宁麻将\n'

    local str = nil
    str = game_name

    str = self:getJuAndPersonNums(str,room_info)
    str  = str .. ('底分:' .. room_info.iDiFeng .. '.')
    if room_info.iPaoFen == 0 then
        str  = str .. ('不跑分' .. '.')
    else
        str  = str .. ('跑分:' .. room_info.iPaoFen .. '.')
    end
    str  = str .. ((room_info.isDaiZhuangXian) and '带庄闲.' or '')
    str  = str .. ((room_info.isQiShouHua) and '起手花.' or '')
    str  = str .. ((room_info.isZhiKeZiMo) and '只可自摸.' or '')
    str  = str .. ((room_info.isBGYJP) and '补杠一家赔.' or '')
    str  = str .. ((room_info.isDaiFeng) and '带风牌.' or '')
    str  = str .. ((room_info.isCPHT) and '出牌后推.' or '')
    str  = str .. ((room_info.isGSHZ) and '杠随胡走.' or '')
    str  = str .. ((room_info.isGHGL) and '过胡过轮.' or '')
    str  = str .. (room_info.isZKZM and '只可自摸.' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubInviteDialog:getJdpdkParams(params)
    local room_info = params
    local game_name = '经典跑得快,'

    local str = game_name .. room_info.people_num.."人玩,"
    str       = str..room_info.total_ju.."局,"
    if room_info.chu_san == 1 then
        str = str.."首出必带红桃3,"
    end
    local room_type = nil
    if room_info.qunzhu == 0 or room_info.qunzhu == 4 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

return ClubInviteDialog