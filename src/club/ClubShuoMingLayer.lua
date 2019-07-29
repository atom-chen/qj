require('club.ClubHallUI')

local ClubShuoMingLayer = class("ClubShuoMingLayer", function()
    return cc.Node:create()
end)

function ClubShuoMingLayer:create(args)
    local layer = ClubShuoMingLayer.new()
    layer:setName('ClubShuoMingLayer')
    layer.club_room_info = args.club_room_info
    layer:createLayerMenu()
    return layer
end

function ClubShuoMingLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_shuo_ming_node
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node

    self.tShuoMing = ccui.Helper:seekWidgetByName(node, "tShuoMing")
    self.tShuoMing:setColor(cc.c3b(255, 255, 255))
    self:setShuoMing(self.club_room_info)
end

function ClubShuoMingLayer:setShuoMing(club_room_info)
    local params = club_room_info.params

    local qipai_type = params.qipai_type
    local str        = ''
    if qipai_type == "mj_tdh" then
        str = self:getMjTdhParams(params, club_room_info)
    elseif qipai_type == "mj_kd" then
        str = self:getMjKdParams(params, club_room_info)
    elseif qipai_type == "mj_xian" then
        str = self:getMjXaParams(params, club_room_info)
    elseif qipai_type == "pk_pdk" then
        str = self:getPdkParams(params, club_room_info)
    elseif qipai_type == "pk_ddz" then
        str = self:getDdzParams(params, club_room_info)
    elseif qipai_type == "mj_lisi" then
        str = self:getLsParams(params, club_room_info)
    elseif qipai_type == 'mj_gsj' then
        str = self:getGsjParams(params, club_room_info)
    elseif qipai_type == "mj_jz" then
        str = self:getJzParams(params, club_room_info)
    elseif qipai_type == "mj_jzgsj" then
        str = self:getJzGsjParams(params, club_room_info)
    elseif qipai_type == 'mj_hebei' then
        str = self:getMjHBParams(params, club_room_info)
    elseif qipai_type == 'mj_hbtdh' then
        str = self:getMjHBTdhParams(params, club_room_info)
    elseif qipai_type == 'mj_dbz' then
        str = self:getMjBDDbzParams(params, club_room_info)
    elseif qipai_type == 'pk_zgz' then
        str = self:getZgzParams(params, club_room_info)
    elseif qipai_type == 'mj_fn' then
        str = self:getFnParams(params, club_room_info)
    elseif qipai_type == 'pk_jdpdk' then
        str = self:getJdpdkParams(params, club_room_info)
    end
    self.tShuoMing:setString(str or '')
    local ImgShuoMing  = ccui.Helper:seekWidgetByName(self.node, "ImgShuoMing")
    local shuoming_lbl = ImgShuoMing
    local shuoming_txt = self.tShuoMing

    local shuoming_lbl_size = shuoming_lbl:getContentSize()
    local shuoming_txt_size = shuoming_txt:getContentSize()
    if shuoming_txt_size.height + 20 > shuoming_lbl_size.height then
        shuoming_lbl:setContentSize(cc.size(shuoming_lbl_size.width, shuoming_txt_size.height + 20))
        shuoming_txt:setPositionY(shuoming_txt_size.height + 10)
    end
end

function ClubShuoMingLayer:getPeopleNum(club_room_info)
    local status     = club_room_info.status
    local people_num = club_room_info.params.people_num
    if status == 1 then
        people_num = club_room_info.people_num
    end
    people_num = people_num or 4
    return people_num
end

