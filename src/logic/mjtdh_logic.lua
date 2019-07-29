--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-07-16
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2018-07-30
-- @Desc: 麻将推倒胡逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJTDHLogic", MJLogic)

MJLogic.HUSCORES = {
    [ MJLogic.HU_NORMAL       ] = 2,
    [ MJLogic.HU_QIXIAODUI    ] = 3,
    [ MJLogic.HU_YITIAOLONG   ] = 3,
    [ MJLogic.HU_QINGYISE     ] = 3,
    [ MJLogic.HU_HAOQIXIAODUI ] = 6,
    [ MJLogic.HU_SHISANYAO    ] = 9,
}

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass, is_ting, wang, tingCards, isHPBXQM, isYHQ)
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
                    local hu = MJLogic.JudgeHu(new_data, group, wang, isHPBXQM, isYHQ)
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

                if MJLogic.CanTing(new_data, group, wang, isHPBXQM, isYHQ) then
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

-- 判断缺门：缺门,只算万筒条
function MJLogic.isQueMen(hand, group, wang)
    local tmpCards = {}
    for _, h in ipairs(hand) do
        if h < 0x30 and h ~= wang then
            tmpCards[#tmpCards + 1] = h
        end
    end
    for _, g in ipairs(group or {}) do
        if g[1] < 0x30 then
            tmpCards[#tmpCards + 1] = g[1]
        end
    end

    if MJLogic.GetHandColor(tmpCards) <= 2 then
        return true
    end
    return false
end

-- 判断是否可以杠指定的牌
function MJLogic.CanGang(hand, gangCard, is_ting, wang, tingCards, isHPBXQM, isYHQ)
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
                local hu = MJLogic.JudgeHu(new_data, {}, wang, isHPBXQM, isYHQ)
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
            if MJLogic.CanTing(new_data, {}, wang, isHPBXQM, isYHQ) then
                return true
            end
        end
    end

    return false
end

-- 判断是否出牌后可以听牌
function MJLogic.CanOutToTing(hand, group, wang, isHPBXQM, isYHQ)
    wang = wang or MJLogic.FAKE_WANG
    local setCard = table.unique(hand, true)
    for i, v in ipairs(setCard) do
        local new_data = table.copyArray(hand)
        MJLogic.delete_card(new_data, {v})
        new_data[#new_data + 1] = wang
        if MJLogic.JudgeHu(new_data, group, wang, isHPBXQM, isYHQ) > 0 then
            return true
        end
    end
    return false
end

-- 判断能否听牌
function MJLogic.CanTing(hand, group, wang, isHPBXQM, isYHQ)
    wang = wang or MJLogic.FAKE_WANG
    local new_data = table.copyArray(hand)
    new_data[#new_data + 1] = wang
    if MJLogic.JudgeHu(new_data, group, wang, isHPBXQM, isYHQ) > 0 then
        return true
    end
    return false
end


-- 判断是否可以接炮胡
-- 如果card 为耗子，则要把耗子当普通牌处理，这里将该牌加0x80来和耗子区分。
-- 即如果牌值大于0x80，则该张牌是由其它玩家打的耗子牌，不能当耗子来处理
function MJLogic.CanChiHu(hand, group_data, card, wang, isHPBXQM, isYHQ)
    local new_data = table.copyArray(hand)
    if card == wang then
        table.insert(new_data, card + MJLogic.CARD_FLAG)
    else
        table.insert(new_data, card)
    end
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang, isHPBXQM, isYHQ) > 0 then
        return true
    end
    return false
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang, isHPBXQM, isYHQ)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang, isHPBXQM, isYHQ) > 0 then
        return true
    end
    return false
end

-- 获取听牌列表
function MJLogic.CetTingCards(hand, group, wang, isHPBXQM, isYHQ)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL) do
        new_data[#new_data + 1] = card
        local hu = MJLogic.JudgeHu(new_data, group, wang, isHPBXQM, isYHQ)
        if hu > 0 then
            table.insert(ting_cards, card)
        end
        new_data[#new_data] = nil
    end
    return ting_cards
end

function MJLogic.JudgeHu_Duidui(hand, wang, isHPBXQM, isYHQ)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if isHPBXQM and not MJLogic.isQueMen(hand, nil, wang) then
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
            if isYHQ then
                local gangs = MJLogic.GetGangPai(hand)
                if #gangs == 0 then
                    return MJLogic.HU_QIXIAODUI
                else
                    local hasNoWangGang = false
                    for _, gang in ipairs(gangs) do
                        if gang ~= wang then
                            hasNoWangGang = true
                            break
                        end
                    end
                    if hasNoWangGang then
                        return MJLogic.HU_HAOQIXIAODUI
                    else
                        if danPaiCount == 0 then -- 4张耗子组成毫七
                            return MJLogic.HU_HAOQIXIAODUI
                        else
                            return MJLogic.HU_QIXIAODUI
                        end
                    end
                end
            else
                local kePais = MJLogic.GetKePais(hand)
                if #kePais > 0 then
                    local hasNoWangKe = false
                    for _, ke in ipairs(kePais) do
                        if ke ~= wang then
                            hasNoWangKe = true
                            break
                        end
                    end
                    if hasNoWangKe then
                        return MJLogic.HU_HAOQIXIAODUI
                    else
                        if danPaiCount == 0 then -- 4张耗子组成毫七
                            return MJLogic.HU_HAOQIXIAODUI
                        else
                            return MJLogic.HU_QIXIAODUI
                        end
                    end
                else
                    local leftJingCount = jing_num - danPaiCount
                    if leftJingCount >= 2 then
                        return MJLogic.HU_HAOQIXIAODUI
                    else
                        return MJLogic.HU_QIXIAODUI
                    end
                end
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
function MJLogic.JudgeHu_YITIAOLONG(hand, group, wang, isHPBXQM)
    if isHPBXQM and not MJLogic.isQueMen(hand, group, wang) then
        return MJLogic.HU_NONE
    end

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

                -- 多余的耗子加到tab2中
                local add_jing_num = jing_num - (9 - #tab1)
                if wang and add_jing_num > 0 then
                    for i = 1, add_jing_num do
                        table.insert(tab2, wang)
                    end
                end

                if MJLogic.JudgeHu_Normal(tab2, group, wang, isHPBXQM) ~= MJLogic.HU_NONE then
                    return MJLogic.HU_YITIAOLONG
                end
            end
        end
    end

    return MJLogic.HU_NONE
end

-- 清一色 (胡牌)
function MJLogic.JudgeHu_QINGYISE(hand, group, wang, isHPBXQM, isYHQ)
    if isHPBXQM and not MJLogic.isQueMen(hand, group, wang) then
        return MJLogic.HU_NONE
    end

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
    if MJLogic.JudgeHu_Normal(hand, group, wang, isHPBXQM) == MJLogic.HU_NORMAL or MJLogic.JudgeHu_Duidui(hand, wang, isHPBXQM, isYHQ) then
        return MJLogic.HU_QINGYISE
    else
        return MJLogic.HU_NONE
    end
end

-- 13妖
function MJLogic.JudgeHu_SSY(hand, wang, isHPBXQM)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if isHPBXQM then
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

function MJLogic.JudgeHuTypes(hand, group, hu_types, wang, isHPBXQM, isYHQ)
    local types = hu_types or {}

    local hu_type = MJLogic.JudgeHu_Duidui(hand, wang, isHPBXQM, isYHQ)
    if hu_type > 0 then
        table.insert(types, hu_type)
    end

    hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, group, wang, isHPBXQM)
    if hu_type  > 0 then
        table.insert(types, hu_type)
    end

    hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang, isHPBXQM, isYHQ)
    if hu_type  > 0 then
        table.insert(types, hu_type)
    end

    hu_type = MJLogic.JudgeHu_SSY(hand, wang, isHPBXQM)
    if hu_type  > 0 then
        table.insert(types, hu_type)
    end

    return types
end

function MJLogic.JudgeHu(hand, group, wang, isHPBXQM, isYHQ)
    local hu_type = 0

    hu_type = MJLogic.JudgeHu_Duidui(hand, wang, isHPBXQM, isYHQ)
    if hu_type > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_SSY(hand, wang, isHPBXQM)
    if hu_type  > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_Normal(hand, group, wang, isHPBXQM)
    if hu_type > 0 then
        return hu_type
    end

    return hu_type
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, group, wang, isHPBXQM)
    if isHPBXQM and not MJLogic.isQueMen(hand, group, wang) then
        return MJLogic.HU_NONE
    end

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
