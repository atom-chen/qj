local BaseLayer = require("modules.view.BaseLayer")
local GrayLayer = class("GrayLayer",function(args)
    return cc.LayerColor:create(cc.c4b(0, 0, 0, 175))
end,BaseLayer)

return GrayLayer