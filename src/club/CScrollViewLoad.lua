local CScrollViewLoad = {}

function CScrollViewLoad.resetList(listMaxNum, list, list_view, cell_name)
    list       = list or {}
    listMaxNum = listMaxNum or 0
    listMaxNum = (table.maxn(list) > listMaxNum and table.maxn(list) or listMaxNum)
    for i = 1, listMaxNum do
        local item = list_view:getChildByName(cell_name .. i)
        if item then
            item:setVisible(false)
            item.hasSet = false
        end
    end
    return listMaxNum
end

function CScrollViewLoad.newCellorGetCellByName(parent, baseItem, cellName, pos)
    local item = parent:getChildByName(cellName)
    if not item then
        item    = baseItem:clone()
        local x = pos.x
        local y = pos.y
        item:setPosition(cc.p(x, y))
        parent:addChild(item)
        item:setName(cellName)
    end

    item.hasSet = true
    item:setVisible(true)

    return item
end

function CScrollViewLoad.setCellItemPos(cellNums, cellItemPos, startX, startY, cellWidth, cellHeight)
    cellItemPos = cellItemPos or {}

    for i = cellNums, 1, -1 do
        if cellItemPos[i] then
            break
        end
        cellItemPos[i] = cc.p(startX, startY + (i - 1) * cellHeight)
    end
    return cellItemPos
end

function CScrollViewLoad.setListItem(list, itemPos, parent, cellName, callBack, baseItem, scoreView, baseItemHeight)
    local height = baseItemHeight or baseItem:getContentSize().height
    for i, v in ipairs(list) do
        local pos      = itemPos[i]
        local item     = parent:getChildByName(cellName .. i)
        local worldPos = parent:convertToWorldSpace(cc.p(pos.x, pos.y))

        local scoreViewPosY     = scoreView:getPositionY()
        local scoreViewWorldPos = scoreView:convertToWorldSpace(cc.p(0, 0))

        if (not item or not item.hasSet) and worldPos.y + height > scoreViewWorldPos.y then
            callBack(i, v)
        end
    end
end

function CScrollViewLoad.setLayerCont(PlayerList, LayerCont, newHight)
    local iSize = cc.size(LayerCont:getContentSize().width, newHight)
    -- LayerCont:setContentSize(iSize)
    PlayerList:setInnerContainerSize(iSize)

    LayerCont:setPositionY(-LayerCont:getContentSize().height + newHight)

    PlayerList:jumpToTop()
end

return CScrollViewLoad