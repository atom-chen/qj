local PDKLogic = {}

-- 1,    2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
-- 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,   -- 方块 A - K
-- 17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
-- 0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,   -- 梅花 A - K
-- 33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,
-- 0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,   -- 红桃 A - K
-- 49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,
-- 0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,   -- 黑桃 A - K
-- 0x4E,0x4F,                                                          -- 大小王



PDKLogic.CT_ERROR                   = 0      --  错误类型
PDKLogic.CT_SINGLE                  = 1      --  单牌
PDKLogic.CT_DOUBLE                  = 2      --  对子
PDKLogic.CT_THREE                   = 3      --  三个: 777 仅限最后一手
PDKLogic.CT_SINGLE_LINE             = 4      --  顺子
PDKLogic.CT_DOUBLE_LINE             = 5      --  连对
PDKLogic.CT_THREE_TAKE_ONE          = 6      --  三带一: 777+3 仅限最后一手
PDKLogic.CT_THREE_TAKE_TWO          = 7      --  三带二：777+34或777+33
PDKLogic.CT_THREE_LINE_TAKE_TWO     = 8      --  飞机带翅膀： 三顺+同数量一手牌。比如777888+34+56或444555+33+77
PDKLogic.CT_FOUR_TAKE_TWO           = 9      --  四带二：四条+2手牌。比如AAAA+79或9999+33
PDKLogic.CT_BOMB                    = 10     --  炸弹
PDKLogic.CT_FOUR_TAKE_THREE         = 11     --  四带三：四条+3手牌。比如AAAA+789或9999+333


function PDKLogic:sortDESC( t )
    table.sort(t, function (a, b)
        local logicValue1 = self:GetLogicValue(a)
        local logicValue2 = self:GetLogicValue(b)
        if logicValue1 == logicValue2 then
            return a > b
        else
            return logicValue1 > logicValue2
        end
    end)
end

-- 逻辑数值
function PDKLogic:GetLogicValue( data )
    local value = data%16
    if value<=2 then
        return value+13
    else
        return value
    end
end

