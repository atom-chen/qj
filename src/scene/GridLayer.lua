--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Email: liyongjin2009@gmail.com
-- @Date: 2017-04-28
-- @Last Modified by: liyongjin
-- @Last Modified time:2017-05-01
-- @Desc: 以屏幕为中心画满网格线，方便调整界面元素位置
--------------------------------------------------------------------------------
local LINE_WIDTH = 1
local GRID_SIZE  = 40

local GridLayer = class("GridLayer", function()
    return display.newLayer()
end)

function GridLayer:ctor()
    self.drawNode = cc.DrawNode:create()
    self:addChild(self.drawNode)

    self:setGridSize(GRID_SIZE)
end

function GridLayer:setGridSize(gridSize)
    self.gridSize = gridSize
    self.drawNode:clear()
    self:drawGrids()
end

function GridLayer:drawGrids()
    local color
    local gridSize = self.gridSize

    -- 圆定位圆盘
    color = cc.convertColor(cc.c4b(255, 0, 0, 100), "4f")
    self.drawNode:drawDot(VCenter, gridSize, color)
    color = cc.convertColor(cc.c4b(255, 0, 0, 100), "4f")
    self.drawNode:drawDot(VCenterGap(8 * gridSize, 6 * gridSize), gridSize / 2, color)
    self.drawNode:drawDot(VCenterGap(-8 * gridSize, 6 * gridSize), gridSize / 2, color)
    self.drawNode:drawDot(VCenterGap(-8 * gridSize, -6 * gridSize), gridSize / 2, color)
    self.drawNode:drawDot(VCenterGap(8 * gridSize, -6 * gridSize), gridSize / 2, color)

    -- 画线
    color = cc.convertColor(cc.c4b(255, 0, 0, 100), "4f")
    self:drawGridCenter(VCenter.x, VCenter.y, gridSize * 2, color)
    color = cc.convertColor(cc.c4b(0, 0, 255, 80), "4f")
    self:drawGridCenter(VCenter.x + gridSize, VCenter.y + gridSize, gridSize * 2, color)
    color = cc.convertColor(cc.c4b(0, 255, 0, 40), "4f")
    self:drawGridCenter(VCenter.x + gridSize / 2, VCenter.y + gridSize / 2, gridSize, color)
    color = cc.convertColor(cc.c4b(255, 255, 0, 20), "4f")
    self:drawGridCenter(VCenter.x + gridSize / 4, VCenter.y + gridSize / 4, gridSize / 2, color)
end

function GridLayer:drawGridCenter(centerX, centerY, gridSize, color, noGap)
    local maxX = VSize.width
    local maxY = VSize.height

    -- 画横线
    local gap = gridSize
    noGap     = noGap or 1
    self.drawNode:drawSegment(VVec2(0, centerY), VVec2(maxX, centerY), LINE_WIDTH, color)
    while centerY - gap > 0 do
        self.drawNode:drawSegment(VVec2(0, centerY - gap), VVec2(maxX, centerY - gap), LINE_WIDTH, color)
        self.drawNode:drawSegment(VVec2(0, centerY + gap), VVec2(maxX, centerY + gap), LINE_WIDTH, color)
        gap = gap + gridSize
    end

    -- 画竖线
    gap = gridSize
    self.drawNode:drawSegment(VVec2(centerX, 0), VVec2(centerX, maxY), LINE_WIDTH, color)
    while centerX - gap > 0 do
        self.drawNode:drawSegment(VVec2(centerX - gap, 0), VVec2(centerX - gap, maxY), LINE_WIDTH, color)
        self.drawNode:drawSegment(VVec2(centerX + gap, 0), VVec2(centerX + gap, maxY), LINE_WIDTH, color)
        gap = gap + gridSize
    end
end

function GridLayer:captureNode()
    local rtx = cc.RenderTexture:create(g_visible_size.width, g_visible_size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
    rtx:begin()
    self:visit()
    rtx:endToLua()
    rtx:saveToFile("grid.png", cc.IMAGE_FORMAT_PNG)
end

return GridLayer