function ClubShuoMingLayer:getMjTdhParams(params, club_room_info)
    local room_info = params
    local game_name = '推倒胡\n'

    local str        = ''
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    str              = str..room_info.total_ju.."局" .. people_num .. "人\n"
    -- 报听-- 带风-- 只可自摸-- 改变听口不能扛-- 随机耗子-- 大胡-- 平胡
    str             = str .. (room_info.isBaoTing and '报听\n' or '')
    str             = str .. (room_info.isDaiFeng and '带风\n' or '')
    str             = str .. (room_info.isZhiKeZiMo and '只可自摸\n' or '')
    str             = str .. (room_info.isGBTKBNG and '改变听口不能杠\n' or '')
    str             = str .. (room_info.isSJHZ and '随机耗子\n' or '')
    str             = str .. (room_info.isDaHu and '大胡\n' or '')
    str             = str .. (room_info.isPingHu and '平胡\n' or '')
    str             = str .. (room_info.isQueYiMen and '缺一门\n' or '')
    str             = str .. (room_info.isHPBXQM and '胡牌必须缺门\n' or '')
    str             = str .. (room_info.isYHQ and '硬豪七\n' or '')
    str             = str .. (room_info.isGSHZ and '杠随胡走\n' or '')

    if room_info.isPiaoFen then
        if room_info.isPiaoFen > 0 and room_info.isPiaoFen <= 10 then
            str = str .. '定飘' .. room_info.isPiaoFen .. '分\n'
        elseif room_info.isPiaoFen == 101 then
            str = str .. '飘123\n'
        elseif room_info.isPiaoFen == 102 then
            str = str .. '飘235\n'
        elseif room_info.isPiaoFen == 103 then
            str = str .. '飘258\n'
        end
    end

    if room_info.rTGT then
        str = str .. '超时托管' .. room_info.rTGT .. '秒\n'
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

function ClubShuoMingLayer:getMjKdParams(params, club_room_info)
    local room_info = params
    local game_name = '抠点\n'

    local str        = ''
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n"
    else
        str = str..room_info.total_ju.."局\n"
    end
    str = str .. (people_num or 4) .. "人\n"
    str = str .. (room_info.isQYSYTLJF and '清一色加番\n一条龙加番\n' or '')
    str = str .. (room_info.isZhouHaoZi and '捉耗子\n' or '')
    str = str .. (room_info.isFengHaoZi and '风耗子\n' or '')

    str = str .. ((not room_info.isZhouHaoZi and not room_info.isFengHaoZi) and '无耗子\n' or '')

    str = str .. (room_info.isDaiZhuang and '带庄\n' or '')
    str = str .. (room_info.isZMZFFB and '自摸庄分翻倍\n' or '')
    str = str .. (room_info.isGBTKBNG and '改变听口不能杠\n' or '')
    str = str .. (room_info.isFengZuiZi and '风嘴子\n' or '')
    str = str .. (room_info.isDGBG and '点杠包杠\n' or '')
    str = str .. (room_info.isDPBG and '点炮包杠\n' or '')
    str = str .. (room_info.isKHQDBJF and '可胡七对不加番\n' or '')
    str = str .. (room_info.isHZDDBXZM and '耗子单吊\n必须自摸\n' or '')
    str = str .. (room_info.isQueYiMen and '缺一门\n' or '')
    str = str .. (room_info.isFSF and '番上番\n' or '')
    str = str .. (room_info.isDHJD and '大胡加点\n' or '')
    str = str .. (room_info.is3DKT and '3点可听\n' or '')
    str = str .. (room_info.isYHBH and '有胡必胡\n' or '')

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

function ClubShuoMingLayer:getMjXaParams(params, club_room_info)
    local room_info = params
    local game_name = '西安麻将\n'

    local str        = nil
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n" .. (people_num or 4) .. "人\n"
    else
        str = str..room_info.total_ju.."局\n" .. (people_num or 4) .. "人\n"
    end
    str = str .. (room_info.isZhiKeZiMo == 1 and '只可自摸\n' or '')
    str = str .. (room_info.isXiaPaoZi == 1 and '下炮子\n' or '')
    str = str .. (room_info.is258Jiang == 1 and '258硬将\n' or '')
    str = str .. (room_info.isHongZhong == 1 and '红中癞子\n' or '')
    str = str .. (room_info.isDaiFeng == 1 and '带风\n' or '')
    str = str .. (room_info.isQingYiSe == 1 and '清一色\n' or '')
    str = str .. (room_info.isHu258Fan == 1 and '胡258加番\n' or '')
    str = str .. (room_info.isJiang258Fan == 1 and '将258加番\n' or '')
    str = str .. (room_info.canHuQiDui == 1 and '可胡七对不加番\n' or '')
    str = str .. (room_info.canHuQiDui == 2 and '可胡七对加番\n' or '')
    str = str .. (room_info.isQueYiMen == 1 and '缺一门\n' or '')

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

