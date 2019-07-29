local table_insert = table.insert
local table_remove = table.remove

local MJLogic = class("MJLogic")

MJLogic.FAKE_WANG = 0x44 -- 假赖子，判断用
MJLogic.CARD_FLAG = 0x80 -- 牌值大于0x80，则是特殊牌：可能是其它玩家打的耗子牌，要当普通牌处理或者玩家听时，最后出的牌
function MJLogic.copyArray(oldTbl)
    local newTble = {}
    if oldTbl == nil then
        return newTble
    end
    for key,value in pairs(oldTbl) do
        if type(value) == "table" then
            newTble[key] = {}
            self:deepCopy(newTble[key], value)
        elseif type(value) == "userdata" then
            newTble[key] = value
        elseif type(value) == "thread" then
            newTble[key] = value
        else
            newTble[key] = value
        end
    end
    return newTble
end

function table.copyArray(oldTbl)
    local newTble = {}
    if oldTbl == nil then
        return newTble
    end
    for key,value in pairs(oldTbl) do
        if type(value) == "table" then
            newTble[key] = {}
            self:deepCopy(newTble[key], value)
        elseif type(value) == "userdata" then
            newTble[key] = value
        elseif type(value) == "thread" then
            newTble[key] = value
        else
            newTble[key] = value
        end
    end
    return newTble
end

function table_unique(t)
    local check = {};
    local n = {};
    for key , value in pairs(t) do
        if not check[value] then
            n[key] = value
            check[value] = value
        end
    end
    return n
end

-- 统计
MJLogic.HS_ZIMO       = 1    -- 自摸(小胡)
MJLogic.HS_JIEPAO     = 2    -- 接炮(小胡)
MJLogic.HS_DIANPAO    = 3    -- 点炮(小胡)
MJLogic.HS_MINGGANG   = 4    -- 明杠
MJLogic.HS_ANGANG     = 5    -- 暗杠
MJLogic.HS_DA_ZIMO    = 6    -- 自摸(大胡)
MJLogic.HS_DA_JIEPAO  = 7    -- 接炮(大胡)
MJLogic.HS_DA_DIANPAO = 8    -- 点炮(大胡)

-- 牌型
MJLogic.CT_WANZI   = 0x00 -- 万
MJLogic.CT_TONGZI  = 0x10 -- 筒
MJLogic.CT_SUOZI   = 0x20 -- 条
MJLogic.CT_FENGPAI = 0x30 -- 风牌
MJLogic.CT_JIANPAI = 0x40 -- 箭牌
MJLogic.CT_HUAPAI  = 0x50 -- 花牌

-- 胡牌
MJLogic.HU_NONE         = 0 -- 没有胡
MJLogic.HU_NORMAL       = 1 -- 普通胡(顺子刻子将组成)
MJLogic.HU_QIXIAODUI    = 2 -- 七小对
MJLogic.HU_YITIAOLONG   = 3 -- 一条龙
MJLogic.HU_QINGYISE     = 4 -- 清一色
MJLogic.HU_HAOQIXIAODUI = 5 -- 豪华七小对
MJLogic.HU_SHISANYAO    = 6 -- 十三幺

MJLogic.HUSCORES = {
    [ MJLogic.HU_NORMAL       ] = 2,
    [ MJLogic.HU_QIXIAODUI    ] = 3,
    [ MJLogic.HU_YITIAOLONG   ] = 3,
    [ MJLogic.HU_QINGYISE     ] = 3,
    [ MJLogic.HU_HAOQIXIAODUI ] = 6,
    [ MJLogic.HU_SHISANYAO    ] = 9,
}

MJLogic.CARD_ALL = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
    0x31, 0x32, 0x33, 0x34,
    0x41, 0x42, 0x43
}

MJLogic.CARD_ALL2 = {
    [0]  = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09},
    [16] = {0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19},
    [32] = {0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29},
    [48] = {0x41},
    [64] = {0x41},
}

function MJLogic.print_cards(arr)
    for i, v in MJLogic.pairsByKeys(arr) do
        if v > 0 then
            print(string.format("0x%02x %d", i, v))
        end
    end
end

-- 获取花色
function MJLogic.GetColor(card)
    return math.floor(card / 16)
end

-- 获取数值
function MJLogic.GetValue(card)
    return card % 16
end

function MJLogic.NextCard(card)
    local color = MJLogic.GetColor(card)
    local value = MJLogic.GetValue(card)
    local nextValue = 0
    if color <= 32 then
        nextValue = (value == 9 and 1 or value + 1)
    elseif color == 48 then
        nextValue = (value == 4 and 1 or value + 1)
    elseif color == 64 then
        nextValue = (value == 3 and 1 or value + 1)
    end
    return tonumber(color + nextValue)
