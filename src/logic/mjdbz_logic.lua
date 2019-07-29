--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-07-16
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2018-07-30
-- @Desc: 麻将保定打八张逻辑
--------------------------------------------------------------------------------
local MJLogic = require("logic.mj_logic")

local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJDBZLogic", MJLogic)

MJLogic.HU_FENGYISE      = 111  -- 风一色(全风牌)
MJLogic.HU_HUNYISE       = 119  -- 混一色
MJLogic.HU_2HAOQIXIAODUI = 122  -- 双豪七对
MJLogic.HU_3HAOQIXIAODUI = 123  -- 三豪七对

MJLogic.HUSCORES = {
    [ MJLogic.HU_HUNYISE       ] = 2,
    [ MJLogic.HU_QIXIAODUI     ] = 2,
    [ MJLogic.HU_YITIAOLONG    ] = 2,
    [ MJLogic.HU_QINGYISE      ] = 4,
    [ MJLogic.HU_FENGYISE      ] = 8,
    [ MJLogic.HU_SHISANYAO     ] = 10,
    [ MJLogic.HU_HAOQIXIAODUI  ] = 4,
    [ MJLogic.HU_2HAOQIXIAODUI ] = 8,
    [ MJLogic.HU_3HAOQIXIAODUI ] = 16,
}

-- 判断硬八张：万，筒，条，风任意一种满足八张
function MJLogic.isDaBaZhang(hand, group, wang)
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

-- 得到所有能杠的牌。包括暗杠和加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param pass: 不要的牌
function MJLogic.GetCanGang(hand, group, pass, kouCard)
    local anGangCards = MJLogic.GetGangPai(hand, kouCard)
    local jiaGangCards = MJLogic.GetGroupGangpai(hand, group, pass, kouCard)

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
function MJLogic.CanPeng(hand, out_card, kouCard)
    local TmpKouCard = table.copyArray(kouCard)
    local TmpHand = table.copyArray(hand)

    if not TmpHand then --一张手牌都没有 全是扣牌
        return false
    end

    local new_data = table.copyArray(hand)
    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌
            table.insert(new_data, v)
        end
    end

    local duizi = MJLogic.GetDuizi(new_data)
    for i, v in ipairs(duizi) do
        if v == out_card then
            if TmpKouCard then --存在扣牌时判断碰完后是否还有手牌可以出 没有则不能碰
                if #TmpHand >= 3 then --手牌大于三张则可碰
                    return true
                elseif #TmpHand == 2 then --手牌只有两张时 扣牌里面至少有一张则可碰
                    for j, val in pairs(TmpKouCard) do
                        if val == out_card then
                            return true
                        end
                    end
                    return false
                elseif #TmpHand == 1 then --手牌只有一张 则两张碰牌都为扣牌
                    local num = 0
                    for j, val in pairs(TmpKouCard) do
                        if val == out_card then
                            num = num + 1
                        end
                    end
                    if num >= 2 then
                        return true
                    else
                        return false
                    end
                else --手牌没有则肯定不可以碰
                    return false
                end
            else
                return true
            end
        end
    end
    return false
end

-- 判断是否可以杠指定的牌
function MJLogic.CanGang(hand, card, kouCard)
    local new_data = table.copyArray(hand)
    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌
            table.insert(new_data, v)
        end
    end

    local hand_count = MJLogic.GetHandCount(new_data) --牌->牌数
    for i, num in MJLogic.pairsByKeys(hand_count) do --按key值排序
        if i == card and num == 3 then
            return true
        end
    end
    return false
end

