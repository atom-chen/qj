local ZGZLogic = {}

ZGZLogic.CT_ERROR                   = 0      --  错误类型
ZGZLogic.CT_SINGLE                  = 1      --  单牌
ZGZLogic.CT_DOUBLE                  = 2      --  对子
ZGZLogic.CT_THREE                   = 3      --  三条
ZGZLogic.CT_BOMB                    = 4      --  炸弹
ZGZLogic.CT_LIANGSAN                = 5      --  亮三炸
ZGZLogic.CT_ROCKET                  = 6      --  火箭

--未亮方块三排序
function ZGZLogic:sortDESC( t )
    table.sort(t, function ( a,b )
        return self:GetGeneralValue(a) > self:GetGeneralValue(b)
    end)
end
--未亮三单张数值排序
function ZGZLogic:GetGeneralValue( data )
    local color = math.floor(data/16) * 16
    local value = data%16
    if color == 0x40 then --大小王排第一
        return (value+2)*5 + color/16 --80、81
    end

    if value<=4 then
        --在排序红桃三
        if color == 0x20 and value == 3 then
            return (value+13)*4 + color/16 + 7 --66加7变为73 （73设置为红桃三）
        --排序三及四 64、...、71
        else
            return (value+13)*4 + color/16
        end
    else
        return value*4 + color/16 --20、... 、55
    end
end

--亮方块三排序
function ZGZLogic:sortLiangDESC( t )
    table.sort(t, function ( a,b )
        return self:GetGeneralValueLiang(a) > self:GetGeneralValueLiang(b)
    end)
end
--亮三单张数值排序
function ZGZLogic:GetGeneralValueLiang( data )
    local color = math.floor(data/16) * 16
    local value = data%16
    if color == 0x40 then --大小王排第一
        return (value+2)*5 + color/16 --80、81
    end

    if value<=4 then
        --排序红桃三
        if color == 0x20 and value == 3 then
            return (value+13)*4 + color/16 + 7 --66->73 (73设置为红桃三)
        --在排序方块三
        elseif color == 0x00 and value == 3 then
            return (value+13)*4 + color/16 + 8 --64->72 (72设置为方块三)
        --排序三及四 56、...、64、...、71
        else
            return (value+13)*4 + color/16
        end
    else
        return value*4 + color/16 --20、... 、55
    end
end

function ZGZLogic:has_card(cards, card)
    for i,v in ipairs(cards) do
        if v == card then
            return true
        end
    end
    return false
end