function ClubShuoMingLayer:getPdkParams(params)
    local room_info = params
    local game_name = '跑得快\n'

    local str = game_name .. room_info.people_num.."人玩\n"
    str       = str..room_info.total_ju.."局\n"
    if room_info.poke_type == 1 then
        str = str.."16张牌\n"
    elseif room_info.poke_type == 2 then
        str = str.."15张牌\n"
    elseif room_info.poke_type == 3 then
        str = str.."切四张牌\n"
    end
    if room_info.chu_san == 1 then
        str = str.."首出必带红桃3\n"
    end
    if room_info.host_type == 1 then
        str = str.."赢家当庄\n"
    elseif room_info.host_type == 3 then
        str = str.."轮流当庄\n"
    else
        str = str.."红桃3当庄\n"
    end
    if room_info.has_houzi == 1 then
        str = str.."抓鸟(红桃10)\n"
    end
    if room_info.qiang_guan == 1 then
        str = str.."不可强关\n"
    end
    if room_info.zha_chai == 1 then
        str = str.."不拆炸弹\n"
    end
    if room_info.bdbcd == 1 then
        str = str.."报单必出大\n"
    end
    if room_info.piaoniao and room_info.piaoniao == 1 then
        str = str.."飘分\n"
    end

    if room_info.pzfd and room_info.pzfd == 8 then
        str = str.."8张封顶\n"
    end

    if room_info.sdyd and room_info.sdyd == 1 then
        str = str.."三带一对\n"
    end

    if room_info.sadzd and room_info.sadzd == 1 then
        str = str.."3A当炸弹\n"
    end

    if room_info.zddp and room_info.zddp == 2 then
        str = str.."四带三\n"
    end

    if room_info.zddp and room_info.zddp == 1 then
        str = str.."四带二\n"
    end

    if room_info.zddp and room_info.zddp == 0 then
        str = str.."不可带\n"
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

function ClubShuoMingLayer:getDdzParams(params)
    local room_info = params
    local game_name = '斗地主\n'

    local str = game_name .. room_info.people_num.."人玩\n"
    str       = str..room_info.total_ju.."局\n"
    if room_info.host_type == 1 then
        str = str.."赢家坐庄\n"
    elseif room_info.host_type == 2 then
        str = str.."轮流坐庄\n"
    else
        str = str.."随机坐庄\n"
    end

    if room_info.difen == 1 then
        str = str.."一分底\n"
    elseif room_info.difen == 2 then
        str = str.."二分底\n"
    else
        str = str.."三分底\n"
    end

    if room_info.max_zhai == 8 then
        str = str.."3炸\n"
    elseif room_info.max_zhai == 16 then
        str = str.."4炸\n"
    elseif room_info.max_zhai == 32 then
        str = str.."5炸\n"
    else
        str = str.."不封顶\n"
    end

    if room_info.left_show == 1 then
        str = str.."牌数显示\n"
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

function ClubShuoMingLayer:getLsParams(params, club_room_info)
    local room_info = params
    local game_name = '立四麻将\n'

    local str        = nil
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n" .. (people_num or 4) .. "人\n"
    else
        str = str..room_info.total_ju.."局\n" .. (people_num or 4) .. "人\n"
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

function ClubShuoMingLayer:getGsjParams(params, club_room_info)
    local room_info = params
    local game_name = '拐三角\n'

    local str        = nil
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n"
    else
        str = str..room_info.total_ju.."局\n"
    end
    str = str .. (people_num or 3) .. "人\n"
    str = str .. (room_info.isQiXiaoDui and '七小对\n' or '')
    str = str .. (room_info.is13Yao and '十三幺\n' or '')
    str = str .. (room_info.isYing8Zhang and '硬八张\n' or '')
    str = str .. (room_info.isZiMoIfPass and '(过胡后\n只能自摸)\n' or '')
    str = str .. (room_info.isDanDiaoKan and '吊张算砍胡\n' or '')
    str = str .. (room_info.isDaiKanSuanKan and '带砍算砍胡\n' or '')
    str = str .. (room_info.diFen and room_info.diFen .. '分\n' or '')
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

