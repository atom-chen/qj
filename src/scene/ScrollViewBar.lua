ScrollView = class('ScrollView_QJ')
ScrollViewBar = class('ScrollViewBar')

local _marginForLength = 30
local _marginFromBoundary = 0

local _outOfBoundaryAmountDirty = true
local _outOfBoundaryAmount = nil

local ANCHOR_MIDDLE_BOTTOM = cc.p(0.5, 0.0)

local DEFAULT_COLOR = cc.c3b(0x77,0x45,0x45)
local BLACK_COLOR = cc.c3b(0x0,0x0,0x0)

function ScrollViewBar.init()
    local bar = cc.Sprite:create("ui/scrollviewbar/__halfCircleImage.png")
    bar:setOpacity(0)
    local _upperHalfCircle = cc.Sprite:create("ui/scrollviewbar/__halfCircleImage.png")
    _upperHalfCircle:setAnchorPoint(ANCHOR_MIDDLE_BOTTOM)
    bar:addChild(_upperHalfCircle)
    bar._upperHalfCircle = _upperHalfCircle
    local _lowerHalfCircle = cc.Sprite:create("ui/scrollviewbar/__halfCircleImage.png")
    _lowerHalfCircle:setScaleY(-1)
    _lowerHalfCircle:setAnchorPoint(ANCHOR_MIDDLE_BOTTOM)
    bar:addChild(_lowerHalfCircle)
    bar._lowerHalfCircle = _lowerHalfCircle
    local _body = cc.Sprite:create("ui/scrollviewbar/__bodyImage.png")
    _body:setAnchorPoint(ANCHOR_MIDDLE_BOTTOM)
    bar:addChild(_body)
    bar._body = _body
    bar:setAnchorPoint(0,0)

    _marginFromBoundary = _upperHalfCircle:getContentSize().width
    return bar
end

function ScrollViewBar.create(_parent,bListView)
    if gt.isCocos2dx317() then
        local function SpaceFunk()

        end
        return SpaceFunk,SpaceFunk
    end
    local bar = _parent:getParent():getChildByName('ScrollViewBar')
    if not bar then
        bar = ScrollViewBar.init()
        bar:setName('ScrollViewBar')
        _parent:getParent():addChild(bar)
    end
    bar:setColor(DEFAULT_COLOR)
    bar:setVisible(false)

    local function calculateLength(innerContainerMeasure, scrollViewMeasure, outOfBoundaryValue)
        local denominatorValue = innerContainerMeasure
        if outOfBoundaryValue ~= 0 then
            local GETTING_SHORTER_FACTOR = 20
            if outOfBoundaryValue > 0 then
                denominatorValue = denominatorValue + outOfBoundaryValue*GETTING_SHORTER_FACTOR
            else
                denominatorValue = denominatorValue - outOfBoundaryValue*GETTING_SHORTER_FACTOR
            end
        end
        local lengthRatio = scrollViewMeasure / denominatorValue;
        return math.abs(scrollViewMeasure - 2 * _marginForLength) * lengthRatio
    end
    local function calculatePosition(innerContainerMeasure, scrollViewMeasure, innerContainerPosition, outOfBoundaryValue, length)
        local denominatorValue = innerContainerMeasure - scrollViewMeasure
        if outOfBoundaryValue ~= 0 then
            denominatorValue = denominatorValue + math.abs(outOfBoundaryValue)
        end
        local positionRatio = 0
        if denominatorValue ~= 0 then
            positionRatio = innerContainerPosition / denominatorValue
            positionRatio = math.max(positionRatio, 0)
            positionRatio = math.min(positionRatio, 1)
        end
        local position = (scrollViewMeasure - length - 2 * _marginForLength) * positionRatio + _marginForLength
        return cc.p(_parent:getContentSize().width - _marginFromBoundary, position)
    end
    local function updateLength(length)
        local ratio = length / bar._body:getContentSize().height
        bar._body:setScaleY(ratio)
        bar._upperHalfCircle:setPositionY(bar._body:getPositionY() + length)
    end
    local function setPosition(position)
        local worldPos = _parent:convertToWorldSpace(cc.p(position))
        local Pos = nil
        Pos = _parent:getParent():convertToNodeSpace(worldPos)
        bar:setPosition(Pos)
    end
    local function onScrolled(outOfBoundary)
        local innerContainer = _parent:getInnerContainer()
        local innerContainerMeasure = 0
        local scrollViewMeasure = 0
        local outOfBoundaryValue = 0
        local innerContainerPosition = 0
        innerContainerMeasure = innerContainer:getContentSize().height
        scrollViewMeasure = _parent:getContentSize().height
        outOfBoundaryValue = outOfBoundary and outOfBoundary.y or 0
        innerContainerPosition = -innerContainer:getPositionY()
        local length = calculateLength(innerContainerMeasure, scrollViewMeasure, outOfBoundaryValue)
        local position = calculatePosition(innerContainerMeasure, scrollViewMeasure, innerContainerPosition, outOfBoundaryValue, length)
        updateLength(length)
        setPosition(position)
    end
    onScrolled()

    local bTouch = false

    local prePosition = nil
    local function ScrollViewCallBack(sender, eventType)
        local PosX,PosY = _parent:getInnerContainer():getPosition()
        local moveDelta = prePosition and cc.p(PosX - prePosition.x,PosY - prePosition.y) or cc.p(0,0)
        local outOfBoundary = ScrollView.getHowMuchOutOfBoundary(moveDelta,_parent)
        onScrolled(outOfBoundary)
        if prePosition and bTouch then
            barVisible = true
            bar:setVisible(true)
        end
        prePosition = cc.p(PosX,PosY)
    end
    local function touchCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.began or eventType == ccui.TouchEventType.moved then
            bar:stopAllActions()
            bar:setVisible(true)

            bTouch = true
        elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then

            bTouch = false

            bar:stopAllActions()
            bar:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(2) ,
                    cc.CallFunc:create(
                        function ()
                            bar:setVisible(false)
                        end
                    )
                )
            )
        end
    end
    return ScrollViewCallBack,touchCallBack
end

function ScrollView.getHowMuchOutOfBoundary(addition,_parent)
    if addition.x == 0 and addition.y == 0 and not _outOfBoundaryAmountDirty then
        return _outOfBoundaryAmount
    end
    local _leftBoundary = _parent:getLeftBoundary()
    local _rightBoundary = _parent:getRightBoundary()
    local _bottomBoundary = _parent:getBottomBoundary()
    local _topBoundary = _parent:getTopBoundary()

    local _innerContainer = _parent:getInnerContainer()
    local outOfBoundaryAmount = cc.p(0,0)
    if _innerContainer:getPositionY() > 0 then
        outOfBoundaryAmount.y = _innerContainer:getPositionY()
    elseif _innerContainer:getPositionY() < _parent:getContentSize().height - _innerContainer:getContentSize().height then
        outOfBoundaryAmount.y = -(_parent:getContentSize().height - (_innerContainer:getContentSize().height + _innerContainer:getPositionY()))
    end
    if addition.x == 0 and addition.y == 0 then
        _outOfBoundaryAmount = outOfBoundaryAmount
        _outOfBoundaryAmountDirty = false
    end
    return outOfBoundaryAmount
end