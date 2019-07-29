local DDZLogic = {}

DDZLogic.CT_ERROR                  = 0      --  错误类型
DDZLogic.CT_SINGLE                 = 1      --  单排
DDZLogic.CT_DOUBLE                 = 2      --  对子
DDZLogic.CT_THREE                  = 3      --  三条
DDZLogic.CT_SINGLE_LINE            = 4      --  顺子
DDZLogic.CT_DOUBLE_LINE            = 5      --  连对
DDZLogic.CT_THREE_TAKE_SINGLE      = 6      --  三带1
DDZLogic.CT_THREE_TAKE_DOUBLE      = 7      --  三带1对
DDZLogic.CT_THREE_LINE             = 8      --  飞机：三顺
DDZLogic.CT_THREE_LINE_TAKE_SINGLE = 9      --  飞机带翅膀： 三顺+同数量一手牌。比如777888+3+6或444555666+33+77+88
DDZLogic.CT_THREE_LINE_TAKE_DOUBLE = 10     --  飞机带翅膀： 三顺+同数量一手牌。比如777888+3+6或444555666+33+77+88
DDZLogic.CT_FOUR_TAKE_SINGLE       = 11     --  四带二：四条+2手牌。比如AAAA+7+9或9999+33+55
DDZLogic.CT_FOUR_TAKE_DOUBLE       = 12     --  四带二：四条+2手牌。比如AAAA+7+9或9999+33+55
DDZLogic.CT_BOMB                   = 13     --  炸弹
DDZLogic.CT_ROCKET                 = 14     --  火箭

-- local analyseResult = {
--     fourCount       = 0,
--     threeCount      = 0,
--     doubleCount     = 0,
--     singleCount     = 0,
--     fourCardData    = {},
--     threeCardData   = {},
--     doubleCardData  = {},
--     singleCardData  = {}
-- }

function DDZLogic:sortDESC(t)
    table.sort(t, function (a, b)
        return self:GetGeneralValue(a) > self:GetGeneralValue(b)
    end)
end

function DDZLogic:GetGeneralValue(data)
    local color = math.floor(data / 16)
    local value = data % 16
    if color == 4 then
        return (value + 2) * 4 + 4
    end
    if value <= 2 then
        return (value + 13) * 4 + 4
    else
        return value * 4 + 4
    end
end

-- 逻辑数值
function DDZLogic:GetLogicValue(data)
    local color = math.floor(data / 16)
    local value = data % 16

    if color == 4 then
        return value + 2
    end

    if value <= 2 then
        return value + 13
    else
        return value
    end
end