function ClubShuoMingLayer:getJzParams(params, club_room_info)
    local room_info = params
    local game_name = '晋中麻将\n'

    local str        = nil
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n" .. (people_num or 4) .. "人\n"
    else
        str = str..room_info.total_ju.."局\n" .. (people_num or 4) .. "人\n"
    end

    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙\n' or '')
    str = str .. (room_info.isLiuJuGenGang and '流局跟杠\n' or '')
    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸\n' or '')
    str = str .. (room_info.is13Yao and '十三幺\n' or '')
    str = str .. (room_info.isCanHuanGang and '可缓杠\n' or '')
    str = str .. (room_info.isPassPeng and '过手碰\n' or '')

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

function ClubShuoMingLayer:getJzGsjParams(params, club_room_info)
    local room_info = params
    local game_name = '晋中拐三角\n'

    local str        = nil
    str              = game_name
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈\n" .. (people_num or 3) .. "人\n"
    else
        str = str..room_info.total_ju.."局\n" .. (people_num or 3) .. "人\n"
    end

    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸\n' or '')
    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙\n' or '')
    str = str .. (room_info.isDaiKanSuanKan and '带砍算砍胡\n' or '')
    str = str .. (room_info.isLiSi and '立四张\n' or '')

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

function ClubShuoMingLayer:getJuAndPersonNums(str, room_info, club_room_info)
    local str        = str
    local people_num = self:getPeopleNum(club_room_info)
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju - 100) .. "圈." .. (people_num or 3) .. "人\n"
    else
        str = str..room_info.total_ju.."局." .. (people_num or 3) .. "人\n"
    end

    return str
end

function ClubShuoMingLayer:getRoomType(room_info, club_room_info)
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

