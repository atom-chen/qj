--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Email: liyongjin2009@gmail.com
-- @Date:   2017-03-25
-- @Last Modified by:   liyongjin
-- @Last Modified time: 2017-03-29
-- @Desc:
--------------------------------------------------------------------------------
VisibleRect = class ("VisibleRect")

function VisibleRect.getVisibleRect()
    return VisibleRect.mVisibleRect
end

function VisibleRect.getVisibleMaxRect()
    return VisibleRect.mVisibleMaxRect
end

function VisibleRect.getVisibleFrameRect()
    return VisibleRect.mVisibleFrameRect
end

function VisibleRect.getVisibleSize()
    return VisibleRect.mVisibleRect.size
end

function VisibleRect.left()
    return VisibleRect.mLeft
end

function VisibleRect.right()
    return VisibleRect.mRight
end

function VisibleRect.top()
    return VisibleRect.mTop
end

function VisibleRect.bottom()
    return VisibleRect.mBottom
end

function VisibleRect.center()
    return VisibleRect.mCenter
end

function VisibleRect.leftTop()
    return VisibleRect.mLeftTop
end

function VisibleRect.rightTop()
    return VisibleRect.mRightTop
end

function VisibleRect.leftBottom()
    return VisibleRect.mLeftBottom
end

function VisibleRect.rightBottom()
    return VisibleRect.mRightBottom
end

function VisibleRect.leftGap(x, y)
    return cc.p(VisibleRect.mLeft.x + x, VisibleRect.mLeft.y + y)
end

function VisibleRect.rightGap(x, y)
    return cc.p(VisibleRect.mRight.x + x, VisibleRect.mRight.y + y)
end

function VisibleRect.topGap(x, y)
    return cc.p(VisibleRect.mTop.x + x, VisibleRect.mTop.y + y)
end

function VisibleRect.bottomGap(x, y)
    return cc.p(VisibleRect.mBottom.x + x, VisibleRect.mBottom.y + y)
end

function VisibleRect.centerGap(x, y)
    return cc.p(VisibleRect.mCenter.x + x, VisibleRect.mCenter.y + y)
end

function VisibleRect.leftTopGap(x, y)
    return cc.p(VisibleRect.mLeftTop.x + x, VisibleRect.mLeftTop.y + y)
end

function VisibleRect.rightTopGap(x, y)
    return cc.p(VisibleRect.mRightTop.x + x, VisibleRect.mRightTop.y + y)
end

function VisibleRect.leftBottomGap(x, y)
    return  cc.p(VisibleRect.mLeftBottom.x + x, VisibleRect.mLeftBottom.y + y)
end

function VisibleRect.rightBottomGap(x, y)
    return  cc.p(VisibleRect.mRightBottom.x + x, VisibleRect.mRightBottom.y + y)
end

VVec2 = VisibleRect.leftBottomGap
VFrameSize = nil  -- 窗口物理大小,以物理像素为单位
VVisibleFrameRect = nil -- 可视区域，以物理像素为单位,与设计大小等比
VVisibleMaxRect = nil -- 最大可视区域，忽略设计大小，和窗口物理大小等比
VWinSize = nil -- 设计大小，最大化到窗口可视区域外
VVisibleRect = nil -- 最大可视区域，与设计大小等比
VSize = nil -- 最大可视区域大小，与设计大小等比,
VLeft = nil
VRight = nil
VTop = nil
VBottom = nil
VCenter = nil
VLeftTop = nil
VRightTop = nil
VLeftBottom = nil
VRightBottom = nil

VLeftGap = VisibleRect.leftGap
VRightGap = VisibleRect.rightGap
VTopGap = VisibleRect.topGap
VBottomGap = VisibleRect.bottomGap
VCenterGap = VisibleRect.centerGap
VLeftTopGap = VisibleRect.leftTopGap
VRightTopGap = VisibleRect.rightTopGap
VLeftBottomGap = VisibleRect.leftBottomGap
VRightBottomGap = VisibleRect.rightBottomGap

function VisibleRect.setDesignResolutionSize(width, height, resolutionPolicy)
    local pEGLView = cc.Director:getInstance():getOpenGLView()
    local frameSize = pEGLView:getFrameSize()
    printInfo("frameRect(0, 0, %d, %d)", frameSize.width, frameSize.height)
    if resolutionPolicy == cc.ResolutionPolicy.FIXED_HEIGHT or resolutionPolicy == cc.ResolutionPolicy.FIXED_WIDTH then
        pEGLView:setDesignResolutionSize(width, height, resolutionPolicy);
        local winSize = cc.Director:getInstance():getWinSize()
        VisibleRect.initVisible(winSize.width, winSize.height)
        VisibleRect.initVisibleMax(resolutionPolicy)
        VisibleRect.initVisibleFrame(frameSize.width, frameSize.height)
    else
        pEGLView:setDesignResolutionSize(width, height, resolutionPolicy);
        VisibleRect.initVisible(width, height)
        VisibleRect.initVisibleMax(resolutionPolicy)
        VisibleRect.initVisibleFrame(frameSize.width, frameSize.height)
    end


    VisibleRect.initBasicVec2()