-- 获取牌型
function DDZLogic:GetCardTypeOrig(data, count)
    if #data >= count then
        return self:GetCardType(data)
    else
        for i = 1, count - (#data) do
            table.remove(data)
        end
        return self:GetCardType(data)
    end
end

-- 获取牌型
function DDZLogic:GetCardType(data)
    local count = #data

    -- 排序 降序
    self:sortDESC(data)

    -- 简单牌型
    if count == 0 then -- 空牌
        return DDZLogic.CT_ERROR
    elseif count == 1 then -- 单牌
        return DDZLogic.CT_SINGLE
    elseif count == 2 then -- 对牌火箭
        if data[1] == 79 and data[2] == 78 then
            return DDZLogic.CT_ROCKET
        end
        if self:GetLogicValue(data[1]) == self:GetLogicValue(data[2]) then
            return DDZLogic.CT_DOUBLE
        end

        return DDZLogic.CT_ERROR
    end

    -- 分析扑克
    local analyseResult = {
        fourCount      = 0,
        threeCount     = 0,
        doubleCount    = 0,
        singleCount    = 0,
        fourCardData   = {},
        threeCardData  = {},
        doubleCardData = {},
        singleCardData = {}
    }
    self:AnalyseCards(data, analyseResult)

    -- print("singleCount",analyseResult.singleCount)
    -- for i,v in ipairs(analyseResult.singleCardData) do
    --     print(i,v)
    -- end
    -- print("doubleCount",analyseResult.doubleCount)
    -- for i,v in ipairs(analyseResult.doubleCardData) do
    --     print(i,v)
    -- end
    -- print("threeCount",analyseResult.threeCount)
    -- for i,v in ipairs(analyseResult.threeCardData) do
    --     print(i,v)
    -- end
    -- print("fourCount",analyseResult.fourCount)
    -- for i,v in ipairs(analyseResult.fourCardData) do
    --     print(i,v)
    -- end

    if analyseResult.fourCount > 0 then
        -- 炸弹
        if (analyseResult.fourCount == 1) and (count == 4) then return DDZLogic.CT_BOMB end
        -- 四带2
        if (analyseResult.fourCount == 1) and (analyseResult.singleCount == 2) and (count == 6) then return DDZLogic.CT_FOUR_TAKE_SINGLE end
        if (analyseResult.fourCount == 1) and (analyseResult.doubleCount == 2) and (count == 8) then return DDZLogic.CT_FOUR_TAKE_DOUBLE end

        return DDZLogic.CT_ERROR
    end

    if analyseResult.threeCount > 0 then
        -- 三条
        if (analyseResult.threeCount == 1) and (count == 3) then
            return DDZLogic.CT_THREE
        end
        -- 三带1
        if (analyseResult.threeCount == 1) and (analyseResult.singleCount == 1) and (count == 4) then
            return DDZLogic.CT_THREE_TAKE_SINGLE
        end
        -- 三带1对
        if (analyseResult.threeCount == 1) and (analyseResult.doubleCount == 1) and (count == 5) then
            return DDZLogic.CT_THREE_TAKE_DOUBLE
        end

        -- 连牌判断
        if analyseResult.threeCount > 1 then
            local cardData        = analyseResult.threeCardData[1]
            local firstLogicValue = self:GetLogicValue(cardData)
            -- 错误过滤
            if firstLogicValue >= 15 then return DDZLogic.CT_ERROR end
            -- 连牌判断
            for i = 1, analyseResult.threeCount - 1 do
                local cardData = analyseResult.threeCardData[i * 3 + 1]
                if firstLogicValue ~= self:GetLogicValue(cardData) + i then return DDZLogic.CT_ERROR end
            end
        end

        -- 飞机
        if analyseResult.threeCount * 3 == count then return DDZLogic.CT_THREE_LINE end
        if (analyseResult.threeCount * 4 == count) then return DDZLogic.CT_THREE_LINE_TAKE_SINGLE end
        if (analyseResult.threeCount * 5 == count) and (analyseResult.threeCount == analyseResult.doubleCount) then return DDZLogic.CT_THREE_LINE_TAKE_DOUBLE end

        return DDZLogic.CT_ERROR
    end

    if analyseResult.doubleCount >= 3 then
        local firstLogicValue = self:GetLogicValue(analyseResult.doubleCardData[1])

        -- 错误过滤
        if firstLogicValue >= 15 then return DDZLogic.CT_ERROR end
        -- 连牌判断
        for i = 1, analyseResult.doubleCount - 1 do
            local cardData = analyseResult.doubleCardData[i * 2 + 1]
            if firstLogicValue ~= (self:GetLogicValue(cardData) + i) then return DDZLogic.CT_ERROR end
        end

        -- 连对
        if analyseResult.doubleCount * 2 == count then return DDZLogic.CT_DOUBLE_LINE end

        return DDZLogic.CT_ERROR
    end

    if (analyseResult.singleCount >= 5) and (analyseResult.singleCount == count) then
        local firstLogicValue = self:GetLogicValue(analyseResult.singleCardData[1])
        -- 错误过滤
        if firstLogicValue >= 15 then return DDZLogic.CT_ERROR end
        -- 连牌判断
        for i = 1, analyseResult.singleCount - 1 do
            local cardData = analyseResult.singleCardData[i + 1]
            if firstLogicValue ~= (self:GetLogicValue(cardData) + i) then return DDZLogic.CT_ERROR end
        end

        return DDZLogic.CT_SINGLE_LINE
    end

    return DDZLogic.CT_ERROR

end

function DDZLogic:CompareCard(firstCards, nextCards)
    local firstCount = #firstCards
    local nextCount  = #nextCards
    local firstType  = self:GetCardType(firstCards)
    local nextType   = self:GetCardType(nextCards)

    if nextType == DDZLogic.CT_ERROR then return false end
    -- 火箭
    if firstType == DDZLogic.CT_ROCKET then return false end
    if nextType == DDZLogic.CT_ROCKET then return true end

    -- 炸弹
    if firstType ~= DDZLogic.CT_BOMB and nextType == DDZLogic.CT_BOMB then return true end
    if firstType == DDZLogic.CT_BOMB and nextType ~= DDZLogic.CT_BOMB then return false end

    -- 规则判断
    if firstType ~= nextType or firstCount ~= nextCount then return false end

    -- 比牌
    if nextType == DDZLogic.CT_SINGLE or
        nextType == DDZLogic.CT_DOUBLE or
        nextType == DDZLogic.CT_THREE or
        nextType == DDZLogic.CT_SINGLE_LINE or
        nextType == DDZLogic.CT_DOUBLE_LINE or
        nextType == DDZLogic.CT_THREE_LINE or
        nextType == DDZLogic.CT_BOMB
        then
        local firstLogicValue = self:GetLogicValue(firstCards[1])
        local nextLogicValue  = self:GetLogicValue(nextCards[1])
        -- 对比扑克
        return nextLogicValue > firstLogicValue
    elseif nextType == DDZLogic.CT_THREE_TAKE_SINGLE or
        nextType == DDZLogic.CT_THREE_TAKE_DOUBLE or
        nextType == DDZLogic.CT_THREE_LINE_TAKE_SINGLE or
        nextType == DDZLogic.CT_THREE_LINE_TAKE_DOUBLE
        then
        -- 分析扑克
        local firstResult = {
            fourCount      = 0,
            threeCount     = 0,
            doubleCount    = 0,
            singleCount    = 0,
            fourCardData   = {},
            threeCardData  = {},
            doubleCardData = {},
            singleCardData = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards, firstResult)
        self:AnalyseCards(nextCards, nextResult)

        local firstLogicValue = self:GetLogicValue(firstResult.threeCardData[1])
        local nextLogicValue  = self:GetLogicValue(nextResult.threeCardData[1])

        return nextLogicValue > firstLogicValue
    elseif nextType == DDZLogic.CT_FOUR_TAKE_SINGLE or
        nextType == DDZLogic.CT_FOUR_TAKE_DOUBLE then
        -- 分析扑克
        local firstResult = {
            fourCount      = 0,
            threeCount     = 0,
            doubleCount    = 0,
            singleCount    = 0,
            fourCardData   = {},
            threeCardData  = {},
            doubleCardData = {},
            singleCardData = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards, firstResult)
        self:AnalyseCards(nextCards, nextResult)

        local firstLogicValue = self:GetLogicValue(firstResult.fourCardData[1])
        local nextLogicValue  = self:GetLogicValue(nextResult.fourCardData[1])

        return nextLogicValue > firstLogicValue
    end

    return false
end

function DDZLogic:AnalyseCards(data, analyseResult)
    local count = #data

    local i = 1
    while i <= count do
        local sameCount  = 1
        local logicValue = self:GetLogicValue(data[i])

        -- 搜索同牌
        for j = i + 1, count do
            -- 获取扑克
            if self:GetLogicValue(data[j]) ~= logicValue then break end

            sameCount = sameCount + 1
        end
        -- 设置结果
        if sameCount == 1 then
            local idx                                         = analyseResult.singleCount
            analyseResult.singleCount                         = analyseResult.singleCount + 1
            analyseResult.singleCardData[idx * sameCount + 1] = data[i]
        elseif sameCount == 2 then
            local idx                                         = analyseResult.doubleCount
            analyseResult.doubleCount                         = analyseResult.doubleCount + 1
            analyseResult.doubleCardData[idx * sameCount + 1] = data[i]
            analyseResult.doubleCardData[idx * sameCount + 2] = data[i + 1]
        elseif sameCount == 3 then
            local idx                                        = analyseResult.threeCount
            analyseResult.threeCount                         = analyseResult.threeCount + 1
            analyseResult.threeCardData[idx * sameCount + 1] = data[i]
            analyseResult.threeCardData[idx * sameCount + 2] = data[i + 1]
            analyseResult.threeCardData[idx * sameCount + 3] = data[i + 2]
        elseif sameCount == 4 then
            local idx                                       = analyseResult.fourCount
            analyseResult.fourCount                         = analyseResult.fourCount + 1
            analyseResult.fourCardData[idx * sameCount + 1] = data[i]
            analyseResult.fourCardData[idx * sameCount + 2] = data[i + 1]
            analyseResult.fourCardData[idx * sameCount + 3] = data[i + 2]
            analyseResult.fourCardData[idx * sameCount + 4] = data[i + 3]
        end

        i = i + sameCount
    end
end
---- chooseshunzi为true则代表是在手牌中划牌时选择顺子
function DDZLogic:SearchOutCard(handCardData, turnCardData, outCardResult, chooseshunzi)
    local cardData      = handCardData
    local cardCount     = #handCardData
    local turnCardCount = #turnCardData

    if cardCount <= 0 then
        print("SearchOutCard， handCardData为空")
        return false
    end

    self:sortDESC(cardData)

    local turnType = self:GetCardType(turnCardData)

    -- 分析扑克
    local turnAnalyseResult = {
        fourCount      = 0,
        threeCount     = 0,
        doubleCount    = 0,
        singleCount    = 0,
        fourCardData   = {},
        threeCardData  = {},
        doubleCardData = {},
        singleCardData = {}
    }
    self:AnalyseCards(turnCardData, turnAnalyseResult)

    if turnType == DDZLogic.CT_ERROR then
        -- print("上家牌型错误")
        -- 最小的牌
        local logicValue = self:GetLogicValue(cardData[cardCount])

        -- 多牌判断
        local sameCount = 1
        for i = 1, cardCount - 1 do
            if self:GetLogicValue(cardData[cardCount - i]) == logicValue then
                sameCount = sameCount + 1
            else
                break
            end
        end

        local resultCard = {}
        if sameCount > 1 then
            for i = 1, sameCount do
                resultCard[i] = cardData[cardCount - i + 1]
            end
        else
            -- 单牌处理
            resultCard[1] = cardData[cardCount]
        end
        outCardResult[#outCardResult + 1] = resultCard

    elseif (turnType == DDZLogic.CT_SINGLE) or
        (turnType == DDZLogic.CT_DOUBLE) or
        (turnType == DDZLogic.CT_THREE) then

        -- 获取数值
        local logicValue = self:GetLogicValue(turnCardData[1])

        -- 分析扑克
        local analyseResult = {
            fourCount      = 0,
            threeCount     = 0,
            doubleCount    = 0,
            singleCount    = 0,
            fourCardData   = {},
            threeCardData  = {},
            doubleCardData = {},
            singleCardData = {}
        }
        self:AnalyseCards(cardData, analyseResult)

        -- 寻找单牌
        if turnCardCount <= 1 then
            for i = 1, analyseResult.singleCount do
                local idx = (analyseResult.singleCount - i) * 1 + 1
                if self:GetLogicValue(analyseResult.singleCardData[idx]) > logicValue then
                    -- 设置结果
                    outCardResult[#outCardResult + 1] = {analyseResult.singleCardData[idx]}
                end
            end
        end

        -- 寻找对牌
        if turnCardCount <= 2 then
            for i = 1, analyseResult.doubleCount do
                local idx = (analyseResult.doubleCount - i) * 2 + 1
                if self:GetLogicValue(analyseResult.doubleCardData[idx]) > logicValue then
                    local resultCard = {}
                    for i = 1, turnCardCount do
                        resultCard[i] = analyseResult.doubleCardData[idx + i - 1]
                    end
                    outCardResult[#outCardResult + 1] = resultCard
                end
            end
        end

        -- 寻找三牌
        if turnCardCount <= 3 then
            for i = 1, analyseResult.threeCount do
                local idx = (analyseResult.threeCount - i) * 3 + 1
                if self:GetLogicValue(analyseResult.threeCardData[idx]) > logicValue then
                    local resultCard = {}
                    for i = 1, turnCardCount do
                        resultCard[i] = analyseResult.threeCardData[idx + i - 1]
                    end
                    outCardResult[#outCardResult + 1] = resultCard
                end
            end
        end

        -- 单顺类型
    elseif (turnType == DDZLogic.CT_SINGLE_LINE) and (cardCount >= turnCardCount) then
        local logicValue = self:GetLogicValue(turnCardData[1])

        -- 搜索连牌
        for i = turnCardCount, cardCount do
            local handLogicValue = self:GetLogicValue(cardData[cardCount - i + 1])

            -- 构造判断
            if handLogicValue >= 15 then break end
            if not chooseshunzi then
                if handLogicValue > logicValue then
                    -- 搜索hand连牌
                    local lineCount  = 0
                    local resultCard = {}
                    for j = cardCount - i + 1, cardCount do
                        if (self:GetLogicValue(cardData[j]) + lineCount) == handLogicValue then
                            resultCard[lineCount * 1 + 1] = cardData[j]
                            lineCount                     = lineCount + 1
                            if lineCount == turnCardCount then
                                outCardResult[#outCardResult + 1] = resultCard
                                break
                            end
                        end
                    end
                end
            else
                if handLogicValue >= logicValue then
                    -- 搜索hand连牌
                    local lineCount  = 0
                    local resultCard = {}
                    for j = cardCount - i + 1, cardCount do
                        if (self:GetLogicValue(cardData[j]) + lineCount) == handLogicValue then
                            resultCard[lineCount * 1 + 1] = cardData[j]
                            lineCount                     = lineCount + 1
                            if lineCount == turnCardCount then
                                outCardResult[#outCardResult + 1] = resultCard
                                break
                            end
                        end
                    end
                end
            end
        end

        -- 连对
    elseif (turnType == DDZLogic.CT_DOUBLE_LINE) and (cardCount >= turnCardCount) then
        local logicValue = self:GetLogicValue(turnCardData[1])

        -- 搜索连牌
        for i = turnCardCount, cardCount do
            local handLogicValue = self:GetLogicValue(cardData[cardCount - i + 1])

            -- 构造判断
            if handLogicValue >= 15 then break end
            if handLogicValue > logicValue then
                -- 搜索连牌
                local lineCount  = 0
                local resultCard = {}
                for j = cardCount - i + 1, cardCount - 1 do
                    if ((self:GetLogicValue(cardData[j]) + lineCount) == handLogicValue) and
                        ((self:GetLogicValue(cardData[j + 1]) + lineCount) == handLogicValue) then

                        -- 增加连数
                        resultCard[lineCount * 2 + 1] = cardData[j]
                        resultCard[lineCount * 2 + 2] = cardData[j + 1]
                        lineCount                     = lineCount + 1

                        -- 完成判断
                        if lineCount * 2 == turnCardCount then
                            outCardResult[#outCardResult + 1] = resultCard
                            break
                        end
                    end
                end
            end
        end
    elseif ((turnType == DDZLogic.CT_THREE_LINE) or -- 三顺 飞机
            (turnType == DDZLogic.CT_THREE_TAKE_SINGLE) or -- 三带1
            (turnType == DDZLogic.CT_THREE_TAKE_DOUBLE) or -- 三带对
            (turnType == DDZLogic.CT_THREE_LINE_TAKE_SINGLE) or -- 飞机翅膀
            (turnType == DDZLogic.CT_THREE_LINE_TAKE_DOUBLE)) and -- 飞机翅膀
        (cardCount >= turnCardCount) then

        -- 获取数值
        local logicValue = 0
        for i = 1, turnCardCount - 2 do
            logicValue = self:GetLogicValue(turnCardData[i])
            if (self:GetLogicValue(turnCardData[i + 1]) == logicValue) and
                (self:GetLogicValue(turnCardData[i + 2]) == logicValue) then

                break
            end
        end

        -- 属性数值
        local turnLineCount = turnAnalyseResult.threeCount

        -- 搜索连牌
        for i = turnLineCount * 3, cardCount do
            local handLogicValue = self:GetLogicValue(cardData[cardCount - i + 1])

            -- 构造判断
            if handLogicValue > logicValue then
                if turnLineCount > 1 and handLogicValue >= 15 then break end
                -- 搜索连牌
                local lineCount  = 0
                local resultCard = {}
                for j = cardCount - i + 1, cardCount - 2 do

                    if ((self:GetLogicValue(cardData[j]) + lineCount) == handLogicValue) and
                        ((self:GetLogicValue(cardData[j + 1]) + lineCount) == handLogicValue) and
                        ((self:GetLogicValue(cardData[j + 2]) + lineCount) == handLogicValue) then

                        -- 增加连数
                        resultCard[lineCount * 3 + 1] = cardData[j]
                        resultCard[lineCount * 3 + 2] = cardData[j + 1]
                        resultCard[lineCount * 3 + 3] = cardData[j + 2]
                        lineCount                     = lineCount + 1

                        -- 完成判断
                        if lineCount == turnLineCount then
                            -- 删除手牌中的三顺 剩余的牌
                            local leftCardData = clone(cardData)
                            local leftCount    = cardCount - #resultCard
                            for i, v in ipairs(resultCard) do
                                table.removebyvalue(leftCardData, v)
                            end

                            -- 分析扑克
                            local analyseResultLeft = {
                                fourCount      = 0,
                                threeCount     = 0,
                                doubleCount    = 0,
                                singleCount    = 0,
                                fourCardData   = {},
                                threeCardData  = {},
                                doubleCardData = {},
                                singleCardData = {}
                            }
                            self:AnalyseCards(leftCardData, analyseResultLeft)

                            -- 单牌处理
                            if (turnType == DDZLogic.CT_THREE_LINE_TAKE_SINGLE) or (turnType == DDZLogic.CT_THREE_TAKE_SINGLE) then

                                -- 提取单牌
                                for i = 1, analyseResultLeft.singleCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = analyseResultLeft.singleCount - i + 1
                                    local singleCard            = analyseResultLeft.singleCardData[idx]
                                    resultCard[#resultCard + 1] = singleCard
                                end

                                -- 提取单牌 from 对牌
                                for i = 1, analyseResultLeft.doubleCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = (analyseResultLeft.doubleCount - i) * 2 + 1
                                    local singleCard            = analyseResultLeft.doubleCardData[idx]
                                    resultCard[#resultCard + 1] = singleCard
                                end

                                -- 提取单牌 from 三牌
                                for i = 1, analyseResultLeft.threeCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = (analyseResultLeft.threeCount - i) * 3 + 1
                                    local singleCard            = analyseResultLeft.threeCardData[idx]
                                    resultCard[#resultCard + 1] = singleCard
                                end

                                -- 提取单牌 from 四牌
                                for i = 1, analyseResultLeft.fourCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = (analyseResultLeft.fourCount - i) * 4 + 1
                                    local singleCard            = analyseResultLeft.fourCardData[idx]
                                    resultCard[#resultCard + 1] = singleCard
                                end
                            end

                            -- 对牌处理
                            if (turnType == DDZLogic.CT_THREE_LINE_TAKE_DOUBLE) or (turnType == DDZLogic.CT_THREE_TAKE_DOUBLE) then

                                -- 提取对牌
                                for i = 1, analyseResultLeft.doubleCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx       = (analyseResultLeft.doubleCount - i) * 2 + 1
                                    local cardData1 = analyseResultLeft.doubleCardData[idx]
                                    local cardData2 = analyseResultLeft.doubleCardData[idx + 1]

                                    resultCard[#resultCard + 1] = cardData1
                                    resultCard[#resultCard + 1] = cardData2
                                end

                                -- 提取对牌 from三牌
                                for i = 1, analyseResultLeft.threeCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = (analyseResultLeft.threeCount - i) * 3 + 1
                                    local cardData1             = analyseResultLeft.threeCardData[idx]
                                    local cardData2             = analyseResultLeft.threeCardData[idx + 1]
                                    resultCard[#resultCard + 1] = cardData1
                                    resultCard[#resultCard + 1] = cardData2
                                end

                                -- 提取对牌 from四牌
                                for i = 1, analyseResultLeft.fourCount do
                                    -- 中止判断
                                    if #resultCard == turnCardCount then break end

                                    -- 设置扑克
                                    local idx                   = (analyseResultLeft.fourCount - i) * 4 + 1
                                    local cardData1             = analyseResultLeft.fourCardData[idx]
                                    local cardData2             = analyseResultLeft.fourCardData[idx + 1]
                                    resultCard[#resultCard + 1] = cardData1
                                    resultCard[#resultCard + 1] = cardData2
                                end

                            end

                            if #resultCard == turnCardCount then
                                -- 避免出现 333 444 带35的情况
                                if self:GetCardTypeOrig(resultCard, #resultCard) ~= DDZLogic.CT_ERROR then
                                    print("避免出现类似 333 444 带35的情况")
                                    outCardResult[#outCardResult + 1] = clone(resultCard)
                                end
                            end

                        end

                    end
                end
            end
        end
        -- 四带2
    elseif (turnType == DDZLogic.CT_FOUR_TAKE_DOUBLE) or (turnType == DDZLogic.CT_FOUR_TAKE_SINGLE) then
        -- 分析扑克
        local analyseResultHand = {
            fourCount      = 0,
            threeCount     = 0,
            doubleCount    = 0,
            singleCount    = 0,
            fourCardData   = {},
            threeCardData  = {},
            doubleCardData = {},
            singleCardData = {}
        }
        self:AnalyseCards(handCardData, analyseResultHand)

        local resultCard = {}
        for i = 1, analyseResultHand.fourCount do
            local idx            = (analyseResultHand.fourCount - i) * 4 + 1
            local cData          = analyseResultHand.fourCardData[idx]
            local handLogicValue = self:GetLogicValue(cData)
            local turnLogicValue = self:GetLogicValue(turnAnalyseResult.fourCardData[1])
            if handLogicValue > turnLogicValue then
                for i = 1, 4 do
                    resultCard[i] = analyseResultHand.fourCardData[idx + i - 1]
                end
                break
            end
        end

        if #resultCard == 4 then
            -- 删除手牌中的四牌 剩余的牌
            local leftCardData = clone(handCardData)
            local leftCount    = cardCount - #resultCard
            for i, v in ipairs(resultCard) do
                table.removebyvalue(leftCardData, v)
            end

            -- 分析扑克
            local analyseResultLeft = {
                fourCount      = 0,
                threeCount     = 0,
                doubleCount    = 0,
                singleCount    = 0,
                fourCardData   = {},
                threeCardData  = {},
                doubleCardData = {},
                singleCardData = {}
            }
            self:AnalyseCards(leftCardData, analyseResultLeft)

            -- 单牌处理
            if (turnType == DDZLogic.CT_FOUR_TAKE_SINGLE) then

                -- 提取单牌
                for i = 1, analyseResultLeft.singleCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = analyseResultLeft.singleCount - i + 1
                    local singleCard            = analyseResultLeft.singleCardData[idx]
                    resultCard[#resultCard + 1] = singleCard
                end

                -- 提取单牌 from 对牌
                for i = 1, analyseResultLeft.doubleCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.doubleCount - i) * 2 + 1
                    local singleCard            = analyseResultLeft.doubleCardData[idx]
                    resultCard[#resultCard + 1] = singleCard
                end

                -- 提取单牌 from 三牌
                for i = 1, analyseResultLeft.threeCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.threeCount - i) * 3 + 1
                    local singleCard            = analyseResultLeft.threeCardData[idx]
                    resultCard[#resultCard + 1] = singleCard
                end

                -- 提取单牌 from 四牌
                for i = 1, analyseResultLeft.fourCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.fourCount - i) * 4 + 1
                    local singleCard            = analyseResultLeft.fourCardData[idx]
                    resultCard[#resultCard + 1] = singleCard
                end

            end

            -- 对牌处理
            if (turnType == DDZLogic.CT_FOUR_TAKE_DOUBLE) then

                -- 提取对牌
                for i = 1, analyseResultLeft.doubleCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.doubleCount - i) * 2 + 1
                    local cardData1             = analyseResultLeft.doubleCardData[idx]
                    local cardData2             = analyseResultLeft.doubleCardData[idx + 1]
                    resultCard[#resultCard + 1] = cardData1
                    resultCard[#resultCard + 2] = cardData2
                end

                -- 提取对牌 from三牌
                for i = 1, analyseResultLeft.threeCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.threeCount - i) * 3 + 1
                    local cardData1             = analyseResultLeft.threeCardData[idx]
                    local cardData2             = analyseResultLeft.threeCardData[idx + 1]
                    resultCard[#resultCard + 1] = cardData1
                    resultCard[#resultCard + 2] = cardData2
                end

                -- 提取对牌 from四牌
                for i = 1, analyseResultLeft.fourCount do
                    -- 中止判断
                    if #resultCard == turnCardCount then break end

                    -- 设置扑克
                    local idx                   = (analyseResultLeft.fourCount - i) * 4 + 1
                    local cardData1             = analyseResultLeft.fourCardData[idx]
                    local cardData2             = analyseResultLeft.fourCardData[idx + 1]
                    resultCard[#resultCard + 1] = cardData1
                    resultCard[#resultCard + 2] = cardData2
                end
            end

            if #resultCard == turnCardCount then
                outCardResult[#outCardResult + 1] = resultCard
            end
        end
    end

    -- 搜索炸弹
    if (cardCount >= 4) and (turnType ~= DDZLogic.CT_ROCKET) then
        local logicValue = 0
        if turnType == DDZLogic.CT_BOMB then
            logicValue = self:GetLogicValue(turnCardData[1])
        end

        local analyseResultHand = {
            fourCount      = 0,
            threeCount     = 0,
            doubleCount    = 0,
            singleCount    = 0,
            fourCardData   = {},
            threeCardData  = {},
            doubleCardData = {},
            singleCardData = {}
        }
        self:AnalyseCards(handCardData, analyseResultHand)

        for i = 1, analyseResultHand.fourCount do
            local resultCard     = {}
            local idx            = (analyseResultHand.fourCount - i) * 4 + 1
            local cData          = analyseResultHand.fourCardData[idx]
            local handLogicValue = self:GetLogicValue(cData)
            if handLogicValue > logicValue then
                for i = 1, 4 do
                    resultCard[i] = analyseResultHand.fourCardData[idx + i - 1]
                end

                if #resultCard == 4 then
                    outCardResult[#outCardResult + 1] = resultCard
                end
            end
        end
    end

    -- 搜索火箭
    if (cardCount >= 2) and (cardData[1] == 79) and (cardData[2] == 78) then
        local resultCard                  = {}
        resultCard[1]                     = cardData[1]
        resultCard[2]                     = cardData[2]
        outCardResult[#outCardResult + 1] = resultCard
    end
end

function DDZLogic:GetColor(data)
    -- return cc_math:bit_and(data, 0xF0)
    return math.floor(data / 16)
end
function DDZLogic:GetValue(data)
    return data % 16
end

-- 搜索单顺
function DDZLogic:GetSingleLineCard(data, result)
    if data == nil then return false end
    local count = #data
    if count < 5 then
        print("GetSingleLineCard count<5 count:", count)
        return false
    end

    self:sortDESC(data)

    -- 搜索连牌
    for i = count, 5, -1 do
        for j = i, count do
            local logicValue = self:GetLogicValue(data[count - j + 1])
            -- 构造判断
            if logicValue >= 15 then break end
            -- 搜索连牌
            local lineCount = 0
            for k = count - j + 1, count do
                if (self:GetLogicValue(data[k]) + lineCount) == logicValue then
                    result[lineCount * 1 + 1] = data[k]
                    lineCount                 = lineCount + 1
                end
            end
            if lineCount >= 5 then
                return true
            end
        end
    end

    return false
end

-- 搜索双顺
function DDZLogic:GetDoubleLineCard(data, result)
    if data == nil then return false end
    local count = #data
    if count < 6 then
        print("GetDoubleLineCard count<6 count:", count)
        return false
    end

    self:sortDESC(data)

    -- 搜索连牌
    for i = count, 6, -1 do
        for j = i, count do
            local logicValue = self:GetLogicValue(data[count - j + 1])
            -- 构造判断
            if logicValue >= 15 then break end
            -- 搜索连牌
            local lineCount = 0
            for k = count - j + 1, count - 1 do
                if (self:GetLogicValue(data[k]) + lineCount) == logicValue and
                    (self:GetLogicValue(data[k + 1]) + lineCount) == logicValue then

                    result[lineCount * 2 + 1] = data[k]
                    result[lineCount * 2 + 2] = data[k + 1]

                    lineCount = lineCount + 1
                end
            end
            if lineCount * 2 >= 6 then
                return true
            end
        end
    end

    return false
end

-- 搜索三顺
function DDZLogic:GetThreeLineCard(data, result)
    if data == nil then return false end
    local count = #data
    if count < 6 then
        print("GetThreeLineCard count<6 count:", count)
        return false
    end

    self:sortDESC(data)

    -- 搜索连牌
    for i = count, 6, -1 do
        for j = i, count do
            local logicValue = self:GetLogicValue(data[count - j + 1])
            -- 构造判断
            if logicValue >= 15 then break end
            -- 搜索连牌
            local lineCount = 0
            for k = count - j + 1, count - 2 do
                if (self:GetLogicValue(data[k]) + lineCount) == logicValue and
                    (self:GetLogicValue(data[k + 1]) + lineCount) == logicValue and
                    (self:GetLogicValue(data[k + 2]) + lineCount) == logicValue then

                    result[lineCount * 3 + 1] = data[k]
                    result[lineCount * 3 + 2] = data[k + 1]
                    result[lineCount * 3 + 3] = data[k + 2]

                    lineCount = lineCount + 1
                end
            end
            if lineCount * 3 >= 6 then
                return true
            end
        end
    end

    return false
end

return DDZLogic