end

function MJLogic.PrevCard(card)
    local color = MJLogic.GetColor(card)
    local value = MJLogic.GetValue(card)
    local prevValue = 0
    if color <= 32 then
        prevValue = (value == 1 and 9 or value - 1)
    elseif color == 48 then
        prevValue = (value == 1 and 4 or value - 1)
    elseif color == 64 then
        prevValue = (value == 1 and 3 or value - 1)
    end
    return tonumber(color + prevValue)
end

-- 统计手牌的各个牌的数量
-- @return:牌->牌数的索引表
function MJLogic.GetHandCount(hand)
    local hand_count = {}
    for i, v in ipairs(hand) do
        if hand_count[v] == nil then
            hand_count[v] = 1
        else
            hand_count[v] = hand_count[v] + 1
        end
    end
    return hand_count
end

-- 得到一个按key值从小到大顺序访问的迭代器。只考虑value大于0的key。每次迭代返回一个key与value
-- lua 自带的pairs迭代器不能保证按key值大小顺序索引
function MJLogic.pairsByKeys(tbl)
    local keys = {}
    for k, v in pairs(tbl) do
        if v > 0 then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)

    local i = 0
    return function()
        i = i + 1
        return keys[i], tbl[keys[i]]
    end
end

function MJLogic.has_card(cards, tbl)
    local count = 0
    local data = {}
    for _, v in ipairs(tbl) do
        if not data[v] then
            data[v] = 0
        end
        data[v] = data[v] + 1
        count = count + 1
    end

    for i = #cards, 1, -1 do
        local v = cards[i]
        if data[v] and data[v] > 0 then
            data[v] = data[v] - 1
            count = count - 1
        end
    end
    return count == 0
end

function MJLogic.delete_card(cards, tbl)
    local remove = {}
    for k,v in ipairs(tbl) do
        if not remove[v] then
            remove[v] = 0
        end
        remove[v] = remove[v] + 1
    end

    for i = #cards, 1, -1 do
        local v = cards[i]
        if remove[v] and remove[v] > 0 then
            table_remove(cards, i)
            remove[v] = remove[v] - 1
        end
    end
end

function MJLogic.delete_by_card(cards, card)
    for i = #cards, 1, -1 do
        local v = cards[i]
        if v == card then
            table_remove(cards, i)
        end
    end
end

function MJLogic.in_array_obj(arr, obj)
    if not arr or #arr == 0 then
        return false
    end
    for _, v in ipairs(arr) do
        if v == obj then
            return true
        end
    end
    return false
end

-- 从小到大排序
function MJLogic.sortASCE(tbl)
    table.sort(tbl)
end

function MJLogic.Shaizi()
    local shaizi = {}
    math.randomseed(getmicrosecond())
    shaizi[1] = math.random(1, 3)
    math.randomseed(getmicrosecond())
    shaizi[2] = math.random(7, 10) - 6
    return shaizi
end

-- 判断剩余牌的数量
function MJLogic.RemainCard(arr)
    local sum = 0
    for _, v in pairs(arr) do
        sum = sum + v
    end
    return sum
end

-- 统计手上牌的颜色数量
-- @return: 总花色数量，花色->数量的索引表
function MJLogic.GetHandColor(hand)
    local colorCounts = {}
    local wholeColorCount = 0
    for i, v in ipairs(hand) do
        local color = MJLogic.GetColor(v)
        if colorCounts[color] == nil then
            colorCounts[color] = 1
            wholeColorCount = wholeColorCount + 1
        else
            colorCounts[color] = colorCounts[color] + 1
        end
    end
    return wholeColorCount, colorCounts
end

-- 获取所有对子
function MJLogic.GetDuizi(hand)
    local duizi = {}
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if num >= 2 and num < 4 then
            table.insert(duizi, i)
        elseif num == 4 then
            table.insert(duizi, i)
            table.insert(duizi, i)
        end
    end
    return duizi
end

-- 手上的刻牌
function MJLogic.GetKePais(hand)
    local kePais = {}
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if num >= 3 then
            kePais[#kePais + 1] = i
        end
    end
    return kePais
end

-- 加杠
-- @param hand: 手牌
-- @param group: 牌面上的碰牌
-- @param gang_cards: 要加上明杠的牌
-- @param pass: 不要的牌
function MJLogic.GetGroupGangpai(hand, group, pass)
    local cards = {}
    for i, card in ipairs(hand) do
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

-- 暗杠
function MJLogic.GetGangPai(hand)
    local gangs = {}
    local hand_count = MJLogic.GetHandCount(hand)
    for i, num in MJLogic.pairsByKeys(hand_count) do
        if num == 4 then
            table.insert(gangs, i)
        end
    end
    return gangs
end

return MJLogic