-- 获取牌型
function PDKLogic:GetCardType( data, opts, is_last)
    local count   = #data
    local isSdyd  = opts.sdyd or 0
    local isSadzd = opts.sadzd or 0
    local isZddp  = opts.zddp or 2
    if is_last then
        isSdyd = 0
    end
    -- 排序 降序
    self:sortDESC(data)

    -- 简单牌型
    if count==0 then        --空牌
        return PDKLogic.CT_ERROR
    elseif count==1 then    --单牌
        return PDKLogic.CT_SINGLE
    elseif count==2 then    --对牌
        if self:GetLogicValue(data[1]) == self:GetLogicValue(data[2]) then
            return PDKLogic.CT_DOUBLE
        end
        return PDKLogic.CT_ERROR
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

    if analyseResult.fourCount>0 then
        -- 炸弹
        if (analyseResult.fourCount==1) and (count==4) then return PDKLogic.CT_BOMB end
        -- 四带2
        if (isZddp == 1) and (analyseResult.fourCount==1) and (count==6) then return PDKLogic.CT_FOUR_TAKE_TWO end
        -- 四带3
        if (isZddp == 2) and (analyseResult.fourCount==1) and (count==7) then return PDKLogic.CT_FOUR_TAKE_THREE end
        -- 三带二
        if (isSdyd == 0) and (analyseResult.fourCount==1) and (count==5) then return PDKLogic.CT_THREE_TAKE_TWO end
        local lineNum = 1
        if analyseResult.threeCount > 1 then
            local cardData = analyseResult.threeCardData[1]
            local firstLogicValue = self:GetLogicValue(cardData)
            -- 错误过滤
            if firstLogicValue>=15 then return PDKLogic.CT_ERROR end
            -- 连牌判断
            for i=1,analyseResult.threeCount-1 do
                local cardData = analyseResult.threeCardData[i*3+1]
                if firstLogicValue ~= self:GetLogicValue(cardData) + lineNum then
                    firstLogicValue = self:GetLogicValue(cardData)
                    if i == analyseResult.threeCount-1 and lineNum < 2 then
                        return PDKLogic.CT_ERROR
                    end
                else
                    lineNum = lineNum + 1
                end
            end
        end
        -- 飞机
        if isSdyd == 0 and (lineNum*5 == count) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        if isSdyd == 1 and (lineNum*5 == count) and (analyseResult.doubleCount == lineNum) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        if is_last and (lineNum*5 >= count) and (analyseResult.threeCount <= count) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        return PDKLogic.CT_ERROR
    end

    if analyseResult.threeCount>0 then

        if isSdyd == 0 and (analyseResult.threeCount==1) and (count==5) then
            return PDKLogic.CT_THREE_TAKE_TWO
        end

        if isSdyd == 1 and (analyseResult.threeCount==1) and (count==5) then
            if analyseResult.doubleCount == 1 then
                return PDKLogic.CT_THREE_TAKE_TWO
            else
                return PDKLogic.CT_ERROR
            end
        end

        if is_last and (analyseResult.threeCount==1) and (count == 4) then
            return PDKLogic.CT_THREE_TAKE_ONE
        end
        -- 三A当炸弹
        if isSadzd == 1 and (analyseResult.threeCount==1) and (count == 3) then
            if self:GetLogicValue(analyseResult.threeCardData[1]) == 14 then
                return PDKLogic.CT_BOMB
            end
        end

        if is_last and (analyseResult.threeCount==1) and (count == 3) then
            return PDKLogic.CT_THREE
        end

        local lineNum = 1
        -- 连牌判断
        if analyseResult.threeCount>1 then
            local cardData = analyseResult.threeCardData[1]
            local firstLogicValue = self:GetLogicValue(cardData)
            -- 错误过滤
            if firstLogicValue>=15 then return PDKLogic.CT_ERROR end
            -- 连牌判断
            for i=1,analyseResult.threeCount-1 do
                local cardData = analyseResult.threeCardData[i*3+1]
                if firstLogicValue ~= self:GetLogicValue(cardData) + lineNum then
                    firstLogicValue = self:GetLogicValue(cardData)
                    if i == analyseResult.threeCount-1 and lineNum < 2 then
                        return PDKLogic.CT_ERROR
                    end
                else
                    lineNum = lineNum + 1
                end
            end
        end

        -- 飞机
        if isSdyd == 0 and (lineNum*5 == count) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        if isSdyd == 1 and (lineNum*5 == count) and (analyseResult.doubleCount == lineNum) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        if is_last and (lineNum*5 >= count) and (analyseResult.threeCount <= count) then
            return PDKLogic.CT_THREE_LINE_TAKE_TWO
        end

        return PDKLogic.CT_ERROR
    end

    if analyseResult.doubleCount >= 2 then
        local firstLogicValue = self:GetLogicValue(analyseResult.doubleCardData[1])

        -- 错误过滤
        if firstLogicValue>=15 then return PDKLogic.CT_ERROR end
        -- 连牌判断
        for i=1,analyseResult.doubleCount-1 do
            local cardData = analyseResult.doubleCardData[i*2+1]
            if firstLogicValue ~= (self:GetLogicValue(cardData)+i) then return PDKLogic.CT_ERROR end
        end

        -- 连对
        if analyseResult.doubleCount*2 == count then return PDKLogic.CT_DOUBLE_LINE end

        return PDKLogic.CT_ERROR
    end

    if (analyseResult.singleCount>=5) and (analyseResult.singleCount==count) then
        local firstLogicValue=self:GetLogicValue(analyseResult.singleCardData[1])
        -- 错误过滤
        if firstLogicValue>=15 then return PDKLogic.CT_ERROR end
        -- 连牌判断
        for i=1,analyseResult.singleCount-1 do
            local cardData = analyseResult.singleCardData[i+1]
            if firstLogicValue ~= (self:GetLogicValue(cardData)+i) then return PDKLogic.CT_ERROR end
        end

        return PDKLogic.CT_SINGLE_LINE
    end

    return PDKLogic.CT_ERROR

end

