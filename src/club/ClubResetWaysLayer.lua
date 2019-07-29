-- 可以看出服务器传来的参数中对应的哪一种模式
require('club.ClubHallUI')

local ClubResetWaysLayer = class("ClubResetWaysLayer", function()
    return cc.Layer:create()
end)

function ClubResetWaysLayer:create(args)
    local layer          = ClubResetWaysLayer.new()
    layer.club_room_info = args.club_room_info
    layer:createLayerMenu()
    return layer
end

function ClubResetWaysLayer:createLayerMenu()
    local csb  = ClubHallUI.getInstance().csb_club_reset_ways
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.node = node

    local btOk = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-querenEx"), "ccui.Button")
    btOk:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:removeFromParent(true)
        end
    end)

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:removeFromParent(true)
        end
    end)

    self:setShuoMing(self.club_room_info)

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
end

function ClubResetWaysLayer:setShuoMing(club_room_info)
    self.club_room_info = club_room_info

    -- log('params.qipai_type ' .. params.qipai_type)
    -- dump(self.club_room_info)
    local params     = club_room_info.params
    local qipai_type = params.qipai_type
    print('信息来到此处')
    if qipai_type == "mj_tdh" then
        print('推倒胡')
        self:getMjTdhParams(params)
    elseif qipai_type == "mj_kd" then
        print('抠点')
        self:getMjKdParams(params)
    elseif qipai_type == "mj_xian" then
        print('西安麻将')
        self:getMjXaParams(params)
    elseif qipai_type == "pk_pdk" then
        print('跑得快')
        self:getPdkParams(params)
    elseif qipai_type == "pk_ddz" then
        print('斗地主')
        self:getDdzParams(params)
    elseif qipai_type == "mj_lisi" then
        print("立四")
        self:getLsParams(params)
    elseif qipai_type == 'mj_gsj' then
        print('拐三角')
        self:getGsjParams(params)
    elseif qipai_type == 'mj_jz' then
        print('晋中')
        self:getJzParams(params)
    elseif qipai_type == "mj_jzgsj" then
        print('晋中拐三角')
        self:getJzGsjParams(params)
    elseif qipai_type == 'mj_hebei' then
        print('河北麻将')
        self:getMjHBParams(params)
    elseif qipai_type == 'mj_hbtdh' then
        self:getMjHBTdhParams(params)
    elseif qipai_type == 'mj_dbz' then
        self:getMjBDDbzParams(params)
    elseif qipai_type == "pk_zgz" then
        self:getMjZgzParams(params)
    elseif qipai_type == 'mj_fn' then
        self:getMjFnParams(params)
    elseif qipai_type == "pk_jdpdk" then
        self:getJdpdkParams(params)
    end
end

-- 改变其按钮中标题的内容
function ClubResetWaysLayer:setWays(nIndex, str)
    local shouming = ccui.Helper:seekWidgetByName(self.node, 'shouming' .. nIndex)
    if shouming then
        local len = string.len(str)

        local _, count = string.gsub(str, "[^\128-\193]", "")
        print(count)
        print(str .. len)
        if count >= 3 then
            for i = 1, count * 2 + count / 3 do
                str = ' ' .. str
            end
        elseif len > 6 then
            for i = 1, count do
                str = ' ' .. str
            end
        end
        shouming:setTitleText(str)
    end
end

-- 隐藏15个按钮中多余的按钮
function ClubResetWaysLayer:coverShuoming(shouMingIndex)
    for nIndex = shouMingIndex + 1, 15 do
        local shouming = ccui.Helper:seekWidgetByName(self.node, 'shouming' .. nIndex)
        if shouming then
            shouming:setVisible(false)
        end
    end
end

