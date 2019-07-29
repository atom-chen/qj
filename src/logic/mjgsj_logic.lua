--------------------------------------------------------------------------------
-- @Author: wuwei
-- @Date: 2018-10-08
-- @Last Modified by: pplarry@qq.com
-- @Last Modified time: 2018-10-10
-- @Desc: 拐三角麻将逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJGSJLogic", MJLogic)

MJLogic.HU_KANHU = 108  -- 坎胡(胡单张牌)

MJLogic.HUSCORES = {
    [ MJLogic.HU_NORMAL       ] = 5,
    [ MJLogic.HU_KANHU        ] = 10,
    [ MJLogic.HU_QIXIAODUI    ] = 15,
    [ MJLogic.HU_YITIAOLONG   ] = 15,
    [ MJLogic.HU_QINGYISE     ] = 15,
    [ MJLogic.HU_HAOQIXIAODUI ] = 30,
    [ MJLogic.HU_SHISANYAO    ] = 30,
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
function MJLogic.CanGang(hand, gangCard)
    local hasKe = false
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == gangCard and num == 3 then
            hasKe = true
            break
        end
    end
    return hasKe
end

-- 判断是否可以接炮胡
-- 如果card 为耗子，则要把耗子当普通牌处理，这里将该牌加0x80来和耗子区分。
-- 即如果牌值大于0x80，则该张牌是由其它玩家打的耗子牌，不能当耗子来处理
function MJLogic.CanChiHu(hand, group_data, card, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
    local new_data = table.copyArray(hand)
    if card == wang then
        table.insert(new_data, card + MJLogic.CARD_FLAG)
    else
        table.insert(new_data, card)
    end
    local new_data2 = clone(group_data)
    local hu, groups = MJLogic.JudgeHu(new_data, new_data2, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
    if hu > 0 then
        return true, groups
    end
    return false, {}
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    if MJLogic.JudgeHu(new_data, new_data2, wang, isQiXiaoDui, is13Yao, isYing8Zhang) > 0 then
        return true
    end
    return false
end

-- 获取听牌列表
function MJLogic.CetTingCards(hand, group, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL) do
        new_data[#new_data + 1] = card
        local hu = MJLogic.JudgeHu(new_data, group, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
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

-- 坎胡(胡单张，包括夹中、单调、边夹)
function MJLogic.JudgeHu_KANHU(hand, wang, groups, hu_card, isDanDiaoKan)
    local hu_type = 0

    for _, g in ipairs(groups) do
        if isDanDiaoKan and #g == 2 then
            if g[1] == hu_card then
                hu_type = MJLogic.HU_KANHU -- 单调
                break
            elseif MJLogic.has_card(hand, {hu_card, hu_card}) then
            -- 特殊情况如{2,2,3,3,3,4,4,4,5,5}胡5
                local new_hand = table.copyArray(hand)
                MJLogic.delete_card(new_hand, {hu_card, hu_card})
                if MJLogic.JudgeHu_Normal(new_hand, wang, true) ~= MJLogic.HU_NONE then
                    hu_type = MJLogic.HU_KANHU -- 单调
                    break
                end
            end
        elseif #g == 3 then
            if g[1] ~= g[2] then
                if g[2] == hu_card then
                    hu_type = MJLogic.HU_KANHU -- 夹中
                    break
                elseif (g[1] == hu_card and MJLogic.GetValue(hu_card) == 7) or (g[3] == hu_card and MJLogic.GetValue(hu_card) == 3) then
                    hu_type = MJLogic.HU_KANHU -- 边夹
                    break
                end
            end
        end
    end

    return hu_type
end

function MJLogic.JudgeHuTypes(hand, group, wang, groups, hu_card, isQiXiaoDui, is13Yao, isDanDiaoKan)
    local hu_type = 0
    local types = {}

    if is13Yao then
        hu_type = MJLogic.JudgeHu_SSY(hand, wang)
        if hu_type > 0 then
            table.insert(types, hu_type)
            return types
        end
    end

    hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    if hu_type > 0 then
        table.insert(types, hu_type)
    end

    if isQiXiaoDui then
        hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
        if hu_type > 0 then
            table.insert(types, hu_type)
            return types
        end
    end

    hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, wang)
    if hu_type > 0 then
        table.insert(types, hu_type)
    end

    hu_type = MJLogic.JudgeHu_KANHU(hand, wang, groups, hu_card, isDanDiaoKan)
    if hu_type > 0 then
        table.insert(types, hu_type)
    end

    return types
end


function MJLogic.JudgeHu_Y8Z(hand, group)
    local canHu = false
    local new_data = table.copyArray(hand)

    for _, g in ipairs(group) do
        table.insert(new_data, g[1])
        table.insert(new_data, g[2])
        table.insert(new_data, g[3])
        if g[4] ~= nil then
            table.insert(new_data, g[4])
        end
    end

    local colorCounts = {}
    for _, v in ipairs(new_data) do
        local color = v < 0x31 and MJLogic.GetColor(v) or 5
        if colorCounts[color] == nil then
            colorCounts[color] = 1
        else
            colorCounts[color] = colorCounts[color] + 1
        end
    end

    for _, num in pairs(colorCounts) do
        if num >= 8 then
            canHu = true
            break
        end
    end

    return canHu
end

function MJLogic.JudgeHu(hand, group, wang, isQiXiaoDui, is13Yao, isYing8Zhang)
    local hu_type = 0
    local groups = {}

    if isYing8Zhang and not MJLogic.JudgeHu_Y8Z(hand, group) then
        return hu_type, groups
    end

    if isQiXiaoDui then
        hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
        if hu_type > 0 then
            return hu_type, groups
        end
    end

    if is13Yao then
        hu_type = MJLogic.JudgeHu_SSY(hand, wang)
        if hu_type > 0 then
            return hu_type, groups
        end
    end

    hu_type, groups = MJLogic.JudgeHu_Normal(hand, wang)
    if hu_type > 0 then
        return hu_type, groups
    end

    return hu_type, groups
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang, hasJiang)
    local jiang    = hasJiang and 1 or 0 -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local groups   = {}
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
                groups[#groups + 1] = {i, i, wang}
                if NormalHu() == 1 then
                    return 1
                end
                jing_num = jing_num + 1
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
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