function ClubShuoMingLayer:getMjHBParams(params, club_room_info)
    local room_info  = params
    local game_name = '河北麻将\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info, club_room_info)

    str = str .. (room_info.isDaiZhuang and '带庄闲\n' or '')
    str = str .. (room_info.isDaiFeng and '带风玩法\n' or '')
    str = str .. (room_info.isCanChiPai and '可吃牌\n' or '')
    str = str .. (room_info.isSuiJiWang and '随机癞子\n' or '')
    str = str .. (room_info.isMenQing and '门清\n' or '')
    str = str .. (room_info.isZhuo5Kui and '捉五魁\n' or '')
    str = str .. (room_info.isDaDiaoChe and '大吊车\n' or '')
    str = str .. (room_info.isHaiDiLaoYue and '海底捞月\n' or '')
    str = str .. (room_info.isHuaLong and '花龙\n' or '')
    str = str .. (room_info.isYiPaoDuoHu and '可一炮多响\n' or '')
    str = str .. (room_info.isDGBG and '点杠包杠\n' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubShuoMingLayer:getMjHBTdhParams(params, club_room_info)
    local room_info  = params
    local game_name = '河北推倒胡\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info, club_room_info)

    str = str .. (room_info.isDaHu and '大胡\n' or '')
    str = str .. (room_info.isPingHu and '平胡\n' or '')
    str = str .. (room_info.isBTDGBB and '报听点杠不包\n' or '')
    str = str .. (room_info.isDaiFeng and '带风\n' or '')
    str = str .. (room_info.isBaoTing and '报听\n' or '')
    str = str .. (room_info.isChiPai and '可吃牌\n' or '')
    str = str .. (room_info.isHZLZ and '红中癞子\n' or '')
    str = str .. (room_info.isZhiKeZiMo and '只可自摸胡\n' or '')
    str = str .. (room_info.isQueYiMen and '缺一门\n' or '')
    str = str .. (room_info.isYPDX and '可一炮多响\n' or '')
    str = str .. (room_info.isBBTBHBG and '不报听包胡包杠\n' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubShuoMingLayer:getMjBDDbzParams(params, club_room_info)
    local room_info  = params
    local game_name = '保定打八张\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info, club_room_info)
    str = str .. (room_info.isDPXB and '点炮小包\n' or '')
    str = str .. (room_info.isDPDB and '点炮大包\n' or '')
    str = str .. (room_info.isDPSJC and '点炮三家出\n' or '')
    str = str .. (room_info.isDaiZhuangXian and '带庄闲\n' or '')
    str = str .. (room_info.isDaiFeng and '带风\n' or '')
    str = str .. (room_info.isChiPai and '吃牌\n' or '')
    str = str .. (room_info.isYPDX and '一炮多响\n' or '')
    str = str .. (room_info.isGenZhuang and '跟庄\n' or '')
    str = str .. (room_info.isKouPai and '扣牌\n' or '')
    str = str .. (room_info.isDaJiang and '大将\n' or '')
    str = str .. (room_info.isKouPaiKeJian and '扣牌可见\n' or '')
    str = str .. (room_info.isYingBaZhang and '硬八张\n' or '')
    str = str .. (room_info.isGuoShouPeng and '过手碰\n' or '')
    str = str .. (room_info.isGSHZ and '杠随胡走\n' or '')
    str = str .. (room_info.isSSZLJ and '十四张流局\n' or '')
    str = str .. "底分" .. room_info.iDiFeng .. "分\n"

    if room_info.iFengDing == 0 then
        str = str .. "不封顶\n"
    else
        str = str .. room_info.iFengDing .. "分封顶\n"
    end

    str = str..self:getRoomType(room_info)

    return str
end

function ClubShuoMingLayer:getZgzParams(params, club_room_info)
    local room_info = params
    local game_name = '扎股子\n'

    local str = nil
    str       = game_name

    str = self:getJuAndPersonNums(str, room_info, club_room_info)
    str = str .. ((room_info.zhuo_hong_san) and '捉红三\n' or '')
    str = str .. ((room_info.sheng_pai) and '显示剩牌\n' or '')
    str = str .. ((room_info.isHSPR) and '黑三骗人\n' or '')
    str = str .. ((room_info.isHSJF) and '黑三加分\n' or '')
    str = str .. ((room_info.isBLFKS) and '必亮方块三\n' or '')
    str = str .. ((room_info.isPTWF) and '普通玩法\n' or '')
    str = str .. ((room_info.isZHYGBD) and '最后一股不打\n' or '')
    str = str .. ((room_info.isJDFG) and '经典风格\n' or '流行风格\n')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubShuoMingLayer:getFnParams(params,club_room_info)
    local room_info = params
    local game_name = '丰宁麻将\n'

    local str = nil
    str = game_name

    str = self:getJuAndPersonNums(str,room_info,club_room_info)

    str  = str .. ('底分:' .. room_info.iDiFeng .. '\n')
    if room_info.iPaoFen == 0 then
        str  = str .. ('不跑分\n')
    else
        str  = str .. ('跑分:' .. room_info.iPaoFen .. '\n')
    end
    str  = str .. (room_info.isDaiZhuangXian and '带庄闲\n' or '')
    str  = str .. (room_info.isQiShouHua and '起手花\n' or '')
    str  = str .. (room_info.isZhiKeZiMo and '只可自摸\n' or '')
    str  = str .. (room_info.isBGYJP and '补杠一家赔\n' or '')
    str  = str .. (room_info.isDaiFeng and '带风牌\n' or '')
    str  = str .. (room_info.isMPQT and '摸牌前推\n' or '')
    str  = str .. (room_info.isCPHT and '出牌后推\n' or '')
    str  = str .. (room_info.isGSHZ and '杠随胡走\n' or '')
    str  = str .. (room_info.isGHGL and '过胡过轮\n' or '')
    str  = str .. (room_info.isZKZM and '只可自摸\n' or '')

    str = str..self:getRoomType(room_info)

    return str
end

function ClubShuoMingLayer:getJdpdkParams(params,club_room_info)
    local room_info = params
    local game_name = '经典跑得快\n'

    local str = game_name .. room_info.people_num.."人玩\n"
    str       = str..room_info.total_ju.."局\n"

    if room_info.chu_san == 1 then
        str = str.."首出必带红桃3\n"
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

return ClubShuoMingLayer