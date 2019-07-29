--------------------------------------------------------------------------------
-- @Author: wuwei
-- @Date: 2018-11-06
-- @Last Modified by: pplarry@qq.com
-- @Last Modified time: 2018-11-08
-- @Desc: 河北麻将逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJHEBEILogic", MJLogic)

MJLogic.HU_MENQING       = 109  -- 门清
MJLogic.HU_PENGPENGHU    = 113  -- 碰碰胡
MJLogic.HU_QIANGGANGHU   = 114  -- 抢杠胡
MJLogic.HU_GANGSHANGHUA  = 115  -- 杠上开花
MJLogic.HU_HAIDILAOYUE   = 116  -- 海底捞月
MJLogic.HU_DADIAOCHE     = 117  -- 大吊车
MJLogic.HU_QINGFENG      = 118  -- 清风
MJLogic.HU_HUNYISE       = 119  -- 混一色
MJLogic.HU_HUALONG       = 120  -- 花龙
MJLogic.HU_ZHUOWUKUI     = 121  -- 捉五魁
MJLogic.HU_2HAOQIXIAODUI = 122  -- 双豪七对
MJLogic.HU_3HAOQIXIAODUI = 123  -- 三豪七对

MJLogic.HUSCORES = {
    [ MJLogic.HU_QIXIAODUI     ] = 2,
    [ MJLogic.HU_YITIAOLONG    ] = 2,
    [ MJLogic.HU_MENQING       ] = 2,
    [ MJLogic.HU_QIANGGANGHU   ] = 2,
    [ MJLogic.HU_GANGSHANGHUA  ] = 2,
    [ MJLogic.HU_HAIDILAOYUE   ] = 2,
    [ MJLogic.HU_DADIAOCHE     ] = 2,
    [ MJLogic.HU_HUNYISE       ] = 2,
    [ MJLogic.HU_QINGFENG      ] = 3,
    [ MJLogic.HU_QINGYISE      ] = 3,
    [ MJLogic.HU_PENGPENGHU    ] = 3,
    [ MJLogic.HU_HUALONG       ] = 5,
    [ MJLogic.HU_ZHUOWUKUI     ] = 5,
    [ MJLogic.HU_HAOQIXIAODUI  ] = 8,
    [ MJLogic.HU_SHISANYAO     ] = 10,
    [ MJLogic.HU_2HAOQIXIAODUI ] = 16,
    [ MJLogic.HU_3HAOQIXIAODUI ] = 32,
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
function MJLogic.CanChi(hand, card, wang, ret)
    -- 吃的牌不能为风牌字牌或者癞子
    if card >= 0x31 or card == wang then
        return false
    end

    if ret == nil then
        ret = {}
    end

    -- 剔除癞子(癞子不能参与吃牌)
    local new_data = {}
    for _, v in ipairs(hand) do
        if v ~= wang then
            new_data[#new_data + 1] = v
        end
    end

    local hand_count = MJLogic.GetHandCount(new_data)
    if hand_count[card-2] and hand_count[card-1] then
        ret[#ret + 1] = {card-2, card-1}
    end
    if hand_count[card-1] and hand_count[card+1] then
        ret[#ret + 1] = {card-1, card+1}
    end
    if hand_count[card+1] and hand_count[card+2] then
        ret[#ret + 1] = {card+1, card+2}
    end

    if #ret > 0 then
        return true
    end

    return false
end

-- 判断是否可以碰
function MJLogic.CanPeng(hand, out_card, wang)
    -- 碰的牌不能为癞子
    if out_card == wang then
        return false
    end

    local duizi = MJLogic.GetDuizi(hand)
    for i, v in ipairs(duizi) do
        if v == out_card then
            return true
        end
    end
    return false
end

-- 判断是否可以杠(癞子可杠)
function MJLogic.CanGang(hand, card, wang)
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if i == card and num == 3 then
            return true
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

-- 判断是否可以接炮胡
function MJLogic.CanChiHu(hand, group_data, card, wang)
    -- 癞子不能参与吃牌
    if wang and card == wang then
        return false
    end

    local new_data = table.copyArray(hand)
    new_data[#new_data + 1] = card
    local new_data2 = clone(group_data)
    local hu_type = MJLogic.JudgeHu(new_data, new_data2, wang)
    if hu_type > 0 then
        return true
    end
    return false
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)
    local hu_type = MJLogic.JudgeHu(new_data, new_data2, wang)
    if hu_type > 0 then
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

-- 清一色(只算万条筒)
function MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    local new_data = {}
    for _, v in ipairs(hand) do
        if v ~= wang then
            if v >= 0x31 then
                return MJLogic.HU_NONE
            else
                new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
            end
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

-- 七对
function MJLogic.JudgeHu_Duidui(hand, wang, hu_card)
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

        local duizi       = MJLogic.GetDuizi(new_data)
        local danPaiCount = 14 - (2 * #duizi + jing_num)
        if jing_num >= danPaiCount then
            local kePais = MJLogic.GetKePais(new_data)
            if #kePais > 0 then
                if #kePais >= 3 then
                    return MJLogic.HU_3HAOQIXIAODUI
                elseif #kePais == 2 then
                    return MJLogic.HU_2HAOQIXIAODUI
                end
                return MJLogic.HU_HAOQIXIAODUI
            else
                -- 没有刻子牌(包括四张)
                local leftJingCount = jing_num - danPaiCount
                if leftJingCount >= 4 then
                    return MJLogic.HU_2HAOQIXIAODUI
                elseif leftJingCount >= 2 then
                    return MJLogic.HU_HAOQIXIAODUI
                else
                    return MJLogic.HU_QIXIAODUI
                end
            end
            return MJLogic.HU_QIXIAODUI
        end
    else
        local duizi = MJLogic.GetDuizi(hand)
        if #duizi == 7 then
            local gangs = MJLogic.GetGangPai(hand)
            if #gangs >= 3 then
                return MJLogic.HU_3HAOQIXIAODUI
            elseif #gangs == 2 then
                return MJLogic.HU_2HAOQIXIAODUI
            elseif #gangs == 1 then
                return MJLogic.HU_HAOQIXIAODUI
            end
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

                -- 多余的癞子加到tab2中
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

-- 混一色/清风
function MJLogic.JudgeHu_CFYISE(hand, group, wang)
    local hasFeng = false
    local wanTiaoTong = {}
    local jing_num = 0

    for _, card in ipairs(hand) do
        if card == wang then
            jing_num = jing_num + 1
        else
            if card < 0x31 then
                wanTiaoTong[#wanTiaoTong + 1] = card
            else
                hasFeng = true
            end
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

    if hasFeng then -- 没有风的情况至少是有两个癞子做将成混一色，此种情况最优解为清一色
        if #wanTiaoTong > 0 then
            local colorCount = MJLogic.GetHandColor(wanTiaoTong)
            if colorCount == 1 then
                return MJLogic.HU_HUNYISE
            end
        else
            return MJLogic.HU_QINGFENG
        end
    end

    return MJLogic.HU_NONE
end

-- 碰碰胡：4副刻子和1对(手把一又算大吊车)
function MJLogic.JudgeHu_PENGPENGHU(hand, group, wang)
    -- 不能有吃
    if group and #group > 0 then
        for _, g in ipairs(group) do
            if g[1] ~= g[2] then
                return MJLogic.HU_NONE
            end
        end
    end

    if MJLogic.JudgeHu_Normal(hand, wang, true) > 0 then
        return MJLogic.HU_PENGPENGHU
    end

    return MJLogic.HU_NONE
end

-- 花龙：3种基本花色的3副顺子组成1-9的牌型(算吃牌)
function MJLogic.JudgeHu_HUALONG(hand, group, wang)
    local new_data = {}
    local jing_num = 0

    if group and #group > 0 then
        for _, g in ipairs(group) do
            -- 只加入吃牌如{1,2,3}或{4,5,6}或{7,8,9}
            if g[1] ~= g[2] then
                local sum = MJLogic.GetValue(g[1]) + MJLogic.GetValue(g[2]) + MJLogic.GetValue(g[3])
                if sum % 9 == 6 then
                    new_data[#new_data + 1] = g[1]
                    new_data[#new_data + 1] = g[2]
                    new_data[#new_data + 1] = g[3]
                end
            end
        end
    end

    for _, v in ipairs(hand) do
        if v == wang then
            jing_num = jing_num + 1
            new_data[#new_data + 1] = MJLogic.FAKE_WANG
        else
            new_data[#new_data + 1] = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
        end
    end

    -- 花龙9张牌加1对将，new_data不可少于11张牌
    if #new_data < 11 then
        return MJLogic.HU_NONE
    end

    -- tbl1为无重复元素的表，从tbl2中找到tbl1中有的元素
    local function findSameCards(tbl1, tbl2)
        local tbl = {}
        for _, v1 in ipairs(tbl1) do
            for _, v2 in ipairs(tbl2) do
                if v1 == v2 then
                    tbl[#tbl + 1] = v1
                    break
                end
            end
        end
        return tbl
    end

    local huaLongCards = {
        {0x01, 0x02, 0x03, 0x14, 0x15, 0x16, 0x27, 0x28, 0x29},
        {0x01, 0x02, 0x03, 0x24, 0x25, 0x26, 0x17, 0x18, 0x19},
        {0x11, 0x12, 0x13, 0x04, 0x05, 0x06, 0x27, 0x28, 0x29},
        {0x11, 0x12, 0x13, 0x24, 0x25, 0x26, 0x07, 0x08, 0x09},
        {0x21, 0x22, 0x23, 0x04, 0x05, 0x06, 0x17, 0x18, 0x19},
        {0x21, 0x22, 0x23, 0x14, 0x15, 0x16, 0x07, 0x08, 0x09},
    }

    local delCards = {}
    for _, cards in ipairs(huaLongCards) do
        local sameCards = findSameCards(cards, new_data)
        if #sameCards + jing_num >= 9 then
            if #sameCards < 9 then
                local leftJingNum = jing_num - (9 - #sameCards)
                if leftJingNum > 0 then
                    for i=1, leftJingNum do
                        sameCards[#sameCards + 1] = MJLogic.FAKE_WANG
                    end
                end
            end
            delCards[#delCards + 1] = sameCards
        end
    end

    if #delCards > 0 then
        for _, cards in ipairs(delCards) do
            local new_data2 = table.copyArray(new_data)
            MJLogic.delete_card(new_data2, cards)
            if MJLogic.JudgeHu_Normal(new_data2, MJLogic.FAKE_WANG) > 0 then
                return MJLogic.HU_HUALONG
            end
        end
    end

    return MJLogic.HU_NONE
end

-- 捉五魁：胡夹五万
function MJLogic.JudgeHu_ZHUOWUKUI(hand, wang, hu_card)
    -- 胡的牌不是5万或癞子牌
    local card = 0x05
    if hu_card ~= card and hu_card ~= wang then
        return MJLogic.HU_NONE
    end

    local delCards = {{card-1, hu_card, card+1}}
    if wang then
        delCards[#delCards + 1] = {card-1, hu_card, wang}
        delCards[#delCards + 1] = {wang, hu_card, card+1}
        delCards[#delCards + 1] = {wang, hu_card, wang}
    end

    for _, cards in ipairs(delCards) do
        if MJLogic.has_card(hand, cards) then
            local new_data = table.copyArray(hand)
            MJLogic.delete_card(new_data, cards)
            if MJLogic.JudgeHu_Normal(new_data, wang) > 0 then
                return MJLogic.HU_ZHUOWUKUI
            end
        end
    end

    return MJLogic.HU_NONE
end

function MJLogic.JudgeHuTypes(hand, group, wang, hu_card, isMenQing, isZhuo5Kui, isDaDiaoChe, isHuaLong)
    local types = {}
    local hu_type = 0

    -- 门清(自摸算，点炮不算)
    if isMenQing then
        hu_type = MJLogic.JudgeHu_MENQING(hand, group)
        if hu_type > 0 then
            types[#types + 1] = hu_type
        end
    end

    -- 十三幺(可叠加门清)：不可能是以下其他
    hu_type = MJLogic.JudgeHu_SSY(hand, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
        return types
    end

    -- 清一色(只算万条筒)：不可能是清风/混一色
    hu_type = MJLogic.JudgeHu_QINGYISE(hand, group, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    else
        -- 清风/混一色
        hu_type = MJLogic.JudgeHu_CFYISE(hand, group, wang)
        if hu_type > 0 then
            types[#types + 1] = hu_type
        end
    end

    -- 捉五魁
    local isZhuoWuKui = false
    if isZhuo5Kui then
        hu_type = MJLogic.JudgeHu_ZHUOWUKUI(hand, wang, hu_card)
        if hu_type > 0 then
            types[#types + 1] = hu_type
            isZhuoWuKui = true
        end
    end

    -- 七对：不可能是碰碰胡、一条龙、花龙
    hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
    if hu_type > MJLogic.HU_QIXIAODUI then
        types[#types + 1] = hu_type
    else
        local isQiXiaoDui = hu_type == MJLogic.HU_QIXIAODUI

        -- 碰碰胡：不可能是一条龙、花龙
        hu_type = MJLogic.JudgeHu_PENGPENGHU(hand, group, wang)
        if hu_type > 0 then
            if isDaDiaoChe and #hand == 2 then
                types[#types + 1] = MJLogic.HU_DADIAOCHE
            elseif isZhuoWuKui then
                return types -- 同时是捉五魁(5分)和碰碰胡(3分)时算捉五魁
            end
            types[#types + 1] = hu_type
        else
            -- 一条龙
            hu_type = MJLogic.JudgeHu_YITIAOLONG(hand, wang)
            if hu_type > 0 then
                types[#types + 1] = hu_type
            else
                -- 花龙
                if isHuaLong and MJLogic.JudgeHu_HUALONG(hand, group, wang) > 0 then
                    types[#types + 1] = MJLogic.HU_HUALONG
                else
                    -- 同时是捉五魁(5分)和普通七对(2分)时算捉五魁
                    if isQiXiaoDui and not isZhuoWuKui then
                        types[#types + 1] = MJLogic.HU_QIXIAODUI
                    end
                end
            end
        end
    end

    return types
end

-- @return：1.胡牌类型 2.将牌
function MJLogic.JudgeHu(hand, group, wang)
    local hu_type = MJLogic.JudgeHu_SSY(hand, wang)
    if hu_type > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
    if hu_type > 0 then
        return hu_type
    end

    return MJLogic.JudgeHu_Normal(hand, wang)
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, wang, noShunZi) -- noShunZi为true时用来判断碰碰胡
    local jiang    = 0 -- 将牌(眼牌)
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
        if jiang == 1 and remainCardCount == 0 then
            return 1
        end

        for i, num in MJLogic.pairsByKeys(arr) do
            local value = MJLogic.GetValue(i) -- 当前牌处理：分别组成将刻子顺子

            -- 将
            if jiang == 0 and arr[i] >= 2 then
                jiang = jiang + 1
                arr[i] = arr[i] - 2
                remainCardCount = remainCardCount - 2
                if NormalHu() == 1 then return 1 end
                jiang = jiang - 1
                arr[i] = arr[i] + 2
                remainCardCount = remainCardCount + 2
            end

            -- 将,用一张精
            if jiang == 0 and jing_num >= 1 and arr[i] == 1 then
                jing_num = jing_num - 1
                jiang = jiang + 1
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 1
                jiang = jiang - 1
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
            end

            -- 刻子
            if arr[i] >= 3 then
                arr[i] = arr[i] - 3
                remainCardCount = remainCardCount - 3
                if NormalHu() == 1 then return 1 end
                arr[i] = arr[i] + 3
                remainCardCount = remainCardCount + 3
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

            -- 刻子,用二张精
            if jing_num >= 2 and arr[i] == 1 then
                jing_num = jing_num - 2
                arr[i] = arr[i] - 1
                remainCardCount = remainCardCount - 1
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 2
                arr[i] = arr[i] + 1
                remainCardCount = remainCardCount + 1
            end

            -- 顺子
            if not noShunZi and i < 0x31 and value < 8 and arr[i+1] > 0 and arr[i+2] > 0 then
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

            -- 顺子,顺子中间一张用精
            if not noShunZi and i < 0x31 and jing_num >= 1 and value < 8 and arr[i+2] > 0 then
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
            if not noShunZi and i < 0x31 and jing_num >= 1 and value < 9 and arr[i+1] > 0 then
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

            -- 二张精组成将牌
            if jiang == 0 and jing_num >= 2 then
                jiang = jiang + 1
                jing_num = jing_num - 2
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 2
                jiang = jiang - 1
            end

            -- 3张精组成刻子或者顺子
            if jing_num >= 3 then
                jing_num = jing_num - 3
                if NormalHu() == 1 then return 1 end
                jing_num = jing_num + 3
            end

            return 0
        end
    end

    if NormalHu() == 1 then
        return MJLogic.HU_NORMAL
    end
    return MJLogic.HU_NONE
end

return MJLogic