-- 判断是否出牌后可以听牌
function MJLogic.CanOutToTing(hand, group, wang, isYingBaZhang)
    wang = wang or MJLogic.FAKE_WANG
    local setCard = table.unique(hand, true)
    for i, v in ipairs(setCard) do
        local new_data = table.copyArray(hand)
        MJLogic.delete_card(new_data, {v})
        new_data[#new_data + 1] = wang
        if MJLogic.JudgeHu(new_data, group, wang, isYingBaZhang) > 0 then
            return true
        end
    end
    return false
end

-- 判断能否听牌
function MJLogic.CanTing(hand, group, wang, isYingBaZhang)
    wang = wang or MJLogic.FAKE_WANG
    local new_data = table.copyArray(hand)
    new_data[#new_data + 1] = wang
    if MJLogic.JudgeHu(new_data, group, wang, isYingBaZhang) > 0 then
        return true
    end
    return false
end


-- 判断是否可以接炮胡
-- 如果card 为耗子，则要把耗子当普通牌处理，这里将该牌加0x80来和耗子区分。
-- 即如果牌值大于0x80，则该张牌是由其它玩家打的耗子牌，不能当耗子来处理
function MJLogic.CanChiHu(hand, group_data, card, wang, isYingBaZhang, kouCard)
        -- 癞子不能参与吃牌
    if wang and card == wang then
        return false
    end
    local new_data = table.copyArray(hand)
    new_data[#new_data + 1] = card
    local new_data2 = clone(group_data)

    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌判断胡
            table.insert(new_data, v)
        end
    end

    if MJLogic.JudgeHu(new_data, new_data2, wang, isYingBaZhang) > 0 then
        return true
    end
    return false
end

-- 判断自摸
function MJLogic.CanZimoHu(hand, group_data, wang, isYingBaZhang, kouCard)
    local new_data = table.copyArray(hand)
    local new_data2 = clone(group_data)

    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌判断胡
            table.insert(new_data, v)
        end
    end

    if MJLogic.JudgeHu(new_data, new_data2, wang, isYingBaZhang) > 0 then
        return true
    end
    return false
end

-- 获取听牌列表
function MJLogic.CetTingCards(hand, group, wang, isYingBaZhang)
    local ting_cards = {}
    local new_data = table.copyArray(hand)
    for _, card in ipairs(MJLogic.CARD_ALL) do
        new_data[#new_data + 1] = card
        local hu = MJLogic.JudgeHu(new_data, group, wang, isYingBaZhang)
        if hu > 0 then
            table.insert(ting_cards, card)
        end
        new_data[#new_data] = nil
    end
    return ting_cards
end

function MJLogic.JudgeHu_Duidui(hand, wang, hu_card)
    if #hand ~= 14 then
        return MJLogic.HU_NONE
    end

    if wang then
        local arr = {}
        local jing_num = 0
        for _, v in ipairs(hand) do
            if v == wang then
                jing_num = jing_num + 1
            else
                local card = v < MJLogic.CARD_FLAG and v or v - MJLogic.CARD_FLAG
                arr[card] = arr[card] and arr[card] + 1 or 1
            end
        end

        local anGang = 0

        local function duiDui()
            if MJLogic.RemainCard(arr) == 0 then return 1 end
            for i, num in MJLogic.pairsByKeys(arr) do
                if num > 0 then
                    if jing_num >= 2 and num == 2 then
                        arr[i] = arr[i] - num
                        jing_num = jing_num - 2
                        anGang = anGang + 1
                        if duiDui() == 1 then return 1 end
                        arr[i] = arr[i] + num
                        jing_num = jing_num + 2
                        anGang = anGang - 1
                    end

                    if jing_num >= 1 and (num == 1 or num == 3) then
                        arr[i] = arr[i] - num
                        jing_num = jing_num - 1
                        if num == 3 then anGang = anGang + 1 end
                        if duiDui() == 1 then return 1 end
                        arr[i] = arr[i] + num
                        jing_num = jing_num + 1
                        if num == 3 then anGang = anGang - 1 end
                    end

                    if num == 2 or num == 4 then
                        arr[i] = arr[i] - num
                        if num == 4 then anGang = anGang + 1 end
                        if duiDui() == 1 then return 1 end
                        arr[i] = arr[i] + num
                        if num == 4 then anGang = anGang - 1 end
                    end
                end
            end
            return 0
        end

        if duiDui() == 1 then
            if anGang >= 3 then
                return MJLogic.HU_3HAOQIXIAODUI
            elseif anGang == 2 then
                return MJLogic.HU_2HAOQIXIAODUI
            elseif anGang == 1 then
                return MJLogic.HU_HAOQIXIAODUI
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
            return MJLogic.HU_FENGYISE
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

-- 清一色 (胡牌)
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

function MJLogic.JudgeHuTypes(hand, group, wang, hu_card, kouCard)
    local types = {}
    local hu_type = 0

    -- 十三幺(可叠加门清)：不可能是以下其他
    local new_data = table.copyArray(hand)
    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌
            table.insert(new_data, v)
        end
    end


    hu_type = MJLogic.JudgeHu_SSY(new_data, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
        return types
    end

    -- 七对：不可能是碰碰胡、一条龙、花龙
    hu_type = MJLogic.JudgeHu_Duidui(new_data, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    else
        -- -- 碰碰胡：不可能是一条龙、花龙
        -- hu_type = MJLogic.JudgeHu_PENGPENGHU(new_data, group, wang)
        -- if hu_type > 0 then
        --     types[#types + 1] = hu_type
        -- else
            -- 一条龙
            hu_type = MJLogic.JudgeHu_YITIAOLONG(new_data, wang)
            if hu_type > 0 then
                types[#types + 1] = hu_type
            end
        -- end
    end

    local all_beishu = 1
    for _, v in ipairs(types) do
            all_beishu = all_beishu * MJLogic.HUSCORES[v]
    end

    -- 清一色(只算万条筒)：不可能是清风/混一色
    hu_type = MJLogic.JudgeHu_QINGYISE(new_data, group, wang)
    if hu_type > 0 then
        types[#types + 1] = hu_type
    else
        -- 清风/混一色
        hu_type = MJLogic.JudgeHu_CFYISE(new_data, group, wang)
        if hu_type > 0 then
            if MJLogic.HUSCORES[hu_type] > all_beishu then --胡清风或混一色比较大 则舍弃其余所有的
                types = {}
                types[#types + 1] = hu_type
            end
        end
    end
    return types
end

function MJLogic.JudgeHu(hand, group, wang, isYingBaZhang)
    local hu_type = 0


    if isYingBaZhang and not MJLogic.isDaBaZhang(hand, group, wang) then
        return 0
    end

    hu_type = MJLogic.JudgeHu_Duidui(hand, wang)
    if hu_type > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_SSY(hand, wang)
    if hu_type > 0 then
        return hu_type
    end

    hu_type = MJLogic.JudgeHu_Normal(hand, group, wang)
    if hu_type > 0 then
        return hu_type
    end

    return hu_type
end

-- 判断普通胡
function MJLogic.JudgeHu_Normal(hand, group, wang)
    local jiang    = 0 -- 将牌(眼牌)
    local jing_num = 0 -- 精牌数量
    local remainCardCount = 0
    local arr      = {}
    -- 这里要放入所有的牌(所有牌的单个)，因为下面顺子的处理会用到当前牌的前后张数量
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

-- 暗杠
function MJLogic.GetGangPai(hand, kouCard)
    local new_data = table.copyArray(hand)
    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌
            table.insert(new_data, v)
        end
    end

    local gangs = {}
    local hand_count = MJLogic.GetHandCount(new_data)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if num == 4 then
            table.insert(gangs, i)
        end
    end
    return gangs
end

-- 加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param gang_cards: 要加上明杠的牌
-- @param pass: 不要的牌
function MJLogic.GetGroupGangpai(hand, group, pass, kouCard)
    local new_data = table.copyArray(hand)
    if kouCard then
        for _, v in pairs(kouCard) do --插入扣牌
            table.insert(new_data, v)
        end
    end

    local cards = {}
    for i, card in ipairs(new_data) do
        for j, g in ipairs(group) do
            if card == g[1] and card == g[2] and card == g[3] and g[4] == nil then
                if MJLogic.in_array_obj(pass, card) == false then
                    table.insert(cards, card)
                end
            end
        end
    end
    return cards
end

return MJLogic
