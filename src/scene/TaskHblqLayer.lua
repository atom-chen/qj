local TaskHblqLayer = class("TaskHblqLayer", function()
    return cc.Layer:create()
end)

function TaskHblqLayer:create(rtn_msg)
    local layer = TaskHblqLayer.new()
    layer:createLayerMenu(rtn_msg)
    return layer
end

function TaskHblqLayer:createLayerMenu(rtn_msg)
    local node = tolua.cast(cc.CSLoader:createNode("ui/task_hblq.csb"), "ccui.Widget")
    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    local shareBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "share"), "ccui.Button")
    shareBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0.25), cc.CallFunc:create(function()

                    local erweimaUrl = cc.UserDefault:getInstance():getStringForKey("hbhd_ewm", "")
                    local  ddd       = cc.FileUtils:getInstance():getWritablePath()..string.gsub(erweimaUrl, "/", "_")
                    if cc.FileUtils:getInstance():isFileExist(ddd) then
                        local content = io.readfile(ddd)
                        io.writefile(cc.FileUtils:getInstance():getWritablePath() .. "MyCurScene.png", content)
                    end

                end)))

                ymkj.wxReq(3, "")
                print("open share pengyouquan")
            end
        end
    )

    if rtn_msg.qrcode_url and #rtn_msg.qrcode_url > 8 then
        local sper = string.find(rtn_msg.qrcode_url, "/", 8)
        cc.UserDefault:getInstance():setStringForKey("hbhd_ewm", rtn_msg.qrcode_url)
        cc.UserDefault:getInstance():flush()
        tolua.cast(ccui.Helper:seekWidgetByName(node, "ewm"), "ccui.ImageView"):downloadImg(string.sub(rtn_msg.qrcode_url, sper + 1, -1), string.sub(rtn_msg.qrcode_url, 1, sper - 1))
    end
end

return TaskHblqLayer