local MJHeadPos = {}

local windowSize = cc.Director:getInstance():getWinSize()

MJHeadPos.headPos3d = {cc.p(48,240),cc.p(windowSize.width-80,400),cc.p(windowSize.width/4.1,windowSize.height-70),cc.p(120,480)}
MJHeadPos.headPos = {cc.p(78,240),cc.p(windowSize.width-68,400),cc.p(windowSize.width/4.1,windowSize.height-102),cc.p(78,528)}

return MJHeadPos
