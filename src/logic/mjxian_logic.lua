local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("XIANLogic", MJLogic)

MJLogic.HUSCORES = {
    [ MJLogic.HU_QIXIAODUI ] = 2,
    [ MJLogic.HU_QINGYISE  ] = 2,
}

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass)
    local anGangCards = MJLogic.GetGangPai(hand)
    local jiaGangCards = MJLogic.GetGroupGangpai(hand, group, pass)

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
function MJLogic.CanPeng(hand, out_card)
    local duizi = MJLogic.GetDuizi(hand)
    for i, v in ipairs(duizi) do
        if v == out_card then
            return true
        end
    end
    return false
end

-- 判断是否可以杠
function MJLogic.CanGang(hand, card)
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == card and num == 3 then
            return true
        end
    end
    return false
end

-- 判断是否可以接炮胡
function MJLogic.CanChiHu(hand, group_data, card, wang, canHuQiDui, is258Jiang)
    local new_data = table.copyArray(hand)
    local tmp_card = card
    if wang ~= nil and card == wang then
        tmp_card = MJLogic.FAKE_WANG
    end
    table.insert(new_data, tmp_card)
    local new_data2 = clone(group_data)
    local hu_type, jiang = MJLogic.JudgeHu(new_data, new_data2, wang, canHuQiDui, is258Jiang)
    if hu_type > 0 then
        return true, jiang
    end
    return false, {}
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang, canHuQiDui, is258Jiang)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    local hu_type, jiang = MJLogic.JudgeHu(new_data, new_data2, wang, canHuQiDui, is258Jiang)
    if hu_type > 0 then
        return true, jiang
    end
    return false, {}
end

-- 获取听牌列表
function MJLogic.GetTingCards(hand, group, wang, canHuQiDui, is258Jiang)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL) do
        new_data[#new_data + 1] = card
        local hu = MJLogic.JudgeHu(new_data, group, wang, canHuQiDui, is258Jiang)
        if hu > 0 then
            table.insert(ting_cards, card)
        end
        new_data[#new_data] = nil
    end
    return ting_cards
end

function MJLogic.JudgeHu_Duidui(hand, wang)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if wang then
        local new_data = {}
        local jing_num = 0
        for i, v in ipairs(hand) do
            if v == wang then
                jing_num = jing_num + 1
            else
                new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
            end
        end

        local duizi = MJLogic.GetDuizi(new_data)
        local danPaiCount = 14 - (2 * #duizi + jing_num)
        if jing_num >= danPaiCount then
            local gangs = MJLogic.GetGangPai(hand)
            if #gangs == 0 then
                return MJLogic.HU_QIXIAODUI
            else
                return MJLogic.HU_QIXIAODUI
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
                return MJLogic.HU_QIXIAODUI
            end
        end
        return MJLogic.HU_NONE
    end
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

-- 胡258加番(抓癞子牌自摸时判断)
function MJLogic.JudgeHu_HU258FAN(hand, group, wang, canHuQiDui, is258Jiang)
    local new_data = table.copyArray(hand)
    MJLogic.delete_card(new_data, {wang})
    local cards258 = {0x02, 0x05, 0x08, 0x12, 0x15, 0x18, 0x22, 0x25, 0x28}
    for _, card in ipairs(cards258) do
        new_data[#new_data + 1] = card
        if MJLogic.JudgeHu(new_data, group, wang, canHuQiDui, is258Jiang) > 0 then
            return true
        end
        new_data[#new_data] = nil
    end
    return false
end

function MJLogic.JudgeHuTypes(hand, group, hu_types, wang, canHuQiDui, isQingYiSe)
    local types = hu_types or {}

    if canHuQiDui > 0 then
        local hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
        if hu_type > 0 then
            table.insert(types, hu_type)
        end
    end

    if isQingYiSe then
        local hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
        if hu_type  > 0 then
            table.insert(types, hu_type)
        end
    end

    return types
end

-- @return：1.胡牌类型 2.将牌
function MJLogic.JudgeHu(hand, group, wang, canHuQiDui, is258Jiang)
    if canHuQiDui > 0 then
        local hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
        if hu_type > 0 then
            return hu_type, {}
        end
    end

    return MJLogic.JudgeHu_Normal(hand, wang, is258Jiang)
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang, is258Jiang)
    local jiang    = {} -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local arr      = {}
    -- 这里要放入所有的牌，因为下面顺子的处理会用到当前牌的前后张数量


    for _, v in ipairs(MJLogic.CARD_ALL) do
        arr[v] = 0
    end
    for _, v in ipairs(hand) do
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
        if #jiang > 0 and remainCardCount == 0 then
            return 1
        end

        for i, num in MJLogic.pairsByKeys(arr) do
            local value = MJLogic.GetValue(i) -- 当前牌处理：分别组成将刻子顺子

            -- 将
            if #jiang == 0 and arr[i] >= 2 and (not is258Jiang or (i < 48 and (value == 2 or value == 5 or value == 8))) then
                jiang = {i, i}
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then
                    return 1
                end
                jiang = {}
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 将,用一张精
            if #jiang == 0 and jing_num >= 1 and arr[i] == 1 and (not is258Jiang or (i < 48 and (value == 2 or value == 5 or value == 8))) then
                jing_num = jing_num - 1
                jiang = {i, wang}
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                jiang = {}
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

            -- 二张精组成将牌
            if #jiang == 0 and jing_num >= 2 then
                jiang = {wang, wang}
                jing_num = jing_num - 2
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 2
                jiang = {}
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
        return MJLogic.HU_NORMAL, jiang
    else
        return MJLogic.HU_NONE, jiang
    end
end

return MJLogic
