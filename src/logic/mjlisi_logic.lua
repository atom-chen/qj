--------------------------------------------------------------------------------
-- @Author: wuwei
-- @Date: 2018-08-03
-- @Last Modified by: pplarry@qq.com
-- @Last Modified time: 2018-08-03
-- @Desc: 立四麻将逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJLISILogic", MJLogic)

MJLogic.HU_HOST      = 100  -- 庄家
MJLogic.HU_QUEMEN    = 103  -- 缺门(缺一色)
MJLogic.HU_KANZHANG  = 104  -- 坎张(夹中)
MJLogic.HU_BIANZHANG = 105  -- 边张(边夹)
MJLogic.HU_DIAOZHANG = 106  -- 吊张(单吊)
MJLogic.HU_FANGTONG  = 107  -- 放铳(放炮)

MJLogic.HUSCORES = {
    [ MJLogic.HU_HOST       ] = 1,
    [ MJLogic.HU_QUEMEN     ] = 1,
    [ MJLogic.HU_KANZHANG   ] = 1,
    [ MJLogic.HU_BIANZHANG  ] = 1,
    [ MJLogic.HU_DIAOZHANG  ] = 1,
    [ MJLogic.HU_FANGTONG   ] = 1,
    [ MJLogic.HU_YITIAOLONG ] = 10,
    [ MJLogic.HU_QINGYISE   ] = 10,
}

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass, liPaiInHand, is_ting, wang, tingCards)
    local anGangCards = MJLogic.GetGangPai(hand)
    local jiaGangCards = MJLogic.GetGroupGangpai(hand, group, pass)

    -- 没听须保证手中立牌>=1
    if not is_ting then
        for i, v in ipairs(anGangCards) do
            local liPais = table.copyArray(liPaiInHand)
            MJLogic.delete_by_card(liPais, v)
            if #liPais < 1 then
                table.remove(anGangCards, i)
            end
        end

        for i, v in ipairs(jiaGangCards) do
            local liPais = table.copyArray(liPaiInHand)
            MJLogic.delete_card(liPais, {v})
            if #liPais < 1 then
                table.remove(jiaGangCards, i)
            end
        end
    end

    local gangCards = table.copyArray(anGangCards)
    for _, v in ipairs(jiaGangCards) do
        gangCards[#gangCards + 1] = v
    end

    if #gangCards == 0 then
        return gangCards, anGangCards, jiaGangCards
    end

    if not is_ting then
        return gangCards, anGangCards, jiaGangCards
    end

    if is_ting then
        if tingCards and #tingCards > 0 then -- 改变听口不能杠
            local canGangCards = {}
            for _, gangCard in ipairs(gangCards) do
                local new_data = clone(hand)
                if MJLogic.has_card(anGangCards, {gangCard}) then
                    MJLogic.delete_card(new_data, {gangCard, gangCard, gangCard, gangCard})
                else
                    MJLogic.delete_card(new_data, {gangCard})
                end

                local tmpTingCards = {}
                for _, card in ipairs(tingCards) do
                    new_data[#new_data + 1] = card
                    local hu = MJLogic.JudgeHu(new_data, group, wang)
                    if hu > 0 then
                        table.insert(tmpTingCards, card)
                    end
                    new_data[#new_data] = nil
                end

                if #tmpTingCards >= #tingCards then
                    canGangCards[#canGangCards + 1] = gangCard
                end
            end
            return canGangCards, anGangCards, jiaGangCards
        else -- 杠后能听
            local canGangCards = {}
            for _, gangCard in ipairs(gangCards) do
                local new_data = clone(hand)
                if MJLogic.has_card(anGangCards, {gangCard}) then
                    MJLogic.delete_card(new_data, {gangCard, gangCard, gangCard, gangCard})
                else
                    MJLogic.delete_card(new_data, {gangCard})
                end

                if MJLogic.CanTing(new_data, group, wang) then
                    canGangCards[#canGangCards + 1] = gangCard
                end
            end
            return canGangCards, anGangCards, jiaGangCards
        end
    end
end

-- 判断是否可以吃牌(组成顺子)
function MJLogic.CanChi( hand, card, ret, wang)
    return false
end

-- 判断是否可以碰(没听须保证手中立牌)
function MJLogic.CanPeng(hand, out_card, liPaiInHand, huoPaiInHand)
    local duizi = MJLogic.GetDuizi(hand)
    for i, v in ipairs(duizi) do
        if v == out_card then
            if MJLogic.has_card(huoPaiInHand, {out_card, out_card}) then
                return true
            end

            local liPais = table.copyArray(liPaiInHand)
            if MJLogic.has_card(huoPaiInHand, {out_card}) then
                MJLogic.delete_card(liPais, {out_card})
            else
                MJLogic.delete_card(liPais, {out_card, out_card})
            end
            if #liPais >= 1 then
                return true
            end
        end
    end
    return false
end

-- 判断是否可以杠指定的牌
function MJLogic.CanGang(hand, gangCard, liPaiInHand, is_ting, wang, tingCards)
    local hasKe = false

    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == gangCard and num == 3 then
            local liPais = table.copyArray(liPaiInHand)
            MJLogic.delete_by_card(liPais, gangCard)
            if is_ting or #liPais >= 1 then
                hasKe = true
            end
            break
        end
    end

    if not hasKe or not is_ting then
        return hasKe
    end

    if is_ting then
        if tingCards and #tingCards > 0 then -- 改变听口不能杠
            local new_data = clone(hand)
            MJLogic.delete_card(new_data, {gangCard, gangCard, gangCard})

            local tmpTingCards = {}
            for _, card in ipairs(tingCards) do
                new_data[#new_data + 1] = card
                local hu = MJLogic.JudgeHu(new_data, {}, wang)
                if hu > 0 then
                    table.insert(tmpTingCards, card)
                end
                new_data[#new_data] = nil
            end

            if #tmpTingCards >= #tingCards then
                return true
            end
        else -- 杠后能听
            local new_data = clone(hand)
            MJLogic.delete_card(new_data, {gangCard, gangCard, gangCard})
            if MJLogic.CanTing(new_data, {}, wang) then
                return true
            end
        end
    end

    return false
end

-- 判断是否出牌后可以听牌
function MJLogic.CanOutToTing(hand, group, wang)
    wang = wang or MJLogic.FAKE_WANG
    local setCard = table.unique(hand, true)
    for i, v in ipairs(setCard) do
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
-- 如果card 为耗子，则要把耗子当普通牌处理，这里将该牌加0x80来和耗子区分。
-- 即如果牌值大于0x80，则该张牌是由其它玩家打的耗子牌，不能当耗子来处理
function MJLogic.CanChiHu(hand, group_data, card, wang)
    local new_data = table.copyArray(hand)
    if card == wang then
        table.insert(new_data, card + MJLogic.CARD_FLAG)
    else
        table.insert(new_data, card)
    end
    local new_data2 = clone(group_data)
    local hu, groupsCards = MJLogic.JudgeHu(new_data, new_data2, wang)
    if hu > 0 then
        return true, groupsCards
    end
    return false, {}
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

-- 一条龙
function MJLogic.JudgeHu_YITIAOLONG(hand, wang, hu_card, hu_types)
    local new_data = {}
    local jing_num = 0
    for i, v in ipairs(hand) do
        if v == wang then
            jing_num = jing_num + 1
        else
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    -- 将要胡的牌放入new_data中，如果hu_card是耗子，则把它当普通牌处理
    table.insert(new_data, hu_card)

    local color, color_count = MJLogic.GetHandColor(new_data)
    for color, colorCount in pairs(color_count) do -- 对每一种花色进行处理
        if colorCount + jing_num >= 9 and color <= 0x20 then
            local tab1 = {} -- 当前花色中有的牌，每个值只有一张，如两个1万，则这里只有一个1万
            local tab2 = {} -- 除去tab1中的所有其它牌
            for j, k in ipairs(new_data) do
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

-- 清一色 (胡牌)
function MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    local new_data = {}
    for i, v in ipairs(hand) do
        if v ~= wang then
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    local cur_color = -1
    for i, v in ipairs(new_data) do
        local color = MJLogic.GetColor(v)
        if cur_color ~= -1 and cur_color ~= color then
            return MJLogic.HU_NONE
        end
        cur_color = color
    end

    if group and #group > 0 then
        for i,v in ipairs(group) do
            for j, vv in ipairs(v) do
                if j <= 4 then
                    local color = MJLogic.GetColor(vv)
                    if cur_color ~= color  then
                        return MJLogic.HU_NONE
                    end
                end
            end
        end
    end

    -- 胡牌
    if MJLogic.JudgeHu_Normal(hand, wang) == MJLogic.HU_NORMAL then
        return MJLogic.HU_QINGYISE
    else
        return MJLogic.HU_NONE
    end
end

function MJLogic.JudgeHuTypes(hand, group, groups, wang, hu_card)
    local types = {}

    local hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, wang)
    if hu_type  > 0 then
        types[#types + 1] = hu_type
    end

    hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    if hu_type  > 0 then
        types[#types + 1] = hu_type
    end

    -- 缺门，(坎张、边张、吊张)[三选一]
    local hasShun = false
    local allCards = table.copyArray(hand)
    for _, g in ipairs(group) do
        if g[1] ~= g[2] then
            hasShun = true
        end

        allCards[#allCards + 1] = g[1]
        allCards[#allCards + 1] = g[2]
        allCards[#allCards + 1] = g[3]
    end

    if MJLogic.GetHandColor(allCards) == 2 then
        types[#types + 1] = MJLogic.HU_QUEMEN
    end

    for _, g in ipairs(groups) do
        if #g == 2 and g[1] == hu_card then
            types[#types + 1] = MJLogic.HU_DIAOZHANG
            break
        elseif #g == 3 then
            if g[1] ~= g[2] then
                hasShun = true
                if g[2] == hu_card then
                    types[#types + 1] = MJLogic.HU_KANZHANG
                    break
                elseif (g[1] == hu_card and MJLogic.GetValue(hu_card) == 7) or (g[3] == hu_card and MJLogic.GetValue(hu_card) == 3) then
                    types[#types + 1] = MJLogic.HU_BIANZHANG
                    break
                end
            end
        end
    end

    return types
end

function MJLogic.JudgeHu(hand, group, wang)
    return MJLogic.JudgeHu_Normal(hand, wang)
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang)
    local jiang = 0 -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local arr = {}
    local groups = {}

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

            -- 将
            if jiang == 0 and arr[i] >= 2 then
                jiang = 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                groups[#groups + 1] = {i, i}
                if NormalHu() == 1 then
                    return 1
                end
                jiang = 0
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
                table_remove(groups, #groups)
            end

            -- 将,用一张精
            if jiang == 0 and jing_num >= 1 and arr[i] == 1 then
                jing_num = jing_num - 1
                jiang = 1
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                groups[#groups + 1] = {i, wang}
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                jiang = 0
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
                table_remove(groups, #groups)
            end

            -- 刻子
            if arr[i] >= 3 then
                arr[i] = arr[i] - 3
                remainCardCount = remainCardCount - 3
                groups[#groups + 1] = {i, i, i}
                if NormalHu() == 1 then
                    return 1
                end
                arr[i] = arr[i] + 3
                remainCardCount = remainCardCount + 3
                table_remove(groups, #groups)
            end

            -- 刻子,用一张精
            if jing_num >= 1 and arr[i] == 2 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                groups[#groups + 1] = {i, i, i}
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
                table_remove(groups, #groups)
            end

            -- 顺子
            if i < 0x31 and value < 8 and arr[i+1] > 0 and arr[i+2] > 0 then
                arr[i] = arr[i] - 1
                arr[i+1] = arr[i+1] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 3
                groups[#groups + 1] = {i, i+1, i+2}
                if NormalHu() == 1 then
                    return 1
                end
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                arr[i+2] = arr[i+2] + 1
                remainCardCount = remainCardCount + 3
                table_remove(groups, #groups)
            end

            -- 顺子,顺子中间一张用精
            if i < 0x31 and jing_num >= 1 and value < 8 and arr[i+2] > 0 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 2
                groups[#groups + 1] = {i, wang, i+2}
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 1
                arr[i+2] = arr[i+2] + 1
                remainCardCount = remainCardCount + 2
                table_remove(groups, #groups)
            end

            -- 顺子,顺子最后一张用精
            if i < 0x31 and jing_num >= 1 and value < 9 and arr[i+1] > 0 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 1
                arr[i+1] = arr[i+1] - 1
                remainCardCount = remainCardCount - 2
                groups[#groups + 1] = {i, i+1, wang}
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                remainCardCount = remainCardCount + 2
                table_remove(groups, #groups)
            end

            return 0
        end
    end

    if NormalHu() == 1 then
        return MJLogic.HU_NORMAL, groups
    else
        return MJLogic.HU_NONE, {}
    end
end

return MJLogic
