--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-07-23
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2018-07-23
-- @Desc: 抠点逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJKDLogic", MJLogic)

MJLogic.HUSCORES = {
    [ MJLogic.HU_NORMAL       ] = 2,
    [ MJLogic.HU_QIXIAODUI    ] = 2,
    [ MJLogic.HU_YITIAOLONG   ] = 2,
    [ MJLogic.HU_QINGYISE     ] = 2,
    [ MJLogic.HU_HAOQIXIAODUI ] = 2,
    [ MJLogic.HU_SHISANYAO    ] = 2,
}

MJLogic.HUSCORES_FSF = {
    [ MJLogic.HU_NORMAL       ] = 2,
    [ MJLogic.HU_QIXIAODUI    ] = 2,
    [ MJLogic.HU_YITIAOLONG   ] = 2,
    [ MJLogic.HU_QINGYISE     ] = 2,
    [ MJLogic.HU_HAOQIXIAODUI ] = 4,
    [ MJLogic.HU_SHISANYAO    ] = 4,
}

MJLogic.CARD_ALL = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
    0x31, 0x32, 0x33, 0x34,
    0x41, 0x42, 0x43
}

-- 小于6点不能报听
MJLogic.CARD_ALL_TING = {
    0x06, 0x07, 0x08, 0x09,
    0x16, 0x17, 0x18, 0x19,
    0x26, 0x27, 0x28, 0x29,
    0x31, 0x32, 0x33, 0x34,
    0x41, 0x42, 0x43
}

-- 3点可听；1，2点不能听
MJLogic.CARD_ALL_TING_3 = {
    0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
    0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
    0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
    0x31, 0x32, 0x33, 0x34,
    0x41, 0x42, 0x43
}

-- 1,2点不能胡
MJLogic.CARD_ALL_HU = {
    0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
    0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
    0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
    0x31, 0x32, 0x33, 0x34,
    0x41, 0x42, 0x43
}


-- 得到抠点的card值。风牌值为10点
function MJLogic.getKDValue(card)
    if card < 0x30 then
        return card % 16
    else
        return 10
    end