-- 获取牌型
function ZGZLogic:GetCardTypeOrig( data , count, isLiang , people_num)
    if #data>=count then
        return self:GetCardType(data, isLiang, people_num)
    else
        for i=1,count-(#data) do
            table.remove(data)
        end
        return self:GetCardType(data, isLiang, people_num)
    end
end

--排序
function ZGZLogic:sortTmpDESC( t )
    table.sort(t, function ( a,b )
        return self:GetGeneralValueTmp(a) > self:GetGeneralValueTmp(b)
    end)
end
function ZGZLogic:GetGeneralValueTmp( data )
    local color = math.floor(data/16) * 16
    local value = data%16
    if color == 0x40 then
        return (value+2)*5 + color/16 --80、81
    end
    if value<=4 then
        return (value+13)*4 + color/16 --56、...、71
    else
        return value*4 + color/16
    end
end


-- 逻辑数值
function ZGZLogic:GetLogicValue( data )
    local color = math.floor(data/16) * 16
    local value = data%16

    if color == 0x40 then
        return value+4
    end

    if value<=4 then
        return value+13
    else
        return value
    end
end
-- 逻辑数值 亮三
function ZGZLogic:GetLogicValueLiang( data )
    local color = math.floor(data/16) * 16
    local value = data%16

    if color == 0x40 then
        return value+5 --19、20
    end
    if (color == 0x20 and value == 3) or (color == 0x00 and value == 3) then
        return value + 15 --18
    end
    if value<=4 then --17
        return value+13
    else
        return value
    end
end

-- 逻辑数值 亮三
function ZGZLogic:GetLogicValueNoLiang( data )
    local color = math.floor(data/16) * 16
    local value = data%16

    if color == 0x40 then
        return value+5 --19、20
    end
    if color == 0x20 and value == 3 then
        return value + 15 --18
    end
    if value<=4 then --17
        return value+13
    else
        return value
    end
end

-- 获取牌型
function ZGZLogic:GetCardType( data , isLiang, people_num)
    local count = #data

    --正常排序
        self:sortTmpDESC(data)
    -- 简单牌型
    if count==0 then        --空牌
        return ZGZLogic.CT_ERROR
    elseif count==1 then    --单牌
        return ZGZLogic.CT_SINGLE
    elseif count==2 then    --对牌火箭
        if data[1]==0x4F and data[2]==0x4E then
            return ZGZLogic.CT_ROCKET
        end
        if ((data[1]==0x23 and data[2]==0x03) or (data[1]==0x03 and data[2]==0x23)) and (isLiang or people_num == 6) then
            return ZGZLogic.CT_LIANGSAN
        end
        if self:GetLogicValue(data[1]) == self:GetLogicValue(data[2]) then
            return ZGZLogic.CT_DOUBLE
        end
        return ZGZLogic.CT_ERROR
    end

    -- 分析扑克
    local analyseResult = {
        fourCount       = 0,
        threeCount      = 0,
        doubleCount     = 0,
        singleCount     = 0,
        fourCardData    = {},
        threeCardData   = {},
        doubleCardData  = {},
        singleCardData  = {}
    }
    self:AnalyseCards(data,analyseResult)

    --[[
    WARN("singleCount",analyseResult.singleCount)
    WARN("singleCardData", singleCardData)

    WARN("doubleCount",analyseResult.doubleCount)
    WARN("doubleCardData", doubleCardData)

    WARN("threeCount",analyseResult.threeCount)
    WARN("threeCardData", threeCardData)

    WARN("fourCount",analyseResult.fourCount)
    WARN("fourCardData",analyseResult.fourCardData)
    ]]--

    if analyseResult.fourCount>0 then
        -- 炸弹
        if (analyseResult.fourCount==1) and (count==4) then return ZGZLogic.CT_BOMB end
        return ZGZLogic.CT_ERROR
    end

    if analyseResult.threeCount>0 then --存在三个一样的手牌
        -- 三条
        if (analyseResult.threeCount==1) and (count==3) then
            return  ZGZLogic.CT_THREE
        end
        return ZGZLogic.CT_ERROR
    end

    return ZGZLogic.CT_ERROR

end


--firstCards:玩家已出的牌 nextCards:玩家想出的牌 第二个参数大则可出
function ZGZLogic:CompareCard( firstCards,nextCards,isLiang,people_num)
    local firstCount = #firstCards
    local nextCount = #nextCards
    local firstType = self:GetCardType(firstCards, isLiang, people_num)
    local nextType = self:GetCardType(nextCards, isLiang, people_num)
    local firstData = firstCards
    local nextData = nextCards

    if nextType==ZGZLogic.CT_ERROR then return false end

    --火箭和亮三炸 一样大
    if isLiang or people_num == 6 then
        if firstType==ZGZLogic.CT_LIANGSAN or firstType==ZGZLogic.CT_ROCKET then return false end --玩家出亮三对或火箭 都要不起
        if nextType==ZGZLogic.CT_LIANGSAN or nextType==ZGZLogic.CT_ROCKET then return true end --亮三对或火箭可以大过任意牌
    else
        -- 火箭
        if firstType==ZGZLogic.CT_ROCKET then return false end
        if nextType==ZGZLogic.CT_ROCKET then return true end
    end

    --轰 四张一样的
    if firstType ~= ZGZLogic.CT_BOMB and nextType == ZGZLogic.CT_BOMB then return true end --轰大过任意其它牌型
    if firstType == ZGZLogic.CT_BOMB and nextType ~= ZGZLogic.CT_BOMB then return false end --其它牌型都大不过轰

    --炸弹 三张一样的
    if firstType ~= ZGZLogic.CT_THREE and nextType == ZGZLogic.CT_THREE then return true end --炸弹大过任意其它牌型
    if firstType == ZGZLogic.CT_THREE and nextType ~= ZGZLogic.CT_THREE then return false end --其它牌型都大不过炸弹

    -- 规则判断
    if firstType~=nextType or firstCount ~= nextCount then return false end --除炸弹外 牌型及出牌张数都需一致

    -- 比牌
    if nextType==ZGZLogic.CT_SINGLE then
        local firstLogicValue = 0
        local nextLogicValue = 0
        if isLiang or people_num == 6 then --亮三 红桃三 在方块三
            firstLogicValue = self:GetLogicValueLiang(firstCards[1])
            nextLogicValue = self:GetLogicValueLiang(nextCards[1])
        else
            firstLogicValue = self:GetLogicValueNoLiang(firstCards[1])
            nextLogicValue = self:GetLogicValueNoLiang(nextCards[1])
        end
        return nextLogicValue>firstLogicValue
    elseif
       nextType==ZGZLogic.CT_DOUBLE or --对子
       nextType==ZGZLogic.CT_THREE or --三条
       nextType==ZGZLogic.CT_BOMB --炸弹
    then
       local firstLogicValue = self:GetLogicValue(firstCards[1])
       local nextLogicValue = self:GetLogicValue(nextCards[1])
       return nextLogicValue>firstLogicValue
    end
    return false
end

--对牌型进行分析
function ZGZLogic:AnalyseCards( data , analyseResult)
    local count = #data

    local i = 1
    while i<=count do
        local sameCount = 1
        local logicValue = self:GetLogicValue(data[i])

        -- 搜索同牌
        for j=i+1,count do
            -- 获取扑克
            if self:GetLogicValue(data[j]) ~= logicValue then break end

            sameCount = sameCount+1
        end
        -- 设置结果
        if sameCount==1 then --该手牌只有一张
            local idx = analyseResult.singleCount
            analyseResult.singleCount = analyseResult.singleCount + 1
            analyseResult.singleCardData[idx*sameCount+1] = data[i]
        elseif sameCount==2 then
            local idx = analyseResult.doubleCount
            analyseResult.doubleCount = analyseResult.doubleCount + 1
            analyseResult.doubleCardData[idx*sameCount+1] = data[i]
            analyseResult.doubleCardData[idx*sameCount+2] = data[i+1]
        elseif sameCount==3 then
            local idx = analyseResult.threeCount
            analyseResult.threeCount = analyseResult.threeCount+1
            analyseResult.threeCardData[idx*sameCount+1] = data[i]
            analyseResult.threeCardData[idx*sameCount+2] = data[i+1]
            analyseResult.threeCardData[idx*sameCount+3] = data[i+2]
        elseif sameCount==4 then
            local idx = analyseResult.fourCount
            analyseResult.fourCount = analyseResult.fourCount + 1
            analyseResult.fourCardData[idx*sameCount+1] = data[i]
            analyseResult.fourCardData[idx*sameCount+2] = data[i+1]
            analyseResult.fourCardData[idx*sameCount+3] = data[i+2]
            analyseResult.fourCardData[idx*sameCount+4] = data[i+3]
        end

        i = i + sameCount
    end

    -- return analyseResult
end

--手牌 、 上家已出牌 、 提示出来的牌
function ZGZLogic:SearchOutCard( handCardData , turnCardData , outCardResult, isLiang, people_num)
    local cardData = handCardData
    local cardCount = #handCardData
    local turnCardCount = #turnCardData

    if cardCount <= 0 then --手牌为空
        print("SearchOutCard， handCardData为空")
        return false
    end

    self:sortTmpDESC(cardData) --手牌正常排序

    local turnType = self:GetCardType(turnCardData, isLiang, people_num) --已出牌牌型

    -- 分析扑克
    local turnAnalyseResult = {
        fourCount       = 0,
        threeCount      = 0,
        doubleCount     = 0,
        singleCount     = 0,
        fourCardData    = {},
        threeCardData   = {},
        doubleCardData  = {},
        singleCardData  = {}
    }
    self:AnalyseCards(turnCardData,turnAnalyseResult)

    if turnType == ZGZLogic.CT_ERROR then
        -- print("上家牌型错误")
        -- 手牌里最小的牌
        local logicValue = self:GetLogicValue(cardData[cardCount])
        -- 多牌判断
        local sameCount=1 --手牌里该最小的牌一共有多少张
        for i=1,cardCount-1 do
            if self:GetLogicValue(cardData[cardCount-i])==logicValue then
                sameCount=sameCount+1
            else
                break
            end
        end

        local resultCard = {}
        if sameCount>1 then
            for i=1,sameCount do
                resultCard[i] = cardData[cardCount-i+1]
            end
        else
            -- 单牌处理
            resultCard[1] = cardData[cardCount]
        end
        outCardResult[#outCardResult+1] = resultCard

    elseif (turnType == ZGZLogic.CT_SINGLE) or --单牌
           (turnType == ZGZLogic.CT_DOUBLE) --对子
        then

        local logicValue = self:GetLogicValue(turnCardData[1]) --以上牌型取第一张牌
        local analyseResult = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        -- 分析手牌
        self:AnalyseCards(cardData,analyseResult)
        -- 寻找单牌
        local table_liang_san = {} --保存手牌内最大的牌最后处理
        if turnCardCount<=1 then --上家出了一张单牌
            local function fun_LiangSan_Wang(card_data, isLiang, people_num)
                if card_data == 0x23 or (card_data == 0x03 and (isLiang or people_num == 6)) or card_data == 0x4E or card_data == 0x4F then
                    return true
                else
                    return false
                end
            end

            for i=1,analyseResult.singleCount do --循环手牌内所有单牌
                local idx = (analyseResult.singleCount-i)*1+1 --找到最小单牌的下标
                if fun_LiangSan_Wang(analyseResult.singleCardData[idx], isLiang, people_num) then --这两个三及大小王先保存不处理 最后在进行提示
                    table.insert(table_liang_san, analyseResult.singleCardData[idx])
                else
                    if not fun_LiangSan_Wang(turnCardData[1], isLiang, people_num) then --庄家没有出特殊牌
                        if self:GetLogicValue(analyseResult.singleCardData[idx]) > logicValue then --比较手牌内单牌最小值是否大于已出的单牌
                            -- 设置结果
                            outCardResult[#outCardResult+1] = {analyseResult.singleCardData[idx]}
                        end
                    end
                end
            end
            for i=1,analyseResult.doubleCount do --对牌提示其中的单牌
                local idx = (analyseResult.doubleCount-i)*2+1
                --当对子是3的时候 存在红桃三或亮方三要多提示一个三
                if self:GetLogicValue(analyseResult.doubleCardData[idx]) == 16 then --该对子是3
                    local table_hong_san = {} --红三及亮张方三
                    local table_hei_san = {} --黑三
                    for i=1,2 do
                        if analyseResult.doubleCardData[idx+i-1] == 0x23 or (analyseResult.doubleCardData[idx+i-1] == 0x03 and (isLiang or people_num == 6)) then
                            table.insert(table_hong_san, analyseResult.doubleCardData[idx+i-1])
                        else
                            table.insert(table_hei_san, analyseResult.doubleCardData[idx+i-1])
                        end
                    end

                    if #table_hong_san == 2 then
                        table.insert(table_liang_san, table_hong_san[1])
                    elseif #table_hong_san == 1 then
                        table.insert(table_liang_san, table_hong_san[1])
                        if logicValue ~= 16 and logicValue ~= 17 then --玩家没出三
                            table.insert(table_liang_san, table_hei_san[1])
                        end
                    else
                        if logicValue ~= 16 and logicValue ~= 17 then
                            table.insert(table_liang_san, table_hei_san[1])
                        end
                    end
                else
                    if not fun_LiangSan_Wang(turnCardData[1], isLiang, people_num) then --庄家没有出特殊牌
                        if self:GetLogicValue(analyseResult.doubleCardData[idx])>logicValue then
                            local resultCard = {}
                            for i=1,turnCardCount do
                                resultCard[i] = analyseResult.doubleCardData[idx+i-1]
                            end
                            outCardResult[#outCardResult+1] = resultCard
                        end
                    end
                end
            end

            for i=1,analyseResult.threeCount do --炸弹提示其中的单牌
                local idx = (analyseResult.threeCount-i)*3+1
                --当炸弹是3的时候 存在红桃三或亮方三要多提示一个三
                if self:GetLogicValue(analyseResult.threeCardData[idx]) == 16 then --该炸弹是3
                    local table_hong_san = {} --红三及亮张方三
                    local table_hei_san = {} --黑三
                    for i=1,3 do
                        if analyseResult.threeCardData[idx+i-1] == 0x23 or (analyseResult.threeCardData[idx+i-1] == 0x03 and (isLiang or people_num == 6)) then
                            table.insert(table_hong_san, analyseResult.threeCardData[idx+i-1])
                        else
                            table.insert(table_hei_san, analyseResult.threeCardData[idx+i-1])
                        end
                    end
                    if #table_hong_san == 2 or #table_hong_san == 1 then --存在红三时
                        table.insert(table_liang_san, table_hong_san[1])
                        if logicValue ~= 16 and logicValue ~= 17 then --玩家没出三四
                            table.insert(table_liang_san, table_hei_san[1])
                        end
                    else
                        if logicValue ~= 16 and logicValue ~= 17 then --玩家没出三四
                            table.insert(table_liang_san, table_hei_san[1])
                        end
                    end
                else
                    if not fun_LiangSan_Wang(turnCardData[1], isLiang, people_num) then --庄家没有出特殊牌
                        if self:GetLogicValue(analyseResult.threeCardData[idx])>logicValue then
                            local resultCard = {}
                            for i=1,turnCardCount do
                                resultCard[i] = analyseResult.threeCardData[idx+i-1]
                            end
                            outCardResult[#outCardResult+1] = resultCard
                        end
                    end
                end
            end

            for i=1,analyseResult.fourCount do --轰提示其中的单牌
                local idx = (analyseResult.fourCount-i)*4+1
                --当轰全是3的时候 存在红桃三或亮方三要多提示一个三
                if self:GetLogicValue(analyseResult.fourCardData[idx]) == 16 then --该轰是3
                    local table_hong_san = {} --红三及亮张方三
                    local table_hei_san = {} --黑三
                    for i=1,4 do
                        if analyseResult.fourCardData[idx+i-1] == 0x23 or (analyseResult.fourCardData[idx+i-1] == 0x03 and (isLiang or people_num == 6)) then
                            table.insert(table_hong_san, analyseResult.fourCardData[idx+i-1])
                        else
                            table.insert(table_hei_san, analyseResult.fourCardData[idx+i-1])
                        end
                    end
                    table.insert(table_liang_san, table_hong_san[1])
                    if logicValue ~= 16 and logicValue ~= 17 then --玩家没出三四
                        table.insert(table_liang_san, table_hei_san[1])
                    end
                else
                    if not fun_LiangSan_Wang(turnCardData[1], isLiang, people_num) then --庄家没有出特殊牌
                        if self:GetLogicValue(analyseResult.fourCardData[idx])>logicValue then
                            local resultCard = {}
                            for i=1,turnCardCount do
                                resultCard[i] = analyseResult.fourCardData[idx+i-1]
                            end
                            outCardResult[#outCardResult+1] = resultCard
                        end
                    end
                end
            end

            --最后处理未提示的方块三及大小王
            if table_liang_san then
                for i,v in ipairs(table_liang_san) do
                    if turnCardData[1] == 0x23 or (turnCardData[1] == 0x03 and (isLiang or people_num == 6)) then --玩家出了亮三 只提示大小王
                        if v == 0x4E or v == 0x4F then
                           outCardResult[#outCardResult+1] = {v}
                        end
                    elseif turnCardData[1] == 0x4E or turnCardData[1] == 0x4F then --玩家出了小王或大王 只提示大王
                        if v == 0x4F then
                            outCardResult[#outCardResult+1] = {v}
                        end
                    else --玩家出了其它牌 都需要进行提示
                        outCardResult[#outCardResult+1] = {v}
                    end
                end
            end
        end

        -- 寻找对牌
        if turnCardCount==2 then
            for i=1,analyseResult.doubleCount do
                local idx = (analyseResult.doubleCount-i)*2+1
                if self:GetLogicValue(analyseResult.doubleCardData[idx])>logicValue then
                    local resultCard = {}
                    for i=1,turnCardCount do
                        resultCard[i] = analyseResult.doubleCardData[idx+i-1]
                    end
                    outCardResult[#outCardResult+1] = resultCard
                end
            end
        end
    end

    -- 提示炸弹
    if (cardCount>=3) and (turnType ~= ZGZLogic.CT_ROCKET and turnType ~= ZGZLogic.CT_LIANGSAN) then --手牌数目至少三张并且上家没有出火箭和亮三炸
        local logicValueThree = 0 --上家出牌的值
        local logicValueFour = 0 --上家出牌的值
        if turnType==ZGZLogic.CT_THREE then
            logicValueThree = self:GetLogicValue(turnCardData[1])
        end
        if turnType==ZGZLogic.CT_BOMB then
            logicValueFour = self:GetLogicValue(turnCardData[1])
        end

        local analyseResultHand = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        self:AnalyseCards(handCardData,analyseResultHand)

        if turnType ~= ZGZLogic.CT_BOMB then --上家没出轰就需要提示3牌炸
            local resultCard = {}
            for i=1,analyseResultHand.threeCount do
                local idx = (analyseResultHand.threeCount-i)*3 + 1
                local handCardData = analyseResultHand.threeCardData[idx]
                local handLogicValue = self:GetLogicValue(handCardData)
                if handLogicValue > logicValueThree then
                    for i=1,3 do
                        resultCard[i] = analyseResultHand.threeCardData[idx+i-1]
                    end
                    break
                end
            end
            if #resultCard == 3 then
                outCardResult[#outCardResult+1] = resultCard
            end
        end

        --提示轰
        local resultCard = {}
        for i=1,analyseResultHand.fourCount do
            local idx = (analyseResultHand.fourCount-i)*4 + 1
            local handCardData = analyseResultHand.fourCardData[idx]
            local handLogicValue = self:GetLogicValue(handCardData)
            if handLogicValue > logicValueFour then
                for i=1,4 do
                    resultCard[i] = analyseResultHand.fourCardData[idx+i-1]
                end
                break
            end
        end
        if #resultCard == 4 then
            outCardResult[#outCardResult+1] = resultCard
        end
    end

    --提示亮三
    if turnType ~= ZGZLogic.CT_ROCKET and turnType ~= ZGZLogic.CT_LIANGSAN then
        if (cardCount>=2) and (isLiang or people_num == 6) then
            local table_shuang_san = {}
            for _,v in ipairs(cardData) do
                if v == 0x03 or v == 0x23 then
                    table.insert(table_shuang_san, v)
                end
            end
            if #table_shuang_san == 2 then
                local resultCard = {}
                resultCard[1] = table_shuang_san[1]
                resultCard[2] = table_shuang_san[2]
                outCardResult[#outCardResult+1] = resultCard
            end
        end

        -- 提示火箭
        if (cardCount>=2) and (cardData[1]==0x4F) and (cardData[2]==0x4E) then
            local resultCard = {}
            resultCard[1] = cardData[1]
            resultCard[2] = cardData[2]
            outCardResult[#outCardResult+1] = resultCard
        end
    end
end

function ZGZLogic:GetColor( data )
    --return cc_math:bit_and(data, 0xF0)
    return math.floor(data/16) * 16
end
function ZGZLogic:GetValue( data )
    return data % 16
end

return ZGZLogic