--------------------------------------------------------------------------------
-- @Author: wuwei
-- @Date: 2018-11-01
-- @Last Modified by: pplarry@qq.com
-- @Last Modified time: 2018-11-01
-- @Desc: 晋中拐三角逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJJZGSJLogic", MJLogic)

MJLogic.HU_HOST       = 100  -- 庄家
MJLogic.HU_KANZHANG   = 104  -- 坎张(夹中)
MJLogic.HU_BIANZHANG  = 105  -- 边张(边夹)
MJLogic.HU_DIAOZHANG  = 106  -- 吊张(单吊)
MJLogic.HU_MENQING    = 109  -- 门清
MJLogic.HU_DUANYAO    = 110  -- 断幺(胡牌无幺九)
MJLogic.HU_FENGYISE   = 111  -- 风一色(全风牌)
MJLogic.HU_COUYISE    = 112  -- 凑一色(风牌+一色)
MJLogic.HU_PENGPENGHU = 113  -- 碰碰胡(须对倒胡)

MJLogic.HUSCORES = {
    [ MJLogic.HU_HOST       ] = 1,
    [ MJLogic.HU_MENQING    ] = 1,
    [ MJLogic.HU_DUANYAO    ] = 1,
    [ MJLogic.HU_KANZHANG   ] = 1,
    [ MJLogic.HU_BIANZHANG  ] = 1,
    [ MJLogic.HU_DIAOZHANG  ] = 1,
    [ MJLogic.HU_COUYISE    ] = 5,
    [ MJLogic.HU_PENGPENGHU ] = 5,
    [ MJLogic.HU_QIXIAODUI  ] = 9,
    [ MJLogic.HU_QINGYISE   ] = 10,
    [ MJLogic.HU_YITIAOLONG ] = 10,
    [ MJLogic.HU_FENGYISE   ] = 20,
}

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass, liPaiInHand)
    local anGangCards = MJLogic.GetGangPai(hand)
    local jiaGangCards = MJLogic.GetGroupGangpai(hand, group, pass)

    if liPaiInHand then
        -- 因为只能听前杠，所以须保证手中立牌>=1
        for i, v in ipairs(anGangCards) do
            local liPais = table.copyArray(liPaiInHand)
            MJLogic.delete_by_card(liPais, v)
            if #liPais == 0 then
                table.remove(anGangCards, i)
            end
        end

        for i, v in ipairs(jiaGangCards) do
            local liPais = table.copyArray(liPaiInHand)
            MJLogic.delete_card(liPais, {v})
            if #liPais == 0 then
                table.remove(jiaGangCards, i)
            end
        end
    end

    local gangCards = table.copyArray(anGangCards)
    for _, v in ipairs(jiaGangCards) do
        gangCards[#gangCards + 1] = v
    end

    return gangCards, anGangCards, jiaGangCards
end

-- 判断是否可以吃牌(组成顺子)
function MJLogic.CanChi( hand, card, ret, wang)
    return false
end

-- 判断是否可以碰
function MJLogic.CanPeng(hand, out_card, liPaiInHand, huoPaiInHand)
    local duizi = MJLogic.GetDuizi(hand)
    for i, v in ipairs(duizi) do
        if v == out_card then
            if MJLogic.has_card(huoPaiInHand or hand, {out_card, out_card}) then
                return true
            end

            if liPaiInHand and huoPaiInHand then
                local liPais = table.copyArray(liPaiInHand)
                if MJLogic.has_card(huoPaiInHand, {out_card}) then
                    MJLogic.delete_card(liPais, {out_card})
                else
                    MJLogic.delete_card(liPais, {out_card, out_card})
                end
                if #liPais > 0 then
                    return true
                end
            end
        end
    end
    return false
end

-- 判断是否可以杠指定的牌
function MJLogic.CanGang(hand, gangCard, liPaiInHand)
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == gangCard and num == 3 then
            if liPaiInHand then
                local liPais = table.copyArray(liPaiInHand)
                MJLogic.delete_by_card(liPais, gangCard)
                if #liPais > 0 then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end

-- 判断缺门：报听必须缺门,只算万桶条
function MJLogic.judgeQueMen(hand, group, wang)
    local tmpCards = {}
    for _, h in ipairs(hand) do
        if h < 0x31 and h ~= wang then
            tmpCards[#tmpCards + 1] = h
        end
    end
    for _, g in ipairs(group) do
        if g[1] < 0x31 then
            tmpCards[#tmpCards + 1] = g[1]
        end
    end

    if MJLogic.GetHandColor(tmpCards) <= 2 then
        return true
    end
    return false
end

-- 判断是否出牌后可以听牌
function MJLogic.CanOutToTing(hand, group, wang, liPai)
    wang = wang or MJLogic.FAKE_WANG
    local setCard = table.unique(liPai or hand, true)
    for _, v in ipairs(setCard) do
        local new_data = table.copyArray(hand)
        MJLogic.delete_card(new_data, {v})
        new_data[#new_data + 1] = wang
        if MJLogic.JudgeHu(new_data, group, wang) > 0 then
            return true
        end
    end
    return false
end

-- 判断能否听牌
function MJLogic.CanTing(hand, group, wang)
    wang = wang or MJLogic.FAKE_WANG
    local new_data = table.copyArray(hand)
    new_data[#new_data + 1] = wang
    if MJLogic.JudgeHu(new_data, group, wang) > 0 then
        return true
    end
    return false
end

-- 判断是否可以接炮胡
function MJLogic.CanChiHu(hand, group_data, card, wang)
    local new_data = table.copyArray(hand)
    table.insert(new_data, card)
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang) > 0 then
        return true
    end
    return false
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang) > 0 then
        return true
    end
    return false
end

-- 获取听牌列表
function MJLogic.CetTingCards(hand, group, wang)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL) do
        new_data[#new_data + 1] = card
        local hu = MJLogic.JudgeHu(new_data, group, wang)
        if hu > 0 then
            table.insert(ting_cards, card)
        end
        new_data[#new_data] = nil
    end
    return ting_cards
end

-- 七小对
function MJLogic.JudgeHu_Duidui(hand, wang)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if wang then
        local new_data = {}
        local jing_num = 0
        for _, v in ipairs(hand) do
            if v == wang then
                jing_num = jing_num + 1
            else
                new_data[#new_data + 1] = v
            end
        end

        local duizi = MJLogic.GetDuizi(new_data)
        local danPaiCount = 14 - (2 * #duizi + jing_num)
        if jing_num >= danPaiCount then
            return MJLogic.HU_QIXIAODUI
        end
    else
        local duizi = MJLogic.GetDuizi(hand)
        if #duizi == 7 then
            return MJLogic.HU_QIXIAODUI
        end
    end

    return MJLogic.HU_NONE
end

-- 一条龙
function MJLogic.JudgeHu_YITIAOLONG(hand, wang)
    local new_data = {}
    local jing_num = 0
    for _, v in ipairs(hand) do
        if v == wang then
            jing_num = jing_num + 1
        else
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    local color, color_count = MJLogic.GetHandColor(new_data)
    for color, colorCount in pairs(color_count) do -- 对每一种花色进行处理
        if colorCount + jing_num >= 9 and color <= 0x20 then
            local tab1 = {} -- 当前花色中有的牌，每个值只有一张，如两个1万，则这里只有一个1万
            local tab2 = {} -- 除去tab1中的所有其它牌
            for _, k in ipairs(new_data) do
                if MJLogic.GetColor(k) == color and not MJLogic.in_array_obj(tab1, k) then
                    table.insert(tab1, k)
                else
                    table.insert(tab2, k)
                end
            end
            if #tab1 + jing_num >= 9 then -- 可组成一条龙
                local thecolor = color

                -- 多余的耗子加到tab2中
                local add_jing_num = jing_num - (9 - #tab1)
                if wang and add_jing_num > 0 then
                    for i = 1, add_jing_num do
                        table.insert(tab2, wang)
                    end
                end

                if MJLogic.JudgeHu_Normal(tab2, wang) ~= MJLogic.HU_NONE then
                    return MJLogic.HU_YITIAOLONG
                end
            end
        end
    end

    return MJLogic.HU_NONE
end

-- 清一色
function MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    local new_data = {}
    for _, v in ipairs(hand) do
        if v ~= wang then
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    local cur_color = -1
    for _, v in ipairs(new_data) do
        local color = MJLogic.GetColor(v)
        if cur_color ~= -1 and cur_color ~= color then
            return MJLogic.HU_NONE
        end
        cur_color = color
    end

    if group and #group > 0 then
        for _, g in ipairs(group) do
            local color = MJLogic.GetColor(g[1])
            if cur_color ~= color then
                return MJLogic.HU_NONE
            end
        end
    end

    return MJLogic.HU_QINGYISE
end

-- 判断是否是夹胡(砍胡)
function MJLogic.JudgeHu_JIAHU(hand, wang, hu_card)
    -- 胡牌是花牌的夹胡为单调夹
    if hu_card >= 0x31 then
        return true
    end

    local new_data = table.copyArray(hand)
    MJLogic.delete_card(new_data, {hu_card}) -- 删掉手里胡的牌

    for _, card in ipairs(MJLogic.CARD_ALL) do
        if card ~= hu_card then
            new_data[#new_data + 1] = card
            if MJLogic.JudgeHu_Normal(new_data, wang) > 0 then
                return false
            end
            new_data[#new_data] = nil
        end
    end

    return true
end

-- 砍胡(胡单张，包括夹中、单调、边夹)
function MJLogic.JudgeHu_KANHU(hand, wang, hu_card, isDaiKanSuanKan)
    local delCards = {}

    delCards[MJLogic.HU_DIAOZHANG] = {hu_card, hu_card} -- 单调

    if #hand > 4 and hu_card < 0x31 then
        local value = MJLogic.GetValue(hu_card)
        if value > 1 and value < 9 then
            delCards[MJLogic.HU_KANZHANG] = {hu_card-1, hu_card, hu_card+1} -- 夹中
            if value == 3 then
                delCards[MJLogic.HU_BIANZHANG] = {hu_card-2, hu_card-1, hu_card} -- 边3
            elseif value == 7 then
                delCards[MJLogic.HU_BIANZHANG] = {hu_card, hu_card+1, hu_card+2} -- 边7
            end
        end
    end

    for hu_type, cards in pairs(delCards) do
        if MJLogic.has_card(hand, cards) then
            local new_data = table.copyArray(hand)
            MJLogic.delete_card(new_data, cards)
            local hasJiang = hu_type == MJLogic.HU_DIAOZHANG
            if MJLogic.JudgeHu_Normal(new_data, wang, hasJiang) > 0 then
                if isDaiKanSuanKan or MJLogic.JudgeHu_JIAHU(hand, wang, hu_card) then
                    return hu_type
                end
            end
        end
    end

    return MJLogic.HU_NONE
end

-- 门清：组牌不能有吃碰或明杠
function MJLogic.JudgeHu_MENQING(hand, group)
    if group and #group > 0 then
        for _, g in ipairs(group) do
            if #g < 4 then -- 吃、碰
                return MJLogic.HU_NONE
            elseif g[5] ~= 2 then -- 非暗杠
                return MJLogic.HU_NONE
            end
        end
    end

    return MJLogic.HU_MENQING
end

-- 碰碰胡：4组刻牌和1对将，且胡的牌不是将牌
function MJLogic.JudgeHu_PENGPENGHU(hand, group, hu_card)
    -- 只能对倒胡，不能手把一
    if #hand < 5 then
        return MJLogic.HU_NONE
    end

    -- 不能有吃
    if group and #group > 0 then
        for _, g in ipairs(group) do
            if g[1] ~= g[2] then
                return MJLogic.HU_NONE
            end
        end
    end

    -- 手里只有刻子和1个对子，且胡的牌不是对子牌
    local handCount = MJLogic.GetHandCount(hand)
    local hasJiang = false
    for card, num in pairs(handCount) do
        if num == 1 or num == 4 then
           return MJLogic.HU_NONE
        elseif num == 2 then
            if hasJiang or card == hu_card then
                return MJLogic.HU_NONE
            end
            hasJiang = true
        end
    end

    return MJLogic.HU_PENGPENGHU
end

-- 断幺：手牌、组牌无幺九、花牌
function MJLogic.JudgeHu_DUANYAO(hand, group)
    if group and #group > 0 then
        for _, g in ipairs(group) do
            -- 若是第一张不是风牌
            if g[1] < 0x31 then
                local value1 = MJLogic.GetValue(g[1])
                if value1 == 1 or value1 == 9 then
                    return MJLogic.HU_NONE
                end

                -- 若是吃，判断后面两张牌
                if g[2] ~= g[1] then
                    local value2 = MJLogic.GetValue(g[2])
                    if value2 == 1 or value2 == 9 then
                        return MJLogic.HU_NONE
                    end

                    local value3 = MJLogic.GetValue(g[3])
                    if value3 == 1 or value3 == 9 then
                        return MJLogic.HU_NONE
                    end
                end
            else
                return MJLogic.HU_NONE
            end
        end
    end

    for _, card in ipairs(hand) do
        if card < 0x31 then
            local value = MJLogic.GetValue(card)
            if value == 1 or value == 9 then
                return MJLogic.HU_NONE
            end
        else
            return MJLogic.HU_NONE
        end
    end

    return MJLogic.HU_DUANYAO
end

-- 凑一色/风一色
function MJLogic.JudgeHu_CFYISE(hand, group, wang)
    local hasFeng = false
    local wanTiaoTong = {}

    for _, card in ipairs(hand) do
        if card < 0x31 then
            if card ~= wang then
                wanTiaoTong[#wanTiaoTong + 1] = card
            end
        else
            hasFeng = true
        end
    end

    if group and #group > 0 then
        for _, g in ipairs(group) do
            if g[1] < 0x31 then
                wanTiaoTong[#wanTiaoTong + 1] = g[1]
            else
                hasFeng = true
            end
        end
    end

    if hasFeng then
        if #wanTiaoTong > 0 then
            local colorCount = MJLogic.GetHandColor(wanTiaoTong)
            if colorCount == 1 then
                return MJLogic.HU_COUYISE
            end
        else
            return MJLogic.HU_FENGYISE
        end
    end

    return MJLogic.HU_NONE
end

function MJLogic.JudgeHuTypes(hand, group, wang, hu_card, isDaiKanSuanKan)
    local types = {}

    -- 清一色
    local hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    end

    -- 凑一色/风一色：和断幺冲突
    hu_type = MJLogic.JudgeHu_CFYISE(hand, group, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    else
        -- 断幺
        hu_type = MJLogic.JudgeHu_DUANYAO(hand, group)
        if hu_type > 0 then
            types[#types + 1] = hu_type
        end
    end

    -- 七小对：不算门清、碰碰胡、一条龙、坎胡
    hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    else
        -- 门清
        hu_type = MJLogic.JudgeHu_MENQING(hand, group)
        if hu_type > 0 then
            types[#types + 1] = hu_type
        end

        -- 碰碰胡：不算一条龙、坎胡
        hu_type = MJLogic.JudgeHu_PENGPENGHU(hand, group, hu_card)
        if hu_type > 0 then
            types[#types + 1] = hu_type
        else
            -- 一条龙
            hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, wang)
            if hu_type > 0 then
                types[#types + 1] = hu_type
            end

            -- 砍胡
            hu_type = MJLogic.JudgeHu_KANHU(hand, wang, hu_card, isDaiKanSuanKan)
            if hu_type > 0 then
                table.insert(types, hu_type)
            end
        end
    end

    return types
end

function MJLogic.JudgeHu(hand, group, wang)
    -- 判断缺门
    if not MJLogic.judgeQueMen(hand, group, wang) then
        return MJLogic.HU_NONE
    end

    -- 判断七对
    local hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
    if hu_type > 0 then
        return hu_type
    end

    return MJLogic.JudgeHu_Normal(hand, wang)
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang, hasJiang)
    local jiang = hasJiang and 1 or 0 -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local arr = {}

    -- 这里要放入所有的牌，因为下面顺子的处理会用到当前牌的前后张数量
    for i, v in ipairs(MJLogic.CARD_ALL) do
        arr[v] = 0
    end
    for i, v in ipairs(hand) do
        if v == wang then
            jing_num = jing_num + 1
        else
            if v < MJLogic.CARD_FLAG then
                arr[v] = arr[v] + 1
            else
                arr[v - MJLogic.CARD_FLAG] = arr[v - MJLogic.CARD_FLAG] + 1
            end
            remainCardCount = remainCardCount + 1
        end
    end

    local function NormalHu()
        -- 递归退出条件：如果没有剩牌，则胡牌返回
        if jiang == 1 and remainCardCount == 0 then
            return 1
        end

        for i, num in MJLogic.pairsByKeys(arr) do
            local value = MJLogic.GetValue(i) -- 当前牌处理：分别组成将刻子顺子

            -- 顺子
            if i < 0x31 and value < 8 and arr[i+1] > 0 and arr[i+2] > 0 then
                arr[i] = arr[i] - 1
                arr[i+1] = arr[i+1] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 3
                if NormalHu() == 1 then return 1 end
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                arr[i+2] = arr[i+2] + 1
                remainCardCount = remainCardCount + 3
            end

            -- 刻子
            if arr[i] >= 3 then
                arr[i] = arr[i] - 3
                remainCardCount = remainCardCount - 3
                if NormalHu() == 1 then return 1 end
                arr[i] = arr[i] + 3
                remainCardCount = remainCardCount + 3
            end

            -- 将
            if jiang == 0 and arr[i] >= 2 then
                jiang = 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then return 1 end
                jiang = 0
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 刻子,用一张精
            if jing_num >= 1 and arr[i] == 2 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 顺子,顺子中间一张用精
            if i < 0x31 and jing_num >= 1 and value < 8 and arr[i+2] > 0 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 1
                arr[i+2] = arr[i+2] + 1
                remainCardCount = remainCardCount + 2
            end

            -- 顺子,顺子最后一张用精
            if i < 0x31 and jing_num >= 1 and value < 9 and arr[i+1] > 0 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 1
                arr[i+1] = arr[i+1] - 1
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                remainCardCount = remainCardCount + 2
            end

            -- 将,用一张精
            if jiang == 0 and jing_num >= 1 and arr[i] == 1 then
                jing_num = jing_num - 1
                jiang = 1
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 1
                jiang = 0
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
            end

            return 0
        end
    end

    if NormalHu() == 1 then
        return MJLogic.HU_NORMAL
    else
        return MJLogic.HU_NONE
    end
end

return MJLogic