end

function VisibleRect.initVisible(width, height)
    local winSize = cc.Director:getInstance():getWinSize()
    printInfo("winRect(0, 0, %d, %d)", winSize.width, winSize.height)
    VisibleRect.mVisibleRect = {}
    VisibleRect.mVisibleRect.origin = cc.p((winSize.width - width) / 2, (winSize.height - height) / 2)
    VisibleRect.mVisibleRect.size = cc.size(width, height)
    VisibleRect.mLeft = cc.p(VisibleRect.mVisibleRect.origin.x, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height/2)
    VisibleRect.mRight = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height/2)
    VisibleRect.mTop = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width/2, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height)
    VisibleRect.mBottom = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width/2, VisibleRect.mVisibleRect.origin.y)
    VisibleRect.mCenter = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width/2, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height/2)
    VisibleRect.mLeftTop = cc.p(VisibleRect.mVisibleRect.origin.x, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height)
    VisibleRect.mRightTop = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width, VisibleRect.mVisibleRect.origin.y+VisibleRect.mVisibleRect.size.height)
    VisibleRect.mLeftBottom = VisibleRect.mVisibleRect.origin
    VisibleRect.mRightBottom = cc.p(VisibleRect.mVisibleRect.origin.x+VisibleRect.mVisibleRect.size.width, VisibleRect.mVisibleRect.origin.y)
    printInfo("VisibleRect(%d, %d, %d, %d)",
        VisibleRect.mVisibleRect.origin.x,
        VisibleRect.mVisibleRect.origin.y,
        VisibleRect.mVisibleRect.size.width,
        VisibleRect.mVisibleRect.size.height)
end

function VisibleRect.initVisibleMax(resolutionPolicy)
    local director = cc.Director:getInstance()
    local winSize = director:getWinSize()
    local frameSize = director:getOpenGLView():getFrameSize()
    local visibleMaxWidth
    local visibleMaxHeight
    if resolutionPolicy == cc.ResolutionPolicy.LEAF or resolutionPolicy == cc.ResolutionPolicy.NO_BORDER then
        local scaleX = winSize.width / frameSize.width
        local scaleY = winSize.height / frameSize.height
        local scale = 0
        if scaleX < scaleY then
            scale = scaleX
        else
            scale = scaleY
        end
        visibleMaxWidth = frameSize.width * scale
        visibleMaxHeight = frameSize.height * scale
    else
        visibleMaxWidth = winSize.width
        visibleMaxHeight = winSize.height
    end
    VisibleRect.mVisibleMaxRect = {}
    VisibleRect.mVisibleMaxRect.origin = cc.p((winSize.width - visibleMaxWidth) / 2, (winSize.height - visibleMaxHeight) / 2)
    VisibleRect.mVisibleMaxRect.size = cc.size(visibleMaxWidth, visibleMaxHeight)
    printInfo("mVisibleMaxRect(%d, %d, %d, %d)",
        VisibleRect.mVisibleMaxRect.origin.x,
        VisibleRect.mVisibleMaxRect.origin.y,
        VisibleRect.mVisibleMaxRect.size.width,
        VisibleRect.mVisibleMaxRect.size.height)
end

function VisibleRect.initVisibleFrame(width, height)
    local frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    local scaleX = frameSize.width / width
    local scaleY = frameSize.height / height
    local minScale = 0
    if scaleX < scaleY then
        minScale = scaleX
    else
        minScale = scaleY
    end
    local frameMinWidth = width * minScale
    local frameMinHeight = height * minScale
    VisibleRect.mVisibleFrameRect = {}
    VisibleRect.mVisibleFrameRect.origin = cc.p((frameSize.width - frameMinWidth) / 2, (frameSize.height - frameMinHeight) / 2)
    VisibleRect.mVisibleFrameRect.size = cc.size(frameMinWidth, frameMinHeight)
    printInfo("mVisibleFrameRect(%d, %d, %d, %d)",
        VisibleRect.mVisibleFrameRect.origin.x,
        VisibleRect.mVisibleFrameRect.origin.y,
        VisibleRect.mVisibleFrameRect.size.width,
        VisibleRect.mVisibleFrameRect.size.height)
end

function VisibleRect.initBasicVec2(width, height)
    VFrameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    VVisibleFrameRect = VisibleRect.getVisibleFrameRect()
    VVisibleMaxRect = VisibleRect.getVisibleMaxRect()
    VWinSize = cc.Director:getInstance():getWinSize()
    VSize = VisibleRect.getVisibleSize()
    VLeft = VisibleRect.left()
    VRight = VisibleRect.right()
    VTop = VisibleRect.top()
    VBottom = VisibleRect.bottom()
    VCenter = VisibleRect.center()
    VLeftTop = VisibleRect.leftTop()
    VRightTop = VisibleRect.rightTop()
    VLeftBottom = VisibleRect.leftBottom()
    VRightBottom = VisibleRect.rightBottom()
end