function PDKLogic:CompareCard( firstCards, nextCards, opts, is_last)
    local firstCount = #firstCards
    local nextCount = #nextCards
    local firstType = self:GetCardType(firstCards, opts, is_last)
    local nextType = self:GetCardType(nextCards, opts, is_last)

    if nextType == PDKLogic.CT_ERROR then return false end

    -- 炸弹
    if firstType ~= PDKLogic.CT_BOMB and nextType == PDKLogic.CT_BOMB then
        return true
    end
    if firstType == PDKLogic.CT_BOMB and nextType ~= PDKLogic.CT_BOMB then
        return false
    end
    if firstType == PDKLogic.CT_BOMB and nextType == PDKLogic.CT_BOMB then
        local firstLogicValue = self:GetLogicValue(firstCards[1])
        local nextLogicValue = self:GetLogicValue(nextCards[1])
        -- 对比扑克
        return nextLogicValue>firstLogicValue
    end
    --最后一手牌三张可出完
    if is_last and firstType == PDKLogic.CT_THREE_TAKE_TWO and
        (nextType == PDKLogic.CT_THREE or
        nextType == PDKLogic.CT_THREE_TAKE_ONE or
        nextType == PDKLogic.CT_THREE_TAKE_TWO) then
        local firstResult = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards,firstResult)
        self:AnalyseCards(nextCards,nextResult)
        local firstLogicValue = self:GetLogicValue(firstResult.threeCardData[1])
        local nextLogicValue = self:GetLogicValue(nextResult.threeCardData[1])

        return nextLogicValue > firstLogicValue
    end
    -- 最后一手牌飞机可出完
    if is_last and firstType == PDKLogic.CT_THREE_LINE_TAKE_TWO and
        nextType == PDKLogic.CT_THREE_LINE_TAKE_TWO then
        local firstResult = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards,firstResult)
        self:AnalyseCards(nextCards,nextResult)
        local firstLogicValue = self:GetLogicValue(firstResult.threeCardData[1])
        local nextLogicValue = self:GetLogicValue(nextResult.threeCardData[1])

        return nextLogicValue > firstLogicValue
    end

    -- 规则判断
    if firstType ~= nextType then
        return false
    end

    if firstCount ~= nextCount then
        return false
    end

    -- 比牌
    if nextType==PDKLogic.CT_SINGLE or
       nextType==PDKLogic.CT_DOUBLE or
       nextType==PDKLogic.CT_SINGLE_LINE or
       nextType==PDKLogic.CT_DOUBLE_LINE or
       nextType==PDKLogic.CT_BOMB
    then
        local firstLogicValue = self:GetLogicValue(firstCards[1])
        local nextLogicValue = self:GetLogicValue(nextCards[1])
        -- 对比扑克
        return nextLogicValue>firstLogicValue
    elseif nextType==PDKLogic.CT_THREE_TAKE_TWO or
           nextType==PDKLogic.CT_THREE_LINE_TAKE_TWO
    then
        -- 分析扑克
        local firstResult = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards,firstResult)
        self:AnalyseCards(nextCards,nextResult)

        local firstLogicValue = self:GetLogicValue(firstResult.threeCardData[1])
        local nextLogicValue = self:GetLogicValue(nextResult.threeCardData[1])

        return nextLogicValue > firstLogicValue
    elseif nextType==PDKLogic.CT_FOUR_TAKE_TWO or nextType == PDKLogic.CT_FOUR_TAKE_THREE then
        -- 分析扑克
        local firstResult = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        local nextResult = clone(firstResult)
        self:AnalyseCards(firstCards,firstResult)
        self:AnalyseCards(nextCards,nextResult)

        local firstLogicValue = self:GetLogicValue(firstResult.fourCardData[1])
        local nextLogicValue = self:GetLogicValue(nextResult.fourCardData[1])

        return nextLogicValue > firstLogicValue
    end

    return false
end

function PDKLogic:AnalyseCards( data , analyseResult)
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
        if sameCount==1 then
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

            local idxs = analyseResult.threeCount
            analyseResult.threeCount = analyseResult.threeCount+1
            analyseResult.threeCardData[idxs*3+1] = data[i]
            analyseResult.threeCardData[idxs*3+2] = data[i+1]
            analyseResult.threeCardData[idxs*3+3] = data[i+2]
        end

        i = i + sameCount
    end
end

