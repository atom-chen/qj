local TaskDldLayer = class("TaskDldLayer", function()
    return cc.Layer:create()
end)

function TaskDldLayer:create()
    local layer = TaskDldLayer.new()
    layer:createLayerMenu()
    return layer
end

function TaskDldLayer:createLayerMenu()
    local node = tolua.cast(cc.CSLoader:createNode("ui/task_dld.csb"), "ccui.Widget")
    self:addChild(node)
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local gzhLabel = ccui.Helper:seekWidgetByName(node, "gzh")
    gzhLabel:setString(string.format("如有疑问,请联系公众号:%s", gt.getConf("gongzhonghao")))

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    local copyBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "copy"), "ccui.Button")
    copyBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                ymkj.copyClipboard(gt.getConf("gongzhonghao"))
                commonlib.showLocalTip("复制成功")
            end
        end
    )

    local checkBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "check"), "ccui.Button")
    checkBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local node_tip = tolua.cast(cc.CSLoader:createNode("ui/task_dld_tip.csb"), "ccui.Widget")
                self:addChild(node_tip)
                node_tip:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

                ccui.Helper:doLayout(node_tip)

                local exitBtn = tolua.cast(ccui.Helper:seekWidgetByName(node_tip, "btn-exit"), "ccui.Button")
                exitBtn:addTouchEventListener(
                    function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            node_tip:removeFromParent(true)
                        end
                    end
                )
            end
        end
    )

    local downloadBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "download"), "ccui.Button")
    downloadBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local _url = gt.getConf("download_url")
                if g_os == "ios" then
                    _url = gt.getConf("iosdownload_url")
                end
                _url = _url .. "?v=" .. os.date("%m%d%H", os.time())
                gt.openUrl(_url)
            end
        end
    )
end

return TaskDldLayer