end

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass, is_ting, wang, tingCards, isFengZuiZi, is3DKT)
    local anGangCards = MJLogic.GetGangPai(hand)
    local jiaGangCards = MJLogic.GetGroupGangpai(hand, group, pass)

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
                    local hu = MJLogic.JudgeHu(new_data, group, wang, isFengZuiZi)
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

                if MJLogic.CanTing(new_data, group, wang, is3DKT) then
                    canGangCards[#canGangCards + 1] = gangCard
                end
            end
            return canGangCards, anGangCards, jiaGangCards
        end
    end
end

-- 判断是否可以吃牌(组成顺子)
function MJLogic.CanChi(hand, card, ret, wang)
    return false
end

-- 判断是否可以碰
function MJLogic.CanPeng(hand, out_card)
    local duizi = MJLogic.GetDuizi(hand)
    for i, v in ipairs(duizi) do
        if v == out_card then
            return true
        end
    end
    return false
end

-- 判断是否可以杠指定的牌
function MJLogic.CanGang(hand, gangCard, is_ting, wang, tingCards, isFengZuiZi, is3DKT)
    local hasKe = false

    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == gangCard and num == 3 then
            hasKe = true
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
                local hu = MJLogic.JudgeHu(new_data, {}, wang, isFengZuiZi)
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
            if MJLogic.CanTing(new_data, {}, wang, is3DKT) then
                return true
            end
        end
    end

    return false
end

-- 判断是否出牌后可以听牌
function MJLogic.CanOutToTing(hand, group, wang, isFengZuiZi, isKHQDBJF, is3DKT)
    wang = wang or MJLogic.FAKE_WANG
    local setCard = table.unique(hand, true)
    for i, v in ipairs(setCard) do
        local new_data = table.copyArray(hand)
        MJLogic.delete_card(new_data, {v})
        new_data[#new_data + 1] = wang
        if MJLogic.JudgeHu(new_data, group, wang, isFengZuiZi, isKHQDBJF) > 0 then
            new_data[#new_data] = nil
            if MJLogic.CanTing(new_data, group, wang, isFengZuiZi, isKHQDBJF, is3DKT) then
                return true
            end
        end
    end
    return false
end

-- 判断能否听牌
function MJLogic.CanTing(hand, group, wang, isFengZuiZi, isKHQDBJF, is3DKT)
    local new_data = table.copyArray(hand)
    local canTingCards = nil
    if is3DKT then
        canTingCards = MJLogic.CARD_ALL_TING_3
    else
        canTingCards = MJLogic.CARD_ALL_TING
    end
    for _, card in ipairs(canTingCards) do
        -- 对于赖子，则只考虑其本身
        if card == wang then
            new_data[#new_data + 1] = card + MJLogic.CARD_FLAG
        else
            new_data[#new_data + 1] = card
        end
        local hu = MJLogic.JudgeHu(new_data, group, wang, isFengZuiZi, isKHQDBJF)
        if hu > 0 then
            return true
        end
        new_data[#new_data] = nil
    end
    return false
end

-- 能不能单调耗子，即胡任意牌
function MJLogic.CanWangDanDiaoHu(hand, wang, isFengZuiZi, isKHQDBJF)
    if MJLogic.JudgeHu_Duidui(hand, wang, isKHQDBJF, true) > 0 then
        return true
    end

    if MJLogic.JudgeHu_Normal(hand, wang, isFengZuiZi, true) > 0 then
        return true
    end

    return false
end

-- 判断是否可以接炮胡
-- 如果card 为耗子，则要把耗子当普通牌处理，这里将该牌加0x80来和耗子区分。
-- 即如果牌值大于0x80，则该张牌是由其它玩家打的耗子牌，不能当耗子来处理
function MJLogic.CanChiHu(hand, group_data, card, wang, isFengZuiZi, isKHQDBJF)
    if MJLogic.getKDValue(card) < 6 then
        return false
    end
    local new_data = table.copyArray(hand)
    if card == wang then
        table.insert(new_data, card + MJLogic.CARD_FLAG)
    else
        table.insert(new_data, card)
    end
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang, isFengZuiZi, isKHQDBJF) > 0 then
        return true
    end
    return false
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, card, wang, isFengZuiZi, isKHQDBJF)
    if card ~= wang and MJLogic.getKDValue(card) < 3 then
        return false
    end
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang, isFengZuiZi, isKHQDBJF) > 0 then
        return true
    end
    return false
end

-- 获取听牌列表
function MJLogic.CetTingCards(hand, group, wang, isFengZuiZi, isKHQDBJF)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL_HU) do
        -- 对于赖子，则只考虑其本身
        if card == wang then
            new_data[#new_data + 1] = card + MJLogic.CARD_FLAG
        else
            new_data[#new_data + 1] = card
        end
        local hu = MJLogic.JudgeHu(new_data, group, wang, isFengZuiZi, isKHQDBJF)
        if hu > 0 then
            table.insert(ting_cards, card)
        end
        new_data[#new_data] = nil
    end
    return ting_cards
end

-- 七对，毫华七小对，十三幺只有在没有勾选捉耗子或者风耗子玩法,即不存在耗子玩法时，才存在
-- @param isKHQDBJF 当存在耗子玩法时，则可胡七对，只是不加番
function MJLogic.JudgeHu_Duidui(hand, wang, isKHQDBJF, isWangDanDiao)
    local handCount = 14
    if isWangDanDiao then
        handCount = 13
    end

    if #hand ~= handCount then
        return MJLogic.HU_NONE
    end

    if wang and wang ~= MJLogic.FAKE_WANG and not isKHQDBJF then
        -- 捉耗子/风耗子玩法却没有勾选可胡七对不加番,则不能胡七对
        return MJLogic.HU_NONE
    elseif wang and (isKHQDBJF or wang == MJLogic.FAKE_WANG) then
        -- 捉耗子/风耗子玩法时可胡七对不加番或非捉耗子/风耗子时判断听七对
        local new_data = {}
        local jing_num = 0
        for i, v in ipairs(hand) do
            if v == wang then
                jing_num = jing_num + 1
            else
                new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
            end
        end

        if isWangDanDiao then
            if jing_num == 0 then
                return MJLogic.HU_NONE
            end

            jing_num = jing_num - 1
            handCount = handCount - 1
        end

        local duizi = MJLogic.GetDuizi(new_data)
        local danPaiCount = handCount - (2 * #duizi + jing_num)
        if jing_num >= danPaiCount then
            local gangs = MJLogic.GetGangPai(hand)
            if #gangs == 0 then
                return MJLogic.HU_QIXIAODUI
            else
                return MJLogic.HU_HAOQIXIAODUI
            end
        end
        return MJLogic.HU_NONE
    else
        local duizi = MJLogic.GetDuizi(hand)
        if #duizi == 7 then
            local gangs = MJLogic.GetGangPai(hand)
            if #gangs == 0 then
                return MJLogic.HU_QIXIAODUI
            else
                return MJLogic.HU_HAOQIXIAODUI
            end
        end
        return MJLogic.HU_NONE
    end
end

-- 一条龙
function MJLogic.JudgeHu_YITIAOLONG(hand, wang, isFengZuiZi)
    local new_data = {}
    local jing_num = 0
    for i, v in ipairs(hand) do
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
            for j, k in ipairs(new_data) do
                if MJLogic.GetColor(k) == color and not MJLogic.in_array_obj(tab1, k) then
                    table.insert(tab1, k)
                else
                    table.insert(tab2, k)
                end
            end
            if #tab1 + jing_num >= 9 then -- 可组成一条龙
                local thecolor = color

                -- tab2 为去掉组成一张龙的1-9或加耗子的9张牌，然后判定tab2能不能胡
                -- 多余的耗子加到tab2中
                local add_jing_num = jing_num - (9 - #tab1)
                if wang and add_jing_num > 0 then
                    for i = 1, add_jing_num do
                        table.insert(tab2, wang)
                    end
                end

                if MJLogic.JudgeHu_Normal(tab2, wang, isFengZuiZi) ~= MJLogic.HU_NONE then
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
    if MJLogic.JudgeHu_Normal(hand, wang) == MJLogic.HU_NORMAL or MJLogic.JudgeHu_Duidui(hand, wang) then
        return MJLogic.HU_QINGYISE
    else
        return MJLogic.HU_NONE
    end
end

-- 13妖
function MJLogic.JudgeHu_SSY(hand, wang)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if wang and wang ~= MJLogic.FAKE_WANG then
        return MJLogic.HU_NONE
    end

    local new_data = {} -- 除去赖子的所有其它牌
    for i, v in ipairs(hand) do
        if v ~= wang then
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    -- 万条筒，如果不是1，9和赖子，则不能胡13妖
    for i, v in ipairs(new_data) do
        local value = MJLogic.GetValue(v)
        if v < 0x31 and value ~= 1 and value ~= 9 then
            return MJLogic.HU_NONE
        end
    end

    -- 除去赖子的所有其它牌中，只能有一个将牌，才能胡13妖
    local hand_count = MJLogic.GetHandCount(new_data)
    local has_two = 0
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if num > 2 then
            return MJLogic.HU_NONE
        end
        if num == 2 then
            has_two = has_two + 1
            if has_two >= 2 then
                return MJLogic.HU_NONE
            end
        end
    end

    return MJLogic.HU_SHISANYAO
end

-- 七对，毫华七小对，十三幺只有在没有勾选捉耗子或者风耗子玩法,即不存在耗子玩法时，才存在
-- @param isKHQDBJF 当存在耗子玩法时，则可胡七对，只是不加番
function MJLogic.JudgeHuTypes(hand, group, hu_types, wang, isFengZuiZi, isQYSYTLJF, isKHQDBJF, isDHJD)
    local types = hu_types or {}

    local hu_type = MJLogic.JudgeHu_Duidui(hand, wang, isKHQDBJF)
    if hu_type > 0 then
        table.insert(types, hu_type)
    end

    if isDHJD or isQYSYTLJF then
        hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, wang, isFengZuiZi)
        if hu_type  > 0 then
            table.insert(types, hu_type)
        end

        hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
        if hu_type  > 0 then
            table.insert(types, hu_type)
        end
    end

    hu_type = MJLogic.JudgeHu_SSY(hand, wang)
    if hu_type  > 0 then
        table.insert(types, hu_type)
    end

    return types
end

function MJLogic.JudgeHu(hand, group, wang, isFengZuiZi, isKHQDBJF)
    local hu_type = 0

    hu_type = MJLogic.JudgeHu_Duidui(hand, wang, isKHQDBJF)
    if hu_type > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_SSY(hand, wang)
    if hu_type  > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_Normal(hand, wang, isFengZuiZi)
    if hu_type > 0 then
        return hu_type
    end

    return hu_type
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang, isFengZuiZi, isWangDanDiao)
    local jiang    = 0 -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local arr      = {}
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

    if isWangDanDiao then
        if jing_num == 0 then
            return MJLogic.HU_NONE
        end

        jing_num = jing_num - 1 -- 减去一张耗子牌，来单调任意牌
        jiang = 1
    end

    local function NormalHu()
        -- 递归退出条件：如果没有剩牌，则胡牌返回
        if remainCardCount == 0 then
            if jiang == 1 then
                return 1
            elseif jing_num % 3 == 2 then
                return 1
            end
        end

        for i, num in MJLogic.pairsByKeys(arr) do
            local value = MJLogic.GetValue(i) -- 当前牌处理：分别组成将刻子顺子

            -- 将
            if jiang == 0 and arr[i] >= 2 then
                jiang = 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then
                    return 1
                end
                jiang = 0
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 将,用一张精
            if jiang == 0 and jing_num >= 1 and arr[i] == 1 then
                jing_num = jing_num - 1
                jiang = 1
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                jiang = 0
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
            end

            -- 刻子
            if arr[i] >= 3 then
                arr[i] = arr[i] - 3
                remainCardCount = remainCardCount - 3
                if NormalHu() == 1 then
                    return 1
                end
                arr[i] = arr[i] + 3
                remainCardCount = remainCardCount + 3
            end

            -- 刻子,用一张精
            if jing_num >= 1 and arr[i] == 2 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 刻子,用二张精
            if jing_num >= 2 and arr[i] == 1 then
                jing_num = jing_num - 2
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 2
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
            end

            -- 顺子
            if i < 0x31 and value < 8 and arr[i+1] > 0 and arr[i+2] > 0 then
                arr[i] = arr[i] - 1
                arr[i+1] = arr[i+1] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 3
                if NormalHu() == 1 then
                    return 1
                end
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                arr[i+2] = arr[i+2] + 1
                remainCardCount = remainCardCount + 3
            end

            -- 顺子,顺子中间一张用精
            if i < 0x31 and jing_num >= 1 and value < 8 and arr[i+2] > 0 then
                jing_num = jing_num - 1
                arr[i] = arr[i] - 1
                arr[i+2] = arr[i+2] - 1
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then
                    return 1
                end
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
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 1
                arr[i+1] = arr[i+1] + 1
                remainCardCount = remainCardCount + 2
            end

            -- 风嘴子, 东南西北
            if isFengZuiZi and i >= 0x31 and i <= 0x34 then
                -- 东南西北, 不用精
                local combinations = {{1, 2, 3}, {1, 2, 4}, {1, 3, 4}, {2, 3, 4}}
                for _, comb in ipairs(combinations) do
                    if i == 0x30 + comb[1] and arr[0x30 + comb[2]] > 0 and arr[0x30 + comb[3]] > 0 then
                        arr[0x30+comb[1]] = arr[0x30+comb[1]] - 1
                        arr[0x30+comb[2]] = arr[0x30+comb[2]] - 1
                        arr[0x30+comb[3]] = arr[0x30+comb[3]] - 1
                        remainCardCount = remainCardCount - 3
                        if NormalHu() == 1 then return 1 end
                        remainCardCount = remainCardCount + 3
                        arr[0x30+comb[1]] = arr[0x30+comb[1]] + 1
                        arr[0x30+comb[2]] = arr[0x30+comb[2]] + 1
                        arr[0x30+comb[3]] = arr[0x30+comb[3]] + 1
                    end
                end

                -- 东南西北, 用一张精
                local combinations = {{1, 2}, {1, 3}, {1, 4}, {2, 3}, {2, 4}, {3, 4}}
                for _, comb in ipairs(combinations) do
                    if jing_num > 0 and i == 0x30 + comb[1] and arr[0x30 + comb[2]] > 0 then
                        jing_num = jing_num - 1
                        arr[0x30+comb[1]] = arr[0x30+comb[1]] - 1
                        arr[0x30+comb[2]] = arr[0x30+comb[2]] - 1
                        remainCardCount = remainCardCount - 2
                        if NormalHu() == 1 then return 1 end
                        remainCardCount = remainCardCount + 2
                        jing_num = jing_num + 1
                        arr[0x30+comb[1]] = arr[0x30+comb[1]] + 1
                        arr[0x30+comb[2]] = arr[0x30+comb[2]] + 1
                    end
                end

            end

            -- 风嘴子,中发白
            if isFengZuiZi and i >= 0x41 and i <= 0x43 then
                -- 中发白 无精
                if i == 0x41 and arr[i+1] > 0 and arr[i+2] > 0 then
                    arr[i] = arr[i] - 1
                    arr[i+1] = arr[i+1] - 1
                    arr[i+2] = arr[i+2] - 1
                    remainCardCount = remainCardCount - 3
                    if NormalHu() == 1 then return 1 end
                    remainCardCount = remainCardCount + 3
                    arr[i] = arr[i] + 1
                    arr[i+1] = arr[i+1] + 1
                    arr[i+2] = arr[i+2] + 1
                end

                -- 中发白, 用一张精
                local combinations = {{1, 2}, {1, 3}, {2, 3}}
                for _, comb in ipairs(combinations) do
                    if jing_num > 0 and i == 0x40 + comb[1] and arr[0x40 + comb[2]] > 0 then
                        jing_num = jing_num - 1
                        arr[0x40+comb[1]] = arr[0x40+comb[1]] - 1
                        arr[0x40+comb[2]] = arr[0x40+comb[2]] - 1
                        remainCardCount = remainCardCount - 2
                        if NormalHu() == 1 then return 1 end
                        remainCardCount = remainCardCount + 2
                        jing_num = jing_num + 1
                        arr[0x40+comb[1]] = arr[0x40+comb[1]] + 1
                        arr[0x40+comb[2]] = arr[0x40+comb[2]] + 1
                    end
                end
            end

            -- 二张精组成将牌
            if jiang == 0 and jing_num >= 2 then
                jiang = 1
                jing_num = jing_num - 2
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 2
                jiang = 0
            end

            -- 3张精组成刻子或者顺子
            if jing_num >= 3 then
                jing_num = jing_num - 3
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 3
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