function PDKLogic:SearchOutCard( handCardData , turnCardData , outCardResult, chooseShunzi, opts)
    local cardData      = handCardData
    local cardCount     = #handCardData
    local turnCardCount = #turnCardData
    local isSadzd       = opts.sadzd or 0
    local isSdyd        = opts.sdyd or 0
    local isZddp        = opts.zddp or 2

    if cardCount <= 0 then
        print("SearchOutCard， handCardData为空")
        return false
    end

    self:sortDESC(cardData)

    local turnType = self:GetCardType(turnCardData, opts)

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

    if turnType == PDKLogic.CT_ERROR then
        -- print("上家牌型错误")
        -- 最小的牌
        local logicValue = self:GetLogicValue(cardData[cardCount])

        -- 多牌判断
        local sameCount=1
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

    elseif (turnType == PDKLogic.CT_SINGLE) or
           (turnType == PDKLogic.CT_DOUBLE) then

        -- 获取数值
        local logicValue = self:GetLogicValue(turnCardData[1])

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
        self:AnalyseCards(cardData,analyseResult)

        -- 寻找单牌
        if turnCardCount<=1 then
            for i=1,analyseResult.singleCount do
                local idx = (analyseResult.singleCount-i)*1+1
                if self:GetLogicValue(analyseResult.singleCardData[idx])>logicValue then
                    -- 设置结果
                    outCardResult[#outCardResult+1] = {analyseResult.singleCardData[idx]}
                end
            end
        end

        -- 寻找对牌
        if turnCardCount<=2 then
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

        -- 寻找三牌
        if turnCardCount<=3 then
            for i=1,analyseResult.threeCount do
                local idx = (analyseResult.threeCount-i)*3+1
                if self:GetLogicValue(analyseResult.threeCardData[idx])>logicValue then
                    local resultCard = {}
                    for i=1,turnCardCount do
                        resultCard[i] = analyseResult.threeCardData[idx+i-1]
                    end
                    outCardResult[#outCardResult+1] = resultCard
                end
            end
        end

    -- 单顺类型
    elseif (turnType == PDKLogic.CT_SINGLE_LINE) and (cardCount >= turnCardCount) then
        local logicValue = self:GetLogicValue(turnCardData[1])

        -- 搜索连牌
        for i=turnCardCount,cardCount do
            local handLogicValue = self:GetLogicValue(cardData[cardCount-i+1])

            -- 构造判断
            if handLogicValue>=15 then break end
            if chooseShunzi and handLogicValue>=logicValue or handLogicValue>logicValue then
                -- 搜索hand连牌
                local lineCount = 0
                local resultCard = {}
                for j=cardCount-i+1,cardCount do
                    if (self:GetLogicValue(cardData[j])+lineCount) == handLogicValue then
                        resultCard[lineCount*1+1] = cardData[j]
                        lineCount = lineCount + 1
                        if lineCount == turnCardCount then
                            outCardResult[#outCardResult+1] = resultCard
                            break
                        end
                    end
                end
            end
        end

    -- 连对
    elseif (turnType == PDKLogic.CT_DOUBLE_LINE) and (cardCount >= turnCardCount)  then
        local logicValue = self:GetLogicValue(turnCardData[1])

        -- 搜索连牌
        for i=turnCardCount,cardCount  do
            local handLogicValue = self:GetLogicValue(cardData[cardCount-i+1])

            -- 构造判断
            if handLogicValue>=15 then break end
            if handLogicValue>logicValue then
                -- 搜索连牌
                local lineCount = 0
                local resultCard = {}
                for j=cardCount-i+1,cardCount-1 do
                    if ((self:GetLogicValue(cardData[j])+lineCount) == handLogicValue) and
                       ((self:GetLogicValue(cardData[j+1])+lineCount) == handLogicValue) then

                        -- 增加连数
                        resultCard[lineCount*2+1] = cardData[j]
                        resultCard[lineCount*2+2] = cardData[j+1]
                        lineCount = lineCount + 1

                        -- 完成判断
                        if lineCount*2 == turnCardCount then
                            outCardResult[#outCardResult+1] = resultCard
                            break
                        end
                    end
                end
            end
        end
    elseif ((turnType == PDKLogic.CT_THREE_TAKE_TWO) or           -- 三带二
           (turnType == PDKLogic.CT_THREE_LINE_TAKE_TWO)) and    -- 飞机翅膀
           (cardCount >= turnCardCount)  then

        -- 获取数值
        local logicValue = 0
        for i=1,turnCardCount-2 do
            logicValue = self:GetLogicValue(turnCardData[i])
            if (self:GetLogicValue(turnCardData[i+1]) == logicValue) and
               (self:GetLogicValue(turnCardData[i+2]) == logicValue) then

                break
            end
        end

        -- 属性数值
        local turnLineCount  = 0
        local turnLogicValue = 0
        self:sortDESC(turnAnalyseResult.threeCardData)
        for __, v in ipairs(turnAnalyseResult.threeCardData) do
            if turnLogicValue ~= self:GetLogicValue(v) then
                turnLogicValue = self:GetLogicValue(v)
                local lineCount = 0
                for i = 1, #turnAnalyseResult.threeCardData - 2 do
                    if (self:GetLogicValue(turnAnalyseResult.threeCardData[i]) + lineCount == turnLogicValue) and
                       (self:GetLogicValue(turnAnalyseResult.threeCardData[i + 1]) + lineCount == turnLogicValue) and
                       (self:GetLogicValue(turnAnalyseResult.threeCardData[i + 2]) + lineCount == turnLogicValue) then
                        lineCount = lineCount + 1
                    end
                end
                if lineCount > turnLineCount then
                    turnLineCount = lineCount
                end
            end
        end
        -- 搜索连牌
        for i=turnLineCount*3,cardCount do
            local handLogicValue = self:GetLogicValue(cardData[cardCount-i+1])

            -- 构造判断
            if handLogicValue>logicValue then
                if turnLineCount>1 and handLogicValue>=15 then break end
                -- 搜索连牌
                local lineCount = 0
                local resultCard = {}
                for j=cardCount-i+1,cardCount-2 do

                    if ((self:GetLogicValue(cardData[j])+lineCount) == handLogicValue) and
                       ((self:GetLogicValue(cardData[j+1])+lineCount) == handLogicValue) and
                       ((self:GetLogicValue(cardData[j+2])+lineCount) == handLogicValue) then

                        -- 增加连数
                        resultCard[lineCount*3+1] = cardData[j]
                        resultCard[lineCount*3+2] = cardData[j+1]
                        resultCard[lineCount*3+3] = cardData[j+2]
                        lineCount = lineCount + 1

                        -- 完成判断
                        if lineCount == turnLineCount then
                            -- 删除手牌中的三顺 剩余的牌
                            local leftCardData = clone(cardData)
                            local leftCount = cardCount - #resultCard
                            for i,v in ipairs(resultCard) do
                                table.removebyvalue(leftCardData,v)
                            end

                            -- 分析扑克
                            local analyseResultLeft = {
                                fourCount       = 0,
                                threeCount      = 0,
                                doubleCount     = 0,
                                singleCount     = 0,
                                fourCardData    = {},
                                threeCardData   = {},
                                doubleCardData  = {},
                                singleCardData  = {}
                            }
                            self:AnalyseCards(leftCardData,analyseResultLeft)

                            if (turnType==PDKLogic.CT_THREE_LINE_TAKE_TWO) or (turnType==PDKLogic.CT_THREE_TAKE_TWO) then

                                -- 提取 from 单牌
                                for i=1,analyseResultLeft.singleCount do
                                    -- 中止判断
                                    if #resultCard ==turnCardCount or isSdyd == 1 then break end
                                    -- 设置扑克
                                    local idx = analyseResultLeft.singleCount-i+1
                                    local singleCard = analyseResultLeft.singleCardData[idx]
                                    resultCard[#resultCard+1] = singleCard
                                end

                                -- 提取 from 对牌
                                for i=1,analyseResultLeft.doubleCount do
                                    -- 中止判断
                                    if #resultCard ==turnCardCount then break end

                                    -- 设置扑克
                                    local idx = (analyseResultLeft.doubleCount-i)*2+1
                                    local singleCard = analyseResultLeft.doubleCardData[idx]
                                    resultCard[#resultCard+1] = singleCard

                                      -- 中止判断
                                    if #resultCard ==turnCardCount then break end

                                    local singleCard2 = analyseResultLeft.doubleCardData[idx+1]
                                    resultCard[#resultCard+1] = singleCard2

                                end

                                 -- 提取 from 三牌
                                for i=1,analyseResultLeft.threeCount do
                                    -- 中止判断
                                   if #resultCard ==turnCardCount then break end

                                    -- 设置扑克
                                    local idx = (analyseResultLeft.threeCount-i)*3+1
                                    local singleCard = analyseResultLeft.threeCardData[idx]
                                    resultCard[#resultCard+1] = singleCard

                                        -- 中止判断
                                    if #resultCard ==turnCardCount then break end

                                    local singleCard2 = analyseResultLeft.threeCardData[idx+1]
                                    resultCard[#resultCard+1] = singleCard2
                                end

                            end

                            if #resultCard == turnCardCount then
                                local result = clone(resultCard)
                                outCardResult[#outCardResult+1] = result
                            end

                        end

                    end
                end
            end
        end
    -- 四带2
    elseif (turnType == PDKLogic.CT_FOUR_TAKE_TWO) or
        (turnType == PDKLogic.CT_FOUR_TAKE_THREE) then
        -- 分析扑克
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

        local resultCard = {}
        for i=1,analyseResultHand.fourCount do
            local idx = (analyseResultHand.fourCount-i)*4 + 1
            local cData = analyseResultHand.fourCardData[idx]
            local handLogicValue = self:GetLogicValue(cData)
            local turnLogicValue = self:GetLogicValue(turnAnalyseResult.fourCardData[1])
            if handLogicValue > turnLogicValue then
                for i=1,4 do
                    resultCard[i] = analyseResultHand.fourCardData[idx+i-1]
                end
                break
            end
        end

        if #resultCard == 4 then
            -- 删除手牌中的四牌 剩余的牌
            local leftCardData = clone(handCardData)
            local leftCount = cardCount - #resultCard
            for i,v in ipairs(resultCard) do
                 table.removebyvalue(leftCardData,v)
            end

            -- 分析扑克
            local analyseResultLeft = {
                fourCount       = 0,
                threeCount      = 0,
                doubleCount     = 0,
                singleCount     = 0,
                fourCardData    = {},
                threeCardData   = {},
                doubleCardData  = {},
                singleCardData  = {}
            }
            self:AnalyseCards(leftCardData,analyseResultLeft)

            if  (turnType==PDKLogic.CT_FOUR_TAKE_TWO)  or
                (turnType == PDKLogic.CT_FOUR_TAKE_THREE) then
                -- 提取 from 单牌
                for i=1,analyseResultLeft.singleCount do
                    -- 中止判断
                    if #resultCard ==turnCardCount then break end

                    -- 设置扑克
                    local idx = analyseResultLeft.singleCount-i+1
                    local singleCard = analyseResultLeft.singleCardData[idx]
                    resultCard[#resultCard+1] = singleCard
                end

                -- 提取 from 对牌
                for i=1,analyseResultLeft.doubleCount do
                    -- 中止判断
                    if #resultCard ==turnCardCount then break end

                    -- 设置扑克
                    local idx = (analyseResultLeft.doubleCount-i)*2+1
                    local singleCard = analyseResultLeft.doubleCardData[idx]
                    resultCard[#resultCard+1] = singleCard

                     -- 中止判断
                    if #resultCard ==turnCardCount then break end

                    local singleCard2 = analyseResultLeft.doubleCardData[idx+1]
                    resultCard[#resultCard+1] = singleCard2
                end

                 -- 提取单牌 from 三牌
                for i=1,analyseResultLeft.threeCount do
                    -- 中止判断
                    if #resultCard==turnCardCount then break end

                    -- 设置扑克
                    local idx = (analyseResultLeft.threeCount-i)*3+1
                    local singleCard = analyseResultLeft.threeCardData[idx]
                    resultCard[#resultCard+1] = singleCard

                    -- 中止判断
                    if #resultCard ==turnCardCount then break end

                    local singleCard2 = analyseResultLeft.threeCardData[idx+1]
                    resultCard[#resultCard+1] = singleCard2
                end

            end

            if #resultCard == turnCardCount then
                outCardResult[#outCardResult+1] = resultCard
            end
        end
    end

    -- 搜索炸弹
    local bombCount = 4
    if isSadzd == 1 then
        bombCount = 3
    end
    if (cardCount>=bombCount) then
        local logicValue = 0
        if turnType==PDKLogic.CT_BOMB then
            logicValue = self:GetLogicValue(turnCardData[1])
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

        local resultCard = {}
        for i=1,analyseResultHand.fourCount do
            local idx = (analyseResultHand.fourCount-i)*4 + 1
            local cData = analyseResultHand.fourCardData[idx]
            local handLogicValue = self:GetLogicValue(cData)
            if handLogicValue > logicValue then
                for i=1,4 do
                    resultCard[i] = analyseResultHand.fourCardData[idx+i-1]
                end
            end
        end

        if #resultCard == 4 then
            outCardResult[#outCardResult+1] = resultCard
        end
        resultCard = {}
        if isSadzd == 1 then
            for i=1,analyseResultHand.threeCount do
                local idx = (analyseResultHand.threeCount-i)*3 + 1
                local cData = analyseResultHand.threeCardData[idx]
                local handLogicValue = self:GetLogicValue(cData)
                if handLogicValue == 14 then
                    for i=1,3 do
                        resultCard[i] = analyseResultHand.threeCardData[idx+i-1]
                    end
                end
            end
            if #resultCard == 3 then
                outCardResult[#outCardResult+1] = resultCard
            end
        end
    end
end

function PDKLogic:SearchCanOutCards(selList, opts)
    local isSadzd       = opts.sadzd or 0
    local isSdyd        = opts.sdyd or 0
    local isZddp        = opts.zddp or 2 --0 不可带 1 四带二 2 四带三

    self:sortDESC(selList)

    local cardCount  = #selList

    -- 寻找单顺
    local lineResult = {}
    for k, v in ipairs(selList) do
        local logicValue = self:GetLogicValue(v)
        if logicValue >= 15 then break end
        local lineCount  = 0
        local resultCard = {}
        for i=1, cardCount do
            if self:GetLogicValue(selList[i]) + lineCount == logicValue then
                resultCard[#resultCard + 1] = selList[i]
                lineCount = lineCount + 1
            end
        end
        if #resultCard >= 5 and #resultCard > #lineResult then
            lineResult = resultCard
        end
    end
    -- print("lineResult")
    -- for i,v in ipairs(lineResult) do
    --     print(i,v)
    -- end

    -- 寻找连对
    local doubleLineResult = {}
    for k, v in ipairs(selList) do
        local logicValue = self:GetLogicValue(v)
        if logicValue >= 15 then break end
        -- 搜索连牌
        local lineCount = 0
        local resultCard = {}
        for i = 1, cardCount - 1 do
            if ((self:GetLogicValue(selList[i]) + lineCount) == logicValue) and
               ((self:GetLogicValue(selList[i+1]) + lineCount) == logicValue) then

                -- 增加连数
                resultCard[lineCount*2+1] = selList[i]
                resultCard[lineCount*2+2] = selList[i+1]
                lineCount = lineCount + 1
            end
        end
        if #resultCard >= 4 and #resultCard > #doubleLineResult then
            doubleLineResult = resultCard
        end
    end
    -- print("doubleLineResult")
    -- for i,v in ipairs(doubleLineResult) do
    --     print(i,v)
    -- end

    -- 寻找三带
    local threeCountResult = {}
    for k, v in ipairs(selList) do
        local logicValue = self:GetLogicValue(v)

        -- 构造判断
        if logicValue >= 15 then break end
        -- 搜索连牌
        local lineCount  = 0
        local resultCard = {}
        for i = 1, cardCount - 2 do
            if ((self:GetLogicValue(selList[i]) + lineCount) == logicValue) and
               ((self:GetLogicValue(selList[i+1]) + lineCount) == logicValue) and
               ((self:GetLogicValue(selList[i+2]) + lineCount) == logicValue) then

                -- 增加连数
                resultCard[lineCount*3+1] = selList[i]
                resultCard[lineCount*3+2] = selList[i+1]
                resultCard[lineCount*3+3] = selList[i+2]
                lineCount = lineCount + 1

                -- 删除手牌中的三顺 剩余的牌
                local leftCardData = clone(selList)
                local leftCount = cardCount - #resultCard
                for i,v in ipairs(resultCard) do
                    table.removebyvalue(leftCardData,v)
                end

                -- 分析扑克
                local analyseResultLeft = {
                    fourCount       = 0,
                    threeCount      = 0,
                    doubleCount     = 0,
                    singleCount     = 0,
                    fourCardData    = {},
                    threeCardData   = {},
                    doubleCardData  = {},
                    singleCardData  = {}
                }
                self:AnalyseCards(leftCardData,analyseResultLeft)

                -- 提取 from 单牌
                for i=1,analyseResultLeft.singleCount do
                    -- 中止判断
                    if #resultCard == lineCount * 5 or isSdyd == 1 then break end
                    -- 设置扑克
                    local idx = analyseResultLeft.singleCount-i+1
                    local singleCard = analyseResultLeft.singleCardData[idx]
                    resultCard[#resultCard+1] = singleCard
                end

                -- 提取 from 对牌
                for i=1,analyseResultLeft.doubleCount do
                    -- 中止判断
                    if #resultCard == lineCount * 5 then break end

                    -- 设置扑克
                    local idx = (analyseResultLeft.doubleCount-i)*2+1
                    local singleCard = analyseResultLeft.doubleCardData[idx]
                    resultCard[#resultCard+1] = singleCard

                      -- 中止判断
                    if #resultCard == lineCount * 5 then break end

                    local singleCard2 = analyseResultLeft.doubleCardData[idx+1]
                    resultCard[#resultCard+1] = singleCard2
                end

                 -- 提取 from 三牌
                for i=1,analyseResultLeft.threeCount do
                    -- 中止判断
                   if #resultCard == lineCount * 5 then break end

                    -- 设置扑克
                    local idx = (analyseResultLeft.threeCount-i)*3+1
                    local singleCard = analyseResultLeft.threeCardData[idx]
                    resultCard[#resultCard+1] = singleCard

                    -- 中止判断
                    if #resultCard == lineCount * 5 then break end

                    local singleCard2 = analyseResultLeft.threeCardData[idx+1]
                    resultCard[#resultCard+1] = singleCard2
                end
            end
        end
        if #resultCard >= 5 and #resultCard > #threeCountResult then
            local threeresult = clone(resultCard)
            threeCountResult = threeresult
        end
    end
    -- print("threeCountResult")
    -- for i, v in ipairs(threeCountResult) do
    --     print(i, v)
    -- end

    -- 寻找炸弹
    local bombResult = {}
    local bombCount = 4
    if isSadzd == 1 then
        bombCount = 3
    end
    if (cardCount >= bombCount) then
        local analyseResultSel = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        self:AnalyseCards(selList, analyseResultSel)

        local resultCard = {}
        for i=1,analyseResultSel.fourCount do
            local idx = (analyseResultSel.fourCount-i)*4 + 1
            local cData = analyseResultSel.fourCardData[idx]
            for i=1,4 do
                resultCard[i] = analyseResultSel.fourCardData[idx+i-1]
            end
        end

        if #resultCard == 4 and #resultCard > #bombResult then
            bombResult = clone(resultCard)
        end

        if isSadzd == 1 then
            for i=1,analyseResultSel.threeCount do
                local idx = (analyseResultSel.threeCount-i)*3 + 1
                local cData = analyseResultSel.threeCardData[idx]
                local handLogicValue = self:GetLogicValue(cData)
                if handLogicValue == 14 then
                    for i=1,3 do
                        resultCard[i] = analyseResultSel.threeCardData[idx+i-1]
                    end
                end
            end
            if #resultCard == 3 and #resultCard > #bombResult then
                bombResult = clone(resultCard)
            end
        end

    end
    -- print("bombResult")
    -- for i,v in ipairs(bombResult) do
    --     print(i,v)
    -- end
    -- 寻找四带
    local fourCountResult = {}
    if isZddp ~= 0 then
        local needCardCount   = 7
        if isZddp == 1 then
            needCardCount   = 6
        end
        -- 分析扑克
        local analyseResultSel = {
            fourCount       = 0,
            threeCount      = 0,
            doubleCount     = 0,
            singleCount     = 0,
            fourCardData    = {},
            threeCardData   = {},
            doubleCardData  = {},
            singleCardData  = {}
        }
        self:AnalyseCards(selList,analyseResultSel)

        local resultCard = {}
        for i=1,analyseResultSel.fourCount do
            local idx = (analyseResultSel.fourCount-i)*4 + 1
            local cData = analyseResultSel.fourCardData[idx]
            for i=1,4 do
                resultCard[i] = analyseResultSel.fourCardData[idx+i-1]
            end
        end

        if #resultCard == 4 then
            -- 删除手牌中的四牌 剩余的牌
            local leftCardData = clone(selList)
            local leftCount = cardCount - #resultCard
            for i,v in ipairs(resultCard) do
                 table.removebyvalue(leftCardData,v)
            end

            -- 分析扑克
            local analyseResultLeft = {
                fourCount       = 0,
                threeCount      = 0,
                doubleCount     = 0,
                singleCount     = 0,
                fourCardData    = {},
                threeCardData   = {},
                doubleCardData  = {},
                singleCardData  = {}
            }
            self:AnalyseCards(leftCardData,analyseResultLeft)

            -- 提取 from 单牌
            for i=1,analyseResultLeft.singleCount do
                -- 中止判断
                if #resultCard == needCardCount then break end

                -- 设置扑克
                local idx = analyseResultLeft.singleCount-i+1
                local singleCard = analyseResultLeft.singleCardData[idx]
                resultCard[#resultCard+1] = singleCard
            end

            -- 提取 from 对牌
            for i=1,analyseResultLeft.doubleCount do
                -- 中止判断
                if #resultCard == needCardCount then break end

                -- 设置扑克
                local idx = (analyseResultLeft.doubleCount-i)*2+1
                local singleCard = analyseResultLeft.doubleCardData[idx]
                resultCard[#resultCard+1] = singleCard

                 -- 中止判断
                if #resultCard == needCardCount then break end

                local singleCard2 = analyseResultLeft.doubleCardData[idx+1]
                resultCard[#resultCard+1] = singleCard2
            end

             -- 提取单牌 from 三牌
            for i=1,analyseResultLeft.threeCount do
                -- 中止判断
                if #resultCard == needCardCount then break end

                -- 设置扑克
                local idx = (analyseResultLeft.threeCount-i)*3+1
                local singleCard = analyseResultLeft.threeCardData[idx]
                resultCard[#resultCard+1] = singleCard

                -- 中止判断
                if #resultCard == needCardCount then break end

                local singleCard2 = analyseResultLeft.threeCardData[idx+1]
                resultCard[#resultCard+1] = singleCard2
            end
            if #resultCard == needCardCount and #resultCard > #fourCountResult then
                fourCountResult = clone(resultCard)
            end
        end
    end
    -- print("fourCountResult")
    -- for i, v in ipairs(fourCountResult) do
    --     print(i, v)
    -- end
    local resultList     = {}
    resultList["line"]   = lineResult
    resultList["double"] = doubleLineResult
    resultList["three"]  = threeCountResult
    resultList["bomb"]   = bombResult
    resultList["four"]   = fourCountResult
    local cardCount = 0
    local result    = {}
    for k, v in pairs(resultList) do
        if #v > cardCount then
            cardCount = #v
            result    = v
        end
    end
    return result
end

return PDKLogic