function ClubResetWaysLayer:getMjTdhParams(params)
    local room_info = params
    local game_name = '推倒胡'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, room_info.total_ju.."局")

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isBaoTing then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('报听'))
    end

    if room_info.isDaiFeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带风'))
    end

    if room_info.isZhiKeZiMo then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('只可自摸'))
    end

    if room_info.isGBTKBNG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('改变听口不能杠'))
    end

    if room_info.isSJHZ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('随机耗子'))
    end

    if room_info.isDaHu then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('大胡'))
    end

    if room_info.isPingHu then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('平胡'))
    end

    if room_info.isQueYiMen then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('缺一门'))
    end

    if room_info.isHPBXQM then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('胡牌必须缺门'))
    end

    if room_info.isYHQ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('硬豪七'))
    end

    if room_info.isGSHZ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('杠随胡走'))
    end

    if room_info.isPiaoFen then
        if room_info.isPiaoFen > 0 and room_info.isPiaoFen <= 10 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('定飘' .. room_info.isPiaoFen .. '分'))
        elseif room_info.isPiaoFen == 101 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('飘123'))
        elseif room_info.isPiaoFen == 102 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('飘235'))
        elseif room_info.isPiaoFen == 103 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('飘258'))
        end
    end

    if room_info.rTGT and room_info.rTGT ~= 0 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('超时托管' .. room_info.rTGT .. '秒'))
    end
    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjKdParams(params)
    local room_info = params
    local game_name = '抠点'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isQYSYTLJF then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('清一条龙加番'))
    end

    if room_info.isZhouHaoZi then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('捉耗子'))
    end

    if room_info.isFengHaoZi then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('风耗子'))
    end

    if not room_info.isZhouHaoZi and not room_info.isFengHaoZi then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('无耗子'))
    end

    if room_info.isDaiZhuang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带庄'))
    end

    if room_info.isZMZFFB then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('自摸庄分翻倍'))
    end

    if room_info.isGBTKBNG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('改变听口不能杠'))
    end

    if room_info.isFengZuiZi then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('风嘴子'))
    end

    if room_info.isDGBG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点杠包杠'))
    end

    if room_info.isDPBG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点炮包杠'))
    end

    if room_info.isQueYiMen then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('缺一门'))
    end

    if room_info.isKHQDBJF then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('七对不加番'))
    end

    if room_info.isHZDDBXZM then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('单吊耗子必自摸'))
    end

    if room_info.isFSF then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('番上番'))
    end

    if room_info.isDHJD then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('大胡加点'))
    end

    if room_info.is3DKT then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('3点可听'))
    end

    if room_info.isYHBH then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('有胡必胡'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjXaParams(params)
    local room_info = params
    local game_name = '西安麻将'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isZhiKeZiMo == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('只可自摸'))
    end

    if room_info.isXiaPaoZi == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('下炮子'))
    end

    if room_info.is258Jiang == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('258硬将'))
    end

    if room_info.isHongZhong == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('红中癞子'))
    end

    if room_info.isDaiFeng == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带风'))
    end

    if room_info.isQingYiSe == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('清一色'))
    end

    if room_info.isHu258Fan == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('胡258加番'))
    end

    if room_info.isJiang258Fan == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('将258加番'))
    end

    if room_info.canHuQiDui == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('胡七对不加番'))
    elseif room_info.canHuQiDui == 2 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('胡七对加番'))
    end
    if room_info.isQueYiMen == 1 then
        self:setWays(shouMingIndex, ('缺一门'))
    end
    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getPdkParams(params)
    local room_info = params
    local game_name = '跑得快'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.poke_type == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('16张牌'))
    elseif room_info.poke_type == 2 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('15张牌'))
    elseif room_info.poke_type == 3 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('切四张牌'))
    end

    if room_info.chu_san == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('首出必带红桃3'))
    end

    if room_info.host_type == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('赢家当庄'))
    elseif room_info.host_type == 3 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('轮流当庄'))
    else
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('红桃3当庄'))
    end

    if room_info.has_houzi == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('抓鸟(红桃10)'))
    end

    if room_info.qiang_guan == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('不可强关'))
    end

    if room_info.zha_chai == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('不拆炸弹'))
    end

    if room_info.bdbcd == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('报单必出大'))
    end

    if room_info.piaoniao and room_info.piaoniao == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('飘分'))
    end

    if room_info.pzfd and room_info.pzfd == 8 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('8张封顶'))
    end

    if room_info.sdyd and room_info.sdyd == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('三带一对'))
    end

    if room_info.sadzd and room_info.sadzd == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('3A当炸弹'))
    end

    if room_info.zddp and room_info.zddp == 2 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('四带三'))
    end

    if room_info.zddp and room_info.zddp == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('四带二'))
    end

    if room_info.zddp and room_info.zddp == 0 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('不可带'))
    end

    if room_info.zdbsf and room_info.zdbsf == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('炸弹不算分'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getDdzParams(params)
    local room_info = params
    local game_name = '斗地主'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.host_type == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('赢家坐庄'))
    elseif room_info.host_type == 2 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('轮流坐庄'))
    elseif room_info.host_type == 3 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('随机坐庄'))
    end

    if room_info.difen == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('一分底'))
    elseif room_info.difen == 2 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('二分底'))
    else
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('三分底'))
    end

    if room_info.max_zhai == 8 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('3炸'))
    elseif room_info.max_zhai == 16 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('4炸'))
    elseif room_info.max_zhai == 32 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('5炸'))
    else
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('不封顶'))
    end

    if room_info.left_show == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('牌数显示'))
    end

    if room_info.people_num == 3 then
        if room_info.jiaofen == 10 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('5/10分'))
        else
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('1/2/3分'))
        end
        if room_info.can_jiabei == 1 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('可加倍'))
        end
    else
        if room_info.rpfd == 1 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('让牌1倍'))
        elseif room_info.rpfd == 4 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('让牌4倍'))
        elseif room_info.rpfd == 8 then
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('让牌8倍'))
        else
            shouMingIndex = shouMingIndex + 1
            self:setWays(shouMingIndex, ('让牌16倍'))
        end
    end
    if room_info.isFDBHCT == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('封顶包含春天'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getLsParams(params)
    local room_info = params
    local game_name = '立四麻将'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getGsjParams(params)
    local room_info = params
    local game_name = '拐三角'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 3) .. "人")

    if room_info.isQiXiaoDui then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('七小对'))
    end

    if room_info.is13Yao then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('十三幺'))
    end

    if room_info.isYing8Zhang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('硬八张'))
    end

    if room_info.isZiMoIfPass then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过胡后只能自摸'))
    end

    if room_info.isDanDiaoKan then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('吊张算砍胡'))
    end

    if room_info.isDaiKanSuanKan then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带砍算砍胡'))
    end

    if room_info.diFen then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, (room_info.diFen .. '分'))
    end

    if room_info.isQueYiMen then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('缺一门'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getJzParams(params)
    local room_info = params
    local game_name = '晋中麻将'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isGuoLongHuLong then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过龙只能胡龙'))
    end

    if room_info.isLiuJuGenGang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('流局跟杠'))
    end

    if room_info.isZiMoIfPass then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过胡只能自摸'))
    end

    if room_info.is13Yao then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('十三幺'))
    end

    if room_info.isCanHuanGang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('可缓杠'))
    end

    if room_info.isPassPeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过手碰'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getJzGsjParams(params)
    local room_info = params
    local game_name = '晋中拐三角\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isZiMoIfPass then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过胡只能自摸'))
    end
    if room_info.isGuoLongHuLong then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过龙只能胡龙'))
    end
    if room_info.isDaiKanSuanKan then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带砍算砍胡'))
    end
    if room_info.isLiSi then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('立四张'))
    end
    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjHBParams(params)
    local room_info = params
    local game_name = '河北麻将\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isDaiZhuang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带庄闲'))
    end
    if room_info.isDaiFeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带风玩法'))
    end
    if room_info.isCanChiPai then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('可吃牌'))
    end
    if room_info.isSuiJiWang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('随机癞子'))
    end
    if room_info.isMenQing then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('门清'))
    end
    if room_info.isZhuo5Kui then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('捉五魁'))
    end
    if room_info.isDaDiaoChe then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('大吊车'))
    end
    if room_info.isHaiDiLaoYue then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('海底捞月'))
    end
    if room_info.isHuaLong then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('花龙'))
    end
    if room_info.isYiPaoDuoHu then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('可一炮多响'))
    end
    if room_info.isDGBG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点杠包杠'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjHBTdhParams(params)
    local room_info = params
    local game_name = '河北推倒胡\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.isDaHu then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('大胡'))
    end
    if room_info.isPingHu then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('平胡'))
    end
    if room_info.isBTDGBB then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('报听点杠不包'))
    end
    if room_info.isDaiFeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带风'))
    end
    if room_info.isBaoTing then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('报听'))
    end
    if room_info.isChiPai then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('可吃牌'))
    end
    if room_info.isHZLZ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('红中癞子'))
    end
    if room_info.isZhiKeZiMo then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('只可自摸胡'))
    end
    if room_info.isQueYiMen then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('缺一门'))
    end
    if room_info.isYPDX then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('可一炮多响'))
    end
    if room_info.isBBTBHBG then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('不报听包胡包杠'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjBDDbzParams(params)
    local room_info = params
    local game_name = '保定打八张\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈" .. (room_info.people_num or 4) .. "人")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局" .. (room_info.people_num or 4) .. "人")
    end

    -- shouMingIndex = shouMingIndex + 1
    -- self:setWays(shouMingIndex,(room_info.people_num or 4).."人")

    if room_info.isDPXB then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点炮小包'))
    end
    if room_info.isDPDB then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点炮大包'))
    end
    if room_info.isDPSJC then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('点炮三家出'))
    end
    if room_info.isDaiZhuangXian then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带庄闲'))
    end
    if room_info.isDaiFeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('带风'))
    end
    if room_info.isChiPai then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('吃牌'))
    end
    if room_info.isYPDX then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('一炮多响'))
    end
    if room_info.isGenZhuang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('跟庄'))
    end
    if room_info.isKouPai then
        shouMingIndex = shouMingIndex + 1
        if room_info.isDaJiang then
            self:setWays(shouMingIndex, ('扣牌,大将'))
        else
            self:setWays(shouMingIndex, ('扣牌'))
        end
    end
    -- if room_info.isDaJiang then
    --     shouMingIndex = shouMingIndex + 1
    --     self:setWays(shouMingIndex,('大将'))
    -- end
    if room_info.isKouPaiKeJian then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('扣牌可见'))
    end
    if room_info.isYingBaZhang then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('硬八张'))
    end
    if room_info.isGuoShouPeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('过手碰'))
    end
    if room_info.isGSHZ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('杠随胡走'))
    end
    if room_info.isSSZLJ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('十四张流局'))
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, "底分" .. room_info.iDiFeng .. '分')

    shouMingIndex = shouMingIndex + 1
    if room_info.iFengDing == 0 then
        self:setWays(shouMingIndex, ('不封顶'))
    else
        self:setWays(shouMingIndex, room_info.iFengDing .. '分封顶')
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjZgzParams(params)
    local room_info = params
    local game_name = '扎股子\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.zhuo_hong_san then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('捉红三'))
    end

    if room_info.sheng_pai then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('显示剩牌'))
    end

    if room_info.isHSPR then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('黑三骗人'))
    end

    if room_info.isHSJF then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('黑三加分'))
    end

    if room_info.isBLFKS then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('必亮方块三'))
    end

    if room_info.isPTWF then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('普通玩法'))
    end

    if room_info.isZHYGBD then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('最后一股不打'))
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.isJDFG and '经典风格' or "流行风格"))

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getMjFnParams(params)
    local room_info = params
    local game_name = '丰宁麻将\n'

    local shouMingIndex = 1
    self:setWays(shouMingIndex,game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex,(room_info.total_ju-100).."圈")
    else
        self:setWays(shouMingIndex,room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex,(room_info.people_num or 4).."人")

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex,('底分:' .. room_info.iDiFeng))

    shouMingIndex = shouMingIndex + 1
    if room_info.iPaoFen == 0 then
        self:setWays(shouMingIndex,('不跑分'))
    else
        self:setWays(shouMingIndex,('跑分:' .. room_info.iPaoFen))
    end

    if room_info.isDaiZhuangXian then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('带庄闲'))
    end

    if room_info.isQiShouHua then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('起手花'))
    end

    if room_info.isZhiKeZiMo then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('只可自摸'))
    end

    if room_info.isBGYJP then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('补杠一家赔'))
    end

    if room_info.isDaiFeng then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('带风牌'))
    end

    if room_info.isMPQT then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('摸牌前推'))
    end

    if room_info.isCPHT then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('出牌后推'))
    end

    if room_info.isGSHZ then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('杠随胡走'))
    end

    if room_info.isGHGL then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('过胡过轮'))
    end

    if room_info.isZKZM then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex,('只可自摸'))
    end

    self:coverShuoming(shouMingIndex)
end

function ClubResetWaysLayer:getJdpdkParams(params)
    local room_info = params
    local game_name = '经典跑得快'

    local shouMingIndex = 1
    self:setWays(shouMingIndex, game_name)

    shouMingIndex = shouMingIndex + 1
    if room_info.total_ju > 100 then
        self:setWays(shouMingIndex, (room_info.total_ju - 100) .. "圈")
    else
        self:setWays(shouMingIndex, room_info.total_ju.."局")
    end

    shouMingIndex = shouMingIndex + 1
    self:setWays(shouMingIndex, (room_info.people_num or 4) .. "人")

    if room_info.chu_san == 1 then
        shouMingIndex = shouMingIndex + 1
        self:setWays(shouMingIndex, ('首出必带红桃3'))
    end

    self:coverShuoming(shouMingIndex)
end

return ClubResetWaysLayer